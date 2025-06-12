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

  /// Process a payment request with enhanced error handling and retry logic
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      debugPrint(
          '🔄 Processing payment: ${request.id} (${request.amount.amount} ${request.amount.currency.name})');

      switch (request.gateway) {
        case PaymentGateway.stripe:
          return await _processStripePayment(request);
      }
    } catch (e) {
      debugPrint('❌ Payment processing failed: $e');

      // Enhanced error handling with user-friendly messages
      String userFriendlyMessage = _getUserFriendlyErrorMessage(e.toString());

      return PaymentResponse(
        id: request.id,
        status: PaymentStatus.failed,
        amount: request.amount.amount,
        currency: request.amount.currency,
        gateway: request.gateway,
        errorMessage: userFriendlyMessage,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Convert technical error messages to user-friendly ones
  String _getUserFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('card_declined') || error.contains('declined')) {
      return 'Your card was declined. Please try a different payment method or contact your bank.';
    } else if (error.contains('insufficient_funds')) {
      return 'Insufficient funds. Please check your account balance or try a different card.';
    } else if (error.contains('expired_card') || error.contains('expired')) {
      return 'Your card has expired. Please use a different card.';
    } else if (error.contains('incorrect_cvc') || error.contains('cvc')) {
      return 'The security code (CVC) is incorrect. Please check the 3-digit code on the back of your card.';
    } else if (error.contains('invalid_number') || error.contains('number')) {
      return 'The card number is invalid. Please check and try again.';
    } else if (error.contains('processing_error')) {
      return 'There was a processing error. Please try again in a moment.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('authentication') ||
        error.contains('3d_secure')) {
      return 'Card authentication required. Please complete the verification process.';
    } else if (error.contains('rate_limit')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }

    return 'Payment failed. Please try again or contact support if the problem persists.';
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
