import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final movementLogsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final controller = StreamController<List<Map<String, dynamic>>>();
  final supabase = Supabase.instance.client;

  Future<void> fetchAndEmit() async {
    try {
      final response = await supabase
          .from('movement_logs')
          .select('''
            *,
            asset:serialized_assets!movement_logs_asset_id_fkey(id, dnts_serial),
            user:profiles!movement_logs_action_by_fkey(id, full_name),
            previous_location:locations!movement_logs_previous_loc_id_fkey(id, name),
            new_location:locations!movement_logs_new_loc_id_fkey(id, name)
          ''')
          .order('created_at', ascending: false);
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  fetchAndEmit();

  final channel = supabase.channel('public:movement_logs').onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'movement_logs',
    callback: (payload) {
      fetchAndEmit();
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});

class MovementHistoryScreen extends ConsumerStatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  ConsumerState<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends ConsumerState<MovementHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM dd, yyyy • HH:mm').format(date).toUpperCase();
    } catch (e) {
      return 'UNKNOWN';
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(movementLogsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
            ),
            child: const Row(
              children: [
                Text(
                  'MOVEMENT LEDGER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'FILTER BY SERIAL',
                labelStyle: const TextStyle(letterSpacing: 1.0),
                hintText: 'e.g. CT1_LAB6_SU1',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
              ),
            ),
          ),

          // Ledger Timeline
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (logs) {
                final filtered = logs.where((log) {
                  if (_searchQuery.isEmpty) return true;
                  final assetSerial = log['asset']?['dnts_serial']?.toString().toLowerCase() ?? '';
                  return assetSerial.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'NO RECORDS FOUND',
                      style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    final assetSerial = log['asset']?['dnts_serial'] ?? 'UNKNOWN';
                    final userName = log['user']?['full_name'] ?? 'System';
                    final fromLoc = log['previous_location']?['name'];
                    final toLoc = log['new_location']?['name'] ?? 'Unknown';
                    final statusChange = log['status_change'] as String?;
                    final timestamp = _formatDate(log['created_at']);

                    final isInitial = statusChange == 'Initial Deployment' || fromLoc == null;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline line & node
                          SizedBox(
                            width: 40,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                if (index != filtered.length - 1)
                                  Container(
                                    width: 1,
                                    color: Colors.black,
                                    margin: const EdgeInsets.only(top: 24), // start line after node
                                  ),
                                Container(
                                  width: 11,
                                  height: 11,
                                  margin: const EdgeInsets.only(top: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content Box
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timestamp,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      if (isInitial)
                                        _buildBadge('NEW', Colors.black)
                                      else
                                        _buildBadge('MOVE', Colors.black),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: assetSerial,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const TextSpan(text: ' was moved by '),
                                        TextSpan(
                                          text: userName,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        if (fromLoc != null) ...[
                                          const TextSpan(text: ' from '),
                                          TextSpan(
                                            text: fromLoc,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                        const TextSpan(text: ' to '),
                                        TextSpan(
                                          text: toLoc,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
