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

    // COMPLETELY BLOCK App Check in debug mode
    if (kDebugMode) {
      debugPrint("🚫 DEBUG MODE: App Check initialization completely blocked");
      debugPrint(
          "📧 Firebase Auth will operate without App Check verification");
      _isInitialized = false; // Keep as false to prevent any token requests
      return;
    }

    try {
      debugPrint("🔧 Initializing Firebase App Check (Production Mode)...");

      await FirebaseAppCheck.instance.activate(
        // Use Play Integrity for Android in production
        androidProvider: AndroidProvider.playIntegrity,
        // Use App Attest for iOS in production
        appleProvider: AppleProvider.appAttest,
        // Web provider - replace with your actual reCAPTCHA site key
        webProvider: ReCaptchaV3Provider(
            '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'), // Test key
      );

      _isInitialized = true;
      debugPrint("✅ Firebase App Check initialized successfully (Production)");
    } catch (e) {
      debugPrint("❌ Firebase App Check initialization failed: $e");
      // Continue without App Check in case of failure
      _isInitialized = false;
      rethrow;
    }
  }

  /// Get App Check token with retry logic
  Future<String?> getAppCheckToken({int maxRetries = 3}) async {
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
}
