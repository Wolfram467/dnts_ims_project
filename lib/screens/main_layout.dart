import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/map_state_provider.dart';
import '../providers/theme_provider.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'interactive_map_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
              child: InkWell(
                onTap: () {
                  // Increment global refresh trigger
                  ref.read(refreshTriggerProvider.notifier).state++;
                  // Reset map camera to global overview
                  ref.read(cameraControlProvider.notifier).fitAllLabs();
                },
                mouseCursor: SystemMouseCursors.click,
                child: Column(
                  children: [
                    Text(
                      'DNTS',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(width: 24, height: 1, color: Theme.of(context).colorScheme.onSurface),
                  ],
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          ref.watch(themeProvider) ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.grey.shade500,
                        ),
                        tooltip: 'Toggle Theme',
                        onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.grey.shade500),
                        tooltip: 'Logout',
                        onPressed: _handleLogout,
                      ),
                    ],
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
