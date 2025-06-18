import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;

import '../../models/payment_models.dart';
import '../../config/payment_environment_config.dart';

/// Simplified Stripe service for basic payment operations
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  late StripeConfig _config;
  bool _isInitialized = false;

  /// Initialize Stripe service with configuration
  Future<void> initialize() async {
    try {
      _config = PaymentEnvironmentConfig.instance.stripeConfig;

      if (!_config.isValid) {
        throw StripeServiceException('Invalid Stripe configuration');
      }

      // Initialize Stripe SDK
      stripe.Stripe.publishableKey = _config.publishableKey;
      stripe.Stripe.merchantIdentifier = 'merchant.com.shamil.app';

      await stripe.Stripe.instance.applySettings();

      _isInitialized = true;
      debugPrint('✅ Stripe service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Stripe service: $e');
      rethrow;
    }
  }

  /// Create or get existing customer in Stripe with improved error handling
  Future<String> _ensureCustomerExists(PaymentCustomer customer) async {
    try {
      debugPrint('🔍 Checking if customer exists: ${customer.email}');

      // Handle guest customers by creating them in Stripe
      if (_isGuestCustomer(customer.id)) {
        debugPrint('👤 Creating Stripe customer for guest: ${customer.email}');
        return await _createStripeCustomer(customer);
      }

      // Skip customer creation for demo/temp users to avoid API errors
      if (_isDemoCustomer(customer.id)) {
        debugPrint(
            '⚡ Demo customer detected, creating in Stripe: ${customer.id}');
        return await _createStripeCustomer(customer);
      }

      // Try to get existing customer by email
      final searchResponse = await _makeApiCall(
        'GET',
        '/customers',
        queryParams: {
          'email': customer.email,
          'limit': '1',
        },
      );

      final searchData = json.decode(searchResponse.body);
      final customers = searchData['data'] as List;

      if (customers.isNotEmpty) {
        final existingCustomer = customers.first;
        debugPrint(
            '✅ Found existing Stripe customer: ${existingCustomer['id']}');
        return existingCustomer['id'];
      }

      debugPrint('➕ Creating new Stripe customer for: ${customer.email}');
      return await _createStripeCustomer(customer);
    } catch (e) {
      debugPrint('❌ Error ensuring customer exists: $e');
      // For production, we should handle this more gracefully
      throw StripeServiceException(
          'Failed to prepare customer for payment: ${e.toString()}');
    }
  }

  /// Check if customer is a guest customer
  bool _isGuestCustomer(String customerId) {
    return customerId.startsWith('guest_');
  }

  /// Check if customer is a demo/temp customer
  bool _isDemoCustomer(String customerId) {
    return customerId.startsWith('temp_') ||
        customerId.startsWith('user_') ||
        customerId.startsWith('demo_') ||
        customerId == 'current_user_id';
  }

  /// Create a new customer in Stripe
  Future<String> _createStripeCustomer(PaymentCustomer customer) async {
    final createResponse = await _makeApiCall(
      'POST',
      '/customers',
      body: {
        'email': customer.email,
        'name': customer.name,
        'phone': customer.phone ?? '',
        'metadata': {
          'firebase_uid': customer.id,
          'source': 'shamil_app',
          'created_at': DateTime.now().toIso8601String(),
          'customer_type':
              _isGuestCustomer(customer.id) ? 'guest' : 'registered',
        },
      },
    );

    final customerData = json.decode(createResponse.body);
    debugPrint('✅ Created new Stripe customer: ${customerData['id']}');
    return customerData['id'];
  }

  /// Create payment intent for reservation
  Future<PaymentResponse> createReservationPayment({
    required String reservationId,
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      debugPrint(
          '🔄 Creating payment intent for ${customer.email} (\$${amount.toStringAsFixed(2)} ${currency.name})');

      // Ensure customer exists in Stripe
      final stripeCustomerId = await _ensureCustomerExists(customer);
      debugPrint('✅ Stripe customer ID: $stripeCustomerId');

      // Create payment intent on server
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        customer: customer.copyWith(id: stripeCustomerId),
        description: description ?? 'Reservation Payment',
        metadata: {
          'type': 'reservation',
          'reservation_id': reservationId,
          'customer_id': customer.id,
          'firebase_uid': customer.id,
          'stripe_customer_id': stripeCustomerId,
          ...?metadata,
        },
      );

      debugPrint('✅ Payment intent created: ${paymentIntent['id']}');

      // Don't confirm payment here - let the UI handle it
      final result = await _confirmPayment(paymentIntent);

      return PaymentResponse(
        id: result['id'] ?? '',
        status: _mapStripeStatus(result['status'] ?? 'requires_payment_method'),
        amount: amount,
        currency: currency,
        gateway: PaymentGateway.stripe,
        gatewayResponse: result,
        metadata: metadata,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Payment intent creation error: $e');
      return _handleError(e, amount, currency);
    }
  }

  /// Create payment intent for subscription
  Future<PaymentResponse> createSubscriptionPayment({
    required String subscriptionId,
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      // Ensure customer exists in Stripe
      final stripeCustomerId = await _ensureCustomerExists(customer);

      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        customer: customer.copyWith(id: stripeCustomerId),
        description: description ?? 'Subscription Payment',
        metadata: {
          'type': 'subscription',
          'subscription_id': subscriptionId,
          'customer_id': customer.id,
          'firebase_uid': customer.id,
          'stripe_customer_id': stripeCustomerId,
          ...?metadata,
        },
      );

      final result = await _confirmPayment(paymentIntent);

      return PaymentResponse(
        id: result['id'] ?? '',
        status: _mapStripeStatus(result['status'] ?? 'failed'),
        amount: amount,
        currency: currency,
        gateway: PaymentGateway.stripe,
        gatewayResponse: result,
        metadata: metadata,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return _handleError(e, amount, currency);
    }
  }

  /// Get saved payment methods for customer
  Future<List<PaymentMethodData>> getSavedPaymentMethods({
    required String customerId,
  }) async {
    _ensureInitialized();

    try {
      // Skip lookup for temporary or demo customer IDs
      if (customerId.startsWith('temp_') ||
          customerId.startsWith('user_') ||
          customerId == 'current_user_id' ||
          customerId.isEmpty) {
        debugPrint(
            'Skipping saved payment methods for temporary/demo customer: $customerId');
        return [];
      }

      // Validate that we have a real customer ID
      if (customerId.length < 10) {
        debugPrint('Customer ID too short, likely invalid: $customerId');
        return [];
      }

      // Try to get customer by Firebase UID first, then by Stripe customer ID
      String stripeCustomerId = customerId;

      if (!customerId.startsWith('cus_')) {
        // This is a Firebase UID, find the corresponding Stripe customer
        final searchResponse = await _makeApiCall(
          'GET',
          '/customers',
          queryParams: {
            'limit': '100',
          },
        );

        final searchData = json.decode(searchResponse.body);
        final customers = searchData['data'] as List;

        bool customerFound = false;
        for (final customer in customers) {
          final metadata = customer['metadata'] as Map<String, dynamic>?;
          if (metadata?['firebase_uid'] == customerId) {
            stripeCustomerId = customer['id'];
            customerFound = true;
            debugPrint(
                'Found Stripe customer $stripeCustomerId for Firebase UID $customerId');
            break;
          }
        }

        // If customer not found by Firebase UID, return empty list
        if (!customerFound) {
          debugPrint('No Stripe customer found for Firebase UID: $customerId');
          return [];
        }
      }

      final response = await _makeApiCall(
        'GET',
        '/customers/$stripeCustomerId/payment_methods',
        queryParams: {'type': 'card'},
      );

      final data = json.decode(response.body);
      final paymentMethods = data['data'] as List;

      debugPrint(
          'Found ${paymentMethods.length} saved payment methods for customer $stripeCustomerId');

      return paymentMethods
          .map((pm) => PaymentMethodData.fromStripe(pm))
          .toList();
    } on StripeServiceException catch (e) {
      // Handle specific Stripe errors gracefully
      if (e.code == 'resource_missing') {
        debugPrint('Customer not found in Stripe: $customerId');
        return [];
      }
      debugPrint('Stripe error fetching saved payment methods: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('General error fetching saved payment methods: $e');
      return [];
    }
  }

  /// Verify payment status with retry logic for timing issues
  Future<PaymentResponse> verifyPayment({
    required String paymentIntentId,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    _ensureInitialized();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _makeApiCall(
          'GET',
          '/payment_intents/$paymentIntentId',
        );

        final data = json.decode(response.body);
        final status = data['status'] as String;

        debugPrint(
            '🔍 Payment verification attempt $attempt: status = $status');

        // If payment is still processing and we have retries left, wait and retry
        if ((status == 'processing' || status == 'requires_action') &&
            attempt < maxRetries) {
          debugPrint(
              '⏳ Payment still processing, waiting ${retryDelay.inSeconds}s before retry...');
          await Future.delayed(retryDelay);
          continue;
        }

        final paymentResponse = PaymentResponse(
          id: data['id'],
          status: _mapStripeStatus(status),
          amount: (data['amount'] as int) / 100.0,
          currency: Currency.values.firstWhere(
            (c) => c.name.toLowerCase() == data['currency'],
            orElse: () => Currency.egp,
          ),
          gateway: PaymentGateway.stripe,
          gatewayResponse: data,
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(data['created'] * 1000),
        );

        debugPrint(
            '✅ Payment verification final result: ${paymentResponse.status.name}');
        return paymentResponse;
      } catch (e) {
        debugPrint('❌ Payment verification attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          debugPrint('❌ All payment verification attempts failed');
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }

    throw Exception('Payment verification failed after $maxRetries attempts');
  }

  /// Create payment intent (public method for UI widget)
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    // Ensure customer exists in Stripe
    final stripeCustomerId = await _ensureCustomerExists(customer);
    debugPrint('✅ Stripe customer ID: $stripeCustomerId');

    return await _createPaymentIntent(
      amount: amount,
      currency: currency,
      customer: customer.copyWith(id: stripeCustomerId),
      description: description,
      metadata: metadata,
    );
  }

  // Private methods

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StripeServiceException(
          'Stripe service not initialized. Call initialize() first.');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _makeApiCall(
      'POST',
      '/payment_intents',
      body: {
        'amount': (amount * 100).round(), // Convert to cents
        'currency': currency.name.toLowerCase(),
        'description': description,
        'customer': customer.id, // Use Stripe customer ID
        'metadata': metadata ?? {},
        'automatic_payment_methods[enabled]': 'true',
      },
    );

    if (response.statusCode >= 400) {
      debugPrint(
          '❌ Stripe API error (${response.statusCode}): ${response.body}');

      try {
        final errorData = json.decode(response.body);
        throw StripeServiceException(
          errorData['error']['message'] ?? 'Unknown Stripe error',
          code: errorData['error']['code'],
          statusCode: response.statusCode,
        );
      } catch (e) {
        // If JSON parsing fails, throw with raw response
        throw StripeServiceException(
          'API Error: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> _confirmPayment(
      Map<String, dynamic> paymentIntent) async {
    try {
      // For mobile payments, we don't confirm here automatically
      // The confirmation will be handled by the Stripe SDK in the UI
      // Just return the payment intent data for the UI to handle
      return {
        'id': paymentIntent['id'],
        'status': paymentIntent['status'] ?? 'requires_payment_method',
        'amount': paymentIntent['amount'],
        'currency': paymentIntent['currency'],
        'client_secret': paymentIntent['client_secret'],
        'created': paymentIntent['created'] ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      debugPrint('Error in payment setup: $e');
      // Return the original payment intent data
      return paymentIntent;
    }
  }

  Future<http.Response> _makeApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${_config.apiBaseUrl}/v1$endpoint');
    final finalUri =
        queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

    final headers = {
      'Authorization': 'Bearer ${_config.secretKey}',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Stripe-Version': _config.apiVersion,
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(finalUri, headers: headers);
        break;
      case 'POST':
        String encodedBody = '';
        if (body != null) {
          encodedBody = _encodeBodyForStripe(body);
        }
        response =
            await http.post(finalUri, headers: headers, body: encodedBody);
        break;
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }

    if (response.statusCode >= 400) {
      debugPrint(
          '❌ Stripe API error (${response.statusCode}): ${response.body}');

      try {
        final errorData = json.decode(response.body);
        throw StripeServiceException(
          errorData['error']['message'] ?? 'Unknown Stripe error',
          code: errorData['error']['code'],
          statusCode: response.statusCode,
        );
      } catch (e) {
        // If JSON parsing fails, throw with raw response
        throw StripeServiceException(
          'API Error: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }

    return response;
  }

  /// Properly encode body for Stripe API with nested objects
  String _encodeBodyForStripe(Map<String, dynamic> body) {
    final List<String> parts = [];

    void addPart(String key, dynamic value) {
      if (value == null) return;

      if (value is Map<String, dynamic>) {
        // Handle nested objects (like metadata)
        for (final entry in value.entries) {
          addPart('$key[${entry.key}]', entry.value);
        }
      } else if (value is List) {
        // Handle arrays
        for (int i = 0; i < value.length; i++) {
          addPart('$key[$i]', value[i]);
        }
      } else {
        // Handle simple values
        parts.add(
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
      }
    }

    for (final entry in body.entries) {
      addPart(entry.key, entry.value);
    }

    return parts.join('&');
  }

  PaymentStatus _mapStripeStatus(String status) {
    debugPrint('🔍 Mapping Stripe status: $status');

    switch (status) {
      case 'succeeded':
        debugPrint('✅ Status mapped to: completed');
        return PaymentStatus.completed;
      case 'processing':
        debugPrint('⏳ Status mapped to: processing');
        return PaymentStatus.processing;
      case 'requires_payment_method':
        debugPrint('❓ Status mapped to: pending (requires_payment_method)');
        return PaymentStatus.pending;
      case 'requires_confirmation':
        debugPrint('❓ Status mapped to: pending (requires_confirmation)');
        return PaymentStatus.pending;
      case 'requires_action':
        debugPrint('❓ Status mapped to: pending (requires_action)');
        return PaymentStatus.pending;
      case 'canceled':
      case 'cancelled':
        debugPrint('❌ Status mapped to: cancelled');
        return PaymentStatus.cancelled;
      default:
        debugPrint('❌ Unknown status "$status" mapped to: failed');
        return PaymentStatus.failed;
    }
  }

  PaymentResponse _handleError(
      dynamic error, double amount, Currency currency) {
    String message = 'Payment failed';
    String? code;

    if (error is stripe.StripeException) {
      message = error.error.localizedMessage ??
          error.error.message ??
          'Payment failed';
      code = error.error.code.toString();
    } else if (error is StripeServiceException) {
      message = error.message;
      code = error.code;
    } else if (error is Exception) {
      message = error.toString();
    }

    debugPrint('Stripe payment error: $message');

    return PaymentResponse(
      id: '',
      status: PaymentStatus.failed,
      amount: amount,
      currency: currency,
      gateway: PaymentGateway.stripe,
      errorMessage: message,
      errorCode: code,
      timestamp: DateTime.now(),
    );
  }
}

/// Payment method data model for Stripe
class PaymentMethodData {
  final String id;
  final String type;
  final String? last4;
  final String? brand;
  final int? expMonth;
  final int? expYear;

  PaymentMethodData({
    required this.id,
    required this.type,
    this.last4,
    this.brand,
    this.expMonth,
    this.expYear,
  });

  factory PaymentMethodData.fromStripe(Map<String, dynamic> data) {
    final card = data['card'] as Map<String, dynamic>?;

    return PaymentMethodData(
      id: data['id'],
      type: data['type'],
      last4: card?['last4'],
      brand: card?['brand'],
      expMonth: card?['exp_month'],
      expYear: card?['exp_year'],
    );
  }
}

/// Custom Stripe service exception
class StripeServiceException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  StripeServiceException(this.message, {this.code, this.statusCode});

  @override
  String toString() =>
      'StripeServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}
