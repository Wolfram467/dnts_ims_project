import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier to manage the theme state (Dark Mode vs Light Mode)
class ThemeNotifier extends Notifier<bool> {
  static const String _storageKey = 'is_dark_mode';

  @override
  bool build() {
    // Initial state is light mode (false)
    return false;
  }

  /// Load theme preference from SharedPreferences
  Future<void> initializeTheme() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    state = sharedPreferences.getBool(_storageKey) ?? false;
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    state = !state;
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool(_storageKey, state);
  }
}

/// Provider for the application theme state
final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
