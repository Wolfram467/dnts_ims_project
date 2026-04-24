import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// WORKSTATION DATA MAP
/// ============================================================================
/// Paste your JSON payload here. Format:
/// {
///   'L5_T01': {'dnts_serial': '...', 'category': '...', 'status': '...'},
///   'L5_T02': {'dnts_serial': '...', 'category': '...', 'status': '...'},
///   ...
/// }
  const Map<String, List<Map<String, String>>> workstationData = {
  "L5_T01": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM301248N", "dnts_serial": "CT1_LAB5_MR01"},
    {"category": "Mouse", "mfg_serial": "97205H5", "dnts_serial": "CT1_LAB5_M01"},
    {"category": "Keyboard", "mfg_serial": "95NAA63", "dnts_serial": "CT1_LAB5_K01"},
    {"category": "System Unit", "mfg_serial": "2022A0853", "dnts_serial": "CT1_LAB5_SU01"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-7825", "dnts_serial": "CT1_LAB5_SSD01"},
    {"category": "AVR", "mfg_serial": "YY2023030106970", "dnts_serial": "CT1_LAB5_AVR01"}
  ],
  "L5_T02": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM501690H", "dnts_serial": "CT1_LAB5_MR02"},
    {"category": "Mouse", "mfg_serial": "96C0DJL", "dnts_serial": "CT1_LAB5_M02"},
    {"category": "Keyboard", "mfg_serial": "95NA3MF", "dnts_serial": "CT1_LAB5_K02"},
    {"category": "System Unit", "mfg_serial": "2022A0674", "dnts_serial": "CT1_LAB5_SU02"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-3DC5", "dnts_serial": "CT1_LAB5_SSD02"},
    {"category": "AVR", "mfg_serial": "UNKNOWN", "dnts_serial": "CT1_LAB5_AVR02"}
  ],
  "L5_T03": [
    {"category": "Monitor", "mfg_serial": "ZZMH4ZKA00826P", "dnts_serial": "CT1_LAB5_MR03"},
    {"category": "Mouse", "mfg_serial": "97205H2", "dnts_serial": "CT1_LAB5_M03"},
    {"category": "Keyboard", "mfg_serial": "902A2273", "dnts_serial": "CT1_LAB5_K03"},
    {"category": "System Unit", "mfg_serial": "2022A0855", "dnts_serial": "CT1_LAB5_SU03"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-5855", "dnts_serial": "CT1_LAB5_SSD03"},
    {"category": "AVR", "mfg_serial": "747889", "dnts_serial": "CT1_LAB5_AVR03"}
  ],
  "L5_T04": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM501325A", "dnts_serial": "CT1_LAB5_MR04"},
    {"category": "Mouse", "mfg_serial": "97205HH", "dnts_serial": "CT1_LAB5_M04"},
    {"category": "Keyboard", "mfg_serial": "95NA4CL", "dnts_serial": "CT1_LAB5_K04"},
    {"category": "System Unit", "mfg_serial": "2022A0805", "dnts_serial": "CT1_LAB5_SU04"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-5055", "dnts_serial": "CT1_LAB5_SSD04"},
    {"category": "AVR", "mfg_serial": "YY2023030107", "dnts_serial": "CT1_LAB5_AVR04"}
  ],
  "L5_T05": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM500954X", "dnts_serial": "CT1_LAB5_MR05"},
    {"category": "Mouse", "mfg_serial": "97205H3", "dnts_serial": "CT1_LAB5_M05"},
    {"category": "Keyboard", "mfg_serial": "95NAA61", "dnts_serial": "CT1_LAB5_K05"},
    {"category": "System Unit", "mfg_serial": "2022A0844", "dnts_serial": "CT1_LAB5_SU05"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-3345", "dnts_serial": "CT1_LAB5_SSD05"},
    {"category": "AVR", "mfg_serial": "716164", "dnts_serial": "CT1_LAB5_AVR05"}
  ],
  "L5_T06": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM300546T", "dnts_serial": "CT1_LAB5_MR06"},
    {"category": "Mouse", "mfg_serial": "97205H3", "dnts_serial": "CT1_LAB5_M06"},
    {"category": "Keyboard", "mfg_serial": "95NAA5X", "dnts_serial": "CT1_LAB5_K06"},
    {"category": "System Unit", "mfg_serial": "2022A0739", "dnts_serial": "CT1_LAB5_SU06"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-3345", "dnts_serial": "CT1_LAB5_SSD06"},
    {"category": "AVR", "mfg_serial": "UNKNOWN", "dnts_serial": "CT1_LAB5_AVR06"}
  ],
  "L5_T07": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM304167F", "dnts_serial": "CT1_LAB5_MR07"},
    {"category": "Mouse", "mfg_serial": "97205HG", "dnts_serial": "CT1_LAB5_M07"},
    {"category": "Keyboard", "mfg_serial": "95PA9M8", "dnts_serial": "CT1_LAB5_K07"},
    {"category": "System Unit", "mfg_serial": "2022A0785", "dnts_serial": "CT1_LAB5_SU07"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-DAF5", "dnts_serial": "CT1_LAB5_SSD07"},
    {"category": "AVR", "mfg_serial": "YY2023030106971", "dnts_serial": "CT1_LAB5_AVR07"}
  ],
  "L5_T08": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM500850X", "dnts_serial": "CT1_LAB5_MR08"},
    {"category": "Mouse", "mfg_serial": "97205H8", "dnts_serial": "CT1_LAB5_M08"},
    {"category": "Keyboard", "mfg_serial": "95PA9M5", "dnts_serial": "CT1_LAB5_K08"},
    {"category": "System Unit", "mfg_serial": "2022A0723", "dnts_serial": "CT1_LAB5_SU08"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-4015", "dnts_serial": "CT1_LAB5_SSD08"},
    {"category": "AVR", "mfg_serial": "651516", "dnts_serial": "CT1_LAB5_AVR08"}
  ],
  "L5_T09": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM103480F", "dnts_serial": "CT1_LAB5_MR09"},
    {"category": "Mouse", "mfg_serial": "97205HV", "dnts_serial": "CT1_LAB5_M09"},
    {"category": "Keyboard", "mfg_serial": "9021AN0M", "dnts_serial": "CT1_LAB5_K09"},
    {"category": "System Unit", "mfg_serial": "2022A0681", "dnts_serial": "CT1_LAB5_SU09"},
    {"category": "SSD", "mfg_serial": "0026-B768-656C-FFC5", "dnts_serial": "CT1_LAB5_SSD09"},
    {"category": "AVR", "mfg_serial": "YY2023030107630", "dnts_serial": "CT1_LAB5_AVR09"}
  ],
  "L5_T10": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM502441H", "dnts_serial": "CT1_LAB5_MR10"},
    {"category": "Mouse", "mfg_serial": "97205J1", "dnts_serial": "CT1_LAB5_M10"},
    {"category": "Keyboard", "mfg_serial": "95NAA5Y", "dnts_serial": "CT1_LAB5_K10"},
    {"category": "System Unit", "mfg_serial": "2022A0841", "dnts_serial": "CT1_LAB5_SU10"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-4695", "dnts_serial": "CT1_LAB5_SSD10"},
    {"category": "AVR", "mfg_serial": "747962", "dnts_serial": "CT1_LAB5_AVR10"}
  ],
  "L5_T11": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM300811F", "dnts_serial": "CT1_LAB5_MR11"},
    {"category": "Mouse", "mfg_serial": "97205VX", "dnts_serial": "CT1_LAB5_M11"},
    {"category": "Keyboard", "mfg_serial": "902A1N0G", "dnts_serial": "CT1_LAB5_K11"},
    {"category": "System Unit", "mfg_serial": "2022A0662", "dnts_serial": "CT1_LAB5_SU11"},
    {"category": "SSD", "mfg_serial": "0026-B768-656C-F0B5", "dnts_serial": "CT1_LAB5_SSD11"},
    {"category": "AVR", "mfg_serial": "YY2023030112396", "dnts_serial": "CT1_LAB5_AVR11"}
  ],
  "L5_T12": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM501781Z", "dnts_serial": "CT1_LAB5_MR12"},
    {"category": "Mouse", "mfg_serial": "97205H5", "dnts_serial": "CT1_LAB5_M12"},
    {"category": "Keyboard", "mfg_serial": "95PA9M7", "dnts_serial": "CT1_LAB5_K12"},
    {"category": "System Unit", "mfg_serial": "2022A0856", "dnts_serial": "CT1_LAB5_SU12"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-4FE5", "dnts_serial": "CT1_LAB5_SSD12"},
    {"category": "AVR", "mfg_serial": "UNKNOWN", "dnts_serial": "CT1_LAB5_AVR12"}
  ],
  "L5_T13": [
    {"category": "Monitor", "mfg_serial": "ZZNNH4ZM902095R", "dnts_serial": "CT1_LAB5_MR13"},
    {"category": "Mouse", "mfg_serial": "23XWU1", "dnts_serial": "CT1_LAB5_M13"},
    {"category": "Keyboard", "mfg_serial": "23X10U00", "dnts_serial": "CT1_LAB5_K13"},
    {"category": "System Unit", "mfg_serial": "2022A0661", "dnts_serial": "CT1_LAB5_SU13"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-01F5", "dnts_serial": "CT1_LAB5_SSD13"},
    {"category": "AVR", "mfg_serial": "YY20230106447", "dnts_serial": "CT1_LAB5_AVR13"}
  ],
  "L5_T14": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB503241D", "dnts_serial": "CT1_LAB5_MR14"},
    {"category": "Mouse", "mfg_serial": "97205HN", "dnts_serial": "CT1_LAB5_M14"},
    {"category": "Keyboard", "mfg_serial": "95PA9M3", "dnts_serial": "CT1_LAB5_K14"},
    {"category": "System Unit", "mfg_serial": "2022A0871", "dnts_serial": "CT1_LAB5_SU14"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-2225", "dnts_serial": "CT1_LAB5_SSD14"},
    {"category": "AVR", "mfg_serial": "UNKNOWN", "dnts_serial": "CT1_LAB5_AVR14"}
  ],
  "L5_T15": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB407138F", "dnts_serial": "CT1_LAB5_MR15"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M15"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K15"},
    {"category": "System Unit", "mfg_serial": "2022A0666", "dnts_serial": "CT1_LAB5_SU15"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-0BE5", "dnts_serial": "CT1_LAB5_SSD15"},
    {"category": "AVR", "mfg_serial": "YY2023030105499", "dnts_serial": "CT1_LAB5_AVR15"}
  ],
  "L5_T16": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB500022E", "dnts_serial": "CT1_LAB5_MR16"},
    {"category": "Mouse", "mfg_serial": "97205HN", "dnts_serial": "CT1_LAB5_M16"},
    {"category": "Keyboard", "mfg_serial": "95NAA60", "dnts_serial": "CT1_LAB5_K16"},
    {"category": "System Unit", "mfg_serial": "2022A0842", "dnts_serial": "CT1_LAB5_SU16"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-51A5", "dnts_serial": "CT1_LAB5_SSD16"},
    {"category": "AVR", "mfg_serial": "729888", "dnts_serial": "CT1_LAB5_AVR16"}
  ],
  "L5_T17": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB4009592", "dnts_serial": "CT1_LAB5_MR17"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M17"},
    {"category": "Keyboard", "mfg_serial": "95NAA9L", "dnts_serial": "CT1_LAB5_K17"},
    {"category": "System Unit", "mfg_serial": "2022A0779", "dnts_serial": "CT1_LAB5_SU17"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-44F5", "dnts_serial": "CT1_LAB5_SSD17"},
    {"category": "AVR", "mfg_serial": "YY2023030107631", "dnts_serial": "CT1_LAB5_AVR17"}
  ],
  "L5_T18": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB4004372", "dnts_serial": "CT1_LAB5_MR18"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M18"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K18"},
    {"category": "System Unit", "mfg_serial": "2022A0783", "dnts_serial": "CT1_LAB5_SU18"},
    {"category": "SSD", "mfg_serial": "0026-B768-656C-F175", "dnts_serial": "CT1_LAB5_SSD18"},
    {"category": "AVR", "mfg_serial": "747896", "dnts_serial": "CT1_LAB5_AVR18"}
  ],
  "L5_T19": [
    {"category": "Monitor", "mfg_serial": "ZWF4H4LC902776V", "dnts_serial": "CT1_LAB5_MR19"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M19"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K19"},
    {"category": "System Unit", "mfg_serial": "2022A0752", "dnts_serial": "CT1_LAB5_SU19"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-21B5", "dnts_serial": "CT1_LAB5_SSD19"},
    {"category": "AVR", "mfg_serial": "YY2023030106448", "dnts_serial": "CT1_LAB5_AVR19"}
  ],
  "L5_T20": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB401474Y", "dnts_serial": "CT1_LAB5_MR20"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M20"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K20"},
    {"category": "System Unit", "mfg_serial": "2022A0829", "dnts_serial": "CT1_LAB5_SU20"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-48B5", "dnts_serial": "CT1_LAB5_SSD20"},
    {"category": "AVR", "mfg_serial": "716049", "dnts_serial": "CT1_LAB5_AVR20"}
  ],
  "L5_T21": [
    {"category": "Monitor", "mfg_serial": "ZWF4H4LC800071H", "dnts_serial": "CT1_LAB5_MR21"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M21"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K21"},
    {"category": "System Unit", "mfg_serial": "2022A0734", "dnts_serial": "CT1_LAB5_SU21"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-5035", "dnts_serial": "CT1_LAB5_SSD21"},
    {"category": "AVR", "mfg_serial": "747379", "dnts_serial": "CT1_LAB5_AVR21"}
  ],
  "L5_T22": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB400907W", "dnts_serial": "CT1_LAB5_MR22"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M22"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K22"},
    {"category": "System Unit", "mfg_serial": "2022A0699", "dnts_serial": "CT1_LAB5_SU22"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-4335", "dnts_serial": "CT1_LAB5_SSD22"},
    {"category": "AVR", "mfg_serial": "716177", "dnts_serial": "CT1_LAB5_AVR22"}
  ],
  "L5_T23": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB405757F", "dnts_serial": "CT1_LAB5_MR23"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M23"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K23"},
    {"category": "System Unit", "mfg_serial": "2022A0757", "dnts_serial": "CT1_LAB5_SU23"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-DA05", "dnts_serial": "CT1_LAB5_SSD23"},
    {"category": "AVR", "mfg_serial": "716055", "dnts_serial": "CT1_LAB5_AVR23"}
  ],
  "L5_T24": [
    {"category": "Monitor", "mfg_serial": "ZWF4H4LC902284X", "dnts_serial": "CT1_LAB5_MR24"},
    {"category": "Mouse", "mfg_serial": "23XWU01", "dnts_serial": "CT1_LAB5_M24"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K24"},
    {"category": "System Unit", "mfg_serial": "2022A0835", "dnts_serial": "CT1_LAB5_SU24"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172252", "dnts_serial": "CT1_LAB5_SSD24"},
    {"category": "AVR", "mfg_serial": "UNKNOWN", "dnts_serial": "CT1_LAB5_AVR24"}
  ],
  "L5_T25": [
    {"category": "Monitor", "mfg_serial": "336010998233", "dnts_serial": "CT1_LAB5_MR25"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M25"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K25"},
    {"category": "System Unit", "mfg_serial": "2022A0923", "dnts_serial": "CT1_LAB5_SU25"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172245", "dnts_serial": "CT1_LAB5_SSD25"},
    {"category": "AVR", "mfg_serial": "YY14062327059", "dnts_serial": "CT1_LAB5_AVR25"}
  ],
  "L5_T26": [
    {"category": "Monitor", "mfg_serial": "336010533233", "dnts_serial": "CT1_LAB5_MR26"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M26"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K26"},
    {"category": "System Unit", "mfg_serial": "2022A0916", "dnts_serial": "CT1_LAB5_SU26"},
    {"category": "SSD", "mfg_serial": "51A9073B027D00161931", "dnts_serial": "CT1_LAB5_SSD26"},
    {"category": "AVR", "mfg_serial": "YY14062327064", "dnts_serial": "CT1_LAB5_AVR26"}
  ],
  "L5_T27": [
    {"category": "Monitor", "mfg_serial": "336010569233", "dnts_serial": "CT1_LAB5_MR27"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M27"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K27"},
    {"category": "System Unit", "mfg_serial": "2022A0939", "dnts_serial": "CT1_LAB5_SU27"},
    {"category": "SSD", "mfg_serial": "1153073B021800171470", "dnts_serial": "CT1_LAB5_SSD27"},
    {"category": "AVR", "mfg_serial": "YY14072303864", "dnts_serial": "CT1_LAB5_AVR27"}
  ],
  "L5_T28": [
    {"category": "Monitor", "mfg_serial": "336011927233", "dnts_serial": "CT1_LAB5_MR28"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M28"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K28"},
    {"category": "System Unit", "mfg_serial": "2022A0895", "dnts_serial": "CT1_LAB5_SU28"},
    {"category": "SSD", "mfg_serial": "51A9073B027D00161897", "dnts_serial": "CT1_LAB5_SSD28"},
    {"category": "AVR", "mfg_serial": "YY14062327060", "dnts_serial": "CT1_LAB5_AVR28"}
  ],
  "L5_T29": [
    {"category": "Monitor", "mfg_serial": "336011927233", "dnts_serial": "CT1_LAB5_MR29"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M29"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K29"},
    {"category": "System Unit", "mfg_serial": "2022A0907", "dnts_serial": "CT1_LAB5_SU29"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172285", "dnts_serial": "CT1_LAB5_SSD29"},
    {"category": "AVR", "mfg_serial": "YY14072303865", "dnts_serial": "CT1_LAB5_AVR29"}
  ],
  "L5_T30": [
    {"category": "Monitor", "mfg_serial": "336010995233", "dnts_serial": "CT1_LAB5_MR30"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M30"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K30"},
    {"category": "System Unit", "mfg_serial": "2022A0918", "dnts_serial": "CT1_LAB5_SU30"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-DAE5", "dnts_serial": "CT1_LAB5_SSD30"},
    {"category": "AVR", "mfg_serial": "YY14072303861", "dnts_serial": "CT1_LAB5_AVR30"}
  ],
  "L5_T31": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB503252A", "dnts_serial": "CT1_LAB5_MR31"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M31"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K31"},
    {"category": "System Unit", "mfg_serial": "2022A0821", "dnts_serial": "CT1_LAB5_SU31"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-3DB5", "dnts_serial": "CT1_LAB5_SSD31"},
    {"category": "AVR", "mfg_serial": "YY2023030107629", "dnts_serial": "CT1_LAB5_AVR31"}
  ],
  "L5_T32": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB407127H", "dnts_serial": "CT1_LAB5_MR32"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M32"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K32"},
    {"category": "System Unit", "mfg_serial": "2022A0874", "dnts_serial": "CT1_LAB5_SU32"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-DA15", "dnts_serial": "CT1_LAB5_SSD32"},
    {"category": "AVR", "mfg_serial": "YY2023021525931", "dnts_serial": "CT1_LAB5_AVR32"}
  ],
  "L5_T33": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB406005Y", "dnts_serial": "CT1_LAB5_MR33"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M33"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K33"},
    {"category": "System Unit", "mfg_serial": "2022A0854", "dnts_serial": "CT1_LAB5_SU33"},
    {"category": "SSD", "mfg_serial": "0026-B768-656E-0AA5", "dnts_serial": "CT1_LAB5_SSD33"},
    {"category": "AVR", "mfg_serial": "747630", "dnts_serial": "CT1_LAB5_AVR33"}
  ],
  "L5_T34": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB502257H", "dnts_serial": "CT1_LAB5_MR34"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M34"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K34"},
    {"category": "System Unit", "mfg_serial": "2022A0826", "dnts_serial": "CT1_LAB5_SU34"},
    {"category": "SSD", "mfg_serial": "0026-B768-656D-32C5", "dnts_serial": "CT1_LAB5_SSD34"},
    {"category": "AVR", "mfg_serial": "YY2023030101112", "dnts_serial": "CT1_LAB5_AVR34"}
  ],
  "L5_T35": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB400710R", "dnts_serial": "CT1_LAB5_MR35"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M35"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K35"},
    {"category": "System Unit", "mfg_serial": "2022A0748", "dnts_serial": "CT1_LAB5_SU35"},
    {"category": "SSD", "mfg_serial": "0026-B768-656C-F735", "dnts_serial": "CT1_LAB5_SSD35"},
    {"category": "AVR", "mfg_serial": "YY2023030105498", "dnts_serial": "CT1_LAB5_AVR35"}
  ],
  "L5_T36": [
    {"category": "Monitor", "mfg_serial": "V8CFH9NB309294K", "dnts_serial": "CT1_LAB5_MR36"},
    {"category": "Mouse", "mfg_serial": "23XWUO1", "dnts_serial": "CT1_LAB5_M36"},
    {"category": "Keyboard", "mfg_serial": "23XWU00", "dnts_serial": "CT1_LAB5_K36"},
    {"category": "System Unit", "mfg_serial": "2022A0649", "dnts_serial": "CT1_LAB5_SU36"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172291", "dnts_serial": "CT1_LAB5_SSD36"},
    {"category": "AVR", "mfg_serial": "YY19052312067", "dnts_serial": "CT1_LAB5_AVR36"}
  ],
  "L5_T37": [
    {"category": "Monitor", "mfg_serial": "336010497233", "dnts_serial": "CT1_LAB5_MR37"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M37"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K37"},
    {"category": "System Unit", "mfg_serial": "2022A0881", "dnts_serial": "CT1_LAB5_SU37"},
    {"category": "SSD", "mfg_serial": "KJ202101001809315", "dnts_serial": "CT1_LAB5_SSD37"},
    {"category": "AVR", "mfg_serial": "YY14062327063", "dnts_serial": "CT1_LAB5_AVR37"}
  ],
  "L5_T38": [
    {"category": "Monitor", "mfg_serial": "336010514233", "dnts_serial": "CT1_LAB5_MR38"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M38"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K38"},
    {"category": "System Unit", "mfg_serial": "2022A0902", "dnts_serial": "CT1_LAB5_SU38"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172236", "dnts_serial": "CT1_LAB5_SSD38"},
    {"category": "AVR", "mfg_serial": "YY14072303869", "dnts_serial": "CT1_LAB5_AVR38"}
  ],
  "L5_T39": [
    {"category": "Monitor", "mfg_serial": "3360110495233", "dnts_serial": "CT1_LAB5_MR39"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M39"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K39"},
    {"category": "System Unit", "mfg_serial": "2022A0879", "dnts_serial": "CT1_LAB5_SU39"},
    {"category": "SSD", "mfg_serial": "KJ202101001809320", "dnts_serial": "CT1_LAB5_SSD39"},
    {"category": "AVR", "mfg_serial": "YY08222307027", "dnts_serial": "CT1_LAB5_AVR39"}
  ],
  "L5_T40": [
    {"category": "Monitor", "mfg_serial": "336011929233", "dnts_serial": "CT1_LAB5_MR40"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M40"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K40"},
    {"category": "System Unit", "mfg_serial": "2022A0926", "dnts_serial": "CT1_LAB5_SU40"},
    {"category": "SSD", "mfg_serial": "51A9073B027D00161934", "dnts_serial": "CT1_LAB5_SSD40"},
    {"category": "AVR", "mfg_serial": "YY08222304556", "dnts_serial": "CT1_LAB5_AVR40"}
  ],
  "L5_T41": [
    {"category": "Monitor", "mfg_serial": "336011942233", "dnts_serial": "CT1_LAB5_MR41"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M41"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K41"},
    {"category": "System Unit", "mfg_serial": "2022A0884", "dnts_serial": "CT1_LAB5_SU41"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172276", "dnts_serial": "CT1_LAB5_SSD41"},
    {"category": "AVR", "mfg_serial": "YY14072303866", "dnts_serial": "CT1_LAB5_AVR41"}
  ],
  "L5_T42": [
    {"category": "Monitor", "mfg_serial": "336010973233", "dnts_serial": "CT1_LAB5_MR42"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M42"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K42"},
    {"category": "System Unit", "mfg_serial": "2022A0888", "dnts_serial": "CT1_LAB5_SU42"},
    {"category": "SSD", "mfg_serial": "0E74073B020000152289", "dnts_serial": "CT1_LAB5_SSD42"},
    {"category": "AVR", "mfg_serial": "YY14062327061", "dnts_serial": "CT1_LAB5_AVR42"}
  ],
  "L5_T43": [
    {"category": "Monitor", "mfg_serial": "336010527233", "dnts_serial": "CT1_LAB5_MR43"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M43"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K43"},
    {"category": "System Unit", "mfg_serial": "2022A0929", "dnts_serial": "CT1_LAB5_SU43"},
    {"category": "SSD", "mfg_serial": "0E74073B020000152337", "dnts_serial": "CT1_LAB5_SSD43"},
    {"category": "AVR", "mfg_serial": "YY08222307032", "dnts_serial": "CT1_LAB5_AVR43"}
  ],
  "L5_T44": [
    {"category": "Monitor", "mfg_serial": "336011957233", "dnts_serial": "CT1_LAB5_MR44"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M44"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K44"},
    {"category": "System Unit", "mfg_serial": "2022A0920", "dnts_serial": "CT1_LAB5_SU44"},
    {"category": "SSD", "mfg_serial": "5193073B027F00172246", "dnts_serial": "CT1_LAB5_SSD44"},
    {"category": "AVR", "mfg_serial": "YY08222304560", "dnts_serial": "CT1_LAB5_AVR44"}
  ],
  "L5_T45": [
    {"category": "Monitor", "mfg_serial": "336011745233", "dnts_serial": "CT1_LAB5_MR45"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M45"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K45"},
    {"category": "System Unit", "mfg_serial": "2022A0935", "dnts_serial": "CT1_LAB5_SU45"},
    {"category": "SSD", "mfg_serial": "115E073B021800171453", "dnts_serial": "CT1_LAB5_SSD45"},
    {"category": "AVR", "mfg_serial": "YY08222304557", "dnts_serial": "CT1_LAB5_AVR45"}
  ],
  "L5_T46": [
    {"category": "Monitor", "mfg_serial": "336011928233", "dnts_serial": "CT1_LAB5_MR46"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M46"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K46"},
    {"category": "System Unit", "mfg_serial": "2022A0915", "dnts_serial": "CT1_LAB5_SU46"},
    {"category": "SSD", "mfg_serial": "115E073B021800171520", "dnts_serial": "CT1_LAB5_SSD46"},
    {"category": "AVR", "mfg_serial": "YY08222307029", "dnts_serial": "CT1_LAB5_AVR46"}
  ],
  "L5_T47": [
    {"category": "Monitor", "mfg_serial": "336010841233", "dnts_serial": "CT1_LAB5_MR47"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M47"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K47"},
    {"category": "System Unit", "mfg_serial": "2022A0943", "dnts_serial": "CT1_LAB5_SU47"},
    {"category": "SSD", "mfg_serial": "115E073B021800171465", "dnts_serial": "CT1_LAB5_SSD47"},
    {"category": "AVR", "mfg_serial": "YY08222307025", "dnts_serial": "CT1_LAB5_AVR47"}
  ],
  "L5_T48": [
    {"category": "Monitor", "mfg_serial": "336010503233", "dnts_serial": "CT1_LAB5_MR48"},
    {"category": "Mouse", "mfg_serial": "23JIU01", "dnts_serial": "CT1_LAB5_M48"},
    {"category": "Keyboard", "mfg_serial": "23UIU00", "dnts_serial": "CT1_LAB5_K48"},
    {"category": "System Unit", "mfg_serial": "2022A0906", "dnts_serial": "CT1_LAB5_SU48"},
    {"category": "SSD", "mfg_serial": "115E073B021800171465", "dnts_serial": "CT1_LAB5_SSD48"},
    {"category": "AVR", "mfg_serial": "YY08222304561", "dnts_serial": "CT1_LAB5_AVR48"}
  ]
};


/// ============================================================================
/// SEED FUNCTION
/// ============================================================================
/// Saves the workstationData Map to SharedPreferences (permanent local storage)
Future<void> seedLab5Data() async {
  print('🌱 Starting Lab 5 data seeding...');
  
  if (workstationData.isEmpty) {
    print('⚠️  WARNING: workstationData Map is empty!');
    print('   Please paste your JSON payload into seed_lab5_data.dart');
    return;
  }
  
  final prefs = await SharedPreferences.getInstance();
  
  // Commit each workstation assignment to permanent storage
  int savedCount = 0;
  for (final entry in workstationData.entries) {
    final workstationId = entry.key;
    final assetsList = entry.value; // This is a List of assets
    
    // Store as JSON string
    final jsonString = jsonEncode(assetsList);
    await prefs.setString('workstation_$workstationId', jsonString);
    
    savedCount++;
    // Show first asset's serial as summary
    final firstSerial = assetsList.isNotEmpty ? assetsList[0]['dnts_serial'] ?? 'N/A' : 'N/A';
    print('  ✓ Saved: $workstationId -> ${assetsList.length} components (first: $firstSerial)');
  }
  
  // Store metadata about the seed
  await prefs.setString('seed_timestamp', DateTime.now().toIso8601String());
  await prefs.setInt('seed_count', savedCount);
  
  print('✅ Lab 5 seeding complete! $savedCount workstations assigned.');
  print('📦 Data committed to SharedPreferences (permanent local storage)');
}

/// ============================================================================
/// QUERY FUNCTIONS
/// ============================================================================

/// Query a specific workstation's asset data from local storage
/// Returns a List of assets (6 components per desk)
Future<List<Map<String, dynamic>>?> getWorkstationAssets(String workstationId) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('workstation_$workstationId');
  
  if (jsonString == null) {
    return null;
  }
  
  // Decode as List<dynamic> first, then cast to List<Map<String, dynamic>>
  final decoded = jsonDecode(jsonString);
  if (decoded is List) {
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
  
  return null;
}

/// Get the count of workstations in the data map (before seeding)
int getWorkstationDataCount() {
  return workstationData.length;
}

/// ============================================================================
/// DEBUG & UTILITY FUNCTIONS
/// ============================================================================

/// Clear all workstation data (for testing)
Future<void> clearAllWorkstationData() async {
  print('🧹 Clearing all workstation data...');
  final prefs = await SharedPreferences.getInstance();
  
  // Get all keys and remove workstation-related ones
  final keys = prefs.getKeys();
  int removedCount = 0;
  
  for (final key in keys) {
    if (key.startsWith('workstation_') || key.startsWith('seed_')) {
      await prefs.remove(key);
      removedCount++;
    }
  }
  
  print('✅ Cleared $removedCount entries from local storage');
}

/// Debug: List all workstation data in storage
Future<void> listAllWorkstationData() async {
  print('\n📋 LISTING ALL WORKSTATION DATA IN LOCAL STORAGE');
  print('═══════════════════════════════════════════════════');
  
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith('workstation_')).toList();
  keys.sort();
  
  if (keys.isEmpty) {
    print('❌ No workstation data found in local storage');
    return;
  }
  
  print('Found ${keys.length} workstations:\n');
  
  for (final key in keys) {
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString);
      final workstationId = key.replaceFirst('workstation_', '');
      
      if (decoded is List) {
        final assetsList = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        print('  $workstationId → ${assetsList.length} components:');
        for (final asset in assetsList) {
          print('    - ${asset['dnts_serial']} (${asset['category']})');
        }
      }
    }
  }
  
  // Show metadata
  final timestamp = prefs.getString('seed_timestamp');
  final count = prefs.getInt('seed_count');
  
  if (timestamp != null) {
    print('\n📅 Last seeded: $timestamp');
  }
  if (count != null) {
    print('📊 Seed count: $count');
  }
  
  print('═══════════════════════════════════════════════════\n');
}

