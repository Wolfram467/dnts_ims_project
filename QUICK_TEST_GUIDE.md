# Quick Test Guide - Map Storage Wiring

## 🚀 Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run app
flutter run -d chrome
```

## 🎯 Test in 3 Steps

### Step 1: Seed Data
- Click **☁️ (cloud upload icon)** in map toolbar
- Watch terminal for: `✅ Lab 5 seeding complete!`

### Step 2: Verify Storage
- Click **📋 (list icon)** in map toolbar
- Terminal shows all 8 stored workstations

### Step 3: Click Desks
- Click desk `L5_T01` on the map
- **Terminal should show**:
  ```
  🖱️ Desk clicked: L5_T01
  🔍 Querying local storage for workstation: L5_T01
  ✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
  ```
- **Modal should show**:
  - Serial: CT1_LAB5_MR01
  - Category: Monitor
  - Status: Deployed
  - Green "LOCAL" badge

## ✅ Success Criteria

- [ ] Terminal prints desk ID when clicked
- [ ] Terminal shows "Querying local storage" message
- [ ] Terminal confirms found/not found
- [ ] Modal displays asset data
- [ ] "LOCAL" badge appears
- [ ] Data persists after app restart

## 🐛 If Something's Wrong

**No terminal output?**
- Check debug console in your IDE
- For web: Open browser DevTools console

**No data showing?**
- Click ☁️ to seed first
- Click 📋 to verify storage
- Check for errors in terminal

**Data not persisting?**
- SharedPreferences works on all platforms
- For web: stored in browser localStorage
- Clearing cache will clear data

## 📍 Where to Look

| What | Where |
|------|-------|
| Seed script | `lib/seed_lab5_data.dart` |
| Map UI | `lib/screens/interactive_map_screen.dart` |
| Dependencies | `pubspec.yaml` |
| Full guide | `TESTING_MAP_STORAGE.md` |
| Summary | `IMPLEMENTATION_SUMMARY.md` |
