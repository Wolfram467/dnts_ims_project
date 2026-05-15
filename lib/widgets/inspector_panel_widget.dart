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
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Watch Riverpod state for reactive updates
    final isInspectorOpen = ref.watch(inspectorStateProvider);
    final activeWorkstationIdentifier = ref.watch(activeDeskProvider);
    final activeWorkstationComponentsAsync = ref.watch(activeDeskComponentsProvider);
    final activeWorkstationComponents = activeWorkstationComponentsAsync.valueOrNull ?? [];

    final size = MediaQuery.of(context).size;
    
    // Panel width set to 40%
    const double panelWidthFraction = 0.4;
    final panelWidthPixels = widget.isMobile ? size.width : size.width * panelWidthFraction;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      top: 0,
      right: isInspectorOpen && activeWorkstationIdentifier != null ? 0 : -panelWidthPixels,
      bottom: 0,
      width: panelWidthPixels,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light gray background
          border: Border(
            left: BorderSide(color: const Color(0xFFD1D5DB), width: widget.isMobile ? 0 : 1), // Swiss border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(-5, 0),
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // HOLISTIC SCALING: Calculate scale factor based on reference height (800px)
            final double scaleFactor = (constraints.maxHeight / 800.0).clamp(0.6, 1.2);
            
            if (activeWorkstationIdentifier == null) return const SizedBox.shrink();

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

    final bool isLab7 = workstationIdentifier.toLowerCase().contains('lab 7') || 
                        workstationIdentifier.toLowerCase().contains('lab7') || 
                        workstationIdentifier.toLowerCase().contains('l7');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Keyboard and Mouse (1x Height)
        Expanded(flex: 1, child: buildRow1()),
        SizedBox(height: gap),

        // Row 2: Monitor (2x Height) - Split in half for Lab 7
        if (isLab7)
          Expanded(
            flex: 2, 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Monitor 1', scaleFactor, categoryIndex: 0)),
                SizedBox(width: gap),
                Expanded(child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Monitor 2', scaleFactor, categoryIndex: 1)),
              ],
            )
          )
        else
          Expanded(flex: 2, child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'Monitor', scaleFactor)),
        
        SizedBox(height: gap),

        // Row 3: System Unit with nested SSD (2x Height)
        Expanded(flex: 2, child: _buildSystemUnitWithNestedSsdSlot(context, workstationIdentifier, workstationComponents, scaleFactor)),
        SizedBox(height: gap),

        // Row 4: AVR (1x Height)
        Expanded(flex: 1, child: _buildComponentSlot(context, workstationIdentifier, workstationComponents, 'AVR', scaleFactor)),
        SizedBox(height: gap),

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
    int categoryIndex = 0,
  }) {
    HardwareComponent? foundComponent;
    try {
      // Normalize targetCategory for searching (Monitor 1/2 -> Monitor)
      String normalizedTarget = targetCategory.toLowerCase();
      if (normalizedTarget == 'monitor 1' || normalizedTarget == 'monitor 2') {
        normalizedTarget = 'monitor';
      }

      final categoryComponents = workstationComponents.where((component) {
        String existingCategory = component.category.toLowerCase();
        if (existingCategory == 'monitor 1' || existingCategory == 'monitor 2') {
          existingCategory = 'monitor';
        }
        return existingCategory == normalizedTarget;
      }).toList();
      
      if (categoryComponents.length > categoryIndex) {
        foundComponent = categoryComponents[categoryIndex];
      }
    } catch (_) {
      foundComponent = null;
    }

    final bool isComponentFound = foundComponent != null;
    final bool isCreationMode = ref.watch(isCreationModeProvider);
    final String? selectedCreationType = ref.watch(selectedCreationTypeProvider);
    final bool isSelectedForCreation = isCreationMode && selectedCreationType?.toLowerCase() == targetCategory.toLowerCase();
    
    final double padding = (isNestedComponent ? 10.0 : 16.0) * scaleFactor;

    return InkWell(
      onTap: () {
        if (isCreationMode) {
          ref.read(selectedCreationTypeProvider.notifier).state = targetCategory;
        } else if (isComponentFound) {
          _openComponentEditDialog(context, workstationIdentifier, foundComponent!);
        } else {
          // Shortcut: Start creation mode for this type
          ref.read(isCreationModeProvider.notifier).state = true;
          ref.read(selectedCreationTypeProvider.notifier).state = targetCategory;
        }
      },
      child: Container(
        decoration: isSelectedForCreation ? BoxDecoration(
          border: Border.all(color: const Color(0xFF00E676), width: 2 * scaleFactor), // Highlight with Carbon Mint
        ) : null,
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
                      color: isSelectedForCreation 
                        ? const Color(0xFF00E676)
                        : _resolveStatusLightColor(isComponentFound ? foundComponent.status : 'Empty'),
                      boxShadow: (isComponentFound && foundComponent.status.toLowerCase() == 'deployed') || isSelectedForCreation
                        ? [BoxShadow(color: (isSelectedForCreation ? const Color(0xFF00E676) : Colors.green).withOpacity(0.5), blurRadius: 4 * scaleFactor)] 
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
                          color: isSelectedForCreation ? const Color(0xFF00E676) : Colors.white,
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
                    isSelectedForCreation 
                      ? 'SELECTED FOR CREATION'
                      : (isComponentFound ? 'DNTS: ${foundComponent.dntsSerial}' : 'Empty Slot'),
                    style: TextStyle(
                      fontSize: 12 * scaleFactor,
                      fontWeight: FontWeight.w400,
                      color: isSelectedForCreation 
                        ? const Color(0xFF00E676).withOpacity(0.8)
                        : (isComponentFound ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF)),
                      letterSpacing: 0.25 * scaleFactor,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    double scaleFactor, {
    int categoryIndex = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Deep Anthracite
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: _buildComponentSlotContent(context, workstationIdentifier, workstationComponents, targetCategory, scaleFactor, categoryIndex: categoryIndex),
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
            flex: 7, // Matches Keyboard width proportion
            child: _buildComponentSlotContent(
              context, 
              workstationIdentifier, 
              workstationComponents, 
              'System Unit',
              scaleFactor,
            ),
          ),
          VerticalDivider(color: Colors.black, width: 1, thickness: 1),
          Expanded(
            flex: 3, // Matches Mouse width proportion
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8 * scaleFactor),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 2, // 2/4 = 0.5 of height. Since parent is flex 2, 0.5 * 2 = 1.0 (Matches Keyboard/AVR height)
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
    final bool isCreationMode = ref.watch(isCreationModeProvider);
    
    return SizedBox(
      height: 56 * scaleFactor,
      child: ElevatedButton(
        onPressed: () {
          if (isCreationMode) {
            // First click: Close creation mode only
            ref.read(isCreationModeProvider.notifier).state = false;
            ref.read(selectedCreationTypeProvider.notifier).state = null;
            ref.read(draftComponentProvider.notifier).state = {};
          } else {
            // Second click (or if not in creation): Close inspector
            _closeInspector();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCreationMode ? Colors.black : const Color(0xFF374151),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: Text(
          isCreationMode ? 'CLOSE CREATION' : 'CLOSE',
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
    
    // Reset Creation State (Double-safety)
    ref.read(isCreationModeProvider.notifier).state = false;
    ref.read(selectedCreationTypeProvider.notifier).state = null;
    ref.read(draftComponentProvider.notifier).state = {};

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
}
