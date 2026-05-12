import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dock_provider.dart';
import '../providers/map_state_provider.dart';
import '../providers/repository_providers.dart';
import '../models/hardware_component.dart';
import '../services/pdf_report_service.dart';
import '../domain/print_settings.dart';

/// A modular, left-aligned sidebar for inventory management and audit.
/// Redesigned from a bottom dock to a sidebar for layout consistency.
class InventoryDockWidget extends ConsumerWidget {
  const InventoryDockWidget({super.key});

  static const availableFacilities = [
    'CT1', 'Lab 1', 'Lab 2', 'Lab 3', 'Lab 4', 'Lab 5', 'Lab 6', 'Lab 7',
    'Others', 'Storage', 'CT2'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dockState = ref.watch(dockProvider);
    final isExpanded = dockState.isExpanded;
    final selectedFacility = ref.watch(selectedFacilityProvider);
    final inventoryAsync = ref.watch(facilityInventoryProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      top: 0,
      bottom: 0,
      left: isExpanded ? 0 : -400,
      width: 400,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          boxShadow: [
            if (isExpanded)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(4, 0),
              ),
          ],
        ),
        child: inventoryAsync.when(
          data: (inventory) {
            final groupedComponents = _groupInventory(inventory);
            return Column(
              children: [
                _buildSidebarHeader(context, ref, selectedFacility, groupedComponents),
                Expanded(child: _buildAuditView(context, ref, groupedComponents)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _groupInventory(List<Map<String, dynamic>> inventory) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> result = {};
    for (final item in inventory) {
      final deskId = item['location']?['name'] as String? ?? 'Unknown';
      final facilityName = _mapDeskIdentifierToFacilityName(deskId);
      final category = item['category'] as String? ?? 'Unknown';

      final enrichedItem = Map<String, dynamic>.from(item);
      enrichedItem['desk_id'] = deskId;

      result.putIfAbsent(facilityName, () => {});
      result[facilityName]!.putIfAbsent(category, () => []);
      result[facilityName]![category]!.add(enrichedItem);
    }
    
    final sortedResult = <String, Map<String, List<Map<String, dynamic>>>>{};
    final sortedFacilities = result.keys.toList()..sort();
    for (final f in sortedFacilities) {
      final sortedCategoriesMap = <String, List<Map<String, dynamic>>>{};
      final sortedCategories = result[f]!.keys.toList()..sort();
      for (final c in sortedCategories) {
        final list = result[f]![c]!;
        list.sort((a, b) => (a['desk_id'] as String).compareTo(b['desk_id'] as String));
        sortedCategoriesMap[c] = list;
      }
      sortedResult[f] = sortedCategoriesMap;
    }
    return sortedResult;
  }

  String _mapDeskIdentifierToFacilityName(String deskIdentifier) {
    if (deskIdentifier.startsWith('L')) {
      final laboratoryMatch = RegExp(r'L(\d+)').firstMatch(deskIdentifier);
      if (laboratoryMatch != null) {
        return 'Lab ${laboratoryMatch.group(1)}';
      }
    }
    if (deskIdentifier.startsWith('Others')) return 'Others';
    if (deskIdentifier.startsWith('Storage')) return 'Storage';
    if (deskIdentifier.startsWith('CT2')) return 'CT2';
    return 'Unknown Facility';
  }

  Widget _buildSidebarHeader(
    BuildContext context, 
    WidgetRef ref, 
    String selectedFacility,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedComponents,
  ) {
    // SECURE UX: All header UI elements (Title, Close, Dropdown, Print) 
    // have been visually removed as requested, while retaining the print 
    // methods in the class for future relocation.
    return const SizedBox.shrink();
  }

  void _showPrintSettingsDialog(
    BuildContext context, 
    WidgetRef ref, 
    String selectedFacility,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedComponents,
  ) {
    if (groupedComponents.isEmpty) return;

    final now = DateTime.now();
    final academicYear = now.month >= 6 
        ? '${now.year}-${now.year + 1}' 
        : '${now.year - 1}-${now.year}';
    final dateUpdated = DateFormat('M/d/yyyy').format(now);

    final academicYearController = TextEditingController(text: academicYear);
    final shiftTypeController = TextEditingController();
    final dateUpdatedController = TextEditingController(text: dateUpdated);
    final taAssignedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Print Settings',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(context, 'Academic Year', academicYearController),
                _buildDialogField(context, 'Shift Type', shiftTypeController),
                _buildDialogField(context, 'Date Updated', dateUpdatedController),
                _buildDialogField(context, 'T.A Assigned', taAssignedController, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final settings = PrintSettings(
                  academicYear: academicYearController.text,
                  dateUpdated: dateUpdatedController.text,
                  taAssignedNames: taAssignedController.text,
                  shiftType: shiftTypeController.text,
                );
                Navigator.of(context).pop();
                await PdfReportService.generateInventoryReport(
                  selectedFacility,
                  groupedComponents,
                  settings,
                );
              },
              child: const Text(
                'PRINT',
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(
    BuildContext context, 
    String label, 
    TextEditingController controller, 
    {int maxLines = 1}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditView(
    BuildContext context,
    WidgetRef ref,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedComponents,
  ) {
    if (groupedComponents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No items found in selected facility',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: groupedComponents.keys.length,
      itemBuilder: (context, facilityIndex) {
        final facilityName = groupedComponents.keys.elementAt(facilityIndex);
        final categoriesMap = groupedComponents[facilityName] ?? {};

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: ExpansionTile(
            title: Text(
              facilityName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            iconColor: Theme.of(context).colorScheme.onSurface,
            collapsedIconColor: Theme.of(context).colorScheme.onSurface,
            children: categoriesMap.keys.map((categoryName) {
              final components = categoriesMap[categoryName] ?? [];
              return ExpansionTile(
                title: Text(
                  '$categoryName (${components.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      horizontalMargin: 12,
                      headingRowHeight: 32,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 48,
                      columns: const [
                        DataColumn(label: Text('DESK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                        DataColumn(label: Text('SERIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                        DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                      ],
                      rows: components.map((comp) => _buildDataRow(context, ref, comp)).toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, WidgetRef ref, Map<String, dynamic> componentJson) {
    final String deskId = componentJson['desk_id'] ?? 'N/A';
    final String serial = componentJson['dnts_serial'] ?? 'N/A';
    final String status = componentJson['status'] ?? 'Deployed';

    return DataRow(
      cells: [
        DataCell(Text(deskId, style: const TextStyle(fontSize: 11))),
        DataCell(
          Draggable<HardwareComponent>(
            data: HardwareComponent.fromJson(componentJson),
            feedback: _buildDragFeedback(context, componentJson),
            onDragStarted: () {
              ref.read(draggingComponentProvider.notifier).setDraggingComponent(HardwareComponent.fromJson(componentJson));
              ref.read(sourceWorkstationProvider.notifier).state = deskId;
              ref.read(dockProvider.notifier).setExpanded(false);
            },
            onDraggableCanceled: (_, __) {
              ref.read(draggingComponentProvider.notifier).clearDragging();
            },
            onDragEnd: (_) {
              ref.read(draggingComponentProvider.notifier).clearDragging();
            },
            child: Text(
              serial,
              style: const TextStyle(
                fontSize: 11,
                decoration: TextDecoration.underline,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ),
        DataCell(_buildStatusBadge(context, status)),
      ],
    );
  }

  Widget _buildDragFeedback(BuildContext context, Map<String, dynamic> componentJson) {
    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.blue.shade100,
        child: Text(
          componentJson['category'] ?? 'Component',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = _resolveStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Color _resolveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'deployed': return Colors.green;
      case 'under maintenance': return Colors.orange;
      case 'missing': return Colors.red;
      default: return Colors.grey;
    }
  }
}
