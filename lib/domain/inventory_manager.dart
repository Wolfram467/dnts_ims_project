import 'dart:convert';
import 'package:isar/isar.dart';
import '../core/result.dart';
import '../models/hardware_component.dart';
import '../models/workstation_model.dart';
import '../utils/workstation_repository.dart';
import '../services/cloud_sync_service.dart';

/// Domain manager for orchestrating complex inventory operations.
/// Ensures transactional integrity and business rule enforcement.
class InventoryManager {
  final WorkstationRepository _repository;
  final CloudSyncService _syncService;

  InventoryManager(this._repository, this._syncService);

  /// Moves a hardware component from one workstation to another atomically.
  /// 
  /// Logic:
  /// 1. Initializes the Isar database instance.
  /// 2. Executes a write transaction for atomicity.
  /// 3. Fetches and updates both source and target workstation data.
  /// 4. Enforces the Swiss Rule (one component category per desk).
  /// 5. Commits changes or rolls back on exception.
  /// 6. Synchronizes the change to the cloud if the transaction succeeds.
  /// 
  /// Returns [Success] if the move completed, or [Failure] with an explanation.
  Future<Result<void, Exception>> moveComponent({
    required String componentId,
    required String fromWorkstationId,
    required String toWorkstationId,
  }) async {
    try {
      final isar = await _repository.getDatabaseInstance();

      await isar.writeTxn(() async {
        // 1. Fetch both workstation entities from Isar
        final workstations = isar.workstations;
        final sourceWorkstation = await workstations.filter()
            .identifierEqualTo(fromWorkstationId)
            .findFirst();
        final targetWorkstation = await workstations.filter()
            .identifierEqualTo(toWorkstationId)
            .findFirst();

        if (sourceWorkstation == null) {
          throw Exception('Source workstation "$fromWorkstationId" not found in database');
        }

        // 2. Decode source components and find the target component
        final List<dynamic> sourceJson = jsonDecode(sourceWorkstation.componentsJson);
        final sourceComponents = sourceJson.map((item) => HardwareComponent.fromJson(Map<String, dynamic>.from(item as Map))).toList();

        HardwareComponent? componentToMove;
        final updatedSourceList = <HardwareComponent>[];

        for (final component in sourceComponents) {
          if (component.dntsSerial == componentId) {
            componentToMove = component;
          } else {
            updatedSourceList.add(component);
          }
        }

        if (componentToMove == null) {
          throw Exception('Component "$componentId" not found in workstation "$fromWorkstationId"');
        }

        // 3. Decode target components and verify capacity (Swiss Rule)
        final targetComponentsList = <HardwareComponent>[];
        final bool isTargetPresent = targetWorkstation == null;
        if (isTargetPresent == false) {
          final List<dynamic> targetJson = jsonDecode(targetWorkstation.componentsJson);
          targetComponentsList.addAll(targetJson.map((item) => HardwareComponent.fromJson(Map<String, dynamic>.from(item as Map))));
        }

        final categoryToMatch = componentToMove.category.toLowerCase();
        final bool alreadyHasCategory = targetComponentsList.any(
          (component) => component.category.toLowerCase() == categoryToMatch,
        );

        if (alreadyHasCategory) {
          throw Exception('Target workstation "$toWorkstationId" already has a ${componentToMove.category}');
        }

        // 4. Update both workstation states
        final updatedTargetList = [...targetComponentsList, componentToMove];

        sourceWorkstation.componentsJson = jsonEncode(updatedSourceList.map((c) => c.toJson()).toList());
        
        final targetEntity = targetWorkstation ?? Workstation();
        targetEntity.identifier = toWorkstationId;
        targetEntity.componentsJson = jsonEncode(updatedTargetList.map((c) => c.toJson()).toList());

        // 5. Persist both changes within the same transaction
        await workstations.put(sourceWorkstation);
        await workstations.put(targetEntity);
      });

      // 6. Cloud Sync (Background)
      // Only reached if the transaction above succeeds.
      _syncService.syncComponentMove(componentId, toWorkstationId);

      return const Success(null);
    } catch (error) {
      return Failure(Exception('Unexpected error during atomic component move: $error'));
    }
  }
}
