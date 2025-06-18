import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/components/payment_method_selector.dart';
import '../shared/step_header.dart';

/// Ultra-premium payment step using the new PaymentMethodSelector
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
  final Function(String)? onPaymentMethodChanged;

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
    this.onPaymentMethodChanged,
  });

  @override
  State<BookingPaymentStep> createState() => _BookingPaymentStepState();
}

class _BookingPaymentStepState extends State<BookingPaymentStep> {
  String _selectedPaymentMethod = 'stripeSheet';

  @override
  void initState() {
    super.initState();

    // Set up the payment trigger callback if needed
    if (widget.onPaymentTriggerReady != null) {
      widget.onPaymentTriggerReady!(
          null); // No external trigger needed with PaymentMethodSelector
    }
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepHeader(
                    title: 'Complete Payment',
                    subtitle: 'Secure payment to confirm your booking',
                  ),
                  const Gap(24),
                  _buildBookingSummary(),
                  const Gap(24),
                  _buildPaymentMethodSelection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingSummary() {
    final itemName = widget.service?.name ?? widget.plan?.name ?? 'Service';
    final totalAttendees = widget.state.selectedAttendees.length +
        (widget.state.includeUserInBooking ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E1A),
            AppColors.tealColor.withOpacity(0.15),
            AppColors.successColor.withOpacity(0.1),
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
            color: AppColors.tealColor.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
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
          _buildSummaryRow('Attendees', '$totalAttendees person(s)'),
          const Gap(20),
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
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: app_text_style.getTitleStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'EGP ${widget.state.totalPrice.toStringAsFixed(2)}',
                style: app_text_style.getTitleStyle(
                  color: AppColors.tealColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    final paymentMethods = [
      PaymentMethodInfo(
        id: 'stripeSheet',
        name: 'Card Payment',
        description: 'Visa, Mastercard, Amex - Powered by Stripe',
        icon: CupertinoIcons.creditcard_fill,
        color: AppColors.premiumBlue,
        isRecommended: true,
      ),
      PaymentMethodInfo(
        id: 'applePay',
        name: 'Apple Pay',
        description: 'Touch ID, Face ID, or Apple Watch',
        icon: CupertinoIcons.device_phone_portrait,
        color: AppColors.darkText,
        isRecommended: false,
      ),
      PaymentMethodInfo(
        id: 'googlePay',
        name: 'Google Pay',
        description: 'Quick & secure Google payments',
        icon: CupertinoIcons.money_dollar_circle,
        color: AppColors.successColor,
        isRecommended: false,
      ),
      PaymentMethodInfo(
        id: 'cash',
        name: 'Pay on Arrival',
        description: 'Cash payment at the venue',
        icon: CupertinoIcons.money_dollar_circle_fill,
        color: AppColors.orangeColor,
        isRecommended: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E1A),
            AppColors.premiumBlue.withOpacity(0.15),
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
            color: AppColors.premiumBlue.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
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
                      AppColors.premiumBlue,
                      AppColors.tealColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumBlue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.creditcard_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(16),
              Text(
                'Choose Payment Method',
                style: app_text_style.getTitleStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              return _buildPaymentMethodCard(paymentMethods[index]);
            },
          ),
          const Gap(24),
          _buildPaymentNote(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodInfo method) {
    final isSelected = _selectedPaymentMethod == method.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method.id;
        });
        widget.onPaymentMethodChanged?.call(method.id);
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
        child: Padding(
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
                  if (method.isRecommended && !isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.successColor,
                            AppColors.tealColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              Text(
                method.name,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                method.description.split(' - ').first,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.premiumBlue.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.premiumBlue.withOpacity(0.2),
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
                  AppColors.premiumBlue,
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
                  'Payment will be processed when you tap "Complete Booking"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your payment is secured by Stripe\'s bank-level encryption',
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
}

class PaymentMethodInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRecommended;

  PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isRecommended = false,
  });
}
