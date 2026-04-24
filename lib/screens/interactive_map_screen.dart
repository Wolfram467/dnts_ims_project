import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../seed_lab5_data.dart';

class InteractiveMapScreen extends StatefulWidget {
  final String userRole;

  const InteractiveMapScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;
  
  // View Management (Three-way toggle: Map, Spreadsheet, History)
  String activeView = 'Map'; // Options: 'Map', 'Spreadsheet', 'History'
  
  List<Map<String, dynamic>> _spreadsheetData = []; // Flattened data for spreadsheet
  List<dynamic> auditLogs = []; // Audit trail logs
  
  // Global Handoff State (for drag feedback)
  Map<String, dynamic>? _draggingComponent;
  Offset _dragPosition = Offset.zero;
  
  // In-Screen Dock State
  String? _activeDeskId; // Tracks which desk's dock is open
  bool _isDraggingComponent = false; // Tracks if a drag is active
  List<Map<String, dynamic>> _activeDeskComponents = []; // Components for active desk
  
  // Status Filter Hit List (Phase 3)
  String activeFilter = 'All';
  final List<String> statusFilters = ['All', 'Deployed', 'Borrowed', 'Under Maintenance', 'Missing', 'Retired', 'In Storage'];
  
  // Professional Status Options (for editing) - Borrowed and Retired can only be set via drag zones
  final List<String> statusOptions = ['Deployed', 'Under Maintenance', 'Missing', 'In Storage'];
  
  // Global Sniper Search (Target Bravo)
  String searchQuery = '';

  // Fixed dimensions for perfect alignment
  static const double deskWidth = 50.0;
  static const double deskHeight = 35.0;
  static const double deskMargin = 1.0;
  static const double aisleHeight = 45.0; // Global aisle size - physical walkways between blocks
  static const double labPadding = 16.0; // Uniform padding inside all lab containers
  static const double labBorderWidth = 1.0; // Border width
  
  // Calculate exact vertical positions for alignment
  // Each block is: (rows * (deskHeight + 2*deskMargin))
  // Block of 2 rows = 2 * (35 + 2) = 74px
  static const double blockHeight2Rows = 74.0;
  static const double blockHeight1Row = 37.0;
  
  // Account for padding and border in slot calculations
  // When a lab starts, it adds: labPadding (top) + labBorderWidth (top border)
  static const double labTopOffset = labPadding + labBorderWidth;
  
  // Slot positions (Y-coordinates from top of Wing B)
  // All labs start with the same top offset, so alignment is maintained
  static const double slot1Y = 0.0; // L1-B1 and L3-B1 start here
  static const double slot3Y = slot1Y + labTopOffset + (2 * blockHeight2Rows) + (2 * aisleHeight) + labPadding + labBorderWidth; // L1-B3 and L4-B1
  static const double slot4Y = slot3Y + labTopOffset + blockHeight2Rows + aisleHeight; // L2-B1 and L4-B2
  static const double slot5Y = slot4Y + labTopOffset + blockHeight2Rows + aisleHeight; // L2-B2 and L5-B1

  @override
  void initState() {
    super.initState();
    _autoInitializeData();
    _loadAssets();
    _loadAuditLogs();
  }

  Future<void> _autoInitializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('is_initialized') ?? false;
    
    if (!isInitialized) {
      print('🚀 AUTO-INITIALIZING Lab 5 data (first run)...');
      
      final dataCount = getWorkstationDataCount();
      if (dataCount > 0) {
        await seedLab5Data();
        await prefs.setBool('is_initialized', true);
        print('✅ Auto-initialization complete. System ready.');
      } else {
        print('⚠️  No workstation data found in seed file.');
      }
    } else {
      print('✓ System already initialized. Skipping auto-seed.');
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('serialized_assets')
          .select('*')
          .order('dnts_serial');

      setState(() {
        _assets = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assets: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _loadAuditLogs() async {
    print('📜 Loading audit logs...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJsonString = prefs.getString('dnts_audit_logs');
      
      if (logsJsonString != null) {
        final decoded = jsonDecode(logsJsonString);
        if (decoded is List) {
          setState(() {
            auditLogs = decoded;
          });
          print('✅ Loaded ${auditLogs.length} audit log entries');
        }
      } else {
        print('ℹ️  No audit logs found');
        setState(() {
          auditLogs = [];
        });
      }
    } catch (e) {
      print('❌ Error loading audit logs: $e');
      setState(() {
        auditLogs = [];
      });
    }
  }

  Future<void> _loadDeskComponents(String deskId) async {
    print('🖱️ Desk clicked: $deskId');
    print('🔍 Loading components for dock...');
    
    // Query local storage for this specific workstation
    final localAssets = await getWorkstationAssets(deskId);
    
    if (localAssets != null && localAssets.isNotEmpty) {
      print('✅ Found in local storage: ${localAssets.length} components');
      setState(() {
        _activeDeskId = deskId;
        _activeDeskComponents = localAssets;
      });
    } else {
      print('❌ No assets found in local storage for: $deskId');
      setState(() {
        _activeDeskId = deskId;
        _activeDeskComponents = [];
      });
    }
  }

  Future<void> _listStoredData() async {
    print('\n═══════════════════════════════════════');
    print('📋 LIST STORED DATA TRIGGERED FROM UI');
    print('═══════════════════════════════════════\n');
    
    await listAllWorkstationData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Check terminal for stored data listing'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateComponent(
    String workstationId, 
    int componentIndex, 
    String newSerial,
    String newStatus,
    String newNotes,
  ) async {
    print('💾 Updating component...');
    print('   Workstation: $workstationId');
    print('   Component Index: $componentIndex');
    print('   New Serial: $newSerial');
    print('   New Status: $newStatus');
    print('   New Notes: $newNotes');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('workstation_$workstationId');
      
      if (jsonString == null) {
        throw Exception('Workstation data not found');
      }
      
      final decoded = jsonDecode(jsonString);
      if (decoded is List && componentIndex < decoded.length) {
        final assetsList = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        
        // Update the component fields
        assetsList[componentIndex]['dnts_serial'] = newSerial;
        assetsList[componentIndex]['status'] = newStatus;
        assetsList[componentIndex]['notes'] = newNotes;
        
        // Save back to SharedPreferences
        final updatedJsonString = jsonEncode(assetsList);
        await prefs.setString('workstation_$workstationId', updatedJsonString);
        
        print('✅ Component updated successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Component updated: $newSerial ($newStatus)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error updating component: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating component: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // AUDIT TRAIL: Silent Movement History Logger
  Future<void> _logMovement(
    String dntsSerial,
    String category,
    String source,
    String target,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create the audit log payload
      final logEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'action_type': 'MOVE',
        'dnts_serial': dntsSerial,
        'category': category,
        'source_location': source,
        'target_location': target,
        'user': 'Local Admin',
      };
      
      // Retrieve existing logs
      final logsJsonString = prefs.getString('dnts_audit_logs');
      List<Map<String, dynamic>> logs = [];
      
      if (logsJsonString != null) {
        final decoded = jsonDecode(logsJsonString);
        if (decoded is List) {
          logs = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      
      // Add new log to the beginning (newest first)
      logs.insert(0, logEntry);
      
      // Save back to SharedPreferences
      await prefs.setString('dnts_audit_logs', jsonEncode(logs));
      
      print('📝 AUDIT LOG: Movement recorded - ${logEntry['id']}');
      
    } catch (e) {
      print('❌ Error logging movement: $e');
      // Silent failure - don't interrupt the user's workflow
    }
  }

  Future<void> _handleComponentDrop(Map<String, dynamic> draggedComponent, String targetDeskId) async {
    print('🔄 HANDLING COMPONENT DROP');
    print('   Source Desk: ${draggedComponent['source_desk']}');
    print('   Target Desk: $targetDeskId');
    print('   Component: ${draggedComponent['category']} - ${draggedComponent['dnts_serial']}');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourceDeskId = draggedComponent['source_desk'] as String;
      
      // 1. Remove from source desk
      final sourceJsonString = prefs.getString('workstation_$sourceDeskId');
      if (sourceJsonString != null) {
        final sourceDecoded = jsonDecode(sourceJsonString);
        if (sourceDecoded is List) {
          final sourceList = sourceDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          
          // Remove the dragged component
          sourceList.removeWhere((item) => 
            item['dnts_serial'] == draggedComponent['dnts_serial']
          );
          
          // Save updated source desk
          await prefs.setString('workstation_$sourceDeskId', jsonEncode(sourceList));
          print('   ✓ Removed from source desk');
        }
      }
      
      // 2. Add to target desk (ADDITIVE - no overwrite)
      final targetJsonString = prefs.getString('workstation_$targetDeskId');
      List<Map<String, dynamic>> targetList = [];
      
      if (targetJsonString != null) {
        final targetDecoded = jsonDecode(targetJsonString);
        if (targetDecoded is List) {
          targetList = targetDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      
      // PHASE 4: RECOVERY LOGIC - If item was Borrowed, revert to Deployed when dropped on desk
      final currentStatus = draggedComponent['status'] ?? 'Deployed';
      final recoveredStatus = currentStatus == 'Borrowed' ? 'Deployed' : currentStatus;
      
      if (currentStatus == 'Borrowed' && recoveredStatus == 'Deployed') {
        print('   🔄 RECOVERY: Borrowed item returned to desk, status → Deployed');
      }
      
      // Add the new component
      final newComponent = {
        'category': draggedComponent['category'],
        'dnts_serial': draggedComponent['dnts_serial'],
        'mfg_serial': draggedComponent['mfg_serial'],
        'status': recoveredStatus,
        'notes': draggedComponent['notes'] ?? '',
      };
      targetList.add(newComponent);
      
      // Save updated target desk
      await prefs.setString('workstation_$targetDeskId', jsonEncode(targetList));
      print('   ✓ Added to target desk');
      
      print('✅ DROP COMPLETE - Fluid persistence saved');
      
      // 2.5. AUDIT TRAIL: Log the movement
      await _logMovement(
        draggedComponent['dnts_serial'] ?? 'UNKNOWN',
        draggedComponent['category'] ?? 'UNKNOWN',
        sourceDeskId,
        targetDeskId,
      );
      
      // 3. Auto-Focus Preview: Switch dock to show target desk inventory
      print('🎯 AUTO-FOCUS: Switching dock to target desk: $targetDeskId');
      setState(() {
        _activeDeskId = targetDeskId;
      });
      
      // 4. Load target desk components to display in dock
      await _loadDeskComponents(targetDeskId);
      
      // 5. Refresh spreadsheet if in spreadsheet mode
      if (activeView == 'Spreadsheet') {
        await _loadSpreadsheetData();
      }
      
    } catch (e) {
      print('❌ Error handling drop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving component: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showEditSerialDialog(String workstationId, int componentIndex, String currentSerial, String category) async {
    // Load current component data
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('workstation_$workstationId');
    
    String currentStatus = 'Deployed';
    String currentNotes = '';
    
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString);
      if (decoded is List && componentIndex < decoded.length) {
        final component = decoded[componentIndex];
        currentStatus = component['status'] ?? 'Deployed';
        currentNotes = component['notes'] ?? '';
      }
    }
    
    final TextEditingController serialController = TextEditingController(text: currentSerial);
    final TextEditingController notesController = TextEditingController(text: currentNotes);
    String selectedStatus = currentStatus;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            'Edit $category',
            style: const TextStyle(
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workstation: $workstationId',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // DNTS Serial Field
                TextField(
                  controller: serialController,
                  decoration: InputDecoration(
                    labelText: 'DNTS Serial',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                
                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                
                // Notes Field
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: selectedStatus == 'Retired' ? 'Notes (Required for Retired)' : 'Notes (Optional)',
                    hintText: selectedStatus == 'Retired' 
                        ? 'e.g., Broken capacitor, screen damage...' 
                        : 'Additional information...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: selectedStatus == 'Retired' ? Colors.orange : Colors.grey,
                        width: selectedStatus == 'Retired' ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: selectedStatus == 'Retired' ? Colors.orange.shade700 : Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                
                // Warning for Retired status
                if (selectedStatus == 'Retired')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please provide a reason for retirement',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final newSerial = serialController.text.trim();
                final newNotes = notesController.text.trim();
                
                // Validation
                if (newSerial.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Serial number cannot be empty'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
                
                if (selectedStatus == 'Retired' && newNotes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notes are required when retiring a component'),
                      backgroundColor: Colors.orange.shade700,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _updateComponent(workstationId, componentIndex, newSerial, selectedStatus, newNotes);
                
                // Refresh the dock
                await _loadDeskComponents(workstationId);
                
                // Refresh spreadsheet if in spreadsheet mode
                if (activeView == 'Spreadsheet') {
                  await _loadSpreadsheetData();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSpreadsheetData() async {
    print('📊 Loading spreadsheet data from local storage...');
    
    final List<Map<String, dynamic>> flattenedData = [];
    
    // Get all workstation data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workstation_')).toList();
    keys.sort();
    
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final workstationId = key.replaceFirst('workstation_', '');
        
        try {
          final decoded = jsonDecode(jsonString);
          if (decoded is List) {
            final assetsList = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
            
            // Flatten: each component becomes a row
            for (final asset in assetsList) {
              flattenedData.add({
                'desk_id': workstationId,
                'category': asset['category'] ?? 'N/A',
                'dnts_serial': asset['dnts_serial'] ?? 'N/A',
                'mfg_serial': asset['mfg_serial'] ?? 'N/A',
                'status': asset['status'] ?? 'Deployed', // Default status
              });
            }
          }
        } catch (e) {
          print('Error parsing data for $workstationId: $e');
        }
      }
    }
    
    setState(() {
      _spreadsheetData = flattenedData;
    });
    
    print('✅ Loaded ${flattenedData.length} components for spreadsheet view');
  }

  void _switchView(String newView) async {
    print('🔄 SWITCHING VIEW: $activeView → $newView');
    
    setState(() {
      activeView = newView;
    });
    
    // Load data based on view
    if (newView == 'Spreadsheet') {
      print('   Loading spreadsheet data...');
      await _loadSpreadsheetData();
    } else if (newView == 'History') {
      print('   Loading audit logs...');
      await _loadAuditLogs();
    }
  }

  Widget _buildHistoryView() {
    if (auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No movement history recorded',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag and drop components to create audit logs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 28, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'Movement History (${auditLogs.length} Records)',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Audit Log List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: auditLogs.length,
              itemBuilder: (context, index) {
                final log = auditLogs[index];
                final timestamp = DateTime.parse(log['timestamp'] ?? DateTime.now().toIso8601String());
                final formattedDate = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          border: Border.all(color: Colors.blue.shade700, width: 1),
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        '${log['dnts_serial']} (${log['category']})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Moved from ${log['source_location']} to ${log['target_location']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedDate • ${log['user']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          border: Border.all(color: Colors.green.shade700, width: 1),
                        ),
                        child: Text(
                          log['action_type'] ?? 'MOVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDock() {
    if (_activeDeskId == null) return const SizedBox.shrink();
    
    // Check for duplicates
    Map<String, int> categoryCounts = {};
    for (final component in _activeDeskComponents) {
      final category = component['category'] ?? 'Unknown';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    
    return AnimatedOpacity(
      opacity: _isDraggingComponent ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: _isDraggingComponent,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _activeDeskId!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            border: Border.all(color: Colors.green.shade700, width: 1),
                          ),
                          child: Text(
                            '${_activeDeskComponents.length} Components',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _activeDeskId = null;
                              _activeDeskComponents = [];
                            });
                          },
                          tooltip: 'Close Dock',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Components List
              Expanded(
                child: _activeDeskComponents.isEmpty
                    ? Center(
                        child: Text(
                          'Empty Workstation',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activeDeskComponents.length,
                        itemBuilder: (context, index) {
                          final component = _activeDeskComponents[index];
                          final category = component['category'] ?? 'Unknown';
                          final isDuplicate = (categoryCounts[category] ?? 0) > 1;
                          
                          Widget componentCard = Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDuplicate ? Colors.yellow.shade100 : Colors.white,
                              border: Border.all(
                                color: isDuplicate ? Colors.orange.shade700 : Colors.black,
                                width: isDuplicate ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isDuplicate)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${index + 1}. $category',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isDuplicate ? Colors.orange.shade900 : Colors.black,
                                            ),
                                          ),
                                          if (isDuplicate)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade700,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: const Text(
                                                  'DUPLICATE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'DNTS: ${component['dnts_serial'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Mfg: ${component['mfg_serial'] ?? 'N/A'}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () {
                                    _showEditSerialDialog(
                                      _activeDeskId!,
                                      index,
                                      component['dnts_serial'] ?? '',
                                      category,
                                    );
                                  },
                                  tooltip: 'Edit Serial',
                                ),
                              ],
                            ),
                          );
                          
                          // Make draggable
                          return LongPressDraggable<Map<String, dynamic>>(
                            data: {
                              'category': category,
                              'dnts_serial': component['dnts_serial'],
                              'mfg_serial': component['mfg_serial'],
                              'status': component['status'] ?? 'Deployed',
                              'source_desk': _activeDeskId!,
                            },
                            delay: const Duration(milliseconds: 300),
                            dragAnchorStrategy: pointerDragAnchorStrategy,
                            feedback: Material(
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
                                      category,
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
                                      component['dnts_serial'] ?? 'N/A',
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
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: componentCard,
                            ),
                            onDragStarted: () {
                              print('🎯 DRAG STARTED: ${component['dnts_serial']}');
                              setState(() {
                                _isDraggingComponent = true;
                              });
                              print('   ✓ Dock hidden, map fully visible');
                            },
                            onDragEnd: (details) {
                              print('🏁 DRAG ENDED');
                              setState(() {
                                _isDraggingComponent = false;
                                // Don't close dock here - auto-focus preview will show target desk
                              });
                            },
                            onDragCompleted: () {
                              print('✅ DRAG COMPLETED');
                            },
                            onDraggableCanceled: (velocity, offset) {
                              print('❌ DRAG CANCELLED');
                              setState(() {
                                _isDraggingComponent = false;
                                _activeDeskId = null; // Close dock on cancel
                              });
                            },
                            child: componentCard,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDesk(String deskLabel, {bool isPillar = false}) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => !isPillar, // Don't accept drops on pillars
      onAccept: (draggedComponent) async {
        print('📦 DROP ACCEPTED');
        print('   Component: ${draggedComponent['dnts_serial']}');
        print('   Target Desk: $deskLabel');
        
        await _handleComponentDrop(draggedComponent, deskLabel);
        
        // Clear global dragging state
        setState(() {
          _draggingComponent = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty || _draggingComponent != null;
        
        return GestureDetector(
          onTap: isPillar ? null : () {
            // If we're dragging, treat tap as drop
            if (_draggingComponent != null) {
              _handleComponentDrop(_draggingComponent!, deskLabel);
              setState(() {
                _draggingComponent = null;
              });
            } else {
              // Open dock for this desk
              _loadDeskComponents(deskLabel);
            }
          },
          child: Container(
            width: deskWidth,
            height: deskHeight,
            margin: const EdgeInsets.all(deskMargin),
            decoration: BoxDecoration(
              color: isPillar 
                  ? Colors.grey.shade400 
                  : isHovering 
                      ? Colors.blue.shade100 
                      : Colors.white,
              border: Border.all(
                color: isHovering ? Colors.blue : Colors.black, 
                width: isHovering ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                isPillar ? '' : deskLabel,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(int labNum, int rows, int cols, int blockIndex, int deskCounter, List<String>? pillars) {
    int currentDesk = deskCounter;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (rowIndex) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (colIndex) {
            final isPillar = pillars?.contains('R${rowIndex + 1}C${colIndex + 1}') ?? false;
            final deskLabel = isPillar ? '' : 'L${labNum}_T${currentDesk.toString().padLeft(2, '0')}';
            if (!isPillar) currentDesk++;
            return _buildDesk(deskLabel, isPillar: isPillar);
          }),
        );
      }),
    );
  }

  Widget _buildLab(String labName, int labNum, List<List<int>> blockConfigs, {bool showLabel = true}) {
    int deskCounter = 1;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label sits in the aisle space (45px total height)
        if (showLabel)
          SizedBox(
            height: aisleHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  labName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        // Lab Container with walls (1px border) and uniform padding
        Container(
          padding: const EdgeInsets.all(16.0), // Strict uniform padding
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blockConfigs.asMap().entries.map((entry) {
              final blockIndex = entry.key;
              final config = entry.value;
              final rows = config[0];
              final cols = config[1];
              
              List<String>? pillars;
              if (labNum == 3 && blockIndex == 1) {
                pillars = ['R1C1', 'R1C2'];
              } else if (labNum == 4 && blockIndex == 1) {
                pillars = ['R2C1', 'R2C2'];
              }

              final block = _buildBlock(labNum, rows, cols, blockIndex, deskCounter, pillars);
              
              // Update desk counter
              final totalDesks = rows * cols;
              final pillarCount = pillars?.length ?? 0;
              deskCounter += (totalDesks - pillarCount);

              return Padding(
                padding: EdgeInsets.only(bottom: blockIndex < blockConfigs.length - 1 ? aisleHeight : 0),
                child: block,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpreadsheetView() {
    if (_spreadsheetData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the seed button (☁️) to load Lab 5 data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // MASTER FOLDERS: Define the exact list of locations
    final List<String> locationFolders = [
      'Lab 1',
      'Lab 2',
      'Lab 3',
      'Lab 4',
      'Lab 5',
      'Lab 6',
      'Lab 7',
      'Others',
      'Storage',
      'CT2',
      'Borrowed Zone', // PHASE 4: SPATIAL STATUS LOGIC
      'Retired/Archive', // PHASE 4: SPATIAL STATUS LOGIC
    ];

    // LOCATION MATCHER: Helper function to map asset to folder based on desk_id
    String getLocationFolder(Map<String, dynamic> asset) {
      final deskId = (asset['desk_id'] ?? '').toString().toUpperCase();
      
      // PHASE 4: SPATIAL STATUS LOGIC - Handle special zones
      if (deskId.contains('LOANER_ZONE') || deskId == 'LOANER_ZONE') return 'Borrowed Zone';
      if (deskId.contains('ARCHIVE') || deskId == 'ARCHIVE') return 'Retired/Archive';
      
      if (deskId.contains('L1_') || deskId.contains('LAB1')) return 'Lab 1';
      if (deskId.contains('L2_') || deskId.contains('LAB2')) return 'Lab 2';
      if (deskId.contains('L3_') || deskId.contains('LAB3')) return 'Lab 3';
      if (deskId.contains('L4_') || deskId.contains('LAB4')) return 'Lab 4';
      if (deskId.contains('L5_') || deskId.contains('LAB5')) return 'Lab 5';
      if (deskId.contains('L6_') || deskId.contains('LAB6')) return 'Lab 6';
      if (deskId.contains('L7_') || deskId.contains('LAB7')) return 'Lab 7';
      if (deskId.contains('CT2')) return 'CT2';
      if (deskId.contains('STORAGE') || deskId.contains('STR')) return 'Storage';
      
      return 'Others';
    }

    // MASTER FILING CABINET UI: Column with Header + ListView of Location Folders
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Context Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, size: 28, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'Audit Dashboard',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // GLOBAL SNIPER SEARCH BAR (Target Bravo)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                hintText: 'Search serial, category, or notes...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          // STATUS FILTER CHIPS (Hit List)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statusFilters.map((filterName) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filterName),
                      selected: activeFilter == filterName,
                      onSelected: (bool selected) {
                        setState(() {
                          activeFilter = filterName;
                        });
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: activeFilter == filterName ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Master List: Location Folders (Level 1)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: locationFolders.length,
              itemBuilder: (context, folderIndex) {
                final folderName = locationFolders[folderIndex];
                
                // STEP A: Filter assets for this location folder
                final folderAssets = _spreadsheetData.where((asset) {
                  return getLocationFolder(asset) == folderName;
                }).toList();
                
                // STEP B: Apply status filter if not 'All'
                final statusFilteredAssets = activeFilter == 'All'
                    ? folderAssets
                    : folderAssets.where((asset) {
                        // Treat missing status as 'Deployed' by default
                        final status = asset['status'] ?? 'Deployed';
                        return status == activeFilter;
                      }).toList();
                
                // STEP C: TRIPLE FILTER - Apply search query (Global Sniper Search)
                final tripleFilteredAssets = searchQuery.isEmpty
                    ? statusFilteredAssets
                    : statusFilteredAssets.where((asset) {
                        final dntsSerial = (asset['dnts_serial'] ?? '').toString().toLowerCase();
                        final mfgSerial = (asset['mfg_serial'] ?? '').toString().toLowerCase();
                        final category = (asset['category'] ?? '').toString().toLowerCase();
                        final notes = (asset['notes'] ?? '').toString().toLowerCase();
                        
                        return dntsSerial.contains(searchQuery) ||
                               mfgSerial.contains(searchQuery) ||
                               category.contains(searchQuery) ||
                               notes.contains(searchQuery);
                      }).toList();
                
                // DYNAMIC FOLDER HIDING: If any filter is active and folder is empty, hide it
                if ((activeFilter != 'All' || searchQuery.isNotEmpty) && tripleFilteredAssets.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                // EMPTY STATE: No items in this folder (only show when no filters active)
                if (tripleFilteredAssets.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: ExpansionTile(
                      leading: Icon(Icons.folder, color: Colors.grey.shade400),
                      initiallyExpanded: false,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        '$folderName (0 Items)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // POPULATED STATE: Group triple-filtered assets by category
                Map<String, List<Map<String, dynamic>>> groupedByCategory = {};
                
                for (final item in tripleFilteredAssets) {
                  final category = item['category'] ?? 'Unknown';
                  if (!groupedByCategory.containsKey(category)) {
                    groupedByCategory[category] = [];
                  }
                  groupedByCategory[category]!.add(item);
                }
                
                final sortedCategories = groupedByCategory.keys.toList()..sort();
                
                // Level 1 Accordion: Location Folder
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.folder, color: Colors.black),
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      '$folderName (${tripleFilteredAssets.length} Items)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    children: [
                      // Level 2 Accordions: Component Categories inside this folder
                      ...sortedCategories.map((categoryName) {
                        final categoryItems = groupedByCategory[categoryName]!;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              '$categoryName (${categoryItems.length} Items)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            children: [
                              // Horizontal scroll for the data table
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                                    border: TableBorder.all(color: Colors.black, width: 1),
                                    columnSpacing: 40,
                                    horizontalMargin: 20,
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Desk ID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'DNTS Serial',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Mfg Serial',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: categoryItems.map((row) {
                                      final status = row['status'] ?? 'Deployed';
                                      final isRetiredOrMissing = status == 'Retired' || status == 'Missing';
                                      
                                      return DataRow(
                                        cells: [
                                          // Desk ID Cell (with highlighting)
                                          DataCell(_buildHighlightedText(
                                            row['desk_id'] ?? 'N/A',
                                            isRetiredOrMissing,
                                          )),
                                          
                                          // DNTS Serial Cell (with highlighting and icons)
                                          DataCell(
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: searchQuery.isEmpty || 
                                                         !(row['dnts_serial'] ?? '').toString().toLowerCase().contains(searchQuery)
                                                      ? Text(
                                                          row['dnts_serial'] ?? 'N/A',
                                                          style: TextStyle(
                                                            decoration: isRetiredOrMissing ? TextDecoration.lineThrough : null,
                                                            color: isRetiredOrMissing ? Colors.grey.shade600 : Colors.black,
                                                            decorationThickness: 2,
                                                          ),
                                                        )
                                                      : RichText(
                                                          text: TextSpan(
                                                            style: TextStyle(
                                                              decoration: isRetiredOrMissing ? TextDecoration.lineThrough : null,
                                                              color: isRetiredOrMissing ? Colors.grey.shade600 : Colors.black,
                                                              decorationThickness: 2,
                                                              fontSize: 14,
                                                            ),
                                                            children: _buildHighlightedSpans(
                                                              row['dnts_serial'] ?? 'N/A',
                                                              isRetiredOrMissing,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                                if (status == 'Missing')
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Icon(
                                                      Icons.search_off,
                                                      size: 16,
                                                      color: Colors.red.shade700,
                                                    ),
                                                  ),
                                                if (status == 'Retired')
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Icon(
                                                      Icons.archive,
                                                      size: 16,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Mfg Serial Cell (with highlighting)
                                          DataCell(_buildHighlightedText(
                                            row['mfg_serial'] ?? 'N/A',
                                            isRetiredOrMissing,
                                          )),
                                          
                                          // Status Cell (with highlighting)
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(row['status']),
                                                border: Border.all(color: Colors.black, width: 1),
                                              ),
                                              child: searchQuery.isEmpty || !status.toLowerCase().contains(searchQuery)
                                                  ? Text(
                                                      status,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: isRetiredOrMissing ? Colors.grey.shade800 : Colors.black,
                                                      ),
                                                    )
                                                  : RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isRetiredOrMissing ? Colors.grey.shade800 : Colors.black,
                                                        ),
                                                        children: _buildHighlightedSpans(status, isRetiredOrMissing),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'deployed':
        return Colors.green.shade100;
      case 'under maintenance':
        return Colors.orange.shade100;
      case 'borrowed':
        return Colors.blue.shade100;
      case 'in storage':
        return Colors.grey.shade200;
      case 'missing':
        return Colors.red.shade200;
      case 'retired':
        return Colors.grey.shade400;
      default:
        return Colors.green.shade100;
    }
  }
  
  // GLOBAL SNIPER SEARCH: Text Highlighting Helper
  Widget _buildHighlightedText(String text, bool isRetiredOrMissing) {
    if (searchQuery.isEmpty || !text.toLowerCase().contains(searchQuery)) {
      // No highlighting needed
      return Text(
        text,
        style: TextStyle(
          color: isRetiredOrMissing ? Colors.grey.shade600 : Colors.black,
        ),
      );
    }
    
    // Highlight matching text with yellow background
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isRetiredOrMissing ? Colors.grey.shade600 : Colors.black,
          fontSize: 14,
        ),
        children: _buildHighlightedSpans(text, isRetiredOrMissing),
      ),
    );
  }
  
  // Helper to build TextSpan list with highlighting
  List<TextSpan> _buildHighlightedSpans(String text, bool isRetiredOrMissing) {
    if (searchQuery.isEmpty || !text.toLowerCase().contains(searchQuery)) {
      return [TextSpan(text: text)];
    }
    
    final lowerText = text.toLowerCase();
    final startIndex = lowerText.indexOf(searchQuery);
    
    if (startIndex == -1) {
      return [TextSpan(text: text)];
    }
    
    final endIndex = startIndex + searchQuery.length;
    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final afterMatch = text.substring(endIndex);
    
    return [
      if (beforeMatch.isNotEmpty) TextSpan(text: beforeMatch),
      TextSpan(
        text: match,
        style: TextStyle(
          backgroundColor: Colors.yellow.shade200,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      if (afterMatch.isNotEmpty) TextSpan(text: afterMatch),
    ];
  }
  
  // PHASE 4: SPATIAL STATUS LOGIC - Borrowed Zone Handler
  Future<void> _handleBorrowedZoneDrop(Map<String, dynamic> draggedComponent) async {
    print('📦 Processing Borrowed Zone drop...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourceDeskId = draggedComponent['source_desk'] as String;
      
      // 1. Remove from source desk
      final sourceJsonString = prefs.getString('workstation_$sourceDeskId');
      if (sourceJsonString != null) {
        final sourceDecoded = jsonDecode(sourceJsonString);
        if (sourceDecoded is List) {
          final sourceList = sourceDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          
          sourceList.removeWhere((item) => 
            item['dnts_serial'] == draggedComponent['dnts_serial']
          );
          
          await prefs.setString('workstation_$sourceDeskId', jsonEncode(sourceList));
          print('   ✓ Removed from source desk');
        }
      }
      
      // 2. Store in LOANER_ZONE with Borrowed status
      final loanerJsonString = prefs.getString('workstation_LOANER_ZONE');
      List<Map<String, dynamic>> loanerList = [];
      
      if (loanerJsonString != null) {
        final loanerDecoded = jsonDecode(loanerJsonString);
        if (loanerDecoded is List) {
          loanerList = loanerDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      
      final borrowedComponent = {
        'category': draggedComponent['category'],
        'dnts_serial': draggedComponent['dnts_serial'],
        'mfg_serial': draggedComponent['mfg_serial'],
        'status': 'Borrowed',
        'notes': draggedComponent['notes'] ?? '',
      };
      loanerList.add(borrowedComponent);
      
      await prefs.setString('workstation_LOANER_ZONE', jsonEncode(loanerList));
      print('   ✓ Added to LOANER_ZONE with Borrowed status');
      
      // 3. Log the movement
      await _logMovement(
        draggedComponent['dnts_serial'] ?? 'UNKNOWN',
        draggedComponent['category'] ?? 'UNKNOWN',
        sourceDeskId,
        'LOANER_ZONE',
      );
      
      // 4. Refresh views
      setState(() {
        _activeDeskId = null;
      });
      
      if (activeView == 'Spreadsheet') {
        await _loadSpreadsheetData();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 ${draggedComponent['dnts_serial']} marked as BORROWED'),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('✅ Borrowed zone drop complete');
      
    } catch (e) {
      print('❌ Error handling borrowed zone drop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
  
  // PHASE 4: SPATIAL STATUS LOGIC - Retired Zone Handler
  Future<void> _handleRetiredZoneDrop(Map<String, dynamic> draggedComponent) async {
    print('🗑️ Processing Retired Zone drop...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourceDeskId = draggedComponent['source_desk'] as String;
      
      // 1. Remove from source desk
      final sourceJsonString = prefs.getString('workstation_$sourceDeskId');
      if (sourceJsonString != null) {
        final sourceDecoded = jsonDecode(sourceJsonString);
        if (sourceDecoded is List) {
          final sourceList = sourceDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          
          sourceList.removeWhere((item) => 
            item['dnts_serial'] == draggedComponent['dnts_serial']
          );
          
          await prefs.setString('workstation_$sourceDeskId', jsonEncode(sourceList));
          print('   ✓ Removed from source desk');
        }
      }
      
      // 2. Store in ARCHIVE with Retired status
      final archiveJsonString = prefs.getString('workstation_ARCHIVE');
      List<Map<String, dynamic>> archiveList = [];
      
      if (archiveJsonString != null) {
        final archiveDecoded = jsonDecode(archiveJsonString);
        if (archiveDecoded is List) {
          archiveList = archiveDecoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      
      final retiredComponent = {
        'category': draggedComponent['category'],
        'dnts_serial': draggedComponent['dnts_serial'],
        'mfg_serial': draggedComponent['mfg_serial'],
        'status': 'Retired',
        'notes': draggedComponent['notes'] ?? 'Retired via drag-and-drop',
      };
      archiveList.add(retiredComponent);
      
      await prefs.setString('workstation_ARCHIVE', jsonEncode(archiveList));
      print('   ✓ Added to ARCHIVE with Retired status');
      
      // 3. Log the movement
      await _logMovement(
        draggedComponent['dnts_serial'] ?? 'UNKNOWN',
        draggedComponent['category'] ?? 'UNKNOWN',
        sourceDeskId,
        'ARCHIVE',
      );
      
      // 4. Refresh views
      setState(() {
        _activeDeskId = null;
      });
      
      if (activeView == 'Spreadsheet') {
        await _loadSpreadsheetData();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${draggedComponent['dnts_serial']} moved to ARCHIVE'),
            backgroundColor: Colors.grey.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('✅ Retired zone drop complete');
      
    } catch (e) {
      print('❌ Error handling retired zone drop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeView == 'History' ? 'Movement History' : activeView == 'Spreadsheet' ? 'Audit Dashboard' : 'CT1 Floor Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                ),
                Row(
                  children: [
                    // THREE-WAY VIEW TOGGLE (Map, Spreadsheet, History)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Map Button
                          InkWell(
                            onTap: () => _switchView('Map'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: activeView == 'Map' ? Colors.black : Colors.white,
                                border: Border(
                                  right: BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: Icon(
                                Icons.map,
                                color: activeView == 'Map' ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          // Spreadsheet Button
                          InkWell(
                            onTap: () => _switchView('Spreadsheet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: activeView == 'Spreadsheet' ? Colors.black : Colors.white,
                                border: Border(
                                  right: BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: Icon(
                                Icons.table_chart,
                                color: activeView == 'Spreadsheet' ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          // History Button
                          InkWell(
                            onTap: () => _switchView('History'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: activeView == 'History' ? Colors.black : Colors.white,
                              ),
                              child: Icon(
                                Icons.history,
                                color: activeView == 'History' ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Only show zoom buttons in map mode
                    if (activeView == 'Map') ...[
                      IconButton(
                        icon: const Icon(Icons.zoom_out),
                        onPressed: () {
                          final matrix = _transformationController.value.clone();
                          matrix.scale(0.8);
                          _transformationController.value = matrix;
                        },
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () {
                          final matrix = _transformationController.value.clone();
                          matrix.scale(1.2);
                          _transformationController.value = matrix;
                        },
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        if (activeView == 'Map') {
                          _loadAssets();
                        } else if (activeView == 'Spreadsheet') {
                          _loadSpreadsheetData();
                        } else if (activeView == 'History') {
                          _loadAuditLogs();
                        }
                      },
                      tooltip: activeView == 'Map' ? 'Refresh Assets' : activeView == 'Spreadsheet' ? 'Refresh Spreadsheet' : 'Refresh History',
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.list),
                      onPressed: _listStoredData,
                      tooltip: 'List Stored Data',
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content: Map, Spreadsheet, or History
          Expanded(
            child: Listener(
              onPointerMove: (event) {
                if (_draggingComponent != null) {
                  setState(() {
                    _dragPosition = event.position;
                  });
                }
              },
              child: Stack(
                children: [
                  // Main content layer - Three-way view switcher
                  if (activeView == 'History')
                    _buildHistoryView()
                  else if (activeView == 'Spreadsheet')
                    _buildSpreadsheetView()
                  else if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.black))
                  else
                    InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      minScale: 0.3,
                      maxScale: 2.5,
                      boundaryMargin: const EdgeInsets.all(200),
                      child: Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.all(40),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Wing A (Left): Lab 6 & Lab 7
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLab('Lab 6', 6, [
                                      [2, 10],
                                      [2, 10],
                                      [1, 8],
                                    ]),
                                    SizedBox(height: aisleHeight), // Aisle between labs
                                    _buildLab('Lab 7', 7, [
                                      [2, 6],
                                      [2, 6],
                                      [2, 6],
                                      [2, 6],
                                    ], showLabel: false), // No label, continues from Lab 6
                                  ],
                                ),

                                const SizedBox(width: 60),

                                // Wing B (Right): Absolute positioning for perfect alignment
                                SizedBox(
                                  width: 1200, // Wide enough for both columns
                                  height: 1400, // Tall enough for all labs
                                  child: Stack(
                                    children: [
                                      // Lab 1 - Left column, starts at slot1Y
                                      Positioned(
                                        left: 0,
                                        top: slot1Y,
                                        child: _buildLab('Lab 1', 1, [
                                          [2, 8],
                                          [2, 8],
                                          [2, 8],
                                        ]),
                                      ),

                                      // Lab 3 - Right column, starts at slot1Y (same as Lab 1)
                                      Positioned(
                                        left: 500,
                                        top: slot1Y,
                                        child: _buildLab('Lab 3', 3, [
                                          [2, 12],
                                          [2, 12],
                                        ]),
                                      ),

                                      // Lab 2 - Left column, starts at slot4Y
                                      Positioned(
                                        left: 0,
                                        top: slot4Y,
                                        child: _buildLab('Lab 2', 2, [
                                          [2, 8],
                                          [2, 8],
                                          [2, 8],
                                        ]),
                                      ),

                                      // Lab 4 - Right column, starts at slot3Y (aligned with L1-B3)
                                      Positioned(
                                        left: 500,
                                        top: slot3Y,
                                        child: _buildLab('Lab 4', 4, [
                                          [2, 12],
                                          [2, 12],
                                        ]),
                                      ),

                                      // Lab 5 - Right column, starts at slot5Y (aligned with L2-B2)
                                      Positioned(
                                        left: 500,
                                        top: slot5Y,
                                        child: _buildLab('Lab 5', 5, [
                                          [2, 12],
                                          [2, 12],
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  
                  // Global Ghost Overlay - appears when dragging after modal closes
                  if (_draggingComponent != null)
                    Positioned(
                      left: _dragPosition.dx - 60, // Center on cursor (120px width / 2)
                      top: _dragPosition.dy - 30, // Approximate center
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
                                  _draggingComponent!['category'] ?? 'N/A',
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
                                  _draggingComponent!['dnts_serial'] ?? 'N/A',
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
                  
                  // BORROWED ZONE (Bottom-Right) - Phase 4: Spatial Status Logic
                  if (activeView == 'Map')
                    Positioned(
                      right: 20,
                      bottom: 320, // Above the dock
                      child: DragTarget<Map<String, dynamic>>(
                        onWillAccept: (data) => data != null,
                        onAccept: (draggedComponent) async {
                          print('📦 BORROWED ZONE: Item dropped');
                          await _handleBorrowedZoneDrop(draggedComponent);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return Container(
                            width: 150,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isHovering ? Colors.blue.shade100 : Colors.white,
                              border: Border.all(
                                color: Colors.blue.shade700,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: Colors.blue.shade700,
                                strokeWidth: 2,
                                dashLength: 8,
                                gapLength: 4,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 32,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'BORROWED',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // RETIRED ZONE / THE PIT (Bottom-Left) - Phase 4: Spatial Status Logic
                  if (activeView == 'Map')
                    Positioned(
                      left: 20,
                      bottom: 320, // Above the dock
                      child: DragTarget<Map<String, dynamic>>(
                        onWillAccept: (data) => data != null,
                        onAccept: (draggedComponent) async {
                          print('🗑️ RETIRED ZONE: Item dropped');
                          await _handleRetiredZoneDrop(draggedComponent);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return Container(
                            width: 150,
                            height: 100,
                            decoration: BoxDecoration(
                              color: isHovering ? Colors.grey.shade300 : Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade700,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: Colors.grey.shade700,
                                strokeWidth: 2,
                                dashLength: 8,
                                gapLength: 4,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.archive_outlined,
                                      size: 32,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'RETIRED/ARCHIVE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // In-Screen Dock at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildDock(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PHASE 4: SPATIAL STATUS LOGIC - Dashed Border Painter for Borrowed/Retired Zones
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashLength = 8.0,
    this.gapLength = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw dashed rectangle
    _drawDashedLine(canvas, paint, Offset.zero, Offset(size.width, 0)); // Top
    _drawDashedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height)); // Right
    _drawDashedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height)); // Bottom
    _drawDashedLine(canvas, paint, Offset(0, size.height), Offset.zero); // Left
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startFraction = i * (dashLength + gapLength) / distance;
      final endFraction = (i * (dashLength + gapLength) + dashLength) / distance;

      final dashStart = Offset(
        start.dx + dx * startFraction,
        start.dy + dy * startFraction,
      );
      final dashEnd = Offset(
        start.dx + dx * endFraction,
        start.dy + dy * endFraction,
      );

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
