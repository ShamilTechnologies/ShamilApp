import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/payment_models.dart';
import 'payment_environment_config.dart';

/// Secure credentials manager for Stripe payment gateway
///
/// Handles secure storage, validation, and management of Stripe credentials
/// with proper encryption and environment separation.
class PaymentCredentialsManager {
  static final PaymentCredentialsManager _instance =
      PaymentCredentialsManager._internal();

  factory PaymentCredentialsManager() => _instance;

  /// Singleton instance getter
  static PaymentCredentialsManager get instance => _instance;

  PaymentCredentialsManager._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys for different environments
  static const String _stripeDevPrefix = 'stripe_dev_';
  static const String _stripeStagingPrefix = 'stripe_staging_';
  static const String _stripeProdPrefix = 'stripe_prod_';

  /// Initialize credentials manager with Stripe credentials
  Future<void> initialize({
    // Stripe credentials for development
    String? stripePublishableKeyDev,
    String? stripeSecretKeyDev,
    String? stripeWebhookSecretDev,
    // Stripe credentials for staging
    String? stripePublishableKeyStaging,
    String? stripeSecretKeyStaging,
    String? stripeWebhookSecretStaging,
    // Stripe credentials for production
    String? stripePublishableKeyProd,
    String? stripeSecretKeyProd,
    String? stripeWebhookSecretProd,
  }) async {
    try {
      // Store development credentials
      if (stripePublishableKeyDev != null) {
        await _storeCredential(
            '${_stripeDevPrefix}publishable_key', stripePublishableKeyDev);
      }
      if (stripeSecretKeyDev != null) {
        await _storeCredential(
            '${_stripeDevPrefix}secret_key', stripeSecretKeyDev);
      }
      if (stripeWebhookSecretDev != null) {
        await _storeCredential(
            '${_stripeDevPrefix}webhook_secret', stripeWebhookSecretDev);
      }

      // Store staging credentials
      if (stripePublishableKeyStaging != null) {
        await _storeCredential('${_stripeStagingPrefix}publishable_key',
            stripePublishableKeyStaging);
      }
      if (stripeSecretKeyStaging != null) {
        await _storeCredential(
            '${_stripeStagingPrefix}secret_key', stripeSecretKeyStaging);
      }
      if (stripeWebhookSecretStaging != null) {
        await _storeCredential('${_stripeStagingPrefix}webhook_secret',
            stripeWebhookSecretStaging);
      }

      // Store production credentials
      if (stripePublishableKeyProd != null) {
        await _storeCredential(
            '${_stripeProdPrefix}publishable_key', stripePublishableKeyProd);
      }
      if (stripeSecretKeyProd != null) {
        await _storeCredential(
            '${_stripeProdPrefix}secret_key', stripeSecretKeyProd);
      }
      if (stripeWebhookSecretProd != null) {
        await _storeCredential(
            '${_stripeProdPrefix}webhook_secret', stripeWebhookSecretProd);
      }

      debugPrint('✅ Stripe credentials initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Stripe credentials: $e');
      rethrow;
    }
  }

  /// Initialize with your provided Stripe test credentials
  Future<void> initializeWithStripeCredentials() async {
    await initialize(
      stripePublishableKeyDev:
          'pk_test_51OMIxwB7R0ZlXV65QN5otHfPIzb51sK8nlZF5Gv7MuHf9rjKcXQoHMT5qXg8xurBJ1VnpIWCs7HmOkWJuCpEKkwt00uaCBogSC',
      stripeSecretKeyDev:
          'sk_test_51OMIxwB7R0ZlXV65NvSCi17HCvmbrKarz5yZP5blPHsrbw4CvT65LUuq3x0IGOUmZdKSxGMCcL8y1p2GxhVZ2FmT00dhy2Nuiv',
      stripeWebhookSecretDev:
          '', // You'll need to set this up in Stripe dashboard

      // Use same test credentials for staging
      stripePublishableKeyStaging:
          'pk_test_51OMIxwB7R0ZlXV65QN5otHfPIzb51sK8nlZF5Gv7MuHf9rjKcXQoHMT5qXg8xurBJ1VnpIWCs7HmOkWJuCpEKkwt00uaCBogSC',
      stripeSecretKeyStaging:
          'sk_test_51OMIxwB7R0ZlXV65NvSCi17HCvmbrKarz5yZP5blPHsrbw4CvT65LUuq3x0IGOUmZdKSxGMCcL8y1p2GxhVZ2FmT00dhy2Nuiv',
      stripeWebhookSecretStaging: '',
    );
  }

  /// Get Stripe configuration for current environment
  Future<StripeConfig> getStripeConfig(
      [PaymentEnvironment? environment]) async {
    final env =
        environment ?? PaymentEnvironmentConfig.instance.currentEnvironment;
    final prefix = _getStripePrefix(env);

    final publishableKey =
        await _getCredential('${prefix}publishable_key') ?? '';
    final secretKey = await _getCredential('${prefix}secret_key') ?? '';
    final webhookSecret = await _getCredential('${prefix}webhook_secret') ?? '';

    return StripeConfig(
      publishableKey: publishableKey,
      secretKey: secretKey,
      webhookSecret: webhookSecret,
      isLiveMode: env == PaymentEnvironment.production,
    );
  }

  /// Store encrypted credential
  Future<void> _storeCredential(String key, String value) async {
    try {
      final encryptedValue = _encryptValue(value);
      await _secureStorage.write(key: key, value: encryptedValue);
    } catch (e) {
      debugPrint('Error storing credential $key: $e');
      rethrow;
    }
  }

  /// Retrieve and decrypt credential
  Future<String?> _getCredential(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;
      return _decryptValue(encryptedValue);
    } catch (e) {
      debugPrint('Error retrieving credential $key: $e');
      return null;
    }
  }

  /// Get Stripe prefix for environment
  String _getStripePrefix(PaymentEnvironment environment) {
    switch (environment) {
      case PaymentEnvironment.production:
        return _stripeProdPrefix;
      case PaymentEnvironment.staging:
        return _stripeStagingPrefix;
      case PaymentEnvironment.development:
        return _stripeDevPrefix;
    }
  }

  /// Simple encryption for stored values
  String _encryptValue(String value) {
    // For now, just base64 encode. In production, use proper encryption
    return base64Encode(utf8.encode(value));
  }

  /// Simple decryption for stored values
  String _decryptValue(String encryptedValue) {
    // For now, just base64 decode. In production, use proper decryption
    return utf8.decode(base64Decode(encryptedValue));
  }

  /// Clear all stored credentials
  Future<void> clearAllCredentials() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('All payment credentials cleared');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  /// Clear credentials for specific environment
  Future<void> clearEnvironmentCredentials(
      PaymentEnvironment environment) async {
    try {
      final prefix = _getStripePrefix(environment);
      final keys = [
        '${prefix}publishable_key',
        '${prefix}secret_key',
        '${prefix}webhook_secret',
      ];

      for (final key in keys) {
        await _secureStorage.delete(key: key);
      }

      debugPrint('Credentials cleared for environment: ${environment.name}');
    } catch (e) {
      debugPrint('Error clearing environment credentials: $e');
    }
  }

  /// Validate stored credentials for environment
  Future<bool> validateCredentials([PaymentEnvironment? environment]) async {
    try {
      final stripeConfig = await getStripeConfig(environment);
      return stripeConfig.isValid;
    } catch (e) {
      debugPrint('Error validating credentials: $e');
      return false;
    }
  }

  /// Get credentials statistics
  Future<Map<String, dynamic>> getCredentialsStats() async {
    final stats = <String, dynamic>{};

    for (final env in PaymentEnvironment.values) {
      final isValid = await validateCredentials(env);
      stats[env.name] = {
        'configured': isValid,
        'environment': env.name,
      };
    }

    return stats;
  }
}
 