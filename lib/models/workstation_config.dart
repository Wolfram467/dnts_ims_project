/// Represents the logical grid coordinates of a workstation on the map.
class WorkstationConfig {
  final String id;
  final double dx;
  final double dy;

  const WorkstationConfig({
    required this.id,
    required this.dx,
    required this.dy,
  });
}
