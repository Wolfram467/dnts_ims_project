import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../providers/dock_provider.dart';
import '../models/hardware_component.dart';
import '../utils/drag_boundary_calculator.dart';
import '../widgets/map_canvas_widget.dart';
import '../widgets/inspector_panel_widget.dart';
import '../widgets/inventory_dock_widget.dart';
import '../widgets/create_component_dialog.dart';
import '../services/pdf_report_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 8: SYSTEMATIC FRAGMENTATION
// InteractiveMapScreen is now a clean orchestrator for modular widgets.
// Audit and Dock logic have been extracted to InventoryDockWidget.
// ═══════════════════════════════════════════════════════════════════════════

class InteractiveMapScreen extends ConsumerStatefulWidget {
  final String userRole;

  const InteractiveMapScreen({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  @override
  void initState() {
    super.initState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final activeDraggingComponent = ref.watch(draggingComponentProvider);
    final currentDragPositionOffset = ref.watch(dragPositionProvider);
    final selectedFacility = ref.watch(selectedFacilityProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScreenHeader(context),
          Expanded(
            child: Listener(
              onPointerMove: (pointerEvent) => _processPointerMovement(context, ref, pointerEvent),
              child: Stack(
                children: [
                  MapCanvasWidget(facilityId: selectedFacility),
                  const InspectorPanelWidget(),
                  if (activeDraggingComponent != null)
                    _buildDraggableGhostOverlay(activeDraggingComponent, currentDragPositionOffset),
                  const InventoryDockWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateComponentDialog(),
          );
        },
        backgroundColor: const Color(0xFF374151),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreenHeader(BuildContext context) {
    final isDockExpanded = ref.watch(dockProvider.select((state) => state.isExpanded));
    final bool isCompact = MediaQuery.of(context).size.height < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isCompact ? 8 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  ref.read(dockProvider.notifier).toggleExpanded();
                  ref.read(refreshTriggerProvider.notifier).state++;
                  ref.read(cameraControlProvider.notifier).fitAllLabs();
                },
                mouseCursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDockExpanded 
                        ? Theme.of(context).colorScheme.onSurface 
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1),
                  ),
                  child: Icon(
                    isDockExpanded ? Icons.close : Icons.assessment,
                    color: isDockExpanded 
                        ? Theme.of(context).colorScheme.surface 
                        : Theme.of(context).colorScheme.onSurface,
                    size: isCompact ? 20 : 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Inventory Management System',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: isCompact ? 16 : 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          Row(
            children: [],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTURE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  void _processPointerMovement(BuildContext context, WidgetRef widgetRef, PointerMoveEvent pointerEvent) {
    final activeDraggingComponent = widgetRef.read(draggingComponentProvider);
    if (activeDraggingComponent == null) return;

    widgetRef.read(dragPositionProvider.notifier).updatePosition(pointerEvent.position);

    final screenSize = MediaQuery.of(context).size;
    if (DragBoundaryCalculator.shouldTriggerEscapeGesture(pointerEvent.position, screenSize)) {
      _resetSpatialState(widgetRef);
    }

    if (widgetRef.read(inspectorStateProvider)) {
      if (DragBoundaryCalculator.hasExitedModalSafeZone(pointerEvent.position, screenSize)) {
        _deactivateInspectorPanel(widgetRef);
      }
    }
  }

  void _resetSpatialState(WidgetRef widgetRef) {
    print('🔄 SPATIAL RESET: Escape gesture triggered');
    _deactivateInspectorPanel(widgetRef);
    widgetRef.read(draggingComponentProvider.notifier).clearDragging();
    widgetRef.read(dragPositionProvider.notifier).reset();
    widgetRef.read(sourceWorkstationProvider.notifier).state = null;
  }

  void _deactivateInspectorPanel(WidgetRef widgetRef) {
    widgetRef.read(inspectorStateProvider.notifier).closeInspector();
    widgetRef.read(activeDeskProvider.notifier).clearActiveDesk();
    widgetRef.read(selectedDeskProvider.notifier).clearSelection();
  }

  Widget _buildDraggableGhostOverlay(HardwareComponent component, Offset positionOffset) {
    return RepaintBoundary(
      child: Positioned(
        left: positionOffset.dx - 60,
        top: positionOffset.dy - 30,
        child: IgnorePointer(
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.5),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade100, border: Border.all(color: Colors.blue.shade700, width: 2)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(component.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(component.dntsSerial, style: const TextStyle(fontSize: 9, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _displayKeyboardShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Keyboard Shortcuts', style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.5)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeyboardShortcutEntry('ESC', 'Close Inspector / Return to Overview'),
              _buildKeyboardShortcutEntry('Arrow Keys', 'Pan Camera'),
              _buildKeyboardShortcutEntry('+/-', 'Zoom In/Out'),
              _buildKeyboardShortcutEntry('Space', 'Fit All Labs'),
              _buildKeyboardShortcutEntry('1-7', 'Jump to Lab 1-7'),
              _buildKeyboardShortcutEntry('Tab', 'Next Desk in Lab'),
              _buildKeyboardShortcutEntry('?', 'Show This Help'),
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

  Widget _buildKeyboardShortcutEntry(String keyboardKey, String shortcutDescription) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade200, border: Border.all(color: Colors.black, width: 1)),
            child: Text(keyboardKey, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(shortcutDescription)),
        ],
      ),
    );
  }
}
