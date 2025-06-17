import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../utils/colors.dart';
import '../../utils/text_style.dart' as app_text_style;
import '../ui/stripe_payment_widget.dart' as stripe_ui;
import '../models/payment_models.dart';

/// Modern payment widget wrapper that provides consistent styling
/// across the app with glassmorphism effects and smooth animations
class ModernPaymentWidget extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final Function(PaymentResponse) onPaymentComplete;
  final Function(String)? onError;
  final bool showSavedMethods;
  final String? customerId;
  final VoidCallback? onCancel;
  final String? title;
  final Widget? headerIcon;

  const ModernPaymentWidget({
    super.key,
    required this.paymentRequest,
    required this.onPaymentComplete,
    this.onError,
    this.showSavedMethods = true,
    this.customerId,
    this.onCancel,
    this.title,
    this.headerIcon,
  });

  @override
  State<ModernPaymentWidget> createState() => _ModernPaymentWidgetState();
}

class _ModernPaymentWidgetState extends State<ModernPaymentWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.mainBackgroundGradient,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom header
          if (widget.title != null) _buildCustomHeader(),

          // Payment widget - Full width, no constraints
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: stripe_ui.StripePaymentWidget(
              paymentRequest: widget.paymentRequest,
              onPaymentComplete: widget.onPaymentComplete,
              onError: widget.onError,
              showSavedMethods: widget.showSavedMethods,
              customerId: widget.customerId,
              onCancel: widget.onCancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (widget.headerIcon != null) ...[
            widget.headerIcon!,
            const Gap(16),
          ],
          Expanded(
            child: Text(
              widget.title!,
              style: app_text_style.getHeadlineTextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.lightText,
              ),
            ),
          ),
          if (widget.onCancel != null)
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: 40,
                height: 40,
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
                  size: 20,
                  color: AppColors.lightText.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Payment summary card widget for displaying payment details
class PaymentSummaryCard extends StatelessWidget {
  final PaymentRequest paymentRequest;
  final List<PaymentSummaryItem>? additionalItems;
  final Widget? footer;

  const PaymentSummaryCard({
    super.key,
    required this.paymentRequest,
    this.additionalItems,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Payment Summary',
            style: app_text_style.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.lightText,
            ),
          ),
          const Gap(16),

          // Main item
          _buildSummaryItem(
            label: paymentRequest.description,
            amount: paymentRequest.amount.amount,
            currency: paymentRequest.amount.currency,
            isMain: true,
          ),

          // Additional items
          if (additionalItems != null) ...[
            const Gap(12),
            ...additionalItems!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSummaryItem(
                    label: item.label,
                    amount: item.amount,
                    currency: paymentRequest.amount.currency,
                    isSubItem: true,
                  ),
                )),
          ],

          // Tax and fees
          if (paymentRequest.amount.taxAmount != null) ...[
            const Gap(8),
            _buildSummaryItem(
              label: 'Tax',
              amount: paymentRequest.amount.taxAmount!,
              currency: paymentRequest.amount.currency,
              isSubItem: true,
            ),
          ],

          if (paymentRequest.amount.discountAmount != null) ...[
            const Gap(8),
            _buildSummaryItem(
              label: 'Discount',
              amount: -paymentRequest.amount.discountAmount!,
              currency: paymentRequest.amount.currency,
              isSubItem: true,
              isDiscount: true,
            ),
          ],

          // Divider
          const Gap(16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const Gap(16),

          // Total
          _buildSummaryItem(
            label: 'Total',
            amount: paymentRequest.amount.totalAmount,
            currency: paymentRequest.amount.currency,
            isTotal: true,
          ),

          // Footer
          if (footer != null) ...[
            const Gap(16),
            footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required Currency currency,
    bool isMain = false,
    bool isSubItem = false,
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: app_text_style.getbodyStyle(
              fontSize: isTotal ? 16 : (isMain ? 15 : 14),
              fontWeight: isTotal
                  ? FontWeight.w700
                  : (isMain ? FontWeight.w600 : FontWeight.normal),
              color: isSubItem
                  ? AppColors.lightText.withValues(alpha: 0.7)
                  : AppColors.lightText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: Text(
            '${isDiscount ? '-' : ''}${currency.symbol}${amount.abs().toStringAsFixed(2)}',
            style: app_text_style.getbodyStyle(
              fontSize: isTotal ? 18 : (isMain ? 16 : 14),
              fontWeight: isTotal
                  ? FontWeight.w800
                  : (isMain ? FontWeight.w600 : FontWeight.w500),
              color: isDiscount
                  ? AppColors.successColor
                  : (isTotal ? AppColors.primaryColor : AppColors.lightText),
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Payment summary item model
class PaymentSummaryItem {
  final String label;
  final double amount;

  const PaymentSummaryItem({
    required this.label,
    required this.amount,
  });
}

/// Payment success widget with celebration animation
class PaymentSuccessWidget extends StatefulWidget {
  final PaymentResponse paymentResponse;
  final VoidCallback? onContinue;
  final String? successMessage;
  final Widget? customIcon;

  const PaymentSuccessWidget({
    super.key,
    required this.paymentResponse,
    this.onContinue,
    this.successMessage,
    this.customIcon,
  });

  @override
  State<PaymentSuccessWidget> createState() => _PaymentSuccessWidgetState();
}

class _PaymentSuccessWidgetState extends State<PaymentSuccessWidget>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebration();
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startCelebration() {
    HapticFeedback.heavyImpact();
    _scaleController.forward();
    _celebrationController.forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.mainBackgroundGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon with animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: widget.customIcon ??
                      Container(
                        width: 120,
                        height: 120,
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
                              color:
                                  AppColors.successColor.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                ),
              ),
              const Gap(40),

              // Success message
              Text(
                widget.successMessage ?? 'Payment Successful!',
                style: app_text_style.getHeadlineTextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightText,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),

              // Payment details
              Text(
                'Your payment of ${widget.paymentResponse.currency.symbol}${widget.paymentResponse.amount.toStringAsFixed(2)} has been processed successfully.',
                style: app_text_style.getbodyStyle(
                  fontSize: 16,
                  color: AppColors.lightText.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(32),

              // Payment ID
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transaction ID',
                      style: app_text_style.getSmallStyle(
                        fontSize: 12,
                        color: AppColors.lightText.withValues(alpha: 0.6),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      widget.paymentResponse.id,
                      style: app_text_style.getbodyStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(40),

              // Continue button
              if (widget.onContinue != null)
                GestureDetector(
                  onTap: widget.onContinue,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: app_text_style.getButtonStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
}

/// Quick payment button for common actions
class QuickPaymentButton extends StatelessWidget {
  final String label;
  final PaymentAmount amount;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;

  const QuickPaymentButton({
    super.key,
    required this.label,
    required this.amount,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
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
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Gap(12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: app_text_style.getbodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightText,
                    ),
                  ),
                  Text(
                    '${amount.currency.symbol}${amount.totalAmount.toStringAsFixed(2)}',
                    style: app_text_style.getSmallStyle(
                      fontSize: 12,
                      color: AppColors.lightText.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              )
            else
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.lightText.withValues(alpha: 0.6),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
