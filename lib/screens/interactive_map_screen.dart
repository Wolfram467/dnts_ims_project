import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/map_state_provider.dart';
import '../utils/drag_boundary_calculator.dart';
import '../services/camera_state_service.dart';
import '../widgets/map_canvas_widget.dart';
import '../widgets/inspector_panel_widget.dart';
import '../services/pdf_report_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 3D: SHELL REFACTOR + AUDIT DASHBOARD
// InteractiveMapScreen is a layout orchestrator and global gesture listener.
// It now includes a toggleable Audit Dashboard with PDF reporting.
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
  bool _isAuditDashboardVisible = false;
  String _selectedFacilityName = 'CT1';
  final List<String> _availableFacilities = [
    'CT1', 'Lab 1', 'Lab 2', 'Lab 3', 'Lab 4', 'Lab 5', 'Lab 6', 'Lab 7',
    'Others', 'Storage', 'CT2'
  ];
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupedAuditComponents = {};
  bool _isAuditDataLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-load data if we start in audit mode (default is false)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

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

  Future<void> _loadFacilityAuditData() async {
    if (!mounted) return;
    setState(() => _isAuditDataLoading = true);
    print('📊 Loading audit data for $_selectedFacilityName...');

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final workstationPreferencesKeys = sharedPreferences.getKeys().where((key) => key.startsWith('workstation_')).toList();
      
      final Map<String, Map<String, List<Map<String, dynamic>>>> componentsByFacilityAndCategory = {};

      for (final workstationKey in workstationPreferencesKeys) {
        final deskIdentifier = workstationKey.replaceFirst('workstation_', '');
        final facilityName = _mapDeskIdentifierToFacilityName(deskIdentifier);

        // Filter by current facility if not "CT1"
        if (_selectedFacilityName != 'CT1' && facilityName != _selectedFacilityName) continue;

        final serializedWorkstationData = sharedPreferences.getString(workstationKey);
        if (serializedWorkstationData != null) {
          final decodedWorkstationComponents = jsonDecode(serializedWorkstationData);
          if (decodedWorkstationComponents is List) {
            final workstationComponents = decodedWorkstationComponents.map((item) => Map<String, dynamic>.from(item as Map)).toList();
            
            for (var component in workstationComponents) {
              final componentCategory = component['category'] ?? 'Unknown';
              
              componentsByFacilityAndCategory.putIfAbsent(facilityName, () => {});
              componentsByFacilityAndCategory[facilityName]!.putIfAbsent(componentCategory, () => []);
              
              // Add deskIdentifier to component for reporting
              final componentWithDeskIdentifier = Map<String, dynamic>.from(component);
              componentWithDeskIdentifier['desk_id'] = deskIdentifier;
              componentsByFacilityAndCategory[facilityName]![componentCategory]!.add(componentWithDeskIdentifier);
            }
          }
        }
      }

      // Sort facilities and categories alphabetically
      final sortedFacilityNames = componentsByFacilityAndCategory.keys.toList()..sort();
      final Map<String, Map<String, List<Map<String, dynamic>>>> sortedAuditComponents = {};
      
      for (var facilityName in sortedFacilityNames) {
        final categoriesMap = componentsByFacilityAndCategory[facilityName]!;
        final sortedCategoryNames = categoriesMap.keys.toList()..sort();
        final Map<String, List<Map<String, dynamic>>> sortedCategories = {};
        
        for (var categoryName in sortedCategoryNames) {
          // Sort components within category alphabetically by deskIdentifier
          final categoryComponents = categoriesMap[categoryName]!;
          categoryComponents.sort((a, b) => (a['desk_id'] ?? '').compareTo(b['desk_id'] ?? ''));
          sortedCategories[categoryName] = categoryComponents;
        }
        sortedAuditComponents[facilityName] = sortedCategories;
      }

      if (!mounted) return;
      setState(() {
        _groupedAuditComponents = sortedAuditComponents;
        _isAuditDataLoading = false;
      });
      
      int totalComponentCount = 0;
      for (var facilityMap in _groupedAuditComponents.values) {
        for (var componentList in facilityMap.values) {
          totalComponentCount += componentList.length;
        }
      }
      print('✅ Loaded $totalComponentCount components across ${_groupedAuditComponents.length} facilities');
    } catch (exception) {
      print('❌ Error loading audit data: $exception');
      if (mounted) setState(() => _isAuditDataLoading = false);
    }
  }

  void _toggleAuditDashboard() {
    setState(() {
      _isAuditDashboardVisible = !_isAuditDashboardVisible;
    });
    if (_isAuditDashboardVisible) {
      _loadFacilityAuditData();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final activeDraggingComponent = ref.watch(draggingComponentProvider);
    final currentDragPositionOffset = ref.watch(dragPositionProvider);

    // Listen for global refresh triggers
    ref.listen(refreshTriggerProvider, (previousRefreshCount, currentRefreshCount) {
      if (currentRefreshCount > 0) {
        print('🔄 GLOBAL REFRESH TRIGGERED: Reloading data');
        _loadFacilityAuditData();
      }
    });

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScreenHeader(context),
          Expanded(
            child: _isAuditDashboardVisible 
              ? _buildAuditDashboardView()
              : Listener(
                  onPointerMove: (pointerEvent) => _processPointerMovement(context, ref, pointerEvent),
                  child: Stack(
                    children: [
                      const MapCanvasWidget(),
                      const InspectorPanelWidget(),
                      if (activeDraggingComponent != null)
                        _buildDraggableGhostOverlay(activeDraggingComponent, currentDragPositionOffset),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScreenHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  _toggleAuditDashboard();
                  // Call refresh logic if audit dashboard is active
                  if (_isAuditDashboardVisible) {
                    _loadFacilityAuditData();
                  }
                  // Increment global refresh trigger for other components
                  ref.read(refreshTriggerProvider.notifier).state++;
                  // Reset camera to global view
                  ref.read(cameraControlProvider.notifier).fitAllLabs();
                },
                mouseCursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isAuditDashboardVisible ? Colors.black : Colors.white,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Icon(
                    _isAuditDashboardVisible ? Icons.map : Icons.assessment,
                    color: _isAuditDashboardVisible ? Colors.white : Colors.black,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _isAuditDashboardVisible ? 'Audit Dashboard: $_selectedFacilityName' : 'Inventory Management System',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
              ),
            ],
          ),
          Row(
            children: [
              if (_isAuditDashboardVisible) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFacilityName,
                      icon: const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.domain, size: 18)),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13),
                      items: _availableFacilities.map((facility) => DropdownMenuItem(value: facility, child: Text(facility))).toList(),
                      onChanged: (selectedFacility) {
                        if (selectedFacility != null) {
                          setState(() => _selectedFacilityName = selectedFacility);
                          print('🏢 FACILITY SWITCHED: $_selectedFacilityName');
                          if (_isAuditDashboardVisible) _loadFacilityAuditData();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.print, size: 18),
                    onPressed: _groupedAuditComponents.isEmpty ? null : () async {
                      await PdfReportService.generateInventoryReport(_selectedFacilityName, _groupedAuditComponents);
                    },
                    tooltip: 'Print Ledger',
                    style: IconButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!_isAuditDashboardVisible) ...[
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () => ref.read(cameraControlProvider.notifier).zoomIn(),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.keyboard),
                onPressed: () => _displayKeyboardShortcutsDialog(context),
                tooltip: 'Keyboard Shortcuts',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditDashboardView() {
    if (_isAuditDataLoading) return const Center(child: CircularProgressIndicator(color: Colors.black));
    if (_groupedAuditComponents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No audit data available for $_selectedFacilityName', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFacilityAuditData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('RETRY LOADING'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF9FAFB),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _groupedAuditComponents.keys.length,
        itemBuilder: (context, index) {
          final facilityName = _groupedAuditComponents.keys.elementAt(index);
          final categoriesMap = _groupedAuditComponents[facilityName]!;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            child: ExpansionTile(
              title: Text('$facilityName (${categoriesMap.values.fold(0, (sum, list) => sum + list.length)} Items)', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              leading: const Icon(Icons.domain, color: Colors.black),
              children: categoriesMap.keys.map((categoryName) {
                final categoryComponents = categoriesMap[categoryName]!;
                
                return ExpansionTile(
                  title: Text('$categoryName (${categoryComponents.length} Items)', style: const TextStyle(fontWeight: FontWeight.w500)),
                  leading: const Icon(Icons.inventory_2, size: 18, color: Colors.black),
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowHeight: 40,
                        border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                        columns: const [
                          DataColumn(label: Text('Desk Identifier', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('DNTS Serial Number', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Manufacturing Serial', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: categoryComponents.map((component) => DataRow(
                          cells: [
                            DataCell(Text(component['desk_id'] ?? 'N/A')),
                            DataCell(Text(component['dnts_serial'] ?? 'N/A')),
                            DataCell(Text(component['mfg_serial'] ?? 'N/A')),
                            DataCell(_buildStatusBadge(component['status'])),
                          ],
                        )).toList(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String? deploymentStatus) {
    final statusColor = _resolveStatusColor(deploymentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.2), border: Border.all(color: statusColor)),
      child: Text(deploymentStatus ?? 'Deployed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
    );
  }

  Color _resolveStatusColor(String? deploymentStatus) {
    switch (deploymentStatus?.toLowerCase()) {
      case 'deployed': return Colors.green.shade700;
      case 'under maintenance': return Colors.orange.shade700;
      case 'borrowed': return Colors.blue.shade700;
      case 'storage': return Colors.grey.shade700;
      case 'retired': return Colors.red.shade700;
      default: return Colors.green.shade700;
    }
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
  }

  void _deactivateInspectorPanel(WidgetRef widgetRef) {
    widgetRef.read(inspectorStateProvider.notifier).closeInspector();
    widgetRef.read(activeDeskProvider.notifier).clearActiveDesk();
    widgetRef.read(activeDeskComponentsProvider.notifier).clearComponents();
    widgetRef.read(selectedDeskProvider.notifier).clearSelection();
  }

  Widget _buildDraggableGhostOverlay(Map<String, dynamic> component, Offset positionOffset) {
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
                  Text(component['category'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(component['dnts_serial'] ?? 'N/A', style: const TextStyle(fontSize: 9, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
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

