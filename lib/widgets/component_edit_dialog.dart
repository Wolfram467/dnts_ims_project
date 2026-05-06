import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../models/hardware_component.dart';

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
  static const List<String> _validDeploymentStatuses = [
    'Deployed',
    'Under Maintenance',
    'Borrowed',
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
    _selectedDeploymentStatus = widget.component.status;
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
    if (!repository.isValidDntsSerialNumber(serialNumber)) {
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

    if (!isSerialNumberUnique) {
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

  /// Save changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dntsSerialNumber = _dntsSerialNumberController.text.trim();

    // Validate DNTS serial
    final isSerialNumberValid = await _validateDntsSerialNumber(dntsSerialNumber);
    if (!isSerialNumberValid) {
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
      widget.component.category,
      updatedComponent,
    );

    setState(() {
      _isSavingInProgress = false;
    });

    if (wasUpdateSuccessful) {
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${widget.component.category} updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Notify parent to refresh
        widget.onSaved();

        // Close dialog
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                decoration: InputDecoration(
                  labelText: 'DNTS Serial Number',
                  hintText: 'CT1_LAB5_MR01',
                  errorText: _dntsSerialNumberErrorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Manufacturer Serial Number',
                  hintText: 'Enter manufacturer serial',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.tag),
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
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.info_outline),
                ),
                items: _validDeploymentStatuses.map((status) {
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
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSavingInProgress ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSavingInProgress ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
