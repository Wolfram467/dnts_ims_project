# CRITICAL: Manual File Cleanup Required

## Current Status

The file `lib/screens/interactive_map_screen.dart` has corrupted code that needs manual cleanup.

## Errors Found

```
error - Expected to find ')' - lib\screens\interactive_map_screen.dart:706:5
error - The await expression can only be used in an async function - lib\screens\interactive_map_screen.dart:706:25
error - The name '_buildInfoRow' is already defined - lib\screens\interactive_map_screen.dart:1085:10
```

## Root Cause

The old `_showWorkstationDetails()` method code got inserted into the `_buildInfoRow()` method at line 702, creating a corrupted duplicate.

## Required Manual Fix

### DELETE Lines 702-1084

The entire section from line 702 to line 1084 needs to be deleted. This section contains:
- Corrupted `_buildInfoRow` method (line 702)
- Old `showModalBottomSheet` code
- Old modal rendering logic
- Old drag-and-drop code with boundary detection

### KEEP Line 1085 onwards

The correct `_buildInfoRow` method starts at line 1085:

```dart
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        Text(value),
      ],
    ),
  );
}
```

## Step-by-Step Manual Fix

1. Open `lib/screens/interactive_map_screen.dart`
2. Go to line 702
3. Select from line 702 to line 1084 (inclusive)
4. Delete the selected lines
5. Save the file
6. Run `flutter analyze lib/screens/interactive_map_screen.dart`
7. Verify zero errors

## What Should Remain

After the fix, the file should have:

**Line ~700:** End of `_buildDock()` method
```dart
      ),
    );
  }
```

**Line ~701:** Correct `_buildInfoRow()` method
```dart
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
```

**Line ~720:** `_buildDesk()` method
```dart
  Widget _buildDesk(String deskLabel, {bool isPillar = false}) {
    return DragTarget<Map<String, dynamic>>(
      // ... desk implementation
    );
  }
```

## State Variables Status

✅ **FIXED** - All required state variables are declared:
```dart
Map<String, dynamic>? _draggingComponent;
Offset _dragPosition = Offset.zero;
String? _activeDeskId;
bool _isDraggingComponent = false;
List<Map<String, dynamic>> _activeDeskComponents = [];
```

✅ **FIXED** - Desk tap handler updated to call `_loadDeskComponents()`

✅ **FIXED** - Edit dialog updated to call `_loadDeskComponents()` instead of old modal

## After Manual Fix

Once lines 702-1084 are deleted, the file should compile with zero errors (only warnings about print statements and deprecated methods).

---

**Action Required:** Manual deletion of lines 702-1084  
**Expected Result:** Zero compilation errors  
**File:** `lib/screens/interactive_map_screen.dart`
