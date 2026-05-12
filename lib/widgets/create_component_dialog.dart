import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hardware_component.dart';
import '../providers/repository_providers.dart';
import '../providers/domain_providers.dart';
import '../providers/map_state_provider.dart';

class CreateComponentDialog extends ConsumerStatefulWidget {
  final String? initialLocation;
  const CreateComponentDialog({super.key, this.initialLocation});

  @override
  ConsumerState<CreateComponentDialog> createState() => _CreateComponentDialogState();
}

class _CreateComponentDialogState extends ConsumerState<CreateComponentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;
  final _dntsSerialController = TextEditingController();
  final _mfgSerialController = TextEditingController();
  final _brandController = TextEditingController();
  final _dateAcquiredController = TextEditingController();
  String? _selectedLocation;

  List<String> _availableLocations = ['Storage'];
  bool _isLoadingLocations = true;

  bool _isCheckingCapacity = false;
  String? _capacityErrorMessage;

  final List<String> _componentTypes = [
    'Monitor',
    'Mouse',
    'Keyboard',
    'System Unit',
    'AVR',
    'SSD'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? ref.read(activeDeskProvider) ?? 'Storage';
    
    _loadLocations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(draftComponentProvider);
      if (draft.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedType = draft['type'];
            _dntsSerialController.text = draft['dnts'] ?? '';
            _mfgSerialController.text = draft['mfg'] ?? '';
            _brandController.text = draft['brand'] ?? '';
          });
        }
      }
      if (_selectedLocation != null && _selectedType != null) {
        _validateCapacity();
      }
    });
  }

  Future<void> _loadLocations() async {
    final spatialManager = ref.read(spatialManagerProvider);
    final configs = spatialManager.getLayoutForFacility('CT1');
    final deskIds = configs.map((c) => c.id).toList();
    deskIds.sort();

    if (mounted) {
      setState(() {
        _availableLocations = ['Storage', ...deskIds];
        _isLoadingLocations = false;
        
        if (_selectedLocation != null && !_availableLocations.contains(_selectedLocation)) {
          _selectedLocation = 'Storage';
        }
      });
    }
  }

  @override
  void dispose() {
    _dntsSerialController.dispose();
    _mfgSerialController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _autoFillDntsSerial() {
    if (_selectedLocation == null || _selectedLocation == 'Storage' || _selectedType == null) {
      return;
    }

    final match = RegExp(r'L(?:ab)?(\d+)_[a-zA-Z]*(\d+)', caseSensitive: false).firstMatch(_selectedLocation!);
    if (match == null) return;

    final labNumber = match.group(1);
    final deskNumber = match.group(2);

    String categoryAbbr = '';
    switch (_selectedType) {
      case 'Monitor':
        categoryAbbr = 'MR';
        break;
      case 'Mouse':
        categoryAbbr = 'M';
        break;
      case 'Keyboard':
        categoryAbbr = 'K';
        break;
      case 'System Unit':
        categoryAbbr = 'SU';
        break;
      case 'AVR':
        categoryAbbr = 'AVR';
        break;
      case 'SSD':
        categoryAbbr = 'SSD';
        break;
      default:
        return;
    }

    _dntsSerialController.text = 'CT1_LAB${labNumber}_$categoryAbbr$deskNumber';
  }

  Future<void> _validateCapacity() async {
    if (_selectedLocation == null || _selectedType == null) {
      if (mounted) {
        setState(() {
          _capacityErrorMessage = null;
        });
      }
      return;
    }

    setState(() {
      _isCheckingCapacity = true;
    });

    final inventoryManager = ref.read(inventoryManagerProvider);
    final result = await inventoryManager.validateCapacity(_selectedLocation!, _selectedType!);

    if (mounted) {
      setState(() {
        _isCheckingCapacity = false;
        result.fold(
          (success) {
            _capacityErrorMessage = null;
          },
          (failure) {
            _capacityErrorMessage = failure.toString().replaceAll('Exception: ', '');
          },
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capacityErrorMessage != null || _isCheckingCapacity) return;

    final newComponent = HardwareComponent(
      category: _selectedType!,
      dntsSerial: _dntsSerialController.text.trim(),
      mfgSerial: _mfgSerialController.text.trim(),
      brand: _brandController.text.trim(),
      dateAcquired: _dateAcquiredController.text.trim().isEmpty ? null : _dateAcquiredController.text.trim(),
      status: _selectedLocation == 'Storage' ? 'Storage' : 'Deployed', 
    );

    final inventoryManager = ref.read(inventoryManagerProvider);
    final location = _selectedLocation!;

    final result = await inventoryManager.createComponent(location, newComponent);

    if (mounted) {
      result.fold(
        (success) {
          ref.read(draftComponentProvider.notifier).state = {};
          ref.read(refreshTriggerProvider.notifier).state++;
          ref.invalidate(activeDeskComponentsProvider);
          Navigator.of(context).pop();
        },
        (failure) {
          setState(() {
            _capacityErrorMessage = failure.toString().replaceAll('Exception: ', '');
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 1),
    );

    final inputDecoration = InputDecoration(
      border: defaultBorder,
      enabledBorder: defaultBorder,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'CREATE COMPONENT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Component Type
                DropdownButtonFormField<String>(
                  decoration: inputDecoration.copyWith(labelText: 'Component Type'),
                  value: _selectedType,
                  items: _componentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _autoFillDntsSerial();
                    _validateCapacity();
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // DNTS Serial
                TextFormField(
                  controller: _dntsSerialController,
                  decoration: inputDecoration.copyWith(labelText: 'Component Sticker Number (DNTS)'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Mfg Serial
                TextFormField(
                  controller: _mfgSerialController,
                  decoration: inputDecoration.copyWith(labelText: 'Manufacturer Serial Number'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Brand
                TextFormField(
                  controller: _brandController,
                  decoration: inputDecoration.copyWith(labelText: 'Component Brand'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Acquisition Date
                TextFormField(
                  controller: _dateAcquiredController,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Acquisition Date (Optional)',
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateAcquiredController.text = "\${picked.year}-\${picked.month.toString().padLeft(2, '0')}-\${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: Key(_selectedLocation ?? 'none'),
                        initialValue: _selectedLocation ?? 'None Selected',
                        decoration: inputDecoration.copyWith(labelText: 'Location'),
                        readOnly: true,
                        validator: (value) => _selectedLocation == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(draftComponentProvider.notifier).state = {
                            if (_selectedType != null) 'type': _selectedType!,
                            'dnts': _dntsSerialController.text,
                            'mfg': _mfgSerialController.text,
                            'brand': _brandController.text,
                          };
                          ref.read(isLocationPickingModeProvider.notifier).state = true;
                          ref.read(cameraControlProvider.notifier).resetToGlobalOverview();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('SELECT ON MAP'),
                      ),
                    ),
                  ],
                ),
                
                if (_capacityErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _capacityErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 32),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_capacityErrorMessage != null || _isCheckingCapacity) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: _isCheckingCapacity 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            )
                          : const Text('CREATE', style: TextStyle(letterSpacing: 1.0)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}