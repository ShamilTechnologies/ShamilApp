import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'models/payment_models.dart';
import 'ui/widgets/enhanced_payment_widget.dart';
import 'bloc/payment_bloc.dart';
import 'integration_helper.dart';

/// Comprehensive payment integration examples with BLoC state management
class PaymentIntegrationExamples {
  /// Build a service payment screen with BLoC integration
  static Widget buildServicePaymentScreen({
    required String serviceId,
    required String serviceName,
    required double amount,
    required String userId,
    required String userEmail,
    required String userName,
  }) {
    return BlocProvider(
      create: (context) => PaymentBloc(),
      child: PaymentDemoScreen(
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
      ),
    );
  }

  /// Build a subscription payment screen with BLoC integration
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

    return BlocProvider(
      create: (context) => PaymentBloc(),
      child: PaymentDemoScreen(
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
          'monthly_price': monthlyPrice,
        },
      ),
    );
  }

  /// Build a reservation payment screen with BLoC integration
  static Widget buildReservationPaymentScreen({
    required String reservationId,
    required String serviceName,
    required double amount,
    required String userId,
    required String userEmail,
    required String userName,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return BlocProvider(
      create: (context) => PaymentBloc(),
      child: PaymentDemoScreen(
        title: 'Reservation Payment',
        subtitle: 'Reserve $serviceName',
        amount: amount,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        metadata: {
          'type': 'reservation',
          'reservation_id': reservationId,
          'service_name': serviceName,
          ...?additionalMetadata,
        },
      ),
    );
  }

  /// Build a comprehensive payment showcase screen
  static Widget buildPaymentShowcaseScreen() {
    return const PaymentShowcaseScreen();
  }
}

/// Demo payment screen widget with enhanced UI and BLoC integration
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary card
            PaymentIntegrationHelper.buildPaymentSummary(
              context: context,
              amount: PaymentAmount(
                amount: amount,
                currency: Currency.egp,
              ),
              description: subtitle,
            ),

            const SizedBox(height: 24),

            // Payment button
            PaymentIntegrationHelper.buildPaymentButton(
              context: context,
              text: 'Pay EGP ${amount.toStringAsFixed(0)}',
              icon: CupertinoIcons.creditcard,
              onPressed: () => _showPaymentScreen(context),
            ),

            const SizedBox(height: 16),

            // Alternative payment methods section
            _buildAlternativePaymentMethods(context),

            const SizedBox(height: 24),

            // Features section
            _buildFeaturesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativePaymentMethods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        PaymentIntegrationHelper.buildPaymentMethodCard(
          context: context,
          title: 'Credit/Debit Card',
          subtitle: 'Visa, Mastercard, American Express',
          icon: CupertinoIcons.creditcard,
          onTap: () => _showPaymentScreen(context),
          isSelected: true,
        ),
        PaymentIntegrationHelper.buildPaymentMethodCard(
          context: context,
          title: 'Apple Pay',
          subtitle: 'Pay with Touch ID or Face ID',
          icon: CupertinoIcons.device_phone_portrait,
          onTap: () => _showComingSoonDialog(context, 'Apple Pay'),
          isEnabled: false,
        ),
        PaymentIntegrationHelper.buildPaymentMethodCard(
          context: context,
          title: 'Google Pay',
          subtitle: 'Quick and secure payments',
          icon: CupertinoIcons.device_phone_portrait,
          onTap: () => _showComingSoonDialog(context, 'Google Pay'),
          isEnabled: false,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose Our Payment System?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          CupertinoIcons.lock_shield,
          'Bank-Level Security',
          'Your payment information is protected with 256-bit SSL encryption',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.device_phone_portrait,
          'Mobile Optimized',
          'Seamless payment experience designed for mobile devices',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.exclamationmark_triangle,
          'Error Handling',
          'Smart error detection and user-friendly error messages',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.sparkles,
          'Modern UI/UX',
          'Beautiful animations and intuitive user interface',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => BlocProvider(
          create: (context) => PaymentBloc(),
          child: EnhancedPaymentScreen(
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
            metadata: metadata,
            onSuccess: () {
              Navigator.of(context).pop();
              _showSuccessDialog(context);
            },
            onFailure: () {
              Navigator.of(context).pop();
              _showErrorDialog(context);
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment of EGP ${amount.toStringAsFixed(0)} has been processed successfully.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'There was an issue processing your payment. Please try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showPaymentScreen(context);
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clock,
                  color: Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$paymentMethod integration is coming soon. Stay tuned for updates!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Comprehensive payment showcase screen
class PaymentShowcaseScreen extends StatefulWidget {
  const PaymentShowcaseScreen({super.key});

  @override
  State<PaymentShowcaseScreen> createState() => _PaymentShowcaseScreenState();
}

class _PaymentShowcaseScreenState extends State<PaymentShowcaseScreen> {
  double _selectedAmount = 100.0;
  final List<double> _quickAmounts = [50, 100, 200, 500];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Payment Showcase'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modern Payment System',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experience seamless, secure, and beautiful payment flows',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick amount selection
            Text(
              'Select Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  return PaymentIntegrationHelper.buildQuickPayButton(
                    context: context,
                    amount: amount,
                    label: amount == 50
                        ? 'Basic'
                        : amount == 100
                            ? 'Standard'
                            : amount == 200
                                ? 'Premium'
                                : 'VIP',
                    onPressed: () => setState(() => _selectedAmount = amount),
                    isSelected: _selectedAmount == amount,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Payment options
            Text(
              'Payment Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildPaymentOptionCard(
              context,
              'Service Payment',
              'Pay for individual services',
              CupertinoIcons.wrench,
              Colors.blue,
              () => _showServicePayment(context),
            ),

            _buildPaymentOptionCard(
              context,
              'Subscription Payment',
              'Monthly or yearly subscriptions',
              CupertinoIcons.calendar,
              Colors.green,
              () => _showSubscriptionPayment(context),
            ),

            _buildPaymentOptionCard(
              context,
              'Reservation Payment',
              'Book and pay for reservations',
              CupertinoIcons.bookmark,
              Colors.orange,
              () => _showReservationPayment(context),
            ),

            const SizedBox(height: 24),

            // Features section
            _buildFeaturesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          CupertinoIcons.shield_lefthalf_fill,
          'Secure Payments',
          'Bank-level security with SSL encryption',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.device_phone_portrait,
          'Mobile First',
          'Optimized for mobile devices',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.exclamationmark_triangle,
          'Error Handling',
          'Smart error detection and recovery',
        ),
        _buildFeatureItem(
          context,
          CupertinoIcons.sparkles,
          'Modern UI/UX',
          'Beautiful animations and smooth interactions',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServicePayment(BuildContext context) {
    PaymentIntegrationHelper.showServicePaymentDialog(
      context,
      serviceId: 'service_123',
      serviceName: 'Premium Service',
      amount: _selectedAmount,
      onSuccess: () => _showSuccessSnackBar(context, 'Service payment'),
      onFailure: () => _showErrorSnackBar(context),
    );
  }

  void _showSubscriptionPayment(BuildContext context) {
    PaymentIntegrationHelper.showSubscriptionPaymentDialog(
      context,
      planId: 'plan_123',
      planName: 'Premium Plan',
      monthlyPrice: _selectedAmount / 3,
      durationMonths: 3,
      onSuccess: () => _showSuccessSnackBar(context, 'Subscription'),
      onFailure: () => _showErrorSnackBar(context),
    );
  }

  void _showReservationPayment(BuildContext context) {
    PaymentIntegrationHelper.showReservationPaymentDialog(
      context,
      reservationId: 'reservation_123',
      serviceName: 'Premium Service',
      amount: _selectedAmount,
      onSuccess: () => _showSuccessSnackBar(context, 'Reservation'),
      onFailure: () => _showErrorSnackBar(context),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type payment completed successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment failed. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
