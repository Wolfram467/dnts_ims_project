import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// KEYBOARD SHORTCUTS CONFIGURATION
// Defines all keyboard shortcuts for map navigation
// ═══════════════════════════════════════════════════════════════════════════

enum MapShortcutAction {
  closeInspector,      // ESC
  panUp,               // Arrow Up
  panDown,             // Arrow Down
  panLeft,             // Arrow Left
  panRight,            // Arrow Right
  zoomIn,              // + or =
  zoomOut,             // - or _
  fitAllLabs,          // Space
  jumpToLab1,          // 1
  jumpToLab2,          // 2
  jumpToLab3,          // 3
  jumpToLab4,          // 4
  jumpToLab5,          // 5
  jumpToLab6,          // 6
  jumpToLab7,          // 7
  cycleDeskNext,       // Tab
  cycleDeskPrevious,   // Shift+Tab
  showHelp,            // ?
}

class KeyboardShortcuts {
  /// Map of keyboard keys to their corresponding actions
  static final Map<LogicalKeyboardKey, MapShortcutAction> keyMap = {
    LogicalKeyboardKey.escape: MapShortcutAction.closeInspector,
    LogicalKeyboardKey.arrowUp: MapShortcutAction.panUp,
    LogicalKeyboardKey.arrowDown: MapShortcutAction.panDown,
    LogicalKeyboardKey.arrowLeft: MapShortcutAction.panLeft,
    LogicalKeyboardKey.arrowRight: MapShortcutAction.panRight,
    LogicalKeyboardKey.equal: MapShortcutAction.zoomIn,
    LogicalKeyboardKey.add: MapShortcutAction.zoomIn,
    LogicalKeyboardKey.minus: MapShortcutAction.zoomOut,
    LogicalKeyboardKey.space: MapShortcutAction.fitAllLabs,
    LogicalKeyboardKey.digit1: MapShortcutAction.jumpToLab1,
    LogicalKeyboardKey.digit2: MapShortcutAction.jumpToLab2,
    LogicalKeyboardKey.digit3: MapShortcutAction.jumpToLab3,
    LogicalKeyboardKey.digit4: MapShortcutAction.jumpToLab4,
    LogicalKeyboardKey.digit5: MapShortcutAction.jumpToLab5,
    LogicalKeyboardKey.digit6: MapShortcutAction.jumpToLab6,
    LogicalKeyboardKey.digit7: MapShortcutAction.jumpToLab7,
    LogicalKeyboardKey.tab: MapShortcutAction.cycleDeskNext,
    LogicalKeyboardKey.question: MapShortcutAction.showHelp,
  };

  /// Get action from key event
  static MapShortcutAction? getAction(KeyEvent event) {
    // Handle Shift+Tab for previous desk
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        HardwareKeyboard.instance.isShiftPressed) {
      return MapShortcutAction.cycleDeskPrevious;
    }

    return keyMap[event.logicalKey];
  }

  /// Get human-readable label for action
  static String getActionLabel(MapShortcutAction action) {
    switch (action) {
      case MapShortcutAction.closeInspector:
        return 'Close Inspector / Return to Overview';
      case MapShortcutAction.panUp:
        return 'Pan Up';
      case MapShortcutAction.panDown:
        return 'Pan Down';
      case MapShortcutAction.panLeft:
        return 'Pan Left';
      case MapShortcutAction.panRight:
        return 'Pan Right';
      case MapShortcutAction.zoomIn:
        return 'Zoom In';
      case MapShortcutAction.zoomOut:
        return 'Zoom Out';
      case MapShortcutAction.fitAllLabs:
        return 'Fit All Labs';
      case MapShortcutAction.jumpToLab1:
        return 'Jump to Lab 1';
      case MapShortcutAction.jumpToLab2:
        return 'Jump to Lab 2';
      case MapShortcutAction.jumpToLab3:
        return 'Jump to Lab 3';
      case MapShortcutAction.jumpToLab4:
        return 'Jump to Lab 4';
      case MapShortcutAction.jumpToLab5:
        return 'Jump to Lab 5';
      case MapShortcutAction.jumpToLab6:
        return 'Jump to Lab 6';
      case MapShortcutAction.jumpToLab7:
        return 'Jump to Lab 7';
      case MapShortcutAction.cycleDeskNext:
        return 'Next Desk';
      case MapShortcutAction.cycleDeskPrevious:
        return 'Previous Desk';
      case MapShortcutAction.showHelp:
        return 'Show Keyboard Shortcuts';
    }
  }

  /// Get keyboard shortcut key for action
  static String getShortcutKey(MapShortcutAction action) {
    switch (action) {
      case MapShortcutAction.closeInspector:
        return 'ESC';
      case MapShortcutAction.panUp:
        return '↑';
      case MapShortcutAction.panDown:
        return '↓';
      case MapShortcutAction.panLeft:
        return '←';
      case MapShortcutAction.panRight:
        return '→';
      case MapShortcutAction.zoomIn:
        return '+';
      case MapShortcutAction.zoomOut:
        return '-';
      case MapShortcutAction.fitAllLabs:
        return 'Space';
      case MapShortcutAction.jumpToLab1:
        return '1';
      case MapShortcutAction.jumpToLab2:
        return '2';
      case MapShortcutAction.jumpToLab3:
        return '3';
      case MapShortcutAction.jumpToLab4:
        return '4';
      case MapShortcutAction.jumpToLab5:
        return '5';
      case MapShortcutAction.jumpToLab6:
        return '6';
      case MapShortcutAction.jumpToLab7:
        return '7';
      case MapShortcutAction.cycleDeskNext:
        return 'Tab';
      case MapShortcutAction.cycleDeskPrevious:
        return 'Shift+Tab';
      case MapShortcutAction.showHelp:
        return '?';
    }
  }
}
