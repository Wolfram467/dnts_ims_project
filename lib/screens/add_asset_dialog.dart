import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dntsSerialController = TextEditingController();
  final _mfgSerialController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLabId;
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Monitor',
    'Mouse',
    'Keyboard',
    'System Unit',
    'AVR',
    'SSD',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _dntsSerialController.dispose();
    _mfgSerialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final response = await Supabase.instance.client
          .from('locations')
          .select()
          .order('name');

      setState(() {
        _locations = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading locations: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String? _validateDntsSerial(String? value) {
    if (value == null || value.isEmpty) {
      return 'DNTS Serial is required';
    }

    // Validate format: CT1_LAB#_[MR|M|K|SU|AVR|SSD]#
    final regex = RegExp(
      r'^CT1_LAB[1-7]_(MR|M|K|SU|AVR|SSD)\d+$',
      caseSensitive: false,
    );

    if (!regex.hasMatch(value.toUpperCase())) {
      return 'Invalid format. Use: CT1_LAB#_[MR|M|K|SU|AVR|SSD]#';
    }

    return null;
  }

  String? _validateMfgSerial(String? value) {
    if (value == null || value.isEmpty) {
      return 'Manufacturer Serial is required';
    }
    return null;
  }

  Future<bool> _checkDuplicateSerial(String dntsSerial, String mfgSerial) async {
    try {
      final dntsCheck = await Supabase.instance.client
          .from('serialized_assets')
          .select('id')
          .eq('dnts_serial', dntsSerial.toUpperCase())
          .maybeSingle();

      if (dntsCheck != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('DNTS Serial "$dntsSerial" already exists'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return true;
      }

      final mfgCheck = await Supabase.instance.client
          .from('serialized_assets')
          .select('id')
          .eq('mfg_serial', mfgSerial)
          .maybeSingle();

      if (mfgCheck != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Manufacturer Serial "$mfgSerial" already exists'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return true;
      }

      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking duplicates: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLabId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a designated lab'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dntsSerial = _dntsSerialController.text.trim().toUpperCase();
    final mfgSerial = _mfgSerialController.text.trim();

    // Check for duplicates
    final hasDuplicate = await _checkDuplicateSerial(dntsSerial, mfgSerial);
    if (hasDuplicate) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await Supabase.instance.client.from('serialized_assets').insert({
        'dnts_serial': dntsSerial,
        'mfg_serial': mfgSerial,
        'category': _selectedCategory,
        'designated_lab_id': _selectedLabId,
        'current_loc_id': _selectedLabId, // Auto-set to designated lab
        'status': 'Deployed', // Initial status
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asset Commissioned: $dntsSerial'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error commissioning asset: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Commission New Asset',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Colors.black, width: 1),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _dntsSerialController,
                              validator: _validateDntsSerial,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'DNTS Serial',
                                hintText: 'CT1_LAB6_SU1',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _mfgSerialController,
                              validator: _validateMfgSerial,
                              decoration: const InputDecoration(
                                labelText: 'Manufacturer Serial',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value);
                              },
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _selectedLabId,
                              decoration: const InputDecoration(
                                labelText: 'Designated Lab',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              items: _locations.map((loc) {
                                return DropdownMenuItem<String>(
                                  value: loc['id'],
                                  child: Text(loc['name'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedLabId = value);
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notes (Optional)',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'COMMISSION',
                                    style: TextStyle(
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
