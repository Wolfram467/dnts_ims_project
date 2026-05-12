import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'data/lab_data_generator.dart';

import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Supabase.initialize(
    url: 'https://wycbnxuhzemgkfebzfmz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5Y2JueHVoemVtZ2tmZWJ6Zm16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MDE2MzgsImV4cCI6MjA5MjQ3NzYzOH0.Df5rENWQ8_xwd6tNQG4x68sAR_MxZMqb7tsJPDnGoKA',
  );

  // Initialize the provider container to load theme state before app start
  final container = ProviderContainer();
  await container.read(themeProvider.notifier).initializeTheme();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DNTSApp(),
    ),
  );
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
