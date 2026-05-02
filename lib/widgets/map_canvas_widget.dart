import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../utils/workstation_storage.dart';
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
  double? _minAllowedScale;

  /// Desk coordinate map (Master Blueprint: 332 desks across 7 labs)
  final Map<String, Offset> deskLayouts = _generateDeskCoordinates();

  /// Cached list of desk widgets (generated once, reused on every build)
  /// PERFORMANCE: Prevents re-mapping deskLayouts.entries on every rebuild
  List<Widget>? _cachedDeskWidgets;

  /// Focus node for keyboard shortcuts
  late final FocusNode _focusNode;

  /// Timer for debouncing camera state saves
  Timer? _saveStateTimer;

  /// Flag to prevent loading state during initialization
  bool _isInitializing = true;

  /// Scroll zoom animation controller
  AnimationController? _scrollZoomController;
  Animation<Matrix4>? _scrollZoomAnimation;
  
  /// Target scale for smooth scroll zoom
  double? _targetScrollScale;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double gridCellSize = 100.0;
  static const double inspectorZoomLevel = 2.5;
  static const double panStep = 200.0; // Pixels to pan per arrow key press

  // iOS-style animation constants
  static const Duration iosQuickDuration = Duration(milliseconds: 300);
  static const Duration iosStandardDuration = Duration(milliseconds: 350);
  static const Duration iosSlowDuration = Duration(milliseconds: 450);
  static const Duration iosScrollZoomDuration = Duration(milliseconds: 150); // Faster for scroll
  static const Curve iosEaseOut = Curves.easeOut;
  static const Curve iosEaseInOut = Curves.easeInOut;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_enforceMinScale);
    _transformationController.addListener(_onCameraChanged);

    // Initialize focus node for keyboard shortcuts
    _focusNode = FocusNode();

    // PERFORMANCE: Pre-generate desk widgets once
    // This list is static and doesn't depend on reactive state
    _cachedDeskWidgets = _buildDeskWidgetList();

    // Load saved camera state or fit all labs after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialState();
    });
  }

  /// Load initial camera state from localStorage or fit all labs
  Future<void> _loadInitialState() async {
    final savedMatrix = await CameraStateService.loadCameraState();
    final savedDeskId = await CameraStateService.loadActiveDeskState();

    if (!mounted) return;

    setState(() {
      _isInitializing = false;
    });

    if (savedMatrix != null) {
      // Restore saved camera position
      _transformationController.value = savedMatrix;
      print('📂 Restored camera state');

      // If there was an active desk, restore it
      if (savedDeskId != null && deskLayouts.containsKey(savedDeskId)) {
        await _loadDeskComponents(savedDeskId);
      }
    } else {
      // No saved state, fit all labs
      _fitAllLabs();
    }
  }

  /// Called when camera transformation changes (debounced save)
  void _onCameraChanged() {
    if (_isInitializing) return;

    // Debounce: only save after 500ms of no changes
    _saveStateTimer?.cancel();
    _saveStateTimer = Timer(const Duration(milliseconds: 500), () {
      CameraStateService.saveCameraState(_transformationController.value);
    });
  }

  /// Build the list of desk widgets once (called in initState)
  /// PERFORMANCE: Prevents re-mapping 332 desks on every rebuild
  List<Widget> _buildDeskWidgetList() {
    const double offsetX = 2.0 * gridCellSize; // 200px
    const double offsetY = 2.0 * gridCellSize; // 200px

    return deskLayouts.entries.map((entry) {
      final id = entry.key;
      final cell = entry.value;

      // Adjust position by subtracting offset (shift from col 2, row 2 to 0, 0)
      final adjustedX = (cell.dx * gridCellSize) - offsetX;
      final adjustedY = (cell.dy * gridCellSize) - offsetY;

      // Render pillars differently
      if (id.startsWith('PILLAR_')) {
        return Positioned(
          left: adjustedX,
          top: adjustedY,
          child: _buildPillar(),
        );
      }

      return Positioned(
        left: adjustedX,
        top: adjustedY,
        child: _buildCanvasDesk(id),
      );
    }).toList();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_enforceMinScale);
    _transformationController.removeListener(_onCameraChanged);
    _transformationController.dispose();
    _snapAnimationController?.dispose();
    _scrollZoomController?.dispose();
    _focusNode.dispose();
    _saveStateTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZOOM CONSTRAINT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enforce minimum scale constraint (prevent zooming out too far)
  void _enforceMinScale() {
    if (_minAllowedScale == null) return;

    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    if (currentScale < _minAllowedScale!) {
      // Scale is too small, clamp it to minimum
      final clampedMatrix = matrix.clone();
      final scaleFactor = _minAllowedScale! / currentScale;
      clampedMatrix.scale(scaleFactor);
      _transformationController.value = clampedMatrix;
    }
  }

  /// Fit all laboratories in view (used for initial load and reset)
  void _fitAllLabs() {
    if (!mounted) return;

    // Actual lab bounds: Columns 2-33 (B-AG), Rows 2-18
    const double minCol = 2.0;
    const double maxCol = 33.0;
    const double minRow = 2.0;
    const double maxRow = 18.0;

    final double contentWidth = (maxCol - minCol + 1) * gridCellSize;
    final double contentHeight = (maxRow - minRow + 1) * gridCellSize;

    final screenSize = MediaQuery.of(context).size;

    // Calculate scale to fit all content with padding
    final double scaleX = (screenSize.width * 0.9) / contentWidth;
    final double scaleY = (screenSize.height * 0.9) / contentHeight;
    final double scale = min(scaleX, scaleY);

    // Set this as the minimum allowed scale
    _minAllowedScale = scale;

    // Calculate center of content in world coordinates
    final double contentCenterX = (minCol + maxCol) / 2 * gridCellSize;
    final double contentCenterY = (minRow + maxRow) / 2 * gridCellSize;

    // Calculate screen center
    final double screenCenterX = screenSize.width / 2;
    final double screenCenterY = screenSize.height / 2;

    // Calculate translation to center content
    final double translateX = screenCenterX - (contentCenterX * scale);
    final double translateY = screenCenterY - (contentCenterY * scale);

    final targetMatrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(scale);

    _transformationController.value = targetMatrix;
  }

  /// Zoom in by 20% with iOS-style animation
  void _zoomIn() {
    if (!mounted) return;
    
    final currentMatrix = _transformationController.value.clone();
    final targetMatrix = currentMatrix.clone();
    targetMatrix.scale(1.2);
    
    _animateMatrixChange(currentMatrix, targetMatrix, iosQuickDuration);
  }

  /// Zoom out by 20% with iOS-style animation
  void _zoomOut() {
    if (!mounted) return;
    
    final currentMatrix = _transformationController.value.clone();
    final targetMatrix = currentMatrix.clone();
    targetMatrix.scale(0.8);
    
    _animateMatrixChange(currentMatrix, targetMatrix, iosQuickDuration);
  }

  /// Animate matrix change with iOS-style curve
  void _animateMatrixChange(Matrix4 begin, Matrix4 end, Duration duration) {
    _snapAnimationController?.dispose();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: duration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseOut,
    );

    _snapAnimation = Matrix4Tween(
      begin: begin,
      end: end,
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
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final action = KeyboardShortcuts.getAction(event);
    if (action == null) return KeyEventResult.ignored;

    _executeShortcutAction(action);
    return KeyEventResult.handled;
  }

  /// Execute keyboard shortcut action
  void _executeShortcutAction(MapShortcutAction action) {
    switch (action) {
      case MapShortcutAction.closeInspector:
        _handleCloseInspector();
        break;
      case MapShortcutAction.panUp:
        _panCamera(0, -panStep);
        break;
      case MapShortcutAction.panDown:
        _panCamera(0, panStep);
        break;
      case MapShortcutAction.panLeft:
        _panCamera(-panStep, 0);
        break;
      case MapShortcutAction.panRight:
        _panCamera(panStep, 0);
        break;
      case MapShortcutAction.zoomIn:
        _zoomIn();
        _showShortcutFeedback('Zoom In');
        break;
      case MapShortcutAction.zoomOut:
        _zoomOut();
        _showShortcutFeedback('Zoom Out');
        break;
      case MapShortcutAction.fitAllLabs:
        _fitAllLabs();
        _showShortcutFeedback('Fit All Labs');
        break;
      case MapShortcutAction.jumpToLab1:
        _jumpToLab(1);
        break;
      case MapShortcutAction.jumpToLab2:
        _jumpToLab(2);
        break;
      case MapShortcutAction.jumpToLab3:
        _jumpToLab(3);
        break;
      case MapShortcutAction.jumpToLab4:
        _jumpToLab(4);
        break;
      case MapShortcutAction.jumpToLab5:
        _jumpToLab(5);
        break;
      case MapShortcutAction.jumpToLab6:
        _jumpToLab(6);
        break;
      case MapShortcutAction.jumpToLab7:
        _jumpToLab(7);
        break;
      case MapShortcutAction.cycleDeskNext:
        _cycleDeskInCurrentLab(forward: true);
        break;
      case MapShortcutAction.cycleDeskPrevious:
        _cycleDeskInCurrentLab(forward: false);
        break;
      case MapShortcutAction.showHelp:
        _showKeyboardShortcutsHelp();
        break;
    }
  }

  /// Handle close inspector shortcut
  void _handleCloseInspector() {
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) {
      resetToGlobalOverview();
      _showShortcutFeedback('Inspector Closed');
    }
  }

  /// Pan camera by delta pixels
  void _panCamera(double dx, double dy) {
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) return; // Don't pan when inspector is open

    if (!mounted) return;
    final matrix = _transformationController.value.clone();
    matrix.translate(dx, dy);
    _transformationController.value = matrix;
  }

  /// Jump to a specific lab
  Future<void> _jumpToLab(int labNumber) async {
    // Get first desk in the lab
    final labDesks = deskLayouts.keys
        .where((id) => id.startsWith('L${labNumber}_D'))
        .toList()
      ..sort();

    if (labDesks.isEmpty) {
      _showShortcutFeedback('Lab $labNumber not found');
      return;
    }

    // Calculate lab bounds
    final labDeskOffsets = labDesks.map((id) => deskLayouts[id]!).toList();
    final minCol = labDeskOffsets.map((o) => o.dx).reduce((a, b) => a < b ? a : b);
    final maxCol = labDeskOffsets.map((o) => o.dx).reduce((a, b) => a > b ? a : b);
    final minRow = labDeskOffsets.map((o) => o.dy).reduce((a, b) => a < b ? a : b);
    final maxRow = labDeskOffsets.map((o) => o.dy).reduce((a, b) => a > b ? a : b);

    // Calculate center of lab
    final centerCol = (minCol + maxCol) / 2;
    final centerRow = (minRow + maxRow) / 2;

    // Animate to lab center
    await _animateToPosition(centerCol, centerRow, 1.5);
    _showShortcutFeedback('Lab $labNumber');
  }

  /// Cycle through desks in current lab
  void _cycleDeskInCurrentLab({required bool forward}) {
    final activeDeskId = ref.read(activeDeskProvider);
    
    if (activeDeskId == null) {
      _showShortcutFeedback('No active desk');
      return;
    }

    // Extract lab number from current desk
    final labMatch = RegExp(r'L(\d+)_D').firstMatch(activeDeskId);
    if (labMatch == null) return;

    final labNumber = int.parse(labMatch.group(1)!);

    // Get all desks in this lab
    final labDesks = deskLayouts.keys
        .where((id) => id.startsWith('L${labNumber}_D'))
        .toList()
      ..sort();

    if (labDesks.isEmpty) return;

    // Find current desk index
    final currentIndex = labDesks.indexOf(activeDeskId);
    if (currentIndex == -1) return;

    // Calculate next index
    int nextIndex;
    if (forward) {
      nextIndex = (currentIndex + 1) % labDesks.length;
    } else {
      nextIndex = (currentIndex - 1 + labDesks.length) % labDesks.length;
    }

    final nextDeskId = labDesks[nextIndex];
    _loadDeskComponents(nextDeskId);
    _showShortcutFeedback(nextDeskId);
  }

  /// Animate camera to a specific position
  Future<void> _animateToPosition(double col, double row, double zoom) async {
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final targetX = screenSize.width * 0.5;
    final targetY = screenSize.height * 0.5;

    const double offsetX = 2.0 * gridCellSize;
    const double offsetY = 2.0 * gridCellSize;

    final worldX = (col * gridCellSize) - offsetX;
    final worldY = (row * gridCellSize) - offsetY;

    final translationX = targetX - (worldX * zoom);
    final translationY = targetY - (worldY * zoom);

    final targetMatrix = Matrix4.identity()
      ..translate(translationX, translationY)
      ..scale(zoom);

    final currentMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosQuickDuration, // iOS-style quick navigation
    );

    // iOS uses easeOut for navigation - starts fast, ends smoothly
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseOut,
    );

    _snapAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(curvedAnimation);

    _snapAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _snapAnimation!.value;
      }
    });

    await _snapAnimationController!.forward();
  }

  /// Show keyboard shortcut feedback
  void _showShortcutFeedback(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
  void _showKeyboardShortcutsHelp() {
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
              _buildShortcutRow('ESC', 'Close Inspector / Return to Overview'),
              _buildShortcutRow('Arrow Keys', 'Pan Camera'),
              _buildShortcutRow('+/-', 'Zoom In/Out'),
              _buildShortcutRow('Space', 'Fit All Labs'),
              _buildShortcutRow('1-7', 'Jump to Lab 1-7'),
              _buildShortcutRow('Tab', 'Next Desk in Lab'),
              _buildShortcutRow('Shift+Tab', 'Previous Desk in Lab'),
              _buildShortcutRow('?', 'Show This Help'),
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

  Widget _buildShortcutRow(String key, String description) {
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
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SNAP-TO-INSPECT ANIMATION (Kinetic Motion Engine)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Snap-to-Inspect: Animate camera with iOS-style spring physics
  Future<void> _snapToDesk(String deskId) async {
    final deskOffset = deskLayouts[deskId];
    if (deskOffset == null || !mounted) return;

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final targetX = screenSize.width * 0.3; // 30% from left (center-left)
    final targetY = screenSize.height * 0.5; // Vertical center

    // Calculate the desk's world position on canvas
    // Account for coordinate offset (canvas starts at col 2, row 2)
    const double offsetX = 2.0 * gridCellSize; // 200px
    const double offsetY = 2.0 * gridCellSize; // 200px

    final deskWorldX = (deskOffset.dx * gridCellSize) - offsetX;
    final deskWorldY = (deskOffset.dy * gridCellSize) - offsetY;

    final translationX = targetX - (deskWorldX * inspectorZoomLevel);
    final translationY = targetY - (deskWorldY * inspectorZoomLevel);

    // Create target transformation matrix
    final targetMatrix = Matrix4.identity()
      ..translate(translationX, translationY)
      ..scale(inspectorZoomLevel);

    // Get current matrix
    final currentMatrix = _transformationController.value.clone();

    // Dispose old controller if exists
    _snapAnimationController?.dispose();

    // iOS-style spring animation - responsive and natural
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosStandardDuration, // 350ms - iOS standard duration
    );

    // iOS uses a custom spring curve for interactive elements
    // This curve provides a subtle bounce that feels responsive
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: Curves.easeOutCubic, // iOS-style ease out with subtle deceleration
    );

    // Create matrix tween
    _snapAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
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

    // Calculate global overview matrix (fit all labs in view)
    const double minCol = 2.0;
    const double maxCol = 33.0;
    const double minRow = 2.0;
    const double maxRow = 18.0;

    final double contentWidth = (maxCol - minCol + 1) * gridCellSize;
    final double contentHeight = (maxRow - minRow + 1) * gridCellSize;

    final screenSize = MediaQuery.of(context).size;

    // Calculate scale to fit all content with padding
    final double scaleX = (screenSize.width * 0.95) / contentWidth;
    final double scaleY = (screenSize.height * 0.95) / contentHeight;
    final double scale = min(scaleX, scaleY);

    // Calculate center of content in world coordinates
    final double contentCenterX = (minCol + maxCol) / 2 * gridCellSize;
    final double contentCenterY = (minRow + maxRow) / 2 * gridCellSize;

    // Calculate screen center
    final double screenCenterX = screenSize.width / 2;
    final double screenCenterY = screenSize.height / 2;

    // Calculate translation to center content
    final double translateX = screenCenterX - (contentCenterX * scale);
    final double translateY = screenCenterY - (contentCenterY * scale);

    final targetMatrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(scale);

    // Animate from current position to global overview
    final currentMatrix = _transformationController.value.clone();

    _snapAnimationController?.dispose();
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: iosSlowDuration, // 450ms - iOS uses slightly longer for "back" actions
    );

    // iOS uses easeInOut for dismissal/back actions - smooth both ways
    final curvedAnimation = CurvedAnimation(
      parent: _snapAnimationController!,
      curve: iosEaseInOut,
    );

    _snapAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
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
  Future<void> _loadDeskComponents(String deskId) async {
    print('🖱️ Desk clicked: $deskId');
    print('🔍 Loading components for inspector...');

    // Set selected desk for pulse animation (via Riverpod)
    ref.read(selectedDeskProvider.notifier).selectDesk(deskId);

    // Trigger pulse animation (will reset after 250ms - iOS timing)
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(selectedDeskProvider.notifier).clearSelection();
      }
    });

    // Query local storage for this specific workstation
    final localAssets = await WorkstationStorage.getWorkstationComponents(deskId);

    if (localAssets != null && localAssets.isNotEmpty) {
      print('✅ Found in local storage: ${localAssets.length} components');
      
      // Update Riverpod state
      ref.read(activeDeskProvider.notifier).setActiveDesk(deskId);
      ref.read(activeDeskComponentsProvider.notifier).setComponents(localAssets);
      ref.read(inspectorStateProvider.notifier).openInspector();

      // Save active desk to localStorage
      CameraStateService.saveActiveDeskState(deskId);

      // Snap-to-Inspect: Animate to desk position with spring physics
      await _snapToDesk(deskId);
    } else {
      print('❌ No assets found in local storage for: $deskId');
      
      // Update Riverpod state (empty desk)
      ref.read(activeDeskProvider.notifier).setActiveDesk(deskId);
      ref.read(activeDeskComponentsProvider.notifier).clearComponents();
      ref.read(inspectorStateProvider.notifier).openInspector();

      // Save active desk to localStorage
      CameraStateService.saveActiveDeskState(deskId);

      // Still snap even if empty
      await _snapToDesk(deskId);
    }
  }

  /// Handle component drop on a desk
  Future<void> _handleComponentDrop(
    Map<String, dynamic> draggedComponent,
    String targetDeskId,
  ) async {
    // This will be implemented in the parent screen
    // For now, just clear the dragging state
    ref.read(draggingComponentProvider.notifier).clearDragging();
  }

  /// Handle canvas tap in edit mode
  void _handleCanvasTap(TapUpDetails details) {
    if (!widget.isEditMode) return;
    final localPos = details.localPosition;

    // Account for offset (canvas starts at col 2, row 2)
    const double offsetX = 2.0;
    const double offsetY = 2.0;

    final int gridX = (localPos.dx / gridCellSize).floor() + offsetX.toInt();
    final int gridY = (localPos.dy / gridCellSize).floor() + offsetY.toInt();
    final tapCell = Offset(gridX.toDouble(), gridY.toDouble());

    setState(() {
      // Toggle: if a desk exists at this cell, remove it; otherwise add one.
      final existing = deskLayouts.entries
          .where((e) => e.value == tapCell && !e.key.startsWith('PILLAR_'))
          .map((e) => e.key)
          .toList();

      if (existing.isNotEmpty) {
        for (final key in existing) {
          deskLayouts.remove(key);
        }
      } else {
        // In edit mode, allow adding custom desks
        final id =
            'CUSTOM_${(deskLayouts.length + 1).toString().padLeft(3, '0')}';
        deskLayouts[id] = tapCell;
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
          _fitAllLabs();
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

    return _buildInfiniteCanvas(isInspectorOpen);
  }

  /// Builds the blueprint-style infinite canvas inside the InteractiveViewer.
  Widget _buildInfiniteCanvas(bool isInspectorOpen) {
    // Canvas sized exactly to lab content (cols 2-33, rows 2-18)
    // 32 columns × 100px = 3200px width
    // 17 rows × 100px = 1700px height
    const double canvasWidth = 3200.0;
    const double canvasHeight = 1700.0;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Listener(
        // Intercept scroll events for smooth zoom
        onPointerSignal: (event) {
          // Check if event has scrollDelta property (indicates scroll event)
          try {
            final scrollDelta = (event as dynamic).scrollDelta;
            if (scrollDelta != null) {
              _handleScrollZoom(event);
            }
          } catch (e) {
            // Not a scroll event, ignore
          }
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.2, // Will be overridden by _enforceMinScale
          maxScale: 5.0,
          panEnabled: !widget.isEditMode && !isInspectorOpen, // Lock pan when inspector open
          onInteractionUpdate: _handleInteractionUpdate, // Smooth zoom on pinch/scroll
          child: GestureDetector(
            onTapUp: _handleCanvasTap,
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              color: const Color(0xFFF5F5F5), // Off-white background
              // PERFORMANCE: RepaintBoundary caches the grid as a GPU texture
              // The 3200x1700px grid with ~600 lines is expensive to repaint
              // This prevents repainting when desks/drag ghost move above it
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GridPainter(cellSize: gridCellSize),
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
      ),
    );
  }

  /// Handle interaction updates for smooth zoom
  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    // This provides smooth zoom during pinch gestures
    // The transformation is already applied by InteractiveViewer
    // We just need to ensure it's smooth
  }

  /// Handle smooth scroll zoom (cross-platform compatible)
  void _handleScrollZoom(dynamic event) {
    if (!mounted) return;

    // Access scrollDelta dynamically (works on both web and native)
    final scrollDelta = (event as dynamic).scrollDelta;
    if (scrollDelta == null) return;

    // Calculate zoom delta from scroll
    final double scrollDeltaY = (scrollDelta.dy as num).toDouble();
    final double zoomFactor = scrollDeltaY > 0 ? 0.9 : 1.1; // Zoom out/in

    // Get current transformation
    final currentMatrix = _transformationController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    // Calculate new scale
    final newScale = (currentScale * zoomFactor).clamp(0.2, 5.0);

    // Get pointer position in widget coordinates
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Access position dynamically
    final position = (event as dynamic).position;
    final Offset focalPoint = renderBox.globalToLocal(position as Offset);

    // Calculate zoom around focal point
    final Matrix4 targetMatrix = _calculateZoomMatrix(
      currentMatrix,
      currentScale,
      newScale,
      focalPoint,
    );

    // Animate to target matrix with fast iOS-style animation
    _animateScrollZoom(currentMatrix, targetMatrix);
  }

  /// Calculate zoom matrix around a focal point
  Matrix4 _calculateZoomMatrix(
    Matrix4 currentMatrix,
    double currentScale,
    double newScale,
    Offset focalPoint,
  ) {
    // Get current translation
    final currentTranslation = currentMatrix.getTranslation();

    // Calculate the point in the scene that's under the focal point
    final scenePointX = (focalPoint.dx - currentTranslation.x) / currentScale;
    final scenePointY = (focalPoint.dy - currentTranslation.y) / currentScale;

    // Calculate new translation to keep the scene point under the focal point
    final newTranslationX = focalPoint.dx - (scenePointX * newScale);
    final newTranslationY = focalPoint.dy - (scenePointY * newScale);

    // Create new matrix
    return Matrix4.identity()
      ..translate(newTranslationX, newTranslationY)
      ..scale(newScale);
  }

  /// Animate scroll zoom smoothly
  void _animateScrollZoom(Matrix4 begin, Matrix4 end) {
    _scrollZoomController?.dispose();
    _scrollZoomController = AnimationController(
      vsync: this,
      duration: iosScrollZoomDuration, // Fast 150ms for responsive feel
    );

    final curvedAnimation = CurvedAnimation(
      parent: _scrollZoomController!,
      curve: Curves.easeOutCubic, // Smooth deceleration
    );

    _scrollZoomAnimation = Matrix4Tween(
      begin: begin,
      end: end,
    ).animate(curvedAnimation);

    _scrollZoomAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _scrollZoomAnimation!.value;
      }
    });

    _scrollZoomController!.forward();
  }

  /// A pillar (structural obstruction, no interaction).
  Widget _buildPillar() {
    return Container(
      width: gridCellSize,
      height: gridCellSize,
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
  Widget _buildCanvasDesk(String deskId) {
    return DeskWidget(
      deskId: deskId,
      position: deskLayouts[deskId]!,
      cellSize: gridCellSize,
      isEditMode: widget.isEditMode,
      onTap: () => _loadDeskComponents(deskId),
      onComponentDrop: (component) => _handleComponentDrop(component, deskId),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC DESK COORDINATE GENERATION (Master Blueprint)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generates the complete 332-desk coordinate map from the Master Blueprint.
  static Map<String, Offset> _generateDeskCoordinates() {
    final Map<String, Offset> coords = {};

    // Lab 6: B-K (2-11), Rows 2-6, 48 desks
    _addLabDesks(coords, 6, [
      {'row': 2, 'cols': [2, 11], 'start': 1}, // D1-D10
      {'row': 3, 'cols': [2, 11], 'start': 11}, // D11-D20
      {'row': 4, 'cols': [2, 11], 'start': 21}, // D21-D30
      {'row': 5, 'cols': [2, 11], 'start': 31}, // D31-D40
      {'row': 6, 'cols': [2, 9], 'start': 41}, // D41-D48 (ends at I)
    ]);

    // Lab 7: B-G (2-7), Rows 8-9,11-12,14-15,17-18, 48 desks
    _addLabDesks(coords, 7, [
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
    _addLabDesks(coords, 1, [
      {'row': 2, 'cols': [13, 20], 'start': 1}, // D1-D8
      {'row': 3, 'cols': [13, 20], 'start': 9}, // D9-D16
      {'row': 5, 'cols': [13, 20], 'start': 17}, // D17-D24
      {'row': 6, 'cols': [13, 20], 'start': 25}, // D25-D32
      {'row': 8, 'cols': [13, 20], 'start': 33}, // D33-D40
      {'row': 9, 'cols': [13, 20], 'start': 41}, // D41-D48
    ]);

    // Lab 2: M-T (13-20), Rows 11-12,14-15,17-18, 48 desks
    _addLabDesks(coords, 2, [
      {'row': 11, 'cols': [13, 20], 'start': 1}, // D1-D8
      {'row': 12, 'cols': [13, 20], 'start': 9}, // D9-D16
      {'row': 14, 'cols': [13, 20], 'start': 17}, // D17-D24
      {'row': 15, 'cols': [13, 20], 'start': 25}, // D25-D32
      {'row': 17, 'cols': [13, 20], 'start': 33}, // D33-D40
      {'row': 18, 'cols': [13, 20], 'start': 41}, // D41-D48
    ]);

    // Lab 3: V-AG (22-33), Rows 2-3,5-6, 46 desks (2 pillars at V5, W5)
    _addLabDesks(coords, 3, [
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
    _addLabDesks(coords, 4, [
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
    _addLabDesks(coords, 5, [
      {'row': 14, 'cols': [22, 33], 'start': 1}, // D1-D12
      {'row': 15, 'cols': [22, 33], 'start': 13}, // D13-D24
      {'row': 17, 'cols': [22, 33], 'start': 25}, // D25-D36
      {'row': 18, 'cols': [22, 33], 'start': 37}, // D37-D48
    ]);

    // Add pillar markers (non-interactive structural elements)
    coords['PILLAR_V5'] = const Offset(22, 5);
    coords['PILLAR_W5'] = const Offset(23, 5);
    coords['PILLAR_V12'] = const Offset(22, 12);
    coords['PILLAR_W12'] = const Offset(23, 12);

    return coords;
  }

  /// Helper to add a lab's desks to the coordinate map.
  static void _addLabDesks(
    Map<String, Offset> coords,
    int labNum,
    List<Map<String, dynamic>> rows,
  ) {
    for (final rowConfig in rows) {
      final int row = rowConfig['row'];
      final List<int> colRange = rowConfig['cols'];
      int deskNum = rowConfig['start'];
      final List<int>? pillarCols = rowConfig['pillars'];

      for (int col = colRange[0]; col <= colRange[1]; col++) {
        // Skip pillars
        if (pillarCols != null && pillarCols.contains(col)) {
          continue;
        }

        final deskId = 'L${labNum}_D${deskNum.toString().padLeft(2, '0')}';
        coords[deskId] = Offset(col.toDouble(), row.toDouble());
        deskNum++;
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID PAINTER (Custom Paint for Canvas Background)
// ═══════════════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  final double cellSize;

  _GridPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB) // Light gray grid lines
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
