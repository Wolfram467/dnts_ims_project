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
    final isLoading = dockState.isLoading;
    final groupedComponents = dockState.groupedAuditComponents;
    final selectedFacility = ref.watch(selectedFacilityProvider);

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
        child: Column(
          children: [
            _buildSidebarHeader(context, ref, selectedFacility, groupedComponents),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _buildAuditView(context, ref, groupedComponents),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(
    BuildContext context, 
    WidgetRef ref, 
    String selectedFacility,
    Map<String, Map<String, List<Map<String, dynamic>>>> groupedComponents,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVENTORY AUDIT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              IconButton(
                onPressed: () => ref.read(dockProvider.notifier).toggleExpanded(),
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface, size: 20),
                tooltip: 'Close Sidebar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFacility,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      icon: Icon(Icons.domain, size: 18, color: Theme.of(context).colorScheme.onSurface),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      items: availableFacilities
                          .map((facility) => DropdownMenuItem(value: facility, child: Text(facility)))
                          .toList(),
                      onChanged: (newFacility) {
                        if (newFacility != null) {
                          ref.read(selectedFacilityProvider.notifier).state = newFacility;
                          ref.read(dockProvider.notifier).loadFacilityAuditData();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                ),
                child: IconButton(
                  icon: Icon(Icons.print, size: 18, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => _showPrintSettingsDialog(context, ref, selectedFacility, groupedComponents),
                  tooltip: 'Generate Report',
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
