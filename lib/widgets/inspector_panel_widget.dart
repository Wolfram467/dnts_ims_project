import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_state_provider.dart';
import '../utils/workstation_storage.dart';
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
    final activeDeskId = ref.watch(activeDeskProvider);
    final activeDeskComponents = ref.watch(activeDeskComponentsProvider);

    // Don't render if inspector is closed
    if (!isInspectorOpen || activeDeskId == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * inspectorPanelWidthFraction;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: panelWidth,
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
            _buildHeader(context, activeDeskId),

            // Visual Desk Layout
            Expanded(
              child: activeDeskComponents.isEmpty
                  ? _buildEmptyState()
                  : _buildVisualDeskLayout(context, activeDeskId, activeDeskComponents),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, String deskId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
      ),
      child: Text(
        deskId,
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

  Widget _buildEmptyState() {
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

  /// Build visual desk layout with component blocks
  Widget _buildVisualDeskLayout(
    BuildContext context,
    String workstationId,
    List<Map<String, dynamic>> components,
  ) {
    // Helper to find component by category
    Map<String, dynamic>? findComponent(String category) {
      try {
        return components.firstWhere(
          (c) =>
              c['category']?.toString().toLowerCase() ==
              category.toLowerCase(),
        );
      } catch (e) {
        return null;
      }
    }

    final keyboard = findComponent('Keyboard');
    final mouse = findComponent('Mouse');
    final monitor = findComponent('Monitor');
    final systemUnit = findComponent('System Unit');
    final ssd = findComponent('SSD');
    final avr = findComponent('AVR');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Force full width
        children: [
          // Row 1: Keyboard and Mouse (small - 12% of height)
          Expanded(
            flex: 12,
            child: Row(
              children: [
                // Keyboard (70% width)
                Expanded(
                  flex: 7,
                  child: _buildComponentBlock(
                    context,
                    workstationId,
                    'KEYBOARD',
                    'K',
                    keyboard,
                  ),
                ),
                const SizedBox(width: 12),
                // Mouse (30% width)
                Expanded(
                  flex: 3,
                  child: _buildComponentBlock(
                    context,
                    workstationId,
                    'MOUSE',
                    'M',
                    mouse,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Monitor (large - 32% of height)
          Expanded(
            flex: 32,
            child: _buildComponentBlock(
              context,
              workstationId,
              'MONITOR',
              'MR',
              monitor,
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: System Unit with SSD (large - 32% of height)
          Expanded(
            flex: 32,
            child: Row(
              children: [
                // System Unit (80% width)
                Expanded(
                  flex: 8,
                  child: _buildComponentBlock(
                    context,
                    workstationId,
                    'SYSTEM UNIT',
                    'SU',
                    systemUnit,
                  ),
                ),
                const SizedBox(width: 12),
                // SSD (20% width)
                Expanded(
                  flex: 2,
                  child: _buildComponentBlock(
                    context,
                    workstationId,
                    'SSD',
                    'S',
                    ssd,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: AVR (small - 12% of height, same as keyboard)
          Expanded(
            flex: 12,
            child: _buildComponentBlock(
              context,
              workstationId,
              'AVR',
              'AVR',
              avr,
            ),
          ),
          const SizedBox(height: 16),

          // Close Button (fixed height, not expanded)
          _buildCloseButton(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT BLOCK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a single component block with edit button
  Widget _buildComponentBlock(
    BuildContext context,
    String workstationId,
    String label,
    String abbreviation,
    Map<String, dynamic>? component,
  ) {
    final hasComponent = component != null;

    return Container(
      decoration: BoxDecoration(
        color: hasComponent
            ? const Color(0xFF374151) // Dark gray when component exists
            : const Color(0xFFE5E7EB), // Light gray when empty
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasComponent
              ? const Color(0xFF1F2937) // Darker border when filled
              : const Color(0xFFD1D5DB), // Light border when empty
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Component Label and Status Badge in a Row
                Row(
                  children: [
                    // Component Label (H5)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: hasComponent
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                        letterSpacing: 0.15,
                        height: 1.2,
                      ),
                    ),
                    if (hasComponent) ...[
                      const SizedBox(width: 12),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(component['status']),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          component['status'] ?? 'Deployed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasComponent) ...[
                  // DNTS Serial (Body text - no spacing)
                  Text(
                    'DNTS: ${component['dnts_serial'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFD1D5DB),
                      letterSpacing: 0.25,
                      height: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Edit button (top-right corner)
          if (hasComponent)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: const Color(0xFF9CA3AF),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () => _openEditDialog(context, workstationId, component),
                tooltip: 'Edit $label',
              ),
            ),
        ],
      ),
    );
  }

  /// Open edit dialog for a component
  void _openEditDialog(
    BuildContext context,
    String workstationId,
    Map<String, dynamic> component,
  ) {
    showDialog(
      context: context,
      builder: (context) => ComponentEditDialog(
        workstationId: workstationId,
        component: component,
        onSaved: () => _refreshWorkstationData(workstationId),
      ),
    );
  }

  /// Refresh workstation data after edit
  Future<void> _refreshWorkstationData(String workstationId) async {
    final components = await WorkstationStorage.getWorkstationComponents(workstationId);
    if (components != null && mounted) {
      ref.read(activeDeskComponentsProvider.notifier).setComponents(components);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLOSE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCloseButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _closeInspector,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF374151),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Fully rounded
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
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
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
