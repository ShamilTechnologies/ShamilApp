import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/ui/premium_card_details_sheet.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

/// High-End Payment Method Selector with Built-in Stripe Payment Sheet
/// Premium UI/UX matching the best fintech apps in the industry
class PaymentMethodSelector extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final Function(String) onPaymentMethodChanged;
  final Function(PaymentResponse) onPaymentCompleted;
  final String? userId;
  final String? userName;
  final String? userEmail;

  const PaymentMethodSelector({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    required this.onPaymentMethodChanged,
    required this.onPaymentCompleted,
    this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector>
    with TickerProviderStateMixin {
  String _selectedMethod = 'stripeSheet';
  bool _isProcessingPayment = false;

  // Premium animation controllers
  late AnimationController _containerController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _containerAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  final List<PaymentMethodInfo> _paymentMethods = [
    PaymentMethodInfo(
      id: 'stripeSheet',
      name: 'Card Payment',
      description: 'Visa, Mastercard, Amex - Powered by Stripe',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primaryColor,
      processingFee: 2.9,
      isInstant: true,
      gatewayMethod: PaymentMethod.creditCard,
      isRecommended: true,
    ),
    PaymentMethodInfo(
      id: 'applePay',
      name: 'Apple Pay',
      description: 'Touch ID, Face ID, or Apple Watch',
      icon: CupertinoIcons.device_phone_portrait,
      color: AppColors.darkText,
      processingFee: 0.0,
      isInstant: true,
      gatewayMethod: PaymentMethod.applePay,
      isRecommended: false,
    ),
    PaymentMethodInfo(
      id: 'googlePay',
      name: 'Google Pay',
      description: 'Quick & secure Google payments',
      icon: CupertinoIcons.money_dollar_circle,
      color: AppColors.successColor,
      processingFee: 0.0,
      isInstant: true,
      gatewayMethod: PaymentMethod.googlePay,
      isRecommended: false,
    ),
    PaymentMethodInfo(
      id: 'cash',
      name: 'Pay on Arrival',
      description: 'Cash payment at the venue',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: AppColors.orangeColor,
      processingFee: 0.0,
      isInstant: false,
      gatewayMethod: PaymentMethod.cash,
      isRecommended: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.state.paymentMethod.isNotEmpty) {
      _selectedMethod = widget.state.paymentMethod;
    }
  }

  void _initializeAnimations() {
    _containerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _containerAnimation = CurvedAnimation(
      parent: _containerController,
      curve: Curves.easeOutCubic,
    );

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _containerController.forward();
    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _containerController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _containerAnimation.value)),
          child: Opacity(
            opacity: _containerAnimation.value,
            child: _buildPremiumPaymentContainer(),
          ),
        );
      },
    );
  }

  Widget _buildPremiumPaymentContainer() {
    final selectedPaymentMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedMethod,
      orElse: () => _paymentMethods.first,
    );

    final baseAmount = widget.state.totalPrice;
    final processingFee =
        (baseAmount * selectedPaymentMethod.processingFee / 100);
    final totalWithFee = baseAmount + processingFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E1A),
            AppColors.primaryColor.withOpacity(0.15),
            AppColors.tealColor.withOpacity(0.1),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 50,
            offset: const Offset(0, 25),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: selectedPaymentMethod.color.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 80,
            offset: const Offset(0, 40),
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header
            _buildPremiumHeader(selectedPaymentMethod),

            // Payment Amount Summary
            _buildAmountSummary(
                selectedPaymentMethod, baseAmount, processingFee, totalWithFee),

            // Premium Payment Methods Grid
            _buildPaymentMethodsGrid(),

            // Stripe Security Badge
            if (_selectedMethod == 'stripeSheet') _buildStripeBadge(),

            // Premium Payment Button
            _buildPremiumPaymentButton(selectedPaymentMethod, totalWithFee),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(PaymentMethodInfo selectedMethod) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selectedMethod.color.withOpacity(0.15),
            selectedMethod.color.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        selectedMethod.color,
                        selectedMethod.color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: selectedMethod.color.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    selectedMethod.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(4),
                Text(
                  selectedMethod.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(4),
                Text(
                  selectedMethod.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (selectedMethod.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.successColor,
                    AppColors.tealColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'RECOMMENDED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary(PaymentMethodInfo selectedMethod,
      double baseAmount, double processingFee, double totalWithFee) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Amount',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'EGP ${baseAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (processingFee > 0) ...[
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Processing Fee (${selectedMethod.processingFee}%)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'EGP ${processingFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const Gap(16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'EGP ${totalWithFee.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.tealColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Payment Method',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              return _buildPaymentMethodCard(_paymentMethods[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodInfo method) {
    final isSelected = _selectedMethod == method.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMethod = method.id;
        });
        widget.onPaymentMethodChanged(method.id);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    method.color.withOpacity(0.3),
                    method.color.withOpacity(0.1),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? method.color.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: method.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Shimmer effect for selected item
            if (isSelected)
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment(
                            -1.0 + 2.0 * _shimmerAnimation.value, 0.0),
                        end:
                            Alignment(1.0 + 2.0 * _shimmerAnimation.value, 0.0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        method.icon,
                        color: isSelected
                            ? method.color
                            : Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: method.color,
                          size: 18,
                        ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    method.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (method.processingFee > 0)
                    Text(
                      '${method.processingFee}% fee',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.orangeColor
                            : Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'No fees',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.successColor
                            : Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStripeBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.tealColor,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: Colors.white,
              size: 16,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment by Stripe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your payment is protected by Stripe\'s world-class security',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPaymentButton(
      PaymentMethodInfo selectedMethod, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: _isProcessingPayment
              ? LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.5),
                    Colors.grey.withOpacity(0.3),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    selectedMethod.color,
                    selectedMethod.color.withOpacity(0.8),
                  ],
                ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isProcessingPayment
              ? null
              : [
                  BoxShadow(
                    color: selectedMethod.color.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: selectedMethod.color.withOpacity(0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 25),
                  ),
                  BoxShadow(
                    color: selectedMethod.color.withOpacity(0.1),
                    blurRadius: 100,
                    offset: const Offset(0, 50),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _isProcessingPayment ? null : _processPayment,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              child: _isProcessingPayment
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const Gap(16),
                        const Text(
                          'Processing Payment...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedMethod.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                        const Gap(12),
                        Text(
                          'Pay EGP ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    HapticFeedback.mediumImpact();

    try {
      final selectedPaymentMethod = _paymentMethods.firstWhere(
        (method) => method.id == _selectedMethod,
        orElse: () => _paymentMethods.first,
      );

      final baseAmount = widget.state.totalPrice;
      final processingFee =
          (baseAmount * selectedPaymentMethod.processingFee / 100);
      final totalAmount = baseAmount + processingFee;

      if (_selectedMethod == 'cash') {
        // Simulate cash payment processing
        await Future.delayed(const Duration(seconds: 2));
        final response = PaymentResponse(
          id: 'cash_${DateTime.now().millisecondsSinceEpoch}',
          status: PaymentStatus.completed,
          amount: totalAmount,
          currency: Currency.egp,
          gateway: PaymentGateway.stripe,
          timestamp: DateTime.now(),
        );
        widget.onPaymentCompleted(response);
      } else {
        // Use premium swipable credit card details sheet
        final paymentRequest = PaymentOrchestrator.createReservationPayment(
          reservationId: 'booking_${DateTime.now().millisecondsSinceEpoch}',
          amount: totalAmount,
          currency: Currency.egp,
          customer: PaymentCustomer(
            id: widget.userId ?? 'guest_user',
            name: widget.userName ?? 'Guest User',
            email: widget.userEmail ?? 'guest@shamil.app',
          ),
          description:
              'Booking payment for ${widget.service?.name ?? widget.plan?.name ?? 'service'}',
          metadata: {
            'provider_id': widget.provider.id,
            'service_id': widget.service?.id ?? '',
            'plan_id': widget.plan?.id ?? '',
            'booking_date': widget.state.selectedDate?.toIso8601String() ?? '',
            'booking_time': widget.state.selectedTime ?? '',
            'attendees_count': widget.state.selectedAttendees.length.toString(),
            'payment_method': _selectedMethod,
          },
        );

        // Show premium swipable card details bottom sheet
        final response = await showModalBottomSheet<PaymentResponse>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withOpacity(0.8),
          builder: (context) => PremiumCardDetailsSheet(
            paymentRequest: paymentRequest,
            onPaymentComplete: (response) =>
                Navigator.of(context).pop(response),
            onError: (error) => debugPrint('Payment error: $error'),
          ),
        );

        if (response != null) {
          widget.onPaymentCompleted(response);
        }
      }

      if (mounted) {
        setState(() => _isProcessingPayment = false);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        HapticFeedback.heavyImpact();
        _showErrorDialog('Payment failed. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: Text(
          'Payment Error',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tealColor,
                  AppColors.tealColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double processingFee;
  final bool isInstant;
  final PaymentMethod gatewayMethod;
  final bool isRecommended;

  PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.processingFee,
    required this.isInstant,
    required this.gatewayMethod,
    this.isRecommended = false,
  });
}
