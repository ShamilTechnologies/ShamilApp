import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/payment_models.dart';

/// Environment-specific payment configuration for Stripe only
/// Manages credentials and settings for Stripe payment gateway
class PaymentEnvironmentConfig {
  static PaymentEnvironmentConfig? _instance;

  static PaymentEnvironmentConfig get instance {
    _instance ??= PaymentEnvironmentConfig._internal();
    return _instance!;
  }

  PaymentEnvironmentConfig._internal();

  /// Initialize the payment environment configuration
  Future<void> initialize() async {
    // Load environment variables if not already loaded
    try {
      if (dotenv.env.isEmpty) {
        await dotenv.load(fileName: "assets/env/.env");
      }
      debugPrint('✅ Payment environment configuration initialized');
    } catch (e) {
      debugPrint('⚠️ Could not load .env file, using fallback credentials: $e');
    }
  }

  /// Current environment (development, staging, production)
  PaymentEnvironment get currentEnvironment {
    if (kDebugMode) {
      return PaymentEnvironment.development;
    }

    final env = dotenv.env['PAYMENT_ENVIRONMENT']?.toLowerCase();
    switch (env) {
      case 'production':
      case 'prod':
        return PaymentEnvironment.production;
      case 'staging':
      case 'stage':
        return PaymentEnvironment.staging;
      default:
        return PaymentEnvironment.development;
    }
  }

  /// Get Stripe configuration for current environment
  StripeConfig get stripeConfig {
    switch (currentEnvironment) {
      case PaymentEnvironment.production:
        return StripeConfig(
          publishableKey: dotenv.env['STRIPE_PUBLISHABLE_KEY_PROD'] ?? '',
          secretKey: dotenv.env['STRIPE_SECRET_KEY_PROD'] ?? '',
          webhookSecret: dotenv.env['STRIPE_WEBHOOK_SECRET_PROD'] ?? '',
          isLiveMode: true,
        );
      case PaymentEnvironment.staging:
        return StripeConfig(
          publishableKey: dotenv.env['STRIPE_PUBLISHABLE_KEY_STAGING'] ??
              'pk_test_51OMIxwB7R0ZlXV65QN5otHfPIzb51sK8nlZF5Gv7MuHf9rjKcXQoHMT5qXg8xurBJ1VnpIWCs7HmOkWJuCpEKkwt00uaCBogSC',
          secretKey: dotenv.env['STRIPE_SECRET_KEY_STAGING'] ??
              'sk_test_51OMIxwB7R0ZlXV65NvSCi17HCvmbrKarz5yZP5blPHsrbw4CvT65LUuq3x0IGOUmZdKSxGMCcL8y1p2GxhVZ2FmT00dhy2Nuiv',
          webhookSecret: dotenv.env['STRIPE_WEBHOOK_SECRET_STAGING'] ?? '',
          isLiveMode: false,
        );
      case PaymentEnvironment.development:
        return StripeConfig(
          publishableKey: dotenv.env['STRIPE_PUBLISHABLE_KEY_DEV'] ??
              'pk_test_51OMIxwB7R0ZlXV65QN5otHfPIzb51sK8nlZF5Gv7MuHf9rjKcXQoHMT5qXg8xurBJ1VnpIWCs7HmOkWJuCpEKkwt00uaCBogSC',
          secretKey: dotenv.env['STRIPE_SECRET_KEY_DEV'] ??
              'sk_test_51OMIxwB7R0ZlXV65NvSCi17HCvmbrKarz5yZP5blPHsrbw4CvT65LUuq3x0IGOUmZdKSxGMCcL8y1p2GxhVZ2FmT00dhy2Nuiv',
          webhookSecret: dotenv.env['STRIPE_WEBHOOK_SECRET_DEV'] ?? '',
          isLiveMode: false,
        );
    }
  }

  /// Get webhook configuration for Stripe
  WebhookConfig getWebhookConfig() {
    return WebhookConfig(
      stripeSecret: stripeConfig.webhookSecret,
    );
  }

  /// Validate Stripe configuration
  bool isStripeConfigured() {
    try {
      final config = stripeConfig;
      return config.isValid;
    } catch (e) {
      return false;
    }
  }

  /// Get default gateway (always Stripe)
  PaymentGateway get defaultGateway => PaymentGateway.stripe;

  /// Get currency configuration
  CurrencyConfig get currencyConfig {
    return CurrencyConfig(
      defaultCurrency: Currency.egp,
      supportedCurrencies: [Currency.egp, Currency.usd, Currency.eur],
      exchangeRates: {
        Currency.usd: 30.9, // EGP to USD rate
        Currency.eur: 33.5, // EGP to EUR rate
      },
    );
  }

  /// Get payment limits configuration
  PaymentLimitsConfig get paymentLimitsConfig {
    return PaymentLimitsConfig(
      minAmount: {
        Currency.egp: 10.0,
        Currency.usd: 1.0,
        Currency.eur: 1.0,
      },
      maxAmount: {
        Currency.egp: 100000.0,
        Currency.usd: 3000.0,
        Currency.eur: 3000.0,
      },
      dailyLimit: {
        Currency.egp: 50000.0,
        Currency.usd: 1500.0,
        Currency.eur: 1500.0,
      },
    );
  }

  /// Get required environment variables for Stripe
  static List<String> getRequiredEnvVars({
    required PaymentEnvironment environment,
  }) {
    final suffix = environment == PaymentEnvironment.production
        ? '_PROD'
        : environment == PaymentEnvironment.staging
            ? '_STAGING'
            : '_DEV';

    return [
      'STRIPE_PUBLISHABLE_KEY$suffix',
      'STRIPE_SECRET_KEY$suffix',
      'STRIPE_WEBHOOK_SECRET$suffix',
    ];
  }

  /// Validate configurations for Stripe
  static Map<String, bool> validateConfigurations({
    required PaymentEnvironment environment,
  }) {
    final config = PaymentEnvironmentConfig.instance;
    return {
      'stripe': config.isStripeConfigured(),
    };
  }

  /// Print current configuration (for debugging)
  void printConfiguration() {
    if (kDebugMode) {
      debugPrint('=== Payment Configuration ===');
      debugPrint('Environment: ${currentEnvironment.name}');
      debugPrint('Stripe configured: ${isStripeConfigured()}');
      debugPrint('Default gateway: ${defaultGateway.name}');
      debugPrint('Default currency: ${currencyConfig.defaultCurrency.name}');
      debugPrint('=============================');
    }
  }
}

/// Stripe configuration model
class StripeConfig extends PaymentGatewayConfig {
  final String publishableKey;
  final String secretKey;
  final String webhookSecret;
  final bool isLiveMode;
  final String apiVersion;
  final String apiBaseUrl;

  const StripeConfig({
    required this.publishableKey,
    required this.secretKey,
    required this.webhookSecret,
    required this.isLiveMode,
    this.apiVersion = '2023-10-16',
    this.apiBaseUrl = 'https://api.stripe.com',
  });

  @override
  bool get isValid =>
      publishableKey.isNotEmpty &&
      secretKey.isNotEmpty &&
      publishableKey.startsWith(isLiveMode ? 'pk_live_' : 'pk_test_') &&
      secretKey.startsWith(isLiveMode ? 'sk_live_' : 'sk_test_');

  @override
  PaymentGateway get gateway => PaymentGateway.stripe;

  @override
  Map<String, dynamic> toJson() {
    return {
      'publishableKey': publishableKey,
      'secretKey': secretKey,
      'webhookSecret': webhookSecret,
      'isLiveMode': isLiveMode,
      'apiVersion': apiVersion,
      'apiBaseUrl': apiBaseUrl,
    };
  }
}

/// Webhook configuration for Stripe
class WebhookConfig {
  final String stripeSecret;

  const WebhookConfig({
    required this.stripeSecret,
  });

  String? getWebhookSecret(PaymentGateway gateway) {
    switch (gateway) {
      case PaymentGateway.stripe:
        return stripeSecret;
    }
  }
}

/// Currency configuration
class CurrencyConfig {
  final Currency defaultCurrency;
  final List<Currency> supportedCurrencies;
  final Map<Currency, double> exchangeRates;

  const CurrencyConfig({
    required this.defaultCurrency,
    required this.supportedCurrencies,
    required this.exchangeRates,
  });
}

/// Payment limits configuration
class PaymentLimitsConfig {
  final Map<Currency, double> minAmount;
  final Map<Currency, double> maxAmount;
  final Map<Currency, double> dailyLimit;

  const PaymentLimitsConfig({
    required this.minAmount,
    required this.maxAmount,
    required this.dailyLimit,
  });
}

/// Base class for payment gateway configurations
abstract class PaymentGatewayConfig {
  const PaymentGatewayConfig();

  bool get isValid;
  PaymentGateway get gateway;
  Map<String, dynamic> toJson();
}
