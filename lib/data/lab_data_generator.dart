import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
        });
      }

      labData[deskId] = components;
    }

    return labData;
  }

  /// ============================================================================
  /// AUTO-SEED FUNCTIONS
  /// ============================================================================

  /// Check if labs have been auto-seeded
  static Future<bool> isAutoSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('labs_auto_seeded') ?? false;
  }

  /// Auto-seed all labs (1-4) with generated data
  static Future<void> autoSeedAllLabs() async {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🌱 AUTO-SEEDING LABS 1-7 WITH GENERATED DATA');
    print('═══════════════════════════════════════════════════════════════\n');

    final prefs = await SharedPreferences.getInstance();
    int totalWorkstations = 0;

    for (final labEntry in labDeskCounts.entries) {
      final labNumber = labEntry.key;
      final deskCount = labEntry.value;

      print('📊 Generating Lab $labNumber data ($deskCount workstations)...');

      final labData = generateLabData(labNumber);

      // Save each workstation to SharedPreferences
      for (final entry in labData.entries) {
        final workstationId = entry.key;
        final components = entry.value;

        final jsonString = jsonEncode(components);
        await prefs.setString('workstation_$workstationId', jsonString);
        totalWorkstations++;
      }

      print('  ✓ Lab $labNumber seeded: $deskCount workstations');
    }

    // Mark as seeded
    await prefs.setBool('labs_auto_seeded', true);
    await prefs.setString('auto_seed_timestamp', DateTime.now().toIso8601String());

    print('\n✅ AUTO-SEED COMPLETE!');
    print('📦 Total workstations seeded: $totalWorkstations');
    print('🔒 Auto-seed flag set (will not seed again)');
    print('═══════════════════════════════════════════════════════════════\n');
  }

  /// Force re-seed (clears auto-seed flag and re-generates data)
  static Future<void> forceReseed() async {
    print('🔄 Force re-seeding labs 1-7...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('labs_auto_seeded', false);
    await autoSeedAllLabs();
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
    // Format: CT1_LAB[1-7]_[MR|M|K|SU|SSD|AVR][01-99]
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
