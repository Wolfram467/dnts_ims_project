import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../utils/drag_boundary_utils.dart';
import '../services/camera_state_service.dart';
import '../widgets/map_canvas_widget.dart';
import '../widgets/inspector_panel_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 3D: SHELL REFACTOR
// InteractiveMapScreen is now a lightweight ConsumerWidget that serves as a
// layout orchestrator and global gesture listener. All heavy lifting has been
// extracted to dedicated widgets and Riverpod providers.
// ═══════════════════════════════════════════════════════════════════════════

class InteractiveMapScreen extends ConsumerWidget {
  final String userRole;

  const InteractiveMapScreen({
    super.key,
    required this.userRole,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD - LIGHTWEIGHT ORCHESTRATOR
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Riverpod state for reactive updates
    final draggingComponent = ref.watch(draggingComponentProvider);
    final dragPosition = ref.watch(dragPositionProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title and controls
          _buildHeader(context, ref),

          // Main content area with global gesture listener
          Expanded(
            child: Listener(
              // Global pointer tracking for drag-and-drop and escape gesture
              onPointerMove: (event) {
                _handlePointerMove(context, ref, event);
              },
              child: Stack(
                children: [
                  // Layer 1 (Bottom): Map Canvas
                  const MapCanvasWidget(),

                  // Layer 2 (Middle): Inspector Panel
                  const InspectorPanelWidget(),

                  // Layer 3 (Top): Global Drag Ghost
                  if (draggingComponent != null)
                    _buildGlobalDragGhost(draggingComponent, dragPosition),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            'CT1 Floor Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
          ),

          // Controls
          Row(
            children: [
              // Fit All Labs / Reset View
              IconButton(
                icon: const Icon(Icons.zoom_out_map),
                onPressed: () async {
                  await _handleResetView(ref);
                },
                tooltip: 'Fit All Labs',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Zoom In
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  ref.read(cameraControlProvider.notifier).zoomIn();
                },
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Keyboard Shortcuts Help
              IconButton(
                icon: const Icon(Icons.keyboard),
                onPressed: () => _showKeyboardShortcutsHelp(context),
                tooltip: 'Keyboard Shortcuts',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Trigger data refresh
                  // This would be handled by a data provider
                },
                tooltip: 'Refresh Assets',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOBAL GESTURE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle pointer movement for drag tracking and escape gesture detection
  void _handlePointerMove(
    BuildContext context,
    WidgetRef ref,
    PointerMoveEvent event,
  ) {
    final draggingComponent = ref.read(draggingComponentProvider);

    // Only track if actively dragging
    if (draggingComponent == null) return;

    // Update drag position in Riverpod
    ref.read(dragPositionProvider.notifier).updatePosition(event.position);

    // Check for escape gesture using DragBoundaryUtils
    final screenSize = MediaQuery.of(context).size;
    final shouldEscape = DragBoundaryUtils.shouldTriggerEscapeGesture(
      event.position,
      screenSize,
    );

    if (shouldEscape) {
      _triggerSpatialReset(ref);
    }

    // Check if drag has exited modal safe zone
    final isInspectorOpen = ref.read(inspectorStateProvider);
    if (isInspectorOpen) {
      final hasExitedSafeZone = DragBoundaryUtils.hasExitedModalSafeZone(
        event.position,
        screenSize,
      );

      if (hasExitedSafeZone) {
        _closeInspectorPanel(ref);
      }
    }
  }

  /// Trigger spatial reset (escape gesture)
  void _triggerSpatialReset(WidgetRef ref) {
    print('🔄 SPATIAL RESET: Escape gesture triggered');

    // Close inspector panel
    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();

    // Clear dragging state
    ref.read(draggingComponentProvider.notifier).clearDragging();
    ref.read(dragPositionProvider.notifier).reset();

    // Note: Camera animation to global overview should be triggered by
    // MapCanvasWidget listening to inspectorStateProvider changes
  }

  /// Close inspector panel (break-away gesture)
  void _closeInspectorPanel(WidgetRef ref) {
    print('🔄 BREAK-AWAY: Inspector panel closing');

    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOBAL DRAG GHOST
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build the global drag ghost that follows the cursor
  Widget _buildGlobalDragGhost(
    Map<String, dynamic> component,
    Offset position,
  ) {
    // PERFORMANCE: RepaintBoundary isolates drag ghost repaints
    // As dragPositionProvider updates 60-120 times per second,
    // this prevents the ghost's movement from invalidating the
    // paint layers of MapCanvasWidget and InspectorPanelWidget below
    return RepaintBoundary(
      child: Positioned(
        left: position.dx - 60, // Center on cursor (120px width / 2)
        top: position.dy - 30, // Approximate center
        child: IgnorePointer(
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.5),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                border: Border.all(color: Colors.blue.shade700, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    component['category'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    component['dnts_serial'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle reset view button (clear saved state)
  Future<void> _handleResetView(WidgetRef ref) async {
    await CameraStateService.clearAllState();
    
    // Close inspector and reset camera
    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();
    
    // Trigger fit all labs
    ref.read(cameraControlProvider.notifier).fitAllLabs();
  }

  /// Show keyboard shortcuts help dialog
  void _showKeyboardShortcutsHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
            style: TextButton.styleFrom(foregroundColor: Colors.black),
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
}
