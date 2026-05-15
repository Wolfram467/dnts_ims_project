import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/bootstrap_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';

// Conditionally import the splash handler
import 'utils/splash_handler_stub.dart' if (dart.library.js_interop) 'utils/splash_handler_web.dart';

void main() {
  // 1. Instant Engine Initialization
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Set UI Orientations (Non-blocking)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 3. Start Heavy Services in Parallel (Do NOT await here)
  final initializationFuture = _initializeServices();

  runApp(
    ProviderScope(
      child: AppInitializer(initFuture: initializationFuture),
    ),
  );
}

/// Orchestrates the background connection to Supabase and Local Storage
Future<void> _initializeServices() async {
  await Future.wait([
    dotenv.load(fileName: "assets/env"),
    Supabase.initialize(
      url: 'https://wycbnxuhzemgkfebzfmz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5Y2JueHVoemVtZ2tmZWJ6Zm16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MDE2MzgsImV4cCI6MjA5MjQ3NzYzOH0.Df5rENWQ8_xwd6tNQG4x68sAR_MxZMqb7tsJPDnGoKA',
    ),
  ]);
}

/// ═══════════════════════════════════════════════════════════════════════════
/// APP INITIALIZER
/// The bridge between the Bootstrap Screen (FCP) and the main Application.
/// ═══════════════════════════════════════════════════════════════════════════
class AppInitializer extends ConsumerWidget {
  final Future<void> initFuture;
  const AppInitializer({super.key, required this.initFuture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        initFuture,
        ref.read(themeProvider.notifier).initializeTheme(),
      ]),
      builder: (context, snapshot) {
        // Once services are ready, transition to the full app
        if (snapshot.connectionState == ConnectionState.done) {
          // Trigger the native HTML splash removal
          if (kIsWeb) {
            handleSplashRemoval();
          }
          return const DNTSApp();
        }

        // Otherwise, keep the DNTS Identity visible (Sub-second FCP)
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BootstrapScreen(),
        );
      },
    );
  }
}

class DNTSApp extends ConsumerWidget {
  const DNTSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'DNTS IMS',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF111827),
        dividerColor: const Color(0xFF374151),
        colorScheme: const ColorScheme.dark().copyWith(
          surface: const Color(0xFF1F2937),
          onSurface: Colors.white,
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
