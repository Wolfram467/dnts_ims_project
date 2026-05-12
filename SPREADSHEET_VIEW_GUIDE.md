# Spreadsheet View Guide

## 🎯 New Feature: Toggleable Spreadsheet View

The Interactive Map now has a **Spreadsheet View** that displays all Lab 5 components in a tabular format.

## 🔄 How to Toggle Views

### Toggle Button Location
**Top-left corner** of the header, next to the title.

### Button Icons
- **📊 Table Chart Icon**: Click to switch to Spreadsheet View
- **🗺️ Map Icon**: Click to switch back to Map View

### Visual Indicator
- When in Spreadsheet mode, the toggle button has a **black background**
- Title changes from "CT1 Floor Plan" to "Lab 5 Spreadsheet"

## 📊 Spreadsheet View Features

### Data Source
- Fetches all data from **SharedPreferences** (local storage)
- Automatically flattens the data structure
- Each hardware component becomes a separate row

### Columns
1. **Desk ID** - Workstation identifier (e.g., L5_T01, L5_T02)
2. **Category** - Component type (Monitor, Mouse, Keyboard, etc.)
3. **DNTS Serial** - DNTS inventory serial number
4. **Mfg Serial** - Manufacturer serial number
5. **Status** - Component status with color coding

### Status Color Coding
- 🟢 **Green**: Deployed
- 🟠 **Orange**: Under Maintenance
- 🔵 **Blue**: Borrowed
- ⚪ **Gray**: Storage
- 🔴 **Red**: Retired

### Scrolling
- **Vertical scroll**: Navigate through all rows
- **Horizontal scroll**: View all columns if screen is narrow
- Fully responsive to different screen sizes

## 🎨 UI Layout

### Spreadsheet Mode Header
```
┌────────────────────────────────────────────────────────────┐
│ [🗺️] Lab 5 Spreadsheet        [🔄] [☁️] [📋]             │
└────────────────────────────────────────────────────────────┘
```

### Map Mode Header
```
┌────────────────────────────────────────────────────────────┐
│ [📊] CT1 Floor Plan            [🔍-] [🔍+] [🔄] [☁️] [📋] │
└────────────────────────────────────────────────────────────┘
```

### Spreadsheet Table
```
┌──────────┬──────────────┬─────────────────┬──────────────────┬──────────────┐
│ Desk ID  │ Category     │ DNTS Serial     │ Mfg Serial       │ Status       │
├──────────┼──────────────┼─────────────────┼──────────────────┼──────────────┤
│ L5_T01   │ Monitor      │ CT1_LAB5_MR01   │ ZZNNH4ZM301248N  │ [Deployed]   │
│ L5_T01   │ Mouse        │ CT1_LAB5_M01    │ 97205H5          │ [Deployed]   │
│ L5_T01   │ Keyboard     │ CT1_LAB5_K01    │ 95NAA63          │ [Deployed]   │
│ L5_T01   │ System Unit  │ CT1_LAB5_SU01   │ 2022A0853        │ [Deployed]   │
│ L5_T01   │ SSD          │ CT1_LAB5_SSD01  │ 0026-B768-...    │ [Deployed]   │
│ L5_T01   │ AVR          │ CT1_LAB5_AVR01  │ YY2023030106970  │ [Deployed]   │
│ L5_T02   │ Monitor      │ CT1_LAB5_MR02   │ ZZNNH4ZM501690H  │ [Deployed]   │
│ ...      │ ...          │ ...             │ ...              │ ...          │
└──────────┴──────────────┴─────────────────┴──────────────────┴──────────────┘
```

## 🚀 Usage Workflow

### Step 1: Seed Data (If Not Already Done)
1. Click **☁️ (cloud upload)** button
2. Wait for confirmation: "✅ Lab 5 data seeded successfully!"

### Step 2: Switch to Spreadsheet View
1. Click **📊 (table chart)** button in top-left
2. Data automatically loads from local storage
3. Spreadsheet displays all components

### Step 3: View Data
- Scroll vertically to see all components
- Scroll horizontally if needed
- Each desk's 6 components are listed sequentially

### Step 4: Refresh Data
- Click **🔄 (refresh)** button to reload spreadsheet data
- Useful after seeding new data

### Step 5: Switch Back to Map
- Click **🗺️ (map)** button in top-left
- Returns to visual map view

## 📊 Data Structure

### Example: L5_T01 (6 Components)
```
Row 1: L5_T01 | Monitor      | CT1_LAB5_MR01  | ZZNNH4ZM301248N  | Deployed
Row 2: L5_T01 | Mouse        | CT1_LAB5_M01   | 97205H5          | Deployed
Row 3: L5_T01 | Keyboard     | CT1_LAB5_K01   | 95NAA63          | Deployed
Row 4: L5_T01 | System Unit  | CT1_LAB5_SU01  | 2022A0853        | Deployed
Row 5: L5_T01 | SSD          | CT1_LAB5_SSD01 | 0026-B768-656D-7825 | Deployed
Row 6: L5_T01 | AVR          | CT1_LAB5_AVR01 | YY2023030106970  | Deployed
```

### Total Rows
- **24 workstations** × **6 components** = **144 rows**

## 🎯 Use Cases

### Inventory Audit
- Quickly scan all components in Lab 5
- Verify serial numbers
- Check component status

### Reporting
- Export-ready format (future feature)
- Easy to read and review
- Organized by desk

### Comparison
- Compare components across desks
- Identify patterns
- Spot missing or duplicate serials

### Search & Filter (Future)
- Find specific serial numbers
- Filter by category
- Sort by desk ID

## 🔧 Technical Details

### Data Loading
```dart
// Triggered when switching to spreadsheet mode
_loadSpreadsheetData()
  ↓
Fetch from SharedPreferences
  ↓
Decode JSON for each workstation
  ↓
Flatten: each component → separate row
  ↓
Display in DataTable
```

### Flattening Logic
```dart
For each workstation (L5_T01, L5_T02, ...):
  For each component (6 per desk):
    Create row: {
      desk_id: 'L5_T01',
      category: 'Monitor',
      dnts_serial: 'CT1_LAB5_MR01',
      mfg_serial: 'ZZNNH4ZM301248N',
      status: 'Deployed'
    }
```

### Empty State
If no data is seeded:
```
┌────────────────────────────────────┐
│         📊                         │
│    No data available               │
│                                    │
│ Click the seed button (☁️) to     │
│ load Lab 5 data                    │
└────────────────────────────────────┘
```

## 🎨 Design Features

### Minimalist Aesthetic
- Black borders (1px)
- Clean typography
- Consistent spacing
- No rounded corners (matches design system)

### Responsive
- Adapts to screen size
- Scrollable in both directions
- Touch-friendly on mobile

### Accessibility
- Clear column headers
- High contrast text
- Color-coded status for quick scanning

## 🐛 Troubleshooting

### Issue: Spreadsheet is empty
**Solution**: 
1. Switch back to Map view
2. Click ☁️ to seed data
3. Switch back to Spreadsheet view

### Issue: Data not updating
**Solution**: Click 🔄 (refresh) button in Spreadsheet mode

### Issue: Can't see all columns
**Solution**: Scroll horizontally (table is wider than screen)

### Issue: Toggle button not working
**Solution**: Ensure data is seeded first

## 📱 Keyboard Shortcuts (Future)

- `M` - Switch to Map view
- `S` - Switch to Spreadsheet view
- `R` - Refresh current view
- `Ctrl+F` - Search in spreadsheet

## 🚀 Future Enhancements

- [ ] Export to CSV/Excel
- [ ] Search functionality
- [ ] Column sorting
- [ ] Filtering by category/status
- [ ] Inline editing
- [ ] Print view
- [ ] Copy to clipboard
- [ ] Highlight duplicates

## ✅ Testing Checklist

- [ ] Toggle button switches views
- [ ] Spreadsheet loads data from local storage
- [ ] All 144 rows displayed (24 desks × 6 components)
- [ ] Columns show correct data
- [ ] Status colors display correctly
- [ ] Scrolling works (vertical & horizontal)
- [ ] Refresh button reloads data
- [ ] Empty state shows when no data
- [ ] Map view still works after toggling
- [ ] Seed button works in both modes

---

**The Spreadsheet View is now live!** Toggle between Map and Spreadsheet to view Lab 5 data in different formats. 🎉
