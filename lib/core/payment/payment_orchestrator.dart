import 'package:flutter/foundation.dart';
import 'models/payment_models.dart';
import 'gateways/stripe/stripe_service.dart';

/// Payment orchestrator that coordinates payment operations across different gateways
class PaymentOrchestrator {
  final StripeService _stripeService = StripeService();

  /// Initialize the payment orchestrator
  Future<void> initialize() async {
    try {
      await _stripeService.initialize();
      debugPrint('✅ Payment orchestrator initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize payment orchestrator: $e');
      rethrow;
    }
  }

  /// Process a payment request
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      switch (request.gateway) {
        case PaymentGateway.stripe:
          return await _processStripePayment(request);
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return PaymentResponse(
        id: request.id,
        status: PaymentStatus.failed,
        amount: request.amount.amount,
        currency: request.amount.currency,
        gateway: request.gateway,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Verify payment status
  Future<PaymentResponse> verifyPayment(String paymentId) async {
    try {
      return await _stripeService.verifyPayment(paymentIntentId: paymentId);
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Get payment history for a customer
  Future<List<PaymentResponse>> getPaymentHistory(String customerId) async {
    try {
      // For now, return an empty list
      // In a real implementation, you would fetch from your backend
      return [];
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics(String customerId) async {
    try {
      // For now, return empty stats
      // In a real implementation, you would calculate from your backend
      return {
        'totalAmount': 0.0,
        'totalPayments': 0,
        'successfulPayments': 0,
        'failedPayments': 0,
      };
    } catch (e) {
      debugPrint('Error fetching payment statistics: $e');
      return {};
    }
  }

  /// Process Stripe payment
  Future<PaymentResponse> _processStripePayment(PaymentRequest request) async {
    final metadata = request.metadata ?? {};
    final type = metadata['type'] as String?;

    if (type == 'reservation') {
      return await _stripeService.createReservationPayment(
        reservationId: metadata['reservation_id'] ?? request.id,
        amount: request.amount.amount,
        currency: request.amount.currency,
        customer: request.customer,
        description: request.description,
        metadata: metadata,
      );
    } else if (type == 'subscription') {
      return await _stripeService.createSubscriptionPayment(
        subscriptionId: metadata['subscription_id'] ?? request.id,
        amount: request.amount.amount,
        currency: request.amount.currency,
        customer: request.customer,
        description: request.description,
        metadata: metadata,
      );
    } else {
      // Generic payment
      return await _stripeService.createReservationPayment(
        reservationId: request.id,
        amount: request.amount.amount,
        currency: request.amount.currency,
        customer: request.customer,
        description: request.description,
        metadata: metadata,
      );
    }
  }
}
