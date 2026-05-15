import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/repository_providers.dart';
import '../providers/map_state_provider.dart';
import '../providers/service_providers.dart';
import '../models/hardware_component.dart';
import 'serial_scanner_overlay.dart';

/// ============================================================================
/// COMPONENT EDIT DIALOG
/// ============================================================================
/// Dialog for editing component details:
/// - DNTS Serial Number (with validation)
/// - Manufacturer Serial Number
/// - Status (dropdown)
/// ============================================================================

class ComponentEditDialog extends ConsumerStatefulWidget {
  final String workstationIdentifier;
  final HardwareComponent component;
  final VoidCallback onSaved;

  const ComponentEditDialog({
    super.key,
    required this.workstationIdentifier,
    required this.component,
    required this.onSaved,
  });

  @override
  ConsumerState<ComponentEditDialog> createState() => _ComponentEditDialogState();
}

class _ComponentEditDialogState extends ConsumerState<ComponentEditDialog> {
  late TextEditingController _dntsSerialNumberController;
  late TextEditingController _manufacturingSerialNumberController;
  late String _selectedDeploymentStatus;

  final _formKey = GlobalKey<FormState>();
  bool _isSavingInProgress = false;
  String? _dntsSerialNumberErrorText;

  // Valid statuses
  final List<String> _deploymentStatuses = [
    'Deployed',
    'Borrowed',
    'Under Maintenance',
    'Storage',
    'Retired',
  ];

  @override
  void initState() {
    super.initState();
    _dntsSerialNumberController = TextEditingController(
      text: widget.component.dntsSerial,
    );
    _manufacturingSerialNumberController = TextEditingController(
      text: widget.component.mfgSerial,
    );
    
    // Safe Status Mapping logic
    final rawStatus = widget.component.status;
    
    // Find matching status case-insensitively, or default to 'Deployed'
    final matchedStatus = _deploymentStatuses.firstWhere(
      (status) => status.toLowerCase() == rawStatus.toLowerCase(),
      orElse: () => 'Deployed',
    );
    
    _selectedDeploymentStatus = matchedStatus;
  }

  @override
  void dispose() {
    _dntsSerialNumberController.dispose();
    _manufacturingSerialNumberController.dispose();
    super.dispose();
  }

  /// Validate DNTS serial format and uniqueness
  Future<bool> _validateDntsSerialNumber(String serialNumber) async {
    final repository = ref.read(workstationRepositoryProvider);

    // Check format
    final bool isFormatValid = repository.isValidDntsSerialNumber(serialNumber);
    if (isFormatValid == false) {
      setState(() {
        _dntsSerialNumberErrorText = 'Invalid format. Expected: CT1_LAB#_[MR|M|K|SU|SSD|AVR]##';
      });
      return false;
    }

    // Check uniqueness within the lab
    final isSerialNumberUnique = await repository.isDntsSerialNumberUnique(
      serialNumber,
      widget.workstationIdentifier,
      widget.component.category,
    );

    if (isSerialNumberUnique == false) {
      setState(() {
        _dntsSerialNumberErrorText = 'This DNTS serial already exists in this lab';
      });
      return false;
    }

    setState(() {
      _dntsSerialNumberErrorText = null;
    });
    return true;
  }

  Future<void> _startScanning() async {
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
      
      final result = await scannerService.extractData(imagePath);
      
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
        if (result != null && result['mfg_serial'] != null && result['mfg_serial']!.isNotEmpty) {
          setState(() {
            _manufacturingSerialNumberController.text = result['mfg_serial']!;
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

  /// Save changes
  Future<void> _saveChanges() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }
    
    final bool isFormValid = formState.validate();
    if (isFormValid == false) {
      return;
    }

    final dntsSerialNumber = _dntsSerialNumberController.text.trim();

    // Validate DNTS serial
    final isSerialNumberValid = await _validateDntsSerialNumber(dntsSerialNumber);
    if (isSerialNumberValid == false) {
      return;
    }

    setState(() {
      _isSavingInProgress = true;
    });

    // Create updated component
    final updatedComponent = widget.component.copyWith(
      dntsSerial: dntsSerialNumber,
      mfgSerial: _manufacturingSerialNumberController.text.trim(),
      status: _selectedDeploymentStatus,
    );

    // Save to storage
    final wasUpdateSuccessful = await ref.read(workstationRepositoryProvider).updateWorkstationComponent(
      widget.workstationIdentifier,
      widget.component.dntsSerial,
      updatedComponent,
    );

    setState(() {
      _isSavingInProgress = false;
    });

    if (wasUpdateSuccessful) {
      final bool isComponentMounted = mounted;
      if (isComponentMounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${widget.component.category} updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Notify parent to refresh
        ref.read(refreshTriggerProvider.notifier).state++;
        widget.onSaved();

        // Close dialog
        Navigator.of(context).pop();
      }
    } else {
      final bool isComponentMounted = mounted;
      if (isComponentMounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to save changes'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _retireComponent() async {
    setState(() {
      _selectedDeploymentStatus = 'Retired';
    });
    await _saveChanges();
  }

  Future<void> _deleteComponent() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Delete Component'),
          content: const Text('Are you sure you want to delete this component?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                foregroundColor: Colors.black,
              ),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isSavingInProgress = true;
      });

      final wasDeleteSuccessful = await ref.read(workstationRepositoryProvider)
          .deleteWorkstationComponent(widget.workstationIdentifier, widget.component.category);

      setState(() {
        _isSavingInProgress = false;
      });

      if (wasDeleteSuccessful) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${widget.component.category} deleted successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          ref.read(refreshTriggerProvider.notifier).state++;
          widget.onSaved();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to delete component'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 1),
    );

    final isScanning = ref.watch(isScanningProvider);

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${widget.component.category}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.workstationIdentifier,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              // DNTS Serial Number
              TextFormField(
                controller: _dntsSerialNumberController,
                decoration: inputDecoration.copyWith(
                  labelText: 'DNTS Serial Number',
                  hintText: 'CT1_LAB5_MR01',
                  errorText: _dntsSerialNumberErrorText,
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'DNTS serial is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Clear error when user types
                  if (_dntsSerialNumberErrorText != null) {
                    setState(() {
                      _dntsSerialNumberErrorText = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Manufacturer Serial Number
              TextFormField(
                controller: _manufacturingSerialNumberController,
                decoration: inputDecoration.copyWith(
                  labelText: isScanning ? 'Scanning...' : 'Manufacturer Serial Number',
                  hintText: 'Enter manufacturer serial',
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: isScanning ? null : _startScanning,
                    tooltip: 'Scan Serial Number',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Manufacturer serial is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDeploymentStatus,
                decoration: inputDecoration.copyWith(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.info_outline),
                ),
                items: _deploymentStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDeploymentStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side Actions
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSavingInProgress ? null : _deleteComponent,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('DELETE'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _isSavingInProgress ? null : _retireComponent,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('RETIRE'),
                      ),
                    ],
                  ),
                  
                  // Right Side Actions
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSavingInProgress ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSavingInProgress ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: _isSavingInProgress
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('SAVE CHANGES', style: TextStyle(letterSpacing: 1.0)),
                      ),
                    ],
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
