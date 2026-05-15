import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Possible view modes for the Inventory Dock
enum DockViewMode {
  inventory,
  audit,
  history,
  comparison,
}

/// State class for the Inventory Dock
class DockState {
  final bool isExpanded;
  final String? selectedCategory;
  final DockViewMode viewMode;

  const DockState({
    this.isExpanded = false,
    this.selectedCategory,
    this.viewMode = DockViewMode.inventory,
  });

  DockState copyWith({
    bool? isExpanded,
    String? selectedCategory,
    DockViewMode? viewMode,
  }) {
    return DockState(
      isExpanded: isExpanded ?? this.isExpanded,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      viewMode: viewMode ?? this.viewMode,
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

  void setViewMode(DockViewMode mode) {
    state = state.copyWith(viewMode: mode, isExpanded: true);
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }
}

/// Provider for the inventory dock state
final dockProvider = NotifierProvider<DockNotifier, DockState>(() {
  return DockNotifier();
});
