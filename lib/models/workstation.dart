import 'hardware_component.dart';

class Workstation {
  final String id;
  final List<HardwareComponent> components;

  const Workstation({
    required this.id,
    required this.components,
  });

  factory Workstation.fromJson(String id, List<dynamic> jsonList) {
    return Workstation(
      id: id,
      components: jsonList
          .map((item) => HardwareComponent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return components.map((component) => component.toJson()).toList();
  }

  Workstation copyWith({
    String? id,
    List<HardwareComponent>? components,
  }) {
    return Workstation(
      id: id ?? this.id,
      components: components ?? this.components,
    );
  }
}
