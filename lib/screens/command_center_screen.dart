import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  
  // Track selected role for each user
  final Map<String, String> _selectedRoles = {};

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      setState(() {
        _pendingUsers = List<Map<String, dynamic>>.from(response);
        // Initialize selected roles to 'viewer' for each user
        for (var user in _pendingUsers) {
          final userId = user['id'];
          _selectedRoles[userId] ??= 'viewer';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending users: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _approveUser(String userId, String selectedRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'is_approved': true,
            'role': selectedRole,
          })
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User access granted'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reload the list
      _loadPendingUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'dnts_head':
        return 'Supreme Leader';
      case 'lab_ta':
        return 'Editor';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Command Center',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPendingUsers,
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pending Access Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _pendingUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No pending requests',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _pendingUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final user = _pendingUsers[index];
                              final fullName = user['full_name'] ?? 'Unknown';
                              final userId = user['id'];
                              final selectedRole = _selectedRoles[userId] ?? 'viewer';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Role Selector
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        value: selectedRole,
                                        decoration: const InputDecoration(
                                          labelText: 'Assign Role',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'viewer',
                                            child: Text('Viewer'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'lab_ta',
                                            child: Text('Editor'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedRoles[userId] = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Grant Access Button
                                    SizedBox(
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: () => _approveUser(userId, selectedRole),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'GRANT ACCESS',
                                          style: TextStyle(
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
