import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'interactive_map_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      setState(() {
        _userRole = response['role'] as String?;
        _isLoading = false;
      });
    } catch (_) {
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

  Widget _buildViewport() {
    switch (selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return InteractiveMapScreen(userRole: _userRole ?? 'viewer');
      default:
        return const Center(
          child: Text(
            'Module Coming Soon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────────────────
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: Colors.black),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text(
                    'DNTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 24, height: 1, color: Colors.black),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: Icon(Icons.logout, color: Colors.grey.shade500),
                    tooltip: 'Logout',
                    onPressed: _handleLogout,
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.router_outlined),
                selectedIcon: Icon(Icons.router),
                label: Text('Network'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Schedule'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_seat_outlined),
                selectedIcon: Icon(Icons.event_seat),
                label: Text('Sit-In'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.gavel_outlined),
                selectedIcon: Icon(Icons.gavel),
                label: Text('Violation'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.electric_bolt_outlined),
                selectedIcon: Icon(Icons.electric_bolt),
                label: Text('Energy'),
              ),
            ],
          ),

          // Divider
          const VerticalDivider(thickness: 1, width: 1),

          // ── Viewport ─────────────────────────────────────────────────────
          Expanded(child: _buildViewport()),
        ],
      ),
    );
  }
}
