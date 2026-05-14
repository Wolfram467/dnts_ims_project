import 'dart:js_interop';

@JS('removeDNTSSplash')
external void _removeDNTSSplash();

// Web implementation
void handleSplashRemoval() {
  try {
    _removeDNTSSplash();
  } catch (e) {
    // Ignore if not present
  }
}
