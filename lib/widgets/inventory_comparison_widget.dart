import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/historical_monitors_lab6.dart';
import '../providers/historical_data_lab6.dart';
import '../providers/historical_data_lab7.dart';
import '../providers/map_state_provider.dart';
import '../providers/historical_baseline_provider.dart';

class InventoryComparisonWidget extends ConsumerStatefulWidget {
  const InventoryComparisonWidget({super.key});

  @override
  ConsumerState<InventoryComparisonWidget> createState() => _InventoryComparisonWidgetState();
}

class _InventoryComparisonWidgetState extends ConsumerState<InventoryComparisonWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(facilityInventoryProvider);
    final selectedFacility = ref.watch(selectedFacilityProvider);

    return inventoryAsync.when(
      data: (liveInventory) {
        // Filter historical data based on selected facility
        final historicalData = _getHistoricalDataForFacility(selectedFacility);
        
        // Identify all unique categories across both datasets
        final allCategories = {
          ...liveInventory.map((e) => e['category'] as String),
          ...historicalData.map((e) => e.category),
        }.toList()..sort();

        if (allCategories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No baseline data available for $selectedFacility',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(context),
            _buildComparisonHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: allCategories.map((category) {
                  return _buildComparisonSection(
                    context, 
                    category, 
                    liveInventory.where((e) => e['category'] == category).toList(),
                    historicalData.where((e) => e.category == category).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search serial, sticker, or desk...',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
      ),
    );
  }

  List<HistoricalRecord> _getHistoricalDataForFacility(String facility) {
    if (facility == 'Lab 6') {
      return [
        ...HistoricalMonitorsLab6.monitorData,
        ...HistoricalDataLab6.lab6Data,
      ];
    } else if (facility == 'Lab 7') {
      return HistoricalDataLab7.lab7Data;
    }
    return [];
  }

  Widget _buildComparisonHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'CURRENT (LIVE)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.compare_arrows, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PREVIOUS (PAPER)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(
    BuildContext context, 
    String title, 
    List<Map<String, dynamic>> liveItems,
    List<HistoricalRecord> historicalItems,
  ) {
    // Create a map of MFG Serial to Live Item for quick lookup
    final Map<String, Map<String, dynamic>> liveMapByMfg = {
      for (var item in liveItems) 
        (item['mfg_serial'] as String? ?? item['mfgSerial'] as String? ?? 'UNKNOWN_MFG_${item['id']}'): item
    };

    // Create a set of all unique MFG Serials across both datasets
    final allMfgSerials = {
      ...liveMapByMfg.keys,
      ...historicalItems.map((e) => e.mfgSerial)
    }.where((s) => s != null && s.isNotEmpty).toList()..sort();

    // Filter by search query
    final filteredSerials = allMfgSerials.where((mfg) {
      if (_searchQuery.isEmpty) return true;
      
      final live = liveMapByMfg[mfg];
      final prev = historicalItems.cast<HistoricalRecord?>().firstWhere(
        (e) => e?.mfgSerial == mfg, 
        orElse: () => null
      );

      final mfgMatch = mfg.toLowerCase().contains(_searchQuery);
      final liveStickerMatch = (live?['dntsSerial'] ?? live?['dnts_serial'] ?? '').toString().toLowerCase().contains(_searchQuery);
      final prevStickerMatch = (prev?.dntsSerial ?? '').toLowerCase().contains(_searchQuery);
      final liveLocMatch = (live?['location']?['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
      final prevLocMatch = (prev?.deskId ?? '').toLowerCase().contains(_searchQuery);

      return mfgMatch || liveStickerMatch || prevStickerMatch || liveLocMatch || prevLocMatch;
    }).toList();

    if (filteredSerials.isEmpty && _searchQuery.isNotEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '$title (${filteredSerials.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        ...filteredSerials.map((mfgSerial) {
          final live = liveMapByMfg[mfgSerial];
          final prev = historicalItems.cast<HistoricalRecord?>().firstWhere(
            (e) => e?.mfgSerial == mfgSerial, 
            orElse: () => null
          );

          return _buildComparisonRow(context, mfgSerial, live, prev);
        }).toList(),
        const Divider(),
      ],
    );
  }

  Widget _buildComparisonRow(
    BuildContext context, 
    String mfgSerial, 
    Map<String, dynamic>? live, 
    HistoricalRecord? prev
  ) {
    final liveLocation = live?['location']?['name'] ?? 'MISSING';
    final prevLocation = prev?.deskId ?? 'NEW';
    final liveSticker = live?['dntsSerial'] ?? live?['dnts_serial'] ?? 'N/A';
    final prevSticker = prev?.dntsSerial ?? 'N/A';
    
    // Logic for color coding based on hardware location
    Color rowColor = Colors.transparent;
    if (live == null) {
      rowColor = Colors.red.withOpacity(0.1); // Missing in live
    } else if (prev == null) {
      rowColor = Colors.blue.withOpacity(0.1); // New item found
    } else if (liveLocation != prevLocation) {
      rowColor = Colors.orange.withOpacity(0.1); // Hardware moved
    } else if (liveSticker != prevSticker) {
      rowColor = Colors.yellow.withOpacity(0.1); // Match location, but sticker changed
    } else {
      rowColor = Colors.green.withOpacity(0.05); // Perfect Match
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          left: BorderSide(
            color: rowColor == Colors.transparent ? Colors.grey.shade300 : rowColor.withOpacity(1),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mfgSerial, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(liveSticker, style: const TextStyle(fontSize: 8, color: Colors.blueAccent)),
                    const SizedBox(width: 4),
                    Text('| $liveLocation', style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(prevSticker, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(prevLocation, style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
