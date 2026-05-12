import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../models/hardware_component.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PERFORMANCE OPTIMIZATION: GLOBAL DRAG GHOST OVERLAY
/// Isolates high-frequency drag position updates to a single widget.
/// This prevents the entire screen (including Map and Inspector) from rebuilding
/// on every pixel of movement during a drag-and-drop operation.
/// ═══════════════════════════════════════════════════════════════════════════

class GlobalDragGhostOverlay extends ConsumerWidget {
  const GlobalDragGhostOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch dragging state and position here
    final draggingComponent = ref.watch(draggingComponentProvider);
    final positionOffset = ref.watch(dragPositionProvider);

    // If not dragging, render nothing
    if (draggingComponent == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Positioned(
        left: positionOffset.dx - 60, // Center the ghost horizontally (120/2)
        top: positionOffset.dy - 30,  // Center the ghost vertically (60/2)
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
                    draggingComponent.category,
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
                    draggingComponent.dntsSerial,
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
}
