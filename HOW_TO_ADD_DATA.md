# How to Add Your Workstation Data

## Quick Start

1. Open `lib/seed_lab5_data.dart`
2. Find the `workstationData` Map (around line 10)
3. Paste your JSON payload between the curly braces
4. Save the file
5. Run the app and click the ☁️ button to seed

## Data Format

### Expected Structure

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
  // ... more workstations
};
```

### Key Format
- **Workstation ID**: `L5_T01`, `L5_T02`, etc.
- Must match the desk labels on the map

### Value Format (Asset Data)
Each workstation maps to an object with:
- `dnts_serial` (String): Asset serial number (e.g., "CT1_LAB5_MR01")
- `category` (String): Asset category (e.g., "Monitor", "Mouse", "Keyboard")
- `status` (String): Asset status (e.g., "Deployed", "Under Maintenance")
- `current_workstation_id` (String): Should match the key (e.g., "L5_T01")

## Step-by-Step Instructions

### Step 1: Prepare Your JSON Data

If you have JSON data like this:
```json
{
  "L5_T01": {
    "dnts_serial": "CT1_LAB5_MR01",
    "category": "Monitor",
    "status": "Deployed",
    "current_workstation_id": "L5_T01"
  },
  "L5_T02": {
    "dnts_serial": "CT1_LAB5_M02",
    "category": "Mouse",
    "status": "Deployed",
    "current_workstation_id": "L5_T02"
  }
}
```

### Step 2: Convert to Dart Format

Change:
- `"key":` → `'key':`
- Add trailing commas after each closing brace
- Ensure proper indentation

Result:
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
};
```

### Step 3: Paste into File

1. Open `lib/seed_lab5_data.dart`
2. Find this section:
   ```dart
   const Map<String, Map<String, dynamic>> workstationData = {
     // TODO: Paste your workstation data here
   };
   ```
3. Replace the comment with your data:
   ```dart
   const Map<String, Map<String, dynamic>> workstationData = {
     'L5_T01': {
       'dnts_serial': 'CT1_LAB5_MR01',
       'category': 'Monitor',
       'status': 'Deployed',
       'current_workstation_id': 'L5_T01',
     },
     // ... rest of your data
   };
   ```

### Step 4: Save and Test

1. Save the file
2. Run the app: `flutter run -d chrome`
3. Navigate to the Interactive Map
4. Click the ☁️ (cloud upload) button
5. Check terminal for confirmation
6. Click any desk to verify data

## Example: Complete Lab 5 Data

Lab 5 has 48 workstations (L5_T01 through L5_T48). Here's a template:

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
  // ... continue for all 48 workstations
  'L5_T48': {
    'dnts_serial': 'CT1_LAB5_MR48',
    'category': 'Monitor',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T48',
  },
};
```

## Lab 5 Workstation Layout

Lab 5 has 4 blocks with 2 rows and 12 columns each:
- **Block 1**: L5_T01 to L5_T12 (Row 1), L5_T13 to L5_T24 (Row 2)
- **Block 2**: L5_T25 to L5_T36 (Row 1), L5_T37 to L5_T48 (Row 2)

Wait, let me check the actual layout from the map screen...

Actually, looking at the map code, Lab 5 has:
- Block 1: 2 rows × 12 columns = 24 desks (L5_T01 to L5_T24)
- Block 2: 2 rows × 12 columns = 24 desks (L5_T25 to L5_T48)
- **Total: 48 workstations**

## Validation

After pasting your data, the seed script will:
1. Check if `workstationData` is empty
2. If empty, show warning and abort
3. If not empty, save each workstation to SharedPreferences
4. Print confirmation for each saved workstation

### Expected Terminal Output

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

## Troubleshooting

### Issue: "workstationData Map is empty!"

**Cause**: You haven't pasted data yet, or the Map is still empty.

**Solution**: 
1. Open `lib/seed_lab5_data.dart`
2. Find the `workstationData` Map
3. Paste your data between the curly braces
4. Save the file

### Issue: Syntax error after pasting

**Cause**: JSON format doesn't match Dart format.

**Solution**:
- Use single quotes `'` instead of double quotes `"`
- Add trailing commas after each closing brace
- Ensure all keys and values are properly quoted
- Check for missing commas

### Issue: Some desks show data, others don't

**Cause**: Workstation IDs in your data don't match desk labels on map.

**Solution**:
- Ensure keys match exactly: `L5_T01`, `L5_T02`, etc.
- Check for typos (e.g., `L5_T1` vs `L5_T01`)
- Desk numbers should be zero-padded (01, 02, not 1, 2)

### Issue: Data doesn't persist after app restart

**Cause**: Data wasn't seeded, or SharedPreferences failed.

**Solution**:
- Click ☁️ button to seed data
- Check terminal for "Data committed to SharedPreferences"
- For web: Check browser localStorage (DevTools → Application)

## Quick Conversion Tool

If you have pure JSON, you can use this regex find/replace:

**Find**: `"([^"]+)":`
**Replace**: `'$1':`

This converts all double quotes around keys to single quotes.

## Alternative: Generate Data Programmatically

If you want to generate data instead of pasting:

```dart
const Map<String, Map<String, dynamic>> workstationData = {
  for (int i = 1; i <= 48; i++)
    'L5_T${i.toString().padLeft(2, '0')}': {
      'dnts_serial': 'CT1_LAB5_MR${i.toString().padLeft(2, '0')}',
      'category': 'Monitor',
      'status': 'Deployed',
      'current_workstation_id': 'L5_T${i.toString().padLeft(2, '0')}',
    },
};
```

This generates all 48 workstations automatically.

## Next Steps

Once your data is pasted and seeded:
1. Click any desk on the map
2. Verify terminal shows the correct workstation ID
3. Verify modal displays the correct asset data
4. Check that "LOCAL" badge appears
5. Restart app and verify data persists

## Need Help?

Check these files:
- `QUICK_TEST_GUIDE.md` - Quick testing steps
- `TESTING_MAP_STORAGE.md` - Detailed testing guide
- `VERIFICATION_CHECKLIST.md` - Complete test checklist
