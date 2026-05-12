import 'hardware_component.dart';

/// Represents a workstation in the inventory system.
class Workstation {
  /// The unique workstation identifier (e.g., L5_D01)
  String identifier;

  /// List of HardwareComponent objects
  List<HardwareComponent> components;

  Workstation({
    required this.identifier,
    this.components = const [],
  });
}
