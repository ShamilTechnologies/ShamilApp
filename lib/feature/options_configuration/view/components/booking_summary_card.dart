import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:intl/intl.dart';

/// Booking Summary Card Component
class BookingSummaryCard extends StatelessWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final bool isPlan;

  const BookingSummaryCard({
    super.key,
    required this.state,
    required this.provider,
    required this.isPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.15),
            AppColors.tealColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Gap(20),
          _buildSummaryDetails(),
          const Gap(16),
          _buildPricingBreakdown(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.tealColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isPlan
                ? CupertinoIcons.star_fill
                : CupertinoIcons.calendar_badge_plus,
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
                'Booking Summary',
                style: app_text_style.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                'Review your booking details',
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDetails() {
    return Column(
      children: [
        _buildSummaryItem(
          'Service Provider',
          provider.businessName,
          CupertinoIcons.building_2_fill,
        ),
        _buildSummaryItem(
          isPlan ? 'Plan' : 'Service',
          state.itemName,
          isPlan ? CupertinoIcons.star_fill : CupertinoIcons.wrench_fill,
        ),
        if (state.selectedDate != null)
          _buildSummaryItem(
            'Date',
            DateFormat('EEEE, MMMM d, y').format(state.selectedDate!),
            CupertinoIcons.calendar,
          ),
        if (state.selectedTime != null)
          _buildSummaryItem(
            'Time',
            state.selectedTime!,
            CupertinoIcons.clock_fill,
          ),
        _buildSummaryItem(
          'Attendees',
          '${state.selectedAttendees.length + 1} person(s)',
          CupertinoIcons.person_2_fill,
        ),
        if (state.notes != null && state.notes!.isNotEmpty)
          _buildSummaryItem(
            'Special Notes',
            state.notes!,
            CupertinoIcons.doc_text_fill,
          ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
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
                  label,
                  style: app_text_style.getSmallStyle(
                    color: AppColors.lightText.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            'Base Price',
            'EGP ${state.basePrice.toStringAsFixed(0)}',
            false,
          ),
          if (state.addOnsPrice > 0)
            _buildPriceRow(
              'Add-ons',
              'EGP ${state.addOnsPrice.toStringAsFixed(0)}',
              false,
            ),
          if (state.selectedAttendees.isNotEmpty &&
              state.costSplitConfig != null)
            _buildPriceRow(
              'Your Share',
              _calculateUserShare(),
              false,
            ),
          const Divider(
            color: Colors.white24,
            height: 24,
          ),
          _buildPriceRow(
            'Total Amount',
            'EGP ${state.totalPrice.toStringAsFixed(0)}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, bool isTotal) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: isTotal ? 1.0 : 0.8),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateUserShare() {
    if (state.costSplitConfig == null) {
      return 'EGP ${state.totalPrice.toStringAsFixed(0)}';
    }

    final config = state.costSplitConfig!;
    final attendeeCount = state.selectedAttendees.length + 1;

    switch (config.type) {
      case CostSplitType.splitEqually:
        final userShare = state.totalPrice / attendeeCount;
        return 'EGP ${userShare.toStringAsFixed(0)}';
      case CostSplitType.payAllMyself:
        return 'EGP ${state.totalPrice.toStringAsFixed(0)}';
      case CostSplitType.splitCustom:
        // Default to equal split for now
        final userShare = state.totalPrice / attendeeCount;
        return 'EGP ${userShare.toStringAsFixed(0)}';
    }
  }
}
