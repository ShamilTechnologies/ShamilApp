import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_orchestrator.dart';
import 'models/payment_models.dart';
import 'ui/widgets/enhanced_payment_widget.dart';
import 'bloc/payment_bloc.dart';

/// Helper class for easy payment integration throughout the app
class PaymentIntegrationHelper {
  static final PaymentOrchestrator _orchestrator = PaymentOrchestrator();

  /// Show a service payment dialog with modern UI/UX and BLoC integration
  static void showServicePaymentDialog(
    BuildContext context, {
    required String serviceId,
    required String serviceName,
    required double amount,
    String? description,
    PaymentCustomer? customer,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    // Create a new BLoC instance for this payment flow
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (context) => PaymentBloc(),
        child: EnhancedPaymentScreen(
          amount: PaymentAmount(
            amount: amount,
            currency: Currency.egp,
          ),
          customer: customer ??
              PaymentCustomer(
                id: 'user123', // Get from auth service
                name: 'User Name', // Get from auth service
                email: 'user@example.com', // Get from auth service
              ),
          description: description ?? 'Payment for $serviceName',
          metadata: {
            'type': 'service',
            'service_id': serviceId,
            'service_name': serviceName,
          },
          onSuccess: onSuccess,
          onFailure: onFailure,
          onCancel: onCancelled,
        ),
      ),
    );
  }

  /// Show a subscription payment dialog with modern UI/UX and BLoC integration
  static void showSubscriptionPaymentDialog(
    BuildContext context, {
    required String planId,
    required String planName,
    required double monthlyPrice,
    required int durationMonths,
    String? description,
    PaymentCustomer? customer,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    final totalAmount = monthlyPrice * durationMonths;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (context) => PaymentBloc(),
        child: EnhancedPaymentScreen(
          amount: PaymentAmount(
            amount: totalAmount,
            currency: Currency.egp,
          ),
          customer: customer ??
              PaymentCustomer(
                id: 'user123', // Get from auth service
                name: 'User Name', // Get from auth service
                email: 'user@example.com', // Get from auth service
              ),
          description: description ?? 'Subscription for $planName',
          metadata: {
            'type': 'subscription',
            'plan_id': planId,
            'plan_name': planName,
            'duration_months': durationMonths,
            'monthly_price': monthlyPrice,
          },
          onSuccess: onSuccess,
          onFailure: onFailure,
          onCancel: onCancelled,
        ),
      ),
    );
  }

  /// Show a reservation payment dialog with modern UI/UX and BLoC integration
  static void showReservationPaymentDialog(
    BuildContext context, {
    required String reservationId,
    required String serviceName,
    required double amount,
    String? description,
    PaymentCustomer? customer,
    Map<String, dynamic>? additionalMetadata,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (context) => PaymentBloc(),
        child: EnhancedPaymentScreen(
          amount: PaymentAmount(
            amount: amount,
            currency: Currency.egp,
          ),
          customer: customer ??
              PaymentCustomer(
                id: 'user123', // Get from auth service
                name: 'User Name', // Get from auth service
                email: 'user@example.com', // Get from auth service
              ),
          description: description ?? 'Reservation payment for $serviceName',
          metadata: {
            'type': 'reservation',
            'reservation_id': reservationId,
            'service_name': serviceName,
            ...?additionalMetadata,
          },
          onSuccess: onSuccess,
          onFailure: onFailure,
          onCancel: onCancelled,
        ),
      ),
    );
  }

  /// Show payment screen as a full screen modal
  static void showFullScreenPayment(
    BuildContext context, {
    required PaymentAmount amount,
    required PaymentCustomer customer,
    required String description,
    Map<String, dynamic>? metadata,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    VoidCallback? onCancelled,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => BlocProvider(
          create: (context) => PaymentBloc(),
          child: EnhancedPaymentScreen(
            amount: amount,
            customer: customer,
            description: description,
            metadata: metadata,
            onSuccess: () {
              Navigator.of(context).pop();
              onSuccess?.call();
            },
            onFailure: () {
              Navigator.of(context).pop();
              onFailure?.call();
            },
            onCancel: () {
              Navigator.of(context).pop();
              onCancelled?.call();
            },
          ),
        ),
      ),
    );
  }

  /// Build a modern payment button with enhanced styling
  static Widget buildPaymentButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isLoading = false,
    double? width,
    double height = 56,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          isLoading ? 'Processing...' : text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isLoading ? 0 : 4,
          shadowColor: (backgroundColor ?? Theme.of(context).primaryColor)
              .withOpacity(0.3),
        ),
      ),
    );
  }

  /// Build a quick pay button for common amounts
  static Widget buildQuickPayButton({
    required BuildContext context,
    required double amount,
    required String label,
    required VoidCallback onPressed,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EGP ${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a payment method selection card
  static Widget buildPaymentMethodCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).iconTheme.color,
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isEnabled
                                      ? null
                                      : Theme.of(context).disabledColor,
                                ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isEnabled
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7)
                                  : Theme.of(context).disabledColor,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a payment summary card
  static Widget buildPaymentSummary({
    required BuildContext context,
    required PaymentAmount amount,
    String? description,
    List<Widget>? additionalItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 16),

          // Amount breakdown
          _buildSummaryRow(
            context,
            'Subtotal',
            '${amount.currencySymbol} ${amount.amount.toStringAsFixed(2)}',
          ),

          if (amount.taxAmount != null && amount.taxAmount! > 0)
            _buildSummaryRow(
              context,
              'Tax',
              '${amount.currencySymbol} ${amount.taxAmount!.toStringAsFixed(2)}',
            ),

          if (amount.discountAmount != null && amount.discountAmount! > 0)
            _buildSummaryRow(
              context,
              'Discount',
              '-${amount.currencySymbol} ${amount.discountAmount!.toStringAsFixed(2)}',
              color: Colors.green,
            ),

          if (amount.shippingAmount != null && amount.shippingAmount! > 0)
            _buildSummaryRow(
              context,
              'Shipping',
              '${amount.currencySymbol} ${amount.shippingAmount!.toStringAsFixed(2)}',
            ),

          if (additionalItems != null) ...additionalItems,

          const Divider(height: 24),

          _buildSummaryRow(
            context,
            'Total',
            '${amount.currencySymbol} ${amount.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color ?? Theme.of(context).primaryColor,
                    )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
          ),
        ],
      ),
    );
  }

  /// Initialize the payment system
  static Future<void> initialize() async {
    await _orchestrator.initialize();
  }

  /// Process a payment directly
  static Future<PaymentResponse> processPayment(PaymentRequest request) async {
    return await PaymentOrchestrator.processPayment(paymentRequest: request);
  }
}
