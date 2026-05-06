import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../utils/workstation_repository.dart';
import '../utils/keyboard_shortcuts.dart';
import '../services/camera_state_service.dart';
import 'desk_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 3B: MAP CANVAS EXTRACTION
// Extracted from InteractiveMapScreen into a dedicated ConsumerStatefulWidget.
// Manages the InteractiveViewer, TransformationController, snap animations,
// and desk grid rendering.
// ═══════════════════════════════════════════════════════════════════════════

class MapCanvasWidget extends ConsumerStatefulWidget {
  final bool isEditMode;

  const MapCanvasWidget({
    super.key,
    this.isEditMode = false,
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

  /// Desk coordinate map (Master Blueprint: 332 desks across 7 labs)
  final Map<String, Offset> _deskLayouts = _generateDeskCoordinates();

  /// Cached list of desk widgets (generated once, reused on every build)
  /// PERFORMANCE: Prevents re-mapping deskLayouts.entries on every rebuild
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

    // PERFORMANCE: Pre-generate desk widgets once
    // This list is static and doesn't depend on reactive state
    _cachedDeskWidgets = _buildDeskWidgetList();

    // Load saved camera state or fit all labs after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialCameraState();
    });
  }

  /// Load initial camera state from localStorage or fit all labs
  Future<void> _loadInitialCameraState() async {
    final savedMatrix = await CameraStateService.loadCameraState();
    final savedWorkstationIdentifier = await CameraStateService.loadActiveDeskState();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
    });

    if (savedMatrix != null) {
      // Restore saved camera position
      _transformationController.value = savedMatrix;
      print('📂 Restored camera state');

      // If there was an active desk, restore it
      if (savedWorkstationIdentifier != null && _deskLayouts.containsKey(savedWorkstationIdentifier)) {
        await _loadWorkstationComponents(savedWorkstationIdentifier);
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

  /// Build the list of desk widgets once (called in initState)
  /// PERFORMANCE: Prevents re-mapping 332 desks on every rebuild
  List<Widget> _buildDeskWidgetList() {
    const double horizontalOffsetPixels = 2.0 * gridCellSizePixels; 
    const double verticalOffsetPixels = 2.0 * gridCellSizePixels;

    return _deskLayouts.entries.map((entry) {
      final workstationIdentifier = entry.key;
      final gridCoordinates = entry.value;

      // Adjust position by subtracting offset (shift from col 2, row 2 to 0, 0)
      final adjustedHorizontalPositionPixels = (gridCoordinates.dx * gridCellSizePixels) - horizontalOffsetPixels;
      final adjustedVerticalPositionPixels = (gridCoordinates.dy * gridCellSizePixels) - verticalOffsetPixels;

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
        child: _buildCanvasWorkstation(workstationIdentifier),
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
  /// Derived from user's manual adjustments: ~40px horizontal and ~150px vertical padding.
  Matrix4 _calculateGlobalOverviewMatrix() {
    // Determine exact size of the MapCanvasWidget viewport.
    // Fallback to MediaQuery if renderBox is not yet laid out (rare edge case).
    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    const double canvasWidthPixels = 3200.0;
    const double canvasHeightPixels = 1700.0;

    // Calculate scale to fit canvas with dynamic padding
    final double horizontalScaleFactor = (viewportSize.width - 40) / canvasWidthPixels;
    final double verticalScaleFactor = (viewportSize.height - 150) / canvasHeightPixels;
    final double targetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(0.01, 5.0);

    _minimumAllowedScale = targetScale;

    // Center of the physical blueprint canvas
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

  /// Fit all laboratories in view (used for initial load and reset)
  void _fitAllLabsInView() {
    if (!mounted) return;
    _transformationController.value = _calculateGlobalOverviewMatrix();
  }

  /// Zoom in by 20% with iOS-style animation
  void _zoomIn() {
    if (!mounted) return;
    
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(1.2);
    
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  /// Zoom out by 20% with iOS-style animation
  void _zoomOut() {
    if (!mounted) return;
    
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(0.8);
    
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  /// Animate matrix change with iOS-style curve
  void _animateCameraTransformation(Matrix4 startMatrix, Matrix4 endMatrix, Duration animationDuration) {
    _snapAnimationController?.dispose();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseOutCurve,
    );

    _snapAnimation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(curvedAnimation);

    _snapAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _snapAnimation!.value;
      }
    });

    _snapAnimationController!.forward();
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
    if (isInspectorOpen) return; // Don't pan when inspector is open

    if (!mounted) return;
    final currentTransformationMatrix = _transformationController.value.clone();
    currentTransformationMatrix.translate(horizontalDeltaPixels, verticalDeltaPixels);
    _transformationController.value = currentTransformationMatrix;
  }

  /// Jump to a specific lab
  Future<void> _transitionToLaboratory(int labNumber) async {
    // Get first desk in the lab
    final labWorkstationIdentifiers = _deskLayouts.keys
        .where((identifier) => identifier.startsWith('L${labNumber}_D'))
        .toList()
      ..sort();

    if (labWorkstationIdentifiers.isEmpty) {
      _displayShortcutFeedbackMessage('Lab $labNumber not found');
      return;
    }

    // Calculate lab bounds
    final labWorkstationOffsets = labWorkstationIdentifiers.map((identifier) => _deskLayouts[identifier]!).toList();
    final minimumColumnNumber = labWorkstationOffsets.map((offset) => offset.dx).reduce((a, b) => a < b ? a : b);
    final maximumColumnNumber = labWorkstationOffsets.map((offset) => offset.dx).reduce((a, b) => a > b ? a : b);
    final minimumRowNumber = labWorkstationOffsets.map((offset) => offset.dy).reduce((a, b) => a < b ? a : b);
    final maximumRowNumber = labWorkstationOffsets.map((offset) => offset.dy).reduce((a, b) => a > b ? a : b);

    // Get exact viewport size for dynamic responsive zooming
    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    final double contentWidthPixels = (maximumColumnNumber - minimumColumnNumber + 1) * gridCellSizePixels;
    final double contentHeightPixels = (maximumRowNumber - minimumRowNumber + 1) * gridCellSizePixels;

    // Apply ~200px dynamic padding to reverse-engineer user's exact manual zoom preference
    final double horizontalScaleFactor = (viewportSize.width - 200) / contentWidthPixels;
    final double verticalScaleFactor = (viewportSize.height - 200) / contentHeightPixels;
    final double dynamicTargetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(0.01, 5.0);

    // Calculate center of lab (adding 1 to include full cell width/height)
    final centerColumnNumber = (minimumColumnNumber + maximumColumnNumber + 1) / 2;
    final centerRowNumber = (minimumRowNumber + maximumRowNumber + 1) / 2;

    // Animate to lab center with dynamic scale
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

    // Extract lab number from current desk
    final laboratoryMatch = RegExp(r'L(\d+)_D').firstMatch(activeWorkstationIdentifier);
    if (laboratoryMatch == null) return;

    final labNumber = int.parse(laboratoryMatch.group(1)!);

    // Get all desks in this lab
    final labWorkstationIdentifiers = _deskLayouts.keys
        .where((identifier) => identifier.startsWith('L${labNumber}_D'))
        .toList()
      ..sort();

    if (labWorkstationIdentifiers.isEmpty) return;

    // Find current desk index
    final currentWorkstationIndex = labWorkstationIdentifiers.indexOf(activeWorkstationIdentifier);
    if (currentWorkstationIndex == -1) return;

    // Calculate next index
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
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosQuickAnimationDuration, // iOS-style quick navigation
    );

    // iOS uses easeOut for navigation - starts fast, ends smoothly
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseOutCurve,
    );

    _snapAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);

    _snapAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _snapAnimation!.value;
      }
    });

    await _snapAnimationController!.forward();
  }

  /// Show keyboard shortcut feedback
  void _displayShortcutFeedbackMessage(String feedbackMessage) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedbackMessage),
        duration: const Duration(milliseconds: 1200), // iOS-style longer feedback
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // iOS-style rounded corners
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
    final workstationGridOffset = _deskLayouts[workstationIdentifier];
    if (workstationGridOffset == null || !mounted) return;

    // Get exact viewport size for dynamic placement
    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.of(context).size;
    }

    // Dynamic placement: reverse-engineered from user's manual framing
    // The inspector panel takes up 40% of the right screen, so our available map area is the left 60%.
    final double availableWidthPixels = viewportSize.width * 0.6;
    final double availableHeightPixels = viewportSize.height;

    // A single desk is exactly 1 cell (100x100 pixels)
    const double contentWidthPixels = gridCellSizePixels;
    const double contentHeightPixels = gridCellSizePixels;

    // Apply ~200px dynamic padding to exactly mimic the lab zoom logic
    final double horizontalScaleFactor = (availableWidthPixels - 200) / contentWidthPixels;
    final double verticalScaleFactor = (availableHeightPixels - 200) / contentHeightPixels;
    final double dynamicTargetScale = min(horizontalScaleFactor, verticalScaleFactor).clamp(0.01, 15.0);

    // Target the center of the available 60% space (which is 30% from the left edge)
    final screenTargetHorizontalPixels = viewportSize.width * 0.3; 
    final screenTargetVerticalPixels = viewportSize.height * 0.5; // Vertical dead-center

    // Calculate the desk's world position on canvas (centering on the 1x1 cell by adding 0.5)
    // Account for coordinate offset (canvas starts at col 2, row 2)
    const double horizontalOffsetPixels = 2.0 * gridCellSizePixels; 
    const double verticalOffsetPixels = 2.0 * gridCellSizePixels; 

    final worldHorizontalPixels = ((workstationGridOffset.dx + 0.5) * gridCellSizePixels) - horizontalOffsetPixels;
    final worldVerticalPixels = ((workstationGridOffset.dy + 0.5) * gridCellSizePixels) - verticalOffsetPixels;

    final translationHorizontalPixels = screenTargetHorizontalPixels - (worldHorizontalPixels * dynamicTargetScale);
    final translationVerticalPixels = screenTargetVerticalPixels - (worldVerticalPixels * dynamicTargetScale);

    // Create target transformation matrix
    final targetTransformationMatrix = Matrix4.identity()
      ..translate(translationHorizontalPixels, translationVerticalPixels)
      ..scale(dynamicTargetScale);

    // Get current matrix
    final currentTransformationMatrix = _transformationController.value.clone();

    // Dispose old controller if exists
    _snapAnimationController?.dispose();

    // iOS-style spring animation - responsive and natural
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosStandardAnimationDuration, // 350ms - iOS standard duration
    );

    // iOS uses a custom spring curve for interactive elements
    // This curve provides a subtle bounce that feels responsive
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: Curves.easeOutCubic, // iOS-style ease out with subtle deceleration
    );

    // Create matrix tween
    _snapAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);

    // Listen to animation and update transformation controller
    _snapAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _snapAnimation!.value;
      }
    });

    // Start animation
    await _snapAnimationController!.forward();
  }

  /// Reset to global overview (all labs visible) with iOS-style animation
  Future<void> resetToGlobalOverview() async {
    if (!mounted) return;

    // Close inspector panel via Riverpod
    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();

    // Clear active desk from localStorage
    CameraStateService.clearActiveDeskState();

    // Calculate global overview matrix
    final targetTransformationMatrix = _calculateGlobalOverviewMatrix();

    // Animate from current position to global overview
    final currentTransformationMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosSlowAnimationDuration, // 450ms - iOS uses slightly longer for "back" actions
    );

    // iOS uses easeInOut for dismissal/back actions - smooth both ways
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseInOutCurve,
    );

    _snapAnimation = Matrix4Tween(
      begin: currentTransformationMatrix,
      end: targetTransformationMatrix,
    ).animate(curvedAnimation);

    _snapAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _snapAnimation!.value;
      }
    });

    await _snapAnimationController!.forward();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESK INTERACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load desk components and trigger snap-to-inspect animation
  Future<void> _loadWorkstationComponents(String workstationIdentifier) async {
    print('🖱️ Desk clicked: $workstationIdentifier');
    print('🔍 Loading components for inspector...');

    // Set selected desk for pulse animation (via Riverpod)
    ref.read(selectedDeskProvider.notifier).selectDesk(workstationIdentifier);

    // Trigger pulse animation (will reset after 250ms - iOS timing)
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(selectedDeskProvider.notifier).clearSelection();
      }
    });

    // Query local repository for this specific workstation
    final workstationComponents = await WorkstationRepository.getWorkstationComponents(workstationIdentifier);

    if (workstationComponents != null && workstationComponents.isNotEmpty) {
      print('✅ Found in local storage: ${workstationComponents.length} components');
      
      // Update Riverpod state
      ref.read(activeDeskProvider.notifier).setActiveDesk(workstationIdentifier);
      ref.read(activeDeskComponentsProvider.notifier).setComponents(workstationComponents);
      ref.read(inspectorStateProvider.notifier).openInspector();

      // Save active desk to localStorage
      CameraStateService.saveActiveDeskState(workstationIdentifier);

      // Snap-to-Inspect: Animate to desk position with spring physics
      await _animateToWorkstationFocus(workstationIdentifier);
    } else {
      print('❌ No assets found in local storage for: $workstationIdentifier');
      
      // Update Riverpod state (empty desk)
      ref.read(activeDeskProvider.notifier).setActiveDesk(workstationIdentifier);
      ref.read(activeDeskComponentsProvider.notifier).clearComponents();
      ref.read(inspectorStateProvider.notifier).openInspector();

      // Save active desk to localStorage
      CameraStateService.saveActiveDeskState(workstationIdentifier);

      // Still snap even if empty
      await _animateToWorkstationFocus(workstationIdentifier);
    }
  }

  /// Handle component drop on a desk
  Future<void> _handleComponentDrop(
    Map<String, dynamic> draggedComponent,
    String targetWorkstationIdentifier,
  ) async {
    // This will be implemented in the parent screen
    // For now, just clear the dragging state
    ref.read(draggingComponentProvider.notifier).clearDragging();
  }

  /// Handle canvas tap in edit mode
  void _processCanvasTap(TapUpDetails tapDetails) {
    if (!widget.isEditMode) return;
    final localTapPosition = tapDetails.localPosition;

    // Account for offset (canvas starts at col 2, row 2)
    const double horizontalOffsetPixels = 2.0;
    const double verticalOffsetPixels = 2.0;

    final int gridColumnNumber = (localTapPosition.dx / gridCellSizePixels).floor() + horizontalOffsetPixels.toInt();
    final int gridRowNumber = (localTapPosition.dy / gridCellSizePixels).floor() + verticalOffsetPixels.toInt();
    final tapGridCoordinates = Offset(gridColumnNumber.toDouble(), gridRowNumber.toDouble());

    setState(() {
      // Toggle: if a desk exists at this cell, remove it; otherwise add one.
      final existingWorkstationIdentifiers = _deskLayouts.entries
          .where((entry) => entry.value == tapGridCoordinates && !entry.key.startsWith('PILLAR_'))
          .map((entry) => entry.key)
          .toList();

      if (existingWorkstationIdentifiers.isNotEmpty) {
        for (final workstationIdentifier in existingWorkstationIdentifiers) {
          _deskLayouts.remove(workstationIdentifier);
        }
      } else {
        // In edit mode, allow adding custom desks
        final customWorkstationIdentifier =
            'CUSTOM_${(_deskLayouts.length + 1).toString().padLeft(3, '0')}';
        _deskLayouts[customWorkstationIdentifier] = tapGridCoordinates;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDERING
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod state for reactive updates
    final isInspectorOpen = ref.watch(inspectorStateProvider);

    // OPTIMIZATION: Removed selectedDeskProvider watch from parent
    // Each DeskWidget now watches it individually with .select()
    // This prevents the entire canvas from rebuilding when a desk is selected

    // Listen for camera control actions
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

    // Listen for inspector state changes to trigger camera animations
    ref.listen<bool>(inspectorStateProvider, (previous, next) {
      // If inspector just closed, reset to global overview
      if (previous == true && next == false) {
        resetToGlobalOverview();
      }
    });

    return _buildInfiniteCanvasView(isInspectorOpen);
  }

  /// Builds the blueprint-style infinite canvas inside the InteractiveViewer.
  Widget _buildInfiniteCanvasView(bool isInspectorOpen) {
    // Canvas sized exactly to lab content (cols 2-33, rows 2-18)
    // 32 columns × 100px = 3200px width
    // 17 rows × 100px = 1700px height
    const double canvasWidthPixels = 3200.0;
    const double canvasHeightPixels = 1700.0;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _processKeyboardEvent,
      autofocus: true,
      child: Listener(
        // Intercept scroll events for smooth zoom
        onPointerSignal: (pointerSignalEvent) {
          // Check if event has scrollDelta property (indicates scroll event)
          try {
            final scrollDelta = (pointerSignalEvent as dynamic).scrollDelta;
            if (scrollDelta != null) {
              _processScrollZoomEvent(pointerSignalEvent);
            }
          } catch (exception) {
            // Not a scroll event, ignore
          }
        },
        child: ClipRect(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.none,
            minScale: 0.01, // Relaxed for "infinite" feel
            maxScale: 20.0, // Relaxed for "infinite" feel
            scaleEnabled: false, // Disable choppy built-in zoom to yield control to custom logic
            panEnabled: !widget.isEditMode && !isInspectorOpen, // Lock pan when inspector open
            onInteractionUpdate: _processInteractionUpdate, // Smooth zoom on pinch/scroll
            child: GestureDetector(
              onTapUp: _processCanvasTap,
              child: Container(
                width: canvasWidthPixels,
                height: canvasHeightPixels,
                color: Theme.of(context).scaffoldBackgroundColor, // Background color based on theme
                // PERFORMANCE: RepaintBoundary caches the grid as a GPU texture
                // The 3200x1700px grid with ~600 lines is expensive to repaint
                // This prevents repainting when desks/drag ghost move above it
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GridPainter(
                      gridCellSizePixels: gridCellSizePixels,
                      gridColor: Theme.of(context).dividerColor, // Grid color based on theme
                    ),
                    child: Stack(
                      // PERFORMANCE: Use cached desk widget list
                      // Generated once in initState, reused on every build
                      children: _cachedDeskWidgets!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),      ),
    );
  }

  /// Handle interaction updates for smooth zoom
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

  /// Handle smooth scroll zoom (cross-platform compatible)
  void _processScrollZoomEvent(dynamic scrollEvent) {
    if (!mounted) return;

    // Access scrollDelta dynamically (works on both web and native)
    final scrollDelta = (scrollEvent as dynamic).scrollDelta;
    if (scrollDelta == null) return;

    // Handle trackpad panning vs mouse wheel zooming
    if ((scrollEvent as dynamic).kind == PointerDeviceKind.trackpad) {
      final double dx = -(scrollDelta.dx as num).toDouble();
      final double dy = -(scrollDelta.dy as num).toDouble();

      final Matrix4 baseTransformationMatrix = _accumulatedTargetMatrix ?? _transformationController.value.clone();
      final double currentScale = baseTransformationMatrix.getMaxScaleOnAxis();

      _accumulatedTargetMatrix = baseTransformationMatrix.clone()..translate(dx / currentScale, dy / currentScale);

      // Animate smoothly towards the accumulated target
      _animateScrollZoomTransformation(_transformationController.value, _accumulatedTargetMatrix!);
      return;
    }

    // Proportional Delta: Calculate zoom factor based on scroll displacement
    // Negative scrollDelta.dy means scroll up (zoom in)
    final double scrollDeltaVerticalPixels = (scrollDelta.dy as num).toDouble();
    
    // Calculate a proportional multiplier (e.g., 0.0015 per pixel)
    // We clamp the multiplier to prevent extreme jumps from high-precision wheels
    final double scrollDeltaMultiplier = (scrollDeltaVerticalPixels * 0.0015).clamp(-0.2, 0.2);
    final double zoomScaleFactor = 1.0 - scrollDeltaMultiplier;

    // Accumulation: Determine starting matrix for the target calculation
    // If an animation is active, we accumulate on top of its target to prevent stutter
    final Matrix4 baseTransformationMatrix = _accumulatedTargetMatrix ?? _transformationController.value.clone();
    final double currentTargetScale = baseTransformationMatrix.getMaxScaleOnAxis();

    // Bound Enforcement: Respect relaxed minScale/maxScale limits
    final double accumulatedTargetScale = (currentTargetScale * zoomScaleFactor).clamp(0.01, 20.0);

    // Get pointer position in widget coordinates for focal point zoom
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final pointerPosition = (scrollEvent as dynamic).position;
    final Offset focalPointPixels = renderBox.globalToLocal(pointerPosition as Offset);

    // Calculate the target matrix centered around the cursor focal point
    _accumulatedTargetMatrix = _calculateZoomTransformationMatrix(
      baseTransformationMatrix,
      currentTargetScale,
      accumulatedTargetScale,
      focalPointPixels,
    );

    // Animate smoothly towards the accumulated target
    _animateScrollZoomTransformation(_transformationController.value, _accumulatedTargetMatrix!);
  }

  /// Calculate zoom matrix around a focal point
  Matrix4 _calculateZoomTransformationMatrix(
    Matrix4 currentMatrix,
    double currentScale,
    double targetScale,
    Offset focalPointPixels,
  ) {
    // Get translation from the provided matrix (could be an accumulated target)
    final currentTranslationVector = currentMatrix.getTranslation();

    // Calculate the point in the scene that's under the focal point
    final worldHorizontalPixels = (focalPointPixels.dx - currentTranslationVector.x) / currentScale;
    final worldVerticalPixels = (focalPointPixels.dy - currentTranslationVector.y) / currentScale;

    // Calculate new translation to keep the scene point under the focal point after scaling
    final targetTranslationHorizontalPixels = focalPointPixels.dx - (worldHorizontalPixels * targetScale);
    final targetTranslationVerticalPixels = focalPointPixels.dy - (worldVerticalPixels * targetScale);

    // Create new matrix
    return Matrix4.identity()
      ..translate(targetTranslationHorizontalPixels, targetTranslationVerticalPixels)
      ..scale(targetScale);
  }

  /// Animate scroll zoom smoothly towards the target
  void _animateScrollZoomTransformation(Matrix4 startMatrix, Matrix4 endMatrix) {
    // Reuse or create the controller
    if (_scrollZoomController == null) {
      _scrollZoomController = AnimationController(
        vsync: this,
        duration: iosScrollZoomAnimationDuration,
      );
    } else {
      // If already animating, we reset but keep the current visual position as start
      _scrollZoomController!.stop();
    }

    // Always animate from current visual state to the latest accumulated target
    _scrollZoomAnimation = Matrix4Tween(
      begin: startMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _scrollZoomController!,
      curve: Curves.easeOutCubic,
    ));

    _scrollZoomAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _scrollZoomAnimation!.value;
      }
    });

    _scrollZoomController!.forward().then((_) {
      // Clear accumulation once we reach the destination
      if (mounted && _scrollZoomController!.isCompleted) {
        _accumulatedTargetMatrix = null;
      }
    });
  }

  /// A pillar (structural obstruction, no interaction).
  Widget _buildStructuralPillar() {
    return Container(
      width: gridCellSizePixels,
      height: gridCellSizePixels,
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280), // Solid gray
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

  /// A single desk tile on the infinite canvas.
  Widget _buildCanvasWorkstation(String workstationIdentifier) {
    return DeskWidget(
      deskId: workstationIdentifier,
      position: _deskLayouts[workstationIdentifier]!,
      cellSize: gridCellSizePixels,
      isEditMode: widget.isEditMode,
      onTap: () => _loadWorkstationComponents(workstationIdentifier),
      onComponentDrop: (component) => _handleComponentDrop(component, workstationIdentifier),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC DESK COORDINATE GENERATION (Master Blueprint)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generates the complete 332-desk coordinate map from the Master Blueprint.
  static Map<String, Offset> _generateDeskCoordinates() {
    final Map<String, Offset> workstationCoordinatesMap = {};

    // Lab 6: B-K (2-11), Rows 2-6, 48 desks
    _addLaboratoryWorkstations(workstationCoordinatesMap, 6, [
      {'row': 2, 'cols': [2, 11], 'start': 1}, // D1-D10
      {'row': 3, 'cols': [2, 11], 'start': 11}, // D11-D20
      {'row': 4, 'cols': [2, 11], 'start': 21}, // D21-D30
      {'row': 5, 'cols': [2, 11], 'start': 31}, // D31-D40
      {'row': 6, 'cols': [2, 9], 'start': 41}, // D41-D48 (ends at I)
    ]);

    // Lab 7: B-G (2-7), Rows 8-9,11-12,14-15,17-18, 48 desks
    _addLaboratoryWorkstations(workstationCoordinatesMap, 7, [
      {'row': 8, 'cols': [2, 7], 'start': 1}, // D1-D6
      {'row': 9, 'cols': [2, 7], 'start': 7}, // D7-D12
      {'row': 11, 'cols': [2, 7], 'start': 13}, // D13-D18
      {'row': 12, 'cols': [2, 7], 'start': 19}, // D19-D24
      {'row': 14, 'cols': [2, 7], 'start': 25}, // D25-D30
      {'row': 15, 'cols': [2, 7], 'start': 31}, // D31-D36
      {'row': 17, 'cols': [2, 7], 'start': 37}, // D37-D42
      {'row': 18, 'cols': [2, 7], 'start': 43}, // D43-D48
    ]);

    // Lab 1: M-T (13-20), Rows 2-3,5-6,8-9, 48 desks
    _addLaboratoryWorkstations(workstationCoordinatesMap, 1, [
      {'row': 2, 'cols': [13, 20], 'start': 1}, // D1-D8
      {'row': 3, 'cols': [13, 20], 'start': 9}, // D9-D16
      {'row': 5, 'cols': [13, 20], 'start': 17}, // D17-D24
      {'row': 6, 'cols': [13, 20], 'start': 25}, // D25-D32
      {'row': 8, 'cols': [13, 20], 'start': 33}, // D33-D40
      {'row': 9, 'cols': [13, 20], 'start': 41}, // D41-D48
    ]);

    // Lab 2: M-T (13-20), Rows 11-12,14-15,17-18, 48 desks
    _addLaboratoryWorkstations(workstationCoordinatesMap, 2, [
      {'row': 11, 'cols': [13, 20], 'start': 1}, // D1-D8
      {'row': 12, 'cols': [13, 20], 'start': 9}, // D9-D16
      {'row': 14, 'cols': [13, 20], 'start': 17}, // D17-D24
      {'row': 15, 'cols': [13, 20], 'start': 25}, // D25-D32
      {'row': 17, 'cols': [13, 20], 'start': 33}, // D33-D40
      {'row': 18, 'cols': [13, 20], 'start': 41}, // D41-D48
    ]);

    // Lab 3: V-AG (22-33), Rows 2-3,5-6, 46 desks (2 pillars at V5, W5)
    _addLaboratoryWorkstations(workstationCoordinatesMap, 3, [
      {'row': 2, 'cols': [22, 33], 'start': 1}, // D1-D12
      {'row': 3, 'cols': [22, 33], 'start': 13}, // D13-D24
      {
        'row': 5,
        'cols': [22, 33],
        'start': 25,
        'pillars': [22, 23]
      }, // D25-D36, skip V5/W5
      {'row': 6, 'cols': [22, 33], 'start': 35}, // D35-D46
    ]);

    // Lab 4: V-AG (22-33), Rows 8-9,11-12, 46 desks (2 pillars at V12, W12)
    _addLaboratoryWorkstations(workstationCoordinatesMap, 4, [
      {'row': 8, 'cols': [22, 33], 'start': 1}, // D1-D12
      {'row': 9, 'cols': [22, 33], 'start': 13}, // D13-D24
      {'row': 11, 'cols': [22, 33], 'start': 25}, // D25-D36 (no pillars on row 11)
      {
        'row': 12,
        'cols': [22, 33],
        'start': 37,
        'pillars': [22, 23]
      }, // D37-D46, skip V12/W12
    ]);

    // Lab 5: V-AG (22-33), Rows 14-15,17-18, 48 desks
    _addLaboratoryWorkstations(workstationCoordinatesMap, 5, [
      {'row': 14, 'cols': [22, 33], 'start': 1}, // D1-D12
      {'row': 15, 'cols': [22, 33], 'start': 13}, // D13-D24
      {'row': 17, 'cols': [22, 33], 'start': 25}, // D25-D36
      {'row': 18, 'cols': [22, 33], 'start': 37}, // D37-D48
    ]);

    // Add pillar markers (non-interactive structural elements)
    workstationCoordinatesMap['PILLAR_V5'] = const Offset(22, 5);
    workstationCoordinatesMap['PILLAR_W5'] = const Offset(23, 5);
    workstationCoordinatesMap['PILLAR_V12'] = const Offset(22, 12);
    workstationCoordinatesMap['PILLAR_W12'] = const Offset(23, 12);

    return workstationCoordinatesMap;
  }

  /// Helper to add a lab's desks to the coordinate map.
  static void _addLaboratoryWorkstations(
    Map<String, Offset> workstationCoordinatesMap,
    int labNumber,
    List<Map<String, dynamic>> rowConfigurations,
  ) {
    for (final rowConfiguration in rowConfigurations) {
      final int rowNumber = rowConfiguration['row'];
      final List<int> columnRange = rowConfiguration['cols'];
      int workstationNumber = rowConfiguration['start'];
      final List<int>? pillarColumnNumbers = rowConfiguration['pillars'];

      for (int columnNumber = columnRange[0]; columnNumber <= columnRange[1]; columnNumber++) {
        // Skip pillars
        if (pillarColumnNumbers != null && pillarColumnNumbers.contains(columnNumber)) {
          continue;
        }

        final workstationIdentifier = 'L${labNumber}_D${workstationNumber.toString().padLeft(2, '0')}';
        workstationCoordinatesMap[workstationIdentifier] = Offset(columnNumber.toDouble(), rowNumber.toDouble());
        workstationNumber++;
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID PAINTER (Custom Paint for Canvas Background)
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
      ..color = gridColor // Thematic grid color
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double horizontalPositionPixels = 0; horizontalPositionPixels <= size.width; horizontalPositionPixels += gridCellSizePixels) {
      canvas.drawLine(Offset(horizontalPositionPixels, 0), Offset(horizontalPositionPixels, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double verticalPositionPixels = 0; verticalPositionPixels <= size.height; verticalPositionPixels += gridCellSizePixels) {
      canvas.drawLine(Offset(0, verticalPositionPixels), Offset(size.width, verticalPositionPixels), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor;
  }
}




