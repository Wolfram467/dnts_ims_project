import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _filteredMovements = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('movement_logs')
          .select('''
            *,
            asset:serialized_assets!movement_logs_asset_id_fkey(id, dnts_serial),
            user:profiles!movement_logs_action_by_fkey(id, full_name),
            previous_location:locations!movement_logs_previous_loc_id_fkey(id, name),
            new_location:locations!movement_logs_new_loc_id_fkey(id, name)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _movements = List<Map<String, dynamic>>.from(response);
        _filteredMovements = _movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading movement history: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _filterMovements(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMovements = _movements;
      });
      return;
    }

    setState(() {
      _filteredMovements = _movements.where((movement) {
        final asset = movement['asset'];
        final serial = asset?['dnts_serial']?.toString().toLowerCase() ?? '';
        return serial.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  bool _isStatusChange(String? statusChange) {
    if (statusChange == null) return false;
    return statusChange.toLowerCase().contains('->') ||
        statusChange.toLowerCase().contains('repair') ||
        statusChange.toLowerCase().contains('maintenance');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                'Movement History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMovements,
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

        // Search Bar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterMovements,
            decoration: InputDecoration(
              labelText: 'Search by DNTS Serial',
              hintText: 'CT1_LAB6_SU1',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterMovements('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),

        // Movement Feed
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : _filteredMovements.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No movement history found'
                            : 'No results for "${_searchController.text}"',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _filteredMovements.length,
                      itemBuilder: (context, index) {
                        final movement = _filteredMovements[index];
                        final asset = movement['asset'];
                        final user = movement['user'];
                        final previousLoc = movement['previous_location'];
                        final newLoc = movement['new_location'];
                        final statusChange = movement['status_change'];
                        final timestamp = movement['created_at'];

                        final assetSerial = asset?['dnts_serial'] ?? 'Unknown Asset';
                        final userName = user?['full_name'] ?? 'Unknown User';
                        final fromLocation = previousLoc?['name'] ?? 'Unknown';
                        final toLocation = newLoc?['name'] ?? 'Unknown';

                        final isStatusChange = _isStatusChange(statusChange);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isStatusChange ? Colors.red : Colors.black,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timestamp
                                Text(
                                  _formatDate(timestamp),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 8),

                                // Main Event Description
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          height: 1.5,
                                        ),
                                    children: [
                                      TextSpan(
                                        text: userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' moved ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: assetSerial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isStatusChange
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' from ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: fromLocation,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' to ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: toLocation,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Change (if applicable)
                                if (statusChange != null &&
                                    statusChange.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isStatusChange
                                            ? Colors.red
                                            : Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      statusChange,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isStatusChange
                                            ? Colors.red
                                            : Colors.grey.shade700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],

                                // Borrower Name (if applicable)
                                if (movement['borrower_name'] != null &&
                                    movement['borrower_name'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Borrower: ${movement['borrower_name']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
