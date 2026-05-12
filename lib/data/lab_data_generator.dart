import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================================
/// LAB DATA GENERATOR
/// ============================================================================
/// Programmatically generates workstation data for Labs 1-7.
/// 
/// DNTS Serial Format: CT1_LAB#_[MR|M|K|SU|SSD|AVR]##
/// ============================================================================

class LabDataGenerator {
  /// Lab configurations: number of desks per lab
  static const Map<int, int> labDeskCounts = {
    1: 48,
    2: 48,
    3: 46, // 2 pillars
    4: 46, // 2 pillars
    5: 48,
    6: 48,
    7: 48,
  };

  /// Component categories in order
  static const List<String> categories = [
    'System Unit',
    'Monitor',
    'Keyboard',
    'Mouse',
    'SSD',
    'AVR',
  ];

  /// Category abbreviations for DNTS serial
  static const Map<String, String> categoryAbbreviations = {
    'System Unit': 'SU',
    'Monitor': 'MR',
    'Keyboard': 'K',
    'Mouse': 'M',
    'SSD': 'SSD',
    'AVR': 'AVR',
  };

  /// ============================================================================
  /// GENERATE LAB DATA
  /// ============================================================================

  /// Generate complete workstation data for a specific lab
  static Map<String, List<Map<String, String>>> generateLabData(int labNumber) {
    final deskCount = labDeskCounts[labNumber];
    if (deskCount == null) {
      throw ArgumentError('Invalid lab number: $labNumber');
    }

    final Map<String, List<Map<String, String>>> labData = {};

    for (int deskNum = 1; deskNum <= deskCount; deskNum++) {
      final deskId = 'L${labNumber}_D${deskNum.toString().padLeft(2, '0')}';
      final components = <Map<String, String>>[];

      for (final category in categories) {
        final abbreviation = categoryAbbreviations[category]!;
        final dntsSerial = 'CT1_LAB${labNumber}_$abbreviation${deskNum.toString().padLeft(2, '0')}';

        components.add({
          'category': category,
          'mfg_serial': 'UNKNOWN',
          'dnts_serial': dntsSerial,
          'status': 'FUNCTIONAL',
          'brand': 'UNKNOWN',
        });
      }

      labData[deskId] = components;
    }

    return labData;
  }

  /// ============================================================================
  /// AUTO-SEED FUNCTIONS (ONLINE-ONLY)
  /// ============================================================================

  /// Utility to seed the remote Supabase database instead of local storage.
  /// Ensure you only call this when absolutely necessary, as it performs bulk inserts.
  static Future<void> seedSupabaseDatabase() async {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🌱 SEEDING SUPABASE REMOTE DB (LABS 1-7)');
    print('═══════════════════════════════════════════════════════════════\n');

    final supabase = Supabase.instance.client;
    int totalWorkstations = 0;

    // 1. Fetch all locations and map name to UUID
    print('Fetching location UUIDs...');
    final List<dynamic> locationsResponse = await supabase.from('locations').select('id, name');
    final Map<String, String> locationNameMap = {};
    for (final loc in locationsResponse) {
      locationNameMap[loc['name']] = loc['id'].toString();
    }

    // 2. Generate payloads
    final List<Map<String, dynamic>> allComponentsToInsert = [];

    for (final labEntry in labDeskCounts.entries) {
      final labNumber = labEntry.key;
      final deskCount = labEntry.value;

      final labData = generateLabData(labNumber);

      for (final entry in labData.entries) {
        final workstationId = entry.key; // e.g. L1_D01
        final components = entry.value;
        final locationId = locationNameMap[workstationId];

        if (locationId == null) {
          print('Warning: Location $workstationId not found in Supabase locations table. Skipping.');
          continue;
        }

        for (final comp in components) {
          allComponentsToInsert.add({
            'dnts_serial': comp['dnts_serial'],
            'mfg_serial': comp['mfg_serial'],
            'category': comp['category'],
            'status': comp['status'],
            'brand': comp['brand'],
            'current_loc_id': locationId,
          });
        }
        totalWorkstations++;
      }
    }

    // 3. Batch insert using chunks to prevent hitting limits
    print('Inserting ${allComponentsToInsert.length} components into serialized_assets...');
    const chunkSize = 100;
    for (int i = 0; i < allComponentsToInsert.length; i += chunkSize) {
      final end = (i + chunkSize < allComponentsToInsert.length) ? i + chunkSize : allComponentsToInsert.length;
      final chunk = allComponentsToInsert.sublist(i, end);
      
      try {
        await supabase.from('serialized_assets').upsert(chunk, onConflict: 'dnts_serial');
        print('  ✓ Inserted chunk ${i ~/ chunkSize + 1}');
      } catch (e) {
        print('  ❌ Error inserting chunk: $e');
      }
    }

    print('\n✅ REMOTE SUPABASE SEED COMPLETE!');
    print('📦 Total workstations seeded: $totalWorkstations');
    print('═══════════════════════════════════════════════════════════════\n');
  }

  /// ============================================================================
  /// UTILITY FUNCTIONS
  /// ============================================================================

  /// Get total number of workstations across all labs
  static int getTotalWorkstationCount() {
    return labDeskCounts.values.reduce((a, b) => a + b);
  }

  /// Get desk count for a specific lab
  static int? getDeskCount(int labNumber) {
    return labDeskCounts[labNumber];
  }

  /// Validate DNTS serial format
  static bool isValidDntsSerial(String serial) {
    // Format: CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$
    final regex = RegExp(r'^CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$');
    return regex.hasMatch(serial);
  }

  /// Generate a single component
  static Map<String, String> generateComponent({
    required String category,
    required int labNumber,
    required int deskNumber,
    String mfgSerial = 'UNKNOWN',
  }) {
    final abbreviation = categoryAbbreviations[category];
    if (abbreviation == null) {
      throw ArgumentError('Invalid category: $category');
    }

    final dntsSerial = 'CT1_LAB${labNumber}_$abbreviation${deskNumber.toString().padLeft(2, '0')}';

    return {
      'category': category,
      'mfg_serial': mfgSerial,
      'dnts_serial': dntsSerial,
    };
  }
}
