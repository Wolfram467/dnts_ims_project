import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/create_component_panel.dart';

class InventoryMasterScreen extends StatefulWidget {
  final String userRole;

  const InventoryMasterScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<InventoryMasterScreen> createState() => _InventoryMasterScreenState();
}

class _InventoryMasterScreenState extends State<InventoryMasterScreen> {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  String? _selectedLabFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load locations
      final locationsResponse = await Supabase.instance.client
          .from('locations')
          .select()
          .order('name');

      _locations = List<Map<String, dynamic>>.from(locationsResponse);

      // Load assets with location join
      await _loadAssets();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _loadAssets() async {
    try {
      var query = Supabase.instance.client
          .from('serialized_assets')
          .select('''
            *,
            designated_lab:locations!serialized_assets_designated_lab_id_fkey(id, name),
            current_location:locations!serialized_assets_current_loc_id_fkey(id, name)
          ''');

      // Apply lab filter if selected
      final labFilter = _selectedLabFilter;
      if (labFilter != null) {
        query = query.eq('current_loc_id', labFilter);
      }

      final response = await query.order('dnts_serial');

      setState(() {
        _assets = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
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

  Future<void> _showMoveDialog(Map<String, dynamic> asset) async {
    String? selectedLocationId = asset['current_loc_id'];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Move Asset',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                asset['dnts_serial'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  value: selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'New Location',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  items: _locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['id'],
                      child: Text(loc['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedLocationId = value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(selectedLocationId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('MOVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != asset['current_loc_id']) {
      await _moveAsset(asset, result);
    }
  }

  Future<void> _moveAsset(Map<String, dynamic> asset, String newLocationId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final previousLocId = asset['current_loc_id'];
      final assetId = asset['id'];

      // Update asset location
      await Supabase.instance.client
          .from('serialized_assets')
          .update({'current_loc_id': newLocationId})
          .eq('id', assetId);

      // Create movement log
      await Supabase.instance.client.from('movement_logs').insert({
        'asset_id': assetId,
        'action_by': userId,
        'previous_loc_id': previousLocId,
        'new_loc_id': newLocationId,
        'status_change': 'Location Transfer',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset moved successfully'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reload assets
      _loadAssets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving asset: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Deployed':
        return Colors.black;
      case 'Under Maintenance':
        return Colors.red;
      case 'Borrowed':
        return Colors.orange.shade800;
      case 'Storage':
        return Colors.grey.shade700;
      case 'Retired':
        return Colors.grey.shade500;
      default:
        return Colors.black;
    }
  }

  FontWeight _getStatusWeight(String? status) {
    return status == 'Deployed' ? FontWeight.w600 : FontWeight.normal;
  }

  bool get _canEdit => widget.userRole == 'dnts_head' || widget.userRole == 'lab_ta';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                'Inventory Master List',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAssets,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Bar
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: _isLoading
              ? const SizedBox.shrink()
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    ..._locations.map((loc) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(loc['name'], loc['id']),
                      );
                    }),
                  ],
                ),
        ),

        // Asset List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : _assets.isEmpty
                  ? Center(
                      child: Text(
                        'No assets found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Container(
                        color: Colors.white,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          border: TableBorder.all(color: Colors.black, width: 1),
                          columnSpacing: 24,
                          horizontalMargin: 24,
                          columns: [
                            const DataColumn(
                              label: Text(
                                'DNTS Serial',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (_canEdit)
                              const DataColumn(
                                label: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                          rows: _assets.map((asset) {
                            final currentLoc = asset['current_location'];
                            final status = asset['status'];

                            return DataRow(
                              cells: [
                                DataCell(Text(asset['dnts_serial'] ?? '')),
                                DataCell(Text(asset['category'] ?? '')),
                                DataCell(Text(currentLoc?['name'] ?? 'Unknown')),
                                DataCell(
                                  Text(
                                    status ?? '',
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: _getStatusWeight(status),
                                    ),
                                  ),
                                ),
                                if (_canEdit)
                                  DataCell(
                                    TextButton(
                                      onPressed: () => _showMoveDialog(asset),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('MOVE'),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: CreateComponentPanel(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF374151),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
              child: const Icon(Icons.add_box),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String? locationId) {
    final isSelected = _selectedLabFilter == locationId;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLabFilter = selected ? locationId : null;
        });
        _loadAssets();
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.black,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      side: const BorderSide(color: Colors.black, width: 1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }
}
