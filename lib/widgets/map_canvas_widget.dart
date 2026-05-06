import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../providers/repository_providers.dart';
import '../models/hardware_component.dart';
import '../models/workstation_config.dart';
import '../domain/spatial_manager.dart';
import '../utils/keyboard_shortcuts.dart';
import '../services/camera_state_service.dart';
import 'desk_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 8: SPATIAL LOGIC EXTERNALIZATION
// Data-driven map canvas that renders workstation layouts provided by
// the SpatialManager.
// ═══════════════════════════════════════════════════════════════════════════

class MapCanvasWidget extends ConsumerStatefulWidget {
  final bool isEditMode;
  final String facilityId;

  const MapCanvasWidget({
    super.key,
    this.isEditMode = false,
    this.facilityId = 'CT1',
  });

  @override
  ConsumerState<MapCanvasWidget> createState() => _MapCanvasWidgetState();
}

class _MapCanvasWidgetState extends ConsumerState<MapCanvasWidget>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL UI STATE (Transient, not in Riverpod)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Transformation controller for InteractiveViewer (pan/zoom)
  late final TransformationController _transformationController;

  /// Animation controller for snap-to-desk kinetic motion
  AnimationController? _snapAnimationController;

  /// Matrix animation for smooth camera transitions
  Animation<Matrix4>? _snapAnimation;

  /// Minimum allowed scale (calculated to fit all labs)
  double? _minimumAllowedScale;

  /// Current workstation configurations being rendered
  List<WorkstationConfig> _workstationConfigs = [];

  /// Cached list of desk widgets (generated once, reused on every build)
  /// PERFORMANCE: Prevents re-mapping configs on every rebuild
  List<Widget>? _cachedDeskWidgets;

  /// Focus node for keyboard shortcuts
  late final FocusNode _keyboardFocusNode;

  /// Timer for debouncing camera state saves
  Timer? _cameraStateSaveDebounceTimer;

  /// Flag to prevent loading state during initialization
  bool _isInitializing = true;

  /// Scroll zoom animation controller
  AnimationController? _scrollZoomController;
  Animation<Matrix4>? _scrollZoomAnimation;

  /// The target transformation matrix being accumulated during rapid scroll events
  Matrix4? _accumulatedTargetMatrix;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double gridCellSizePixels = 100.0;
  static const double panStepPixels = 200.0; // Pixels to pan per arrow key press

  // iOS-style animation constants
  static const Duration iosQuickAnimationDuration = Duration(milliseconds: 300);
  static const Duration iosStandardAnimationDuration = Duration(milliseconds: 350);
  static const Duration iosSlowAnimationDuration = Duration(milliseconds: 450);
  static const Duration iosScrollZoomAnimationDuration = Duration(milliseconds: 150); // Faster for scroll
  static const Curve iosEaseOutCurve = Curves.easeOut;
  static const Curve iosEaseInOutCurve = Curves.easeInOut;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onCameraTransformationChanged);

    // Initialize focus node for keyboard shortcuts
    _keyboardFocusNode = FocusNode();

    // PERFORMANCE: Pre-generate configurations and widgets once
    _updateSpatialLayout();

    // Load saved camera state or fit all labs after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialCameraState();
    });
  }

  /// Updates the spatial layout based on the current facility ID
  void _updateSpatialLayout() {
    final spatialManager = ref.read(spatialManagerProvider);
    _workstationConfigs = spatialManager.getLayoutForFacility(widget.facilityId);
    _cachedDeskWidgets = _buildDeskWidgetList();
  }

  @override
  void didUpdateWidget(MapCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facilityId != widget.facilityId) {
      _updateSpatialLayout();
    }
  }

  /// Load initial camera state from localStorage or fit all labs
  Future<void> _loadInitialCameraState() async {
    final savedMatrix = await CameraStateService.loadCameraState();
    final savedWorkstationIdentifier = await CameraStateService.loadActiveDeskState();

    if (!mounted) return;

    // Calculate minimum scale before interactions
    _calculateGlobalOverviewMatrix();

    setState(() {
      _isInitializing = false;
    });

    if (savedMatrix != null) {
      // Restore saved camera position
      _transformationController.value = savedMatrix;
      print('📂 Restored camera state');

      // If there was an active desk, restore it
      if (savedWorkstationIdentifier != null) {
        final bool hasDesk = _workstationConfigs.any((config) => config.id == savedWorkstationIdentifier);
        if (hasDesk) {
          await _loadWorkstationComponents(savedWorkstationIdentifier);
        }
      }
    } else {
      // No saved state, fit all labs
      _fitAllLabsInView();
    }
  }

  /// Called when camera transformation changes (debounced save)
  void _onCameraTransformationChanged() {
    if (_isInitializing) return;

    // Debounce: only save after 500ms of no changes
    _cameraStateSaveDebounceTimer?.cancel();
    _cameraStateSaveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      CameraStateService.saveCameraState(_transformationController.value);
    });
  }

  /// Build the list of desk widgets once
  List<Widget> _buildDeskWidgetList() {
    const double horizontalOffsetPixels = 2.0 * gridCellSizePixels; 
    const double verticalOffsetPixels = 2.0 * gridCellSizePixels;

    return _workstationConfigs.map((config) {
      final workstationIdentifier = config.id;
      final dx = config.dx;
      final dy = config.dy;

      // Adjust position by subtracting offset (shift from col 2, row 2 to 0, 0)
      final adjustedHorizontalPositionPixels = (dx * gridCellSizePixels) - horizontalOffsetPixels;
      final adjustedVerticalPositionPixels = (dy * gridCellSizePixels) - verticalOffsetPixels;

      // Render pillars differently
      if (workstationIdentifier.startsWith('PILLAR_')) {
        return Positioned(
          left: adjustedHorizontalPositionPixels,
          top: adjustedVerticalPositionPixels,
          child: _buildStructuralPillar(),
        );
      }

      return Positioned(
        left: adjustedHorizontalPositionPixels,
        top: adjustedVerticalPositionPixels,
        child: _buildCanvasWorkstation(workstationIdentifier, Offset(dx, dy)),
      );
    }).toList();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onCameraTransformationChanged);
    _transformationController.dispose();
    _snapAnimationController?.dispose();
    _scrollZoomController?.dispose();
    _keyboardFocusNode.dispose();
    _cameraStateSaveDebounceTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZOOM CONSTRAINT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculates the dynamic responsive matrix to perfectly frame the canvas.
  Matrix4 _calculateGlobalOverviewMatrix() {
    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    const double canvasWidthPixels = 3200.0;
    const double canvasHeightPixels = 1700.0;

    final double horizontalScaleFactor = (viewportSize.width - 40) / canvasWidthPixels;
    final double verticalScaleFactor = (viewportSize.height - 150) / canvasHeightPixels;
    final double targetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(0.1, 5.0);

    _minimumAllowedScale = targetScale;

    const double contentCenterHorizontalPixels = canvasWidthPixels / 2;
    const double contentCenterVerticalPixels = canvasHeightPixels / 2;

    final double viewportCenterHorizontalPixels = viewportSize.width / 2;
    final double viewportCenterVerticalPixels = viewportSize.height / 2;

    final double translationHorizontalPixels = viewportCenterHorizontalPixels - (contentCenterHorizontalPixels * targetScale);
    final double translationVerticalPixels = viewportCenterVerticalPixels - (contentCenterVerticalPixels * targetScale);

    return Matrix4.identity()
      ..translate(translationHorizontalPixels, translationVerticalPixels)
      ..scale(targetScale);
  }

  /// Fit all laboratories in view
  void _fitAllLabsInView() {
    if (!mounted) return;
    _transformationController.value = _calculateGlobalOverviewMatrix();
  }

  /// Zoom in by 20%
  void _zoomIn() {
    if (!mounted) return;
    
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(1.2);
    
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  /// Zoom out by 20%
  void _zoomOut() {
    if (!mounted) return;
    
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(0.8);
    
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  /// Animate matrix change
  void _animateCameraTransformation(Matrix4 startMatrix, Matrix4 endMatrix, Duration animationDuration) {
    _snapAnimationController?.dispose();
    
    final animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    _snapAnimationController = animationController;

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: iosEaseOutCurve,
    );

    final matrixAnimation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(curvedAnimation);
    _snapAnimation = matrixAnimation;

    matrixAnimation.addListener(() {
      if (mounted) {
        _transformationController.value = matrixAnimation.value;
      }
    });

    animationController.forward();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYBOARD SHORTCUTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle keyboard shortcuts
  KeyEventResult _processKeyboardEvent(FocusNode focusNode, KeyEvent keyboardEvent) {
    if (keyboardEvent is! KeyDownEvent) return KeyEventResult.ignored;

    final shortcutAction = KeyboardShortcuts.getAction(keyboardEvent);
    if (shortcutAction == null) return KeyEventResult.ignored;

    _executeKeyboardShortcut(shortcutAction);
    return KeyEventResult.handled;
  }

  /// Execute keyboard shortcut action
  void _executeKeyboardShortcut(MapShortcutAction shortcutAction) {
    switch (shortcutAction) {
      case MapShortcutAction.closeInspector:
        _processInspectorCloseRequest();
        break;
      case MapShortcutAction.panUp:
        _panCameraView(0, -panStepPixels);
        break;
      case MapShortcutAction.panDown:
        _panCameraView(0, panStepPixels);
        break;
      case MapShortcutAction.panLeft:
        _panCameraView(-panStepPixels, 0);
        break;
      case MapShortcutAction.panRight:
        _panCameraView(panStepPixels, 0);
        break;
      case MapShortcutAction.zoomIn:
        _zoomIn();
        _displayShortcutFeedbackMessage('Zoom In');
        break;
      case MapShortcutAction.zoomOut:
        _zoomOut();
        _displayShortcutFeedbackMessage('Zoom Out');
        break;
      case MapShortcutAction.fitAllLabs:
        _fitAllLabsInView();
        _displayShortcutFeedbackMessage('Fit All Labs');
        break;
      case MapShortcutAction.jumpToLab1:
        _transitionToLaboratory(1);
        break;
      case MapShortcutAction.jumpToLab2:
        _transitionToLaboratory(2);
        break;
      case MapShortcutAction.jumpToLab3:
        _transitionToLaboratory(3);
        break;
      case MapShortcutAction.jumpToLab4:
        _transitionToLaboratory(4);
        break;
      case MapShortcutAction.jumpToLab5:
        _transitionToLaboratory(5);
        break;
      case MapShortcutAction.jumpToLab6:
        _transitionToLaboratory(6);
        break;
      case MapShortcutAction.jumpToLab7:
        _transitionToLaboratory(7);
        break;
      case MapShortcutAction.cycleDeskNext:
        _cycleWorkstationInCurrentLaboratory(forward: true);
        break;
      case MapShortcutAction.cycleDeskPrevious:
        _cycleWorkstationInCurrentLaboratory(forward: false);
        break;
      case MapShortcutAction.showHelp:
        _displayKeyboardShortcutsDialog();
        break;
    }
  }

  /// Handle close inspector shortcut
  void _processInspectorCloseRequest() {
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) {
      resetToGlobalOverview();
      _displayShortcutFeedbackMessage('Inspector Closed');
    }
  }

  /// Pan camera by delta pixels
  void _panCameraView(double horizontalDeltaPixels, double verticalDeltaPixels) {
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) return;

    if (!mounted) return;
    final currentTransformationMatrix = _transformationController.value.clone();
    currentTransformationMatrix.translate(horizontalDeltaPixels, verticalDeltaPixels);
    _transformationController.value = currentTransformationMatrix;
  }

  /// Jump to a specific lab
  Future<void> _transitionToLaboratory(int labNumber) async {
    final labPrefix = 'L${labNumber}_D';
    final labConfigs = _workstationConfigs.where((config) => config.id.startsWith(labPrefix)).toList();

    if (labConfigs.isEmpty) {
      _displayShortcutFeedbackMessage('Lab $labNumber not found');
      return;
    }

    final minimumColumnNumber = labConfigs.map((config) => config.dx).reduce((a, b) => a < b ? a : b);
    final maximumColumnNumber = labConfigs.map((config) => config.dx).reduce((a, b) => a > b ? a : b);
    final minimumRowNumber = labConfigs.map((config) => config.dy).reduce((a, b) => a < b ? a : b);
    final maximumRowNumber = labConfigs.map((config) => config.dy).reduce((a, b) => a > b ? a : b);

    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    final double contentWidthPixels = (maximumColumnNumber - minimumColumnNumber + 1) * gridCellSizePixels;
    final double contentHeightPixels = (maximumRowNumber - minimumRowNumber + 1) * gridCellSizePixels;

    final double horizontalScaleFactor = (viewportSize.width - 200) / contentWidthPixels;
    final double verticalScaleFactor = (viewportSize.height - 200) / contentHeightPixels;
    final double dynamicTargetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(_minimumAllowedScale ?? 0.1, 5.0);

    final centerColumnNumber = (minimumColumnNumber + maximumColumnNumber + 1) / 2;
    final centerRowNumber = (minimumRowNumber + maximumRowNumber + 1) / 2;

    await _animateToWorldPosition(centerColumnNumber, centerRowNumber, dynamicTargetScale);
    _displayShortcutFeedbackMessage('Lab $labNumber');
  }

  /// Cycle through desks in current lab
  void _cycleWorkstationInCurrentLaboratory({required bool forward}) {
    final activeWorkstationIdentifier = ref.read(activeDeskProvider);
    
    if (activeWorkstationIdentifier == null) {
      _displayShortcutFeedbackMessage('No active desk');
      return;
    }

    final laboratoryMatch = RegExp(r'L(\d+)_D').firstMatch(activeWorkstationIdentifier);
    if (laboratoryMatch == null) return;

    final labNumber = int.parse(laboratoryMatch.group(1).toString());

    final labPrefix = 'L${labNumber}_D';
    final labWorkstationIdentifiers = _workstationConfigs
        .where((config) => config.id.startsWith(labPrefix))
        .map((config) => config.id)
        .toList()
      ..sort();

    if (labWorkstationIdentifiers.isEmpty) return;

    final currentWorkstationIndex = labWorkstationIdentifiers.indexOf(activeWorkstationIdentifier);
    if (currentWorkstationIndex == -1) return;

    int nextWorkstationIndex;
    if (forward) {
      nextWorkstationIndex = (currentWorkstationIndex + 1) % labWorkstationIdentifiers.length;
    } else {
      nextWorkstationIndex = (currentWorkstationIndex - 1 + labWorkstationIdentifiers.length) % labWorkstationIdentifiers.length;
    }

    final nextWorkstationIdentifier = labWorkstationIdentifiers[nextWorkstationIndex];
    _loadWorkstationComponents(nextWorkstationIdentifier);
    _displayShortcutFeedbackMessage(nextWorkstationIdentifier);
  }

  /// Animate camera to a specific position
  Future<void> _animateToWorldPosition(double columnNumber, double rowNumber, double targetScale) async {
    if (!mounted) return;

    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    final screenTargetHorizontalPixels = viewportSize.width * 0.5;
    final screenTargetVerticalPixels = viewportSize.height * 0.5;

    const double horizontalOffsetPixels = 2.0 * gridCellSizePixels;
    const double verticalOffsetPixels = 2.0 * gridCellSizePixels;

    final worldHorizontalPixels = (columnNumber * gridCellSizePixels) - horizontalOffsetPixels;
    final worldVerticalPixels = (rowNumber * gridCellSizePixels) - verticalOffsetPixels;

    final translationHorizontalPixels = screenTargetHorizontalPixels - (worldHorizontalPixels * targetScale);
    final translationVerticalPixels = screenTargetVerticalPixels - (worldVerticalPixels * targetScale);

    final targetTransformationMatrix = Matrix4.identity()
      ..translate(translationHorizontalPixels, translationVerticalPixels)
      ..scale(targetScale);

    final currentTransformationMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    
    final animationController = AnimationController(
      vsync: this,
      duration: iosQuickAnimationDuration,
    );
    _snapAnimationController = animationController;

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: iosEaseOutCurve,
    );

    final matrixAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);
    _snapAnimation = matrixAnimation;

    matrixAnimation.addListener(() {
      if (mounted) {
        _transformationController.value = matrixAnimation.value;
      }
    });

    await animationController.forward();
  }

  /// Show keyboard shortcut feedback
  void _displayShortcutFeedbackMessage(String feedbackMessage) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedbackMessage),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show keyboard shortcuts help dialog
  void _displayKeyboardShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Keyboard Shortcuts',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.5),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeyboardShortcutHelpEntry('ESC', 'Close Inspector / Return to Overview'),
              _buildKeyboardShortcutHelpEntry('Arrow Keys', 'Pan Camera'),
              _buildKeyboardShortcutHelpEntry('+/-', 'Zoom In/Out'),
              _buildKeyboardShortcutHelpEntry('Space', 'Fit All Labs'),
              _buildKeyboardShortcutHelpEntry('1-7', 'Jump to Lab 1-7'),
              _buildKeyboardShortcutHelpEntry('Tab', 'Next Desk in Lab'),
              _buildKeyboardShortcutHelpEntry('Shift+Tab', 'Previous Desk in Lab'),
              _buildKeyboardShortcutHelpEntry('?', 'Show This Help'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcutHelpEntry(String keyboardKey, String shortcutDescription) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              keyboardKey,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(shortcutDescription),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SNAP-TO-INSPECT ANIMATION (Kinetic Motion Engine)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Snap-to-Inspect: Animate camera with iOS-style spring physics
  Future<void> _animateToWorkstationFocus(String workstationIdentifier) async {
    final workstationConfig = _workstationConfigs.firstWhere(
      (config) => config.id == workstationIdentifier,
      orElse: () => const WorkstationConfig(id: '', dx: 0, dy: 0),
    );
    
    if (workstationConfig.id.isEmpty || !mounted) return;

    final dx = workstationConfig.dx;
    final dy = workstationConfig.dy;

    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    final double availableWidthPixels = viewportSize.width * 0.6;
    final double availableHeightPixels = viewportSize.height;

    const double contentWidthPixels = gridCellSizePixels;
    const double contentHeightPixels = gridCellSizePixels;

    final double horizontalScaleFactor = (availableWidthPixels - 200) / contentWidthPixels;
    final double verticalScaleFactor = (availableHeightPixels - 200) / contentHeightPixels;
    final double dynamicTargetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(_minimumAllowedScale ?? 0.1, 5.0);

    final screenTargetHorizontalPixels = viewportSize.width * 0.3; 
    final screenTargetVerticalPixels = viewportSize.height * 0.5;

    const double horizontalOffsetPixels = 2.0 * gridCellSizePixels; 
    const double verticalOffsetPixels = 2.0 * gridCellSizePixels; 

    final worldHorizontalPixels = ((dx + 0.5) * gridCellSizePixels) - horizontalOffsetPixels;
    final worldVerticalPixels = ((dy + 0.5) * gridCellSizePixels) - verticalOffsetPixels;

    final translationHorizontalPixels = screenTargetHorizontalPixels - (worldHorizontalPixels * dynamicTargetScale);
    final translationVerticalPixels = screenTargetVerticalPixels - (worldVerticalPixels * dynamicTargetScale);

    final targetTransformationMatrix = Matrix4.identity()
      ..translate(translationHorizontalPixels, translationVerticalPixels)
      ..scale(dynamicTargetScale);

    final currentTransformationMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    
    final animationController = AnimationController(
      vsync: this,
      duration: iosStandardAnimationDuration,
    );
    _snapAnimationController = animationController;

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );

    final matrixAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);
    _snapAnimation = matrixAnimation;

    matrixAnimation.addListener(() {
      if (mounted) {
        _transformationController.value = matrixAnimation.value;
      }
    });

    await animationController.forward();
  }

  /// Reset to global overview
  Future<void> resetToGlobalOverview() async {
    if (!mounted) return;

    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();

    CameraStateService.clearActiveDeskState();

    final targetTransformationMatrix = _calculateGlobalOverviewMatrix();
    final currentTransformationMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    
    final animationController = AnimationController(
      vsync: this,
      duration: iosSlowAnimationDuration,
    );
    _snapAnimationController = animationController;

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: iosEaseInOutCurve,
    );

    final matrixAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);
    _snapAnimation = matrixAnimation;

    matrixAnimation.addListener(() {
      if (mounted) {
        _transformationController.value = matrixAnimation.value;
      }
    });

    await animationController.forward();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESK INTERACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load desk components
  Future<void> _loadWorkstationComponents(String workstationIdentifier) async {
    print('🖱️ Desk clicked: $workstationIdentifier');

    ref.read(selectedDeskProvider.notifier).selectDesk(workstationIdentifier);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(selectedDeskProvider.notifier).clearSelection();
      }
    });

    final workstationComponents = await ref.read(workstationRepositoryProvider).getWorkstationComponents(workstationIdentifier);

    if (workstationComponents != null && workstationComponents.isNotEmpty) {
      ref.read(activeDeskProvider.notifier).setActiveDesk(workstationIdentifier);
      ref.read(activeDeskComponentsProvider.notifier).setComponents(workstationComponents);
      ref.read(inspectorStateProvider.notifier).openInspector();
      CameraStateService.saveActiveDeskState(workstationIdentifier);
      await _animateToWorkstationFocus(workstationIdentifier);
    } else {
      ref.read(activeDeskProvider.notifier).setActiveDesk(workstationIdentifier);
      ref.read(activeDeskComponentsProvider.notifier).clearComponents();
      ref.read(inspectorStateProvider.notifier).openInspector();
      CameraStateService.saveActiveDeskState(workstationIdentifier);
      await _animateToWorkstationFocus(workstationIdentifier);
    }
  }

  /// Handle component drop
  Future<void> _handleComponentDrop(
    HardwareComponent draggedComponent,
    String targetWorkstationIdentifier,
  ) async {
    final sourceWorkstationIdentifier = ref.read(sourceWorkstationProvider);
    
    if (sourceWorkstationIdentifier == null || sourceWorkstationIdentifier == targetWorkstationIdentifier) {
      ref.read(draggingComponentProvider.notifier).clearDragging();
      return;
    }

    final inventoryManager = ref.read(inventoryManagerProvider);
    final result = await inventoryManager.moveComponent(
      componentId: draggedComponent.dntsSerial,
      fromWorkstationId: sourceWorkstationIdentifier,
      toWorkstationId: targetWorkstationIdentifier,
    );

    result.fold(
      (success) {
        print('✅ Move successful: ${draggedComponent.dntsSerial} to $targetWorkstationIdentifier');
        // Refresh local UI state
        ref.read(refreshTriggerProvider.notifier).state++;
        // If the source or target was the active desk, refresh its components
        final activeDeskIdentifier = ref.read(activeDeskProvider);
        if (activeDeskIdentifier != null && (activeDeskIdentifier == sourceWorkstationIdentifier || activeDeskIdentifier == targetWorkstationIdentifier)) {
          _loadWorkstationComponents(activeDeskIdentifier);
        }
      },
      (failure) {
        print('❌ Move failed: $failure');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Move failed: $failure')),
        );
      },
    );

    ref.read(draggingComponentProvider.notifier).clearDragging();
    ref.read(sourceWorkstationProvider.notifier).state = null;
  }

  /// Handle canvas tap in edit mode
  void _processCanvasTap(TapUpDetails tapDetails) {
    if (!widget.isEditMode) return;
    final localTapPosition = tapDetails.localPosition;

    const double horizontalOffsetPixels = 2.0;
    const double verticalOffsetPixels = 2.0;

    final int gridColumnNumber = (localTapPosition.dx / gridCellSizePixels).floor() + horizontalOffsetPixels.toInt();
    final int gridRowNumber = (localTapPosition.dy / gridCellSizePixels).floor() + verticalOffsetPixels.toInt();
    final tapGridCoordinates = Offset(gridColumnNumber.toDouble(), gridRowNumber.toDouble());

    setState(() {
      final existingWorkstationIdentifiers = _workstationConfigs
          .where((config) => config.dx == tapGridCoordinates.dx && config.dy == tapGridCoordinates.dy && !config.id.startsWith('PILLAR_'))
          .map((config) => config.id)
          .toList();

      if (existingWorkstationIdentifiers.isNotEmpty) {
        for (final workstationIdentifier in existingWorkstationIdentifiers) {
          _workstationConfigs.removeWhere((config) => config.id == workstationIdentifier);
        }
      } else {
        final customWorkstationIdentifier =
            'CUSTOM_${(_workstationConfigs.length + 1).toString().padLeft(3, '0')}';
        _workstationConfigs.add(WorkstationConfig(
          id: customWorkstationIdentifier,
          dx: tapGridCoordinates.dx,
          dy: tapGridCoordinates.dy,
        ));
      }
      _cachedDeskWidgets = _buildDeskWidgetList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDERING
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isInspectorOpen = ref.watch(inspectorStateProvider);

    ref.listen<CameraAction?>(cameraControlProvider, (previous, next) {
      if (next == null) return;

      switch (next) {
        case CameraAction.fitAllLabs:
          _fitAllLabsInView();
          break;
        case CameraAction.zoomIn:
          _zoomIn();
          break;
        case CameraAction.zoomOut:
          _zoomOut();
          break;
        case CameraAction.resetToGlobalOverview:
          resetToGlobalOverview();
          break;
      }
    });

    ref.listen<bool>(inspectorStateProvider, (previous, next) {
      if (previous == true && next == false) {
        resetToGlobalOverview();
      }
    });

    return _buildInfiniteCanvasView(isInspectorOpen);
  }

  /// Builds the blueprint-style infinite canvas
  Widget _buildInfiniteCanvasView(bool isInspectorOpen) {
    const double canvasWidthPixels = 3200.0;
    const double canvasHeightPixels = 1700.0;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _processKeyboardEvent,
      autofocus: true,
      child: Listener(
        onPointerSignal: (pointerSignalEvent) {
          try {
            final scrollDelta = (pointerSignalEvent as dynamic).scrollDelta;
            if (scrollDelta != null) {
              _processScrollZoomEvent(pointerSignalEvent);
            }
          } catch (exception) {
            // Not a scroll event
          }
        },
        child: ClipRect(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.none,
            minScale: _minimumAllowedScale ?? 0.1,
            maxScale: 5.0,
            scaleEnabled: false,
            panEnabled: !widget.isEditMode && !isInspectorOpen,
            onInteractionUpdate: _processInteractionUpdate,
            child: GestureDetector(
              onTapUp: _processCanvasTap,
              child: Container(
                width: canvasWidthPixels,
                height: canvasHeightPixels,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GridPainter(
                      gridCellSizePixels: gridCellSizePixels,
                      gridColor: Theme.of(context).dividerColor,
                    ),
                    child: Stack(
                      children: _cachedDeskWidgets ?? [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),      ),
    );
  }

  /// Handle interaction updates
  void _processInteractionUpdate(ScaleUpdateDetails interactionDetails) {
    if (interactionDetails.scale == 1.0) return;

    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double targetScale = (currentScale * interactionDetails.scale).clamp(_minimumAllowedScale ?? 0.1, 5.0);

    final Matrix4 targetMatrix = _calculateZoomTransformationMatrix(
      currentMatrix,
      currentScale,
      targetScale,
      interactionDetails.localFocalPoint,
    );

    _transformationController.value = targetMatrix;
  }

  /// Handle smooth scroll zoom
  void _processScrollZoomEvent(dynamic scrollEvent) {
    if (!mounted) return;

    final scrollDelta = (scrollEvent as dynamic).scrollDelta;
    if (scrollDelta == null) return;

    if ((scrollEvent as dynamic).kind == PointerDeviceKind.trackpad) {
      final double dx = -(scrollDelta.dx as num).toDouble();
      final double dy = -(scrollDelta.dy as num).toDouble();

      final Matrix4 baseTransformationMatrix = _accumulatedTargetMatrix ?? _transformationController.value.clone();
      final double currentScale = baseTransformationMatrix.getMaxScaleOnAxis();

      final targetMatrix = baseTransformationMatrix.clone()..translate(dx / currentScale, dy / currentScale);
      _accumulatedTargetMatrix = targetMatrix;
      _animateScrollZoomTransformation(_transformationController.value, targetMatrix);
      return;
    }

    final double scrollDeltaVerticalPixels = (scrollDelta.dy as num).toDouble();
    final double scrollDeltaMultiplier = (scrollDeltaVerticalPixels * 0.0015).clamp(-0.2, 0.2);
    final double zoomScaleFactor = 1.0 - scrollDeltaMultiplier;

    final Matrix4 baseTransformationMatrix = _accumulatedTargetMatrix ?? _transformationController.value.clone();
    final double currentTargetScale = baseTransformationMatrix.getMaxScaleOnAxis();
    final double accumulatedTargetScale = (currentTargetScale * zoomScaleFactor).clamp(_minimumAllowedScale ?? 0.1, 5.0);

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final pointerPosition = (scrollEvent as dynamic).position;
    final Offset focalPointPixels = renderBox.globalToLocal(pointerPosition as Offset);

    final targetMatrix = _calculateZoomTransformationMatrix(
      baseTransformationMatrix,
      currentTargetScale,
      accumulatedTargetScale,
      focalPointPixels,
    );
    _accumulatedTargetMatrix = targetMatrix;

    _animateScrollZoomTransformation(_transformationController.value, targetMatrix);
  }

  /// Calculate zoom matrix
  Matrix4 _calculateZoomTransformationMatrix(
    Matrix4 currentMatrix,
    double currentScale,
    double targetScale,
    Offset focalPointPixels,
  ) {
    final currentTranslationVector = currentMatrix.getTranslation();
    final worldHorizontalPixels = (focalPointPixels.dx - currentTranslationVector.x) / currentScale;
    final worldVerticalPixels = (focalPointPixels.dy - currentTranslationVector.y) / currentScale;

    final targetTranslationHorizontalPixels = focalPointPixels.dx - (worldHorizontalPixels * targetScale);
    final targetTranslationVerticalPixels = focalPointPixels.dy - (worldVerticalPixels * targetScale);

    return Matrix4.identity()
      ..translate(targetTranslationHorizontalPixels, targetTranslationVerticalPixels)
      ..scale(targetScale);
  }

  /// Animate scroll zoom
  void _animateScrollZoomTransformation(Matrix4 startMatrix, Matrix4 endMatrix) {
    final currentController = _scrollZoomController;
    if (currentController == null) {
      final newController = AnimationController(
        vsync: this,
        duration: iosScrollZoomAnimationDuration,
      );
      _scrollZoomController = newController;
      _executeScrollZoomAnimation(newController, startMatrix, endMatrix);
    } else {
      currentController.stop();
      _executeScrollZoomAnimation(currentController, startMatrix, endMatrix);
    }
  }

  void _executeScrollZoomAnimation(AnimationController animationController, Matrix4 startMatrix, Matrix4 endMatrix) {
    final matrixAnimation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));
    _scrollZoomAnimation = matrixAnimation;

    matrixAnimation.addListener(() {
      if (mounted) {
        _transformationController.value = matrixAnimation.value;
      }
    });

    animationController.forward().then((_) {
      if (mounted && animationController.isCompleted) {
        _accumulatedTargetMatrix = null;
      }
    });
  }

  /// A pillar
  Widget _buildStructuralPillar() {
    return Container(
      width: gridCellSizePixels,
      height: gridCellSizePixels,
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
      ),
      child: const Center(
        child: Icon(
          Icons.block,
          color: Color(0xFF9CA3AF),
          size: 32,
        ),
      ),
    );
  }

  /// A single desk tile
  Widget _buildCanvasWorkstation(String workstationIdentifier, Offset position) {
    return DeskWidget(
      deskId: workstationIdentifier,
      position: position,
      cellSize: gridCellSizePixels,
      isEditMode: widget.isEditMode,
      onTap: () => _loadWorkstationComponents(workstationIdentifier),
      onComponentDrop: (component) => _handleComponentDrop(component, workstationIdentifier),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  final double gridCellSizePixels;
  final Color gridColor;

  _GridPainter({
    required this.gridCellSizePixels,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (double horizontalPositionPixels = 0; horizontalPositionPixels <= size.width; horizontalPositionPixels += gridCellSizePixels) {
      canvas.drawLine(Offset(horizontalPositionPixels, 0), Offset(horizontalPositionPixels, size.height), gridPaint);
    }

    for (double verticalPositionPixels = 0; verticalPositionPixels <= size.height; verticalPositionPixels += gridCellSizePixels) {
      canvas.drawLine(Offset(0, verticalPositionPixels), Offset(size.width, verticalPositionPixels), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor;
  }
}

