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

