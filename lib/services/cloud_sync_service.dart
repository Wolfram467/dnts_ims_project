import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for synchronizing local state changes to the cloud.
class CloudSyncService {
  /// Pushes a component move event to Supabase.
  /// 
  /// Updates the 'serialized_assets' table matching the [dntsSerial].
  /// Sets the 'notes' column to track the current logical desk.
  Future<void> syncComponentMove(String dntsSerial, String newDeskId) async {
    try {
      await Supabase.instance.client
          .from('serialized_assets')
          .update({'notes': 'Current Desk: $newDeskId'})
          .eq('dnts_serial', dntsSerial);
      
      print('Cloud Sync Success: Component $dntsSerial moved to desk $newDeskId.');
    } catch (error) {
      print('Cloud Sync Error for component $dntsSerial: $error');
    }
  }
}
