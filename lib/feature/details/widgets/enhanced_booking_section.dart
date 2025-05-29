import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/ui/theme/app_theme.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

// Payment system imports
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/ui/widgets/modern_payment_widget.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';

/// Enhanced booking section with integrated payment system
class EnhancedBookingSection extends StatefulWidget {
  final ServiceProviderModel provider;
  final BookableService? selectedService;
  final SubscriptionPlan? selectedPlan;
  final VoidCallback? onBookingSuccess;
  final VoidCallback? onBookingFailure;

  const EnhancedBookingSection({
    super.key,
    required this.provider,
    this.selectedService,
    this.selectedPlan,
    this.onBookingSuccess,
    this.onBookingFailure,
  });

  @override
  State<EnhancedBookingSection> createState() => _EnhancedBookingSectionState();
}

class _EnhancedBookingSectionState extends State<EnhancedBookingSection>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showPaymentSection = false;
  final bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: AppTheme.fastAnimation,
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

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: AppTheme.elevatedCardDecoration,
          margin: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children: [
              _buildBookingHeader(),
              if (!_showPaymentSection) ...[
                _buildServiceSelection(),
                _buildPricingInfo(),
                _buildBookingButton(),
              ] else ...[
                _buildPaymentSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: const Icon(
              CupertinoIcons.calendar_badge_plus,
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
                  _showPaymentSection ? 'Complete Payment' : 'Book Service',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white),
                ),
                const Gap(4),
                Text(
                  _showPaymentSection
                      ? 'Secure payment processing'
                      : 'Choose your service and proceed',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_showPaymentSection)
            IconButton(
              onPressed: () {
                setState(() {
                  _showPaymentSection = false;
                });
                _slideController.reverse();
              },
              icon: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Services',
            style: AppTheme.headingSmall,
          ),
          const Gap(AppTheme.spacingM),

          // Services list
          if (widget.provider.bookableServices.isNotEmpty)
            ...widget.provider.bookableServices
                .map((service) => _buildServiceTile(service))
                .toList()
          else
            _buildNoServicesMessage(),

          // Subscription plans
          if (widget.provider.subscriptionPlans.isNotEmpty) ...[
            const Gap(AppTheme.spacingL),
            Text(
              'Subscription Plans',
              style: AppTheme.headingSmall,
            ),
            const Gap(AppTheme.spacingM),
            ...widget.provider.subscriptionPlans
                .map((plan) => _buildPlanTile(plan))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceTile(BookableService service) {
    final isSelected = widget.selectedService?.id == service.id;

    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            _getServiceIcon(service.type),
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          service.name,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.description.isNotEmpty) ...[
              const Gap(4),
              Text(
                service.description,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Gap(8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle,
                  size: 16,
                  color: AppColors.greenColor,
                ),
                const Gap(4),
                Text(
                  '${(service.price ?? 0).toStringAsFixed(0)} EGP',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.greenColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.clock,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const Gap(4),
                Text(
                  '${service.durationMinutes ?? 60} min',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.primaryColor,
              )
            : const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.secondaryText,
                size: 16,
              ),
        onTap: () {
          // Handle service selection
          _handleServiceSelection(service);
        },
      ),
    );
  }

  Widget _buildPlanTile(SubscriptionPlan plan) {
    final isSelected = widget.selectedPlan?.id == plan.id;

    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accentColor.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isSelected ? AppColors.accentColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: const Icon(
            CupertinoIcons.star_circle,
            color: AppColors.accentColor,
            size: 24,
          ),
        ),
        title: Text(
          plan.name,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.description.isNotEmpty) ...[
              const Gap(4),
              Text(
                plan.description,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Gap(8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle,
                  size: 16,
                  color: AppColors.greenColor,
                ),
                const Gap(4),
                Text(
                  '${plan.price.toStringAsFixed(0)} EGP/month',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.greenColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.accentColor,
              )
            : const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.secondaryText,
                size: 16,
              ),
        onTap: () {
          // Handle plan selection
          _handlePlanSelection(plan);
        },
      ),
    );
  }

  Widget _buildNoServicesMessage() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.calendar_badge_minus,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const Gap(AppTheme.spacingM),
          Text(
            'No services available for booking',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppTheme.spacingS),
          Text(
            'Please contact the provider directly for more information',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo() {
    if (widget.selectedService == null && widget.selectedPlan == null) {
      return const SizedBox.shrink();
    }

    final price =
        widget.selectedService?.price ?? widget.selectedPlan?.price ?? 0.0;
    final isService = widget.selectedService != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isService ? 'Service Fee' : 'Subscription Fee',
                style: AppTheme.bodyLarge,
              ),
              Text(
                '${price.toStringAsFixed(0)} EGP',
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
                style: AppTheme.bodyMedium,
              ),
              Text(
                '${(price * 0.05).toStringAsFixed(0)} EGP',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTheme.headingSmall,
              ),
              Text(
                '${(price * 1.05).toStringAsFixed(0)} EGP',
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

  Widget _buildBookingButton() {
    final hasSelection =
        widget.selectedService != null || widget.selectedPlan != null;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed:
              hasSelection && !_isProcessing ? _navigateToConfiguration : null,
          style: AppTheme.primaryButtonStyle.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return Colors.grey.shade300;
              }
              return AppColors.primaryColor;
            }),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.settings,
                      size: 20,
                    ),
                    const Gap(AppTheme.spacingS),
                    Text(
                      hasSelection ? 'Configure & Book' : 'Select a Service',
                      style: AppTheme.buttonText,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (widget.selectedService == null && widget.selectedPlan == null) {
      return const SizedBox.shrink();
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! LoginSuccessState) {
      return _buildLoginRequired();
    }

    final user = authState.user;
    final price =
        widget.selectedService?.price ?? widget.selectedPlan?.price ?? 0.0;
    final totalAmount = price * 1.05; // Including platform fee
    final isService = widget.selectedService != null;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: BlocProvider(
          create: (context) => PaymentBloc(
            stripeService: null,
          )..add(const InitializePayments()),
          child: ModernPaymentWidget(
            amount: PaymentAmount(
              amount: totalAmount,
              currency: Currency.egp,
              taxAmount: price * 0.05,
            ),
            customer: PaymentCustomer(
              id: user.uid,
              name: user.name,
              email: user.email,
              phone: user.phone,
            ),
            description: isService
                ? 'Service booking: ${widget.selectedService!.name}'
                : 'Subscription: ${widget.selectedPlan!.name}',
            onPaymentSuccess: _handlePaymentSuccess,
            onPaymentFailure: _handlePaymentFailure,
            onPaymentCancelled: _handlePaymentCancellation,
            showSavedMethods: true,
            allowSaving: true,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
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
            'Please log in to proceed with the payment',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(AppTheme.spacingL),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              Navigator.of(context).pushNamed('/login');
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _handleServiceSelection(BookableService service) {
    // This would typically update the parent widget's state
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${service.name}'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _handlePlanSelection(SubscriptionPlan plan) {
    // This would typically update the parent widget's state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${plan.name}'),
        backgroundColor: AppColors.accentColor,
      ),
    );
  }

  void _navigateToConfiguration() {
    // Import the options configuration screen
    Navigator.pushNamed(
      context,
      '/options_configuration',
      arguments: {
        'providerId': widget.provider?.id,
        'service': widget.selectedService,
        'plan': widget.selectedPlan,
      },
    );
  }

  Widget _buildConfigurationScreen() {
    // This method is no longer needed as we navigate to the options configuration screen
    // Keeping for backwards compatibility
    return Container(
      child: const Center(
        child: Text('Configuration screen placeholder'),
      ),
    );
  }

  Widget _buildConfigurationForm() {
    // This method is no longer needed as we navigate to the options configuration screen
    // Keeping for backwards compatibility
    return Container(
      child: const Center(
        child: Text('Configuration form placeholder'),
      ),
    );
  }

  void _handlePaymentSuccess() {
    // Handle successful payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Booking confirmed.'),
        backgroundColor: Colors.green,
      ),
    );
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
    Navigator.pop(context);
  }

  void _handlePaymentCancellation() {
    // Handle payment cancellation
    Navigator.pop(context);
  }

  double _calculateTotalPrice() {
    final price =
        widget.selectedService?.price ?? widget.selectedPlan?.price ?? 0.0;
    return price * 1.05; // Including platform fee
  }

  IconData _getServiceIcon(ReservationType type) {
    switch (type) {
      case ReservationType.timeBased:
        return CupertinoIcons.calendar;
      case ReservationType.group:
        return CupertinoIcons.group;
      case ReservationType.serviceBased:
        return CupertinoIcons.star;
      case ReservationType.seatBased:
        return CupertinoIcons.chat_bubble;
      case ReservationType.accessBased:
        return CupertinoIcons.lock;
      case ReservationType.recurring:
        return CupertinoIcons.repeat;
      case ReservationType.sequenceBased:
        return CupertinoIcons.list_number;
      default:
        return CupertinoIcons.calendar_badge_plus;
    }
  }
}
