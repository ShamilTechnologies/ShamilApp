import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';

/// Ultra-premium payment step with full Stripe integration and fintech-grade UI
class BookingPaymentStep extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final Animation<double> contentAnimation;
  final VoidCallback onPaymentSuccess;
  final Function(String?) onPaymentFailure;
  final Function(VoidCallback?)? onPaymentTriggerReady;

  const BookingPaymentStep({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    this.userId,
    this.userName,
    this.userEmail,
    required this.contentAnimation,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    this.onPaymentTriggerReady,
  });

  @override
  State<BookingPaymentStep> createState() => _BookingPaymentStepState();
}

class _BookingPaymentStepState extends State<BookingPaymentStep>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  String _selectedPaymentMethod = 'stripe_card';
  bool _isProcessingPayment = false;

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption(
      id: 'stripe_card',
      name: 'Card Payment',
      description: 'Visa, Mastercard, Amex',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primaryColor,
      isRecommended: true,
    ),
    PaymentMethodOption(
      id: 'apple_pay',
      name: 'Apple Pay',
      description: 'Touch ID, Face ID, or Apple Watch',
      icon: CupertinoIcons.device_phone_portrait,
      color: AppColors.darkText,
    ),
    PaymentMethodOption(
      id: 'google_pay',
      name: 'Google Pay',
      description: 'Quick & secure Google payments',
      icon: CupertinoIcons.money_dollar_circle,
      color: AppColors.successColor,
    ),
    PaymentMethodOption(
      id: 'cash',
      name: 'Pay on Arrival',
      description: 'Cash payment at the venue',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: AppColors.orangeColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Set up the payment trigger callback
    if (widget.onPaymentTriggerReady != null) {
      widget.onPaymentTriggerReady!(processPayment);
    }
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
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
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - widget.contentAnimation.value)),
          child: Opacity(
            opacity: widget.contentAnimation.value,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildPaymentHeader(),
                  const Gap(32),
                  _buildBookingSummary(),
                  const Gap(28),
                  _buildPaymentMethods(),
                  const Gap(24),
                  _buildSecurityBadge(),
                  const Gap(32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E1A),
            AppColors.primaryColor.withOpacity(0.12),
            AppColors.tealColor.withOpacity(0.08),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.tealColor,
                        AppColors.successColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.5),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              );
            },
          ),
          const Gap(28),
          Text(
            'Secure Payment',
            style: app_text_style.getTitleStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            'Your payment is protected by enterprise-grade security',
            style: app_text_style.getbodyStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    final itemName = widget.plan?.name ?? widget.service?.name ?? 'Service';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E1A),
            Colors.white.withOpacity(0.05),
            AppColors.tealColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealColor,
                      AppColors.successColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tealColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(16),
              Text(
                'Booking Summary',
                style: app_text_style.getTitleStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(24),
          _buildSummaryRow('Service', itemName),
          if (widget.state.selectedDate != null) ...[
            const Gap(16),
            _buildSummaryRow(
              'Date',
              '${widget.state.selectedDate!.day}/${widget.state.selectedDate!.month}/${widget.state.selectedDate!.year}',
            ),
          ],
          if (widget.state.selectedTime != null) ...[
            const Gap(16),
            _buildSummaryRow('Time', widget.state.selectedTime!),
          ],
          const Gap(16),
          _buildSummaryRow(
            'Attendees',
            '${widget.state.selectedAttendees.length + (widget.state.includeUserInBooking ? 1 : 0)} person(s)',
          ),
          const Gap(24),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: app_text_style.getTitleStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.tealColor.withOpacity(0.2),
                          AppColors.successColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.tealColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'EGP ${widget.state.totalPrice.toStringAsFixed(2)}',
                      style: app_text_style.getTitleStyle(
                        color: AppColors.tealColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: app_text_style.getbodyStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: app_text_style.getbodyStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Payment Method',
            style: app_text_style.getTitleStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(20),
          Column(
            children: _paymentMethods
                .map((method) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPaymentMethodCard(method),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodOption method) {
    final isSelected = _selectedPaymentMethod == method.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPaymentMethod = method.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    method.color.withOpacity(0.25),
                    method.color.withOpacity(0.10),
                    method.color.withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? method.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: method.color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          method.color,
                          method.color.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: method.color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                method.icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const Gap(20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (method.isRecommended) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Text(
                    method.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successColor,
                      AppColors.tealColor,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  color: Colors.white,
                  size: 16,
                  weight: 700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
              size: 20,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment by Stripe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(6),
                Text(
                  'Your payment is protected by bank-level security and encryption',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
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

  PaymentMethod _getPaymentMethodFromSelection() {
    switch (_selectedPaymentMethod) {
      case 'stripe_card':
        return PaymentMethod.creditCard;
      case 'apple_pay':
        return PaymentMethod.applePay;
      case 'google_pay':
        return PaymentMethod.googlePay;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.creditCard;
    }
  }

  Future<void> processPayment() async {
    if (_isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);
    HapticFeedback.mediumImpact();

    try {
      if (_selectedPaymentMethod == 'cash') {
        // Handle cash payment
        await Future.delayed(const Duration(seconds: 2));
        widget.onPaymentSuccess();
      } else {
        // Create payment request
        final paymentRequest = PaymentRequest(
          id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
          amount: PaymentAmount(
            amount: widget.state.totalPrice,
            currency: Currency.egp,
          ),
          customer: PaymentCustomer(
            id: widget.userId ?? 'guest_user',
            name: widget.userName ?? 'Guest User',
            email: widget.userEmail ?? 'guest@shamil.app',
          ),
          method: _getPaymentMethodFromSelection(),
          description:
              'Booking payment for ${widget.service?.name ?? widget.plan?.name ?? 'service'}',
          gateway: PaymentGateway.stripe,
          createdAt: DateTime.now(),
          metadata: {
            'provider_id': widget.provider.id,
            'service_id': widget.service?.id ?? '',
            'plan_id': widget.plan?.id ?? '',
            'booking_date': widget.state.selectedDate?.toIso8601String() ?? '',
            'booking_time': widget.state.selectedTime ?? '',
            'attendees_count': widget.state.selectedAttendees.length.toString(),
            'payment_method': _selectedPaymentMethod,
          },
        );

        // Show payment screen
        final response = await PaymentOrchestrator.showPaymentScreen(
          context: context,
          paymentRequest: paymentRequest,
          title: 'Complete Payment',
          showSavedMethods: true,
          customerId: widget.userId,
        );

        if (response != null && response.isSuccessful) {
          widget.onPaymentSuccess();
        } else {
          widget
              .onPaymentFailure(response?.errorMessage ?? 'Payment cancelled');
        }
      }
    } catch (e) {
      widget.onPaymentFailure('Payment failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }
}

class PaymentMethodOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRecommended;

  PaymentMethodOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isRecommended = false,
  });
}
