import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_provider.dart';
import 'main_layout.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.validate() == false) return;
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final rawId = _usernameController.text.trim().toUpperCase();
      final supabaseEmail = '$rawId@dnts.local';
      final response = await supabase.auth.signInWithPassword(
        email: supabaseEmail,
        password: _passwordController.text,
      );
      final user = response.user;
      if (user == null) return;
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red.shade700)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLoginBox(BuildContext context, bool isCompact) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 20.0 : 32.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DEPARTMENT OF NETWORK AND TECHNICAL SERVICES',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Technical Assistants Portal',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, letterSpacing: 1.5),
              ),
              SizedBox(height: isCompact ? 16 : 32),
              SizedBox(
                height: 40,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 16 : 24),
              SizedBox(
                width: 280,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('LOGIN', style: TextStyle(letterSpacing: 2.0, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText(BuildContext context, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Built by a Technical Assistant, for Technical Assistants.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        SizedBox(height: isCompact ? 4 : 8),
        Text(
          'Made with Love, Joy, and Hope.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final size = MediaQuery.of(context).size;
    final bool isCompact = size.height < 500;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background/Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.0, 
                      isCompact ? 16.0 : 40.0, 
                      24.0, 
                      isCompact ? 16.0 : 32.0
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 1), // Top Spacer
                        
                        _buildLoginBox(context, isCompact),
                        
                        _buildFooterText(context, isCompact),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
}
