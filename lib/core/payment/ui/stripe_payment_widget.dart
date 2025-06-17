import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:gap/gap.dart';
import '../../utils/colors.dart';
import '../../utils/text_style.dart' as app_text_style;
import '../models/payment_models.dart';
import '../gateways/stripe/stripe_service.dart';

/// Modern, glassmorphic Stripe payment widget that matches the app's design system
/// Features: Dark theme, smooth animations, glassmorphism, excellent UX
class StripePaymentWidget extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final Function(PaymentResponse) onPaymentComplete;
  final Function(String)? onError;
  final bool showSavedMethods;
  final String? customerId;
  final VoidCallback? onCancel;

  const StripePaymentWidget({
    super.key,
    required this.paymentRequest,
    required this.onPaymentComplete,
    this.onError,
    this.showSavedMethods = true,
    this.customerId,
    this.onCancel,
  });

  @override
  State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget>
    with TickerProviderStateMixin {
  final StripeService _stripeService = StripeService();

  // Simplified animation controllers - only keep essential ones
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodData> _savedMethods = [];
  PaymentMethodData? _selectedSavedMethod;
  bool _showCardForm = true;
  bool _saveCard = false;

  // Form controllers
  final _cardController = stripe.CardFormEditController();

  // Payment step tracking
  int _currentStep =
      0; // 0: method selection, 1: card details, 2: processing, 3: success

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.showSavedMethods && widget.customerId != null) {
      _loadSavedPaymentMethods();
    }
  }

  void _initializeAnimations() {
    // Only keep fade animation for smooth entry
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animation immediately
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPaymentMethods() async {
    try {
      final methods = await _stripeService.getSavedPaymentMethods(
        customerId: widget.customerId!,
      );
      if (mounted) {
        setState(() {
          _savedMethods = methods;
          if (_savedMethods.isNotEmpty) {
            _showCardForm = false;
          }
        });
      }
    } catch (e) {
      // Silently handle error - user can still enter new card
      debugPrint('Error loading saved payment methods: $e');
    }
  }

  Future<void> _processPayment() async {
    if (_isLoading) return;

    // Validate that either a saved method is selected or card form is filled
    if (_selectedSavedMethod == null && !_showCardForm) {
      setState(() {
        _errorMessage = 'Please select a payment method or enter card details';
      });
      return;
    }

    // If using new card, validate that the form is complete
    if (_showCardForm && !_cardController.details.complete) {
      setState(() {
        _errorMessage = 'Please complete all card details';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStep = 2;
      _errorMessage = null;
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      PaymentResponse response;

      if (_selectedSavedMethod != null) {
        // Use saved payment method
        response = await _stripeService.createReservationPayment(
          reservationId: widget.paymentRequest.id,
          amount: widget.paymentRequest.amount.amount,
          currency: widget.paymentRequest.amount.currency,
          customer: widget.paymentRequest.customer,
          description: widget.paymentRequest.description,
          metadata: widget.paymentRequest.metadata,
        );
      } else {
        // Use new card - create payment intent and confirm with card details
        debugPrint('🔄 Creating payment intent for new card...');

        // First create payment intent on server
        final paymentIntentResult = await _stripeService.createPaymentIntent(
          amount: widget.paymentRequest.amount.amount,
          currency: widget.paymentRequest.amount.currency,
          customer: widget.paymentRequest.customer,
          description: widget.paymentRequest.description,
          metadata: {
            'type': 'reservation',
            'reservation_id': widget.paymentRequest.id,
            ...?widget.paymentRequest.metadata,
          },
        );

        final clientSecret = paymentIntentResult['client_secret'] as String;
        debugPrint('✅ Payment intent created with client secret');

        // Present payment sheet to collect and confirm payment
        debugPrint('🔄 Presenting payment sheet...');

        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Shamil App',
            customerId: widget.paymentRequest.customer.id,
            customerEphemeralKeySecret:
                null, // We'll handle this later if needed
            appearance: stripe.PaymentSheetAppearance(
              colors: stripe.PaymentSheetAppearanceColors(
                primary: AppColors.primaryColor,
                background: const Color(0xFF0A0E1A),
                componentBackground: const Color(0xFF1A1F2E),
              ),
            ),
            billingDetails: stripe.BillingDetails(
              email: widget.paymentRequest.customer.email,
              name: widget.paymentRequest.customer.name,
              phone: widget.paymentRequest.customer.phone,
            ),
          ),
        );

        final presentResult =
            await stripe.Stripe.instance.presentPaymentSheet();
        debugPrint('✅ Payment sheet completed');

        // Payment sheet completed successfully
        response = PaymentResponse(
          id: paymentIntentResult['id'] ?? '',
          status:
              PaymentStatus.completed, // Payment sheet success means completed
          amount: widget.paymentRequest.amount.amount,
          currency: widget.paymentRequest.amount.currency,
          gateway: PaymentGateway.stripe,
          gatewayResponse: {
            'id': paymentIntentResult['id'],
            'status': 'succeeded',
            'amount': paymentIntentResult['amount'],
            'currency': paymentIntentResult['currency'],
            'created': paymentIntentResult['created'],
          },
          metadata: widget.paymentRequest.metadata,
          timestamp: DateTime.now(),
        );
      }

      // Check if payment was successful
      if (response.isSuccessful) {
        // Success animation
        setState(() {
          _currentStep = 3;
        });

        HapticFeedback.heavyImpact();

        // Delay to show success animation
        await Future.delayed(const Duration(milliseconds: 1500));

        widget.onPaymentComplete(response);
      } else {
        throw Exception(response.errorMessage ?? 'Payment failed');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();

      String errorMessage = 'Payment failed';
      if (e is stripe.StripeException) {
        errorMessage =
            e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      setState(() {
        _errorMessage = errorMessage;
        _currentStep = 0; // Return to integrated form
      });
      widget.onError?.call(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PaymentStatus _mapStripeStatusToPaymentStatus(
      stripe.PaymentIntentsStatus status) {
    switch (status) {
      case stripe.PaymentIntentsStatus.Succeeded:
        return PaymentStatus.completed;
      case stripe.PaymentIntentsStatus.Processing:
        return PaymentStatus.processing;
      case stripe.PaymentIntentsStatus.RequiresPaymentMethod:
      case stripe.PaymentIntentsStatus.RequiresConfirmation:
      case stripe.PaymentIntentsStatus.RequiresAction:
        return PaymentStatus.pending;
      case stripe.PaymentIntentsStatus.Canceled:
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(0),
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
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: _buildPremiumPaymentContent(),
        ),
      ),
    );
  }

  Widget _buildPremiumPaymentContent() {
    switch (_currentStep) {
      case 2:
        return _buildPremiumProcessingState();
      case 3:
        return _buildPremiumSuccessState();
      default:
        return _buildPremiumPaymentForm();
    }
  }

  Widget _buildPaymentContent() {
    switch (_currentStep) {
      case 2:
        return _buildProcessingState();
      case 3:
        return _buildSuccessState();
      default:
        return _buildIntegratedPaymentForm();
    }
  }

  Widget _buildIntegratedPaymentForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader('Payment Method'),
          const Gap(16),

          // Amount display
          _buildAmountDisplay(),
          const Gap(20),

          // Payment methods with integrated card form
          if (_savedMethods.isNotEmpty) ...[
            Text(
              'Saved Payment Methods',
              style: app_text_style.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.lightText,
              ),
            ),
            const Gap(12),
            ..._savedMethods.map((method) => _buildSavedMethodCard(method)),
            const Gap(16),
          ],

          // New card option with integrated form
          _buildIntegratedCardSection(),

          // Error message
          if (_errorMessage != null) ...[
            const Gap(16),
            _buildErrorMessage(),
          ],

          const Gap(24),

          // Pay button (replaces continue button)
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Processing animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.tealColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              color: Colors.white,
              size: 36,
            ),
          ),
          const Gap(32),

          Text(
            'Processing Payment',
            style: app_text_style.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.lightText,
            ),
          ),
          const Gap(12),

          Text(
            'Please wait while we securely process your payment...',
            style: app_text_style.getbodyStyle(
              fontSize: 14,
              color: AppColors.lightText.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),

          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successColor,
                  AppColors.tealColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.checkmark,
              color: Colors.white,
              size: 40,
            ),
          ),
          const Gap(32),

          Text(
            'Payment Successful!',
            style: app_text_style.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.lightText,
            ),
          ),
          const Gap(12),

          Text(
            'Your payment has been processed successfully.',
            style: app_text_style.getbodyStyle(
              fontSize: 14,
              color: AppColors.lightText.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: app_text_style.getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
        ),
        if (widget.onCancel != null)
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.xmark,
                size: 18,
                color: AppColors.lightText.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.2),
            AppColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: app_text_style.getbodyStyle(
                  fontSize: 14,
                  color: AppColors.lightText.withValues(alpha: 0.7),
                ),
              ),
              const Gap(4),
              Text(
                widget.paymentRequest.description,
                style: app_text_style.getSmallStyle(
                  fontSize: 12,
                  color: AppColors.lightText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Text(
            '${widget.paymentRequest.amount.currency.symbol}${widget.paymentRequest.amount.amount.toStringAsFixed(2)}',
            style: app_text_style.getTitleStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMethodCard(PaymentMethodData method) {
    final isSelected = _selectedSavedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSavedMethod = method;
          _showCardForm = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.tealColor.withValues(alpha: 0.2),
                    AppColors.tealColor.withValues(alpha: 0.1),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.tealColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCardIcon(method.brand ?? 'card'),
                color: Colors.white,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** **** **** ${method.last4 ?? '****'}',
                    style: app_text_style.getbodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightText,
                    ),
                  ),
                  Text(
                    '${(method.brand ?? 'CARD').toUpperCase()} • Expires ${method.expMonth?.toString() ?? '**'}/${method.expYear?.toString() ?? '**'}',
                    style: app_text_style.getSmallStyle(
                      fontSize: 12,
                      color: AppColors.lightText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.tealColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedCardSection() {
    final isSelected = _showCardForm;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.tealColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.tealColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card option header
          GestureDetector(
            onTap: () {
              setState(() {
                _showCardForm = !_showCardForm;
                if (_showCardForm) {
                  _selectedSavedMethod = null;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credit or Debit Card',
                          style: app_text_style.getbodyStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightText,
                          ),
                        ),
                        Text(
                          isSelected
                              ? 'Enter your card details below'
                              : 'Tap to enter card details',
                          style: app_text_style.getSmallStyle(
                            fontSize: 12,
                            color: AppColors.lightText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: AppColors.lightText.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Use Stripe's built-in Payment Sheet instead of custom form
          if (isSelected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Stripe Payment Sheet integration notice
                  Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        labelStyle: app_text_style.getbodyStyle(
                          color: AppColors.lightText.withValues(alpha: 0.7),
                        ),
                        hintStyle: app_text_style.getbodyStyle(
                          color: AppColors.lightText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: stripe.CardFormField(
                      controller: _cardController,
                      style: stripe.CardFormStyle(
                        backgroundColor: Colors.transparent,
                        textColor: AppColors.lightText,
                        fontSize: 16,
                        placeholderColor:
                            AppColors.lightText.withValues(alpha: 0.5),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        borderRadius: 12,
                        borderWidth: 1,
                      ),
                    ),
                  ),

                  const Gap(16),

                  // Save card option
                  GestureDetector(
                    onTap: () => setState(() => _saveCard = !_saveCard),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _saveCard
                                ? AppColors.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _saveCard
                                  ? AppColors.primaryColor
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _saveCard
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            'Save this card for future payments',
                            style: app_text_style.getbodyStyle(
                              fontSize: 14,
                              color: AppColors.lightText.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            AppColors.dangerColor.withValues(alpha: 0.2),
            AppColors.dangerColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dangerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: AppColors.dangerColor,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: app_text_style.getbodyStyle(
                fontSize: 14,
                color: AppColors.dangerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final canPay = (_selectedSavedMethod != null) ||
        (_showCardForm && _cardController.details.complete);
    final buttonText = _isLoading
        ? 'Processing...'
        : 'Pay ${widget.paymentRequest.amount.currency}${widget.paymentRequest.amount.amount.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: canPay && !_isLoading ? _processPayment : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: canPay && !_isLoading
              ? AppColors.primaryColor
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canPay && !_isLoading
                ? AppColors.primaryColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  buttonText,
                  style: app_text_style.getButtonStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: canPay && !_isLoading
                        ? Colors.white
                        : AppColors.lightText.withValues(alpha: 0.5),
                  ),
                ),
        ),
      ),
    );
  }

  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return CupertinoIcons.creditcard_fill;
      case 'mastercard':
        return CupertinoIcons.creditcard_fill;
      case 'amex':
      case 'american_express':
        return CupertinoIcons.creditcard_fill;
      default:
        return CupertinoIcons.creditcard_fill;
    }
  }

  // Premium payment methods with high-end UI/UX
  Widget _buildPremiumPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(),
          const Gap(32),
          _buildPremiumAmountDisplay(),
          const Gap(32),
          _buildPremiumStripeIntegration(),
          if (_errorMessage != null) ...[
            const Gap(24),
            _buildPremiumErrorMessage(),
          ],
          const Gap(32),
          _buildPremiumPayButton(),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.tealColor,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(4),
              Text(
                'Secure Card Payment',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${widget.paymentRequest.amount.currency.name.toUpperCase()} ${widget.paymentRequest.amount.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.tealColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStripeIntegration() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
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
                  CupertinoIcons.device_phone_portrait,
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
                      'Stripe Payment Sheet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Tap below to open the secure payment form',
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
        ],
      ),
    );
  }

  Widget _buildPremiumErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.dangerColor.withOpacity(0.2),
            AppColors.dangerColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dangerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.dangerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.dangerColor,
              size: 16,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.dangerColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPayButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.6),
                  Colors.grey.withOpacity(0.4),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _isLoading ? null : _processPayment,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
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
                      const Icon(
                        CupertinoIcons.creditcard_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                      const Gap(12),
                      Text(
                        'Pay ${widget.paymentRequest.amount.currency.name.toUpperCase()} ${widget.paymentRequest.amount.amount.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildPremiumProcessingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.tealColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              color: Colors.white,
              size: 36,
            ),
          ),
          const Gap(32),
          Text(
            'Processing Payment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(12),
          Text(
            'Please wait while we securely process your payment...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(40),
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.tealColor,
                    AppColors.primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSuccessState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successColor,
                  AppColors.tealColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successColor.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.checkmark,
              color: Colors.white,
              size: 40,
            ),
          ),
          const Gap(32),
          Text(
            'Payment Successful!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(12),
          Text(
            'Your payment has been processed successfully.',
            style: TextStyle(
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
}
