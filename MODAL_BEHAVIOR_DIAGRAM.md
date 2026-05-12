# Modal Dismissal Behavior - Visual Guide

## Screen Layout

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    MAP AREA                             │
│              (Top 30% of screen)                        │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ L5_T01  │  │ L5_T02  │  │ L5_T03  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
│                                                         │
├─────────────────────────────────────────────────────────┤ ← THRESHOLD (30%)
│                                                         │
│                                                         │
│              TRANSITION ZONE                            │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│           MODAL BOTTOM SHEET AREA                       │
│            (Bottom 70% of screen)                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Workstation: L5_T01                            │   │
│  │  ─────────────────────────────────────────────  │   │
│  │  1. Monitor - CT1_LAB5_MR01  [Edit]            │   │
│  │  2. Mouse - CT1_LAB5_M01     [Edit]            │   │
│  │  3. Keyboard - CT1_LAB5_K01  [Edit]            │   │
│  │  4. System Unit - CT1_LAB5_SU01 [Edit]         │   │
│  │  5. SSD - CT1_LAB5_SSD01     [Edit]            │   │
│  │  6. AVR - CT1_LAB5_AVR01     [Edit]            │   │
│  │                                                 │   │
│  │  [CLOSE]                                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Drag Sequence

### Step 1: Long-Press Initiated
```
User long-presses "Monitor - CT1_LAB5_MR01"
┌─────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────┐   │
│  │  Workstation: L5_T01                            │   │
│  │  ─────────────────────────────────────────────  │   │
│  │  1. Monitor - CT1_LAB5_MR01  [Edit] ← 👆        │   │
│  │     ▲                                           │   │
│  │     └─ Long-press detected                      │   │
│  │                                                 │   │
│  │  Modal STAYS OPEN ✓                            │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

Console Output:
🎯 DRAG STARTED: CT1_LAB5_MR01
   Modal stays open during long-press...
```

### Step 2: Cursor Moves Upward (Still Below Threshold)
```
Cursor Y = 50% of screen height (still in modal area)
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
│                                                         │
├─────────────────────────────────────────────────────────┤ ← THRESHOLD (30%)
│                                                         │
│              TRANSITION ZONE                            │
│                      ↑                                  │
│                      │ Cursor moving up                │
│                      │ Y = 50%                         │
├─────────────────────────────────────────────────────────┤
│           MODAL STILL VISIBLE ✓                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Workstation: L5_T01                            │   │
│  │  ─────────────────────────────────────────────  │   │
│  │  1. Monitor - CT1_LAB5_MR01  [Edit] (30% opacity)│  │
│  │  2. Mouse - CT1_LAB5_M01     [Edit]            │   │
│  │                                                 │   │
│  │  ┌──────────────┐                               │   │
│  │  │   Monitor    │ ← Feedback widget            │   │
│  │  │ CT1_LAB5_MR01│   follows cursor              │   │
│  │  └──────────────┘                               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

onDragUpdate fires continuously
Condition: details.globalPosition.dy (50%) > threshold (30%)
Result: Modal stays open
```

### Step 3: Cursor Crosses Threshold
```
Cursor Y = 25% of screen height (entered map area)
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
│              ┌──────────────┐                           │
│              │   Monitor    │ ← Cursor at Y=25%        │
│              │ CT1_LAB5_MR01│                           │
│              └──────────────┘                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ L5_T01  │  │ L5_T02  │  │ L5_T03  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
│                                                         │
├─────────────────────────────────────────────────────────┤ ← THRESHOLD (30%)
│                                                         │
│              TRANSITION ZONE                            │
│                                                         │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│           MODAL CLOSED ✓                                │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘

Console Output:
🚪 Cursor left modal area - closing modal

onDragUpdate detects:
- details.globalPosition.dy (25%) < threshold (30%)
- isModalClosed = false
Action: Navigator.pop(modalContext)
Result: Modal dismissed, full map visible
```

### Step 4: Drop on Target Desk
```
Full map visible, cursor over L5_T05
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
│              ┌──────────────┐                           │
│              │   Monitor    │                           │
│              │ CT1_LAB5_MR01│                           │
│              └──────────────┘                           │
│                      ↓                                  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ L5_T01  │  │ L5_T02  │  │ L5_T03  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ L5_T04  │  │ L5_T05  │  │ L5_T06  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
│                    ↑                                    │
│                    └─ Drop target (highlighted blue)   │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘

Console Output:
📦 DROP ACCEPTED
   Component: CT1_LAB5_MR01
   Target Desk: L5_T05
🔄 HANDLING COMPONENT DROP
   Source Desk: L5_T01
   Target Desk: L5_T05
   Component: Monitor - CT1_LAB5_MR01
   ✓ Removed from source desk
   ✓ Added to target desk
✅ DROP COMPLETE - Fluid persistence saved
✅ DRAG COMPLETED
```

## Code Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  User Long-Presses Component                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  onDragStarted() fires                                  │
│  - Print debug message                                  │
│  - Modal STAYS OPEN (no Navigator.pop)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  User Moves Cursor                                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  onDragUpdate(details) fires continuously               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
              ┌──────┴──────┐
              │             │
              ▼             ▼
    ┌─────────────────┐   ┌─────────────────┐
    │ isModalClosed?  │   │ Y < threshold?  │
    │     true        │   │     false       │
    └────────┬────────┘   └────────┬────────┘
             │                     │
             ▼                     ▼
    ┌─────────────────┐   ┌─────────────────┐
    │ Skip (already   │   │ Continue drag   │
    │ closed)         │   │ Modal visible   │
    └─────────────────┘   └─────────────────┘
                     │
                     ▼
              ┌──────┴──────┐
              │ Y < 30%?    │
              │   true      │
              └──────┬──────┘
                     │
                     ▼
    ┌─────────────────────────────────────┐
    │ isModalClosed = true                │
    │ Navigator.pop(modalContext)         │
    │ Print: "Cursor left modal area"     │
    └────────────────┬────────────────────┘
                     │
                     ▼
    ┌─────────────────────────────────────┐
    │ Modal dismissed                     │
    │ Full map visible                    │
    │ Continue drag to target             │
    └─────────────────────────────────────┘
```

## Threshold Calculation

```dart
// Screen dimensions
final screenHeight = MediaQuery.of(modalContext).size.height;

// Example: 1080px screen
// screenHeight = 1080px

// Threshold at 30% from top
final modalThreshold = screenHeight * 0.3;
// modalThreshold = 1080 * 0.3 = 324px

// Modal occupies bottom 70%
// Modal top edge ≈ 324px from screen top
// Modal bottom edge = 1080px (screen bottom)

// Cursor position check
if (details.globalPosition.dy < 324) {
  // Cursor is in top 30% (map area)
  // Close modal
}
```

## Benefits of This Approach

✅ **Natural UX:** Modal stays visible during initial grab  
✅ **Context Awareness:** User can see component list while deciding  
✅ **Smooth Transition:** Modal dismisses when entering map area  
✅ **No Accidental Closes:** Threshold prevents premature dismissal  
✅ **Performance:** Simple Y-coordinate check, no complex calculations  
✅ **Responsive:** Works with any screen size (percentage-based)  

---

**Implementation:** Complete  
**Testing:** Ready for user validation
