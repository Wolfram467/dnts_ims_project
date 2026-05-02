import 'package:flutter/material.dart';
import '../utils/workstation_storage.dart';

/// ============================================================================
/// COMPONENT EDIT DIALOG
/// ============================================================================
/// Dialog for editing component details:
/// - DNTS Serial Number (with validation)
/// - Manufacturer Serial Number
/// - Status (dropdown)
/// ============================================================================

class ComponentEditDialog extends StatefulWidget {
  final String workstationId;
  final Map<String, dynamic> component;
  final VoidCallback onSaved;

  const ComponentEditDialog({
    super.key,
    required this.workstationId,
    required this.component,
    required this.onSaved,
  });

  @override
  State<ComponentEditDialog> createState() => _ComponentEditDialogState();
}

class _ComponentEditDialogState extends State<ComponentEditDialog> {
  late TextEditingController _dntsController;
  late TextEditingController _mfgController;
  late String _selectedStatus;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _dntsError;

  // Valid statuses
  static const List<String> validStatuses = [
    'Deployed',
    'Under Maintenance',
    'Borrowed',
    'Storage',
    'Retired',
  ];

  @override
  void initState() {
    super.initState();
    _dntsController = TextEditingController(
      text: widget.component['dnts_serial'] ?? '',
    );
    _mfgController = TextEditingController(
      text: widget.component['mfg_serial'] ?? '',
    );
    _selectedStatus = widget.component['status'] ?? 'Deployed';
  }

  @override
  void dispose() {
    _dntsController.dispose();
    _mfgController.dispose();
    super.dispose();
  }

  /// Validate DNTS serial format and uniqueness
  Future<bool> _validateDntsSerial(String value) async {
    // Check format
    if (!WorkstationStorage.isValidDntsSerial(value)) {
      setState(() {
        _dntsError = 'Invalid format. Expected: CT1_LAB#_[MR|M|K|SU|SSD|AVR]##';
      });
      return false;
    }

    // Check uniqueness within the lab
    final isUnique = await WorkstationStorage.isDntsSerialUnique(
      value,
      widget.workstationId,
      widget.component['category'],
    );

    if (!isUnique) {
      setState(() {
        _dntsError = 'This DNTS serial already exists in this lab';
      });
      return false;
    }

    setState(() {
      _dntsError = null;
    });
    return true;
  }

  /// Save changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dntsSerial = _dntsController.text.trim();

    // Validate DNTS serial
    final isValid = await _validateDntsSerial(dntsSerial);
    if (!isValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Create updated component
    final updatedComponent = Map<String, dynamic>.from(widget.component);
    updatedComponent['dnts_serial'] = dntsSerial;
    updatedComponent['mfg_serial'] = _mfgController.text.trim();
    updatedComponent['status'] = _selectedStatus;

    // Save to storage
    final success = await WorkstationStorage.updateComponent(
      widget.workstationId,
      widget.component['category'],
      updatedComponent,
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${widget.component['category']} updated successfully'),
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
                    'Edit ${widget.component['category']}',
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
                widget.workstationId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              // DNTS Serial Number
              TextFormField(
                controller: _dntsController,
                decoration: InputDecoration(
                  labelText: 'DNTS Serial Number',
                  hintText: 'CT1_LAB5_MR01',
                  errorText: _dntsError,
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
                  if (_dntsError != null) {
                    setState(() {
                      _dntsError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Manufacturer Serial Number
              TextFormField(
                controller: _mfgController,
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
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.info_outline),
                ),
                items: validStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
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
                    child: _isSaving
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
