import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier to manage the application theme state (Light/Dark mode)
class ThemeNotifier extends Notifier<bool> {
  static const String _storageKey = 'is_dark_mode';

  @override
  bool build() {
    // Default to light mode (false)
    return false;
  }

  /// Load theme preference from local storage
  Future<void> initializeTheme() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(_storageKey) ?? false;
  }

  /// Flip the theme state and persist to local storage
  Future<void> toggleTheme() async {
    final newState = !state;
    state = newState;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, newState);
  }
}

/// Global provider for the theme state
final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
