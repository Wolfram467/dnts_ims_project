# Architecture: Map UI ↔ Local Storage

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Interactive Map Screen                    │
│                 (interactive_map_screen.dart)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ User clicks desk
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              _showWorkstationDetails(deskLabel)              │
│                                                               │
│  1. print('🖱️ Desk clicked: $deskLabel')                    │
│  2. print('🔍 Querying local storage...')                   │
│  3. Call getWorkstationAsset(deskLabel)                      │
│  4. print('✅ Found' or '❌ Not found')                      │
│  5. Show modal with data                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Query storage
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Seed Script Functions                     │
│                    (seed_lab5_data.dart)                     │
│                                                               │
│  • seedLab5Data()           - Populate storage               │
│  • getWorkstationAsset()    - Query single workstation       │
│  • listAllWorkstationData() - List all data                  │
│  • clearAllWorkstationData()- Clear storage                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Read/Write
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SharedPreferences                         │
│                  (Permanent Local Storage)                   │
│                                                               │
│  Key: workstation_L5_T01                                     │
│  Value: {                                                    │
│    "dnts_serial": "CT1_LAB5_MR01",                          │
│    "category": "Monitor",                                    │
│    "status": "Deployed",                                     │
│    "current_workstation_id": "L5_T01"                       │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow: Seeding

```
User clicks ☁️ button
        │
        ▼
_runSeedScript() called
        │
        ▼
seedLab5Data() executes
        │
        ├─► Create workstation assignments (Map)
        │
        ├─► For each workstation:
        │   ├─► Convert to JSON string
        │   ├─► Save to SharedPreferences
        │   └─► print('✓ Saved: ...')
        │
        ├─► Save metadata (timestamp, count)
        │
        └─► print('✅ Seeding complete!')
```

## Data Flow: Querying

```
User clicks desk "L5_T01"
        │
        ▼
_showWorkstationDetails("L5_T01") called
        │
        ├─► print('🖱️ Desk clicked: L5_T01')
        │
        ├─► print('🔍 Querying local storage...')
        │
        ▼
getWorkstationAsset("L5_T01") called
        │
        ├─► Get SharedPreferences instance
        │
        ├─► Query key: "workstation_L5_T01"
        │
        ├─► Parse JSON string to Map
        │
        └─► Return asset data (or null)
        │
        ▼
Back to _showWorkstationDetails()
        │
        ├─► print('✅ Found' or '❌ Not found')
        │
        ├─► Build modal with data
        │
        └─► Show "LOCAL" badge if from storage
```

## Storage Schema

### Key Format
```
workstation_{LAB_ID}_{DESK_NUMBER}
```

Examples:
- `workstation_L5_T01`
- `workstation_L5_T02`
- `workstation_L5_T48`

### Value Format (JSON)
```json
{
  "dnts_serial": "CT1_LAB5_MR01",
  "category": "Monitor",
  "status": "Deployed",
  "current_workstation_id": "L5_T01"
}
```

### Metadata Keys
- `seed_timestamp`: ISO 8601 timestamp of last seed
- `seed_count`: Number of workstations seeded

## Terminal Output Flow

### Successful Query
```
🖱️ Desk clicked: L5_T01
🔍 Querying local storage for workstation: L5_T01
✅ Found in local storage: CT1_LAB5_MR01 (Monitor)
```

### Empty Workstation
```
🖱️ Desk clicked: L5_T40
🔍 Querying local storage for workstation: L5_T40
❌ No asset found in local storage for: L5_T40
```

### Seed Operation
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
```

## UI Components

### Toolbar Buttons
```
┌──────────────────────────────────────────────────────────┐
│  CT1 Floor Plan                    🔍- 🔍+ 🔄 ☁️ 📋    │
└──────────────────────────────────────────────────────────┘
                                      │   │  │  │  │
                                      │   │  │  │  └─ List stored data
                                      │   │  │  └──── Seed Lab 5 data
                                      │   │  └─────── Refresh Supabase
                                      │   └────────── Zoom in
                                      └────────────── Zoom out
```

### Modal Display
```
┌─────────────────────────────────────┐
│ L5_T01                      [LOCAL] │ ← Green badge
├─────────────────────────────────────┤
│ Serial:   CT1_LAB5_MR01             │
│ Category: Monitor                   │
│ Status:   Deployed                  │
│ Source:   Local Storage             │
├─────────────────────────────────────┤
│            [ CLOSE ]                │
└─────────────────────────────────────┘
```

## Platform Support

| Platform | Storage Backend | Persistence |
|----------|----------------|-------------|
| Web | localStorage | ✅ Yes (per browser) |
| Android | SharedPreferences | ✅ Yes |
| iOS | NSUserDefaults | ✅ Yes |
| Windows | Registry | ✅ Yes |
| macOS | NSUserDefaults | ✅ Yes |
| Linux | File system | ✅ Yes |

## Key Features

✅ **Permanent Storage**: Data survives app restarts
✅ **Terminal Logging**: Every action prints to console
✅ **Visual Feedback**: "LOCAL" badge shows data source
✅ **Debug Tools**: List and clear functions for testing
✅ **Fallback Support**: Falls back to Supabase if not in local storage
✅ **Cross-Platform**: Works on all Flutter platforms
