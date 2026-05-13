import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the visibility state of the History Side Panel.
class HistoryPanelNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // History panel closed by default
  }

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

/// Provider for the History Panel visibility state.
final historyPanelProvider = NotifierProvider<HistoryPanelNotifier, bool>(
  () => HistoryPanelNotifier(),
);
