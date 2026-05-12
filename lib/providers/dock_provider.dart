import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for the Inventory Dock
class DockState {
  final bool isExpanded;
  final String? selectedCategory;

  const DockState({
    this.isExpanded = false,
    this.selectedCategory,
  });

  DockState copyWith({
    bool? isExpanded,
    String? selectedCategory,
  }) {
    return DockState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Notifier to manage the state and data of the inventory dock
class DockNotifier extends Notifier<DockState> {
  @override
  DockState build() {
    return const DockState();
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }
}

/// Provider for the inventory dock state
final dockProvider = NotifierProvider<DockNotifier, DockState>(() {
  return DockNotifier();
});
