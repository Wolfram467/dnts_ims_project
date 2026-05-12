import '../models/workstation_config.dart';

/// Domain manager for handling spatial layout calculations and grid configurations.
/// Centralizes the math for 332 desks across the facility labs.
class SpatialManager {
  /// Returns a pre-calculated list of [WorkstationConfig] objects for a given facility.
  /// 
  /// Supported facility identifiers:
  /// - 'CT1': Returns all desks across all 7 labs.
  /// - 'Lab 1' through 'Lab 7' and 'Laboratory 1' through 'Laboratory 7': Returns desks for specific laboratories.
  /// - 'Storage', 'Others', 'CT2': Returns empty lists (placeholders).
  List<WorkstationConfig> getLayoutForFacility(String facilityId) {
    final List<WorkstationConfig> allConfigs = _generateAllConfigurations();

    if (facilityId == 'CT1') {
      return allConfigs;
    }

    if (facilityId.startsWith('Lab ') || facilityId.startsWith('Laboratory ')) {
      final labNumber = facilityId.split(' ').last;
      final labPrefix = 'L${labNumber}_';
      return allConfigs.where((config) => config.id.startsWith(labPrefix)).toList();
    }

    // Return empty list for facilities without spatial mappings (Storage, Others, etc.)
    return [];
  }

  /// Generates the complete configuration map for all 332 desks and structural elements.
  List<WorkstationConfig> _generateAllConfigurations() {
    final List<WorkstationConfig> configurations = [];

    // Lab 6: 48 desks
    _addLabConfigurations(configurations, 6, [
      {'row': 2, 'cols': [2, 11], 'start': 1},
      {'row': 3, 'cols': [2, 11], 'start': 11},
      {'row': 4, 'cols': [2, 11], 'start': 21},
      {'row': 5, 'cols': [2, 11], 'start': 31},
      {'row': 6, 'cols': [2, 9], 'start': 41},
    ]);

    // Lab 7: 48 desks
    _addLabConfigurations(configurations, 7, [
      {'row': 8, 'cols': [2, 7], 'start': 1},
      {'row': 9, 'cols': [2, 7], 'start': 7},
      {'row': 11, 'cols': [2, 7], 'start': 13},
      {'row': 12, 'cols': [2, 7], 'start': 19},
      {'row': 14, 'cols': [2, 7], 'start': 25},
      {'row': 15, 'cols': [2, 7], 'start': 31},
      {'row': 17, 'cols': [2, 7], 'start': 37},
      {'row': 18, 'cols': [2, 7], 'start': 43},
    ]);

    // Lab 1: 48 desks
    _addLabConfigurations(configurations, 1, [
      {'row': 2, 'cols': [13, 20], 'start': 1},
      {'row': 3, 'cols': [13, 20], 'start': 9},
      {'row': 5, 'cols': [13, 20], 'start': 17},
      {'row': 6, 'cols': [13, 20], 'start': 25},
      {'row': 8, 'cols': [13, 20], 'start': 33},
      {'row': 9, 'cols': [13, 20], 'start': 41},
    ]);

    // Lab 2: 48 desks
    _addLabConfigurations(configurations, 2, [
      {'row': 11, 'cols': [13, 20], 'start': 1},
      {'row': 12, 'cols': [13, 20], 'start': 9},
      {'row': 14, 'cols': [13, 20], 'start': 17},
      {'row': 15, 'cols': [13, 20], 'start': 25},
      {'row': 17, 'cols': [13, 20], 'start': 33},
      {'row': 18, 'cols': [13, 20], 'start': 41},
    ]);

    // Lab 3: 46 desks (Pillars at V5, W5)
    _addLabConfigurations(configurations, 3, [
      {'row': 2, 'cols': [22, 33], 'start': 1},
      {'row': 3, 'cols': [22, 33], 'start': 13},
      {'row': 5, 'cols': [22, 33], 'start': 25, 'pillars': [22, 23]},
      {'row': 6, 'cols': [22, 33], 'start': 35},
    ]);

    // Lab 4: 46 desks (Pillars at V12, W12)
    _addLabConfigurations(configurations, 4, [
      {'row': 8, 'cols': [22, 33], 'start': 1},
      {'row': 9, 'cols': [22, 33], 'start': 13},
      {'row': 11, 'cols': [22, 33], 'start': 25},
      {'row': 12, 'cols': [22, 33], 'start': 37, 'pillars': [22, 23]},
    ]);

    // Lab 5: 48 desks
    _addLabConfigurations(configurations, 5, [
      {'row': 14, 'cols': [22, 33], 'start': 1},
      {'row': 15, 'cols': [22, 33], 'start': 13},
      {'row': 17, 'cols': [22, 33], 'start': 25},
      {'row': 18, 'cols': [22, 33], 'start': 37},
    ]);

    // Add structural pillars
    configurations.addAll([
      const WorkstationConfig(id: 'PILLAR_V5', dx: 22, dy: 5),
      const WorkstationConfig(id: 'PILLAR_W5', dx: 23, dy: 5),
      const WorkstationConfig(id: 'PILLAR_V12', dx: 22, dy: 12),
      const WorkstationConfig(id: 'PILLAR_W12', dx: 23, dy: 12),
    ]);

    return configurations;
  }

  void _addLabConfigurations(
    List<WorkstationConfig> configs,
    int labNumber,
    List<Map<String, dynamic>> rowConfigs,
  ) {
    for (final rowConfig in rowConfigs) {
      final int rowNumber = rowConfig['row'];
      final List<int> columnRange = rowConfig['cols'];
      int workstationNumber = rowConfig['start'];
      final List<int>? pillarColumns = rowConfig['pillars'];

      for (int columnNumber = columnRange[0]; columnNumber <= columnRange[1]; columnNumber++) {
        if (pillarColumns != null && pillarColumns.contains(columnNumber)) {
          continue;
        }

        final id = 'L${labNumber}_D${workstationNumber.toString().padLeft(2, '0')}';
        configs.add(WorkstationConfig(
          id: id,
          dx: columnNumber.toDouble(),
          dy: rowNumber.toDouble(),
        ));
        workstationNumber++;
      }
    }
  }
}
