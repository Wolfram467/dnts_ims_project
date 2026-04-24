# Button Identification Guide

## 🎯 Which Button is Which?

### Header Layout
```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│  CT1 Floor Plan          [📊] [🔍-] [🔍+] [🔄] [☁️] [📋]            │
│                           ↑                           ↑                │
│                        TOGGLE                       LIST               │
│                     (Click this!)              (Not this!)             │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## 📊 Toggle Button (CORRECT)

### Visual Characteristics
```
┌─────────────────────────┐
│  ╔═══════════════════╗  │ ← THICK border (2px)
│  ║                   ║  │
│  ║        📊         ║  │ ← Table chart icon
│  ║                   ║  │
│  ╚═══════════════════╝  │
└─────────────────────────┘
```

### Properties
- **Icon**: 📊 (table_chart) in Map mode, 🗺️ (map) in Spreadsheet mode
- **Border**: 2px thick (thicker than others)
- **Position**: FIRST button on the right side
- **Function**: `_toggleViewMode()`
- **Action**: Switches between Map and Spreadsheet view
- **Background**: White (Map mode) → Black (Spreadsheet mode)

### When Clicked
```
Terminal Output:
🔄 TOGGLE VIEW MODE CALLED
   Current mode: Map
   New mode: Spreadsheet
   Loading spreadsheet data...
📊 Loading spreadsheet data from local storage...
✅ Loaded 144 components for spreadsheet view

UI Changes:
- Title: "CT1 Floor Plan" → "Lab 5 Spreadsheet"
- Button background: White → Black
- Icon: 📊 → 🗺️
- Content: Map grid → DataTable
```

## 📋 List Button (WRONG - Don't Click This!)

### Visual Characteristics
```
┌──────────────────────┐
│  ┌────────────────┐  │ ← THIN border (1px)
│  │                │  │
│  │       📋       │  │ ← List icon
│  │                │  │
│  └────────────────┘  │
└──────────────────────┘
```

### Properties
- **Icon**: 📋 (list) - always the same
- **Border**: 1px thin (thinner than toggle)
- **Position**: LAST button on the right side
- **Function**: `_listStoredData()`
- **Action**: Prints data to terminal (debug function)
- **Background**: Always white

### When Clicked
```
Terminal Output:
═══════════════════════════════════════
📋 LIST STORED DATA TRIGGERED FROM UI
═══════════════════════════════════════

📋 LISTING ALL WORKSTATION DATA IN LOCAL STORAGE
...

UI Changes:
- Snackbar: "📋 Check terminal for stored data listing"
- NO view change
- NO content change
```

## 🔍 Side-by-Side Comparison

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  TOGGLE BUTTON (📊)              LIST BUTTON (📋)              │
│  ═══════════════════              ───────────────              │
│                                                                 │
│  ╔═══════════════╗                ┌─────────────┐              │
│  ║      📊       ║                │     📋      │              │
│  ╚═══════════════╝                └─────────────┘              │
│                                                                 │
│  • 2px border                     • 1px border                 │
│  • First button                   • Last button                │
│  • Switches view                  • Prints to terminal         │
│  • Background changes             • Background stays white     │
│  • Icon changes                   • Icon stays same            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 How to Find the Toggle Button

### Step 1: Look at the Header
```
Find the title "CT1 Floor Plan" on the left side
```

### Step 2: Look to the Right
```
Find the row of buttons on the right side
```

### Step 3: Find the FIRST Button
```
The leftmost button in the right-side row
```

### Step 4: Check the Border
```
It should have a THICKER border than the others
```

### Step 5: Check the Icon
```
Should show 📊 (table chart icon)
```

## 🚀 Quick Test

### Test 1: Identify the Button
```
1. Open the app
2. Go to Interactive Map
3. Look at the right side of the header
4. Count the buttons from left to right
5. The FIRST button is the toggle
```

### Test 2: Click and Verify
```
1. Click the FIRST button (thick border, 📊 icon)
2. Check terminal for "🔄 TOGGLE VIEW MODE CALLED"
3. Check UI for title change to "Lab 5 Spreadsheet"
4. Check content switches to table
```

### Test 3: Toggle Back
```
1. Click the same button again (now shows 🗺️ icon)
2. Check terminal for "🔄 TOGGLE VIEW MODE CALLED"
3. Check UI for title change to "CT1 Floor Plan"
4. Check content switches back to map
```

## ❌ Common Mistakes

### Mistake 1: Clicking the List Button
```
Symptom: Snackbar says "Check terminal for stored data listing"
Problem: You clicked the LAST button (📋) instead of FIRST button (📊)
Solution: Click the FIRST button on the right
```

### Mistake 2: Looking for the Button on the Left
```
Problem: Toggle button is on the RIGHT side, not left
Solution: Look at the right side of the header
```

### Mistake 3: Expecting Immediate Change Without Restart
```
Problem: Hot reload may not work for state changes
Solution: Do a FULL RESTART (flutter run)
```

## 📊 Button Order (Left to Right)

```
Position 1: [📊] Toggle      ← THIS ONE!
Position 2: [🔍-] Zoom Out   (only in Map mode)
Position 3: [🔍+] Zoom In    (only in Map mode)
Position 4: [🔄] Refresh
Position 5: [☁️] Seed
Position 6: [📋] List        ← NOT THIS ONE!
```

## ✅ Correct Button Checklist

When you find the toggle button, it should:
- [ ] Be the FIRST button on the right side
- [ ] Have a THICKER border (2px) than other buttons
- [ ] Show 📊 icon (in Map mode)
- [ ] Be to the LEFT of the zoom buttons
- [ ] Have 16px spacing after it

## 🎯 Visual Memory Aid

```
Think of it as:
[TOGGLE] [zoom] [zoom] [refresh] [seed] [list]
   ↑                                      ↑
  THIS                                 NOT THIS
```

---

**The toggle button is the FIRST button on the right with a THICK border and 📊 icon!** 🎯
