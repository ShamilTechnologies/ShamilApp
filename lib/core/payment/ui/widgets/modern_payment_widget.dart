import 'package:flutter/material.dart';
import '../stripe_payment_widget.dart';
import '../../models/payment_models.dart';

/// Modern payment widget that provides a unified interface for different payment methods
/// Currently wraps the StripePaymentWidget but can be extended for other gateways
class ModernPaymentWidget extends StatelessWidget {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final String description;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailure;
  final VoidCallback onPaymentCancelled;
  final bool showSavedMethods;
  final bool allowSaving;
  final Map<String, dynamic>? metadata;

  const ModernPaymentWidget({
    super.key,
    required this.amount,
    required this.customer,
    required this.description,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    required this.onPaymentCancelled,
    this.showSavedMethods = true,
    this.allowSaving = true,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    // Create a PaymentRequest for the StripePaymentWidget
    final paymentRequest = PaymentRequest(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      customer: customer,
      method: PaymentMethod.creditCard,
      gateway: PaymentGateway.stripe,
      description: description,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
    );

    return StripePaymentWidget(
      paymentRequest: paymentRequest,
      onPaymentComplete: (response) {
        if (response.isSuccessful) {
          onPaymentSuccess();
        } else {
          onPaymentFailure();
        }
      },
      onError: (error) {
        onPaymentFailure();
      },
      onCancel: onPaymentCancelled,
      showSavedMethods: showSavedMethods,
      customerId: customer.id,
    );
  }
}
