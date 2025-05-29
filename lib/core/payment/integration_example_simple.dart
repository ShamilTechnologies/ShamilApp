import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'models/payment_models.dart';
import 'ui/widgets/modern_payment_widget.dart';

/// Simple payment integration examples for demonstration
class SimplePaymentIntegrationExamples {
  /// Build a service payment screen
  static Widget buildServicePaymentScreen({
    required String serviceId,
    required String serviceName,
    required double amount,
    required String userId,
    required String userEmail,
    required String userName,
  }) {
    return PaymentDemoScreen(
      title: 'Service Payment',
      subtitle: 'Pay for $serviceName',
      amount: amount,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      metadata: {
        'type': 'service',
        'service_id': serviceId,
        'service_name': serviceName,
      },
    );
  }

  /// Build a subscription payment screen
  static Widget buildSubscriptionPaymentScreen({
    required String planId,
    required String planName,
    required double monthlyPrice,
    required int durationMonths,
    required String userId,
    required String userEmail,
    required String userName,
  }) {
    final totalAmount = monthlyPrice * durationMonths;

    return PaymentDemoScreen(
      title: 'Subscription Payment',
      subtitle: 'Subscribe to $planName',
      amount: totalAmount,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      metadata: {
        'type': 'subscription',
        'plan_id': planId,
        'plan_name': planName,
        'duration_months': durationMonths,
      },
    );
  }
}

/// Demo payment screen widget
class PaymentDemoScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String userId;
  final String userEmail;
  final String userName;
  final Map<String, dynamic> metadata;

  const PaymentDemoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: EGP ${amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ModernPaymentWidget(
              amount: PaymentAmount(
                amount: amount,
                currency: Currency.egp,
              ),
              customer: PaymentCustomer(
                id: userId,
                name: userName,
                email: userEmail,
              ),
              description: subtitle,
              onPaymentSuccess: () {
                _showSuccessDialog(context);
              },
              onPaymentFailure: () {
                _showErrorDialog(context);
              },
              onPaymentCancelled: () {
                Navigator.pop(context);
              },
              metadata: metadata,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Text(
            'Your payment of EGP ${amount.toStringAsFixed(0)} has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: const Text(
            'Your payment could not be processed. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Demo screen for payment integration testing
class PaymentIntegrationDemoScreen extends StatelessWidget {
  const PaymentIntegrationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(CupertinoIcons.wrench),
                title: const Text('Service Payment'),
                subtitle: const Text('Test service booking payment'),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/service-payment',
                    arguments: {
                      'serviceId': 'demo_service',
                      'serviceName': 'Demo Service',
                      'amount': 250.0,
                      'userId': 'demo_user',
                      'userEmail': 'demo@example.com',
                      'userName': 'Demo User',
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(CupertinoIcons.star),
                title: const Text('Subscription Payment'),
                subtitle: const Text('Test subscription payment'),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/subscription-payment',
                    arguments: {
                      'planId': 'demo_plan',
                      'planName': 'Demo Plan',
                      'monthlyPrice': 99.0,
                      'durationMonths': 1,
                      'userId': 'demo_user',
                      'userEmail': 'demo@example.com',
                      'userName': 'Demo User',
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
