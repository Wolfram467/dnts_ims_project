# Seed Setup - Quick Reference

## 🎯 What You Need to Do

1. **Paste your JSON data** into `lib/seed_lab5_data.dart`
2. **Run the app** and click the ☁️ button
3. **Click desks** to verify data is loaded

## 📝 Step-by-Step

### 1. Open the Seed File
```
lib/seed_lab5_data.dart
```

### 2. Find This Section (around line 13)
```dart
const Map<String, Map<String, dynamic>> workstationData = {
  // TODO: Paste your workstation data here
};
```

### 3. Paste Your Data
Replace the comment with your workstation data:

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
  // ... rest of your data
};
```

### 4. Save the File

### 5. Run the App
```bash
flutter pub get
flutter run -d chrome
```

### 6. Test It
1. Navigate to Interactive Map
2. Click ☁️ (cloud upload) button
3. Check terminal for: `✅ Lab 5 seeding complete! X workstations assigned.`
4. Click any Lab 5 desk (L5_T01, L5_T02, etc.)
5. Verify terminal shows:
   ```
   🖱️ Desk clicked: L5_T01
   🔍 Querying local storage for workstation: L5_T01
   ✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
   ```

## ✅ Success Indicators

- [ ] No warning about empty data map
- [ ] Terminal shows "X workstations assigned"
- [ ] Clicking desk prints workstation ID
- [ ] Modal shows asset data with "LOCAL" badge
- [ ] Data persists after app restart

## 📋 Data Format Requirements

### Workstation ID (Key)
- Format: `L5_T01`, `L5_T02`, ... `L5_T48`
- Must match desk labels on map
- Zero-padded numbers (01, not 1)

### Asset Data (Value)
Required fields:
- `dnts_serial`: String (e.g., "CT1_LAB5_MR01")
- `category`: String (e.g., "Monitor", "Mouse", "Keyboard")
- `status`: String (e.g., "Deployed", "Under Maintenance")
- `current_workstation_id`: String (should match the key)

### Valid Categories
- Monitor
- Mouse
- Keyboard
- System Unit
- AVR
- SSD

### Valid Statuses
- Deployed
- Borrowed
- Under Maintenance
- Storage
- Retired

## 🔧 How It Works

```
Your Data (in seed file)
        ↓
Click ☁️ button
        ↓
seedLab5Data() runs
        ↓
Data saved to SharedPreferences
        ↓
Click desk on map
        ↓
getWorkstationAsset() queries storage
        ↓
Modal displays asset data
```

## 📁 File Structure

```
lib/
├── seed_lab5_data.dart          ← PASTE YOUR DATA HERE
└── screens/
    └── interactive_map_screen.dart  ← Reads from storage
```

## 🐛 Troubleshooting

### "workstationData Map is empty!"
→ You haven't pasted data yet. Open `lib/seed_lab5_data.dart` and paste your data.

### Syntax error after pasting
→ Use single quotes `'` not double quotes `"`
→ Add trailing commas after each `}`

### Desk shows "Empty Workstation"
→ Check workstation ID matches exactly (L5_T01, not L5_T1)
→ Click 📋 button to list all stored data

### Data doesn't persist
→ Make sure you clicked ☁️ to seed the data
→ Check terminal for "Data committed to SharedPreferences"

## 📚 Additional Resources

- `HOW_TO_ADD_DATA.md` - Detailed instructions
- `EXAMPLE_DATA_FORMAT.dart` - Copy-paste template
- `QUICK_TEST_GUIDE.md` - Testing steps
- `VERIFICATION_CHECKLIST.md` - Complete checklist

## 🚀 Quick Test Command

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Then in app:
# 1. Go to Map
# 2. Click ☁️
# 3. Click L5_T01
# 4. Check terminal
```

## 💡 Pro Tip

If you want to test with placeholder data first, use this in the seed file:

```dart
const Map<String, Map<String, dynamic>> workstationData = {
  for (int i = 1; i <= 48; i++)
    'L5_T${i.toString().padLeft(2, '0')}': {
      'dnts_serial': 'CT1_LAB5_TEST${i.toString().padLeft(2, '0')}',
      'category': 'Monitor',
      'status': 'Deployed',
      'current_workstation_id': 'L5_T${i.toString().padLeft(2, '0')}',
    },
};
```

This generates all 48 workstations automatically for testing.
