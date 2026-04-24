# Testing Map UI ↔ Local Storage Integration

## Overview
The Map UI is now wired to persistent local storage (SharedPreferences). This ensures workstation-to-asset mappings survive app restarts.

## How It Works

### 1. Data Storage
- **Technology**: SharedPreferences (permanent local storage)
- **Key Format**: `workstation_{workstation_id}` (e.g., `workstation_L5_T01`)
- **Value Format**: JSON string containing asset data
- **Example**:
  ```json
  {
    "dnts_serial": "CT1_LAB5_MR01",
    "category": "Monitor",
    "status": "Deployed",
    "current_workstation_id": "L5_T01"
  }
  ```

### 2. Seed Script
- **File**: `lib/seed_lab5_data.dart`
- **Function**: `seedLab5Data()`
- **What it does**:
  - Creates sample workstation assignments for Lab 5
  - Commits data to SharedPreferences (permanent storage)
  - Prints detailed logs to terminal

### 3. Map UI Query
- **File**: `lib/screens/interactive_map_screen.dart`
- **Function**: `_showWorkstationDetails(String deskLabel)`
- **What it does**:
  - Prints clicked desk ID to terminal
  - Queries local storage for `workstation_{deskLabel}`
  - Displays asset data in modal
  - Shows "LOCAL" badge if data came from local storage

## Testing Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Run the App
```bash
flutter run -d chrome
```

### Step 3: Navigate to Map
1. Log in (or skip auth if in dev mode)
2. Navigate to the Interactive Map screen

### Step 4: Seed Data
1. Click the **cloud upload icon** (☁️) in the top-right toolbar
2. Check terminal output - you should see:
   ```
   🌱 Starting Lab 5 data seeding...
     ✓ Saved: L5_T01 -> CT1_LAB5_MR01
     ✓ Saved: L5_T02 -> CT1_LAB5_M02
     ...
   ✅ Lab 5 seeding complete! 8 workstations assigned.
   📦 Data committed to SharedPreferences (permanent local storage)
   ```

### Step 5: List Stored Data
1. Click the **list icon** (📋) in the top-right toolbar
2. Check terminal output - you should see all stored workstations

### Step 6: Click Desks
1. Navigate to Lab 5 on the map
2. Click any desk (e.g., `L5_T01`, `L5_T02`, etc.)
3. **Check terminal output**:
   ```
   🖱️ Desk clicked: L5_T01
   🔍 Querying local storage for workstation: L5_T01
   ✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
   ```
4. **Check modal**:
   - Should show asset details
   - Should have a green "LOCAL" badge (indicating data from local storage)

### Step 7: Test Empty Workstation
1. Click a desk that wasn't seeded (e.g., `L5_T40`)
2. **Check terminal output**:
   ```
   🖱️ Desk clicked: L5_T40
   🔍 Querying local storage for workstation: L5_T40
   ❌ No asset found in local storage for: L5_T40
   ```
3. **Check modal**:
   - Should show "Empty Workstation"

## Verification Checklist

- [ ] Seed script runs without errors
- [ ] Terminal shows "Data committed to SharedPreferences"
- [ ] Clicking a seeded desk prints the correct workstation ID
- [ ] Terminal confirms local storage query
- [ ] Modal shows asset data with "LOCAL" badge
- [ ] Clicking an empty desk shows "Empty Workstation"
- [ ] Data persists after app restart (close and reopen app, click desk again)

## Toolbar Icons

| Icon | Function | Description |
|------|----------|-------------|
| 🔍 Zoom Out | Zoom out map | Decreases map scale |
| 🔍 Zoom In | Zoom in map | Increases map scale |
| 🔄 Refresh | Reload Supabase data | Fetches assets from database |
| ☁️ Seed | Run seed script | Populates local storage with Lab 5 data |
| 📋 List | List stored data | Prints all workstation data to terminal |

## Troubleshooting

### No data showing after seed
- Check terminal for errors
- Verify SharedPreferences is working (web platform supported)
- Try clicking the List icon to see what's stored

### Terminal not showing print statements
- Ensure you're running in debug mode
- Check your IDE's debug console
- For web: Open browser DevTools console

### Data not persisting
- SharedPreferences works on all platforms including web
- For web, data is stored in browser's localStorage
- Clearing browser cache will clear the data

## Next Steps

Once verified:
1. Expand seed script to include all labs (Lab 1-7)
2. Add more workstation assignments
3. Integrate with Supabase for real-time sync
4. Add UI to manually assign assets to workstations
