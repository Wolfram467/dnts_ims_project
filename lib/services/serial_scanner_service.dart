import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

enum ScanType { dnts, manufacturer }

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

  /// Processes an image and extracts the DNTS serial number or a full Component payload.
  /// Uses Gemma 4 26B for high-volume agentic reasoning.
  Future<Map<String, String>?> extractData(String imagePath, {ScanType scanType = ScanType.manufacturer}) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      
      final String instructionPrompt = scanType == ScanType.dnts 
          ? 'Act as a Hardware Logistics Intelligence Agent. '
            'Your objective is to locate and extract the internal "DNTS Serial Number" (Asset Tag) from this image. '
            '<agentic_thinking_process> '
            '1. OBSERVE: Scan the sticker for all alphanumeric strings. DNTS stickers are usually separate from the main manufacturer label. '
            '2. CONTEXTUALIZE: Look for patterns that resemble "CT1_LAB", "CT1-LAB", or contain "LAB", "MR", "M", "K", "SU", "AVR", "SSD". '
            '3. FILTER: Ignore standard manufacturer serial numbers, MAC addresses, and part numbers. '
            '4. FORMAT AWARENESS: Be aware that the formatting might vary (e.g., "CT1 LAB 6 SU 01", "LAB6-MR1", "CT1_LAB6_SU1"). Extract exactly what is printed. '
            '5. DECISION: Extract the string that most closely matches the school\'s asset tracking identifier. '
            '</agentic_thinking_process> '
            'Return valid JSON: {"dnts_serial": "[EXTRACTED_CODE]"} or {"dnts_serial": "NOT_FOUND"}.'
          : 'Act as a Hardware Logistics Intelligence Agent. '
            'Analyze the provided image of a hardware label/device and extract the following: '
            '<agentic_thinking_process> '
            '1. SERIAL: Locate the Manufacturer Serial Number (S/N, Serial No). Ignore MAC addresses or P/N. '
            '2. BRAND: Identify the manufacturer brand (e.g., Dell, HP, Lenovo, Acer, Samsung). Look for logos or text like "Manufactured by...". '
            '3. CATEGORY: Infer the type of device from the label or visual shape. Must be strictly one of: [Monitor, Mouse, Keyboard, System Unit, AVR, SSD]. '
            '</agentic_thinking_process> '
            'Return valid JSON: {"mfg_serial": "...", "brand": "...", "category": "..."}. If a field cannot be found, return empty string for that field.';

      final prompt = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(instructionPrompt),
        ]),
      ];

      final response = await _model.generateContent(prompt);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return null;
      }

      // Clean markdown formatting if present
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> jsonResponse = jsonDecode(cleanedText);
      
      final Map<String, String> result = {};
      jsonResponse.forEach((key, value) {
        result[key] = value?.toString().trim() ?? '';
      });

      return result;
    } catch (exception) {
      print('DEBUG_ERROR: $exception');
      return null;
    }
  }
}
