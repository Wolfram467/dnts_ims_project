# Verification Checklist

## 📋 Pre-Flight Check

Before testing, ensure:

- [ ] `pubspec.yaml` includes `shared_preferences: ^2.2.2`
- [ ] `lib/seed_lab5_data.dart` exists
- [ ] `lib/screens/interactive_map_screen.dart` imports seed script
- [ ] Flutter dependencies installed (`flutter pub get`)

## 🧪 Test Sequence

### Test 1: Seed Script Execution
- [ ] Run app and navigate to Interactive Map
- [ ] Click ☁️ (cloud upload) button in toolbar
- [ ] **Terminal shows**:
  - [ ] `🚀 SEED SCRIPT TRIGGERED FROM UI`
  - [ ] `🌱 Starting Lab 5 data seeding...`
  - [ ] `✓ Saved: L5_T01 -> CT1_LAB5_MR01` (8 times)
  - [ ] `✅ Lab 5 seeding complete! 8 workstations assigned.`
  - [ ] `📦 Data committed to SharedPreferences`
- [ ] **UI shows**: Green snackbar "✅ Lab 5 data seeded successfully!"

### Test 2: List Stored Data
- [ ] Click 📋 (list) button in toolbar
- [ ] **Terminal shows**:
  - [ ] `📋 LISTING ALL WORKSTATION DATA IN LOCAL STORAGE`
  - [ ] List of 8 workstations with details
  - [ ] Seed timestamp and count
- [ ] **UI shows**: Snackbar "📋 Check terminal for stored data listing"

### Test 3: Click Seeded Desk (L5_T01)
- [ ] Navigate to Lab 5 on map
- [ ] Click desk labeled `L5_T01`
- [ ] **Terminal shows**:
  - [ ] `🖱️ Desk clicked: L5_T01`
  - [ ] `🔍 Querying local storage for workstation: L5_T01`
  - [ ] `✅ Found in local storage: CT1_LAB5_MR01 (Monitor)`
- [ ] **Modal shows**:
  - [ ] Title: `L5_T01`
  - [ ] Green "LOCAL" badge in top-right
  - [ ] Serial: `CT1_LAB5_MR01`
  - [ ] Category: `Monitor`
  - [ ] Status: `Deployed`
  - [ ] Source: `Local Storage`

### Test 4: Click Another Seeded Desk (L5_T02)
- [ ] Click desk labeled `L5_T02`
- [ ] **Terminal shows**:
  - [ ] `🖱️ Desk clicked: L5_T02`
  - [ ] `🔍 Querying local storage for workstation: L5_T02`
  - [ ] `✅ Found in local storage: CT1_LAB5_M02 (Mouse)`
- [ ] **Modal shows**:
  - [ ] Serial: `CT1_LAB5_M02`
  - [ ] Category: `Mouse`
  - [ ] "LOCAL" badge present

### Test 5: Click Empty Desk (L5_T40)
- [ ] Click desk labeled `L5_T40` (not seeded)
- [ ] **Terminal shows**:
  - [ ] `🖱️ Desk clicked: L5_T40`
  - [ ] `🔍 Querying local storage for workstation: L5_T40`
  - [ ] `❌ No asset found in local storage for: L5_T40`
- [ ] **Modal shows**:
  - [ ] Title: `L5_T40`
  - [ ] Text: `Empty Workstation`
  - [ ] No "LOCAL" badge

### Test 6: Data Persistence
- [ ] Close the app completely
- [ ] Reopen the app
- [ ] Navigate to Interactive Map
- [ ] Click `L5_T01` again
- [ ] **Terminal shows**: Same output as Test 3 (data persisted)
- [ ] **Modal shows**: Same data as Test 3

### Test 7: All Seeded Desks
Test each seeded desk and verify terminal output:

| Desk | Expected Serial | Expected Category | Expected Status |
|------|----------------|-------------------|-----------------|
| L5_T01 | CT1_LAB5_MR01 | Monitor | Deployed |
| L5_T02 | CT1_LAB5_M02 | Mouse | Deployed |
| L5_T03 | CT1_LAB5_K03 | Keyboard | Deployed |
| L5_T10 | CT1_LAB5_SU10 | System Unit | Deployed |
| L5_T15 | CT1_LAB5_AVR15 | AVR | Deployed |
| L5_T20 | CT1_LAB5_SSD20 | SSD | Deployed |
| L5_T25 | CT1_LAB5_MR25 | Monitor | Under Maintenance |
| L5_T30 | CT1_LAB5_M30 | Mouse | Deployed |

- [ ] L5_T01 ✅
- [ ] L5_T02 ✅
- [ ] L5_T03 ✅
- [ ] L5_T10 ✅
- [ ] L5_T15 ✅
- [ ] L5_T20 ✅
- [ ] L5_T25 ✅
- [ ] L5_T30 ✅

## 🎯 Success Criteria

All tests must pass:
- [x] Seed script commits to permanent storage
- [x] Terminal prints desk ID when clicked
- [x] Terminal prints query message
- [x] Terminal prints found/not found result
- [x] Modal displays correct asset data
- [x] "LOCAL" badge appears for stored data
- [x] Empty desks show "Empty Workstation"
- [x] Data persists after app restart

## 🐛 Troubleshooting

### Issue: No terminal output
**Solution**: 
- Check IDE debug console
- For web: Open browser DevTools (F12) → Console tab
- Ensure running in debug mode

### Issue: Seed button does nothing
**Solution**:
- Check for errors in terminal
- Verify `shared_preferences` is installed
- Try `flutter clean` then `flutter pub get`

### Issue: Modal shows "Empty Workstation" for seeded desk
**Solution**:
- Click 📋 to verify data is stored
- Check terminal for seed errors
- Try seeding again

### Issue: No "LOCAL" badge
**Solution**:
- Verify data is in local storage (click 📋)
- Check terminal output when clicking desk
- Ensure `getWorkstationAsset()` is being called

### Issue: Data doesn't persist
**Solution**:
- SharedPreferences works on all platforms
- For web: Check browser localStorage (DevTools → Application → Local Storage)
- Clearing browser cache will clear data
- Try a different browser

## 📊 Expected Terminal Output Summary

### Complete Flow
```
═══════════════════════════════════════
🚀 SEED SCRIPT TRIGGERED FROM UI
═══════════════════════════════════════

🌱 Starting Lab 5 data seeding...
  ✓ Saved: L5_T01 -> CT1_LAB5_MR01
  ✓ Saved: L5_T02 -> CT1_LAB5_M02
  ✓ Saved: L5_T03 -> CT1_LAB5_K03
  ✓ Saved: L5_T10 -> CT1_LAB5_SU10
  ✓ Saved: L5_T15 -> CT1_LAB5_AVR15
  ✓ Saved: L5_T20 -> CT1_LAB5_SSD20
  ✓ Saved: L5_T25 -> CT1_LAB5_MR25
  ✓ Saved: L5_T30 -> CT1_LAB5_M30
✅ Lab 5 seeding complete! 8 workstations assigned.
📦 Data committed to SharedPreferences (permanent local storage)

═══════════════════════════════════════
📋 LIST STORED DATA TRIGGERED FROM UI
═══════════════════════════════════════

📋 LISTING ALL WORKSTATION DATA IN LOCAL STORAGE
═══════════════════════════════════════════════════
Found 8 workstations:

  L5_T01 → CT1_LAB5_MR01 (Monitor, Deployed)
  L5_T02 → CT1_LAB5_M02 (Mouse, Deployed)
  L5_T03 → CT1_LAB5_K03 (Keyboard, Deployed)
  L5_T10 → CT1_LAB5_SU10 (System Unit, Deployed)
  L5_T15 → CT1_LAB5_AVR15 (AVR, Deployed)
  L5_T20 → CT1_LAB5_SSD20 (SSD, Deployed)
  L5_T25 → CT1_LAB5_MR25 (Monitor, Under Maintenance)
  L5_T30 → CT1_LAB5_M30 (Mouse, Deployed)

📅 Last seeded: 2024-04-24T10:30:00.000Z
📊 Seed count: 8
═══════════════════════════════════════════════════

🖱️ Desk clicked: L5_T01
🔍 Querying local storage for workstation: L5_T01
✅ Found in local storage: CT1_LAB5_MR01 (Monitor)

🖱️ Desk clicked: L5_T40
🔍 Querying local storage for workstation: L5_T40
❌ No asset found in local storage for: L5_T40
```

## ✅ Sign-Off

Once all tests pass, the Map UI is successfully wired to permanent local storage!

**Tested by**: _______________
**Date**: _______________
**Platform**: _______________
**Result**: ⬜ PASS  ⬜ FAIL

**Notes**:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
