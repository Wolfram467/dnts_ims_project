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

class CreateComponentPanel extends ConsumerStatefulWidget {
  final String? initialLocation;
  const CreateComponentPanel({super.key, this.initialLocation});

  @override
  ConsumerState<CreateComponentPanel> createState() =>
      _CreateComponentPanelState();
}

class _CreateComponentPanelState extends ConsumerState<CreateComponentPanel> {
  final _dntsSerialController = TextEditingController();
  final _mfgSerialController = TextEditingController();
  final _brandController = TextEditingController();
  final _dateAcquiredController = TextEditingController();
  String? _selectedLocation;

  bool _isDntsSerialAiGenerated = false;
  bool _isMfgSerialAiGenerated = false;
  bool _isBrandAiGenerated = false;
  final Set<TextEditingController> _activeScanningControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ?? ref.read(activeDeskProvider) ?? 'Storage';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(draftComponentProvider);
      if (draft.isNotEmpty) {
        if (mounted) {
          setState(() {
            _dntsSerialController.text = draft['dnts'] ?? '';
            _mfgSerialController.text = draft['mfg'] ?? '';
            _brandController.text = draft['brand'] ?? '';
            _dateAcquiredController.text = draft['date'] ?? '';
          });
        }
      }
      _validateCapacity();
    });
  }

  @override
  void dispose() {
    _dntsSerialController.dispose();
    _mfgSerialController.dispose();
    _brandController.dispose();
    _dateAcquiredController.dispose();
    super.dispose();
  }

  void _syncToDraft() {
    ref.read(draftComponentProvider.notifier).state = {
      'dnts': _dntsSerialController.text,
      'mfg': _mfgSerialController.text,
      'brand': _brandController.text,
      'date': _dateAcquiredController.text,
    };
  }

  void _autoFillDntsSerial(String? type) {
    if (_selectedLocation == null ||
        _selectedLocation == 'Storage' ||
        type == null) {
      return;
    }

    final match = RegExp(
      r'L(?:ab)?(\d+)_[a-zA-Z]*(\d+)',
      caseSensitive: false,
    ).firstMatch(_selectedLocation!);
    if (match == null) return;

    final labNumber = match.group(1);
    final deskNumber = match.group(2);

    String categoryAbbr = '';
    switch (type) {
      case 'Monitor': categoryAbbr = 'MR'; break;
      case 'Monitor 1': categoryAbbr = 'MR1_'; break;
      case 'Monitor 2': categoryAbbr = 'MR2_'; break;
      case 'Mouse': categoryAbbr = 'M'; break;
      case 'Keyboard': categoryAbbr = 'K'; break;
      case 'System Unit': categoryAbbr = 'SU'; break;
      case 'AVR': categoryAbbr = 'AVR'; break;
      case 'SSD': categoryAbbr = 'SSD'; break;
      default: return;
    }

    _dntsSerialController.text = 'CT1_LAB${labNumber}_$categoryAbbr$deskNumber';
    _syncToDraft();
  }

  Future<void> _validateCapacity() async {
    final selectedType = ref.read(selectedCreationTypeProvider);
    if (_selectedLocation == null || selectedType == null) {
      ref.read(creationCapacityErrorProvider.notifier).state = null;
      return;
    }

    ref.read(isCheckingCapacityProvider.notifier).state = true;

    final inventoryManager = ref.read(inventoryManagerProvider);
    final result = await inventoryManager.validateCapacity(
      _selectedLocation!,
      selectedType,
    );

    if (mounted) {
      ref.read(isCheckingCapacityProvider.notifier).state = false;
      result.fold(
        (success) {
          ref.read(creationCapacityErrorProvider.notifier).state = null;
        },
        (failure) {
          ref.read(creationCapacityErrorProvider.notifier).state =
              failure.toString().replaceAll('Exception: ', '');
        },
      );
    }
  }

  Future<void> _startScanning(TextEditingController targetController, ScanType scanType) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan serial numbers'),
          ),
        );
      }
      return;
    }

    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const SerialScannerOverlay()),
    );

    if (imagePath != null && mounted) {
      setState(() {
        _activeScanningControllers.add(targetController);
      });
      ref.read(isScanningProvider.notifier).state = true;
      final scannerService = ref.read(serialScannerServiceProvider);

      try {
        final result = await scannerService.extractData(imagePath, scanType: scanType);

        if (mounted) {
          if (result != null) {
            setState(() {
              if (result.containsKey('dnts_serial') && result['dnts_serial'] != 'NOT_FOUND') {
                _dntsSerialController.text = result['dnts_serial']!;
                _isDntsSerialAiGenerated = true;
              }
              if (scanType == ScanType.manufacturer) {
                if (result.containsKey('mfg_serial') && result['mfg_serial'] != 'NOT_FOUND') {
                  _mfgSerialController.text = result['mfg_serial']!;
                  _isMfgSerialAiGenerated = true;
                }
                if (result.containsKey('brand') && result['brand']!.isNotEmpty) {
                  _brandController.text = result['brand']!;
                  _isBrandAiGenerated = true;
                }
                if (result.containsKey('category') && result['category']!.isNotEmpty) {
                  ref.read(selectedCreationTypeProvider.notifier).state = result['category'];
                }
              }
            });
            _syncToDraft();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan processing failed: ${e.toString().replaceAll('Exception: ', '')}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _activeScanningControllers.remove(targetController);
          });
          if (_activeScanningControllers.isEmpty) {
            ref.read(isScanningProvider.notifier).state = false;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedCreationTypeProvider);
    final formKey = ref.watch(creationFormKeyProvider);
    final capacityError = ref.watch(creationCapacityErrorProvider);
    // isScanning from provider is still active for global indicators, but we won't strictly block UI

    // Auto-fill and validation on type change
    ref.listen(selectedCreationTypeProvider, (prev, next) {
      if (next != null) {
        _autoFillDntsSerial(next);
        _validateCapacity();
      }
    });

    // Update location if activeDeskId changes
    ref.listen(activeDeskProvider, (prev, next) {
      if (next != null) {
        setState(() {
          _selectedLocation = next;
        });
        if (selectedType != null) {
          _autoFillDntsSerial(selectedType);
          _validateCapacity();
        }
      }
    });

    return Container(
      width: 100, // World units
      height: 100, // World units
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        border: Border.all(color: const Color(0xFF1F2937), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 400, // Increased virtual width to provide more character space
          height: 400, // Balanced height
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Text(
                    selectedType?.toUpperCase() ?? "COMPONENT",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),

                  // SINGLE COLUMN OF FIELDS (MAXIMIZES WIDTH)
                  _buildField(_dntsSerialController, 'DNTS Serial', ScanType.dnts),
                  _buildField(_mfgSerialController, 'Mfg Serial', ScanType.manufacturer),
                  _buildField(_brandController, 'Brand', ScanType.manufacturer),
                  _buildField(_dateAcquiredController, 'Date (Optional)', ScanType.manufacturer, isOptional: true),

                  // STATUS & ERROR (COMPACT)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (capacityError != null)
                        Text(
                          capacityError,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        'DEPLOYING TO $_selectedLocation',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildField(TextEditingController controller, String label, ScanType scanType, {bool isOptional = false}) {
    final bool isThisFieldScanning = _activeScanningControllers.contains(controller);
    
    return SizedBox(
      height: 54, // Fixed height for vertical rhythm
      child: TextFormField(
        controller: controller,
        onChanged: (_) => _syncToDraft(),
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: isThisFieldScanning ? 'Scanning...' : label,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF4B5563)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF4B5563)),
          ),
          suffixIcon: isThisFieldScanning
              ? const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.camera_alt, size: 28, color: Colors.white54),
                  onPressed: isThisFieldScanning ? null : () => _startScanning(controller, scanType),
                ),
        ),
        validator: isOptional ? null : (v) => v == null || v.isEmpty ? '!' : null,
      ),
    );
  }
}
