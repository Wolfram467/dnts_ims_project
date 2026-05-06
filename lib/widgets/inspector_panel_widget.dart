import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../providers/repository_providers.dart';
import '../models/hardware_component.dart';
import 'component_edit_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 3C: INSPECTOR PANEL EXTRACTION
// Extracted from InteractiveMapScreen into a dedicated ConsumerWidget.
// Displays the right-aligned sliding panel for desk inspection with visual
// component layout and editing capabilities.
// ═══════════════════════════════════════════════════════════════════════════

class InspectorPanelWidget extends ConsumerStatefulWidget {
  const InspectorPanelWidget({super.key});

  @override
  ConsumerState<InspectorPanelWidget> createState() => _InspectorPanelWidgetState();
}

class _InspectorPanelWidgetState extends ConsumerState<InspectorPanelWidget> {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inspector panel width as a fraction of screen width (40%)
  static const double inspectorPanelWidthFraction = 0.4;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod state for reactive updates
    final isInspectorOpen = ref.watch(inspectorStateProvider);
    final activeWorkstationIdentifier = ref.watch(activeDeskProvider);
    final activeWorkstationComponents = ref.watch(activeDeskComponentsProvider);

    // Don't render if inspector is closed
    if (!isInspectorOpen || activeWorkstationIdentifier == null) {
      return const SizedBox.shrink();
    }

    final screenWidthPixels = MediaQuery.of(context).size.width;
    final panelWidthPixels = screenWidthPixels * inspectorPanelWidthFraction;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: panelWidthPixels,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5), // Light gray background
          border: Border(
            left: BorderSide(color: Color(0xFFD1D5DB), width: 1), // Swiss border
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildPanelHeader(context, activeWorkstationIdentifier),

            // Visual Desk Layout
            Expanded(
              child: activeWorkstationComponents.isEmpty
                  ? _buildEmptyStateView()
                  : _buildVisualWorkstationLayout(context, activeWorkstationIdentifier, activeWorkstationComponents),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPanelHeader(BuildContext context, String workstationIdentifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
      ),
      child: Text(
        workstationIdentifier,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyStateView() {
    return const Center(
      child: Text(
        'Empty Workstation',
        style: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VISUAL DESK LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build visual workstation layout with fixed component slots
  Widget _buildVisualWorkstationLayout(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Keyboard and Mouse
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Keyboard'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Mouse'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Monitor (Double Height)
          Expanded(
            flex: 4,
            child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Monitor'),
          ),
          const SizedBox(height: 12),

          // Row 3: System Unit with nested SSD (Double Height)
          Expanded(
            flex: 4,
            child: _buildSystemUnitWithNestedSsdSlot(context, workstationIdentifier, workstationComponents),
          ),
          const SizedBox(height: 12),

          // Row 4: AVR
          Expanded(
            flex: 2,
            child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'AVR'),
          ),
          const SizedBox(height: 24),

          // Close Button
          _buildPanelCloseButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT SLOTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build the internal content of a component slot (shared between standard and nested layouts)
  Widget _buildComponentSlotContent(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
    String targetCategory, {
    bool isNestedComponent = false,
  }) {
    HardwareComponent? foundComponent;
    try {
      foundComponent = workstationComponents.firstWhere(
        (component) => component.category.toLowerCase() == targetCategory.toLowerCase(),
      );
    } catch (_) {
      foundComponent = null;
    }

    final bool isComponentFound = foundComponent != null;
    final double horizontalPadding = isNestedComponent ? 10.0 : 16.0;
    final double verticalPadding = isNestedComponent ? 10.0 : 16.0;

    return InkWell(
      onTap: isComponentFound
          ? () => _openComponentEditDialog(context, workstationIdentifier, foundComponent!)
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  targetCategory.toUpperCase(),
                  style: TextStyle(
                    fontSize: isNestedComponent ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isComponentFound ? const Color(0xFFA7F3D0) : const Color(0xFF4B5563),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    isComponentFound ? (foundComponent.status).toUpperCase() : 'NOT FOUND',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Serial Number with scale-down logic for long strings
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isComponentFound ? 'DNTS: ${foundComponent.dntsSerial}' : 'Empty Slot',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isComponentFound ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF),
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a fixed component slot with data handling and empty states
  Widget _buildComponentSlot(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
    String targetCategory,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Deep Anthracite
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.zero, // Swiss Style
      ),
      child: _buildComponentSlotContent(context, workstationIdentifier, workstationComponents, targetCategory),
    );
  }

  /// Specialized slot for System Unit with nested SSD card
  Widget _buildSystemUnitWithNestedSsdSlot(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Deep Anthracite
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.zero, // Swiss Style
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: System Unit details (60% width)
          Expanded(
            flex: 6,
            child: _buildComponentSlotContent(
              context, 
              workstationIdentifier, 
              workstationComponents, 
              'System Unit',
            ),
          ),
          // Right side: SSD area (40% width)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: _buildComponentSlotContent(
                        context, 
                        workstationIdentifier, 
                        workstationComponents, 
                        'SSD',
                        isNestedComponent: true,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open edit dialog for a component
  void _openComponentEditDialog(
    BuildContext context,
    String workstationIdentifier,
    HardwareComponent component,
  ) {
    showDialog(
      context: context,
      builder: (context) => ComponentEditDialog(
        workstationIdentifier: workstationIdentifier,
        component: component,
        onSaved: () => _refreshWorkstationData(workstationIdentifier),
      ),
    );
  }

  /// Refresh workstation data after edit
  Future<void> _refreshWorkstationData(String workstationIdentifier) async {
    final workstationComponents = await ref.read(workstationRepositoryProvider).getWorkstationComponents(workstationIdentifier);
    if (workstationComponents != null && mounted) {
      ref.read(activeDeskComponentsProvider.notifier).setComponents(workstationComponents);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLOSE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPanelCloseButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _closeInspector,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF374151),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Swiss Style
          ),
          elevation: 0,
        ),
        child: const Text(
          'CLOSE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Close the inspector panel and reset state
  void _closeInspector() {
    ref.read(inspectorStateProvider.notifier).closeInspector();
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(activeDeskComponentsProvider.notifier).clearComponents();
    ref.read(selectedDeskProvider.notifier).clearSelection();

    // Note: The camera reset animation should be triggered by the parent
    // (InteractiveMapScreen) by listening to inspectorStateProvider changes
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get status badge color
  Color _resolveStatusColor(String? deploymentStatus) {
    switch (deploymentStatus?.toLowerCase()) {
      case 'deployed':
        return const Color(0xFFA7F3D0); // Green
      case 'under maintenance':
        return const Color(0xFFFED7AA); // Orange
      case 'borrowed':
        return const Color(0xFFBAE6FD); // Blue
      case 'in storage':
      case 'storage':
        return const Color(0xFFE5E7EB); // Gray
      case 'missing':
        return const Color(0xFFFECACA); // Red
      case 'retired':
        return const Color(0xFFD1D5DB); // Dark gray
      default:
        return const Color(0xFFA7F3D0); // Default green
    }
  }
}
