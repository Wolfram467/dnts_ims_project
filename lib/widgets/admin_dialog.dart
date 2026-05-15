import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDialog extends StatefulWidget {
  const AdminDialog({super.key});

  @override
  State<AdminDialog> createState() => _AdminDialogState();
}

class _AdminDialogState extends State<AdminDialog> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'lab_ta';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _createAccount() async {
    final fullName = _fullNameController.text.trim();
    final userText = _usernameController.text.trim();
    final passText = _passwordController.text;
    
    if (fullName.isEmpty || userText.isEmpty || passText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final rawId = userText.toUpperCase();
      final supabaseEmail = '$rawId@dnts.local';
      
      // 1. Create Auth Account
      final response = await supabase.auth.signUp(
        email: supabaseEmail,
        password: passText,
      );

      if (response.user != null) {
        // 2. Update Profile immediately (since trigger might set is_approved to false)
        // We wait a bit for the trigger to finish if it exists
        await Future.delayed(const Duration(seconds: 1));
        
        await supabase.from('profiles').update({
          'full_name': fullName,
          'role': _selectedRole,
          'is_approved': true,
        }).eq('id', response.user!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TA Account created and approved'), backgroundColor: Colors.black87)
        );
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CREATE TA ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (e.g. John Doe)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.copyWith(text: newValue.text.toUpperCase());
                  }),
                ],
                decoration: const InputDecoration(
                  labelText: 'Username (Sticker ID)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Assigned Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
                items: const [
                  DropdownMenuItem(value: 'lab_ta', child: Text('TA Editor (Lab_TA)')),
                  DropdownMenuItem(value: 'ta_admin', child: Text('TA Admin (Super User)')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Temporary Password',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('CREATE & APPROVE'),
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
