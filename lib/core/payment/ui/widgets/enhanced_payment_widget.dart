import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import '../../models/payment_models.dart';
import '../../bloc/payment_bloc.dart';
import '../../gateways/stripe/stripe_service.dart';

/// Comprehensive payment screen with BLoC integration
class EnhancedPaymentScreen extends StatefulWidget {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final String description;
  final Map<String, dynamic>? metadata;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;
  final VoidCallback? onCancel;

  const EnhancedPaymentScreen({
    super.key,
    required this.amount,
    required this.customer,
    required this.description,
    this.metadata,
    this.onSuccess,
    this.onFailure,
    this.onCancel,
  });

  @override
  State<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends State<EnhancedPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final stripe.CardFormEditController _cardController =
      stripe.CardFormEditController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State
  bool _isCardValid = false;
  bool _saveCard = false;
  PaymentMethodData? _selectedSavedMethod;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _nameController.text = widget.customer.name;

    // Initialize payment system
    context.read<PaymentBloc>().add(InitializePayments(
          customerId: widget.customer.id,
          loadSavedMethods: true,
        ));
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildContent(context, state),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentState state) {
    if (state is PaymentInitializing || state is PaymentInitial) {
      return _buildLoadingContent('Initializing payment system...');
    }

    if (state is PaymentError && state.isCritical) {
      return _buildErrorContent(state.message, true);
    }

    if (state is PaymentProcessing) {
      return _buildLoadingContent(state.processingMessage);
    }

    if (state is PaymentSuccess) {
      return _buildSuccessContent(state);
    }

    if (state is PaymentFailure) {
      return _buildFailureContent(state);
    }

    if (state is PaymentRequiresAction) {
      return _buildActionRequiredContent(state);
    }

    if (state is PaymentLoaded) {
      return _buildPaymentForm(context, state);
    }

    return _buildLoadingContent('Loading...');
  }

  Widget _buildLoadingContent(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const Gap(20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message, bool isCritical) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.red,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            isCritical ? 'System Error' : 'Payment Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
          ),
          const Gap(12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              if (!isCritical) ...[
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<PaymentBloc>()
                          .add(const ResetPaymentState());
                      context.read<PaymentBloc>().add(InitializePayments(
                            customerId: widget.customer.id,
                          ));
                    },
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(PaymentSuccess state) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: Colors.green,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'Payment Successful!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          const Gap(12),
          Text(
            state.successMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            'Amount: ${widget.amount.currencySymbol} ${widget.amount.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSuccess?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureContent(PaymentFailure state) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Colors.red,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'Payment Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
          ),
          const Gap(12),
          Text(
            state.errorMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onFailure?.call();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              if (state.isRetryable) ...[
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<PaymentBloc>()
                          .add(const ClearPaymentError());
                    },
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRequiredContent(PaymentRequiresAction state) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'Additional Verification Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(12),
          Text(
            'Your bank requires additional verification to complete this payment.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle 3D Secure or other verification
                _handle3DSecure(state.actionUrl);
              },
              child: const Text('Complete Verification'),
            ),
          ),
          const Gap(12),
          TextButton(
            onPressed: () {
              context.read<PaymentBloc>().add(const ClearPaymentError());
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context, PaymentLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Gap(24),
            _buildAmountDisplay(context),
            const Gap(24),
            if (state.savedPaymentMethods.isNotEmpty) ...[
              _buildSavedMethodsSection(context, state),
              const Gap(20),
            ],
            _buildNewCardSection(context, state),
            const Gap(24),
            _buildPaymentButton(context, state),
            if (state.error != null) ...[
              const Gap(16),
              _buildErrorBanner(context, state.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            CupertinoIcons.creditcard,
            color: Theme.of(context).primaryColor,
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            '${widget.amount.currencySymbol} ${widget.amount.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMethodsSection(BuildContext context, PaymentLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Payment Methods',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(12),
        ...state.savedPaymentMethods
            .map((method) => _buildSavedMethodCard(context, method)),
      ],
    );
  }

  Widget _buildSavedMethodCard(BuildContext context, PaymentMethodData method) {
    final isSelected = _selectedSavedMethod?.id == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedSavedMethod = isSelected ? null : method;
            });
            context.read<PaymentBloc>().add(
                  SelectSavedPaymentMethod(isSelected ? null : method),
                );
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.creditcard_fill,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).iconTheme.color,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '**** **** **** ${method.last4 ?? '****'}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${method.brand?.toUpperCase() ?? 'CARD'} • Expires ${method.expMonth}/${method.expYear}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewCardSection(BuildContext context, PaymentLoaded state) {
    final showCardForm = _selectedSavedMethod == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.savedPaymentMethods.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Or use a new card',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!showCardForm)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedSavedMethod = null;
                      });
                      context.read<PaymentBloc>().add(
                            const SelectSavedPaymentMethod(null),
                          );
                    },
                    icon: const Icon(CupertinoIcons.add, size: 16),
                    label: const Text('Add New'),
                  ),
              ],
            )
          else
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          if (showCardForm) ...[
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
                fillColor: Theme.of(context).colorScheme.surface,
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
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: stripe.CardFormField(
                controller: _cardController,
                style: stripe.CardFormStyle(
                  borderColor: Colors.transparent,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  borderRadius: 12,
                  fontSize: 16,
                  placeholderColor: Theme.of(context).hintColor,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
                onCardChanged: (details) {
                  setState(() {
                    _isCardValid = details?.complete ?? false;
                  });
                },
              ),
            ),

            const Gap(16),

            // Save card option
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

  Widget _buildPaymentButton(BuildContext context, PaymentLoaded state) {
    final canPay = _selectedSavedMethod != null ||
        (_isCardValid && _nameController.text.isNotEmpty);

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canPay && !state.isProcessing ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canPay ? 4 : 0,
        ),
        child: state.isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<PaymentBloc>().add(const ClearPaymentError());
            },
            icon: Icon(
              CupertinoIcons.xmark,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (_selectedSavedMethod != null) {
      // Process with saved method
      context.read<PaymentBloc>().add(ProcessPaymentWithSavedMethod(
            amount: widget.amount,
            customer: widget.customer,
            savedMethod: _selectedSavedMethod!,
            description: widget.description,
            metadata: widget.metadata,
          ));
    } else {
      // Process with new card
      if (!_formKey.currentState!.validate()) return;

      context.read<PaymentBloc>().add(CreatePayment(
            amount: widget.amount,
            customer: widget.customer,
            method: PaymentMethod.creditCard,
            description: widget.description,
            metadata: widget.metadata,
            savePaymentMethod: _saveCard,
          ));
    }
  }

  void _handleStateChanges(BuildContext context, PaymentState state) {
    if (state is PaymentSuccess) {
      HapticFeedback.lightImpact();
    } else if (state is PaymentFailure) {
      HapticFeedback.heavyImpact();
    }
  }

  void _handle3DSecure(String actionUrl) {
    // Implementation for 3D Secure handling
    // This would typically open a web view or redirect
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}
