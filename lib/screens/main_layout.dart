import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/map_state_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/create_component_panel.dart';
import '../models/hardware_component.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'interactive_map_screen.dart';
import 'admin_dashboard_screen.dart';

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
    _handleInitialTab();
  }

  void _handleInitialTab() {
    final tab = Uri.base.queryParameters['tab']?.toLowerCase();
    if (tab == null) return;

    final Map<String, int> tabMapping = {
      'dashboard': 0,
      'inventory': 1,
      'history': 2,
      'network': 3,
      'schedule': 4,
      'sit-in': 5,
      'violation': 6,
      'energy': 7,
    };

    if (tabMapping.containsKey(tab)) {
      setState(() {
        selectedIndex = tabMapping[tab]!;
      });
    }
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
        return InteractiveMapScreen(userRole: _userRole ?? 'lab_ta');
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

  Future<void> _submitCreation() async {
    final formKey = ref.read(creationFormKeyProvider);
    if (formKey.currentState?.validate() != true) return;
    
    final draft = ref.read(draftComponentProvider);
    final selectedType = ref.read(selectedCreationTypeProvider);
    final location = ref.read(activeDeskProvider);
    final capacityError = ref.read(creationCapacityErrorProvider);
    final isChecking = ref.read(isCheckingCapacityProvider);

    if (selectedType == null || location == null) return;
    if (capacityError != null || isChecking) return;

    final newComponent = HardwareComponent(
      category: selectedType,
      dntsSerial: draft['dnts']?.trim() ?? '',
      mfgSerial: draft['mfg']?.trim() ?? '',
      brand: draft['brand']?.trim() ?? '',
      dateAcquired: (draft['date']?.trim().isEmpty ?? true) ? null : draft['date']!.trim(),
      status: location == 'Storage' ? 'Storage' : 'Deployed',
    );

    final inventoryManager = ref.read(inventoryManagerProvider);
    final result = await inventoryManager.createComponent(location, newComponent);

    result.fold(
      (success) {
        ref.read(draftComponentProvider.notifier).state = {};
        ref.read(refreshTriggerProvider.notifier).state++;
        ref.invalidate(activeDeskComponentsProvider);
        ref.read(isCreationModeProvider.notifier).state = false;
        ref.read(selectedCreationTypeProvider.notifier).state = null;
      },
      (failure) {
        ref.read(creationCapacityErrorProvider.notifier).state = failure.toString().replaceAll('Exception: ', '');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final isAdmin = _userRole == 'ta_admin' || _userRole == 'dnts_head';
    final isCreationMode = ref.watch(isCreationModeProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Row(
            children: [
              // ── Navigation Rail ──────────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (index) =>
                              setState(() => selectedIndex = index),
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          groupAlignment: -1.0,
                          minWidth: 56,
                          selectedIconTheme: IconThemeData(
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          selectedLabelTextStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                          unselectedIconTheme: IconThemeData(
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          unselectedLabelTextStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: () {
                                ref.read(refreshTriggerProvider.notifier).state++;
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
                                    if (isAdmin) ...[
                                      IconButton(
                                        icon: const Icon(Icons.admin_panel_settings_outlined),
                                        tooltip: 'Admin Portal',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    IconButton(
                                      icon: Icon(Icons.account_circle_outlined, color: Colors.grey.shade500),
                                      tooltip: 'Account & Settings',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => const SettingsDialog(),
                                        );
                                      },
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
                      ),
                    ),
                  );
                },
              ),

              // Divider
              const VerticalDivider(thickness: 1, width: 1),

              // ── Viewport ─────────────────────────────────────────────────────
              Expanded(child: _buildViewport()),
            ],
          ),
          
          // PINNED CREATION BUTTON
          if (isCreationMode)
            Positioned(
              left: 57, // Flush against Navigation Rail + Divider
              top: (MediaQuery.of(context).size.height - 400) / 2,
              child: Material(
                color: const Color(0xFF00E676), // Carbon Mint
                elevation: 4,
                child: InkWell(
                  onTap: _submitCreation,
                  child: const SizedBox(
                    width: 60,
                    height: 400,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
