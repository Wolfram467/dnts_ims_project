import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../providers/domain_providers.dart';
import '../providers/repository_providers.dart';
import '../models/hardware_component.dart';
import '../models/workstation_config.dart';
import '../utils/keyboard_shortcuts.dart';
import '../services/camera_state_service.dart';
import 'inspector_panel_widget.dart';
import 'create_component_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PERFORMANCE OPTIMIZATION: CANVAS ENGINE
// High-performance map canvas that renders workstation layouts using
// a unified CustomPainter for "Google Earth" level performance.
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
  // LOCAL UI STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Transformation controller for pan/zoom
  late final TransformationController _transformationController;

  /// Animation controller for camera transitions
  AnimationController? _snapAnimationController;

  /// Minimum allowed scale (calculated to fit all labs)
  double? _minimumAllowedScale;

  /// Current workstation configurations being rendered
  List<WorkstationConfig> _workstationConfigs = [];

  /// Focus node for keyboard shortcuts
  late final FocusNode _keyboardFocusNode;

  /// Timer for debouncing camera state saves
  Timer? _cameraStateSaveDebounceTimer;

  /// Flag to prevent loading state during initialization
  bool _isInitializing = true;

  /// Physics controller for kinetic scrolling
  late AnimationController _physicsController;
  Animation<Offset>? _physicsAnimation;
  Offset _currentPanOffset = Offset.zero;
  double _baseScale = 1.0;

  /// The desk currently being hovered during a drag operation
  String? _hoveredDeskId;
  
  /// Cached viewport size for physics calculations to prevent layout thrashing
  Size _viewportSize = const Size(1920, 1080);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double gridCellSizePixels = 100.0;
  static const double panStepPixels = 200.0; 

  static const Duration iosQuickAnimationDuration = Duration(milliseconds: 300);
  static const Duration iosStandardAnimationDuration = Duration(milliseconds: 350);
  static const Duration iosSlowAnimationDuration = Duration(milliseconds: 450);
  static const Curve iosEaseOutCurve = Curves.easeOut;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _physicsController = AnimationController(vsync: this);
    _physicsController.addListener(() {
      final animValue = _physicsAnimation?.value;
      if (animValue == null) return;
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      _currentPanOffset = _clampOffset(animValue);
      _transformationController.value = Matrix4.identity()
        ..translate(_currentPanOffset.dx, _currentPanOffset.dy)
        ..scale(currentScale);
    });
    
    _physicsController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        CameraStateService.saveCameraState(_transformationController.value);
      }
    });

    _keyboardFocusNode = FocusNode();

    _updateSpatialLayout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialCameraState();
    });
  }

  void _updateSpatialLayout() {
    final spatialManager = ref.read(spatialManagerProvider);
    _workstationConfigs = spatialManager.getLayoutForFacility(widget.facilityId);
  }

  @override
  void didUpdateWidget(MapCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facilityId != widget.facilityId) {
      _updateSpatialLayout();
    }
  }

  Future<void> _loadInitialCameraState() async {
    final savedMatrix = await CameraStateService.loadCameraState();
    final savedWorkstationIdentifier = await CameraStateService.loadActiveDeskState();

    if (!mounted) return;

    _calculateGlobalOverviewMatrix();

    setState(() {
      _isInitializing = false;
    });

    if (savedMatrix != null) {
      _transformationController.value = savedMatrix;
      if (savedWorkstationIdentifier != null) {
        final bool hasDesk = _workstationConfigs.any((config) => config.id == savedWorkstationIdentifier);
        if (hasDesk) {
          await _loadWorkstationComponents(savedWorkstationIdentifier);
        }
      }
    } else {
      _fitAllLabsInView();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _snapAnimationController?.dispose();
    _physicsController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Matrix4 _calculateGlobalOverviewMatrix() {
    Size viewportSize;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      viewportSize = renderBox.size;
    } else {
      viewportSize = MediaQuery.sizeOf(context);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNIVERSAL MOBILE BASELINE
    // Hardcoded to user's exact preferred framing for 915x412 (Landscape)
    // ═══════════════════════════════════════════════════════════════════════════
    if (viewportSize.width < 1100) {
      const double userScale = 0.19405641180156474;
      _minimumAllowedScale = userScale;

      return Matrix4.identity()
        ..translate(93.14321973125783, 14.38255302580356)
        ..scale(userScale);
    }

    // DESKTOP DEFAULT VIEW
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

  void _fitAllLabsInView() {
    if (!mounted) return;
    _transformationController.value = _calculateGlobalOverviewMatrix();
  }

  void _zoomIn() {
    if (!mounted) return;
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(1.2);
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  void _zoomOut() {
    if (!mounted) return;
    final currentTransformationMatrix = _transformationController.value.clone();
    final targetTransformationMatrix = currentTransformationMatrix.clone();
    targetTransformationMatrix.scale(0.8);
    _animateCameraTransformation(currentTransformationMatrix, targetTransformationMatrix, iosQuickAnimationDuration);
  }

  void _animateCameraTransformation(Matrix4 startMatrix, Matrix4 endMatrix, Duration animationDuration) {
    _snapAnimationController?.dispose();
    final animationController = AnimationController(vsync: this, duration: animationDuration);
    _snapAnimationController = animationController;
    final curvedAnimation = CurvedAnimation(parent: animationController, curve: iosEaseOutCurve);
    final matrixAnimation = Matrix4Tween(begin: startMatrix, end: endMatrix).animate(curvedAnimation);
    matrixAnimation.addListener(() {
      if (mounted) _transformationController.value = matrixAnimation.value;
    });
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        CameraStateService.saveCameraState(_transformationController.value);
      }
    });
    animationController.forward();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERACTION LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  KeyEventResult _processKeyboardEvent(FocusNode focusNode, KeyEvent keyboardEvent) {
    if (keyboardEvent is! KeyDownEvent) return KeyEventResult.ignored;
    final shortcutAction = KeyboardShortcuts.getAction(keyboardEvent);
    if (shortcutAction == null) return KeyEventResult.ignored;
    _executeKeyboardShortcut(shortcutAction);
    return KeyEventResult.handled;
  }

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
        if (ref.read(inspectorStateProvider)) return;
        _zoomIn();
        break;
      case MapShortcutAction.zoomOut:
        if (ref.read(inspectorStateProvider)) return;
        _zoomOut();
        break;
      case MapShortcutAction.fitAllLabs:
        _fitAllLabsInView();
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

  void _processInspectorCloseRequest() {
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) {
      resetToGlobalOverview();
    }
  }

  void _panCameraView(double horizontalDeltaPixels, double verticalDeltaPixels) {
    if (ref.read(inspectorStateProvider) || !mounted) return;
    final currentTransformationMatrix = _transformationController.value.clone();
    currentTransformationMatrix.translate(horizontalDeltaPixels, verticalDeltaPixels);
    _transformationController.value = currentTransformationMatrix;
  }

  Future<void> _transitionToLaboratory(int labNumber) async {
    final labPrefix = 'L${labNumber}_D';
    final labConfigs = _workstationConfigs.where((config) => config.id.startsWith(labPrefix)).toList();
    if (labConfigs.isEmpty) return;

    final minX = labConfigs.map((config) => config.dx).reduce(min);
    final maxX = labConfigs.map((config) => config.dx).reduce(max);
    final minY = labConfigs.map((config) => config.dy).reduce(min);
    final maxY = labConfigs.map((config) => config.dy).reduce(max);

    Size viewportSize = (context.findRenderObject() as RenderBox?)?.size ?? MediaQuery.of(context).size;

    final double contentWidth = (maxX - minX + 1) * gridCellSizePixels;
    final double contentHeight = (maxY - minY + 1) * gridCellSizePixels;

    final double targetScale = min((viewportSize.width - 200) / contentWidth, (viewportSize.height - 200) / contentHeight).clamp(_minimumAllowedScale ?? 0.1, 5.0);
    await _animateToWorldPosition((minX + maxX + 1) / 2, (minY + maxY + 1) / 2, targetScale);
  }

  void _cycleWorkstationInCurrentLaboratory({required bool forward}) {
    final activeId = ref.read(activeDeskProvider);
    if (activeId == null) return;
    final match = RegExp(r'L(\d+)_D').firstMatch(activeId);
    if (match == null) return;
    final labPrefix = 'L${match.group(1)}_D';
    final labIds = _workstationConfigs.where((config) => config.id.startsWith(labPrefix)).map((config) => config.id).toList()..sort();
    final currentIndex = labIds.indexOf(activeId);
    if (currentIndex == -1) return;
    final nextIndex = forward ? (currentIndex + 1) % labIds.length : (currentIndex - 1 + labIds.length) % labIds.length;
    _loadWorkstationComponents(labIds[nextIndex]);
  }

  Future<void> _animateToWorldPosition(double column, double row, double scale) async {
    if (!mounted) return;
    Size viewportSize = (context.findRenderObject() as RenderBox?)?.size ?? MediaQuery.of(context).size;

    const double offset = 2.0 * gridCellSizePixels;
    final worldX = (column * gridCellSizePixels) - offset;
    final worldY = (row * gridCellSizePixels) - offset;

    final targetMatrix = Matrix4.identity()
      ..translate((viewportSize.width * 0.5) - (worldX * scale), (viewportSize.height * 0.5) - (worldY * scale))
      ..scale(scale);

    _animateCameraTransformation(_transformationController.value, targetMatrix, iosQuickAnimationDuration);
  }

  Future<void> _animateToWorkstationFocus(String deskId) async {
    final config = _workstationConfigs.firstWhere((c) => c.id == deskId, orElse: () => const WorkstationConfig(id: '', dx: 0, dy: 0));
    if (config.id.isEmpty || !mounted) return;

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEWPORT-AWARE CENTERING (CRITICAL FOR CALIBRATION)
    // We MUST use the actual widget size (RenderBox) rather than Screen size
    // to account for Navigation Rails, App Bars, and Docks.
    // ═══════════════════════════════════════════════════════════════════════════
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Size widgetSize = renderBox?.size ?? MediaQuery.sizeOf(context);
    final isCompact = widgetSize.width < 1100;
    
    // Target Proportions based on User Calibration (842x355 Viewport)
    // User requested Scale: 2.0847, TransX: 134.49, TransY: 71.07 for Desk (50, 50)
    // targetXFactor = (134.49 + (50 * 2.0847)) / 842 ≈ 0.2835
    // targetYFactor = (71.07 + (50 * 2.0847)) / 355 ≈ 0.4938
    final double targetXFactor = isCompact ? 0.2835 : 0.30;
    final double targetYFactor = isCompact ? 0.4938 : 0.50;
    
    // Scale: 2.0847 for 355px widget height. 
    // We target ~58.7% of the widget height for the desk grid cell.
    final double targetScale = isCompact 
        ? (widgetSize.height * 0.5872) / gridCellSizePixels
        : min((widgetSize.width * 0.6 - 200) / gridCellSizePixels, (widgetSize.height - 200) / gridCellSizePixels);
    
    final clampedScale = targetScale.clamp(_minimumAllowedScale ?? 0.1, 10.0);

    const double offset = 2.0 * gridCellSizePixels;
    final worldX = ((config.dx + 0.5) * gridCellSizePixels) - offset;
    final worldY = ((config.dy + 0.5) * gridCellSizePixels) - offset;

    final targetMatrix = Matrix4.identity()
      ..translate((widgetSize.width * targetXFactor) - (worldX * clampedScale), (widgetSize.height * targetYFactor) - (worldY * clampedScale))
      ..scale(clampedScale);

    _animateCameraTransformation(_transformationController.value, targetMatrix, iosStandardAnimationDuration);
  }

  Future<void> resetToGlobalOverview() async {
    if (!mounted) return;
    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(selectedDeskProvider.notifier).clearSelection();
    CameraStateService.clearActiveDeskState();
    _animateCameraTransformation(_transformationController.value, _calculateGlobalOverviewMatrix(), iosSlowAnimationDuration);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESK INTERACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadWorkstationComponents(String deskId) async {
    if (ref.read(isLocationPickingModeProvider)) {
      ref.read(isLocationPickingModeProvider.notifier).state = false;
      showDialog(context: context, builder: (_) => CreateComponentDialog(initialLocation: deskId));
      return;
    }

    ref.read(selectedDeskProvider.notifier).selectDesk(deskId);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(selectedDeskProvider.notifier).clearSelection();
    });

    ref.read(activeDeskProvider.notifier).setActiveDesk(deskId);
    CameraStateService.saveActiveDeskState(deskId);
    await _animateToWorkstationFocus(deskId);

    if (MediaQuery.of(context).size.width < 600) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const InspectorPanelWidget(isMobile: true),
        ).then((_) {
          if (mounted) {
            ref.read(activeDeskProvider.notifier).clearActiveDesk();
            ref.read(selectedDeskProvider.notifier).clearSelection();
            CameraStateService.clearActiveDeskState();
          }
        });
      }
    } else {
      ref.read(inspectorStateProvider.notifier).openInspector();
    }
  }

  Future<void> _handleComponentDrop(HardwareComponent component, String deskId) async {
    final sourceId = ref.read(sourceWorkstationProvider);
    if (sourceId == null || sourceId == deskId) {
      ref.read(draggingComponentProvider.notifier).clearDragging();
      return;
    }

    final result = await ref.read(inventoryManagerProvider).moveComponent(
      componentId: component.dntsSerial,
      toWorkstationId: deskId,
    );

    result.fold(
      (success) {
        ref.read(refreshTriggerProvider.notifier).state++;
        final activeId = ref.read(activeDeskProvider);
        if (activeId != null && (activeId == sourceId || activeId == deskId)) {
          _loadWorkstationComponents(activeId);
        }
      },
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Move failed: $failure')));
        }
      },
    );
    ref.read(draggingComponentProvider.notifier).clearDragging();
    ref.read(sourceWorkstationProvider.notifier).state = null;
  }

  void _handleCanvasTap(TapUpDetails details, Matrix4 matrix) {
    if (widget.isEditMode) {
      _processCanvasTap(details, matrix);
      return;
    }
    final desk = _getDeskAtPosition(details.localPosition, matrix);
    if (desk != null && !desk.id.startsWith('PILLAR_')) {
      _loadWorkstationComponents(desk.id);
    }
  }

  WorkstationConfig? _getDeskAtPosition(Offset localPosition, Matrix4 matrix) {
    final invertedMatrix = Matrix4.inverted(matrix);
    final worldPosition = MatrixUtils.transformPoint(invertedMatrix, localPosition);

    for (final config in _workstationConfigs) {
      const double offset = 2.0 * gridCellSizePixels;
      final rect = Rect.fromLTWH(
        (config.dx * gridCellSizePixels) - offset,
        (config.dy * gridCellSizePixels) - offset,
        gridCellSizePixels,
        gridCellSizePixels,
      );
      if (rect.contains(worldPosition)) return config;
    }
    return null;
  }

  void _processCanvasTap(TapUpDetails details, Matrix4 matrix) {
    if (!widget.isEditMode) return;
    
    final invertedMatrix = Matrix4.inverted(matrix);
    final worldPosition = MatrixUtils.transformPoint(invertedMatrix, details.localPosition);
    
    final col = (worldPosition.dx / gridCellSizePixels).floor() + 2;
    final row = (worldPosition.dy / gridCellSizePixels).floor() + 2;
    setState(() {
      final existing = _workstationConfigs.where((c) => c.dx == col && c.dy == row && !c.id.startsWith('PILLAR_')).toList();
      if (existing.isNotEmpty) {
        for (final e in existing) _workstationConfigs.remove(e);
      } else {
        _workstationConfigs.add(WorkstationConfig(id: 'CUSTOM_${(_workstationConfigs.length + 1).toString().padLeft(3, '0')}', dx: col.toDouble(), dy: row.toDouble()));
      }
    });
  }

  void _displayKeyboardShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CLOSE'))],
      ),
    );
  }

  Widget _buildKeyboardShortcutHelpEntry(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade200, border: Border.all(color: Colors.black)),
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(desc)),
        ],
      ),
    );
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
        case CameraAction.fitAllLabs: _fitAllLabsInView(); break;
        case CameraAction.zoomIn: _zoomIn(); break;
        case CameraAction.zoomOut: _zoomOut(); break;
        case CameraAction.resetToGlobalOverview: resetToGlobalOverview(); break;
      }
    });

    ref.listen<bool>(inspectorStateProvider, (previous, next) {
      if (previous == true && next == false) resetToGlobalOverview();
    });

    return _buildInfiniteCanvasView(isInspectorOpen);
  }

  Widget _buildInfiniteCanvasView(bool isInspectorOpen) {
    const double canvasWidth = 3200.0;
    const double canvasHeight = 1700.0;
    final inventory = ref.watch(facilityInventoryProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedDeskProvider);
    final activeId = ref.watch(activeDeskProvider);

    _viewportSize = MediaQuery.sizeOf(context);

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _processKeyboardEvent,
      autofocus: true,
      child: Listener(
        onPointerSignal: (signal) {
          // TEMPORARY: Allow movement even if inspector is open for calibration
          if (signal is PointerScrollEvent) _processScrollZoomEvent(signal);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _physicsController.stop();
            final translation = _transformationController.value.getTranslation();
            _currentPanOffset = Offset(translation.x, translation.y);
            _baseScale = _transformationController.value.getMaxScaleOnAxis();
          },
          onScaleUpdate: (details) {
            if (widget.isEditMode) return; // Still block in edit mode
            
            // TEMPORARY: Remove zoom restriction when a desk is being inspected (activeId != null)
            // to allow for manual framing calibration.
            final minScale = activeId != null ? 0.05 : (_minimumAllowedScale ?? 0.1);
            final targetScale = (_baseScale * details.scale).clamp(minScale, 5.0);
            
            _currentPanOffset += details.focalPointDelta;
            
            final currentScale = _transformationController.value.getMaxScaleOnAxis();
            if (currentScale != targetScale) {
              final focalPoint = details.localFocalPoint;
              final ratio = targetScale / currentScale;
              _currentPanOffset = focalPoint - (focalPoint - _currentPanOffset) * ratio;
            }
            
            _currentPanOffset = _clampOffset(_currentPanOffset);
            _transformationController.value = Matrix4.identity()..translate(_currentPanOffset.dx, _currentPanOffset.dy)..scale(targetScale);
          },
          onScaleEnd: (details) {
            if (widget.isEditMode) return; // Still block in edit mode
            final velocity = details.velocity.pixelsPerSecond;
            if (velocity.distance < 50.0) {
              CameraStateService.saveCameraState(_transformationController.value);
              return;
            }
            _physicsAnimation = Tween<Offset>(begin: _currentPanOffset, end: _currentPanOffset + velocity * 0.2).animate(CurvedAnimation(parent: _physicsController, curve: Curves.easeOutCirc));
            _physicsController.duration = const Duration(milliseconds: 800);
            _physicsController.forward(from: 0.0);
          },
          child: ClipRect(
            child: SizedBox.expand(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: DragTarget<HardwareComponent>(
                  onWillAcceptWithDetails: (details) => true,
                  onMove: (details) {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(details.offset);
                    final matrix = _transformationController.value;
                    final desk = _getDeskAtPosition(localPos, matrix);
                    if (desk?.id != _hoveredDeskId) setState(() => _hoveredDeskId = desk?.id);
                  },
                  onLeave: (_) => setState(() => _hoveredDeskId = null),
                  onAcceptWithDetails: (details) {
                    if (_hoveredDeskId != null) _handleComponentDrop(details.data, _hoveredDeskId!);
                    setState(() => _hoveredDeskId = null);
                  },
                  builder: (context, _, __) {
                    return GestureDetector(
                      onTapUp: (details) => _handleCanvasTap(details, _transformationController.value),
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _transformationController,
                        builder: (context, matrix, child) {
                          return Transform(
                            transform: matrix,
                            child: child,
                          );
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(canvasWidth, canvasHeight),
                            painter: LabLayoutPainter(
                              configs: _workstationConfigs,
                              inventory: inventory,
                              selectedDeskId: selectedId,
                              hoveredDeskId: _hoveredDeskId,
                              gridCellSizePixels: gridCellSizePixels,
                              transformMatrix: Matrix4.identity(),
                              theme: Theme.of(context),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _processScrollZoomEvent(PointerScrollEvent signal) {
    if (!mounted) return;
    _physicsController.stop();

    if (signal.kind == PointerDeviceKind.trackpad) {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      _currentPanOffset = _clampOffset(_currentPanOffset - signal.scrollDelta);
      _transformationController.value = Matrix4.identity()..translate(_currentPanOffset.dx, _currentPanOffset.dy)..scale(scale);
      return;
    }

    final double zoomFactor = 1.0 - (signal.scrollDelta.dy * 0.0015).clamp(-0.2, 0.2);
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * zoomFactor).clamp(_minimumAllowedScale ?? 0.1, 5.0);

    if (currentScale == targetScale) return;

    final focalPoint = signal.localPosition;
    final ratio = targetScale / currentScale;
    _currentPanOffset = _clampOffset(focalPoint - (focalPoint - _currentPanOffset) * ratio);
    _transformationController.value = Matrix4.identity()..translate(_currentPanOffset.dx, _currentPanOffset.dy)..scale(targetScale);
  }

  Offset _clampOffset(Offset target) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final double w = 3200.0 * scale, h = 1700.0 * scale;
    final double minDx = _viewportSize.width - w - _viewportSize.width / 2, maxDx = _viewportSize.width / 2;
    final double minDy = _viewportSize.height - h - _viewportSize.height / 2, maxDy = _viewportSize.height / 2;
    return Offset(target.dx.clamp(min(minDx, maxDx), max(minDx, maxDx)), target.dy.clamp(min(minDy, maxDy), max(minDy, maxDy)));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAB LAYOUT PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class LabLayoutPainter extends CustomPainter {
  final List<WorkstationConfig> configs;
  final List<Map<String, dynamic>> inventory;
  final String? selectedDeskId;
  final String? hoveredDeskId;
  final double gridCellSizePixels;
  final Matrix4 transformMatrix;
  final ThemeData theme;

  LabLayoutPainter({
    required this.configs,
    required this.inventory,
    this.selectedDeskId,
    this.hoveredDeskId,
    required this.gridCellSizePixels,
    required this.transformMatrix,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transformMatrix.storage);

    final scale = transformMatrix.getMaxScaleOnAxis();
    final translation = transformMatrix.getTranslation();
    final viewport = Rect.fromLTWH(-translation.x / scale, -translation.y / scale, size.width / scale, size.height / scale);

    _drawGrid(canvas, viewport);

    for (final config in configs) {
      final rect = Rect.fromLTWH((config.dx * gridCellSizePixels) - 200, (config.dy * gridCellSizePixels) - 200, gridCellSizePixels, gridCellSizePixels);
      if (!viewport.overlaps(rect)) continue;

      if (config.id.startsWith('PILLAR_')) {
        _drawPillar(canvas, rect);
      } else {
        _drawDesk(canvas, rect, config.id, scale);
      }
    }
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Rect viewport) {
    final paint = Paint()..color = theme.dividerColor..strokeWidth = 0.5;
    final startX = (viewport.left / gridCellSizePixels).floor() * gridCellSizePixels;
    final endX = (viewport.right / gridCellSizePixels).ceil() * gridCellSizePixels;
    final startY = (viewport.top / gridCellSizePixels).floor() * gridCellSizePixels;
    final endY = (viewport.bottom / gridCellSizePixels).ceil() * gridCellSizePixels;

    for (double x = startX; x <= endX; x += gridCellSizePixels) canvas.drawLine(Offset(x, viewport.top), Offset(x, viewport.bottom), paint);
    for (double y = startY; y <= endY; y += gridCellSizePixels) canvas.drawLine(Offset(viewport.left, y), Offset(viewport.right, y), paint);
  }

  void _drawPillar(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFF6B7280));
    canvas.drawRect(rect, Paint()..color = const Color(0xFFD1D5DB)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final iconPaint = Paint()..color = const Color(0xFF9CA3AF)..strokeWidth = 2.0;
    canvas.drawLine(rect.topLeft + const Offset(20, 20), rect.bottomRight - const Offset(20, 20), iconPaint);
    canvas.drawLine(rect.topRight + const Offset(-20, 20), rect.bottomLeft - const Offset(-20, 20), iconPaint);
  }

  void _drawDesk(Canvas canvas, Rect rect, String deskId, double scale) {
    final isSelected = selectedDeskId == deskId;
    final isHovered = hoveredDeskId == deskId;
    
    canvas.drawRect(rect, Paint()..color = theme.colorScheme.surface);
    canvas.drawRect(rect, Paint()..color = isSelected || isHovered ? theme.colorScheme.primary : theme.dividerColor..style = PaintingStyle.stroke..strokeWidth = isSelected || isHovered ? 3.0 : 1.0);

    if (inventory.any((asset) => asset['location']?['name'] == deskId)) {
      canvas.drawCircle(rect.topRight + const Offset(-10, 10), 4, Paint()..color = const Color(0xFF0055FF));
    }

    if (scale > 0.4) {
      final tp = TextPainter(text: TextSpan(text: deskId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant LabLayoutPainter old) => old.transformMatrix != transformMatrix || old.selectedDeskId != selectedDeskId || old.hoveredDeskId != hoveredDeskId || old.inventory != inventory || old.configs != configs;
}
