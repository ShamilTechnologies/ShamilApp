import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/ui/theme/app_theme.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/auth/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';

// Payment system imports
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/ui/widgets/modern_payment_widget.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';

/// Subscription payment screen with integrated payment system
class SubscriptionPaymentScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  final ServiceProviderModel provider;

  const SubscriptionPaymentScreen({
    super.key,
    required this.plan,
    required this.provider,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildSubscriptionSummary(),
              Expanded(
                child: _buildPaymentSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Complete Subscription'),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSubscriptionSummary() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  CupertinoIcons.star_circle_fill,
                  color: AppColors.accentColor,
                  size: 24,
                ),
              ),
              const Gap(AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: AppTheme.headingSmall,
                    ),
                    const Gap(4),
                    Text(
                      widget.provider.businessName,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppTheme.spacingM),
          if (widget.plan.description.isNotEmpty) ...[
            Text(
              widget.plan.description,
              style: AppTheme.bodyMedium,
            ),
            const Gap(AppTheme.spacingM),
          ],
          if (widget.plan.features.isNotEmpty) ...[
            Text(
              'Features:',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(AppTheme.spacingS),
            ...widget.plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.greenColor,
                        size: 16,
                      ),
                      const Gap(AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
            const Gap(AppTheme.spacingM),
          ],
          const Divider(),
          const Gap(AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription Fee',
                style: AppTheme.bodyLarge,
              ),
              Text(
                '${widget.plan.price.toStringAsFixed(0)} EGP',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Fee',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                '${(widget.plan.price * 0.05).toStringAsFixed(0)} EGP',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const Gap(AppTheme.spacingS),
          const Divider(),
          const Gap(AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTheme.headingSmall,
              ),
              Text(
                '${_calculateTotalAmount().toStringAsFixed(0)} EGP',
                style: AppTheme.headingSmall.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! LoginSuccessState) {
      return _buildLoginRequired();
    }

    final user = authState.user;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: BlocProvider(
        create: (context) => PaymentBloc(
          stripeService: null,
        ),
        child: ModernPaymentWidget(
          amount: PaymentAmount(
            amount: _calculateTotalAmount(),
            currency: Currency.egp,
            taxAmount: widget.plan.price * 0.05,
          ),
          customer: PaymentCustomer(
            id: user.uid,
            name: user.name,
            email: user.email,
            phone: user.phone,
          ),
          description:
              'Subscription: ${widget.plan.name} - ${widget.provider.businessName}',
          onPaymentSuccess: _handlePaymentSuccess,
          onPaymentFailure: _handlePaymentFailure,
          onPaymentCancelled: _handlePaymentCancellation,
          showSavedMethods: true,
          allowSaving: true,
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_circle,
            size: 64,
            color: AppColors.secondaryText,
          ),
          const Gap(AppTheme.spacingM),
          Text(
            'Login Required',
            style: AppTheme.headingSmall,
          ),
          const Gap(AppTheme.spacingS),
          Text(
            'Please log in to proceed with the subscription payment',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(AppTheme.spacingL),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalAmount() {
    return widget.plan.price * 1.05; // Including platform fee
  }

  void _handlePaymentSuccess() {
    // Handle successful payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription payment successful! Welcome aboard!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to home or subscription screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handlePaymentFailure() {
    // Handle payment failure
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment failed. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handlePaymentCancellation() {
    // Handle payment cancellation
    Navigator.pop(context);
  }
}
