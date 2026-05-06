import 'package:isar/isar.dart';

part 'workstation_model.g.dart';

/// Represents a workstation in the inventory system, optimized for Isar persistence.
@collection
class Workstation {
  /// Internal Isar ID
  Id isarId = Isar.autoIncrement;

  /// The unique workstation identifier (e.g., L5_D01)
  @Index(unique: true, replace: true)
  late String identifier;

  /// JSON serialized list of HardwareComponent objects
  late String componentsJson;
}
