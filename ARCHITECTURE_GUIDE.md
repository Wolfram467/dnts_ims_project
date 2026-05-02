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
DragBoundaryUtils.shouldTriggerEscapeGesture() evaluates
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
if (DragBoundaryUtils.myNewBoundaryCheck(event.position, screenSize)) {
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
  group('DragBoundaryUtils', () {
    test('shouldTriggerEscapeGesture detects left edge', () {
      final result = DragBoundaryUtils.shouldTriggerEscapeGesture(
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
**Cause**: `DragBoundaryUtils` threshold too strict  
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
