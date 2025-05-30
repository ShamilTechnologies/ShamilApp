import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'dart:async';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/core/payment/ui/widgets/enhanced_payment_widget.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';

/// Modern Payment Summary Component
class ModernPaymentSummary extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;

  const ModernPaymentSummary({
    super.key,
    required this.state,
    required this.isPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(),
          const Gap(24),
          _buildPriceBreakdown(),
          const Gap(20),
          _buildTotalAmount(),
          if (isPlan) ...[
            const Gap(16),
            _buildSubscriptionDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.creditcard,
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
                'Payment Summary',
                style: AppTextStyle.getHeadlineTextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Review your order before payment',
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isPlan ? 'Subscription' : 'One-time',
            style: AppTextStyle.getSmallStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    final includeUser = state.includeUserInBooking;
    final payForAll = state.payForAllAttendees;
    final selectedAttendees = state.selectedAttendees;
    final basePrice = state.basePrice;

    // Calculate attendee breakdown
    final userCount = includeUser ? 1 : 0;
    final attendeeCount = selectedAttendees.length;
    final totalPeople = userCount + attendeeCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Service base price
          _buildPriceItem(
            label: state.itemName,
            amount: basePrice,
            isMain: true,
          ),

          // User inclusion breakdown
          if (includeUser) ...[
            const Gap(8),
            _buildPriceItem(
              label: 'You (Organizer)',
              amount: basePrice,
              subtitle: payForAll ? 'Paying for all' : 'Individual payment',
            ),
          ],

          // Attendee breakdown
          if (attendeeCount > 0) ...[
            const Gap(8),
            _buildPriceItem(
              label: 'Additional attendees ($attendeeCount)',
              amount: attendeeCount * basePrice,
              subtitle: payForAll ? 'Paid by organizer' : 'Individual payments',
            ),
          ],

          // Add-ons
          if (state.addOnsPrice > 0) ...[
            const Gap(8),
            _buildPriceItem(
              label: 'Add-ons & extras',
              amount: state.addOnsPrice,
            ),
          ],

          const Gap(16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          const Gap(16),

          // Payment responsibility breakdown
          if (payForAll) ...[
            _buildPriceItem(
              label: 'Total (You pay for all)',
              amount: state.totalPrice,
              isSubtotal: true,
            ),
          ] else ...[
            _buildPriceItem(
              label: includeUser ? 'Your portion' : 'Your payment',
              amount: state.totalPrice,
              isSubtotal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required String label,
    required double amount,
    bool isMain = false,
    bool isSubtotal = false,
    String? subtitle,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: isMain ? 16 : 14,
                      fontWeight: isMain || isSubtotal
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: Colors.white.withOpacity(isSubtotal ? 1.0 : 0.9),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(2),
                    Text(
                      subtitle,
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${_getCurrencySymbol()}${amount.toStringAsFixed(2)}',
              style: AppTextStyle.getTitleStyle(
                fontSize: isMain ? 16 : 14,
                fontWeight:
                    isMain || isSubtotal ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    final includeUser = state.includeUserInBooking;
    final payForAll = state.payForAllAttendees;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
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
                payForAll ? 'Total Amount (All Attendees)' : 'Your Payment',
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (state.originalPlan != null)
                Text(
                  'Per ${state.originalPlan?.billingCycle.split(' ').first.toLowerCase() ?? 'month'}',
                  style: AppTextStyle.getSmallStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          Text(
            '${_getCurrencySymbol()}${state.totalPrice.toStringAsFixed(2)}',
            style: AppTextStyle.getHeadlineTextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: Colors.white,
            size: 16,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              'This is a recurring subscription. You can cancel anytime.',
              style: AppTextStyle.getSmallStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol() {
    final currencyCode = state.originalPlan?.currency ??
        state.originalService?.currency ??
        'EGP';
    switch (currencyCode.toUpperCase()) {
      case 'EGP':
        return 'EGP ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$currencyCode ';
    }
  }
}

/// Modern Payment Methods Component
class ModernPaymentMethods extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(String)? onPaymentMethodSelected;

  const ModernPaymentMethods({
    super.key,
    required this.state,
    this.onPaymentMethodSelected,
  });

  @override
  State<ModernPaymentMethods> createState() => _ModernPaymentMethodsState();
}

class _ModernPaymentMethodsState extends State<ModernPaymentMethods> {
  String _selectedMethod = 'stripe';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const Gap(20),
          _buildPaymentMethodsList(),
          const Gap(20),
          _buildSecurityBadge(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.creditcard_fill,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Methods',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Choose your preferred payment method',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsList() {
    return Column(
      children: [
        _buildPaymentMethodItem(
          id: 'stripe',
          icon: CupertinoIcons.creditcard,
          title: 'Credit/Debit Card',
          subtitle: 'Visa, Mastercard, American Express',
          isRecommended: true,
        ),
        const Gap(12),
        _buildPaymentMethodItem(
          id: 'apple_pay',
          icon: CupertinoIcons.device_phone_portrait,
          title: 'Apple Pay',
          subtitle: 'Pay with Touch ID or Face ID',
          isEnabled: false,
        ),
        const Gap(12),
        _buildPaymentMethodItem(
          id: 'google_pay',
          icon: CupertinoIcons.money_dollar_circle,
          title: 'Google Pay',
          subtitle: 'Fast and secure payments',
          isEnabled: false,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isRecommended = false,
    bool isEnabled = true,
  }) {
    final isSelected = _selectedMethod == id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryColor.withOpacity(0.05)
            : isEnabled
                ? AppColors.lightBackground
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryColor
              : isEnabled
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () {
                  setState(() => _selectedMethod = id);
                  widget.onPaymentMethodSelected?.call(id);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : isEnabled
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.primaryColor
                        : isEnabled
                            ? AppColors.secondaryText
                            : Colors.grey,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isEnabled
                                    ? AppColors.primaryText
                                    : Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecommended) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.greenColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Rec.',
                                style: AppTextStyle.getSmallStyle(
                                  color: AppColors.greenColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyle.getSmallStyle(
                          color:
                              isEnabled ? AppColors.secondaryText : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greenColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.shield_lefthalf_fill,
            color: AppColors.greenColor,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greenColor,
                  ),
                ),
                Text(
                  'Your payment information is encrypted and secure',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SSL',
              style: AppTextStyle.getSmallStyle(
                color: AppColors.greenColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Payment Button Component - Enhanced with better data flow
class ModernPaymentButton extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;
  final VoidCallback? onPaymentSuccess;

  const ModernPaymentButton({
    super.key,
    required this.state,
    required this.isPlan,
    this.onPaymentSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFinalSummary(),
          const Gap(24),
          _buildPaymentMethodSelector(),
          const Gap(16),
          _buildPaymentReadyIndicator(),
        ],
      ),
    );
  }

  Widget _buildFinalSummary() {
    final includeUser = state.includeUserInBooking;
    final payForAll = state.payForAllAttendees;
    final selectedAttendees = state.selectedAttendees;
    final basePrice = state.basePrice;
    final userCount = includeUser ? 1 : 0;
    final attendeeCount = selectedAttendees.length;
    final totalAttendees = userCount + attendeeCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.person_2_fill,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'Attendee Summary ($totalAttendees ${totalAttendees == 1 ? 'person' : 'people'})',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),

          // User (organizer) card
          if (includeUser) ...[
            _buildAttendeeRow(
              name: 'You (Host)',
              paymentStatus: payForAll
                  ? 'Paying for all (${_getCurrencySymbol()}${state.totalPrice.toStringAsFixed(2)})'
                  : 'Individual payment (${_getCurrencySymbol()}${basePrice.toStringAsFixed(2)})',
              isOrganizer: true,
              attendeeType: 'user',
            ),
            if (attendeeCount > 0) const Gap(8),
          ],

          // Selected attendees
          ...selectedAttendees.asMap().entries.map((entry) {
            final index = entry.key;
            final attendee = entry.value;
            final paymentStatus = payForAll
                ? 'Paid by host'
                : 'Individual payment (${_getCurrencySymbol()}${basePrice.toStringAsFixed(2)})';

            return Column(
              children: [
                _buildAttendeeRow(
                  name: attendee.name,
                  paymentStatus: paymentStatus,
                  isOrganizer: false,
                  attendeeType: attendee.type,
                ),
                if (index < attendeeCount - 1) const Gap(8),
              ],
            );
          }).toList(),

          const Gap(16),
          Container(height: 1, color: AppColors.primaryColor.withOpacity(0.2)),
          const Gap(16),

          // Booking details summary
          Column(
            children: [
              _buildSummaryRow('Service', state.itemName),
              const Gap(8),
              if (state.selectedDate != null)
                _buildSummaryRow('Date', _formatDate(state.selectedDate!)),
              if (state.selectedTime?.isNotEmpty == true) ...[
                const Gap(8),
                _buildSummaryRow('Time', state.selectedTime!),
              ],
              const Gap(8),
              _buildSummaryRow('Total Amount',
                  '${_getCurrencySymbol()}${state.totalPrice.toStringAsFixed(2)}'),
              if (payForAll && attendeeCount > 0) ...[
                const Gap(8),
                _buildSummaryRow(
                  'Payment Mode',
                  'Paying for all attendees',
                ),
              ],
            ],
          ),

          const Gap(16),
          _buildPaymentMethodSelector(),
        ],
      ),
    );
  }

  Widget _buildAttendeeRow({
    required String name,
    required String paymentStatus,
    bool isOrganizer = false,
    required String attendeeType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Profile picture placeholder
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOrganizer
                    ? [AppColors.primaryColor, AppColors.secondaryColor]
                    : attendeeType == 'friend'
                        ? [
                            AppColors.cyanColor,
                            AppColors.cyanColor.withOpacity(0.7)
                          ]
                        : [
                            AppColors.greenColor,
                            AppColors.greenColor.withOpacity(0.7)
                          ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: AppTextStyle.getTitleStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOrganizer) ...[
                      const Gap(4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOST',
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  paymentStatus,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: AppTextStyle.getTitleStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit/Debit Card',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Secure payment via Stripe',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SSL',
              style: AppTextStyle.getSmallStyle(
                color: AppColors.greenColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReadyIndicator() {
    final isValid = state.canProceedToPayment;
    final validationErrors = _getValidationErrors();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [
                  AppColors.greenColor.withOpacity(0.1),
                  AppColors.greenColor.withOpacity(0.05),
                ]
              : [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? AppColors.greenColor.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isValid
                      ? AppColors.greenColor.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isValid
                      ? CupertinoIcons.checkmark_shield
                      : CupertinoIcons.exclamationmark_triangle,
                  color: isValid ? AppColors.greenColor : Colors.orange,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isValid ? 'Ready to Pay' : 'Complete Required Steps',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isValid ? AppColors.greenColor : Colors.orange,
                      ),
                    ),
                    Text(
                      isValid
                          ? 'All requirements completed. Tap "Pay Now" to proceed.'
                          : 'Please complete the missing requirements below.',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isValid ? AppColors.greenColor : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'EGP ${state.totalPrice.toStringAsFixed(0)}',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Show validation errors if any
          if (!isValid && validationErrors.isNotEmpty) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missing Requirements:',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  const Gap(6),
                  ...validationErrors.map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                error,
                                style: AppTextStyle.getSmallStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getValidationErrors() {
    final errors = <String>[];

    if (!state.isDateTimeStepComplete) {
      if (state.optionsDefinition?['allowDateSelection'] == true &&
          state.selectedDate == null) {
        errors.add('Please select a booking date');
      }
      if (state.optionsDefinition?['allowTimeSelection'] == true &&
          (state.selectedTime == null || state.selectedTime!.isEmpty)) {
        errors.add('Please select a booking time');
      }
    }

    if (!state.isAttendeesStepComplete) {
      errors.add('At least one person must attend (you or invited attendees)');
    }

    if (!state.isPaymentDataValid) {
      if (state.totalPrice <= 0) {
        errors.add('Invalid payment amount');
      } else {
        errors.add('Payment configuration is incomplete');
      }
    }

    return errors;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _getCurrencySymbol() {
    final currencyCode = state.originalPlan?.currency ??
        state.originalService?.currency ??
        'EGP';
    switch (currencyCode.toUpperCase()) {
      case 'EGP':
        return 'EGP ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$currencyCode ';
    }
  }

  // Public method to show payment gateway - can be called from navigation bar
  static void showPaymentGateway(
      BuildContext context, OptionsConfigurationState state, bool isPlan,
      {VoidCallback? onPaymentSuccess}) async {
    // Get real user data from AuthBloc instead of hardcoded values
    String customerId =
        'temp_customer_${DateTime.now().millisecondsSinceEpoch}';
    String customerName = 'User';
    String customerEmail = 'user@example.com';
    String customerPhone = '+201234567890';

    // Try to get user from authentication systems
    try {
      // First, try to get from AuthBloc if available
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is LoginSuccessState) {
          final user = authState.user;
          customerId = user.uid;
          customerName = user.name;
          customerEmail = user.email;
          customerPhone = user.phone ?? '+201234567890';
          debugPrint(
              'Using authenticated user data: ${user.name} (${user.uid})');
        }
      } catch (e) {
        debugPrint('AuthBloc not available, trying Firebase Auth directly: $e');
      }

      // Fallback to Firebase Auth directly if AuthBloc not available
      if (customerId.startsWith('temp_')) {
        final FirebaseAuth _auth = FirebaseAuth.instance;
        final currentUser = _auth.currentUser;

        if (currentUser != null) {
          customerId = currentUser.uid;
          customerName = currentUser.displayName ?? 'User';
          customerEmail = currentUser.email ?? 'user@example.com';
          customerPhone = currentUser.phoneNumber ?? '+201234567890';
          debugPrint(
              'Using Firebase Auth user data: ${currentUser.displayName} (${currentUser.uid})');
        }
      }
    } catch (e) {
      debugPrint('Could not get authenticated user, using temporary ID: $e');
      // Fall back to temporary customer ID for payment processing
    }

    // Get updated payment data
    final totalAttendees =
        (state.includeUserInBooking ? 1 : 0) + state.selectedAttendees.length;
    final paymentAmount = PaymentAmount(
      amount: state.totalPrice,
      currency: Currency.egp,
      taxAmount: state.totalPrice * 0.14, // 14% VAT
      shippingAmount: 0.0,
    );

    // Create customer data with real information
    final customer = PaymentCustomer(
      id: customerId,
      name: customerName,
      email: customerEmail,
      phone: customerPhone,
      billingAddress: const PaymentAddress(
        street: 'User Address Line 1', // TODO: Get from UserService
        city: 'Cairo', // TODO: Get from UserService
        state: 'Cairo',
        country: 'EG',
        postalCode: '11511',
      ),
    );

    // Enhanced metadata for tracking
    final metadata = {
      'provider_id': state.providerId,
      'service_id': state.originalService?.id ?? '',
      'plan_id': state.originalPlan?.id ?? '',
      'total_attendees': totalAttendees.toString(),
      'user_included': state.includeUserInBooking.toString(),
      'pay_for_all': state.payForAllAttendees.toString(),
      'attendee_ids': state.selectedAttendees.map((a) => a.userId).join(','),
      'attendee_names': state.selectedAttendees.map((a) => a.name).join(','),
      'selected_date': state.selectedDate?.toIso8601String() ?? '',
      'selected_time': state.selectedTime ?? '',
      'base_price': state.basePrice.toString(),
      'total_price': state.totalPrice.toString(),
      'booking_type': isPlan ? 'subscription' : 'service_booking',
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // TODO: Get from app config
      'payment_split': state.payForAllAttendees
          ? 'organizer_pays_all'
          : 'individual_payments',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent accidental dismissal during payment
      enableDrag: false, // Prevent dragging to close during payment
      builder: (modalContext) {
        // Capture the bloc reference from the parent context before modal closes
        final bloc = context.read<OptionsConfigurationBloc>();

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: EnhancedPaymentWidget(
            amount: paymentAmount,
            customer: customer,
            description: isPlan
                ? 'Subscription: ${state.itemName} (${totalAttendees} ${totalAttendees == 1 ? 'person' : 'people'})'
                : 'Service Booking: ${state.itemName} (${totalAttendees} ${totalAttendees == 1 ? 'person' : 'people'})',
            onPaymentSuccess: () {
              Navigator.pop(modalContext);
              _handlePaymentSuccess(context, state, onPaymentSuccess, bloc);
            },
            onPaymentFailure: () {
              Navigator.pop(modalContext);
              _handlePaymentFailure(context);
            },
            onPaymentCancelled: () {
              Navigator.pop(modalContext);
              _showPaymentCancelledMessage(context);
            },
            showSavedMethods:
                false, // Don't show saved methods for temp customer
            allowSaving: false, // Don't allow saving for temp customer
            metadata: metadata,
          ),
        );
      },
    );
  }

  static void _handlePaymentSuccess(
      BuildContext context,
      OptionsConfigurationState state,
      VoidCallback? onPaymentSuccess,
      OptionsConfigurationBloc bloc) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.white,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                'Payment successful! Creating your booking...',
                style: AppTextStyle.getTitleStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.greenColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Listen for state changes to show success/error feedback
    late StreamSubscription subscription;
    subscription = bloc.stream.listen((newState) {
      if (newState is OptionsConfigurationConfirmed) {
        // Success - show confirmation message
        subscription.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Booking confirmed! Confirmation ID: ${newState.confirmationId}',
                    style: AppTextStyle.getTitleStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        onPaymentSuccess?.call();

        // Navigate back after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      } else if (newState.errorMessage != null) {
        // Error - show error message
        subscription.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.white,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Booking failed: ${newState.errorMessage}',
                    style: AppTextStyle.getTitleStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.redColor,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    // Trigger configuration confirmation with payment success flag
    // This will create the actual reservation/subscription
    bloc.add(
      const ConfirmConfiguration(paymentSuccessful: true),
    );

    // Cancel subscription after 30 seconds to avoid memory leaks
    Future.delayed(const Duration(seconds: 30), () {
      subscription.cancel();
    });
  }

  static void _handlePaymentFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
            ),
            const Gap(12),
            const Expanded(
              child: Text(
                'Payment failed. Please try again.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.redColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void _showPaymentCancelledMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
            ),
            const Gap(12),
            const Expanded(
              child: Text(
                'Payment cancelled. Please try again later.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.redColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
