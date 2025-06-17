import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';

/// Premium Payment Screen - Fintech-grade UI with glassmorphism and premium animations
/// This is the main payment interface that users see when making payments
class PremiumPaymentScreen extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final String? title;
  final Widget? headerIcon;
  final bool showSavedMethods;
  final String? customerId;
  final List<PaymentSummaryItem>? additionalItems;

  const PremiumPaymentScreen({
    super.key,
    required this.paymentRequest,
    this.title,
    this.headerIcon,
    this.showSavedMethods = true,
    this.customerId,
    this.additionalItems,
  });

  @override
  State<PremiumPaymentScreen> createState() => _PremiumPaymentScreenState();
}

class _PremiumPaymentScreenState extends State<PremiumPaymentScreen>
    with TickerProviderStateMixin {
  // Premium animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  // High-end animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  // Payment state
  String _selectedPaymentMethod = 'stripeSheet';
  bool _isProcessingPayment = false;
  bool _showPaymentSheet = false;

  // Premium payment methods
  final List<PremiumPaymentMethod> _paymentMethods = [
    PremiumPaymentMethod(
      id: 'stripeSheet',
      name: 'Card Payment',
      description: 'Visa, Mastercard, Amex',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.primaryColor,
      gradient: [
        AppColors.primaryColor,
        AppColors.primaryColor.withOpacity(0.8),
      ],
      processingFee: 2.9,
      isRecommended: true,
      isInstant: true,
    ),
    PremiumPaymentMethod(
      id: 'applePay',
      name: 'Apple Pay',
      description: 'Touch ID, Face ID, or Apple Watch',
      icon: CupertinoIcons.device_phone_portrait,
      color: const Color(0xFF000000),
      gradient: [
        const Color(0xFF000000),
        const Color(0xFF333333),
      ],
      processingFee: 0.0,
      isRecommended: false,
      isInstant: true,
    ),
    PremiumPaymentMethod(
      id: 'googlePay',
      name: 'Google Pay',
      description: 'Quick & secure payments',
      icon: CupertinoIcons.money_dollar_circle,
      color: AppColors.successColor,
      gradient: [
        AppColors.successColor,
        AppColors.tealColor,
      ],
      processingFee: 0.0,
      isRecommended: false,
      isInstant: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    // Fade animation for overall screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Scale animation for payment cards
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Shimmer effect for selected elements
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation for CTA buttons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

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
  }

  void _startEntryAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E1A),
              AppColors.primaryColor.withOpacity(0.1),
              AppColors.tealColor.withOpacity(0.1),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildPremiumHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const Gap(32),
                          _buildPaymentSummaryCard(),
                          const Gap(32),
                          _buildPaymentMethodsSection(),
                          const Gap(32),
                          _buildSecuritySection(),
                          const Gap(40),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildPremiumPaymentButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? 'Complete Payment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(4),
                Text(
                  'Secure payment powered by Stripe',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.tealColor,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );

    final baseAmount = widget.paymentRequest.amount.amount;
    final processingFee = (baseAmount * selectedMethod.processingFee / 100);
    final totalAmount = baseAmount + processingFee;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: selectedMethod.color.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Payment header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedMethod.gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                    size: 28,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        widget.paymentRequest.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(24),

            // Amount breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildAmountRow('Service Amount', baseAmount, false),
                  if (processingFee > 0) ...[
                    const Gap(12),
                    _buildAmountRow(
                        'Processing Fee (${selectedMethod.processingFee}%)',
                        processingFee,
                        false,
                        isProcessingFee: true),
                  ],
                  const Gap(16),
                  Container(
                    height: 1,
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
                  const Gap(16),
                  _buildAmountRow('Total Amount', totalAmount, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, bool isTotal,
      {bool isProcessingFee = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? Colors.white
                : isProcessingFee
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.8),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          'EGP ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal
                ? AppColors.tealColor
                : isProcessingFee
                    ? AppColors.orangeColor
                    : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Payment Method',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Gap(20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 3.5,
            mainAxisSpacing: 16,
          ),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            return _buildPremiumPaymentMethodCard(_paymentMethods[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPremiumPaymentMethodCard(PremiumPaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPaymentMethod = method.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    method.color.withOpacity(0.3),
                    method.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? method.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: method.color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
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
                      borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? method.gradient
                            : [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: method.color.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      method.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              method.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(8),
                            if (method.isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            Text(
                              method.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (method.processingFee > 0)
                              Text(
                                '${method.processingFee}% fee',
                                style: TextStyle(
                                  color: AppColors.orangeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Text(
                                'No fees',
                                style: TextStyle(
                                  color: AppColors.successColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? method.color
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? method.color
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.successColor.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successColor,
                  AppColors.tealColor,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.shield_lefthalf_fill,
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
                  'Bank-Grade Security',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your payment is protected by 256-bit SSL encryption and PCI DSS compliance.',
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

  Widget _buildPremiumPaymentButton() {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method.id == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );

    final baseAmount = widget.paymentRequest.amount.amount;
    final processingFee = (baseAmount * selectedMethod.processingFee / 100);
    final totalAmount = baseAmount + processingFee;

    return Container(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isProcessingPayment ? 1.0 : _pulseAnimation.value,
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: _isProcessingPayment
                    ? LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.6),
                          Colors.grey.withOpacity(0.4),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: selectedMethod.gradient,
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isProcessingPayment
                    ? []
                    : [
                        BoxShadow(
                          color: selectedMethod.color.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: selectedMethod.color.withOpacity(0.2),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _isProcessingPayment ? null : _processPayment,
                  borderRadius: BorderRadius.circular(20),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
        },
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    HapticFeedback.mediumImpact();

    try {
      // Use PaymentOrchestrator to handle the actual payment
      final paymentResponse = await PaymentOrchestrator.showPaymentScreen(
        context: context,
        paymentRequest: widget.paymentRequest,
        title: 'Complete Payment',
        showSavedMethods: widget.showSavedMethods,
        customerId: widget.customerId,
      );

      if (mounted) {
        setState(() => _isProcessingPayment = false);

        if (paymentResponse != null) {
          HapticFeedback.heavyImpact();
          Navigator.of(context).pop(paymentResponse);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        HapticFeedback.heavyImpact();
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

/// Premium Payment Method Data Model
class PremiumPaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final double processingFee;
  final bool isRecommended;
  final bool isInstant;

  PremiumPaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.processingFee,
    this.isRecommended = false,
    this.isInstant = true,
  });
}

/// Payment Summary Item for additional breakdown
class PaymentSummaryItem {
  final String label;
  final double amount;
  final bool isTotal;
  final Color? color;

  PaymentSummaryItem({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.color,
  });
}
