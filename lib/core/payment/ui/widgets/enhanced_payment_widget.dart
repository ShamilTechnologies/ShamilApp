import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:gap/gap.dart';
import '../../models/payment_models.dart';
import '../../gateways/stripe/stripe_service.dart';

/// Enhanced payment widget with modern design and better credit card input handling
class EnhancedPaymentWidget extends StatefulWidget {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final String description;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailure;
  final VoidCallback onPaymentCancelled;
  final bool showSavedMethods;
  final bool allowSaving;
  final Map<String, dynamic>? metadata;

  const EnhancedPaymentWidget({
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
  State<EnhancedPaymentWidget> createState() => _EnhancedPaymentWidgetState();
}

class _EnhancedPaymentWidgetState extends State<EnhancedPaymentWidget>
    with SingleTickerProviderStateMixin {
  final StripeService _stripeService = StripeService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;
  List<PaymentMethodData> _savedMethods = [];
  PaymentMethodData? _selectedSavedMethod;
  bool _showCardForm = true;
  bool _saveCard = false;

  // Card form controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCardValid = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showSavedMethods) {
      _loadSavedPaymentMethods();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadSavedPaymentMethods() async {
    try {
      final methods = await _stripeService.getSavedPaymentMethods(
        customerId: widget.customer.id,
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
    }
  }

  Future<void> _processPayment() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedSavedMethod != null) {
        // Use saved payment method
        await _processWithSavedMethod();
      } else {
        // Validate card form first
        if (!_formKey.currentState!.validate()) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please fill in all card details correctly';
          });
          return;
        }

        // Process with new card
        await _processWithNewCard();
      }

      widget.onPaymentSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      widget.onPaymentFailure();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processWithSavedMethod() async {
    // Implementation for saved payment method
    // For now, simulate success
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _processWithNewCard() async {
    // Create payment intent
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

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAmountCard(),
                        const Gap(24),
                        _buildPaymentMethodSection(),
                        const Gap(24),
                        if (_errorMessage != null) _buildErrorMessage(),
                        _buildPayButton(),
                        const Gap(16),
                        _buildSecurityNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.creditcard,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Payment',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Secure payment powered by Stripe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onPaymentCancelled,
                icon: const Icon(CupertinoIcons.xmark),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
              const Gap(4),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
            ],
          ),
          Text(
            '${widget.amount.currency.symbol}${widget.amount.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(16),

        // Saved methods
        if (_savedMethods.isNotEmpty) ...[
          ..._savedMethods.map((method) => _buildSavedMethodCard(method)),
          const Gap(12),
          _buildAddNewCardButton(),
        ],

        // Card form
        if (_showCardForm) _buildCardForm(),
      ],
    );
  }

  Widget _buildSavedMethodCard(PaymentMethodData method) {
    final isSelected = _selectedSavedMethod?.id == method.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSavedMethod = isSelected ? null : method;
          _showCardForm = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  method.brand?.toUpperCase() ?? 'CARD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** **** **** ${method.last4}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    'Expires ${method.expMonth?.toString().padLeft(2, '0')}/${method.expYear.toString().substring(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Colors.blue.shade600,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCardButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showCardForm = true;
          _selectedSavedMethod = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                CupertinoIcons.plus,
                color: Colors.blue.shade600,
                size: 16,
              ),
            ),
            const Gap(12),
            Text(
              'Add new payment method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          const Gap(8),

          // Cardholder name
          _buildTextField(
            controller: _nameController,
            label: 'Cardholder Name',
            hint: 'John Doe',
            prefixIcon: CupertinoIcons.person,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          const Gap(16),

          // Card number
          _buildTextField(
            controller: _cardNumberController,
            label: 'Card Number',
            hint: '1234 5678 9012 3456',
            prefixIcon: CupertinoIcons.creditcard,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter card number';
              }
              if (value!.replaceAll(' ', '').length < 16) {
                return 'Card number must be 16 digits';
              }
              return null;
            },
          ),
          const Gap(16),

          // Expiry and CVC
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expiryController,
                  label: 'MM/YY',
                  hint: '12/25',
                  prefixIcon: CupertinoIcons.calendar,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Required';
                    }
                    if (value!.length < 5) {
                      return 'Invalid date';
                    }
                    return null;
                  },
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildTextField(
                  controller: _cvcController,
                  label: 'CVC',
                  hint: '123',
                  prefixIcon: CupertinoIcons.lock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Required';
                    }
                    if (value!.length < 3) {
                      return 'Invalid CVC';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          if (widget.allowSaving) ...[
            const Gap(16),
            Row(
              children: [
                Checkbox(
                  value: _saveCard,
                  onChanged: (value) {
                    setState(() {
                      _saveCard = value ?? false;
                    });
                  },
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Save this card for future payments',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: Colors.red.shade600,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay ${widget.amount.currency.symbol}${widget.amount.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.lock_shield,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const Gap(8),
        Text(
          'Your payment is secured with 256-bit SSL encryption',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

// Input formatters for card fields
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(' ', '');
    if (newText.length > 16) return oldValue;

    String formatted = '';
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += newText[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll('/', '');
    if (newText.length > 4) return oldValue;

    String formatted = newText;
    if (newText.length > 2) {
      formatted = '${newText.substring(0, 2)}/${newText.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
