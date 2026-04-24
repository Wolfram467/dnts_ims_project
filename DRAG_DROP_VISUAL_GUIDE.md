# Drag-and-Drop Visual Guide

## 🎯 How to Move Components

### Step-by-Step Visual Walkthrough

#### Step 1: Open Workstation Details
```
Click any desk on the map
↓
┌─────────────────────────────────────────────────────────┐
│  L5_T01                                       [LOCAL]   │
├─────────────────────────────────────────────────────────┤
│  [6 Components]                                         │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor                                  [✏️]  │ │
│  │ DNTS Serial: CT1_LAB5_MR01                        │ │
│  │ Mfg Serial:  ZZNNH4ZM301248N                      │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ... (5 more components)                                │
└─────────────────────────────────────────────────────────┘
```

#### Step 2: Long-Press Component
```
Long-press on any component card
↓
┌─────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor                                  [✏️]  │ │ ← Long-press here
│  │ DNTS Serial: CT1_LAB5_MR01                        │ │   (hold for 1 sec)
│  │ Mfg Serial:  ZZNNH4ZM301248N                      │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

#### Step 3: Drag Starts
```
Component becomes semi-transparent
Blue feedback widget appears
↓
┌─────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor (30% opacity)                    [✏️]  │ │ ← Faded
│  │ DNTS Serial: CT1_LAB5_MR01                        │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Cursor position:                                       │
│  ┌─────────────────────┐                               │
│  │ Monitor             │ ← Blue feedback widget        │
│  │ CT1_LAB5_MR01       │   follows cursor              │
│  └─────────────────────┘                               │
└─────────────────────────────────────────────────────────┘
```

#### Step 4: Drag Over Map
```
Modal closes automatically
Map view shows with hover effects
↓
┌─────────────────────────────────────────────────────────┐
│  Map View                                               │
│                                                         │
│  [L5_T01] [L5_T02] [L5_T03] [L5_T04] ...               │
│     ↑        ↑                                          │
│  Source   Target                                        │
│  (normal) (blue highlight)                              │
│                                                         │
│  Dragging: ┌─────────────────────┐                     │
│            │ Monitor             │                      │
│            │ CT1_LAB5_MR01       │                      │
│            └─────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

#### Step 5: Hover Over Target
```
Target desk highlights in blue
Border becomes thicker
↓
┌─────────────────────────────────────────────────────────┐
│  [L5_T01] ╔═══════════╗ [L5_T03] [L5_T04] ...          │
│     ↑     ║  L5_T02   ║    ↑                            │
│  Source   ║  (blue)   ║  Other                          │
│  (normal) ╚═══════════╝ (normal)                        │
│              ↑                                           │
│           Drop zone                                      │
└─────────────────────────────────────────────────────────┘
```

#### Step 6: Drop Component
```
Release finger/mouse
Component drops onto target desk
↓
Terminal Output:
📦 DROP ACCEPTED
   Component: CT1_LAB5_MR01
   Target Desk: L5_T02
🔄 HANDLING COMPONENT DROP
   Source Desk: L5_T01
   Target Desk: L5_T02
   Component: Monitor - CT1_LAB5_MR01
   ✓ Removed from source desk
   ✓ Added to target desk
✅ DROP COMPLETE - Fluid persistence saved
```

#### Step 7: Automatic Detail View
```
Target desk details shown automatically
↓
┌─────────────────────────────────────────────────────────┐
│  L5_T02                                       [LOCAL]   │
├─────────────────────────────────────────────────────────┤
│  [7 Components]                                         │ ← Now 7!
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor                                  [✏️]  │ │ ← Original
│  │ DNTS Serial: CT1_LAB5_MR02                        │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ... (5 more original components)                       │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ ⚠️ 7. Monitor          [DUPLICATE]          [✏️]  │ │ ← Dropped!
│  │ DNTS Serial: CT1_LAB5_MR01                        │ │   Yellow bg
│  │ Mfg Serial:  ZZNNH4ZM301248N                      │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 🎨 Visual States

### Normal Component
```
┌─────────────────────────────────────┐
│ 1. Monitor              [✏️]        │
│ DNTS Serial: CT1_LAB5_MR01          │
│ Mfg Serial:  ZZNNH4ZM301248N        │
└─────────────────────────────────────┘
• White background
• Black border (1px)
• Normal text color
```

### Duplicate Component (Yellow Zone)
```
┌─────────────────────────────────────┐
│ ⚠️ 1. Monitor  [DUPLICATE]  [✏️]   │
│ DNTS Serial: CT1_LAB5_MR01          │
│ Mfg Serial:  ZZNNH4ZM301248N        │
└─────────────────────────────────────┘
• Yellow background (Colors.yellow.shade100)
• Orange border (2px, Colors.orange.shade700)
• Orange text (Colors.orange.shade900)
• Warning icon (⚠️)
• "DUPLICATE" badge
```

### Component While Dragging
```
┌─────────────────────────────────────┐
│ 1. Monitor (faded)      [✏️]        │
│ DNTS Serial: CT1_LAB5_MR01          │
│ Mfg Serial:  ZZNNH4ZM301248N        │
└─────────────────────────────────────┘
• 30% opacity
• Original styling maintained
• Still visible in original position
```

### Drag Feedback Widget
```
┌─────────────────────────────────────┐
│ Monitor                             │
│ CT1_LAB5_MR01                       │
└─────────────────────────────────────┘
• Blue background (Colors.blue.shade100)
• Blue border (2px)
• Bold text
• Follows cursor
• Elevated (shadow)
```

### Desk Normal State
```
┌─────────┐
│ L5_T01  │
└─────────┘
• White background
• Black border (1px)
• Small text (8px)
```

### Desk Hover State (Drop Zone)
```
╔═══════════╗
║  L5_T01   ║
╚═══════════╝
• Blue background (Colors.blue.shade100)
• Blue border (2px)
• Indicates drop zone
```

## 🔄 Interaction Flow Diagram

```
┌─────────────────┐
│ Click Desk      │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Modal Opens     │
│ Show Components │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Long-Press      │
│ Component       │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Drag Starts     │
│ • Opacity 30%   │
│ • Feedback shows│
└────────┬────────┘
         ↓
┌─────────────────┐
│ Drag Over Map   │
│ • Modal closes  │
│ • Desks visible │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Hover Target    │
│ • Blue highlight│
│ • Border thick  │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Drop Component  │
│ • Remove source │
│ • Add to target │
│ • Save changes  │
└────────┬────────┘
         ↓
┌─────────────────┐
│ Show Target     │
│ Details         │
│ • Auto-open     │
│ • Show all      │
│ • Highlight dup │
└─────────────────┘
```

## 🎯 Duplicate Detection Examples

### Example 1: Single Duplicate
```
Before Drop:
┌─────────────────────────────────────┐
│ 1. Monitor              [✏️]        │ ← Normal
│ 2. Mouse                [✏️]        │ ← Normal
│ 3. Keyboard             [✏️]        │ ← Normal
└─────────────────────────────────────┘

After Dropping Another Monitor:
┌─────────────────────────────────────┐
│ ⚠️ 1. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ 2. Mouse                [✏️]        │ ← Normal
│ 3. Keyboard             [✏️]        │ ← Normal
│ ⚠️ 4. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
└─────────────────────────────────────┘
```

### Example 2: Multiple Duplicates
```
After Dropping Multiple Components:
┌─────────────────────────────────────┐
│ ⚠️ 1. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ ⚠️ 2. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ ⚠️ 3. Mouse    [DUPLICATE]  [✏️]   │ ← Yellow
│ ⚠️ 4. Mouse    [DUPLICATE]  [✏️]   │ ← Yellow
│ 5. Keyboard             [✏️]        │ ← Normal
└─────────────────────────────────────┘
```

### Example 3: Triple Duplicate
```
┌─────────────────────────────────────┐
│ ⚠️ 1. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ ⚠️ 2. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ ⚠️ 3. Monitor  [DUPLICATE]  [✏️]   │ ← Yellow
│ 4. Mouse                [✏️]        │ ← Normal
└─────────────────────────────────────┘
```

## 🎨 Color Palette

### Normal State
- Background: `Colors.white`
- Border: `Colors.black` (1px)
- Text: `Colors.black`

### Duplicate State (Yellow Zone)
- Background: `Colors.yellow.shade100` (#FFFDE7)
- Border: `Colors.orange.shade700` (#F57C00) (2px)
- Text: `Colors.orange.shade900` (#E65100)
- Badge: `Colors.orange.shade700` background, white text
- Icon: `Colors.orange.shade700`

### Drag Feedback
- Background: `Colors.blue.shade100` (#BBDEFB)
- Border: `Colors.blue` (#2196F3) (2px)
- Text: `Colors.black` (bold)

### Hover State
- Background: `Colors.blue.shade100` (#BBDEFB)
- Border: `Colors.blue` (#2196F3) (2px)

## 📱 Gesture Guide

### Long-Press
```
Touch and hold for ~1 second
↓
Drag starts
```

### Drag
```
Move finger/mouse while holding
↓
Feedback widget follows
```

### Drop
```
Release finger/mouse over target
↓
Component moves
```

### Cancel
```
Release finger/mouse outside any desk
↓
Component returns to source
```

## ✅ Success Indicators

### Visual
- ✅ Target desk details open automatically
- ✅ Component appears in target list
- ✅ Duplicates highlighted in yellow
- ✅ Warning icons visible

### Terminal
- ✅ "DROP ACCEPTED" message
- ✅ "Removed from source desk"
- ✅ "Added to target desk"
- ✅ "DROP COMPLETE - Fluid persistence saved"

---

**Long-press any component to start dragging!** 🎯
