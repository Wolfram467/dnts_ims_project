# Spreadsheet View - Visual Guide

## 🎯 Toggle Button Location

```
┌─────────────────────────────────────────────────────────────────┐
│  [📊] CT1 Floor Plan                    [🔍-][🔍+][🔄][☁️][📋] │ ← Map Mode
└─────────────────────────────────────────────────────────────────┘
   ↑
   Toggle button (click to switch to Spreadsheet)


┌─────────────────────────────────────────────────────────────────┐
│  [🗺️] Lab 5 Spreadsheet                      [🔄][☁️][📋]      │ ← Spreadsheet Mode
└─────────────────────────────────────────────────────────────────┘
   ↑
   Toggle button (click to switch back to Map)
   (Black background when active)
```

## 📊 Spreadsheet View Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [🗺️] Lab 5 Spreadsheet                              [🔄] [☁️] [📋]         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ Desk ID │ Category    │ DNTS Serial    │ Mfg Serial      │ Status     │ │
│  ├─────────┼─────────────┼────────────────┼─────────────────┼────────────┤ │
│  │ L5_T01  │ Monitor     │ CT1_LAB5_MR01  │ ZZNNH4ZM301248N │ [Deployed] │ │
│  │ L5_T01  │ Mouse       │ CT1_LAB5_M01   │ 97205H5         │ [Deployed] │ │
│  │ L5_T01  │ Keyboard    │ CT1_LAB5_K01   │ 95NAA63         │ [Deployed] │ │
│  │ L5_T01  │ System Unit │ CT1_LAB5_SU01  │ 2022A0853       │ [Deployed] │ │
│  │ L5_T01  │ SSD         │ CT1_LAB5_SSD01 │ 0026-B768-...   │ [Deployed] │ │
│  │ L5_T01  │ AVR         │ CT1_LAB5_AVR01 │ YY2023030106970 │ [Deployed] │ │
│  │ L5_T02  │ Monitor     │ CT1_LAB5_MR02  │ ZZNNH4ZM501690H │ [Deployed] │ │
│  │ L5_T02  │ Mouse       │ CT1_LAB5_M02   │ 96C0DJL         │ [Deployed] │ │
│  │ L5_T02  │ Keyboard    │ CT1_LAB5_K02   │ 95NA3MF         │ [Deployed] │ │
│  │ ...     │ ...         │ ...            │ ...             │ ...        │ │
│  │ L5_T24  │ AVR         │ CT1_LAB5_AVR24 │ UNKNOWN         │ [Deployed] │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ← Scroll horizontally →                                                    │
│  ↑ Scroll vertically ↓                                                      │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 🎨 Status Color Coding

```
┌─────────────────────────────────────────────────────────┐
│ Status          │ Color        │ Visual                 │
├─────────────────┼──────────────┼────────────────────────┤
│ Deployed        │ Light Green  │ [  Deployed  ]         │
│ Under Maint.    │ Light Orange │ [Under Maintenance]    │
│ Borrowed        │ Light Blue   │ [  Borrowed  ]         │
│ Storage         │ Light Gray   │ [  Storage   ]         │
│ Retired         │ Light Red    │ [  Retired   ]         │
└─────────────────────────────────────────────────────────┘
```

## 🔄 View Switching Flow

```
┌─────────────┐
│  Map View   │
│             │
│  [📊] ←───────── Click to switch
│             │
└─────────────┘
       ↓
       ↓ Loads data from SharedPreferences
       ↓ Flattens structure
       ↓
┌─────────────┐
│ Spreadsheet │
│    View     │
│             │
│  [🗺️] ←───────── Click to switch back
│             │
└─────────────┘
```

## 📊 Data Flattening Example

### Before (Nested Structure)
```json
{
  "L5_T01": [
    {"category": "Monitor", "dnts_serial": "CT1_LAB5_MR01", ...},
    {"category": "Mouse", "dnts_serial": "CT1_LAB5_M01", ...},
    {"category": "Keyboard", "dnts_serial": "CT1_LAB5_K01", ...},
    {"category": "System Unit", "dnts_serial": "CT1_LAB5_SU01", ...},
    {"category": "SSD", "dnts_serial": "CT1_LAB5_SSD01", ...},
    {"category": "AVR", "dnts_serial": "CT1_LAB5_AVR01", ...}
  ]
}
```

### After (Flattened for Spreadsheet)
```
Row 1: L5_T01 | Monitor      | CT1_LAB5_MR01  | ... | Deployed
Row 2: L5_T01 | Mouse        | CT1_LAB5_M01   | ... | Deployed
Row 3: L5_T01 | Keyboard     | CT1_LAB5_K01   | ... | Deployed
Row 4: L5_T01 | System Unit  | CT1_LAB5_SU01  | ... | Deployed
Row 5: L5_T01 | SSD          | CT1_LAB5_SSD01 | ... | Deployed
Row 6: L5_T01 | AVR          | CT1_LAB5_AVR01 | ... | Deployed
```

## 🎯 Empty State

```
┌──────────────────────────────────────────────────────────┐
│  [🗺️] Lab 5 Spreadsheet              [🔄] [☁️] [📋]     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│                                                          │
│                        📊                                │
│                                                          │
│                  No data available                       │
│                                                          │
│         Click the seed button (☁️) to                    │
│              load Lab 5 data                             │
│                                                          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## 🖱️ User Interaction

### Click Toggle Button
```
User clicks [📊]
       ↓
State changes: _isSpreadsheetMode = true
       ↓
Title updates: "Lab 5 Spreadsheet"
       ↓
_loadSpreadsheetData() runs
       ↓
Fetches from SharedPreferences
       ↓
Flattens data structure
       ↓
Displays DataTable
```

### Click Refresh in Spreadsheet Mode
```
User clicks [🔄]
       ↓
_loadSpreadsheetData() runs
       ↓
Re-fetches from SharedPreferences
       ↓
Updates _spreadsheetData
       ↓
Table refreshes
```

## 📱 Responsive Behavior

### Desktop (Wide Screen)
```
┌────────────────────────────────────────────────────────────────┐
│  All columns visible                                           │
│  No horizontal scroll needed                                   │
│  Vertical scroll for rows                                      │
└────────────────────────────────────────────────────────────────┘
```

### Tablet (Medium Screen)
```
┌──────────────────────────────────────────┐
│  Most columns visible                    │
│  Slight horizontal scroll                │
│  Vertical scroll for rows                │
└──────────────────────────────────────────┘
```

### Mobile (Narrow Screen)
```
┌────────────────────────┐
│  Few columns visible   │
│  Horizontal scroll     │
│  Vertical scroll       │
└────────────────────────┘
```

## 🎨 Visual Comparison

### Map View
```
┌─────────────────────────────────────────┐
│  Visual grid of desks                   │
│  Click desk → Modal with 6 components   │
│  Spatial representation                 │
│  Good for: Location-based tasks         │
└─────────────────────────────────────────┘
```

### Spreadsheet View
```
┌─────────────────────────────────────────┐
│  Tabular list of all components         │
│  All data visible at once               │
│  Linear representation                  │
│  Good for: Inventory audits, reporting  │
└─────────────────────────────────────────┘
```

## 🔍 Data Organization

### Grouped by Desk
```
L5_T01 → 6 components
L5_T02 → 6 components
L5_T03 → 6 components
...
L5_T24 → 6 components

Total: 144 rows
```

### Component Order (per desk)
```
1. Monitor
2. Mouse
3. Keyboard
4. System Unit
5. SSD
6. AVR
```

## ✅ Quick Reference

| Action | Button | Result |
|--------|--------|--------|
| Switch to Spreadsheet | 📊 | Shows table view |
| Switch to Map | 🗺️ | Shows visual map |
| Refresh Spreadsheet | 🔄 | Reloads data |
| Seed Data | ☁️ | Populates storage |
| List Data | 📋 | Prints to terminal |

## 🎯 Workflow Example

```
1. User opens Map screen
   ↓
2. Clicks [📊] toggle button
   ↓
3. View switches to Spreadsheet
   ↓
4. Data loads from local storage
   ↓
5. Table displays 144 rows
   ↓
6. User scrolls to review data
   ↓
7. User clicks [🗺️] to return to Map
   ↓
8. View switches back to Map
```

---

**Visual guide complete!** Use the toggle button to switch between Map and Spreadsheet views. 🎉
