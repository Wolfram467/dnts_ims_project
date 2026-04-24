# Omni-Directional Break-Away - Visual Guide

## Screen Layout with Boundaries

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
├═════════════════════════════════════════════════════════┤ ← TOP BOUNDARY (Y = 30%)
│ ║                                                     ║ │
│ ║                                                     ║ │
│ ║              MODAL SAFE ZONE                       ║ │
│ ║        (Bottom 70% of screen)                      ║ │
│ ║                                                     ║ │
│ ║  ┌─────────────────────────────────────────────┐   ║ │
│ ║  │  Workstation: L5_T01                        │   ║ │
│ ║  │  ───────────────────────────────────────────│   ║ │
│ ║  │  1. Monitor - CT1_LAB5_MR01  [Edit]         │   ║ │
│ ║  │  2. Mouse - CT1_LAB5_M01     [Edit]         │   ║ │
│ ║  │  3. Keyboard - CT1_LAB5_K01  [Edit]         │   ║ │
│ ║  │  4. System Unit - CT1_LAB5_SU01 [Edit]      │   ║ │
│ ║  │  5. SSD - CT1_LAB5_SSD01     [Edit]         │   ║ │
│ ║  │  6. AVR - CT1_LAB5_AVR01     [Edit]         │   ║ │
│ ║  │                                              │   ║ │
│ ║  │  [CLOSE]                                     │   ║ │
│ ║  └─────────────────────────────────────────────┘   ║ │
│ ║                                                     ║ │
└─╨─────────────────────────────────────────────────────╨─┘
  ↑                                                     ↑
LEFT BOUNDARY                                  RIGHT BOUNDARY
(X = 10%)                                         (X = 90%)

Legend:
═══ Top boundary (horizontal)
║   Left/Right boundaries (vertical)
```

## Exit Scenarios

### Scenario 1: Top Exit (Most Common)

```
Step 1: Long-press component
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
├═════════════════════════════════════════════════════════┤
│ ║  ┌─────────────────────────────────────────────┐   ║ │
│ ║  │  1. Monitor - CT1_LAB5_MR01  [Edit] ← 👆    │   ║ │
│ ║  │     ▲                                       │   ║ │
│ ║  │     └─ Long-press detected                  │   ║ │
│ ║  │                                              │   ║ │
│ ║  │  Modal STAYS OPEN ✓                         │   ║ │
│ ║  └─────────────────────────────────────────────┘   ║ │
└─╨─────────────────────────────────────────────────────╨─┘

Console: 🎯 DRAG STARTED: CT1_LAB5_MR01
         ✓ Global ghost active, monitoring boundaries...
```

```
Step 2: Move cursor upward
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
│                      ↑                                  │
│                      │ Cursor moving up                │
│                      │ Y = 40%                         │
├═════════════════════════════════════════════════════════┤
│ ║                                                     ║ │
│ ║  ┌─────────────────────────────────────────────┐   ║ │
│ ║  │  1. Monitor - CT1_LAB5_MR01  [Edit] (30%)   │   ║ │
│ ║  │  2. Mouse - CT1_LAB5_M01     [Edit]         │   ║ │
│ ║  │                                              │   ║ │
│ ║  │  ┌──────────────┐                            │   ║ │
│ ║  │  │   Monitor    │ ← Feedback widget         │   ║ │
│ ║  │  │ CT1_LAB5_MR01│   follows cursor           │   ║ │
│ ║  │  └──────────────┘                            │   ║ │
│ ║  └─────────────────────────────────────────────┘   ║ │
└─╨─────────────────────────────────────────────────────╨─┘

onDragUpdate: cursorY (40%) > topBoundary (30%)
Result: Modal stays open
```

```
Step 3: Cross top boundary
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
│              ┌──────────────┐                           │
│              │   Monitor    │ ← Cursor at Y=25%        │
│              │ CT1_LAB5_MR01│   (crossed boundary!)    │
│              └──────────────┘                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                │
│  │ L5_T01  │  │ L5_T02  │  │ L5_T03  │                │
│  └─────────┘  └─────────┘  └─────────┘                │
├═════════════════════════════════════════════════════════┤
│                                                         │
│           MODAL CLOSED ✓                                │
│                                                         │
│           Global ghost now tracking                     │
│                                                         │
└─────────────────────────────────────────────────────────┘

Console: 🚪 Cursor exited modal area (TOP) - closing modal
         ✓ Modal closed, global ghost continues tracking

onDragUpdate: cursorY (25%) < topBoundary (30%)
Action: Navigator.pop(modalContext)
Result: Modal dismissed, ghost persists
```

### Scenario 2: Left Exit

```
Step 1: Long-press and move left
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
├═════════════════════════════════════════════════════════┤
│ ║                                                     ║ │
│ ║  ┌─────────────────────────────────────────────┐   ║ │
│ ║  │  1. Monitor - CT1_LAB5_MR01  [Edit]         │   ║ │
│ ║  │     ▲                                       │   ║ │
│ ║  │     └─ Dragging left                        │   ║ │
│ ║  │                                              │   ║ │
│ ║  │  ┌──────────────┐                            │   ║ │
│ ║  │  │   Monitor    │ ← Moving left             │   ║ │
│ ║  │  │ CT1_LAB5_MR01│   X = 15%                 │   ║ │
│ ║  │  └──────────────┘                            │   ║ │
│ ║  └─────────────────────────────────────────────┘   ║ │
└─╨─────────────────────────────────────────────────────╨─┘

onDragUpdate: cursorX (15%) > leftBoundary (10%)
Result: Modal stays open
```

```
Step 2: Cross left boundary
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
├═════════════════════════════════════════════════════════┤
│ ┌──────────────┐                                        │
│ │   Monitor    │ ← Cursor at X=8% (crossed boundary!)  │
│ │ CT1_LAB5_MR01│                                        │
│ └──────────────┘                                        │
│                                                         │
│           MODAL CLOSED ✓                                │
│                                                         │
│           Global ghost now tracking                     │
│                                                         │
└─────────────────────────────────────────────────────────┘

Console: 🚪 Cursor exited modal area (LEFT) - closing modal
         ✓ Modal closed, global ghost continues tracking

onDragUpdate: cursorX (8%) < leftBoundary (10%)
Action: Navigator.pop(modalContext)
Result: Modal dismissed, ghost persists
```

### Scenario 3: Right Exit

```
Step 1: Long-press and move right
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
├═════════════════════════════════════════════════════════┤
│ ║                                                     ║ │
│ ║  ┌─────────────────────────────────────────────┐   ║ │
│ ║  │  1. Monitor - CT1_LAB5_MR01  [Edit]         │   ║ │
│ ║  │     ▲                                       │   ║ │
│ ║  │     └─ Dragging right                       │   ║ │
│ ║  │                                              │   ║ │
│ ║  │                            ┌──────────────┐  │   ║ │
│ ║  │             Moving right → │   Monitor    │  │   ║ │
│ ║  │                 X = 85%    │ CT1_LAB5_MR01│  │   ║ │
│ ║  │                            └──────────────┘  │   ║ │
│ ║  └─────────────────────────────────────────────┘   ║ │
└─╨─────────────────────────────────────────────────────╨─┘

onDragUpdate: cursorX (85%) < rightBoundary (90%)
Result: Modal stays open
```

```
Step 2: Cross right boundary
┌─────────────────────────────────────────────────────────┐
│                    MAP AREA                             │
├═════════════════════════════════════════════════════════┤
│                                        ┌──────────────┐ │
│  Cursor at X=92% (crossed boundary!) → │   Monitor    │ │
│                                        │ CT1_LAB5_MR01│ │
│                                        └──────────────┘ │
│                                                         │
│           MODAL CLOSED ✓                                │
│                                                         │
│           Global ghost now tracking                     │
│                                                         │
└─────────────────────────────────────────────────────────┘

Console: 🚪 Cursor exited modal area (RIGHT) - closing modal
         ✓ Modal closed, global ghost continues tracking

onDragUpdate: cursorX (92%) > rightBoundary (90%)
Action: Navigator.pop(modalContext)
Result: Modal dismissed, ghost persists
```

## Boundary Detection Logic Flow

```
┌─────────────────────────────────────────────────────────┐
│  onDragUpdate(details) fires                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ isModalClosed?│
              │     true      │
              └──────┬────────┘
                     │
                     ▼
              ┌──────────────┐
              │ Skip (already│
              │ closed)      │
              └──────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ Get screen   │
              │ dimensions   │
              └──────┬────────┘
                     │
                     ▼
              ┌──────────────┐
              │ Get cursor   │
              │ position     │
              └──────┬────────┘
                     │
                     ▼
              ┌──────────────┐
              │ Calculate    │
              │ boundaries   │
              └──────┬────────┘
                     │
                     ▼
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│ Y < 30%?      │         │ X < 10%?      │
│ (TOP EXIT)    │         │ (LEFT EXIT)   │
└───────┬───────┘         └───────┬───────┘
        │                         │
        ▼                         ▼
┌───────────────┐         ┌───────────────┐
│ leftSafeZone  │         │ leftSafeZone  │
│ = true        │         │ = true        │
│ direction =   │         │ direction =   │
│ 'TOP'         │         │ 'LEFT'        │
└───────┬───────┘         └───────┬───────┘
        │                         │
        └────────────┬────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ X > 90%?     │
              │ (RIGHT EXIT) │
              └──────┬────────┘
                     │
                     ▼
              ┌──────────────┐
              │ leftSafeZone │
              │ = true       │
              │ direction =  │
              │ 'RIGHT'      │
              └──────┬────────┘
                     │
                     ▼
              ┌──────────────┐
              │ leftSafeZone?│
              │     true     │
              └──────┬────────┘
                     │
                     ▼
    ┌────────────────────────────────┐
    │ Print exit message             │
    │ isModalClosed = true           │
    │ Navigator.pop(modalContext)    │
    │ Print confirmation             │
    └────────────────┬───────────────┘
                     │
                     ▼
    ┌────────────────────────────────┐
    │ Modal dismissed                │
    │ Global ghost continues         │
    │ Listener tracks cursor         │
    └────────────────────────────────┘
```

## Coordinate System

```
Screen Coordinates (0,0 at top-left)

(0,0) ────────────────────────────────────────── (screenWidth, 0)
  │                                                    │
  │                                                    │
  │                  MAP AREA                          │
  │                                                    │
  │                                                    │
(0, screenHeight * 0.3) ═══════════════════════ (screenWidth, screenHeight * 0.3)
  │                                                    │
  │                                                    │
  │                MODAL SAFE ZONE                     │
  │                                                    │
  │                                                    │
(0, screenHeight) ──────────────────────────── (screenWidth, screenHeight)

Boundary Checks:
- Top:   cursorY < screenHeight * 0.3
- Left:  cursorX < screenWidth * 0.1
- Right: cursorX > screenWidth * 0.9
```

## Example Screen Dimensions

### 1920x1080 Screen (Full HD)

```
Screen: 1920px wide × 1080px tall

Boundaries:
- Top:   Y < 324px  (1080 * 0.3)
- Left:  X < 192px  (1920 * 0.1)
- Right: X > 1728px (1920 * 0.9)

Safe Zone:
- X: 192px to 1728px (1536px wide)
- Y: 324px to 1080px (756px tall)
```

### 1366x768 Screen (Laptop)

```
Screen: 1366px wide × 768px tall

Boundaries:
- Top:   Y < 230px  (768 * 0.3)
- Left:  X < 137px  (1366 * 0.1)
- Right: X > 1229px (1366 * 0.9)

Safe Zone:
- X: 137px to 1229px (1092px wide)
- Y: 230px to 768px (538px tall)
```

### 2560x1440 Screen (2K)

```
Screen: 2560px wide × 1440px tall

Boundaries:
- Top:   Y < 432px  (1440 * 0.3)
- Left:  X < 256px  (2560 * 0.1)
- Right: X > 2304px (2560 * 0.9)

Safe Zone:
- X: 256px to 2304px (2048px wide)
- Y: 432px to 1440px (1008px tall)
```

---

**Pattern:** Omni-directional Break-away Detection  
**Boundaries:** TOP (30%), LEFT (10%), RIGHT (90%)  
**Ghost:** Persists after modal closes  
**Status:** Ready for testing
