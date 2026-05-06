import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/workstation_repository.dart';
import '../domain/inventory_manager.dart';

export 'domain_providers.dart';

final workstationRepositoryProvider = Provider<WorkstationRepository>((ref) {
  return WorkstationRepository();
});

final inventoryManagerProvider = Provider<InventoryManager>((ref) {
  final repository = ref.watch(workstationRepositoryProvider);
  return InventoryManager(repository);
});
