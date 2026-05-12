// ============================================================================
// EXAMPLE: How to format your workstation data
// ============================================================================
// Copy this format and paste into lib/seed_lab5_data.dart
// Replace the workstationData Map contents with your actual data

const Map<String, Map<String, dynamic>> workstationData = {
  // Format: 'WorkstationID': { asset data }
  
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
  
  'L5_T04': {
    'dnts_serial': 'CT1_LAB5_SU04',
    'category': 'System Unit',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T04',
  },
  
  'L5_T05': {
    'dnts_serial': 'CT1_LAB5_AVR05',
    'category': 'AVR',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T05',
  },
  
  'L5_T06': {
    'dnts_serial': 'CT1_LAB5_SSD06',
    'category': 'SSD',
    'status': 'Deployed',
    'current_workstation_id': 'L5_T06',
  },
  
  'L5_T07': {
    'dnts_serial': 'CT1_LAB5_MR07',
    'category': 'Monitor',
    'status': 'Under Maintenance',
    'current_workstation_id': 'L5_T07',
  },
  
  'L5_T08': {
    'dnts_serial': 'CT1_LAB5_M08',
    'category': 'Mouse',
    'status': 'Storage',
    'current_workstation_id': 'L5_T08',
  },
  
  // Continue for all 48 workstations...
  // L5_T09, L5_T10, ... L5_T48
};

// ============================================================================
// NOTES:
// ============================================================================
// 1. Workstation IDs must match desk labels on the map (L5_T01, L5_T02, etc.)
// 2. Use single quotes ' not double quotes "
// 3. Add trailing comma after each closing brace
// 4. Valid categories: Monitor, Mouse, Keyboard, System Unit, AVR, SSD
// 5. Valid statuses: Deployed, Borrowed, Under Maintenance, Storage, Retired
// 6. current_workstation_id should match the key
// 7. Lab 5 has 48 total workstations (L5_T01 through L5_T48)

// ============================================================================
// ALTERNATIVE: Generate all 48 workstations programmatically
// ============================================================================
// If you want to generate placeholder data for all 48 desks:

/*
const Map<String, Map<String, dynamic>> workstationData = {
  for (int i = 1; i <= 48; i++)
    'L5_T${i.toString().padLeft(2, '0')}': {
      'dnts_serial': 'CT1_LAB5_PLACEHOLDER${i.toString().padLeft(2, '0')}',
      'category': 'Monitor',
      'status': 'Deployed',
      'current_workstation_id': 'L5_T${i.toString().padLeft(2, '0')}',
    },
};
*/
