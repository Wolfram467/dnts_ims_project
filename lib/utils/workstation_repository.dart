import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// WORKSTATION REPOSITORY
/// ============================================================================
/// Centralized storage layer for workstation and component data.
/// Handles CRUD operations for SharedPreferences.
/// ============================================================================

class WorkstationRepository {
  /// ============================================================================
  /// READ OPERATIONS
  /// ============================================================================

  /// Get all components for a specific workstation
  static Future<List<Map<String, dynamic>>?> getWorkstationComponents(
    String workstationIdentifier,
  ) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final serializedWorkstationData = sharedPreferences.getString('workstation_$workstationIdentifier');

    if (serializedWorkstationData == null) {
      return null;
    }

    try {
      final decodedWorkstationData = jsonDecode(serializedWorkstationData);
      if (decodedWorkstationData is List) {
        return decodedWorkstationData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (exception) {
      print('❌ Error decoding workstation data: $exception');
    }

    return null;
  }

  /// Get a specific component from a workstation by category
  static Future<Map<String, dynamic>?> getComponentByCategory(
    String workstationIdentifier,
    String componentCategory,
  ) async {
    final workstationComponents = await getWorkstationComponents(workstationIdentifier);
    if (workstationComponents == null) return null;

    try {
      return workstationComponents.firstWhere(
        (component) => component['category']?.toString().toLowerCase() == componentCategory.toLowerCase(),
      );
    } catch (exception) {
      return null;
    }
  }

  /// Check if a workstation has data
  static Future<bool> hasWorkstationData(String workstationIdentifier) async {
    final workstationComponents = await getWorkstationComponents(workstationIdentifier);
    return workstationComponents != null && workstationComponents.isNotEmpty;
  }

  /// ============================================================================
  /// WRITE OPERATIONS
  /// ============================================================================

  /// Save complete workstation data
  static Future<bool> saveWorkstationComponents(
    String workstationIdentifier,
    List<Map<String, dynamic>> workstationComponents,
  ) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final serializedWorkstationData = jsonEncode(workstationComponents);
      await sharedPreferences.setString('workstation_$workstationIdentifier', serializedWorkstationData);
      print('✓ Saved workstation: $workstationIdentifier (${workstationComponents.length} components)');
      return true;
    } catch (exception) {
      print('❌ Error saving workstation data: $exception');
      return false;
    }
  }

  /// Update a specific component in a workstation
  static Future<bool> updateWorkstationComponent(
    String workstationIdentifier,
    String componentCategory,
    Map<String, dynamic> updatedComponent,
  ) async {
    try {
      final workstationComponents = await getWorkstationComponents(workstationIdentifier);
      if (workstationComponents == null) {
        print('❌ Workstation not found: $workstationIdentifier');
        return false;
      }

      // Find and update the component
      bool isComponentFound = false;
      for (int index = 0; index < workstationComponents.length; index++) {
        if (workstationComponents[index]['category']?.toString().toLowerCase() ==
            componentCategory.toLowerCase()) {
          workstationComponents[index] = updatedComponent;
          isComponentFound = true;
          break;
        }
      }

      if (!isComponentFound) {
        print('❌ Component not found: $componentCategory in $workstationIdentifier');
        return false;
      }

      // Save updated components
      return await saveWorkstationComponents(workstationIdentifier, workstationComponents);
    } catch (exception) {
      print('❌ Error updating component: $exception');
      return false;
    }
  }

  /// ============================================================================
  /// DELETE OPERATIONS
  /// ============================================================================

  /// Delete a workstation's data
  static Future<bool> deleteWorkstation(String workstationIdentifier) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove('workstation_$workstationIdentifier');
      print('✓ Deleted workstation: $workstationIdentifier');
      return true;
    } catch (exception) {
      print('❌ Error deleting workstation: $exception');
      return false;
    }
  }

  /// Clear all workstation data
  static Future<int> clearAllWorkstations() async {
    print('🧹 Clearing all workstation data...');
    final sharedPreferences = await SharedPreferences.getInstance();

    final preferenceKeys = sharedPreferences.getKeys();
    int removedWorkstationCount = 0;

    for (final preferenceKey in preferenceKeys) {
      if (preferenceKey.startsWith('workstation_')) {
        await sharedPreferences.remove(preferenceKey);
        removedWorkstationCount++;
      }
    }

    print('✅ Cleared $removedWorkstationCount workstations from storage');
    return removedWorkstationCount;
  }

  /// ============================================================================
  /// VALIDATION
  /// ============================================================================

  /// Validate DNTS serial format
  static bool isValidDntsSerialNumber(String serialNumber) {
    // Format: CT1_LAB[1-7]_[MR|M|K|SU|SSD|AVR][01-99]
    final serialNumberRegex = RegExp(r'^CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$');
    return serialNumberRegex.hasMatch(serialNumber);
  }

  /// Validate component status
  static bool isValidDeploymentStatus(String deploymentStatus) {
    const validDeploymentStatuses = [
      'Deployed',
      'Under Maintenance',
      'Borrowed',
      'Storage',
      'Retired',
    ];
    return validDeploymentStatuses.contains(deploymentStatus);
  }

  /// Check if DNTS serial is unique within a lab
  static Future<bool> isDntsSerialNumberUnique(
    String dntsSerialNumber,
    String currentWorkstationIdentifier,
    String componentCategory,
  ) async {
    // Extract lab number from workstation ID (e.g., "L5_D01" -> 5)
    final facilityLabMatch = RegExp(r'L(\d+)_').firstMatch(currentWorkstationIdentifier);
    if (facilityLabMatch == null) return true;

    final labNumberString = facilityLabMatch.group(1);
    final sharedPreferences = await SharedPreferences.getInstance();
    final labWorkstationKeys = sharedPreferences.getKeys().where((key) => key.startsWith('workstation_L${labNumberString}_'));

    for (final workstationKey in labWorkstationKeys) {
      final workstationIdentifier = workstationKey.replaceFirst('workstation_', '');
      final workstationComponents = await getWorkstationComponents(workstationIdentifier);

      if (workstationComponents != null) {
        for (final component in workstationComponents) {
          // Skip the current component being edited
          if (workstationIdentifier == currentWorkstationIdentifier &&
              component['category'] == componentCategory) {
            continue;
          }

          // Check for duplicate
          if (component['dnts_serial'] == dntsSerialNumber) {
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
  static Future<List<String>> getAllWorkstationIdentifiers() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final workstationKeys = sharedPreferences.getKeys().where((key) => key.startsWith('workstation_'));

    return workstationKeys.map((key) => key.replaceFirst('workstation_', '')).toList()..sort();
  }

  /// Get all workstation IDs for a specific lab
  static Future<List<String>> getLabWorkstationIdentifiers(int labNumber) async {
    final allWorkstationIdentifiers = await getAllWorkstationIdentifiers();
    return allWorkstationIdentifiers.where((identifier) => identifier.startsWith('L${labNumber}_')).toList();
  }

  /// Count total workstations in storage
  static Future<int> countWorkstations() async {
    final workstationIdentifiers = await getAllWorkstationIdentifiers();
    return workstationIdentifiers.length;
  }

  /// ============================================================================
  /// DEBUG UTILITIES
  /// ============================================================================

  /// List all workstation data (for debugging)
  static Future<void> debugListAllWorkstations() async {
    print('\n📋 LISTING ALL WORKSTATION DATA');
    print('═══════════════════════════════════════════════════════════════');

    final workstationIdentifiers = await getAllWorkstationIdentifiers();

    if (workstationIdentifiers.isEmpty) {
      print('❌ No workstation data found in storage');
      print('═══════════════════════════════════════════════════════════════\n');
      return;
    }

    print('Found ${workstationIdentifiers.length} workstations:\n');

    for (final identifier in workstationIdentifiers) {
      final workstationComponents = await getWorkstationComponents(identifier);
      if (workstationComponents != null) {
        print('  $identifier → ${workstationComponents.length} components:');
        for (final component in workstationComponents) {
          print('    - ${component['dnts_serial']} (${component['category']})');
        }
      }
    }

    print('═══════════════════════════════════════════════════════════════\n');
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStatistics() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final allWorkstationIdentifiers = await getAllWorkstationIdentifiers();

    final storageStatistics = <String, dynamic>{
      'total_workstations': allWorkstationIdentifiers.length,
      'labs': <int, int>{},
    };

    for (int labNumber = 1; labNumber <= 7; labNumber++) {
      final labWorkstationIdentifiers = allWorkstationIdentifiers.where((identifier) => identifier.startsWith('L${labNumber}_')).toList();
      if (labWorkstationIdentifiers.isNotEmpty) {
        storageStatistics['labs'][labNumber] = labWorkstationIdentifiers.length;
      }
    }

    storageStatistics['auto_seeded'] = sharedPreferences.getBool('labs_auto_seeded') ?? false;
    storageStatistics['seed_timestamp'] = sharedPreferences.getString('auto_seed_timestamp');

    return storageStatistics;
  }
}

