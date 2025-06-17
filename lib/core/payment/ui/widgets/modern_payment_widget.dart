import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../../models/payment_models.dart';
import '../../gateways/stripe/stripe_service.dart';

/// Modern payment widget with seamless UI/UX and smooth interactions
class ModernPaymentWidget extends StatefulWidget {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final String description;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailure;
  final VoidCallback onPaymentCancelled;
  final bool showSavedMethods;
  final bool allowSaving;
  final Map<String, dynamic>? metadata;

  const ModernPaymentWidget({
    super.key,
    required this.amount,
    required this.customer,
    required this.description,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
    required this.onPaymentCancelled,
    this.showSavedMethods = true,
    this.allowSaving = true,
    this.metadata,
  });

  @override
  State<ModernPaymentWidget> createState() => _ModernPaymentWidgetState();
}

class _ModernPaymentWidgetState extends State<ModernPaymentWidget>
    with TickerProviderStateMixin {
  final StripeService _stripeService = StripeService();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // State management
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  List<PaymentMethodData> _savedMethods = [];
  PaymentMethodData? _selectedSavedMethod;
  bool _showCardForm = true;
  bool _saveCard = false;
  bool _isCardValid = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final stripe.CardFormEditController _cardController =
      stripe.CardFormEditController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialState();
    _loadSavedPaymentMethods();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
  }

  void _setupInitialState() {
    _showCardForm = !widget.showSavedMethods;
    _nameController.text = widget.customer.name;
  }

  Future<void> _loadSavedPaymentMethods() async {
    if (!widget.showSavedMethods ||
        widget.customer.id.startsWith('temp_') ||
        widget.customer.id.startsWith('user_') ||
        widget.customer.id == 'current_user_id') {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final methods = await _stripeService.getSavedPaymentMethods(
        customerId: widget.customer.id,
      );

      if (mounted) {
        setState(() {
          _savedMethods = methods;
          _showCardForm = methods.isEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showCardForm = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const Gap(24),
              if (_isLoading)
                _buildLoadingState()
              else ...[
                if (_savedMethods.isNotEmpty && !_showCardForm)
                  _buildSavedMethodsSection(theme),
                if (_showCardForm) _buildCardFormSection(theme),
                const Gap(20),
                _buildPaymentButton(theme),
              ],
              if (_errorMessage != null) ...[
                const Gap(16),
                _buildErrorMessage(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.creditcard,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.amount.currencySymbol} ${widget.amount.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const Gap(16),
            Text(
              'Loading payment methods...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedMethodsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Payment Methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showCardForm = true),
              icon: const Icon(CupertinoIcons.add, size: 16),
              label: const Text('Add New'),
            ),
          ],
        ),
        const Gap(12),
        ..._savedMethods.map((method) => _buildSavedMethodCard(method, theme)),
      ],
    );
  }

  Widget _buildSavedMethodCard(PaymentMethodData method, ThemeData theme) {
    final isSelected = _selectedSavedMethod?.id == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedSavedMethod = method),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primaryColor : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? theme.primaryColor.withOpacity(0.05)
                  : theme.colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.creditcard_fill,
                  color:
                      isSelected ? theme.primaryColor : theme.iconTheme.color,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '**** **** **** ${method.last4 ?? '****'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${method.brand?.toUpperCase() ?? 'CARD'} • Expires ${method.expMonth}/${method.expYear}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: theme.primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFormSection(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_savedMethods.isNotEmpty)
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _showCardForm = false;
                    _selectedSavedMethod = null;
                  }),
                  icon: const Icon(CupertinoIcons.back),
                ),
                Text(
                  'Add New Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Text(
              'Payment Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          const Gap(16),

          // Cardholder Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              prefixIcon: const Icon(CupertinoIcons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),

          const Gap(16),

          // Card Form
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: stripe.CardFormField(
              controller: _cardController,
              style: stripe.CardFormStyle(
                borderColor: Colors.transparent,
                backgroundColor: theme.colorScheme.surface,
                borderRadius: 12,
                fontSize: 16,
                placeholderColor: theme.hintColor,
                textColor: theme.colorScheme.onSurface,
              ),
              onCardChanged: (details) {
                setState(() {
                  _isCardValid = details?.complete ?? false;
                });
              },
            ),
          ),

          if (widget.allowSaving) ...[
            const Gap(16),
            Row(
              children: [
                Checkbox(
                  value: _saveCard,
                  onChanged: (value) =>
                      setState(() => _saveCard = value ?? false),
                ),
                Expanded(
                  child: Text(
                    'Save this card for future payments',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentButton(ThemeData theme) {
    final canPay = (_selectedSavedMethod != null) ||
        (_showCardForm && _isCardValid && _nameController.text.isNotEmpty);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isProcessing ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: canPay && !_isProcessing ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canPay ? 4 : 0,
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const Gap(12),
                        const Text('Processing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.lock_shield, size: 20),
                        const Gap(8),
                        Text(
                          'Pay ${widget.amount.currencySymbol} ${widget.amount.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      if (_selectedSavedMethod != null) {
        await _processWithSavedMethod();
      } else {
        await _processWithNewCard();
      }

      // Success animation
      _pulseController.stop();
      await _successController.forward();

      // Success haptic feedback
      HapticFeedback.lightImpact();

      widget.onPaymentSuccess();
    } catch (e) {
      _pulseController.stop();

      // Error haptic feedback
      HapticFeedback.heavyImpact();

      setState(() {
        _errorMessage = _formatErrorMessage(e.toString());
      });

      widget.onPaymentFailure();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processWithSavedMethod() async {
    // Implementation for saved payment method
    final response = await _stripeService.createReservationPayment(
      reservationId: 'reservation_${DateTime.now().millisecondsSinceEpoch}',
      amount: widget.amount.amount,
      currency: widget.amount.currency,
      customer: widget.customer,
      description: widget.description,
      metadata: widget.metadata,
    );

    if (!response.isSuccessful) {
      throw Exception(response.errorMessage ?? 'Payment failed');
    }
  }

  Future<void> _processWithNewCard() async {
    if (!_formKey.currentState!.validate()) {
      throw Exception('Please fill in all required fields');
    }

    final response = await _stripeService.createReservationPayment(
      reservationId: 'reservation_${DateTime.now().millisecondsSinceEpoch}',
      amount: widget.amount.amount,
      currency: widget.amount.currency,
      customer: widget.customer,
      description: widget.description,
      metadata: widget.metadata,
    );

    if (!response.isSuccessful) {
      throw Exception(response.errorMessage ?? 'Payment failed');
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('card_declined')) {
      return 'Your card was declined. Please try a different payment method.';
    } else if (error.contains('insufficient_funds')) {
      return 'Insufficient funds. Please check your account balance.';
    } else if (error.contains('expired_card')) {
      return 'Your card has expired. Please use a different card.';
    } else if (error.contains('incorrect_cvc')) {
      return 'The security code is incorrect. Please check and try again.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Payment failed. Please try again or contact support.';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _nameController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}
