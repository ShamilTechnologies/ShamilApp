import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NFCSoundType {
  success,
  denied,
  error,
  scanning,
  processing,
}

class NFCSoundService {
  static final NFCSoundService _instance = NFCSoundService._internal();
  factory NFCSoundService() => _instance;

  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _isInitialized = false;

  NFCSoundService._internal();

  /// Initialize the sound service and load settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadSettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[NFC Sound Service] Failed to initialize: $e');
    }
  }

  /// Load sound settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('nfc_sound_effects') ?? true;
    _hapticEnabled = prefs.getBool('nfc_haptic_feedback') ?? true;
  }

  /// Update sound settings
  Future<void> updateSettings({
    bool? soundEnabled,
    bool? hapticEnabled,
  }) async {
    if (soundEnabled != null) {
      _soundEnabled = soundEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nfc_sound_effects', soundEnabled);
    }

    if (hapticEnabled != null) {
      _hapticEnabled = hapticEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nfc_haptic_feedback', hapticEnabled);
    }
  }

  /// Play sound and haptic feedback for NFC events
  Future<void> playNFCFeedback(NFCSoundType soundType) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Play haptic feedback
    if (_hapticEnabled) {
      await _playHapticFeedback(soundType);
    }

    // Play system sounds (using system feedback)
    if (_soundEnabled) {
      await _playSystemSound(soundType);
    }
  }

  /// Play haptic feedback based on sound type
  Future<void> _playHapticFeedback(NFCSoundType soundType) async {
    try {
      switch (soundType) {
        case NFCSoundType.success:
          await HapticFeedback.heavyImpact();
          // Double tap for success
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
          break;

        case NFCSoundType.denied:
        case NFCSoundType.error:
          await HapticFeedback.heavyImpact();
          // Triple tap for error/denied
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          break;

        case NFCSoundType.scanning:
          await HapticFeedback.lightImpact();
          break;

        case NFCSoundType.processing:
          await HapticFeedback.mediumImpact();
          break;
      }
    } catch (e) {
      debugPrint('[NFC Sound Service] Haptic feedback error: $e');
    }
  }

  /// Play system sounds based on sound type
  Future<void> _playSystemSound(NFCSoundType soundType) async {
    try {
      switch (soundType) {
        case NFCSoundType.success:
          await SystemSound.play(SystemSoundType.click);
          break;

        case NFCSoundType.denied:
        case NFCSoundType.error:
          // Use platform-specific error sound
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            // iOS doesn't have a direct error sound, use alert
            await SystemSound.play(SystemSoundType.alert);
          } else {
            // Android - we'll use click sound for now
            await SystemSound.play(SystemSoundType.click);
          }
          break;

        case NFCSoundType.scanning:
          await SystemSound.play(SystemSoundType.click);
          break;

        case NFCSoundType.processing:
          await SystemSound.play(SystemSoundType.click);
          break;
      }
    } catch (e) {
      debugPrint('[NFC Sound Service] System sound error: $e');
    }
  }

  /// Play custom feedback sequence for specific scenarios
  Future<void> playAccessGrantedSequence() async {
    if (!_soundEnabled && !_hapticEnabled) return;

    // Success haptic sequence
    if (_hapticEnabled) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    }

    // Success sound sequence
    if (_soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 150));
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play custom feedback sequence for denied access
  Future<void> playAccessDeniedSequence() async {
    if (!_soundEnabled && !_hapticEnabled) return;

    // Denied haptic sequence (longer, more intense)
    if (_hapticEnabled) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    }

    // Denied sound sequence
    if (_soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Play scanning sequence (gentle pulses)
  Future<void> playScanningSequence() async {
    if (!_hapticEnabled) return;

    for (int i = 0; i < 3; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Quick success feedback
  Future<void> quickSuccess() async {
    if (_hapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
    if (_soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Quick error feedback
  Future<void> quickError() async {
    if (_hapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
    if (_soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Light feedback for UI interactions
  Future<void> lightFeedback() async {
    if (_hapticEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Medium feedback for moderate actions
  Future<void> mediumFeedback() async {
    if (_hapticEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Heavy feedback for important actions
  Future<void> heavyFeedback() async {
    if (_hapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  // Getters for current settings
  bool get isSoundEnabled => _soundEnabled;
  bool get isHapticEnabled => _hapticEnabled;
  bool get isInitialized => _isInitialized;
}
