import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dnts_ims/core/result.dart';
import 'package:dnts_ims/domain/inventory_manager.dart';
import 'package:dnts_ims/models/hardware_component.dart';
import 'package:dnts_ims/utils/workstation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InventoryManager Tests', () {
    late WorkstationRepository repository;
    late InventoryManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = WorkstationRepository();
      manager = InventoryManager(repository);
    });

    test('moveComponent should successfully move a component', () async {
      const component = HardwareComponent(
        dntsSerial: 'CT1_LAB5_MR01',
        mfgSerial: 'SN123456',
        category: 'Monitor',
        status: 'Deployed',
      );

      await repository.saveWorkstationComponents('L5_D01', [component]);
      await repository.saveWorkstationComponents('L5_D02', []);

      final result = await manager.moveComponent(
        componentId: 'CT1_LAB5_MR01',
        fromWorkstationId: 'L5_D01',
        toWorkstationId: 'L5_D02',
      );

      expect(result is Success, isTrue);
      
      final sourceComponents = await repository.getWorkstationComponents('L5_D01');
      final targetComponents = await repository.getWorkstationComponents('L5_D02');

      final bool sourceIsEmpty = sourceComponents?.isEmpty ?? false;
      expect(sourceIsEmpty, isTrue);
      expect(targetComponents?.length, 1);
      expect(targetComponents?.first.dntsSerial, 'CT1_LAB5_MR01');
    });

    test('moveComponent should fail if component category already exists at target', () async {
      const componentToMove = HardwareComponent(
        dntsSerial: 'CT1_LAB5_MR01',
        mfgSerial: 'SN123456',
        category: 'Monitor',
        status: 'Deployed',
      );

      const existingComponent = HardwareComponent(
        dntsSerial: 'CT1_LAB5_MR02',
        mfgSerial: 'SN654321',
        category: 'Monitor',
        status: 'Deployed',
      );

      await repository.saveWorkstationComponents('L5_D01', [componentToMove]);
      await repository.saveWorkstationComponents('L5_D02', [existingComponent]);

      final result = await manager.moveComponent(
        componentId: 'CT1_LAB5_MR01',
        fromWorkstationId: 'L5_D01',
        toWorkstationId: 'L5_D02',
      );

      expect(result is Failure, isTrue);
    });
  });
}
