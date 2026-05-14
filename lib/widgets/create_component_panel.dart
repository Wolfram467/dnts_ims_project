import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/hardware_component.dart';
import '../providers/repository_providers.dart';
import '../providers/map_state_provider.dart';
import '../providers/service_providers.dart';
import 'serial_scanner_overlay.dart';

class CreateComponentPanel extends ConsumerStatefulWidget {
  final String? initialLocation;
  const CreateComponentPanel({super.key, this.initialLocation});

  @override
  ConsumerState<CreateComponentPanel> createState() => _CreateComponentPanelState();
}

class _CreateComponentPanelState extends ConsumerState<CreateComponentPanel> {
  final _formKey = GlobalKey<FormState>();

  final _dntsSerialController = TextEditingController();
  final _mfgSerialController = TextEditingController();
  final _brandController = TextEditingController();
  final _dateAcquiredController = TextEditingController();
  String? _selectedLocation;

  bool _isCheckingCapacity = false;
  String? _capacityErrorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? ref.read(activeDeskProvider) ?? 'Storage';
    
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

  void _autoFillDntsSerial(String? type) {
    if (_selectedLocation == null || _selectedLocation == 'Storage' || type == null) {
      return;
    }

    final match = RegExp(r'L(?:ab)?(\d+)_[a-zA-Z]*(\d+)', caseSensitive: false).firstMatch(_selectedLocation!);
    if (match == null) return;

    final labNumber = match.group(1);
    final deskNumber = match.group(2);

    String categoryAbbr = '';
    switch (type) {
      case 'Monitor': categoryAbbr = 'MR'; break;
      case 'Mouse': categoryAbbr = 'M'; break;
      case 'Keyboard': categoryAbbr = 'K'; break;
      case 'System Unit': categoryAbbr = 'SU'; break;
      case 'AVR': categoryAbbr = 'AVR'; break;
      case 'SSD': categoryAbbr = 'SSD'; break;
      default: return;
    }

    _dntsSerialController.text = 'CT1_LAB${labNumber}_$categoryAbbr$deskNumber';
  }

  Future<void> _validateCapacity() async {
    final selectedType = ref.read(selectedCreationTypeProvider);
    if (_selectedLocation == null || selectedType == null) {
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
    final result = await inventoryManager.validateCapacity(_selectedLocation!, selectedType);

    if (mounted) {
      setState(() {
        _isCheckingCapacity = false;
        result.fold(
          (success) { _capacityErrorMessage = null; },
          (failure) { _capacityErrorMessage = failure.toString().replaceAll('Exception: ', ''); },
        );
      });
    }
  }

  Future<void> _startScanning(TextEditingController targetController) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan serial numbers')),
        );
      }
      return;
    }

    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const SerialScannerOverlay()),
    );

    if (imagePath != null && mounted) {
      ref.read(isScanningProvider.notifier).state = true;
      final scannerService = ref.read(serialScannerServiceProvider);
      
      final result = await scannerService.extractSerialNumber(imagePath);
      
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
        if (result != null) {
          setState(() {
            targetController.text = result;
          });
        } else {
          SystemSound.play(SystemSoundType.alert);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not detect serial number. Please try again or enter manually.')),
          );
        }
      }
    }
  }

  Future<void> _submit() async {
    final selectedType = ref.read(selectedCreationTypeProvider);
    if (selectedType == null) {
      setState(() => _capacityErrorMessage = "Please select a type in the sidebar");
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_capacityErrorMessage != null || _isCheckingCapacity) return;

    final newComponent = HardwareComponent(
      category: selectedType,
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
          _closeCreation();
        },
        (failure) {
          setState(() {
            _capacityErrorMessage = failure.toString().replaceAll('Exception: ', '');
          });
        },
      );
    }
  }

  void _closeCreation() {
    ref.read(isCreationModeProvider.notifier).state = false;
    ref.read(selectedCreationTypeProvider.notifier).state = null;
    ref.read(draftComponentProvider.notifier).state = {};
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scaleFactor = (screenSize.height / 800.0).clamp(0.5, 1.2);
    
    final double buttonHeight = 600.0 * scaleFactor;
    final double buttonWidth = 120.0 * scaleFactor;
    final double sideMargin = 60.0 * scaleFactor;

    final double scaledPadding = 24.0 * scaleFactor;
    final double scaledSpacing = 16.0 * scaleFactor;

    final selectedType = ref.watch(selectedCreationTypeProvider);
    final activeDeskId = ref.watch(activeDeskProvider);
    final isInspectorOpen = ref.watch(inspectorStateProvider);
    final isScanning = ref.watch(isScanningProvider);

    // ADAPTIVE POSITIONING for FORM PANEL
    final double inspectorPanelWidth = screenSize.width * 0.4;
    final double panelWidth = 760 * scaleFactor;

    double panelRightPosition;
    if (isInspectorOpen && activeDeskId != null) {
      // Side-by-side with Inspector
      panelRightPosition = inspectorPanelWidth;
    } else {
      // Centered in full viewport
      panelRightPosition = (screenSize.width / 2) - (panelWidth / 2);
    }

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
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16 * scaleFactor, 
        vertical: 12 * scaleFactor
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(fontSize: 14 * scaleFactor),
    );

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          // THE FORM PANEL (ADAPTIVE POSITIONING)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            right: panelRightPosition,
            top: (screenSize.height - buttonHeight) / 2,
            child: Container(
              width: panelWidth,
              height: buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Redundant Header Removed
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(scaledPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Column 1
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: _dntsSerialController,
                                          style: TextStyle(fontSize: 14 * scaleFactor),
                                          decoration: inputDecoration.copyWith(
                                            labelText: isScanning ? 'Scanning...' : 'DNTS Serial',
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.camera_alt, size: 20 * scaleFactor),
                                              onPressed: isScanning ? null : () => _startScanning(_dntsSerialController),
                                              tooltip: 'Scan DNTS Sticker',
                                            ),
                                          ),
                                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                        ),
                                        SizedBox(height: scaledSpacing),
                                        TextFormField(
                                          controller: _mfgSerialController,
                                          style: TextStyle(fontSize: 14 * scaleFactor),
                                          decoration: inputDecoration.copyWith(
                                            labelText: isScanning ? 'Scanning...' : 'Mfg Serial',
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.camera_alt, size: 20 * scaleFactor),
                                              onPressed: isScanning ? null : () => _startScanning(_mfgSerialController),
                                              tooltip: 'Scan Serial Number',
                                            ),
                                          ),
                                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: scaledSpacing),
                                  // Column 2
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: _brandController,
                                          style: TextStyle(fontSize: 14 * scaleFactor),
                                          decoration: inputDecoration.copyWith(labelText: 'Brand'),
                                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                        ),
                                        SizedBox(height: scaledSpacing),
                                        TextFormField(
                                          controller: _dateAcquiredController,
                                          style: TextStyle(fontSize: 14 * scaleFactor),
                                          decoration: inputDecoration.copyWith(
                                            labelText: 'Date (Optional)',
                                            suffixIcon: Icon(Icons.calendar_today, size: 18 * scaleFactor),
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
                                                _dateAcquiredController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (_capacityErrorMessage != null)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: scaledSpacing / 2),
                                child: Text(
                                  _capacityErrorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red, fontSize: 11 * scaleFactor),
                                ),
                              ),
                              
                            TextFormField(
                              key: ValueKey(_selectedLocation),
                              initialValue: _selectedLocation ?? 'None',
                              style: TextStyle(fontSize: 14 * scaleFactor),
                              decoration: inputDecoration.copyWith(
                                labelText: 'Location',
                                suffixIcon: InkWell(
                                  onTap: () {
                                    // Save current progress
                                    ref.read(draftComponentProvider.notifier).state = {
                                      'dnts': _dntsSerialController.text,
                                      'mfg': _mfgSerialController.text,
                                      'brand': _brandController.text,
                                      'date': _dateAcquiredController.text,
                                    };
                                    
                                    ref.read(isLocationPickingModeProvider.notifier).state = true;
                                    ref.read(isCreationModeProvider.notifier).state = false; // Hide panel while picking
                                    ref.read(inspectorStateProvider.notifier).closeInspector(); // UNBLOCK MAP
                                    ref.read(cameraControlProvider.notifier).resetToGlobalOverview();
                                  },
                                  child: Icon(Icons.map, size: 20 * scaleFactor),
                                ),
                              ),
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // CLOSE BUTTON (Bottom Alignment with Inspector)
                    // HIDE if Inspector is open because Inspector will handle sequential close
                    if (!isInspectorOpen)
                      SizedBox(
                        height: 56 * scaleFactor,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _closeCreation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                          ),
                          child: Text(
                            'CLOSE CREATION',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5 * scaleFactor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // DYNAMIC POSITIONING: Attach to the left edge of the form panel (Overlaying it)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            right: panelRightPosition + panelWidth - (8 * scaleFactor), // Overlap by 8px
            top: (screenSize.height - buttonHeight) / 2,
            child: Material(
              color: const Color(0xFF00E676), // Carbon Mint
              borderRadius: BorderRadius.zero, 
              elevation: 8, // Give it its own shadow to pop over the panel
              child: InkWell(
                onTap: (_capacityErrorMessage != null || _isCheckingCapacity) ? null : _submit,
                child: SizedBox(
                  width: buttonWidth, 
                  height: buttonHeight, 
                  child: Center(
                    child: _isCheckingCapacity 
                      ? SizedBox(
                          width: 32 * scaleFactor,
                          height: 32 * scaleFactor,
                          child: const CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                        )
                      : RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'Create',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              fontSize: 32 * scaleFactor, 
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
