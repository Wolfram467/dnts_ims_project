import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// WORKSTATION STORAGE UTILITIES
/// ============================================================================
/// Centralized storage layer for workstation and component data.
/// Handles CRUD operations for SharedPreferences.
/// ============================================================================

class WorkstationStorage {
  /// ============================================================================
  /// READ OPERATIONS
  /// ============================================================================

  /// Get all components for a specific workstation
  static Future<List<Map<String, dynamic>>?> getWorkstationComponents(
    String workstationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('workstation_$workstationId');

    if (jsonString == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      print('❌ Error decoding workstation data: $e');
    }

    return null;
  }

  /// Get a specific component from a workstation by category
  static Future<Map<String, dynamic>?> getComponent(
    String workstationId,
    String category,
  ) async {
    final components = await getWorkstationComponents(workstationId);
    if (components == null) return null;

    try {
      return components.firstWhere(
        (c) => c['category']?.toString().toLowerCase() == category.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a workstation has data
  static Future<bool> hasWorkstationData(String workstationId) async {
    final components = await getWorkstationComponents(workstationId);
    return components != null && components.isNotEmpty;
  }

  /// ============================================================================
  /// WRITE OPERATIONS
  /// ============================================================================

  /// Save complete workstation data
  static Future<bool> saveWorkstationComponents(
    String workstationId,
    List<Map<String, dynamic>> components,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(components);
      await prefs.setString('workstation_$workstationId', jsonString);
      print('✓ Saved workstation: $workstationId (${components.length} components)');
      return true;
    } catch (e) {
      print('❌ Error saving workstation data: $e');
      return false;
    }
  }

  /// Update a specific component in a workstation
  static Future<bool> updateComponent(
    String workstationId,
    String category,
    Map<String, dynamic> updatedComponent,
  ) async {
    try {
      final components = await getWorkstationComponents(workstationId);
      if (components == null) {
        print('❌ Workstation not found: $workstationId');
        return false;
      }

      // Find and update the component
      bool found = false;
      for (int i = 0; i < components.length; i++) {
        if (components[i]['category']?.toString().toLowerCase() ==
            category.toLowerCase()) {
          components[i] = updatedComponent;
          found = true;
          break;
        }
      }

      if (!found) {
        print('❌ Component not found: $category in $workstationId');
        return false;
      }

      // Save updated components
      return await saveWorkstationComponents(workstationId, components);
    } catch (e) {
      print('❌ Error updating component: $e');
      return false;
    }
  }

  /// ============================================================================
  /// DELETE OPERATIONS
  /// ============================================================================

  /// Delete a workstation's data
  static Future<bool> deleteWorkstation(String workstationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('workstation_$workstationId');
      print('✓ Deleted workstation: $workstationId');
      return true;
    } catch (e) {
      print('❌ Error deleting workstation: $e');
      return false;
    }
  }

  /// Clear all workstation data
  static Future<int> clearAllWorkstations() async {
    print('🧹 Clearing all workstation data...');
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();
    int removedCount = 0;

    for (final key in keys) {
      if (key.startsWith('workstation_')) {
        await prefs.remove(key);
        removedCount++;
      }
    }

    print('✅ Cleared $removedCount workstations from storage');
    return removedCount;
  }

  /// ============================================================================
  /// VALIDATION
  /// ============================================================================

  /// Validate DNTS serial format
  static bool isValidDntsSerial(String serial) {
    // Format: CT1_LAB[1-7]_[MR|M|K|SU|SSD|AVR][01-99]
    final regex = RegExp(r'^CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$');
    return regex.hasMatch(serial);
  }

  /// Validate component status
  static bool isValidStatus(String status) {
    const validStatuses = [
      'Deployed',
      'Under Maintenance',
      'Borrowed',
      'Storage',
      'Retired',
    ];
    return validStatuses.contains(status);
  }

  /// Check if DNTS serial is unique within a lab
  static Future<bool> isDntsSerialUnique(
    String dntsSerial,
    String currentWorkstationId,
    String currentCategory,
  ) async {
    // Extract lab number from workstation ID (e.g., "L5_D01" -> 5)
    final labMatch = RegExp(r'L(\d+)_').firstMatch(currentWorkstationId);
    if (labMatch == null) return true;

    final labNumber = labMatch.group(1);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workstation_L${labNumber}_'));

    for (final key in keys) {
      final workstationId = key.replaceFirst('workstation_', '');
      final components = await getWorkstationComponents(workstationId);

      if (components != null) {
        for (final component in components) {
          // Skip the current component being edited
          if (workstationId == currentWorkstationId &&
              component['category'] == currentCategory) {
            continue;
          }

          // Check for duplicate
          if (component['dnts_serial'] == dntsSerial) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// ============================================================================
  /// QUERY OPERATIONS
  /// ============================================================================

  /// Get all workstation IDs in storage
  static Future<List<String>> getAllWorkstationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workstation_'));

    return keys.map((k) => k.replaceFirst('workstation_', '')).toList()..sort();
  }

  /// Get all workstation IDs for a specific lab
  static Future<List<String>> getLabWorkstationIds(int labNumber) async {
    final allIds = await getAllWorkstationIds();
    return allIds.where((id) => id.startsWith('L${labNumber}_')).toList();
  }

  /// Count total workstations in storage
  static Future<int> countWorkstations() async {
    final ids = await getAllWorkstationIds();
    return ids.length;
  }

  /// ============================================================================
  /// DEBUG UTILITIES
  /// ============================================================================

  /// List all workstation data (for debugging)
  static Future<void> debugListAll() async {
    print('\n📋 LISTING ALL WORKSTATION DATA');
    print('═══════════════════════════════════════════════════════════════');

    final ids = await getAllWorkstationIds();

    if (ids.isEmpty) {
      print('❌ No workstation data found in storage');
      print('═══════════════════════════════════════════════════════════════\n');
      return;
    }

    print('Found ${ids.length} workstations:\n');

    for (final id in ids) {
      final components = await getWorkstationComponents(id);
      if (components != null) {
        print('  $id → ${components.length} components:');
        for (final component in components) {
          print('    - ${component['dnts_serial']} (${component['category']})');
        }
      }
    }

    print('═══════════════════════════════════════════════════════════════\n');
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = await getAllWorkstationIds();

    final stats = <String, dynamic>{
      'total_workstations': allIds.length,
      'labs': <int, int>{},
    };

    for (int lab = 1; lab <= 7; lab++) {
      final labIds = allIds.where((id) => id.startsWith('L${lab}_')).toList();
      if (labIds.isNotEmpty) {
        stats['labs'][lab] = labIds.length;
      }
    }

    stats['auto_seeded'] = prefs.getBool('labs_auto_seeded') ?? false;
    stats['seed_timestamp'] = prefs.getString('auto_seed_timestamp');

    return stats;
  }
}
