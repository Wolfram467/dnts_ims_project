import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_provider.dart';
import '../screens/auth_screen.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isDarkMode = ref.watch(themeProvider);
    final bool isCompact = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACCOUNT SETTINGS',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Section
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: const Icon(Icons.person_outline, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hi, ${user?.email?.split('@').first ?? 'User'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              user?.email?.replaceAll('@dnts.local', '') ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).dividerColor),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text(
                                'MANAGE ACCOUNT',
                                style: TextStyle(
                                  letterSpacing: 1,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Theme Toggle
                      SwitchListTile(
                        value: isDarkMode,
                        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                        title: const Text(
                          'DARK MODE',
                          style: TextStyle(letterSpacing: 1, fontSize: 13),
                        ),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      const Divider(height: 1),

                      // Keyboard Shortcuts (Responsive)
                      if (!isCompact) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'KEYBOARD SHORTCUTS',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildShortcutRow('ESC', 'Close Inspector'),
                        _buildShortcutRow('ARROWS', 'Pan Camera'),
                        _buildShortcutRow('SPACE', 'Reset Camera'),
                        _buildShortcutRow('1 - 7', 'Jump to Lab'),
                        _buildShortcutRow('TAB', 'Next Desk'),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _handleSignOut(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'SIGN OUT',
                    style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade100,
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
