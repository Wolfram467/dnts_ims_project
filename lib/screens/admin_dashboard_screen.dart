import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/admin_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);
      
      setState(() {
        _accounts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching accounts: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount(String id, String email) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE ACCOUNT'),
        content: Text('Are you sure you want to delete account for $email?\nThis will remove their profile record.'),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile deleted successfully')),
        );
        _fetchAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'ta_admin':
      case 'dnts_head':
        return 'TA ADMIN';
      case 'lab_ta':
        return 'TA EDITOR';
      default:
        return role.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TA ACCESS MANAGEMENT', style: TextStyle(letterSpacing: 2.0, fontSize: 14)),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).dividerColor, height: 1.0),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(32.0),
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('TA NAME')),
                    DataColumn(label: Text('DNTS EMAIL')),
                    DataColumn(label: Text('ROLE')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: _accounts.map((account) {
                    final String id = account['id']?.toString() ?? '';
                    final String name = account['full_name']?.toString() ?? 'N/A';
                    final String email = account['email']?.toString().toUpperCase() ?? 'N/A';
                    final String role = _getRoleLabel(account['role']?.toString() ?? '');
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(name)),
                        DataCell(Text(email)),
                        DataCell(Text(role)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _deleteAccount(id, email),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AdminDialog(),
          );
          _fetchAccounts();
        },
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        label: const Text('NEW TA ACCOUNT', style: TextStyle(letterSpacing: 1.0)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
