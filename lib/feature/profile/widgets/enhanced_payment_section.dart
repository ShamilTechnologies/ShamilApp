import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:shamil_mobile_app/core/ui/theme/app_theme.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

// Payment system imports
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';

/// Enhanced payment section for profile screen with payment method management
class EnhancedPaymentSection extends StatefulWidget {
  const EnhancedPaymentSection({super.key});

  @override
  State<EnhancedPaymentSection> createState() => _EnhancedPaymentSectionState();
}

class _EnhancedPaymentSectionState extends State<EnhancedPaymentSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isExpanded = false;
  List<SavedPaymentMethod> _savedMethods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedMethods();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is LoginSuccessState) {
        final methods = await SavedPaymentService().getSavedPaymentMethods();
        setState(() {
          _savedMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment methods: $e'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        decoration: AppTheme.modernCardDecoration,
        child: Column(
          children: [
            _buildHeader(),
            if (_isExpanded) ...[
              SlideTransition(
                position: _slideAnimation,
                child: _buildExpandedContent(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  CupertinoIcons.creditcard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Gap(AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Methods',
                      style: AppTheme.headingSmall,
                    ),
                    const Gap(4),
                    Text(
                      _savedMethods.isEmpty
                          ? 'No saved payment methods'
                          : '${_savedMethods.length} saved method${_savedMethods.length == 1 ? '' : 's'}',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: AppTheme.normalAnimation,
                child: const Icon(
                  CupertinoIcons.chevron_down,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        0,
        AppTheme.spacingL,
        AppTheme.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const Gap(AppTheme.spacingL),
          if (_isLoading)
            _buildLoadingState()
          else if (_savedMethods.isEmpty)
            _buildEmptyState()
          else
            _buildMethodsList(),
          const Gap(AppTheme.spacingL),
          _buildAddMethodButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            Gap(AppTheme.spacingM),
            Text(
              'Loading payment methods...',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              size: 48,
              color: AppColors.primaryColor,
            ),
          ),
          const Gap(AppTheme.spacingL),
          Text(
            'No Payment Methods',
            style: AppTheme.headingSmall,
          ),
          const Gap(AppTheme.spacingS),
          Text(
            'Add a payment method to make bookings faster and more convenient',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsList() {
    return Column(
      children:
          _savedMethods.map((method) => _buildMethodCard(method)).toList(),
    );
  }

  Widget _buildMethodCard(SavedPaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color:
              method.isDefault ? AppColors.primaryColor : Colors.grey.shade300,
          width: method.isDefault ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: _getCardColor(method.method),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Center(
            child: Icon(
              _getCardIcon(method.method),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              _getCardDisplayName(method.method),
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (method.isDefault) ...[
              const Gap(AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  'Default',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(4),
            Text(
              '**** **** **** ${method.last4Digits ?? '****'}',
              style: AppTheme.bodyMedium,
            ),
            if (method.expiryMonth != null && method.expiryYear != null) ...[
              const Gap(2),
              Text(
                'Expires ${method.expiryMonth}/${method.expiryYear}',
                style: AppTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            CupertinoIcons.ellipsis_vertical,
            color: AppColors.secondaryText,
            size: 20,
          ),
          onSelected: (value) => _handleMethodAction(value, method),
          itemBuilder: (context) => [
            if (!method.isDefault)
              const PopupMenuItem(
                value: 'set_default',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.star, size: 16),
                    Gap(8),
                    Text('Set as Default'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(CupertinoIcons.delete,
                      size: 16, color: AppColors.redColor),
                  Gap(8),
                  Text('Delete', style: TextStyle(color: AppColors.redColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddMethodDialog,
        style: AppTheme.secondaryButtonStyle,
        icon: const Icon(CupertinoIcons.add, size: 20),
        label: const Text('Add Payment Method'),
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _showAddMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddMethodBottomSheet(),
    );
  }

  Widget _buildAddMethodBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Payment Method',
                    style: AppTheme.headingSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.xmark),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              child: Column(
                children: [
                  _buildPaymentMethodOption(
                    icon: CupertinoIcons.creditcard,
                    title: 'Credit/Debit Card',
                    subtitle: 'Visa, Mastercard, American Express',
                    onTap: () => _addPaymentMethod(PaymentMethod.creditCard),
                  ),
                  const Gap(AppTheme.spacingM),
                  _buildPaymentMethodOption(
                    icon: CupertinoIcons.device_phone_portrait,
                    title: 'Mobile Wallet',
                    subtitle: 'Vodafone Cash, Orange Money, Etisalat Cash',
                    onTap: () => _addPaymentMethod(PaymentMethod.wallet),
                  ),
                  const Gap(AppTheme.spacingM),
                  _buildPaymentMethodOption(
                    icon: CupertinoIcons.building_2_fill,
                    title: 'Bank Transfer',
                    subtitle: 'Direct bank account transfer',
                    onTap: () => _addPaymentMethod(PaymentMethod.bankTransfer),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const Gap(AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.secondaryText,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPaymentMethod(PaymentMethod type) {
    Navigator.pop(context);

    // Show success message for demo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getCardDisplayName(type)} setup initiated'),
        backgroundColor: AppColors.primaryColor,
      ),
    );

    // In a real implementation, this would navigate to the payment setup flow
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => PaymentMethodSetupScreen(type: type),
    // ));
  }

  void _handleMethodAction(String action, SavedPaymentMethod method) async {
    switch (action) {
      case 'set_default':
        await _setDefaultMethod(method);
        break;
      case 'delete':
        await _deleteMethod(method);
        break;
    }
  }

  Future<void> _setDefaultMethod(SavedPaymentMethod method) async {
    try {
      await SavedPaymentService().setAsDefault(method.id);
      await _loadSavedMethods();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated'),
            backgroundColor: AppColors.greenColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update default method: $e'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteMethod(SavedPaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
            'Are you sure you want to delete this ${_getCardDisplayName(method.method).toLowerCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.redColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SavedPaymentService().deletePaymentMethod(method.id);
        await _loadSavedMethods();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method deleted'),
              backgroundColor: AppColors.greenColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete payment method: $e'),
              backgroundColor: AppColors.redColor,
            ),
          );
        }
      }
    }
  }

  Color _getCardColor(PaymentMethod type) {
    switch (type) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return AppColors.primaryColor;
      case PaymentMethod.wallet:
      case PaymentMethod.vodafoneCash:
      case PaymentMethod.orangeMoney:
      case PaymentMethod.etisalatCash:
        return AppColors.orangeColor;
      case PaymentMethod.bankTransfer:
        return AppColors.greenColor;
      case PaymentMethod.applePay:
      case PaymentMethod.googlePay:
        return AppColors.purpleColor;
      default:
        return AppColors.secondaryColor;
    }
  }

  IconData _getCardIcon(PaymentMethod type) {
    switch (type) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return CupertinoIcons.creditcard_fill;
      case PaymentMethod.wallet:
      case PaymentMethod.vodafoneCash:
      case PaymentMethod.orangeMoney:
      case PaymentMethod.etisalatCash:
        return CupertinoIcons.device_phone_portrait;
      case PaymentMethod.bankTransfer:
        return CupertinoIcons.building_2_fill;
      case PaymentMethod.applePay:
        return CupertinoIcons.device_phone_portrait;
      case PaymentMethod.googlePay:
        return CupertinoIcons.device_phone_portrait;
      case PaymentMethod.fawry:
        return CupertinoIcons.money_dollar_circle;
      default:
        return CupertinoIcons.creditcard;
    }
  }

  String _getCardDisplayName(PaymentMethod type) {
    switch (type) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.wallet:
        return 'Mobile Wallet';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.vodafoneCash:
        return 'Vodafone Cash';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.etisalatCash:
        return 'Etisalat Cash';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.fawry:
        return 'Fawry';
      case PaymentMethod.cash:
        return 'Cash';
      default:
        return 'Payment Method';
    }
  }
}
