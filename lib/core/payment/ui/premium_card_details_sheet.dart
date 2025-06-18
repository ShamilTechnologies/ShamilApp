import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:gap/gap.dart';
import '../../../core/utils/colors.dart';
import '../models/payment_models.dart';
import '../gateways/stripe/stripe_service.dart';

/// Premium credit card details collection with enhanced UX
/// Features: Real-world card design, form validation, secure Stripe processing
/// Note: This component is currently NOT used in the main payment flow.
/// The app now uses direct Stripe Payment Sheet for better security and UX.
/// This file is kept for potential future use or custom payment scenarios.
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
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text;
    final cvv = _cvvController.text;
    final name = _nameController.text.trim();

    // Enhanced validation logic
    bool isCardNumberValid =
        cardNumber.length == 16 && RegExp(r'^[0-9]+$').hasMatch(cardNumber);

    bool isExpiryValid = expiry.length == 5 &&
        expiry.contains('/') &&
        _isValidExpiryDate(expiry);

    bool isCvvValid =
        cvv.length >= 3 && cvv.length <= 4 && RegExp(r'^[0-9]+$').hasMatch(cvv);

    bool isNameValid = name.isNotEmpty && name.length >= 2;

    final isValid =
        isCardNumberValid && isExpiryValid && isCvvValid && isNameValid;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
        _errorMessage = null;
      });
    }
  }

  bool _isValidExpiryDate(String expiry) {
    if (!expiry.contains('/') || expiry.length != 5) return false;

    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    // Check if card is not expired
    final now = DateTime.now();
    final fullYear = 2000 + year;
    final expiryDate =
        DateTime(fullYear, month + 1, 0); // Last day of expiry month

    return expiryDate.isAfter(now);
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
    // Stop all animations to prevent callbacks after dispose
    _slideController.stop();
    _cardFlipController.stop();
    _shimmerController.stop();
    _pulseController.stop();

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
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E1A),
                  AppColors.premiumBlue.withOpacity(0.15),
                  AppColors.tealColor.withOpacity(0.1),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                child: Opacity(
                  opacity: _slideAnimation.value,
                  child: _buildSheetContent(),
                ),
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
          child: KeyboardAwareScrollView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildCreditCard(),
              const Gap(32),
              _buildCardForm(),
              const Gap(24),
              _buildAmountSummary(),
              const Gap(32),
              if (_errorMessage != null) _buildErrorMessage(),
              if (_errorMessage != null) const Gap(16),
              _buildPaymentButton(),
              // Extra padding for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget KeyboardAwareScrollView({
    required EdgeInsets padding,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: children,
      ),
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
              gradient: AppColors.premiumConfigGradient,
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
            AppColors.premiumBlue,
            AppColors.premiumBlue.withOpacity(0.8),
            AppColors.tealColor,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumBlue.withOpacity(0.3),
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
              AppColors.premiumBlue,
              AppColors.premiumBlue.withOpacity(0.8),
              AppColors.tealColor,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumBlue.withOpacity(0.3),
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
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(focusNode.hasFocus ? 0.12 : 0.08),
                Colors.white.withOpacity(focusNode.hasFocus ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focusNode.hasFocus
                  ? AppColors.premiumBlue.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: focusNode.hasFocus ? 2.0 : 1.5,
            ),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.premiumBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
            textInputAction: _getTextInputAction(focusNode),
            onSubmitted: onSubmitted,
            onChanged: (value) {
              // Trigger validation on every change
              _validateForm();
            },
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus
                    ? AppColors.premiumBlue
                    : Colors.white.withOpacity(0.6),
                size: 20,
              ),
              labelStyle: TextStyle(
                color: focusNode.hasFocus
                    ? AppColors.premiumBlue
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
              errorText: _getFieldError(focusNode, controller),
              errorStyle: TextStyle(
                color: AppColors.orangeColor,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  TextInputAction _getTextInputAction(FocusNode focusNode) {
    if (focusNode == _cardNumberFocus) return TextInputAction.next;
    if (focusNode == _expiryFocus) return TextInputAction.next;
    if (focusNode == _cvvFocus) return TextInputAction.next;
    if (focusNode == _nameFocus) return TextInputAction.done;
    return TextInputAction.done;
  }

  String? _getFieldError(
      FocusNode focusNode, TextEditingController controller) {
    if (!focusNode.hasFocus && controller.text.isNotEmpty) {
      if (focusNode == _cardNumberFocus) {
        final cardNumber = controller.text.replaceAll(' ', '');
        if (cardNumber.length != 16 ||
            !RegExp(r'^[0-9]+$').hasMatch(cardNumber)) {
          return 'Please enter a valid 16-digit card number';
        }
      } else if (focusNode == _expiryFocus) {
        if (!_isValidExpiryDate(controller.text)) {
          return 'Please enter a valid expiry date (MM/YY)';
        }
      } else if (focusNode == _cvvFocus) {
        final cvv = controller.text;
        if (cvv.length < 3 ||
            cvv.length > 4 ||
            !RegExp(r'^[0-9]+$').hasMatch(cvv)) {
          return 'Please enter a valid CVV';
        }
      } else if (focusNode == _nameFocus) {
        if (controller.text.trim().length < 2) {
          return 'Please enter the cardholder name';
        }
      }
    }
    return null;
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

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orangeColor.withOpacity(0.2),
            AppColors.orangeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.orangeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: AppColors.orangeColor,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    ? AppColors.premiumConfigGradient
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
                          color: AppColors.premiumBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isProcessing
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
    if (!_isFormValid || _isProcessing || !mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      debugPrint('🚀 Starting Premium Card Payment - Seamless Processing...');

      // Initialize Stripe Service
      final stripeService = StripeService();
      await stripeService.initialize();

      // Extract card details from form for display purposes only
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final holderName = _nameController.text.trim();

      debugPrint(
          '🔐 Processing payment for: **** **** **** ${cardNumber.substring(12)}');

      // Create Payment Intent
      final paymentIntent = await stripeService.createPaymentIntent(
        amount: widget.paymentRequest.amount.amount,
        currency: widget.paymentRequest.amount.currency,
        customer: widget.paymentRequest.customer,
        description: widget.paymentRequest.description,
        metadata: {
          ...?widget.paymentRequest.metadata,
          'card_last4': cardNumber.substring(12),
          'cardholder_name': holderName,
          'payment_source': 'premium_card_seamless',
          'checkout_type': 'reservation',
          'card_type': _cardType,
        },
      );

      if (!mounted) return;
      debugPrint('✅ Payment Intent created: ${paymentIntent['id']}');

      // Create billing details
      final billingDetails = stripe.BillingDetails(
        name: holderName,
        email: widget.paymentRequest.customer.email,
      );

      debugPrint('💳 Processing payment with seamless Stripe integration...');

      // Use the more secure approach: let Stripe handle card processing
      // but with minimal UI - present payment sheet in confirmation mode only
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Shamil App',
          customerId: widget.paymentRequest.customer.id,
          // Use default styling for minimal, fast processing
          style: ThemeMode.system,
          // Simplified setup - no custom appearance for faster processing
        ),
      );

      if (!mounted) return;

      // Present the payment sheet (this should be very quick since payment intent is ready)
      await stripe.Stripe.instance.presentPaymentSheet();

      if (!mounted) return;
      debugPrint('✅ Payment processed seamlessly through Stripe');

      // Verify payment completion
      final verificationResponse = await stripeService.verifyPayment(
        paymentIntentId: paymentIntent['id'],
      );

      if (!mounted) return;

      if (verificationResponse.isSuccessful) {
        debugPrint('🎉 Payment verification successful!');

        // Create enhanced response
        final enhancedResponse = PaymentResponse(
          id: verificationResponse.id,
          status: verificationResponse.status,
          amount: verificationResponse.amount,
          currency: verificationResponse.currency,
          gateway: verificationResponse.gateway,
          gatewayResponse: verificationResponse.gatewayResponse,
          metadata: {
            ...?verificationResponse.metadata,
            'payment_intent_id': paymentIntent['id'],
            'card_last4': cardNumber.substring(12),
            'card_type': _cardType,
            'cardholder_name': holderName,
            'checkout_completed': 'true',
            'payment_flow': 'premium_ui_seamless_stripe',
            'form_validation': 'complete',
            'security_method': 'stripe_minimal_sheet',
            'ui_experience': 'premium_with_secure_processing',
          },
          timestamp: verificationResponse.timestamp,
        );

        // Success haptic feedback
        HapticFeedback.heavyImpact();

        // Call completion handler
        widget.onPaymentComplete(enhancedResponse);

        // Close the sheet
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          // Brief success indication
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(enhancedResponse);
          }
        }
      } else {
        throw Exception(
            'Payment verification failed: ${verificationResponse.status}');
      }
    } on stripe.StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.localizedMessage}');
      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // Handle specific Stripe errors with user-friendly messages
      String errorMessage = 'Payment failed. Please try again.';

      switch (e.error.code) {
        case 'card_declined':
          errorMessage = 'Your card was declined. Please try a different card.';
          break;
        case 'expired_card':
          errorMessage = 'Your card has expired. Please use a different card.';
          break;
        case 'incorrect_cvc':
          errorMessage = 'Your card\'s security code is incorrect.';
          break;
        case 'processing_error':
          errorMessage =
              'An error occurred while processing your card. Please try again.';
          break;
        case 'incorrect_number':
          errorMessage = 'Your card number is incorrect.';
          break;
        case 'insufficient_funds':
          errorMessage = 'Your card has insufficient funds.';
          break;
        case 'authentication_required':
          errorMessage =
              'Your bank requires additional authentication. Please try again.';
          break;
        case 'payment_intent_authentication_failure':
          errorMessage = 'Payment authentication failed. Please try again.';
          break;
        default:
          errorMessage = e.error.localizedMessage ?? errorMessage;
      }

      setState(() {
        _errorMessage = errorMessage;
        _isProcessing = false;
      });

      widget.onError?.call(_errorMessage!);
    } catch (e) {
      debugPrint('❌ Payment processing error: $e');
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage =
            'Payment failed. Please check your details and try again.';
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
    final text = newValue.text.replaceAll('/', '');

    // Limit to 4 digits
    if (text.length > 4) {
      return oldValue;
    }

    String formattedText = text;
    int cursorPosition = text.length;

    // Add slash after month (2 digits)
    if (text.length >= 2) {
      formattedText = '${text.substring(0, 2)}/${text.substring(2)}';
      // Adjust cursor position after slash
      if (newValue.selection.baseOffset >= 2) {
        cursorPosition = text.length + 1;
      } else {
        cursorPosition = newValue.selection.baseOffset;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
