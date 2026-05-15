import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/hardware_component.dart';
import '../providers/repository_providers.dart';
import '../providers/map_state_provider.dart';
import '../providers/service_providers.dart';
import '../services/serial_scanner_service.dart';
import 'serial_scanner_overlay.dart';

class ComponentEditPanel extends ConsumerStatefulWidget {
  final String workstationIdentifier;
  final HardwareComponent component;

  const ComponentEditPanel({
    super.key,
    required this.workstationIdentifier,
    required this.component,
  });

  @override
  ConsumerState<ComponentEditPanel> createState() => _ComponentEditPanelState();
}

class _ComponentEditPanelState extends ConsumerState<ComponentEditPanel> {
  late TextEditingController _dntsSerialController;
  late TextEditingController _mfgSerialController;
  late TextEditingController _brandController;
  late TextEditingController _dateController;
  late String _selectedStatus;
  
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final List<String> _statuses = [
    'Deployed',
    'Under Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _dntsSerialController = TextEditingController(text: widget.component.dntsSerial);
    _mfgSerialController = TextEditingController(text: widget.component.mfgSerial);
    _brandController = TextEditingController(text: widget.component.brand);
    _dateController = TextEditingController(text: widget.component.dateAcquired ?? '');
    
    final rawStatus = widget.component.status;
    _selectedStatus = _statuses.firstWhere(
      (status) => status.toLowerCase() == rawStatus.toLowerCase(),
      orElse: () => 'Deployed',
    );
  }

  @override
  void dispose() {
    _dntsSerialController.dispose();
    _mfgSerialController.dispose();
    _brandController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _startScanning(TextEditingController controller) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const SerialScannerOverlay()),
    );

    if (imagePath != null && mounted) {
      ref.read(isScanningProvider.notifier).state = true;
      final scannerService = ref.read(serialScannerServiceProvider);
      final result = await scannerService.extractData(imagePath);

      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
        if (result != null) {
          setState(() {
            if (result['mfg_serial'] != null && result['mfg_serial']!.isNotEmpty) {
              _mfgSerialController.text = result['mfg_serial']!;
            }
            if (result['brand'] != null && result['brand']!.isNotEmpty) {
              _brandController.text = result['brand']!;
            }
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.component.copyWith(
      dntsSerial: _dntsSerialController.text.trim(),
      mfgSerial: _mfgSerialController.text.trim(),
      brand: _brandController.text.trim(),
      dateAcquired: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      status: _selectedStatus,
    );

    final success = await ref.read(workstationRepositoryProvider).updateWorkstationComponent(
      widget.workstationIdentifier,
      widget.component.dntsSerial,
      updated,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ref.read(refreshTriggerProvider.notifier).state++;
        ref.read(isEditingModeProvider.notifier).state = false;
        ref.read(editingComponentProvider.notifier).state = null;
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _isSaving = true);
    final success = await ref.read(workstationRepositoryProvider)
        .deleteWorkstationComponent(widget.workstationIdentifier, widget.component.category);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ref.read(refreshTriggerProvider.notifier).state++;
        ref.read(isEditingModeProvider.notifier).state = false;
        ref.read(editingComponentProvider.notifier).state = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(isScanningProvider);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 400,
          height: 400,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'EDIT ${widget.component.category.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  _buildField(_dntsSerialController, 'DNTS Serial', Icons.qr_code, false),
                  _buildField(_mfgSerialController, 'Mfg Serial', Icons.tag, true),
                  _buildField(_brandController, 'Brand', Icons.business, true),
                  _buildField(_dateController, 'Date (Optional)', Icons.calendar_today, false),
                  
                  // STATUS DROPDOWN
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      border: Border.all(color: const Color(0xFF4B5563)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: const Color(0xFF111827),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton('DELETE', Colors.redAccent, _delete),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton('SAVE', Colors.greenAccent, _save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool canScan) {
    return SizedBox(
      height: 54,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 18),
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          filled: true,
          fillColor: const Color(0xFF111827),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF4B5563))),
          suffixIcon: canScan ? IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white54, size: 24),
            onPressed: () => _startScanning(controller),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color == Colors.white24 ? Colors.white : Colors.black,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
