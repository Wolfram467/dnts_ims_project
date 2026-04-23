import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wycbnxuhzemgkfebzfmz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5Y2JueHVoemVtZ2tmZWJ6Zm16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MDE2MzgsImV4cCI6MjA5MjQ3NzYzOH0.Df5rENWQ8_xwd6tNQG4x68sAR_MxZMqb7tsJPDnGoKA',
  );

  runApp(const ProviderScope(child: DNTSApp()));
}

class DNTSApp extends StatelessWidget {
  const DNTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNTS IMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AuthScreen(),
    );
  }
}
