import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/serial_scanner_service.dart';

/// Provider for the SerialScannerService.
/// Note: In a real production app, the API key would be fetched from 
/// a secure environment variable or a remote config service.
final serialScannerServiceProvider = Provider<SerialScannerService>((ref) {
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return SerialScannerService(geminiApiKey);
});

/// State provider to track if an OCR operation is currently in progress.
final isScanningProvider = StateProvider<bool>((ref) => false);
