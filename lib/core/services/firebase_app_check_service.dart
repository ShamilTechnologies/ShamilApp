import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check Service
/// Handles App Check configuration and token management
class FirebaseAppCheckService {
  static final FirebaseAppCheckService _instance =
      FirebaseAppCheckService._internal();
  factory FirebaseAppCheckService() => _instance;
  FirebaseAppCheckService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase App Check with proper configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint("🔧 Initializing Firebase App Check...");

      if (kDebugMode) {
        debugPrint("🛠️ DEBUG MODE: Using debug App Check configuration");

        // Use debug providers for development
        await FirebaseAppCheck.instance.activate(
          // Use debug provider for Android in debug mode
          androidProvider: AndroidProvider.debug,
          // Use debug provider for iOS in debug mode
          appleProvider: AppleProvider.debug,
          // Use reCAPTCHA for web (debug)
          webProvider: ReCaptchaV3Provider(
              '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'), // Test key
        );

        debugPrint("✅ Firebase App Check initialized for DEBUG mode");
      } else {
        debugPrint(
            "🔧 PRODUCTION MODE: Using production App Check configuration");

        await FirebaseAppCheck.instance.activate(
          // Use Play Integrity for Android in production
          androidProvider: AndroidProvider.playIntegrity,
          // Use App Attest for iOS in production
          appleProvider: AppleProvider.appAttest,
          // Web provider - replace with your actual reCAPTCHA site key
          webProvider: ReCaptchaV3Provider(
              '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'), // Test key
        );

        debugPrint(
            "✅ Firebase App Check initialized successfully (Production)");
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint("❌ Firebase App Check initialization failed: $e");
      // Continue without App Check in case of failure
      _isInitialized = false;
      rethrow;
    }
  }

  /// Get App Check token with retry logic
  Future<String?> getAppCheckToken({int maxRetries = 3}) async {
    // Always return null in debug mode to avoid App Check conflicts
    if (kDebugMode) {
      debugPrint("🛠️ DEBUG MODE: Bypassing App Check token request");
      return null;
    }

    if (!_isInitialized) {
      debugPrint("⚠️ App Check not initialized, attempting to initialize...");
      try {
        await initialize();
      } catch (e) {
        debugPrint("❌ Failed to initialize App Check: $e");
        return null;
      }
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        if (token != null) {
          debugPrint(
              "✅ App Check token obtained successfully (attempt $attempt)");
          return token;
        }
      } catch (e) {
        debugPrint("⚠️ App Check token request failed (attempt $attempt): $e");

        if (attempt < maxRetries) {
          // Wait before retrying with exponential backoff
          final delay = Duration(seconds: attempt * 2);
          debugPrint("⏳ Retrying in ${delay.inSeconds} seconds...");
          await Future.delayed(delay);
        }
      }
    }

    debugPrint("❌ Failed to get App Check token after $maxRetries attempts");
    return null;
  }

  /// Reset App Check state (useful for testing)
  void reset() {
    _isInitialized = false;
    debugPrint("🔄 App Check service reset");
  }

  /// Force disable App Check for troubleshooting
  void forceDisable() {
    _isInitialized = false;
    debugPrint("🚫 App Check forcefully disabled");
  }
}
