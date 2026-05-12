import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/result.dart';
import '../utils/workstation_repository.dart';
import '../services/cloud_sync_service.dart';
import '../models/hardware_component.dart';

/// Domain manager for orchestrating complex inventory operations.
/// Uses Supabase to enforce rules and maintain data integrity.
class InventoryManager {
  final WorkstationRepository _repository;
  final CloudSyncService _syncService;

  InventoryManager(this._repository, this._syncService);

  /// Validates the Swiss Rule (preventing duplicate component categories at a single desk).
  /// Storage locations are exempt from this rule.
  Future<Result<void, Exception>> validateCapacity(String location, String category) async {
    if (location.toLowerCase() == 'storage') {
      return const Success(null);
    }

    try {
      final components = await _repository.getWorkstationComponents(location);
      final alreadyHasCategory = components.any(
        (c) => c.category.toLowerCase() == category.toLowerCase(),
      );

      if (alreadyHasCategory) {
        return Failure(Exception('Location $location already has a $category.'));
      }

      return const Success(null);
    } catch (error) {
      return Failure(Exception('Capacity validation failed: $error'));
    }
  }

  /// Creates a new component after ensuring the location can accommodate it.
  Future<Result<void, Exception>> createComponent(String location, HardwareComponent newComponent) async {
    final validation = await validateCapacity(location, newComponent.category);
    
    bool isValid = false;
    Exception? validationError;
    
    validation.fold(
      (success) => isValid = true,
      (failure) => validationError = failure,
    );
    
    if (!isValid) {
      return Failure(validationError!);
    }
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        // Resolve exact location ID
        final locationId = await _repository.resolveLocationId(location);
        
        if (locationId != null) {
          
          // 2. Insert into remote Supabase serialized_assets table
          await supabase.from('serialized_assets').insert({
            'dnts_serial': newComponent.dntsSerial,
            'mfg_serial': newComponent.mfgSerial,
            'category': newComponent.category,
            'designated_lab_id': locationId,
            'current_loc_id': locationId,
            'status': newComponent.status, // Must be 'Deployed' or 'Storage'
            'notes': newComponent.brand,
            if (newComponent.dateAcquired != null) 'date_acquired': newComponent.dateAcquired,
          });

          // 3. Find the ID of the newly inserted asset
          Map<String, dynamic>? assetResponse;
          int retries = 0;
          while (assetResponse == null && retries < 5) {
            assetResponse = await supabase.from('serialized_assets').select('id').eq('dnts_serial', newComponent.dntsSerial).maybeSingle();
            if (assetResponse == null) {
              retries++;
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
          
          // 4. Log the movement
          if (assetResponse != null) {
            await supabase.from('movement_logs').insert({
              'asset_id': assetResponse['id'],
              'action_by': userId,
              'previous_loc_id': null,
              'new_loc_id': locationId,
              'status_change': 'Initial Deployment',
            });
          }
        } else {
          print('⚠️ Warning: Could not find database location ID for $location');
          return Failure(Exception('Could not resolve database location ID for $location'));
        }
      }

      return const Success(null);
    } catch (error) {
      return Failure(Exception('Component creation failed: $error'));
    }
  }
  /// Moves a hardware component from one workstation to another.
  /// 
  /// Logic:
  /// 1. Validates the Swiss Rule (one component category per desk) via the repository.
  /// 2. Executes an update on the Supabase `serialized_assets` table.
  /// 3. Synchronizes the change log if needed.
  /// 4. Logs movement history.
  /// 
  /// Returns [Success] if the move completed, or [Failure] with an explanation.
  Future<Result<void, Exception>> moveComponent({
    required String componentId,
    required String toWorkstationId,
  }) async {
    try {
      // 1. Validate Swiss Rule: Check if the target workstation already has this category
      final supabase = Supabase.instance.client;
      
      final componentResponse = await supabase
          .from('serialized_assets')
          .select('id, category, current_loc_id')
          .eq('dnts_serial', componentId)
          .maybeSingle();
          
      if (componentResponse == null) {
        return Failure(Exception('Component "$componentId" not found.'));
      }
      
      final category = componentResponse['category'] as String;
      final assetId = componentResponse['id'];
      final previousLocId = componentResponse['current_loc_id'];

      // Check target workstation capacity
      final targetComponents = await _repository.getWorkstationComponents(toWorkstationId);
      final alreadyHasCategory = targetComponents.any(
        (c) => c.category.toLowerCase() == category.toLowerCase(),
      );

      if (alreadyHasCategory) {
        return Failure(Exception('Target workstation "$toWorkstationId" already has a $category.'));
      }

      // 2. Resolve the new location ID
      final newLocationId = await _repository.resolveLocationId(toWorkstationId);
          
      if (newLocationId == null) {
         return Failure(Exception('Target location "$toWorkstationId" not found in database.'));
      }

      // 3. Update the component's location
      await supabase
          .from('serialized_assets')
          .update({'current_loc_id': newLocationId})
          .eq('dnts_serial', componentId);

      // 4. Log the movement
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('movement_logs').insert({
          'asset_id': assetId,
          'action_by': userId,
          'previous_loc_id': previousLocId,
          'new_loc_id': newLocationId,
          'status_change': 'Location Transfer',
        });
      }

      // 5. Optional Cloud Sync logging
      _syncService.syncComponentMove(componentId, toWorkstationId);

      return const Success(null);
    } catch (error) {
      return Failure(Exception('Error during component move: $error'));
    }
  }
}
