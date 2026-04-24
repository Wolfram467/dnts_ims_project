# Modal Preview - What You'll See

## 📱 Modal Display (After Clicking a Desk)

```
┌─────────────────────────────────────────────────────────────┐
│  L5_T01                                           [LOCAL]   │ ← Green badge
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              6 Components                           │   │ ← Component count
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Monitor                                          │   │ ← Component 1
│  │ DNTS Serial: CT1_LAB5_MR01                          │   │
│  │ Mfg Serial:  ZZNNH4ZM301248N                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 2. Mouse                                            │   │ ← Component 2
│  │ DNTS Serial: CT1_LAB5_M01                           │   │
│  │ Mfg Serial:  97205H5                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 3. Keyboard                                         │   │ ← Component 3
│  │ DNTS Serial: CT1_LAB5_K01                           │   │
│  │ Mfg Serial:  95NAA63                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 4. System Unit                                      │   │ ← Component 4
│  │ DNTS Serial: CT1_LAB5_SU01                          │   │
│  │ Mfg Serial:  2022A0853                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 5. SSD                                              │   │ ← Component 5
│  │ DNTS Serial: CT1_LAB5_SSD01                         │   │
│  │ Mfg Serial:  0026-B768-656D-7825                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 6. AVR                                              │   │ ← Component 6
│  │ DNTS Serial: CT1_LAB5_AVR01                         │   │
│  │ Mfg Serial:  YY2023030106970                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Source: Local Storage                       │   │ ← Source indicator
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                        [ CLOSE ]                            │
└─────────────────────────────────────────────────────────────┘
```

## 🎨 Visual Features

### Header
- **Workstation ID**: Large, prominent (e.g., "L5_T01")
- **LOCAL Badge**: Green badge in top-right corner

### Component Count
- Gray box showing total components (e.g., "6 Components")

### Component Cards
Each component displayed in a bordered box:
- **Number & Category**: Bold header (e.g., "1. Monitor")
- **DNTS Serial**: Primary identifier
- **Mfg Serial**: Manufacturer serial number
- **Spacing**: 12px between cards

### Footer
- **Source Indicator**: Green box showing "Source: Local Storage"
- **Close Button**: Black bordered button at bottom

### Scrolling
- Modal is scrollable if content exceeds screen height
- Max height: 70% of screen
- Smooth scrolling through all components

## 📊 Component Order

Your data shows components in this order:
1. **Monitor** (MR)
2. **Mouse** (M)
3. **Keyboard** (K)
4. **System Unit** (SU)
5. **SSD** (SSD)
6. **AVR** (AVR)

## 🖥️ Terminal Output (When Clicking)

```
🖱️ Desk clicked: L5_T01
🔍 Querying local storage for workstation: L5_T01
✅ Found in local storage: 6 components
   - CT1_LAB5_MR01 (Monitor)
   - CT1_LAB5_M01 (Mouse)
   - CT1_LAB5_K01 (Keyboard)
   - CT1_LAB5_SU01 (System Unit)
   - CT1_LAB5_SSD01 (SSD)
   - CT1_LAB5_AVR01 (AVR)
```

## 🎯 Example: L5_T02

```
┌─────────────────────────────────────────────────────────────┐
│  L5_T02                                           [LOCAL]   │
├─────────────────────────────────────────────────────────────┤
│  [6 Components]                                             │
│                                                             │
│  1. Monitor                                                 │
│     DNTS: CT1_LAB5_MR02                                     │
│     Mfg:  ZZNNH4ZM501690H                                   │
│                                                             │
│  2. Mouse                                                   │
│     DNTS: CT1_LAB5_M02                                      │
│     Mfg:  96C0DJL                                           │
│                                                             │
│  3. Keyboard                                                │
│     DNTS: CT1_LAB5_K02                                      │
│     Mfg:  95NA3MF                                           │
│                                                             │
│  4. System Unit                                             │
│     DNTS: CT1_LAB5_SU02                                     │
│     Mfg:  2022A0674                                         │
│                                                             │
│  5. SSD                                                     │
│     DNTS: CT1_LAB5_SSD02                                    │
│     Mfg:  0026-B768-656D-3DC5                               │
│                                                             │
│  6. AVR                                                     │
│     DNTS: CT1_LAB5_AVR02                                    │
│     Mfg:  UNKNOWN                                           │
│                                                             │
│  [Source: Local Storage]                                    │
│                                                             │
│                        [ CLOSE ]                            │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 Empty Workstation (If No Data)

```
┌─────────────────────────────────────────────────────────────┐
│  L5_T99                                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Empty Workstation                                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                        [ CLOSE ]                            │
└─────────────────────────────────────────────────────────────┘
```

## 🎨 Color Scheme

- **Background**: White
- **Borders**: Black (1px)
- **LOCAL Badge**: Green background, dark green text
- **Component Count Box**: Light gray background
- **Source Box**: Light green background
- **Text**: Black
- **Headers**: Bold, slightly larger

## 📱 Responsive

- Modal adapts to screen size
- Max height: 70% of viewport
- Scrollable content area
- Touch-friendly spacing
- Easy to read on all devices

---

**This is what you'll see when you click any Lab 5 desk!** 🎉
