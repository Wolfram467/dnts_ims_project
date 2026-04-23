import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'command_center_screen.dart';
import 'inventory_master_screen.dart';
import 'movement_history_screen.dart';
import 'interactive_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('DEBUG: No user ID found');
        setState(() => _isLoading = false);
        return;
      }

      print('DEBUG: Loading profile for user ID: $userId');

      final response = await Supabase.instance.client
          .from('profiles')
          .select('role, is_approved')
          .eq('id', userId)
          .single();

      print('DEBUG: Profile response: $response');

      setState(() {
        _userRole = response['role'] as String?;
        _isLoading = false;
      });

      print('DEBUG: User role set to: $_userRole');
    } catch (e) {
      print('DEBUG: Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Widget _buildHomeTab() {
    final user = Supabase.instance.client.auth.currentUser;

    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DNTS IMS Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'User',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_userRole != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${_getRoleLabel(_userRole!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'LOGOUT',
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
    );
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final isSupremeLeader = _userRole == 'dnts_head';
    print('DEBUG: isSupremeLeader = $isSupremeLeader, _userRole = $_userRole');

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: Colors.black),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
              unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Inventory'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                if (isSupremeLeader)
                  const NavigationRailDestination(
                    icon: Icon(Icons.admin_panel_settings_outlined),
                    selectedIcon: Icon(Icons.admin_panel_settings),
                    label: Text('Command Center'),
                  ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _selectedIndex == 0
                ? _buildHomeTab()
                : _selectedIndex == 1
                    ? InteractiveMapScreen(userRole: _userRole ?? 'viewer')
                    : _selectedIndex == 2
                        ? const MovementHistoryScreen()
                        : isSupremeLeader && _selectedIndex == 3
                            ? const CommandCenterScreen()
                            : _buildHomeTab(),
          ),
        ],
      ),
    );
  }
}
