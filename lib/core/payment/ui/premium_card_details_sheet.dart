import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:gap/gap.dart';
import '../../utils/colors.dart';
import '../models/payment_models.dart';

/// Premium swipable credit card details collection sheet
/// Features: Real-world card design, glassmorphism, premium animations
class PremiumCardDetailsSheet extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final Function(PaymentResponse) onPaymentComplete;
  final Function(String)? onError;
  final VoidCallback? onCancel;

  const PremiumCardDetailsSheet({
    super.key,
    required this.paymentRequest,
    required this.onPaymentComplete,
    this.onError,
    this.onCancel,
  });

  @override
  State<PremiumCardDetailsSheet> createState() =>
      _PremiumCardDetailsSheetState();
}

class _PremiumCardDetailsSheetState extends State<PremiumCardDetailsSheet>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _cardFlipController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _slideAnimation;
  late Animation<double> _cardFlipAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  final _cardNumberFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();
  final _nameFocus = FocusNode();

  // State variables
  bool _isProcessing = false;
  bool _showBack = false;
  String _cardType = 'unknown';
  bool _isFormValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFormListeners();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _cardFlipAnimation = CurvedAnimation(
      parent: _cardFlipController,
      curve: Curves.easeInOut,
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

    // Start animations
    _slideController.forward();
    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  void _setupFormListeners() {
    _cardNumberController.addListener(_validateForm);
    _expiryController.addListener(_validateForm);
    _cvvController.addListener(_validateForm);
    _nameController.addListener(_validateForm);

    _cardNumberController.addListener(() {
      setState(() {
        _cardType = _detectCardType(_cardNumberController.text);
      });
    });

    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_showBack) {
        _flipToBack();
      } else if (!_cvvFocus.hasFocus && _showBack) {
        _flipToFront();
      }
    });
  }

  void _validateForm() {
    final isValid =
        _cardNumberController.text.replaceAll(' ', '').length >= 16 &&
            _expiryController.text.length >= 5 &&
            _cvvController.text.length >= 3 &&
            _nameController.text.trim().isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
        _errorMessage = null;
      });
    }
  }

  String _detectCardType(String number) {
    final cleanNumber = number.replaceAll(' ', '');
    if (cleanNumber.startsWith('4')) return 'visa';
    if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2'))
      return 'mastercard';
    if (cleanNumber.startsWith('3')) return 'amex';
    return 'unknown';
  }

  void _flipToBack() {
    if (!_showBack) {
      setState(() => _showBack = true);
      _cardFlipController.forward();
    }
  }

  void _flipToFront() {
    if (_showBack) {
      _cardFlipController.reverse().then((_) {
        setState(() => _showBack = false);
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardFlipController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();

    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();

    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _nameFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0E1A),
                AppColors.primaryColor.withOpacity(0.15),
                AppColors.tealColor.withOpacity(0.1),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: _buildSheetContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetContent() {
    return Column(
      children: [
        _buildSheetHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCreditCard(),
                const Gap(32),
                _buildCardForm(),
                const Gap(24),
                _buildAmountSummary(),
                const Gap(32),
                _buildPaymentButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Card Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard() {
    return AnimatedBuilder(
      animation: _cardFlipAnimation,
      builder: (context, child) {
        final isShowingFront = _cardFlipAnimation.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_cardFlipAnimation.value * 3.14159),
          child: Container(
            width: double.infinity,
            height: 200,
            child: isShowingFront ? _buildCardFront() : _buildCardBack(),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
            AppColors.tealColor,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card pattern/texture
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + 2 * _shimmerAnimation.value, -1.0),
                    end: Alignment(1.0 + 2 * _shimmerAnimation.value, 1.0),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DEBIT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    _buildCardTypeLogo(),
                  ],
                ),
                const Spacer(),

                // Card number
                Text(
                  _formatCardNumber(_cardNumberController.text),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),

                const Gap(16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          _nameController.text.isEmpty
                              ? 'YOUR NAME'
                              : _nameController.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          _expiryController.text.isEmpty
                              ? 'MM/YY'
                              : _expiryController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
              AppColors.tealColor,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            const Gap(20),

            // Magnetic stripe
            Container(
              height: 40,
              color: Colors.black,
            ),

            const Gap(20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _cvvController.text.isEmpty ? 'CVV' : _cvvController.text,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Authorized signature - not valid unless signed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildCardTypeLogo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeLogo() {
    IconData icon;
    Color color = Colors.white;

    switch (_cardType) {
      case 'visa':
        icon = CupertinoIcons.creditcard_fill;
        break;
      case 'mastercard':
        icon = CupertinoIcons.creditcard_fill;
        break;
      case 'amex':
        icon = CupertinoIcons.creditcard_fill;
        break;
      default:
        icon = CupertinoIcons.creditcard;
        color = Colors.white.withOpacity(0.5);
    }

    return Icon(
      icon,
      color: color,
      size: 32,
    );
  }

  String _formatCardNumber(String number) {
    final cleaned = number.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      if (i < 12) {
        buffer.write('•');
      } else {
        buffer.write(cleaned[i]);
      }
    }

    // Fill remaining with placeholders
    final remaining = 16 - cleaned.length;
    if (remaining > 0) {
      if (cleaned.length > 0 && cleaned.length % 4 == 0) {
        buffer.write(' ');
      }
      for (int i = 0; i < remaining; i++) {
        if (i > 0 && (cleaned.length + i) % 4 == 0) {
          buffer.write(' ');
        }
        buffer.write('•');
      }
    }

    return buffer.toString();
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(16),

        // Card number
        _buildFormField(
          controller: _cardNumberController,
          focusNode: _cardNumberFocus,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          icon: CupertinoIcons.creditcard,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberInputFormatter(),
          ],
          maxLength: 19,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _expiryFocus.requestFocus(),
        ),

        const Gap(16),

        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _expiryController,
                focusNode: _expiryFocus,
                label: 'Expiry Date',
                hint: 'MM/YY',
                icon: CupertinoIcons.calendar,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateInputFormatter(),
                ],
                maxLength: 5,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _cvvFocus.requestFocus(),
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildFormField(
                controller: _cvvController,
                focusNode: _cvvFocus,
                label: 'CVV',
                hint: '123',
                icon: CupertinoIcons.lock_shield,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 4,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _nameFocus.requestFocus(),
              ),
            ),
          ],
        ),

        const Gap(16),

        // Cardholder name
        _buildFormField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: 'Cardholder Name',
          hint: 'John Doe',
          icon: CupertinoIcons.person,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _processPayment(),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primaryColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus
                ? AppColors.primaryColor
                : Colors.white.withOpacity(0.6),
            size: 20,
          ),
          labelStyle: TextStyle(
            color: focusNode.hasFocus
                ? AppColors.primaryColor
                : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
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
                'Amount to pay',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'EGP ${widget.paymentRequest.amount.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.tealColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(12),
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
          const Gap(12),
          Row(
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: AppColors.successColor,
                size: 16,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'Your payment is secured with bank-level encryption',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isFormValid ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _isFormValid && !_isProcessing ? _processPayment : null,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: _isFormValid && !_isProcessing
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.tealColor,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isFormValid && !_isProcessing
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: _isFormValid
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          const Gap(12),
                          Text(
                            'Complete Payment',
                            style: TextStyle(
                              color: _isFormValid
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _processPayment() async {
    if (!_isFormValid || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      final response = PaymentResponse(
        id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
        status: PaymentStatus.completed,
        amount: widget.paymentRequest.amount.amount,
        currency: widget.paymentRequest.amount.currency,
        gateway: PaymentGateway.stripe,
        timestamp: DateTime.now(),
      );

      HapticFeedback.heavyImpact();
      widget.onPaymentComplete(response);
      Navigator.of(context).pop();
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Payment failed. Please try again.';
        _isProcessing = false;
      });
      widget.onError?.call(_errorMessage!);
    }
  }
}

// Custom input formatters
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length == 2 && !text.contains('/')) {
      return TextEditingValue(
        text: '$text/',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    return newValue;
  }
}
