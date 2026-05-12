import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CAMERA STATE PERSISTENCE SERVICE
// Saves and restores camera position, zoom level, and active desk state
// ═══════════════════════════════════════════════════════════════════════════

class CameraStateService {
  static const String _cameraStateKey = 'map_camera_state';
  static const String _activeDeskKey = 'map_active_desk';

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save camera transformation matrix to localStorage
  static Future<void> saveCameraState(Matrix4 matrix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert Matrix4 to List<double> for storage
      final matrixList = matrix.storage.toList();
      final jsonString = jsonEncode(matrixList);
      
      await prefs.setString(_cameraStateKey, jsonString);
      print('💾 Camera state saved');
    } catch (e) {
      print('❌ Error saving camera state: $e');
    }
  }

  /// Save active desk ID to localStorage
  static Future<void> saveActiveDeskState(String? deskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (deskId != null) {
        await prefs.setString(_activeDeskKey, deskId);
        print('💾 Active desk saved: $deskId');
      } else {
        await prefs.remove(_activeDeskKey);
        print('💾 Active desk cleared');
      }
    } catch (e) {
      print('❌ Error saving active desk: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load camera transformation matrix from localStorage
  static Future<Matrix4?> loadCameraState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cameraStateKey);
      
      if (jsonString == null) {
        print('📂 No saved camera state found');
        return null;
      }
      
      // Convert List<double> back to Matrix4
      final matrixList = List<double>.from(jsonDecode(jsonString));
      final matrix = Matrix4.fromList(matrixList);
      
      print('📂 Camera state loaded');
      return matrix;
    } catch (e) {
      print('❌ Error loading camera state: $e');
      return null;
    }
  }

  /// Load active desk ID from localStorage
  static Future<String?> loadActiveDeskState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deskId = prefs.getString(_activeDeskKey);
      
      if (deskId != null) {
        print('📂 Active desk loaded: $deskId');
      } else {
        print('📂 No saved active desk found');
      }
      
      return deskId;
    } catch (e) {
      print('❌ Error loading active desk: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clear all saved camera and desk state
  static Future<void> clearAllState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cameraStateKey);
      await prefs.remove(_activeDeskKey);
      print('🗑️ All camera state cleared');
    } catch (e) {
      print('❌ Error clearing camera state: $e');
    }
  }

  /// Clear only camera state (keep active desk)
  static Future<void> clearCameraState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cameraStateKey);
      print('🗑️ Camera state cleared');
    } catch (e) {
      print('❌ Error clearing camera state: $e');
    }
  }

  /// Clear only active desk state (keep camera)
  static Future<void> clearActiveDeskState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeDeskKey);
      print('🗑️ Active desk state cleared');
    } catch (e) {
      print('❌ Error clearing active desk state: $e');
    }
  }
}
