import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class SerialScannerService {
  final GenerativeModel _model;

  SerialScannerService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemma-4-26b-a4b-it', // Specific high-quota identifier provided by user
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// Processes an image and extracts the manufacturer serial number.
  /// Uses Gemma 4 26B for high-volume agentic reasoning.
  Future<String?> extractSerialNumber(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      
      final prompt = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(
            'Act as a Hardware Logistics Intelligence Agent. '
            'Your objective is to locate and extract the Manufacturer Serial Number (S/N) from this image. '
            '<agentic_thinking_process> '
            '1. OBSERVE: Scan the sticker for all alphanumeric strings. '
            '2. CONTEXTUALIZE: Identify labels like S/N, Serial No, SN, MAC, P/N, REV, and Model Name. '
            '3. FILTER: Ignore the MAC address (formatted as XX:XX:XX or XXXXXXXXXXXX), Model Names (like V530S), and Part Numbers (P/N). '
            '4. VALIDATE: Industrial serial numbers are typically 8-15 characters long, often alphanumeric, and located near a barcode. '
            '5. DECISION: If a string is explicitly prefixed with "S/N" or "Serial", prioritize it. '
            '</agentic_thinking_process> '
            'Return valid JSON: {"serial_number": "[EXTRACTED_CODE]"} or {"serial_number": "NOT_FOUND"}.'
          ),
        ]),
      ];

      final response = await _model.generateContent(prompt);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return "DEBUG_ERROR: Empty response from AI";
      }

      // Clean markdown formatting if present
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> jsonResponse = jsonDecode(cleanedText);
      final serial = jsonResponse['serial_number']?.toString().trim();

      if (serial == null || serial == 'NOT_FOUND' || serial.isEmpty) {
        return "DEBUG_ERROR: Agent could not isolate S/N";
      }

      return serial;
    } catch (exception) {
      return 'DEBUG_ERROR: $exception';
    }
  }
}
