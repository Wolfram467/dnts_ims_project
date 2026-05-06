import '../core/result.dart';
import '../models/hardware_component.dart';
import '../utils/workstation_repository.dart';

/// Domain manager for orchestrating complex inventory operations.
/// Ensures transactional integrity and business rule enforcement.
class InventoryManager {
  final WorkstationRepository _repository;

  InventoryManager(this._repository);

  /// Moves a hardware component from one workstation to another atomically.
  /// 
  /// Logic:
  /// 1. Fetches both workstations.
  /// 2. Verifies the component exists in the source workstation.
  /// 3. Verifies the target workstation has capacity (no existing component of the same category).
  /// 4. Updates both workstation component lists in memory.
  /// 5. Saves both updates to the repository.
  /// 
  /// Returns [Success] if the move completed, or [Failure] with an explanation.
  Future<Result<void, Exception>> moveComponent({
    required String componentId,
    required String fromWorkstationId,
    required String toWorkstationId,
  }) async {
    try {
      // 1. Fetch both workstation datasets
      final sourceComponents = await _repository.getWorkstationComponents(fromWorkstationId);
      final targetComponents = await _repository.getWorkstationComponents(toWorkstationId) ?? [];

      if (sourceComponents == null) {
        return Failure(Exception('Source workstation "$fromWorkstationId" not found.'));
      }

      // 2. Verify component exists in source and remove it
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
        return Failure(Exception('Component "$componentId" not found in workstation "$fromWorkstationId".'));
      }

      // 3. Verify destination capacity (Swiss Rule: One component per category per desk)
      final categoryToMatch = componentToMove.category.toLowerCase();
      final bool alreadyHasCategory = targetComponents.any(
        (component) => component.category.toLowerCase() == categoryToMatch,
      );

      if (alreadyHasCategory) {
        return Failure(Exception('Target workstation "$toWorkstationId" already has a ${componentToMove.category}.'));
      }

      // 4. Update target list
      final updatedTargetList = [...targetComponents, componentToMove];

      // 5. Atomic-style save (Sequential saves since SharedPreferences is not transactional)
      // Note: We save source first. If it fails, target isn't touched.
      // If target fails, we have a partial state which is a limitation of SharedPreferences.
      final sourceSaveResult = await _repository.saveWorkstationComponents(fromWorkstationId, updatedSourceList);
      if (!sourceSaveResult) {
        return Failure(Exception('Failed to update source workstation storage.'));
      }

      final targetSaveResult = await _repository.saveWorkstationComponents(toWorkstationId, updatedTargetList);
      if (!targetSaveResult) {
        // Rollback source if target fails (Attempting best-effort atomicity)
        await _repository.saveWorkstationComponents(fromWorkstationId, sourceComponents);
        return Failure(Exception('Failed to update target workstation storage. Rollback performed.'));
      }

      return const Success(null);
    } catch (error) {
      return Failure(Exception('Unexpected error during component move: $error'));
    }
  }
}
