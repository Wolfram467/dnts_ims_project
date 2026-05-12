import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/workstation_repository.dart';
import '../domain/inventory_manager.dart';
import '../services/cloud_sync_service.dart';

export 'domain_providers.dart';

final workstationRepositoryProvider = Provider<WorkstationRepository>((ref) {
  return WorkstationRepository();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

final inventoryManagerProvider = Provider<InventoryManager>((ref) {
  final repository = ref.watch(workstationRepositoryProvider);
  final syncService = ref.watch(cloudSyncServiceProvider);
  return InventoryManager(repository, syncService);
});
