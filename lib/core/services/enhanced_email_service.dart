import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enhanced email service with comprehensive diagnostics and proper Firebase Auth integration
class EnhancedEmailService {
  static final EnhancedEmailService _instance =
      EnhancedEmailService._internal();
  factory EnhancedEmailService() => _instance;
  EnhancedEmailService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Rate limiting map: email -> last sent timestamp
  final Map<String, DateTime> _lastSentMap = {};

  // Rate limit: 1 email per minute per address
  static const Duration _rateLimitDuration = Duration(minutes: 1);

  /// Send password reset email with comprehensive diagnostics
  Future<void> sendPasswordResetEmail(String email) async {
    print('📧 Enhanced Email Service: Starting password reset process...');
    print('   📩 Email: $email');
    print('   🔧 Debug Mode: $kDebugMode');
    print('   🏗️ Firebase Project: ${_auth.app.options.projectId}');

    // Validate email format
    if (!_isValidEmail(email)) {
      print('❌ Invalid email format: $email');
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    // Check rate limiting
    if (_isRateLimited(email)) {
      final lastSent = _lastSentMap[email]!;
      final nextAllowed = lastSent.add(_rateLimitDuration);
      final waitTime = nextAllowed.difference(DateTime.now()).inSeconds;

      print('⏰ Rate limited for $email. Next allowed in ${waitTime}s');
      throw FirebaseAuthException(
        code: 'too-many-requests',
        message:
            'Please wait ${waitTime} seconds before requesting another email.',
      );
    }

    try {
      // Check if user exists (for debugging only - don't prevent sending)
      await _checkUserExists(email);

      print('📧 Sending password reset email via Firebase Auth...');
      print('   🔗 Auth instance: ${_auth.hashCode}');
      print('   🌐 Language: ${_auth.languageCode ?? 'default'}');

      // Send the email using standard Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);

      // Update rate limiting
      _lastSentMap[email] = DateTime.now();

      print('✅ Password reset email request completed successfully');
      print('📬 Email should arrive within 1-5 minutes');
      print('💡 Check spam folder if not received');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code}');
      print('   📝 Message: ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'user-not-found':
          print('⚠️ No account found for $email');
          // Still show success to prevent account enumeration
          print(
              '🔐 Showing success for security (prevents account enumeration)');
          break;
        case 'invalid-email':
          print('❌ Invalid email format');
          rethrow;
        case 'too-many-requests':
          print('⏰ Too many requests - device temporarily blocked');
          print('💡 Solution: Clear app data or wait 1-24 hours');
          throw FirebaseAuthException(
            code: 'too-many-requests',
            message:
                'Device temporarily blocked due to unusual activity. Try: 1) Clear app data in device settings, 2) Wait 1-24 hours, or 3) Test with an existing account.',
          );
        default:
          print('❌ Unexpected error: ${e.code}');
          rethrow;
      }
    } catch (e) {
      print('❌ Unexpected error sending password reset email: $e');
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to send password reset email. Please try again.',
      );
    }
  }

  /// Send email verification with diagnostics
  Future<void> sendEmailVerification(User user) async {
    print('📧 Enhanced Email Service: Starting email verification...');
    print('   👤 User: ${user.email}');
    print('   ✅ Verified: ${user.emailVerified}');

    if (user.emailVerified) {
      print('⚠️ Email already verified');
      throw FirebaseAuthException(
        code: 'email-already-verified',
        message: 'Email is already verified.',
      );
    }

    try {
      print('📧 Sending email verification...');
      await user.sendEmailVerification();

      print('✅ Email verification sent successfully');
      print('📬 Verification email should arrive within 1-5 minutes');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code}');
      print('   📝 Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error sending verification email: $e');
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to send verification email. Please try again.',
      );
    }
  }

  /// Check if user exists (for debugging purposes)
  Future<void> _checkUserExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      print('🔍 User lookup for $email:');
      print(
          '   📋 Sign-in methods: ${methods.isEmpty ? 'None (user may not exist)' : methods.join(', ')}');

      if (methods.isEmpty) {
        print('⚠️ No account found for this email address');
        print('💡 Firebase will still return success (security feature)');
      } else {
        print('✅ Account exists - email should be delivered');
      }
    } catch (e) {
      print('❌ Error checking user existence: $e');
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if email sending is rate limited
  bool _isRateLimited(String email) {
    final lastSent = _lastSentMap[email];
    if (lastSent == null) return false;

    final timeSince = DateTime.now().difference(lastSent);
    return timeSince < _rateLimitDuration;
  }

  /// Get detailed diagnostics for troubleshooting
  Map<String, dynamic> getDiagnostics() {
    return {
      'service_version': '2.0.0',
      'debug_mode': kDebugMode,
      'firebase_project': _auth.app.options.projectId,
      'auth_language': _auth.languageCode ?? 'default',
      'current_user': _auth.currentUser?.email ?? 'none',
      'rate_limit_cache_size': _lastSentMap.length,
    };
  }

  /// Clear rate limiting cache (for testing)
  void clearRateLimit([String? email]) {
    if (email != null) {
      _lastSentMap.remove(email);
      print('🧹 Cleared rate limit for $email');
    } else {
      _lastSentMap.clear();
      print('🧹 Cleared all rate limits');
    }
  }
}
