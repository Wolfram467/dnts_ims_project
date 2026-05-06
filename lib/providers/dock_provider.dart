import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hardware_component.dart';
import 'map_state_provider.dart';

/// State class for the Inventory Dock
class DockState {
  final bool isExpanded;
  final String? selectedCategory;
  final Map<String, Map<String, List<Map<String, dynamic>>>> groupedAuditComponents;
  final bool isLoading;

  const DockState({
    this.isExpanded = false,
    this.selectedCategory,
    this.groupedAuditComponents = const {},
    this.isLoading = false,
  });

  DockState copyWith({
    bool? isExpanded,
    String? selectedCategory,
    Map<String, Map<String, List<Map<String, dynamic>>>>? groupedAuditComponents,
    bool? isLoading,
  }) {
    return DockState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      groupedAuditComponents: groupedAuditComponents ?? this.groupedAuditComponents,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier to manage the state and data of the inventory dock
class DockNotifier extends Notifier<DockState> {
  @override
  DockState build() {
    // Listen for facility changes to refresh data
    ref.listen(selectedFacilityProvider, (previous, next) {
      if (state.isExpanded) {
        loadFacilityAuditData();
      }
    });

    // Listen for global refresh triggers
    ref.listen(refreshTriggerProvider, (previous, next) {
      if (next > 0 && state.isExpanded) {
        loadFacilityAuditData();
      }
    });

    return const DockState();
  }

  void toggleExpanded() {
    final bool newExpandedState = !state.isExpanded;
    state = state.copyWith(isExpanded: newExpandedState);
    if (newExpandedState) {
      loadFacilityAuditData();
    }
  }

  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
    if (expanded) {
      loadFacilityAuditData();
    }
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  String _mapDeskIdentifierToFacilityName(String deskIdentifier) {
    if (deskIdentifier.startsWith('L')) {
      final laboratoryMatch = RegExp(r'L(\d+)').firstMatch(deskIdentifier);
      if (laboratoryMatch != null) {
        return 'Lab ${laboratoryMatch.group(1)}';
      }
    }
    if (deskIdentifier.startsWith('Others')) return 'Others';
    if (deskIdentifier.startsWith('Storage')) return 'Storage';
    if (deskIdentifier.startsWith('CT2')) return 'CT2';
    return 'Unknown Facility';
  }

  Future<void> loadFacilityAuditData() async {
    state = state.copyWith(isLoading: true);
    final selectedFacility = ref.read(selectedFacilityProvider);

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final workstationKeys = sharedPreferences.getKeys().where((key) => key.startsWith('workstation_')).toList();
      
      final Map<String, Map<String, List<Map<String, dynamic>>>> componentsByFacilityAndCategory = {};

      for (final workstationKey in workstationKeys) {
        final deskIdentifier = workstationKey.replaceFirst('workstation_', '');
        final facilityName = _mapDeskIdentifierToFacilityName(deskIdentifier);

        // Filter by current facility if not "CT1"
        if (selectedFacility != 'CT1' && facilityName != selectedFacility) continue;

        final serializedData = sharedPreferences.getString(workstationKey);
        if (serializedData != null) {
          final decodedData = jsonDecode(serializedData);
          if (decodedData is List) {
            final workstationComponents = decodedData
                .map((item) => HardwareComponent.fromJson(Map<String, dynamic>.from(item as Map)))
                .toList();
            
            for (var component in workstationComponents) {
              final componentCategory = component.category;
              
              componentsByFacilityAndCategory.putIfAbsent(facilityName, () => {});
              componentsByFacilityAndCategory[facilityName]!.putIfAbsent(componentCategory, () => []);
              
              final componentJson = component.toJson();
              componentJson['desk_id'] = deskIdentifier;
              componentsByFacilityAndCategory[facilityName]![componentCategory]!.add(componentJson);
            }
          }
        }
      }

      // Sorting logic
      final sortedFacilityNames = componentsByFacilityAndCategory.keys.toList()..sort();
      final Map<String, Map<String, List<Map<String, dynamic>>>> sortedAuditComponents = {};
      
      for (var facilityName in sortedFacilityNames) {
        final categoriesMap = componentsByFacilityAndCategory[facilityName]!;
        final sortedCategoryNames = categoriesMap.keys.toList()..sort();
        final Map<String, List<Map<String, dynamic>>> sortedCategories = {};
        
        for (var categoryName in sortedCategoryNames) {
          final categoryComponents = categoriesMap[categoryName]!;
          categoryComponents.sort((a, b) => (a['desk_id'] ?? '').compareTo(b['desk_id'] ?? ''));
          sortedCategories[categoryName] = categoryComponents;
        }
        sortedAuditComponents[facilityName] = sortedCategories;
      }

      state = state.copyWith(
        groupedAuditComponents: sortedAuditComponents,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Provider for the inventory dock state
final dockProvider = NotifierProvider<DockNotifier, DockState>(() {
  return DockNotifier();
});
