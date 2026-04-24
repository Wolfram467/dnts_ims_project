# Visual Guide: Map Storage Setup

## 📍 Where to Add Your Data

```
lib/seed_lab5_data.dart
│
├─ Line 1-3: Imports (don't touch)
│
├─ Line 5-12: Header comment
│
├─ Line 13-15: ⭐ PASTE YOUR DATA HERE ⭐
│   const Map<String, Map<String, dynamic>> workstationData = {
│     // TODO: Paste your workstation data here  ← Replace this line
│   };
│
├─ Line 17-52: seedLab5Data() function (don't touch)
│
└─ Line 54+: Helper functions (don't touch)
```

## 📝 Data Format Visual

### Before (Empty)
```dart
const Map<String, Map<String, dynamic>> workstationData = {
  // TODO: Paste your workstation data here
};
```

### After (With Your Data)
```dart
const Map<String, Map<String, dynamic>> workstationData = {
  'L5_T01': {
    'dnts_serial': 'CT1_LAB5_MR01',
    'category': 'Monitor',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T01',
  },
  'L5_T02': {
    'dnts_serial': 'CT1_LAB5_M02',
    'category': 'Mouse',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T02',
  },
  'L5_T03': {
    'dnts_serial': 'CT1_LAB5_K03',
    'category': 'Keyboard',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T03',
  },
  // ... continue for all your workstations
};
```

## 🎯 Lab 5 Desk Layout

```
Lab 5 - Block 1 (24 desks)
┌─────────────────────────────────────────────────────────────┐
│ Row 1: L5_T01  L5_T02  L5_T03  ...  L5_T11  L5_T12         │
│ Row 2: L5_T13  L5_T14  L5_T15  ...  L5_T23  L5_T24         │
└─────────────────────────────────────────────────────────────┘

Lab 5 - Block 2 (24 desks)
┌─────────────────────────────────────────────────────────────┐
│ Row 1: L5_T25  L5_T26  L5_T27  ...  L5_T35  L5_T36         │
│ Row 2: L5_T37  L5_T38  L5_T39  ...  L5_T47  L5_T48         │
└─────────────────────────────────────────────────────────────┘

Total: 48 workstations
```

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  1. YOU: Paste data into lib/seed_lab5_data.dart            │
│     const Map<String, Map<String, dynamic>> workstationData │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. RUN APP: flutter run -d chrome                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. NAVIGATE: Go to Interactive Map screen                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. SEED: Click ☁️ button in toolbar                        │
│     → seedLab5Data() runs                                   │
│     → Saves to SharedPreferences                            │
│     → Terminal: "✅ X workstations assigned"                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. TEST: Click any Lab 5 desk (e.g., L5_T01)              │
│     → _showWorkstationDetails() runs                        │
│     → Terminal: "🖱️ Desk clicked: L5_T01"                  │
│     → Terminal: "🔍 Querying local storage..."             │
│     → getWorkstationAsset() queries SharedPreferences       │
│     → Terminal: "✅ Found: CT1_LAB5_MR01 (Monitor)"         │
│     → Modal shows asset data with "LOCAL" badge             │
└─────────────────────────────────────────────────────────────┘
```

## 🖥️ Terminal Output Visual

### When You Seed Data
```
═══════════════════════════════════════
🚀 SEED SCRIPT TRIGGERED FROM UI
═══════════════════════════════════════

📊 Found 48 workstations in data map
🌱 Starting Lab 5 data seeding...
  ✓ Saved: L5_T01 -> CT1_LAB5_MR01
  ✓ Saved: L5_T02 -> CT1_LAB5_M02
  ✓ Saved: L5_T03 -> CT1_LAB5_K03
  ...
  ✓ Saved: L5_T48 -> CT1_LAB5_MR48
✅ Lab 5 seeding complete! 48 workstations assigned.
📦 Data committed to SharedPreferences (permanent local storage)
```

### When You Click a Desk
```
🖱️ Desk clicked: L5_T01
🔍 Querying local storage for workstation: L5_T01
✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
```

### When You Click an Empty Desk
```
🖱️ Desk clicked: L5_T99
🔍 Querying local storage for workstation: L5_T99
❌ No asset found in local storage for: L5_T99
```

## 🎨 UI Visual

### Map Screen Toolbar
```
┌────────────────────────────────────────────────────────────────┐
│  CT1 Floor Plan                    [🔍-] [🔍+] [🔄] [☁️] [📋] │
└────────────────────────────────────────────────────────────────┘
                                        │    │    │    │    │
                                        │    │    │    │    └─ List data
                                        │    │    │    └────── Seed data ⭐
                                        │    │    └─────────── Refresh
                                        │    └──────────────── Zoom in
                                        └───────────────────── Zoom out
```

### Modal When Desk Has Data
```
┌─────────────────────────────────────────────┐
│  L5_T01                           [LOCAL]   │ ← Green badge
├─────────────────────────────────────────────┤
│                                             │
│  Serial:   CT1_LAB5_MR01                    │
│  Category: Monitor                          │
│  Status:   Deployed                         │
│  Source:   Local Storage                    │
│                                             │
├─────────────────────────────────────────────┤
│              [ CLOSE ]                      │
└─────────────────────────────────────────────┘
```

### Modal When Desk Is Empty
```
┌─────────────────────────────────────────────┐
│  L5_T99                                     │
├─────────────────────────────────────────────┤
│                                             │
│  Empty Workstation                          │
│                                             │
├─────────────────────────────────────────────┤
│              [ CLOSE ]                      │
└─────────────────────────────────────────────┘
```

## 📊 Data Structure Visual

### In Memory (Your Code)
```dart
workstationData = {
  'L5_T01': {
    'dnts_serial': 'CT1_LAB5_MR01',
    'category': 'Monitor',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T01',
  },
}
```

### In Storage (SharedPreferences)
```
Key: "workstation_L5_T01"
Value: '{"dnts_serial":"CT1_LAB5_MR01","category":"Monitor","status":"Deployed","current_workstation_id":"L5_T01"}'
```

### Retrieved (When Queried)
```dart
{
  'dnts_serial': 'CT1_LAB5_MR01',
  'category': 'Monitor',
  'status': 'Deployed',
  'current_workstation_id': 'L5_T01',
}
```

## ✅ Success Checklist Visual

```
Before Adding Data:
[ ] workstationData Map is empty
[ ] Seed button shows warning
[ ] Desks show "Empty Workstation"

After Adding Data:
[✓] workstationData Map has entries
[✓] Seed button saves to storage
[✓] Terminal shows "X workstations assigned"

After Clicking Desk:
[✓] Terminal prints desk ID
[✓] Terminal prints query message
[✓] Terminal prints found/not found
[✓] Modal shows asset data
[✓] "LOCAL" badge appears

After App Restart:
[✓] Data still in storage
[✓] Clicking desk still works
[✓] No need to seed again
```

## 🎯 Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    QUICK REFERENCE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📁 File to Edit:  lib/seed_lab5_data.dart                 │
│  📍 Line to Edit:  ~13 (workstationData Map)               │
│  🔧 What to Do:    Paste your JSON data                    │
│                                                             │
│  ▶️  Run:          flutter pub get                         │
│                   flutter run -d chrome                     │
│                                                             │
│  🎯 In App:        1. Go to Map                            │
│                   2. Click ☁️                               │
│                   3. Click L5_T01                           │
│                   4. Check terminal                         │
│                                                             │
│  ✅ Success:       Terminal shows desk ID + query result    │
│                   Modal shows data + "LOCAL" badge          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🚨 Warning Signs

### ⚠️ Data Not Added Yet
```
Terminal: "⚠️  WARNING: workstationData Map is empty!"
UI:       Orange snackbar warning
Action:   Add data to lib/seed_lab5_data.dart
```

### ⚠️ Syntax Error
```
Terminal: Compilation error
UI:       App won't run
Action:   Check quotes, commas, brackets
```

### ⚠️ Wrong Workstation ID
```
Terminal: "❌ No asset found in local storage"
UI:       "Empty Workstation"
Action:   Check ID matches exactly (L5_T01, not L5_T1)
```

## 📚 Documentation Map

```
START HERE
    ↓
README_SEED_SETUP.md ← Quick instructions
    ↓
HOW_TO_ADD_DATA.md ← Detailed guide
    ↓
EXAMPLE_DATA_FORMAT.dart ← Copy-paste template
    ↓
QUICK_TEST_GUIDE.md ← Testing steps
    ↓
VERIFICATION_CHECKLIST.md ← Complete checklist

REFERENCE:
- ARCHITECTURE_DIAGRAM.md ← How it works
- COMMANDS.md ← Command reference
- VISUAL_GUIDE.md ← This file
```

---

**You're all set!** Just add your data and run the app. 🚀
