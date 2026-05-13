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
  final bool isMobile;
  const InspectorPanelWidget({super.key, this.isMobile = false});

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
    final activeWorkstationComponentsAsync = ref.watch(activeDeskComponentsProvider);
    final activeWorkstationComponents = activeWorkstationComponentsAsync.valueOrNull ?? [];

    // Don't render if inspector is closed
    if (!isInspectorOpen || activeWorkstationIdentifier == null) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final panelWidthPixels = widget.isMobile ? size.width : size.width * inspectorPanelWidthFraction;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: panelWidthPixels,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light gray background
          border: Border(
            left: BorderSide(color: const Color(0xFFD1D5DB), width: widget.isMobile ? 0 : 1), // Swiss border
          ),
          boxShadow: widget.isMobile ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(-5, 0),
            )
          ] : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // HOLISTIC SCALING: Calculate scale factor based on reference height (800px)
            final double scaleFactor = (constraints.maxHeight / 800.0).clamp(0.6, 1.2);
            
            return Padding(
              padding: EdgeInsets.all(24.0 * scaleFactor),
              child: _buildVisualWorkstationLayout(
                context, 
                activeWorkstationIdentifier, 
                activeWorkstationComponents,
                scaleFactor,
              ),
            );
          },
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
    double scaleFactor,
  ) {
    final double gap = 12.0 * scaleFactor;

    Widget buildRow1() => Row(
      children: [
        Expanded(
          flex: 7,
          child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Keyboard', scaleFactor),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 3,
          child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Mouse', scaleFactor),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Keyboard and Mouse (1x Height)
        Expanded(flex: 1, child: buildRow1()),
        SizedBox(height: gap),

        // Row 2: Monitor (2x Height)
        Expanded(flex: 2, child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Monitor', scaleFactor)),
        SizedBox(height: gap),

        // Row 3: System Unit with nested SSD (2x Height)
        Expanded(flex: 2, child: _buildSystemUnitWithNestedSsdSlot(context, workstationIdentifier, workstationComponents, scaleFactor)),
        SizedBox(height: gap),

        // Row 4: AVR (1x Height)
        Expanded(flex: 1, child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'AVR', scaleFactor)),
        SizedBox(height: 24 * scaleFactor),

        // Close Button
        _buildPanelCloseButton(scaleFactor),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENT SLOTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build the internal content of a component slot
  Widget _buildComponentSlotContent(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
    String targetCategory,
    double scaleFactor, {
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
    final double padding = (isNestedComponent ? 10.0 : 16.0) * scaleFactor;

    return InkWell(
      onTap: isComponentFound
          ? () => _openComponentEditDialog(context, workstationIdentifier, foundComponent!)
          : null,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Light Indicator
                Container(
                  width: 8 * scaleFactor,
                  height: 8 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _resolveStatusLightColor(isComponentFound ? foundComponent.status : 'Empty'),
                    boxShadow: isComponentFound && foundComponent.status.toLowerCase() == 'deployed' 
                      ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4 * scaleFactor)] 
                      : null,
                  ),
                ),
                SizedBox(width: 8 * scaleFactor),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      targetCategory.toUpperCase(),
                      style: TextStyle(
                        fontSize: (isNestedComponent ? 13 : 15) * scaleFactor,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.0 * scaleFactor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scaleFactor),
            // Serial Number with scale-down logic
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isComponentFound ? 'DNTS: ${foundComponent.dntsSerial}' : 'Empty Slot',
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.w400,
                    color: isComponentFound ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF),
                    letterSpacing: 0.25 * scaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a fixed component slot
  Widget _buildComponentSlot(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
    String targetCategory,
    double scaleFactor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Deep Anthracite
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: _buildComponentSlotContent(context, workstationIdentifier, workstationComponents, targetCategory, scaleFactor),
    );
  }

  /// Specialized slot for System Unit with nested SSD card
  Widget _buildSystemUnitWithNestedSsdSlot(
    BuildContext context,
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
    double scaleFactor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Deep Anthracite
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: _buildComponentSlotContent(
              context, 
              workstationIdentifier, 
              workstationComponents, 
              'System Unit',
              scaleFactor,
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(right: 16 * scaleFactor),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: _buildComponentSlotContent(
                        context, 
                        workstationIdentifier, 
                        workstationComponents, 
                        'SSD',
                        scaleFactor,
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

  /// Refresh workstation data after edit (handled automatically by Stream)
  Future<void> _refreshWorkstationData(String workstationIdentifier) async {
    // Left for callback signature compatibility, but UI updates automatically via StreamProvider.
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLOSE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPanelCloseButton(double scaleFactor) {
    return SizedBox(
      height: 56 * scaleFactor,
      child: ElevatedButton(
        onPressed: _closeInspector,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF374151),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: Text(
          'CLOSE',
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5 * scaleFactor,
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
    if (widget.isMobile) {
      Navigator.of(context).pop();
    } else {
      ref.read(inspectorStateProvider.notifier).closeInspector();
    }
    ref.read(activeDeskProvider.notifier).clearActiveDesk();
    ref.read(selectedDeskProvider.notifier).clearSelection();

    // Note: The camera reset animation should be triggered by the parent
    // (InteractiveMapScreen) by listening to inspectorStateProvider changes
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get status light color
  Color _resolveStatusLightColor(String? deploymentStatus) {
    switch (deploymentStatus?.toLowerCase()) {
      case 'deployed':
        return Colors.green.shade400; // Functional
      case 'under maintenance':
        return Colors.yellow.shade600; // Maintenance
      case 'empty':
      case 'not found':
      case 'storage':
      case 'in storage':
        return Colors.grey.shade500; // Not Found
      default:
        return Colors.grey.shade500;
    }
  }

  /// Get status badge color (Legacy, kept for compatibility if needed)
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
