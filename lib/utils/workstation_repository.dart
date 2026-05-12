import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hardware_component.dart';

/// ============================================================================
/// WORKSTATION REPOSITORY (ONLINE-ONLY)
/// ============================================================================
/// Centralized data layer for workstation and component data.
/// Uses Supabase as the absolute source of truth.
/// Automatically resolves logical desk names (e.g. 'L5_D01') to location UUIDs.
/// ============================================================================

class WorkstationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper to resolve a location name (like 'L5_D01') to its UUID in the database.
  Future<String?> resolveLocationId(String locationName) async {
    try {
      final cleanName = locationName.trim();
      
      // 1. Prioritize EXACT match first (case-insensitive, handling duplicates safely)
      var response = await _supabase
          .from('locations')
          .select('id')
          .ilike('name', cleanName)
          .limit(1);
          
      if (response != null && response.isNotEmpty) {
        return response.first['id'] as String?;
      }

      // 2. Fallback to fuzzy matching if exact match fails
      String searchTerm = cleanName;
      if (cleanName.startsWith('L') && cleanName.contains('_')) {
        final match = RegExp(r'L(\d+)_').firstMatch(cleanName);
        if (match != null) {
          searchTerm = '%Lab%${match.group(1)}%';
        }
      } else if (cleanName.toLowerCase().contains('storage')) {
        searchTerm = '%Storage%';
      } else {
        searchTerm = '%$cleanName%';
      }

      final fallbackResponse = await _supabase
          .from('locations')
          .select('id')
          .ilike('name', searchTerm)
          .limit(1);
          
      if (fallbackResponse != null && fallbackResponse.isNotEmpty) {
        return fallbackResponse.first['id'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error resolving location name $locationName: $e');
      return null;
    }
  }

  /// ============================================================================
  /// READ OPERATIONS
  /// ============================================================================

  /// Get all components for a specific workstation name (e.g. 'L5_D01')
  Future<List<HardwareComponent>> getWorkstationComponents(
    String workstationIdentifier,
  ) async {
    try {
      final locationId = await resolveLocationId(workstationIdentifier);
      if (locationId == null) return [];

      final response = await _supabase
          .from('serialized_assets')
          .select()
          .eq('current_loc_id', locationId)
          .neq('status', 'Retired'); // <--- Must be Title Case

      final List<HardwareComponent> components = [];
      for (final row in response) {
        components.add(HardwareComponent.fromJson(row));
      }
      return components;
    } catch (exception) {
      print('Error retrieving workstation data for $workstationIdentifier: $exception');
      return [];
    }
  }

  /// Stream all components for a specific workstation name for real-time UI updates
  Stream<List<HardwareComponent>> streamWorkstationComponents(String workstationIdentifier) async* {
    final locationId = await resolveLocationId(workstationIdentifier);
    if (locationId == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('serialized_assets')
        .stream(primaryKey: ['id'])
        .eq('current_loc_id', locationId)
        .map((data) {
          return data
              .where((row) => row['status'] != 'Retired') // <--- Must be Title Case
              .map((row) => HardwareComponent.fromJson(row))
              .toList();
        });
  }

  /// Get a specific component from a workstation by category
  Future<HardwareComponent?> getComponentByCategory(
    String workstationIdentifier,
    String componentCategory,
  ) async {
    final components = await getWorkstationComponents(workstationIdentifier);
    try {
      return components.firstWhere(
        (c) => c.category.toLowerCase() == componentCategory.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasWorkstationData(String workstationIdentifier) async {
    final components = await getWorkstationComponents(workstationIdentifier);
    return components.isNotEmpty;
  }

  /// ============================================================================
  /// WRITE OPERATIONS
  /// ============================================================================

  /// Update a specific component in a workstation
  Future<bool> updateWorkstationComponent(
    String workstationIdentifier,
    String componentCategory,
    HardwareComponent updatedComponent,
  ) async {
    try {
      final locationId = await resolveLocationId(workstationIdentifier);
      if (locationId == null) return false;

      // Find the specific component ID in Supabase
      final response = await _supabase
          .from('serialized_assets')
          .select('id')
          .eq('current_loc_id', locationId)
          .eq('category', componentCategory)
          .maybeSingle();

      if (response == null) return false;

      final assetId = response['id'];

      await _supabase
          .from('serialized_assets')
          .update({
            'dnts_serial': updatedComponent.dntsSerial,
            'mfg_serial': updatedComponent.mfgSerial,
            'status': updatedComponent.status,
            'notes': updatedComponent.brand,
          })
          .eq('id', assetId);

      return true;
    } catch (exception) {
      print('Error updating component: $exception');
      return false;
    }
  }

  /// Insert a new component into a workstation
  Future<bool> insertWorkstationComponent(
    String workstationIdentifier,
    HardwareComponent newComponent,
  ) async {
    try {
      final locationId = await resolveLocationId(workstationIdentifier);
      if (locationId == null) return false;

      await _supabase.from('serialized_assets').insert({
        'dnts_serial': newComponent.dntsSerial,
        'mfg_serial': newComponent.mfgSerial,
        'category': newComponent.category,
        'status': newComponent.status,
        'notes': newComponent.brand,
        'current_loc_id': locationId,
        // Depending on schema, we may need a 'designated_lab_id_fkey' or similar. 
        // Assuming current_loc_id is enough for this prototype.
      });
      return true;
    } catch (exception) {
      print('Error inserting component: $exception');
      return false;
    }
  }

  /// ============================================================================
  /// DELETE OPERATIONS
  /// ============================================================================

  /// Delete a specific component from a workstation
  Future<bool> deleteWorkstationComponent(String workstationIdentifier, String componentCategory) async {
    try {
      final locationId = await resolveLocationId(workstationIdentifier);
      if (locationId == null) return false;

      // Find the specific component ID in Supabase
      final response = await _supabase
          .from('serialized_assets')
          .select('id')
          .eq('current_loc_id', locationId)
          .eq('category', componentCategory)
          .maybeSingle();

      if (response == null) return false;

      final assetId = response['id'];

      await _supabase
          .from('serialized_assets')
          .delete()
          .eq('id', assetId);

      return true;
    } catch (exception) {
      print('Error deleting component: $exception');
      return false;
    }
  }

  /// ============================================================================
  /// VALIDATION
  /// ============================================================================

  /// Validate DNTS serial format
  bool isValidDntsSerialNumber(String serialNumber) {
    final serialNumberRegex = RegExp(r'^CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$');
    return serialNumberRegex.hasMatch(serialNumber);
  }

  /// Validate component status
  bool isValidDeploymentStatus(String deploymentStatus) {
    const validDeploymentStatuses = [
      'Deployed',
      'Borrowed',
      'Under Maintenance',
      'Storage',
      'Retired',
    ];
    return validDeploymentStatuses.contains(deploymentStatus);
  }

  /// Check if DNTS serial is unique within a lab
  Future<bool> isDntsSerialNumberUnique(
    String dntsSerialNumber,
    String currentWorkstationIdentifier,
    String componentCategory,
  ) async {
    try {
      final response = await _supabase
          .from('serialized_assets')
          .select('id')
          .eq('dnts_serial', dntsSerialNumber)
          .maybeSingle();

      if (response == null) return true; // Not found anywhere, so it is unique

      // If it is found, it's only valid if it belongs to the EXACT same component we are editing.
      final locationId = await resolveLocationId(currentWorkstationIdentifier);
      if (locationId == null) return false;
      
      final currentAssetResponse = await _supabase
          .from('serialized_assets')
          .select('id')
          .eq('current_loc_id', locationId)
          .eq('category', componentCategory)
          .maybeSingle();

      if (currentAssetResponse != null && currentAssetResponse['id'] == response['id']) {
        return true; // The found duplicate is actually the same record
      }

      return false;
    } catch (exception) {
      print('Error checking serial number uniqueness: $exception');
      return false;
    }
  }
}
