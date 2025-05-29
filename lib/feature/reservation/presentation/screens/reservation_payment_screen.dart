import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/payment/ui/stripe_payment_widget.dart';
import '../../../../core/payment/models/payment_models.dart';
import '../../../../core/payment/bloc/payment_bloc.dart';
import '../../data/models/reservation_model.dart';
import '../../../home/data/service_provider_model.dart';

/// Modern reservation payment screen with Stripe integration
///
/// Features:
/// - Beautiful UI with reservation summary
/// - Stripe payment widget integration
/// - Real-time payment status updates
/// - Error handling and retry logic
/// - Success/failure navigation
class ReservationPaymentScreen extends StatefulWidget {
  final ReservationModel reservation;
  final ServiceProviderModel serviceProvider;

  const ReservationPaymentScreen({
    super.key,
    required this.reservation,
    required this.serviceProvider,
  });

  @override
  State<ReservationPaymentScreen> createState() =>
      _ReservationPaymentScreenState();
}

class _ReservationPaymentScreenState extends State<ReservationPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: _handlePaymentStateChange,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildReservationSummary(),
                    const Gap(24),
                    _buildPricingBreakdown(),
                    const Gap(32),
                    _buildPaymentSection(),
                    const Gap(24),
                    _buildSecurityNotice(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Complete Payment',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildReservationSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: widget.serviceProvider.mainImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(
                              widget.serviceProvider.mainImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: widget.serviceProvider.mainImageUrl == null
                      ? Colors.grey[300]
                      : null,
                ),
                child: widget.serviceProvider.mainImageUrl == null
                    ? Icon(
                        Icons.business,
                        color: Colors.grey[600],
                        size: 30,
                      )
                    : null,
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceProvider.businessName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Gap(4),
                    Text(
                      widget.serviceProvider.category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const Gap(4),
                    Text(
                      widget.serviceProvider.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          Divider(color: Colors.grey[200]),
          const Gap(20),
          _buildReservationDetail(
            'Date & Time',
            '${_formatDate(_getReservationDateTime())} at ${_formatTime(_getReservationDateTime())}',
            Icons.calendar_today,
          ),
          const Gap(16),
          _buildReservationDetail(
            'Duration',
            '${widget.reservation.durationMinutes ?? 60} minutes',
            Icons.access_time,
          ),
          const Gap(16),
          _buildReservationDetail(
            'Group Size',
            '${widget.reservation.groupSize} ${widget.reservation.groupSize == 1 ? 'person' : 'people'}',
            Icons.people,
          ),
          if (widget.reservation.selectedAddOnsList?.isNotEmpty == true) ...[
            const Gap(16),
            _buildReservationDetail(
              'Add-ons',
              widget.reservation.selectedAddOnsList!.join(', '),
              Icons.add_circle_outline,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReservationDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingBreakdown() {
    final basePrice = widget.reservation.totalPrice ?? 100.0;
    final platformFee = basePrice * 0.05; // 5% platform fee
    final tax = (basePrice + platformFee) * 0.14; // 14% tax
    final totalAmount = basePrice + platformFee + tax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(20),
          _buildPriceRow('Service Fee', basePrice),
          const Gap(12),
          _buildPriceRow('Platform Fee', platformFee),
          const Gap(12),
          _buildPriceRow('Tax (14%)', tax),
          const Gap(16),
          Divider(color: Colors.grey[200]),
          const Gap(16),
          _buildPriceRow(
            'Total Amount',
            totalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey[700],
              ),
        ),
        Text(
          'EGP ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTotal ? Theme.of(context).primaryColor : Colors.black,
              ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final basePrice = widget.reservation.totalPrice ?? 100.0;
    final platformFee = basePrice * 0.05;
    final tax = (basePrice + platformFee) * 0.14;
    final totalAmount = basePrice + platformFee + tax;

    final paymentRequest = PaymentRequest(
      id: 'reservation_${widget.reservation.id}',
      amount: PaymentAmount(
        amount: totalAmount,
        currency: Currency.egp,
        taxAmount: tax,
        shippingAmount: platformFee,
      ),
      customer: PaymentCustomer(
        id: widget.reservation.userId,
        name: widget.reservation.userName,
        email: 'user@example.com', // Get from auth
        phone: '+201234567890', // Get from auth
      ),
      method: PaymentMethod.creditCard,
      gateway: PaymentGateway.stripe,
      description:
          'Reservation payment for ${widget.serviceProvider.businessName}',
      metadata: {
        'reservation_id': widget.reservation.id,
        'service_provider_id': widget.serviceProvider.id,
        'type': 'reservation',
      },
      createdAt: DateTime.now(),
    );

    return StripePaymentWidget(
      paymentRequest: paymentRequest,
      onPaymentComplete: (response) {
        if (response.isSuccessful) {
          _handlePaymentSuccess();
        } else {
          setState(() {
            _paymentError = response.errorMessage;
          });
          _handlePaymentFailure();
        }
      },
      onError: (error) {
        setState(() {
          _paymentError = error;
        });
        _handlePaymentFailure();
      },
      onCancel: _handlePaymentCancel,
      showSavedMethods: true,
      customerId: widget.reservation.userId,
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue[700],
            size: 24,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const Gap(4),
                Text(
                  'Your payment information is encrypted and secure. We never store your card details.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers

  void _handlePaymentSuccess() {
    setState(() {
      _paymentError = null;
    });

    // Show success dialog
    _showPaymentResultDialog(
      title: 'Payment Successful!',
      message:
          'Your reservation has been confirmed. You will receive a confirmation email shortly.',
      isSuccess: true,
    );
  }

  void _handlePaymentFailure() {
    setState(() {
      _paymentError = _paymentError ??
          'Something went wrong with your payment. Please try again.';
    });

    // Show error dialog
    _showPaymentResultDialog(
      title: 'Payment Failed',
      message: _paymentError!,
      isSuccess: false,
    );
  }

  void _handlePaymentCancel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment cancelled'),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handlePaymentStateChange(BuildContext context, PaymentState state) {
    if (state is PaymentLoaded) {
      if (state.lastPaymentResponse != null) {
        if (state.lastPaymentResponse!.isSuccessful) {
          _handlePaymentSuccess();
        } else if (state.lastPaymentResponse!.isFailed) {
          setState(() {
            _paymentError = state.lastPaymentResponse!.errorMessage;
          });
          _handlePaymentFailure();
        }
      }
    } else if (state is PaymentError) {
      setState(() {
        _paymentError = state.message;
      });
      _handlePaymentFailure();
    } else if (state is PaymentRequiresAction) {
      // Handle 3D Secure or other required actions
    }
  }

  void _showPaymentResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 50,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            const Gap(20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (isSuccess) {
                    Navigator.of(context).pop(); // Go back to previous screen
                    Navigator.of(context)
                        .pop(); // Go back to home or reservations
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSuccess ? Colors.green : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isSuccess ? 'Continue' : 'Try Again',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  DateTime _getReservationDateTime() {
    return widget.reservation.reservationStartTime?.toDate() ?? DateTime.now();
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
