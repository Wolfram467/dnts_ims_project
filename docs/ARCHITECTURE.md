# DNTS IMS Architecture Documentation

## ARCHITECTURE_DIAGRAM.md

# Architecture: Map UI ↔ Local Storage

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Interactive Map Screen                    │
│                 (interactive_map_screen.dart)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ User clicks desk
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              _showWorkstationDetails(deskLabel)              │
│                                                               │
│  1. print('🖱️ Desk clicked: $deskLabel')                    │
│  2. print('🔍 Querying local storage...')                   │
│  3. Call getWorkstationAsset(deskLabel)                      │
│  4. print('✅ Found' or '❌ Not found')                      │
│  5. Show modal with data                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Query storage
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Seed Script Functions                     │
│                    (seed_lab5_data.dart)                     │
│                                                               │
│  • seedLab5Data()           - Populate storage               │
│  • getWorkstationAsset()    - Query single workstation       │
│  • listAllWorkstationData() - List all data                  │
│  • clearAllWorkstationData()- Clear storage                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Read/Write
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SharedPreferences                         │
│                  (Permanent Local Storage)                   │
│                                                               │
│  Key: workstation_L5_T01                                     │
│  Value: {                                                    │
│    "dnts_serial": "CT1_LAB5_MR01",                          │
│    "category": "Monitor",                                    │
│    "status": "Deployed",                                     │
│    "current_workstation_id": "L5_T01"                       │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow: Seeding

```
User clicks ☁️ button
        │
        ▼
_runSeedScript() called
        │
        ▼
seedLab5Data() executes
        │
        ├─► Create workstation assignments (Map)
        │
        ├─► For each workstation:
        │   ├─► Convert to JSON string
        │   ├─► Save to SharedPreferences
        │   └─► print('✓ Saved: ...')
        │
        ├─► Save metadata (timestamp, count)
        │
        └─► print('✅ Seeding complete!')
```

## Data Flow: Querying

```
User clicks desk "L5_T01"
        │
        ▼
_showWorkstationDetails("L5_T01") called
        │
        ├─► print('🖱️ Desk clicked: L5_T01')
        │
        ├─► print('🔍 Querying local storage...')
        │
        ▼
getWorkstationAsset("L5_T01") called
        │
        ├─► Get SharedPreferences instance
        │
        ├─► Query key: "workstation_L5_T01"
        │
        ├─► Parse JSON string to Map
        │
        └─► Return asset data (or null)
        │
        ▼
Back to _showWorkstationDetails()
        │
        ├─► print('✅ Found' or '❌ Not found')
        │
        ├─► Build modal with data
        │
        └─► Show "LOCAL" badge if from storage
```

## Storage Schema

### Key Format
```
workstation_{LAB_ID}_{DESK_NUMBER}
```

Examples:
- `workstation_L5_T01`
- `workstation_L5_T02`
- `workstation_L5_T48`

### Value Format (JSON)
```json
{
  "dnts_serial": "CT1_LAB5_MR01",
  "category": "Monitor",
  "status": "Deployed",
  "current_workstation_id": "L5_T01"
}
```

### Metadata Keys
- `seed_timestamp`: ISO 8601 timestamp of last seed
- `seed_count`: Number of workstations seeded

## Terminal Output Flow

### Successful Query
```
🖱️ Desk clicked: L5_T01
🔍 Querying local storage for workstation: L5_T01
✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
```

### Empty Workstation
```
🖱️ Desk clicked: L5_T40
🔍 Querying local storage for workstation: L5_T40
❌ No asset found in local storage for: L5_T40
```

### Seed Operation
```
═══════════════════════════════════════
🚀 SEED SCRIPT TRIGGERED FROM UI
═══════════════════════════════════════

🌱 Starting Lab 5 data seeding...
  ✓ Saved: L5_T01 -> CT1_LAB5_MR01
  ✓ Saved: L5_T02 -> CT1_LAB5_M02
  ✓ Saved: L5_T03 -> CT1_LAB5_K03
  ✓ Saved: L5_T10 -> CT1_LAB5_SU10
  ✓ Saved: L5_T15 -> CT1_LAB5_AVR15
  ✓ Saved: L5_T20 -> CT1_LAB5_SSD20
  ✓ Saved: L5_T25 -> CT1_LAB5_MR25
  ✓ Saved: L5_T30 -> CT1_LAB5_M30
✅ Lab 5 seeding complete! 8 workstations assigned.
📦 Data committed to SharedPreferences (permanent local storage)
```

## UI Components

### Toolbar Buttons
```
┌──────────────────────────────────────────────────────────┐
│  CT1 Floor Plan                    🔍- 🔍+ 🔄 ☁️ 📋    │
└──────────────────────────────────────────────────────────┘
                                      │   │  │  │  │
                                      │   │  │  │  └─ List stored data
                                      │   │  │  └──── Seed Lab 5 data
                                      │   │  └─────── Refresh Supabase
                                      │   └────────── Zoom in
                                      └────────────── Zoom out
```

### Modal Display
```
┌─────────────────────────────────────┐
│ L5_T01                      [LOCAL] │ ← Green badge
├─────────────────────────────────────┤
│ Serial:   CT1_LAB5_MR01             │
│ Category: Monitor                   │
│ Status:   Deployed                  │
│ Source:   Local Storage             │
├─────────────────────────────────────┤
│            [ CLOSE ]                │
└─────────────────────────────────────┘
```

## Platform Support

| Platform | Storage Backend | Persistence |
|----------|----------------|-------------|
| Web | localStorage | ✅ Yes (per browser) |
| Android | SharedPreferences | ✅ Yes |
| iOS | NSUserDefaults | ✅ Yes |
| Windows | Registry | ✅ Yes |
| macOS | NSUserDefaults | ✅ Yes |
| Linux | File system | ✅ Yes |

## Key Features

✅ **Permanent Storage**: Data survives app restarts
✅ **Terminal Logging**: Every action prints to console
✅ **Visual Feedback**: "LOCAL" badge shows data source
✅ **Debug Tools**: List and clear functions for testing
✅ **Fallback Support**: Falls back to Supabase if not in local storage
✅ **Cross-Platform**: Works on all Flutter platforms

---

## ARCHITECTURE_GUIDE.md

# 🏗️ DNTS IMS Architecture Guide

## Quick Reference for the Refactored Codebase

---

## 📁 **File Structure**

```
lib/
├── main.dart                          # App entry point (ProviderScope)
├── providers/
│   └── map_state_provider.dart        # Riverpod state management (335 lines)
├── utils/
│   └── drag_boundary_utils.dart       # Pure math functions (280 lines)
├── widgets/
│   ├── map_canvas_widget.dart         # Interactive map viewer (750 lines)
│   └── inspector_panel_widget.dart    # Desk inspection panel (380 lines)
└── screens/
    └── interactive_map_screen.dart    # Layout orchestrator (320 lines)
```

---

## 🎯 **Responsibility Matrix**

| Component | Responsibility | State Type |
|-----------|---------------|------------|
| **InteractiveMapScreen** | Layout orchestration, global gestures | Stateless (ConsumerWidget) |
| **MapCanvasWidget** | Canvas rendering, camera control, animations | Local UI state (TransformationController) |
| **InspectorPanelWidget** | Desk inspection UI | Stateless (ConsumerWidget) |
| **map_state_provider.dart** | Shared app state | Riverpod Notifiers |
| **drag_boundary_utils.dart** | Boundary calculations | Pure functions |

---

## 🔄 **Data Flow**

### User Clicks Desk
```
User taps desk
    ↓
MapCanvasWidget._loadDeskComponents()
    ↓
ref.read(activeDeskProvider.notifier).setActiveDesk(deskId)
ref.read(inspectorStateProvider.notifier).openInspector()
    ↓
InspectorPanelWidget rebuilds (watches inspectorStateProvider)
MapCanvasWidget._snapToDesk() animates camera
```

### User Drags Component
```
User starts drag (LongPressDraggable)
    ↓
ref.read(draggingComponentProvider.notifier).setDraggingComponent(data)
    ↓
InteractiveMapScreen.Listener.onPointerMove()
    ↓
ref.read(dragPositionProvider.notifier).updatePosition(event.position)
    ↓
Global drag ghost rebuilds (watches dragPositionProvider)
DragBoundaryCalculator.shouldTriggerEscapeGesture() evaluates
```

### User Closes Inspector
```
User clicks close button
    ↓
InspectorPanelWidget._closeInspector()
    ↓
ref.read(inspectorStateProvider.notifier).closeInspector()
    ↓
MapCanvasWidget.ref.listen() detects change
    ↓
MapCanvasWidget.resetToGlobalOverview() animates camera
```

---

## 🧩 **Provider Reference**

### State Providers

| Provider | Type | Purpose | Initial Value |
|----------|------|---------|---------------|
| `draggingComponentProvider` | `Map<String, dynamic>?` | Currently dragging component | `null` |
| `dragPositionProvider` | `Offset` | Cursor position during drag | `Offset.zero` |
| `activeDeskProvider` | `String?` | Currently selected desk ID | `null` |
| `inspectorStateProvider` | `bool` | Inspector panel open/closed | `false` |
| `activeDeskComponentsProvider` | `List<Map<String, dynamic>>` | Components in active desk | `[]` |
| `selectedDeskProvider` | `String?` | Desk with pulse animation | `null` |
| `cameraControlProvider` | `CameraAction?` | Camera control commands | `null` |

### Computed Providers

| Provider | Type | Computation |
|----------|------|-------------|
| `isDraggingProvider` | `bool` | `draggingComponent != null` |
| `isInspectorActiveProvider` | `bool` | `isOpen && hasDesk` |

---

## 🎨 **How to Add New Features**

### Adding a New State Variable
```dart
// 1. Create Notifier in map_state_provider.dart
class MyNewStateNotifier extends Notifier<MyType> {
  @override
  MyType build() => initialValue;
  
  void updateState(MyType newValue) {
    state = newValue;
  }
}

// 2. Create Provider
final myNewStateProvider = NotifierProvider<MyNewStateNotifier, MyType>(
  () => MyNewStateNotifier(),
);

// 3. Use in widgets
// Watch (reactive)
final myState = ref.watch(myNewStateProvider);

// Read (one-time)
ref.read(myNewStateProvider.notifier).updateState(newValue);
```

### Adding a New Camera Action
```dart
// 1. Add to CameraAction enum
enum CameraAction {
  fitAllLabs,
  zoomIn,
  zoomOut,
  resetToGlobalOverview,
  myNewAction, // ← Add here
}

// 2. Add method to CameraControlNotifier
void myNewAction() => triggerAction(CameraAction.myNewAction);

// 3. Handle in MapCanvasWidget.ref.listen()
case CameraAction.myNewAction:
  _handleMyNewAction();
  break;

// 4. Trigger from shell
ref.read(cameraControlProvider.notifier).myNewAction();
```

### Adding a New Boundary Check
```dart
// 1. Add to drag_boundary_utils.dart
static bool myNewBoundaryCheck(Offset position, Size screenSize) {
  // Pure math logic here
  return position.dx > screenSize.width / 2;
}

// 2. Use in InteractiveMapScreen._handlePointerMove()
if (DragBoundaryCalculator.myNewBoundaryCheck(event.position, screenSize)) {
  _handleMyNewBehavior(ref);
}
```

---

## 🧪 **Testing Patterns**

### Unit Test (Pure Function)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dnts_ims/utils/drag_boundary_utils.dart';

void main() {
  group('DragBoundaryCalculator', () {
    test('shouldTriggerEscapeGesture detects left edge', () {
      final result = DragBoundaryCalculator.shouldTriggerEscapeGesture(
        Offset(10, 100),
        Size(800, 600),
      );
      expect(result, true);
    });
  });
}
```

### Provider Test (Riverpod Notifier)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dnts_ims/providers/map_state_provider.dart';

void main() {
  group('DraggingComponentNotifier', () {
    test('sets and clears dragging state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(draggingComponentProvider.notifier);
      
      notifier.setDraggingComponent({'category': 'Keyboard'});
      expect(container.read(draggingComponentProvider), isNotNull);
      
      notifier.clearDragging();
      expect(container.read(draggingComponentProvider), isNull);
    });
  });
}
```

### Widget Test (Component)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dnts_ims/widgets/inspector_panel_widget.dart';

void main() {
  testWidgets('InspectorPanelWidget shows desk ID', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inspectorStateProvider.overrideWith((ref) => true),
          activeDeskProvider.overrideWith((ref) => 'L5_D01'),
          activeDeskComponentsProvider.overrideWith((ref) => []),
        ],
        child: MaterialApp(home: Scaffold(body: InspectorPanelWidget())),
      ),
    );
    
    expect(find.text('L5_D01'), findsOneWidget);
  });
}
```

---

## 🐛 **Common Issues & Solutions**

### Issue: "ProviderNotFoundException"
**Cause**: Widget not wrapped in ProviderScope  
**Solution**: Ensure `main.dart` has `ProviderScope(child: DNTSApp())`

### Issue: "setState() called after dispose()"
**Cause**: Animation controller not properly disposed  
**Solution**: Check `MapCanvasWidget.dispose()` disposes all controllers

### Issue: Drag ghost not following cursor
**Cause**: `dragPositionProvider` not updating  
**Solution**: Verify `Listener.onPointerMove` calls `updatePosition()`

### Issue: Inspector not closing on escape gesture
**Cause**: `DragBoundaryCalculator` threshold too strict  
**Solution**: Adjust `escapeGestureEdgeThreshold` constant (currently 50px)

### Issue: Camera animation stuttering
**Cause**: Multiple animations running simultaneously  
**Solution**: Dispose old `_snapAnimationController` before creating new one

---

## 📊 **Performance Optimization Tips**

### 1. Minimize Provider Watches
```dart
// ❌ Bad: Watches entire list
final components = ref.watch(activeDeskComponentsProvider);

// ✅ Good: Watches only length
final componentCount = ref.watch(
  activeDeskComponentsProvider.select((list) => list.length),
);
```

### 2. Use Const Constructors
```dart
// ❌ Bad: Creates new widget every rebuild
child: MapCanvasWidget()

// ✅ Good: Reuses widget instance
child: const MapCanvasWidget()
```

### 3. Avoid Rebuilding Heavy Widgets
```dart
// ❌ Bad: Rebuilds entire canvas on drag
ref.watch(dragPositionProvider);

// ✅ Good: Only rebuilds drag ghost
if (draggingComponent != null)
  _buildGlobalDragGhost(draggingComponent, dragPosition)
```

### 4. Use ref.listen for Side Effects
```dart
// ❌ Bad: Side effect in build method
if (isInspectorOpen) _snapToDesk();

// ✅ Good: Side effect in listener
ref.listen<bool>(inspectorStateProvider, (previous, next) {
  if (next) _snapToDesk();
});
```

---

## 🔐 **Security Considerations**

### State Isolation
- Dragging state cannot corrupt desk data
- Inspector state cannot affect camera transformations
- Camera actions are type-safe (enum-based)

### Input Validation
- All pointer events validated before processing
- Boundary checks prevent out-of-bounds operations
- Null safety enforced throughout

### Data Integrity
- Immutable state updates (no direct mutations)
- Provider state is single source of truth
- No shared mutable state between widgets

---

## 📚 **Further Reading**

### Riverpod Documentation
- [Riverpod 2.x Migration Guide](https://riverpod.dev/docs/migration/from_state_notifier)
- [Notifier Pattern](https://riverpod.dev/docs/concepts/providers#notifierprovider)
- [Provider Listening](https://riverpod.dev/docs/concepts/reading#using-reflisten-to-react-to-a-provider-change)

### Flutter Best Practices
- [Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [State Management](https://docs.flutter.dev/data-and-backend/state-mgmt/intro)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)

### Architecture Patterns
- [Clean Architecture in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Separation of Concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)

---

## 🤝 **Contributing Guidelines**

### Before Adding Code
1. ✅ Check if functionality belongs in existing provider/widget
2. ✅ Ensure new state is truly shared (not local UI state)
3. ✅ Write pure functions when possible (no side effects)
4. ✅ Follow existing naming conventions

### Code Review Checklist
- [ ] No local state in InteractiveMapScreen
- [ ] No business logic in build methods
- [ ] Side effects in ref.listen(), not build()
- [ ] Pure functions in utils/ (no Flutter dependencies)
- [ ] Const constructors where possible
- [ ] Null safety handled explicitly
- [ ] Tests added for new functionality

---

## 📞 **Support**

For questions about this architecture:
1. Check this guide first
2. Review `REFACTOR_VERIFICATION.md` for implementation details
3. Examine existing code for patterns
4. Ask team lead for architectural decisions

---

**Last Updated**: 2026-05-02  
**Architecture Version**: 2.0 (Post-Refactor)  
**Maintainer**: Development Team

---

## DATABASE_SCHEMA.md

# Database Schema: DNTS_IMS

## Overview
This document defines the PostgreSQL database schema for the DNTS Inventory Management System. The architecture accounts for strict lab-based location assignments, tracking of temporary deployments (borrowed items), and a split between serialized hardware and bulk consumables.

## Enums (Custom Data Types)
* `user_role`: `['dnts_head', 'lab_ta', 'viewer']`
* `hardware_category`: `['Monitor', 'Mouse', 'Keyboard', 'System Unit', 'AVR', 'SSD']`
* `asset_status`: `['Deployed', 'Borrowed', 'Under Maintenance', 'Storage', 'Retired']`

---

* `user_role`: `['ta_admin', 'lab_ta']`

### 1. `profiles`
Manages system access. New accounts are created and pre-approved by a TA Admin.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Foreign Key to `auth.users.id` |
| `full_name` | `text` | Not Null |
| `role` | `user_role` | Default: 'lab_ta' |
| `is_approved` | `boolean` | Default: true (Admin-created accounts are ready for use) |
| `assigned_lab` | `text` | Nullable (e.g., 'Lab 6') |

### 2. `locations`
Defines the valid areas an item can exist. Includes the 7 labs, the 'Others' storage, and external borrowing entities.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `name` | `text` | Not Null, Unique (e.g., 'LAB 1', 'Others', 'Registrar') |
| `is_lab` | `boolean` | Default: true (False for 'Others' and borrowing entities) |

### 3. `serialized_assets` (Hardware Inventory)
Tracks individual PC components. Enforces the DNTS naming convention and tracks wandering items.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `dnts_serial` | `text` | Not Null, Unique. Format Rule: `CT1_LAB#_[MR|M|K|SU|AVR|SSD]#` |
| `mfg_serial` | `text` | Not Null, Unique (Manufacturer Serial Number) |
| `category` | `hardware_category`| Not Null |
| `designated_lab_id`| `uuid` | Foreign Key to `locations.id`. Where the item *belongs*. |
| `current_loc_id` | `uuid` | Foreign Key to `locations.id`. Where the item *actually is*. |
| `status` | `asset_status` | Default: 'Storage' |
| `notes` | `text` | Nullable |

### 4. `bulk_consumables` (The "Others" Inventory)
Simplified tracking for non-serialized items.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `item_name` | `text` | Not Null (e.g., 'RJ45 Connectors') |
| `quantity` | `integer` | Default: 0 |
| `minimum_stock` | `integer` | Threshold for re-order alerts |

### 5. `movement_logs` (Audit & Borrowing Ledger)
Tracks every status change, lab transfer, or borrowing event. Crucial for generating Property Custodian reports.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `asset_id` | `uuid` | Foreign Key to `serialized_assets.id` |
| `action_by` | `uuid` | Foreign Key to `profiles.id` (The TA/Head who logged it) |
| `previous_loc_id`| `uuid` | Foreign Key to `locations.id` |
| `new_loc_id` | `uuid` | Foreign Key to `locations.id` |
| `status_change` | `text` | e.g., 'Deployed -> Borrowed' |
| `borrower_name` | `text` | Nullable (e.g., 'Registrar Office') |
| `created_at` | `timestamptz` | Default: `now()` |

---

## Row Level Security (RLS) Directives
All tables MUST have RLS enabled. The AI should generate policies based on these strict rules:
1. **Admin Power:** Users where `role` in `('dnts_head', 'lab_ta')` have FULL access (SELECT, INSERT, UPDATE, DELETE) to `assets`, `locations`, and `consumables`. 
2. **Viewer Power:** Users where `role = 'viewer'` AND `is_approved = true` have READ-ONLY access (SELECT). If `is_approved = false`, they cannot see any data.
3. **User Management:** ONLY users with the `dnts_head` role can update the `profiles` table to change a user's `is_approved` status or `role`.
4. **Audit Immutability:** `movement_logs` are insert-only. No role can UPDATE or DELETE a log.

---

## DESIGN_SYSTEM.md

# UI/UX Design System

## Aesthetic Philosophy
- **Refined Minimalism & Swiss Style:** Prioritize typography, negative space, and a high signal-to-noise ratio.
- **Strict Flat Design:** UI components must be completely flat. 
- **Prohibited Elements:** Absolutely NO skeuomorphism, NO gradients, NO bevels, and NO drop shadows.

## Core Components
- **Surfaces:** Utilize clean, white "Admin Gateway" style card designs for content containers against a slightly off-white or light gray background.
- **Borders:** Use crisp, 1px solid borders to delineate components instead of elevation.
- **Icons:** Use sharp, solid-color vector icons (e.g., Material Symbols).

---

## MAP_DIMENSIONS.md

# Laboratory Map Dimensions

## Canvas Size (Exact Fit - No Extra Margins)

**Canvas Dimensions:**
- **Width**: 3,200 pixels (32 columns × 100px)
- **Height**: 1,700 pixels (17 rows × 100px)
- **Total Area**: 5,440,000 pixels²

**In Inches (at 96 DPI - standard screen resolution):**
- **Width**: 33.33 inches (3,200 ÷ 96)
- **Height**: 17.71 inches (1,700 ÷ 96)
- **Aspect Ratio**: 1.88:1 (approximately 16:8.5)

**Design Philosophy:**
- Canvas is sized exactly to fit laboratory content
- No extra margins or empty space
- Minimum zoom = entire map visible
- Maximum efficiency and precision

---

## Laboratory Content Bounds (Actual Desks)

**Grid Coordinates (Original System):**
- **Columns**: 2 (B) to 33 (AG) = **32 columns**
- **Rows**: 2 to 18 = **17 rows**

**Canvas Coordinates (Adjusted System):**
- **Columns**: 0 to 31 (shifted by -2)
- **Rows**: 0 to 16 (shifted by -2)
- **Note**: Internal coordinates still use original system (2-33, 2-18), but display is offset

**Pixel Dimensions:**
- **Width**: 3,200 pixels (32 columns × 100px)
- **Height**: 1,700 pixels (17 rows × 100px)
- **Total Area**: 5,440,000 pixels²

**In Inches (at 96 DPI):**
- **Width**: 33.33 inches
- **Height**: 17.71 inches

**Position on Canvas:**
- **Left Edge**: 0 pixels (no margin)
- **Top Edge**: 0 pixels (no margin)
- **Right Edge**: 3,200 pixels (full width)
- **Bottom Edge**: 1,700 pixels (full height)

---

## Grid Cell Size

**Each Cell:**
- **Size**: 100 × 100 pixels
- **In Inches**: 1.04 × 1.04 inches (at 96 DPI)
- **Purpose**: Represents one desk position or structural element

---

## Coordinate System

### Internal Coordinates (Data Layer)
- Labs use original spreadsheet coordinates
- Columns: 2-33 (B-AG)
- Rows: 2-18
- Stored in `deskLayouts` map

### Display Coordinates (Visual Layer)
- Canvas starts at (0, 0)
- Offset applied: -200px X, -200px Y
- Formula: `displayX = (dataCol × 100) - 200`
- Formula: `displayY = (dataRow × 100) - 200`

**Example:**
- Desk at column 2, row 2 (B2) → displays at (0, 0)
- Desk at column 33, row 18 (AG18) → displays at (3100, 1600)

---

## Margins

### Canvas Margins
**NONE** - Canvas is sized exactly to content

### InteractiveViewer Boundary Margin
- **100 pixels** on all sides (for panning beyond edges)
- This is a viewport feature, not canvas space
- Allows slight over-panning for better UX

---

## Laboratory Layout

### Lab Positions (Column Ranges)

| Lab | Columns (Data) | Columns (Display) | Width (cells) | Width (pixels) | Width (inches) |
|-----|----------------|-------------------|---------------|----------------|----------------|
| Lab 6 | B-K (2-11) | 0-9 | 10 | 1,000 | 10.42 |
| Lab 7 | B-G (2-7) | 0-5 | 6 | 600 | 6.25 |
| Lab 1 | M-T (13-20) | 11-18 | 8 | 800 | 8.33 |
| Lab 2 | M-T (13-20) | 11-18 | 8 | 800 | 8.33 |
| Lab 3 | V-AG (22-33) | 20-31 | 12 | 1,200 | 12.50 |
| Lab 4 | V-AG (22-33) | 20-31 | 12 | 1,200 | 12.50 |
| Lab 5 | V-AG (22-33) | 20-31 | 12 | 1,200 | 12.50 |

### Lab Positions (Row Ranges)

| Lab | Rows (Data) | Rows (Display) | Height (cells) | Height (pixels) | Height (inches) |
|-----|-------------|----------------|----------------|-----------------|-----------------|
| Lab 6 | 2-6 | 0-4 | 5 | 500 | 5.21 |
| Lab 7 | 8-9, 11-12, 14-15, 17-18 | 6-7, 9-10, 12-13, 15-16 | 8 | 800 | 8.33 |
| Lab 1 | 2-3, 5-6, 8-9 | 0-1, 3-4, 6-7 | 6 | 600 | 6.25 |
| Lab 2 | 11-12, 14-15, 17-18 | 9-10, 12-13, 15-16 | 6 | 600 | 6.25 |
| Lab 3 | 2-3, 5-6 | 0-1, 3-4 | 4 | 400 | 4.17 |
| Lab 4 | 8-9, 11-12 | 6-7, 9-10 | 4 | 400 | 4.17 |
| Lab 5 | 14-15, 17-18 | 12-13, 15-16 | 4 | 400 | 4.17 |

---

## Desk Count

**Total Desks**: 332
- Lab 6: 48 desks
- Lab 7: 48 desks
- Lab 1: 48 desks
- Lab 2: 48 desks
- Lab 3: 46 desks (2 pillars)
- Lab 4: 46 desks (2 pillars)
- Lab 5: 48 desks

**Pillars (Structural Obstructions)**: 4
- V5 (data: 22,5 → display: 20,3) - Lab 3
- W5 (data: 23,5 → display: 21,3) - Lab 3
- V12 (data: 22,12 → display: 20,10) - Lab 4
- W12 (data: 23,12 → display: 21,10) - Lab 4

---

## Zoom Constraints

**Current Implementation:**
- **Minimum Scale**: Dynamically calculated to fit entire canvas with 90% screen coverage
- **Maximum Scale**: 5.0× (500% zoom)
- **Default View**: Fit entire canvas (all labs visible)
- **Enforcement**: `_enforceMinScale()` listener prevents zooming out beyond minimum

**Fit Scale Calculation:**
```dart
canvasWidth = 3,200 pixels
canvasHeight = 1,700 pixels

scaleX = (screenWidth × 0.9) / 3,200
scaleY = (screenHeight × 0.9) / 1,700
fitScale = min(scaleX, scaleY)

_minAllowedScale = fitScale // Cannot zoom out beyond this
```

**Example (1920×1080 screen):**
- scaleX = (1920 × 0.9) / 3,200 = 0.54
- scaleY = (1080 × 0.9) / 1,700 = 0.57
- fitScale = 0.54 (limited by width)
- **Minimum Scale**: 0.54 (enforced - cannot zoom out more)

**Result:**
- At minimum zoom, entire map fills ~90% of screen
- No wasted space or extra margins visible
- Perfect fit every time

---

## Changes from Previous Version

### Before (with margins):
- Canvas: 3,500 × 2,000 pixels
- Content: 3,200 × 1,700 pixels
- Margins: 200px (2.08 inches) on all sides
- Wasted space: 1,560,000 pixels² (22% of canvas)

### After (exact fit):
- Canvas: 3,200 × 1,700 pixels
- Content: 3,200 × 1,700 pixels
- Margins: 0px (none)
- Wasted space: 0 pixels² (0% of canvas)
- **Space saved**: 1,560,000 pixels² (22% reduction)

### Benefits:
✅ No wasted canvas space
✅ Minimum zoom = perfect fit
✅ Cannot zoom out beyond map bounds
✅ More efficient rendering
✅ Cleaner visual presentation
✅ Coordinate system still uses original spreadsheet values internally

---

## Summary

### Current Configuration (Exact Fit)
- **Canvas**: 3,200 × 1,700 pixels (33.33 × 17.71 inches)
- **Content**: 3,200 × 1,700 pixels (100% canvas utilization)
- **Margins**: 0 pixels (none - exact fit)
- **Grid Cell**: 100 × 100 pixels (1.04 × 1.04 inches)
- **Coordinate Offset**: -200px X, -200px Y (internal to display)
- **Minimum Zoom**: Enforced to show entire canvas
- **Result**: Perfect fit, no extra zoom out possible

---

**Note**: All inch measurements assume 96 DPI (standard screen resolution). The coordinate system maintains original spreadsheet values (columns 2-33, rows 2-18) internally, but displays them offset to start at canvas origin (0,0).

---

## PROJECT_CONTEXT.md

# Project: DNTS Inventory Management System (IMS)

## Governance & Hierarchy
- **Supreme Leader (You):** Absolute control. Assigns roles during the approval process.
- **Editors (Lab TAs):** Full inventory management.
- **Viewers:** Read-only & Printing.

## Workflow Rules (Simplified)
- **Sign-up:** Users only provide Name, Email, and Password. No role selection.
- **Approval:** All new users appear in the Command Center as "Pending."
- **Role Assignment:** The Supreme Leader selects either "Viewer" or "Editor" for the user BEFORE clicking "Approve."
