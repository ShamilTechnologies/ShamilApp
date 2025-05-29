import 'package:flutter/material.dart';
import 'payment_orchestrator.dart';
import 'models/payment_models.dart';
import 'ui/widgets/modern_payment_widget.dart';

/// Helper class for easy payment integration throughout the app
class PaymentIntegrationHelper {
  static final PaymentOrchestrator _orchestrator = PaymentOrchestrator();

  /// Show a service payment dialog
  static void showServicePaymentDialog(
    BuildContext context, {
    required String serviceId,
    required String serviceName,
    required double amount,
    String? description,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ModernPaymentWidget(
            amount: PaymentAmount(
              amount: amount,
              currency: Currency.egp,
            ),
            customer: PaymentCustomer(
              id: 'user123', // Get from auth
              name: 'User Name', // Get from auth
              email: 'user@example.com', // Get from auth
            ),
            description: description ?? 'Payment for $serviceName',
            onPaymentSuccess: () {
              Navigator.pop(dialogContext);
              onSuccess?.call();
            },
            onPaymentFailure: () {
              Navigator.pop(dialogContext);
              onFailure?.call();
            },
            onPaymentCancelled: () {
              Navigator.pop(dialogContext);
              onCancelled?.call();
            },
            metadata: {
              'type': 'service',
              'service_id': serviceId,
              'service_name': serviceName,
            },
          ),
        ),
      ),
    );
  }

  /// Show a subscription payment dialog
  static void showSubscriptionPaymentDialog(
    BuildContext context, {
    required String planId,
    required String planName,
    required double monthlyPrice,
    required int durationMonths,
    String? description,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    final totalAmount = monthlyPrice * durationMonths;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ModernPaymentWidget(
            amount: PaymentAmount(
              amount: totalAmount,
              currency: Currency.egp,
            ),
            customer: PaymentCustomer(
              id: 'user123', // Get from auth
              name: 'User Name', // Get from auth
              email: 'user@example.com', // Get from auth
            ),
            description: description ?? 'Subscription for $planName',
            onPaymentSuccess: () {
              Navigator.pop(dialogContext);
              onSuccess?.call();
            },
            onPaymentFailure: () {
              Navigator.pop(dialogContext);
              onFailure?.call();
            },
            onPaymentCancelled: () {
              Navigator.pop(dialogContext);
              onCancelled?.call();
            },
            metadata: {
              'type': 'subscription',
              'plan_id': planId,
              'plan_name': planName,
              'duration_months': durationMonths,
            },
          ),
        ),
      ),
    );
  }

  /// Build a payment button with consistent styling
  static Widget buildPaymentButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Initialize the payment system
  static Future<void> initialize() async {
    await _orchestrator.initialize();
  }

  /// Process a payment directly
  static Future<PaymentResponse> processPayment(PaymentRequest request) async {
    return await _orchestrator.processPayment(request);
  }
}
