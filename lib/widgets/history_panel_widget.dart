import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_panel_provider.dart';
import '../screens/movement_history_screen.dart';

class HistoryPanelWidget extends ConsumerStatefulWidget {
  const HistoryPanelWidget({super.key});

  @override
  ConsumerState<HistoryPanelWidget> createState() => _HistoryPanelWidgetState();
}

class _HistoryPanelWidgetState extends ConsumerState<HistoryPanelWidget> {
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
    final isOpen = ref.watch(historyPanelProvider);
    final logsAsync = ref.watch(movementLogsStreamProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Panel width configuration
    final double panelWidth = screenWidth > 600 ? 400 : screenWidth * 0.85;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: isOpen ? 0 : -panelWidth,
      top: 0,
      bottom: 0,
      child: Container(
        width: panelWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MOVEMENT LEDGER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(historyPanelProvider.notifier).close(),
                  ),
                ],
              ),
            ),

            // Search Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'FILTER BY SERIAL',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ),

            // Ledger List
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
                    return const Center(child: Text('NO RECORDS', style: TextStyle(letterSpacing: 1.5, fontSize: 12)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final log = filtered[index];
                      final assetSerial = log['asset']?['dnts_serial'] ?? 'UNKNOWN';
                      final fromLoc = log['previous_location']?['name'];
                      final toLoc = log['new_location']?['name'] ?? 'Unknown';
                      final timestamp = _formatDate(log['created_at']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(timestamp, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                if (fromLoc == null) _buildBadge('NEW', Colors.black) else _buildBadge('MOVE', Colors.black),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                                children: [
                                  TextSpan(text: assetSerial, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const TextSpan(text: ' moved to '),
                                  TextSpan(text: toLoc, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (fromLoc != null) ...[
                                    const TextSpan(text: ' from '),
                                    TextSpan(text: fromLoc, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ],
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
      ),
    );
  }
}
