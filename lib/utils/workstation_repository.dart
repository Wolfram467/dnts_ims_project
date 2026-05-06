import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/hardware_component.dart';
import '../models/workstation_model.dart';

/// ============================================================================
/// WORKSTATION REPOSITORY
/// ============================================================================
/// Centralized storage layer for workstation and component data.
/// Handles CRUD operations for Isar database.
/// ============================================================================

class WorkstationRepository {
  Isar? _isarDatabaseInstance;

  /// Initialize Isar database
  Future<void> initializeIsar() async {
    final bool isAlreadyInitialized = _isarDatabaseInstance == null;
    if (isAlreadyInitialized == false) return;

    final documentDirectory = await getApplicationDocumentsDirectory();
    _isarDatabaseInstance = await Isar.open(
      [WorkstationSchema],
      directory: documentDirectory.path,
    );
  }

  /// Helper to get Isar instance safely
  Future<Isar> _getIsar() async {
    await initializeIsar();
    final database = _isarDatabaseInstance;
    if (database == null) {
      throw Exception('Isar database failed to initialize');
    }
    return database;
  }

  /// ============================================================================
  /// READ OPERATIONS
  /// ============================================================================

  /// Get all components for a specific workstation
  Future<List<HardwareComponent>?> getWorkstationComponents(
    String workstationIdentifier,
  ) async {
    final isar = await _getIsar();
    final workstation = await isar.workstations.filter()
        .identifierEqualTo(workstationIdentifier)
        .findFirst();

    if (workstation == null) {
      return null;
    }

    try {
      final decodedWorkstationData = jsonDecode(workstation.componentsJson);
      if (decodedWorkstationData is List) {
        return decodedWorkstationData
            .map((item) => HardwareComponent.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (exception) {
      print('Error decoding workstation data: $exception');
    }

    return null;
  }

  /// Get a specific component from a workstation by category
  Future<HardwareComponent?> getComponentByCategory(
    String workstationIdentifier,
    String componentCategory,
  ) async {
    final workstationComponents = await getWorkstationComponents(workstationIdentifier);
    if (workstationComponents == null) return null;

    try {
      return workstationComponents.firstWhere(
        (component) => component.category.toLowerCase() == componentCategory.toLowerCase(),
      );
    } catch (exception) {
      return null;
    }
  }

  /// Check if a workstation has data
  Future<bool> hasWorkstationData(String workstationIdentifier) async {
    final workstationComponents = await getWorkstationComponents(workstationIdentifier);
    final bool isPresent = workstationComponents == null;
    final bool isNotEmpty = isPresent == false && workstationComponents.isNotEmpty;
    return isNotEmpty;
  }

  /// ============================================================================
  /// WRITE OPERATIONS
  /// ============================================================================

  /// Save complete workstation data
  Future<bool> saveWorkstationComponents(
    String workstationIdentifier,
    List<HardwareComponent> workstationComponents,
  ) async {
    try {
      final isar = await _getIsar();
      final serializedWorkstationData = jsonEncode(
        workstationComponents.map((component) => component.toJson()).toList(),
      );

      await isar.writeTxn(() async {
        final existingWorkstation = await isar.workstations.filter()
            .identifierEqualTo(workstationIdentifier)
            .findFirst();

        final workstation = existingWorkstation ?? Workstation();
        workstation.identifier = workstationIdentifier;
        workstation.componentsJson = serializedWorkstationData;

        await isar.workstations.put(workstation);
      });

      print('Saved workstation: $workstationIdentifier (${workstationComponents.length} components)');
      return true;
    } catch (exception) {
      print('Error saving workstation data: $exception');
      return false;
    }
  }

  /// Update a specific component in a workstation
  Future<bool> updateWorkstationComponent(
    String workstationIdentifier,
    String componentCategory,
    HardwareComponent updatedComponent,
  ) async {
    try {
      final workstationComponents = await getWorkstationComponents(workstationIdentifier);
      if (workstationComponents == null) {
        print('Workstation not found: $workstationIdentifier');
        return false;
      }

      // Find and update the component
      final mutableWorkstationComponents = List<HardwareComponent>.from(workstationComponents);
      bool isComponentFound = false;
      for (int index = 0; index < mutableWorkstationComponents.length; index++) {
        final bool isCategoryMatch = mutableWorkstationComponents[index].category.toLowerCase() ==
            componentCategory.toLowerCase();
        if (isCategoryMatch) {
          mutableWorkstationComponents[index] = updatedComponent;
          isComponentFound = true;
          break;
        }
      }

      if (isComponentFound == false) {
        print('Component not found: $componentCategory in $workstationIdentifier');
        return false;
      }

      // Save updated components
      return await saveWorkstationComponents(workstationIdentifier, mutableWorkstationComponents);
    } catch (exception) {
      print('Error updating component: $exception');
      return false;
    }
  }

  /// ============================================================================
  /// DELETE OPERATIONS
  /// ============================================================================

  /// Delete a workstation's data
  Future<bool> deleteWorkstation(String workstationIdentifier) async {
    try {
      final isar = await _getIsar();
      await isar.writeTxn(() async {
        await isar.workstations.filter()
            .identifierEqualTo(workstationIdentifier)
            .deleteFirst();
      });
      print('Deleted workstation: $workstationIdentifier');
      return true;
    } catch (exception) {
      print('Error deleting workstation: $exception');
      return false;
    }
  }

  /// Clear all workstation data
  Future<int> clearAllWorkstations() async {
    print('Clearing all workstation data...');
    final isar = await _getIsar();
    
    int removedWorkstationCount = 0;
    await isar.writeTxn(() async {
      removedWorkstationCount = await isar.workstations.where().deleteAll();
    });

    print('Cleared $removedWorkstationCount workstations from storage');
    return removedWorkstationCount;
  }

  /// ============================================================================
  /// VALIDATION
  /// ============================================================================

  /// Validate DNTS serial format
  bool isValidDntsSerialNumber(String serialNumber) {
    // Format: CT1_LAB[1-7]_[MR|M|K|SU|SSD|AVR][01-99]
    final serialNumberRegex = RegExp(r'^CT1_LAB[1-7]_(MR|M|K|SU|SSD|AVR)\d{2}$');
    return serialNumberRegex.hasMatch(serialNumber);
  }

  /// Validate component status
  bool isValidDeploymentStatus(String deploymentStatus) {
    const validDeploymentStatuses = [
      'FUNCTIONAL',
      'DEFECTIVE',
      'MISSING',
      'FOR REPAIR',
    ];
    return validDeploymentStatuses.contains(deploymentStatus);
  }

  /// Check if DNTS serial is unique within a lab
  Future<bool> isDntsSerialNumberUnique(
    String dntsSerialNumber,
    String currentWorkstationIdentifier,
    String componentCategory,
  ) async {
    // Extract lab number from workstation ID (e.g., "L5_D01" -> 5)
    final facilityLabMatch = RegExp(r'L(\d+)_').firstMatch(currentWorkstationIdentifier);
    if (facilityLabMatch == null) return true;

    final labNumberString = facilityLabMatch.group(1);
    final isar = await _getIsar();
    
    final labWorkstations = await isar.workstations.filter()
        .identifierStartsWith('L${labNumberString}_')
        .findAll();

    for (final workstation in labWorkstations) {
      final workstationIdentifier = workstation.identifier;
      final workstationComponents = await getWorkstationComponents(workstationIdentifier);

      if (workstationComponents == null) {
        continue;
      }
      for (final component in workstationComponents) {
          // Skip the current component being edited
          final bool isCurrentComponent = workstationIdentifier == currentWorkstationIdentifier &&
              component.category == componentCategory;
          if (isCurrentComponent) {
            continue;
          }

          // Check for duplicate
          if (component.dntsSerial == dntsSerialNumber) {
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
  Future<List<String>> getAllWorkstationIdentifiers() async {
    final isar = await _getIsar();
    final workstations = await isar.workstations.where().findAll();
    final identifiers = workstations.map((workstation) => workstation.identifier).toList();
    identifiers.sort();
    return identifiers;
  }

  /// Get all workstation IDs for a specific lab
  Future<List<String>> getLabWorkstationIdentifiers(int labNumber) async {
    final allWorkstationIdentifiers = await getAllWorkstationIdentifiers();
    return allWorkstationIdentifiers.where((identifier) => identifier.startsWith('L${labNumber}_')).toList();
  }

  /// Count total workstations in storage
  Future<int> countWorkstations() async {
    final isar = await _getIsar();
    return await isar.workstations.count();
  }

  /// ============================================================================
  /// ACCESSOR
  /// ============================================================================
  
  /// Provides direct access to Isar for cross-workstation transactions
  Future<Isar> getDatabaseInstance() async {
    return await _getIsar();
  }
}
