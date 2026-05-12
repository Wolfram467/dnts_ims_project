# Edit Feature - Visual Guide

## 🎯 How to Edit Component Serials

### Step 1: Click a Desk
```
Click any Lab 5 desk (e.g., L5_T01)
```

### Step 2: Find the Edit Button
```
┌─────────────────────────────────────────────────────────┐
│  L5_T01                                       [LOCAL]   │
├─────────────────────────────────────────────────────────┤
│  [6 Components]                                         │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor                                  [✏️]  │ │ ← Edit button
│  │ DNTS Serial: CT1_LAB5_MR01                        │ │
│  │ Mfg Serial:  ZZNNH4ZM301248N                      │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 2. Mouse                                    [✏️]  │ │ ← Edit button
│  │ DNTS Serial: CT1_LAB5_M01                         │ │
│  │ Mfg Serial:  97205H5                              │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ... (4 more components with edit buttons)             │
└─────────────────────────────────────────────────────────┘
```

### Step 3: Click Edit Button
```
Click the ✏️ icon next to any component
```

### Step 4: Edit Dialog Opens
```
┌─────────────────────────────────────────────────────────┐
│  Edit Monitor Serial                                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Workstation: L5_T01                                    │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ DNTS Serial                                       │ │
│  │ CT1_LAB5_MR01                                     │ │ ← Pre-filled
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│                          [CANCEL]  [SAVE]               │
└─────────────────────────────────────────────────────────┘
```

### Step 5: Type New Serial
```
┌─────────────────────────────────────────────────────────┐
│  Edit Monitor Serial                                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Workstation: L5_T01                                    │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ DNTS Serial                                       │ │
│  │ CT1_LAB5_MR01_UPDATED█                            │ │ ← Type here
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│                          [CANCEL]  [SAVE]               │
└─────────────────────────────────────────────────────────┘
```

### Step 6: Click SAVE
```
Click the black SAVE button
```

### Step 7: Success!
```
┌─────────────────────────────────────────────────────────┐
│  ✅ Serial updated to: CT1_LAB5_MR01_UPDATED            │
└─────────────────────────────────────────────────────────┘

Modal automatically refreshes with new data:

┌─────────────────────────────────────────────────────────┐
│  L5_T01                                       [LOCAL]   │
├─────────────────────────────────────────────────────────┤
│  [6 Components]                                         │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 1. Monitor                                  [✏️]  │ │
│  │ DNTS Serial: CT1_LAB5_MR01_UPDATED                │ │ ← Updated!
│  │ Mfg Serial:  ZZNNH4ZM301248N                      │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 🎨 Visual Elements

### Edit Button
```
[✏️]  ← Small pencil icon
      18px size
      Appears on the right side
      Only visible for local storage data
```

### Edit Dialog
```
┌─────────────────────────────────────┐
│  Title: "Edit {Category} Serial"   │ ← Dynamic title
├─────────────────────────────────────┤
│  Context: "Workstation: L5_T01"    │ ← Shows location
│                                     │
│  TextField: Pre-filled with current│ ← Ready to edit
│                                     │
│  [CANCEL]  [SAVE]                  │ ← Actions
│   Gray      Black                  │
└─────────────────────────────────────┘
```

### Success Message
```
┌─────────────────────────────────────┐
│  ✅ Serial updated to: {new_value}  │ ← Green snackbar
└─────────────────────────────────────┘
```

## 🔄 Complete Workflow

```
User Action                    System Response
───────────────────────────────────────────────────────────
1. Click desk                  → Show modal with components
                                 
2. Click edit button (✏️)      → Close modal
                                 Open edit dialog
                                 Pre-fill current serial
                                 Focus on text field
                                 
3. Type new serial             → Update text field
                                 
4. Click SAVE                  → Close dialog
                                 Update SharedPreferences
                                 Show success message
                                 Reopen modal with new data
                                 
5. See updated serial          → Component shows new value
                                 Change is permanent
```

## 📊 Terminal Output

### When Edit Button Clicked
```
(No terminal output - UI only)
```

### When SAVE Clicked
```
💾 Updating component serial...
   Workstation: L5_T01
   Component Index: 0
   New Serial: CT1_LAB5_MR01_UPDATED
✅ Component updated successfully
```

### If Error Occurs
```
❌ Error updating component: {error_message}
```

## 🎯 Edit Button Behavior

### When Visible
- Data is from **local storage** (has "LOCAL" badge)
- Component is **editable**

### When Hidden
- Data is from **Supabase** (no "LOCAL" badge)
- Component is **read-only**

### Visual Indicator
```
Local Storage Data:
┌─────────────────────────────────────┐
│ 1. Monitor                    [✏️]  │ ← Edit button visible
└─────────────────────────────────────┘

Supabase Data:
┌─────────────────────────────────────┐
│ 1. Monitor                          │ ← No edit button
└─────────────────────────────────────┘
```

## 🔧 Technical Details

### Component Index
Each component has an index (0-5):
```
Index 0: Monitor
Index 1: Mouse
Index 2: Keyboard
Index 3: System Unit
Index 4: SSD
Index 5: AVR
```

### Update Process
```
1. Fetch workstation data from SharedPreferences
2. Parse JSON to List
3. Update component at specific index
4. Encode back to JSON
5. Save to SharedPreferences
6. Refresh UI
```

### Data Persistence
```
Before Edit:
workstation_L5_T01: [
  {"category":"Monitor","dnts_serial":"CT1_LAB5_MR01",...},
  ...
]

After Edit:
workstation_L5_T01: [
  {"category":"Monitor","dnts_serial":"CT1_LAB5_MR01_UPDATED",...},
  ...
]
```

## ✅ Validation

### Required
- Serial must not be empty
- Whitespace is trimmed

### Optional (Future)
- Format validation (e.g., CT1_LAB5_*)
- Duplicate check
- Length limits

## 🎯 Use Cases

### Scenario 1: Fix Typo
```
1. Notice wrong serial: "CT1_LAB5_MR0O" (O instead of 0)
2. Click edit button
3. Change to: "CT1_LAB5_MR01"
4. Save
5. Typo fixed!
```

### Scenario 2: Replace Component
```
1. Physical monitor replaced
2. New serial: "CT1_LAB5_MR99"
3. Click edit button
4. Update serial
5. Save
6. Record updated!
```

### Scenario 3: Bulk Update
```
1. Edit Monitor serial
2. Edit Mouse serial
3. Edit Keyboard serial
4. All changes persist
5. Data stays consistent
```

## 🚀 Quick Reference

| Action | Result |
|--------|--------|
| Click ✏️ | Opens edit dialog |
| Type in field | Updates text |
| Click CANCEL | Dismisses without saving |
| Click SAVE | Updates and persists |
| Success | Green snackbar appears |
| Error | Red snackbar appears |

## 🔮 Future Enhancements

- [ ] Edit mfg_serial
- [ ] Edit status (dropdown)
- [ ] Edit category (dropdown)
- [ ] Multi-field edit
- [ ] Validation rules
- [ ] Undo button
- [ ] Edit history

---

**Click ✏️ to edit any component serial!** 🎉
