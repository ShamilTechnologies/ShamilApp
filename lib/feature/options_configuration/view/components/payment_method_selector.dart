import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
// Stripe Integration Imports
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/ui/stripe_payment_widget.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';

/// Enhanced Payment Method Selector with Full Stripe Integration
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
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  String _selectedMethod = 'creditCard';
  bool _isProcessingPayment = false;
  bool _showStripeWidget = false;
  final PaymentOrchestrator _paymentOrchestrator = PaymentOrchestrator();

  final List<PaymentMethodInfo> _paymentMethods = [
    PaymentMethodInfo(
      id: 'creditCard',
      name: 'Credit Card',
      description: 'Visa, Mastercard, American Express',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primaryColor,
      processingFee: 2.9,
      isInstant: true,
      gatewayMethod: PaymentMethod.creditCard,
    ),
    PaymentMethodInfo(
      id: 'debitCard',
      name: 'Debit Card',
      description: 'Direct bank payment',
      icon: CupertinoIcons.creditcard,
      color: AppColors.cyanColor,
      processingFee: 1.5,
      isInstant: true,
      gatewayMethod: PaymentMethod.debitCard,
    ),
    PaymentMethodInfo(
      id: 'applePay',
      name: 'Apple Pay',
      description: 'Quick and secure payment',
      icon: CupertinoIcons.device_phone_portrait,
      color: AppColors.tealColor,
      processingFee: 0.0,
      isInstant: true,
      gatewayMethod: PaymentMethod.applePay,
    ),
    PaymentMethodInfo(
      id: 'googlePay',
      name: 'Google Pay',
      description: 'Pay with your Google account',
      icon: CupertinoIcons.money_dollar_circle,
      color: AppColors.greenColor,
      processingFee: 0.0,
      isInstant: true,
      gatewayMethod: PaymentMethod.googlePay,
    ),
    PaymentMethodInfo(
      id: 'bankTransfer',
      name: 'Bank Transfer',
      description: 'Direct transfer from your bank',
      icon: CupertinoIcons.building_2_fill,
      color: AppColors.cyanColor,
      processingFee: 0.0,
      isInstant: false,
      gatewayMethod: PaymentMethod.bankTransfer,
    ),
    PaymentMethodInfo(
      id: 'cash',
      name: 'Pay on Arrival',
      description: 'Pay when you arrive',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: AppColors.orangeColor,
      processingFee: 0.0,
      isInstant: false,
      gatewayMethod: PaymentMethod.cash,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePayment();
    if (widget.state.paymentMethod.isNotEmpty) {
      _selectedMethod = widget.state.paymentMethod;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializePayment() async {
    try {
      await _paymentOrchestrator.initialize();
    } catch (e) {
      debugPrint('Failed to initialize payment orchestrator: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildPaymentSummary(),
            const Gap(20),
            _buildPaymentMethods(),
            if (_showStripeWidget) ...[
              const Gap(20),
              _buildStripePaymentWidget(),
            ],
            const Gap(24),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.greenColor, AppColors.primaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Choose how you\'d like to pay',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greenColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: AppColors.greenColor,
                  size: 14,
                ),
                const Gap(4),
                Text(
                  'Stripe Secured',
                  style: app_text_style.getSmallStyle(
                    color: AppColors.greenColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final selectedPaymentMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedMethod,
      orElse: () => _paymentMethods.first,
    );

    final baseAmount = widget.state.totalPrice;
    final processingFee =
        (baseAmount * selectedPaymentMethod.processingFee / 100);
    final totalWithFee = baseAmount + processingFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              Text(
                'EGP ${baseAmount.toStringAsFixed(2)}',
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (processingFee > 0) ...[
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Processing Fee (${selectedPaymentMethod.processingFee}%)',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'EGP ${processingFee.toStringAsFixed(2)}',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const Gap(12),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: app_text_style.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'EGP ${totalWithFee.toStringAsFixed(2)}',
                style: app_text_style.getTitleStyle(
                  color: AppColors.greenColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _paymentMethods.map(_buildPaymentMethodOption).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethodInfo method) {
    final isSelected = _selectedMethod == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPaymentMethod(method),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        method.color.withValues(alpha: 0.2),
                        method.color.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: !isSelected ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? method.color.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              method.color,
                              method.color.withValues(alpha: 0.8)
                            ],
                          )
                        : null,
                    color: !isSelected
                        ? Colors.white.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method.icon,
                    color: isSelected
                        ? Colors.white
                        : AppColors.lightText.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: app_text_style.getbodyStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        method.description,
                        style: app_text_style.getSmallStyle(
                          color: AppColors.lightText.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (method.processingFee > 0)
                      Text(
                        '${method.processingFee}% fee',
                        style: app_text_style.getSmallStyle(
                          color: AppColors.orangeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'No fee',
                        style: app_text_style.getSmallStyle(
                          color: AppColors.greenColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: method.isInstant
                            ? AppColors.greenColor.withValues(alpha: 0.2)
                            : AppColors.orangeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        method.isInstant ? 'Instant' : '1-3 days',
                        style: app_text_style.getSmallStyle(
                          color: method.isInstant
                              ? AppColors.greenColor
                              : AppColors.orangeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Icon(
                  isSelected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: isSelected
                      ? method.color
                      : AppColors.lightText.withValues(alpha: 0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStripePaymentWidget() {
    final baseAmount = widget.state.totalPrice;
    final selectedPaymentMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedMethod,
      orElse: () => _paymentMethods.first,
    );
    final processingFee =
        (baseAmount * selectedPaymentMethod.processingFee / 100);
    final totalAmount = baseAmount + processingFee;

    final paymentRequest = PaymentRequest(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      amount: PaymentAmount(
        amount: totalAmount,
        currency: Currency.egp,
      ),
      customer: PaymentCustomer(
        id: widget.userId ?? 'guest_user',
        name: widget.userName ?? 'Guest User',
        email: widget.userEmail ?? 'guest@shamil.app',
      ),
      method: selectedPaymentMethod.gatewayMethod,
      gateway: PaymentGateway.stripe,
      description:
          'Booking payment for ${widget.service?.name ?? widget.plan?.name ?? 'service'}',
      metadata: {
        'type': 'reservation',
        'provider_id': widget.provider.id,
        'service_id': widget.service?.id,
        'plan_id': widget.plan?.id,
        'booking_date': widget.state.selectedDate?.toIso8601String(),
        'booking_time': widget.state.selectedTime,
        'attendees_count': widget.state.selectedAttendees.length.toString(),
      },
      createdAt: DateTime.now(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: StripePaymentWidget(
          paymentRequest: paymentRequest,
          onPaymentComplete: (PaymentResponse response) {
            setState(() {
              _isProcessingPayment = false;
              _showStripeWidget = false;
            });
            widget.onPaymentCompleted(response);
          },
          onError: (String error) {
            setState(() {
              _isProcessingPayment = false;
            });
            _showErrorDialog(error);
          },
          showSavedMethods: true,
          customerId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedMethod,
      orElse: () => _paymentMethods.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isProcessingPayment
                  ? 1.0 + (_pulseAnimation.value * 0.05)
                  : 1.0,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isProcessingPayment
                          ? [Colors.grey, Colors.grey.shade800]
                          : [
                              selectedMethod.color,
                              selectedMethod.color.withValues(alpha: 0.8)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isProcessingPayment
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const Gap(12),
                              Text(
                                'Processing...',
                                style: app_text_style.getbodyStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                                size: 20,
                              ),
                              const Gap(8),
                              Text(
                                _getPayButtonText(),
                                style: app_text_style.getbodyStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getPayButtonText() {
    switch (_selectedMethod) {
      case 'cash':
        return 'Confirm Booking';
      case 'bankTransfer':
        return 'Continue to Bank Transfer';
      case 'applePay':
        return 'Pay with Apple Pay';
      case 'googlePay':
        return 'Pay with Google Pay';
      default:
        final baseAmount = widget.state.totalPrice;
        final processingFee = (baseAmount *
            _paymentMethods
                .firstWhere((m) => m.id == _selectedMethod)
                .processingFee /
            100);
        final total = baseAmount + processingFee;
        return 'Pay EGP ${total.toStringAsFixed(2)}';
    }
  }

  void _selectPaymentMethod(PaymentMethodInfo method) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMethod = method.id;
      _showStripeWidget = false;
    });
    widget.onPaymentMethodChanged(method.id);
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    HapticFeedback.mediumImpact();

    try {
      if (_selectedMethod == 'cash') {
        // Handle cash payment (just confirm booking)
        await Future.delayed(const Duration(seconds: 1));
        final response = PaymentResponse(
          id: 'cash_${DateTime.now().millisecondsSinceEpoch}',
          status: PaymentStatus.completed,
          amount: widget.state.totalPrice,
          currency: Currency.egp,
          gateway: PaymentGateway.stripe,
          timestamp: DateTime.now(),
        );
        widget.onPaymentCompleted(response);
      } else if (_selectedMethod == 'bankTransfer') {
        // Handle bank transfer (show instructions)
        await Future.delayed(const Duration(seconds: 1));
        final response = PaymentResponse(
          id: 'transfer_${DateTime.now().millisecondsSinceEpoch}',
          status: PaymentStatus.pending,
          amount: widget.state.totalPrice,
          currency: Currency.egp,
          gateway: PaymentGateway.stripe,
          timestamp: DateTime.now(),
        );
        widget.onPaymentCompleted(response);
      } else {
        // Handle card-based payments through Stripe
        setState(() {
          _showStripeWidget = true;
        });
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
        backgroundColor: AppColors.darkBackground,
        title: Text(
          'Payment Error',
          style: app_text_style.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: app_text_style.getbodyStyle(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: app_text_style.getbodyStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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

  PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.processingFee,
    required this.isInstant,
    required this.gatewayMethod,
  });
}
