import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hardware_component.dart';
import '../providers/repository_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 2: STATE MANAGEMENT MIGRATION
// Extracted from InteractiveMapScreen's local state into Riverpod Notifiers
// ═══════════════════════════════════════════════════════════════════════════

/// Manages the currently dragging component during drag-and-drop operations.
/// This is the "Global Handoff State" for drag feedback.
class DraggingComponentNotifier extends Notifier<HardwareComponent?> {
  @override
  HardwareComponent? build() {
    return null; // No component being dragged initially
  }

  /// Set the component being dragged
  void setDraggingComponent(HardwareComponent? component) {
    state = component;
  }

  /// Clear the dragging state
  void clearDragging() {
    state = null;
  }

  /// Check if currently dragging
  bool get isDragging => state != null;
}

/// Provider for the dragging component state
final draggingComponentProvider =
    NotifierProvider<DraggingComponentNotifier, HardwareComponent?>(
  () => DraggingComponentNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the current drag position for cursor tracking.
/// Used for the "Omni-Directional Break-Away" modal logic.
class DragPositionNotifier extends Notifier<Offset> {
  @override
  Offset build() {
    return Offset.zero; // Default position at origin
  }

  /// Update the drag position
  void updatePosition(Offset position) {
    state = position;
  }

  /// Reset to origin
  void reset() {
    state = Offset.zero;
  }
}

/// Provider for the drag position state
final dragPositionProvider = NotifierProvider<DragPositionNotifier, Offset>(
  () => DragPositionNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the active desk ID for the inspector panel.
/// Tracks which desk's dock is currently open.
class ActiveDeskNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // No desk selected initially
  }

  /// Set the active desk
  void setActiveDesk(String? deskId) {
    state = deskId;
  }

  /// Clear the active desk
  void clearActiveDesk() {
    state = null;
  }

  /// Check if a desk is active
  bool get hasActiveDesk => state != null;
}

/// Provider for the active desk state
final activeDeskProvider = NotifierProvider<ActiveDeskNotifier, String?>(
  () => ActiveDeskNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the inspector panel open/closed state.
/// Controls the "Snap-to-Inspect Navigation" panel visibility.
class InspectorStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Inspector closed initially
  }

  /// Open the inspector panel
  void openInspector() {
    state = true;
  }

  /// Close the inspector panel
  void closeInspector() {
    state = false;
  }

  /// Toggle the inspector panel
  void toggleInspector() {
    state = !state;
  }
}

/// Provider for the inspector panel state
final inspectorStateProvider = NotifierProvider<InspectorStateNotifier, bool>(
  () => InspectorStateNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════
// ADDITIONAL STATE NOTIFIERS
// These manage other pieces of state that were in InteractiveMapScreen
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for the active desk components (Real-time Supabase Stream)
final activeDeskComponentsProvider = StreamProvider<List<HardwareComponent>>((ref) {
  final deskId = ref.watch(activeDeskProvider);
  if (deskId == null) return Stream.value([]);
  
  final repository = ref.watch(workstationRepositoryProvider);
  return repository.streamWorkstationComponents(deskId);
});

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the selected desk ID for pulse animation.
/// Used for the visual feedback when a desk is clicked.
class SelectedDeskNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // No desk selected initially
  }

  /// Set the selected desk (triggers pulse animation)
  void selectDesk(String? deskId) {
    state = deskId;
  }

  /// Clear the selected desk (animation complete)
  void clearSelection() {
    state = null;
  }
}

/// Provider for the selected desk state (pulse animation)
final selectedDeskProvider = NotifierProvider<SelectedDeskNotifier, String?>(
  () => SelectedDeskNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the drag-from-panel state for the "Spatial Reset" escape gesture.
/// Tracks if a drag originated from the inspector panel.
class DragFromPanelNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Not dragging from panel initially
  }

  /// Set dragging from panel state
  void setDraggingFromPanel(bool isDragging) {
    state = isDragging;
  }

  /// Clear the state
  void clear() {
    state = false;
  }
}

/// Provider for the drag-from-panel state
final dragFromPanelProvider = NotifierProvider<DragFromPanelNotifier, bool>(
  () => DragFromPanelNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the current drag position for the escape gesture.
/// This is separate from dragPositionProvider and specifically used for
/// the "Omni-Directional Break-Away" boundary detection.
class CurrentDragPositionNotifier extends Notifier<Offset> {
  @override
  Offset build() {
    return Offset.zero;
  }

  /// Update the current drag position
  void updatePosition(Offset position) {
    state = position;
  }

  /// Reset to origin
  void reset() {
    state = Offset.zero;
  }
}

/// Provider for the current drag position (escape gesture)
final currentDragPositionProvider =
    NotifierProvider<CurrentDragPositionNotifier, Offset>(
  () => CurrentDragPositionNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════

/// Manages the panel boundary X coordinate for escape gesture detection.
/// This is the left edge of the inspector panel.
class PanelBoundaryNotifier extends Notifier<double> {
  @override
  double build() {
    return 0.0; // Default boundary at origin
  }

  /// Set the panel boundary X coordinate
  void setBoundary(double x) {
    state = x;
  }

  /// Reset to origin
  void reset() {
    state = 0.0;
  }
}

/// Provider for the panel boundary X coordinate
final panelBoundaryProvider = NotifierProvider<PanelBoundaryNotifier, double>(
  () => PanelBoundaryNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════
// CONVENIENCE COMPUTED PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Computed provider: Check if a component is currently being dragged
final isDraggingProvider = Provider<bool>((ref) {
  final draggingComponent = ref.watch(draggingComponentProvider);
  return draggingComponent != null;
});

/// Computed provider: Check if inspector is open and has an active desk
final isInspectorActiveProvider = Provider<bool>((ref) {
  final isOpen = ref.watch(inspectorStateProvider);
  final hasDesk = ref.watch(activeDeskProvider) != null;
  return isOpen && hasDesk;
});

/// Provider for triggering a data refresh across the application
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Tracks the source workstation ID during a drag operation.
final sourceWorkstationProvider = StateProvider<String?>((ref) => null);

/// Manages the currently selected facility for spatial filtering.
final selectedFacilityProvider = StateProvider<String>((ref) => 'CT1');

// ═══════════════════════════════════════════════════════════════════════════
// CAMERA CONTROL PROVIDER
// Used for triggering camera actions from the shell (zoom, fit all labs, etc.)
// ═══════════════════════════════════════════════════════════════════════════

/// Camera action types
enum CameraAction {
  fitAllLabs,
  zoomIn,
  zoomOut,
  resetToGlobalOverview,
}

/// Manages camera control actions
/// This is a simple notifier that emits camera action commands
class CameraControlNotifier extends Notifier<CameraAction?> {
  @override
  CameraAction? build() {
    return null; // No action initially
  }

  /// Trigger a camera action
  void triggerAction(CameraAction action) {
    state = action;
    // Reset to null after a frame to allow repeated actions
    Future.microtask(() {
      // In Riverpod 2.x, we don't need a mounted check
      // The provider lifecycle is managed automatically
      state = null;
    });
  }

  /// Fit all labs in view
  void fitAllLabs() => triggerAction(CameraAction.fitAllLabs);

  /// Zoom in
  void zoomIn() => triggerAction(CameraAction.zoomIn);

  /// Zoom out
  void zoomOut() => triggerAction(CameraAction.zoomOut);

  /// Reset to global overview
  void resetToGlobalOverview() => triggerAction(CameraAction.resetToGlobalOverview);
}

/// Provider for camera control
final cameraControlProvider =
    NotifierProvider<CameraControlNotifier, CameraAction?>(
  () => CameraControlNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL REACTIVE INVENTORY SYNCHRONIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Acts as the single source of truth for the Map and Audit sidebar.
/// Streams all non-Retired assets matching the selected facility.
final facilityInventoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final controller = StreamController<List<Map<String, dynamic>>>();
  final supabase = Supabase.instance.client;
  final selectedFacility = ref.watch(selectedFacilityProvider);

  Future<void> fetchAndEmit() async {
    try {
      final response = await supabase
          .from('serialized_assets')
          .select('*, location:locations!serialized_assets_current_loc_id_fkey!inner(name)')
          .neq('status', 'Retired');
          
      if (!controller.isClosed) {
        final filtered = (response as List<dynamic>).where((asset) {
          final locName = asset['location']?['name'] as String? ?? '';
          if (selectedFacility == 'CT1') return true;
          if (selectedFacility.startsWith('Lab ')) {
             final labNum = selectedFacility.split(' ').last;
             return locName.startsWith('L$labNum');
          }
          return true; // Fallback
        }).cast<Map<String, dynamic>>().toList();
        
        controller.add(filtered);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  fetchAndEmit();

  final channel = supabase.channel('public:serialized_assets_inventory').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'serialized_assets',
    callback: (payload) {
      fetchAndEmit();
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});

// ═══════════════════════════════════════════════════════════════════════════

/// Tracks whether the user is currently selecting a location for a new component.
final isLocationPickingModeProvider = StateProvider<bool>((ref) => false);

/// Tracks whether the application is in "Component Creation Mode".
final isCreationModeProvider = StateProvider<bool>((ref) => false);

/// Tracks the currently selected component type for the new asset.
final selectedCreationTypeProvider = StateProvider<String?>((ref) => null);

/// Persists the draft inputs of the component creation form during location picking.
final draftComponentProvider = StateProvider<Map<String, String>>((ref) => {});
