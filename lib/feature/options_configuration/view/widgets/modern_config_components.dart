import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

/// Modern Service Card Component
class ModernServiceCard extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;

  const ModernServiceCard({
    super.key,
    required this.state,
    required this.isPlan,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isPlan ? CupertinoIcons.star_fill : CupertinoIcons.calendar,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.itemName,
                      style: AppTextStyle.getHeadlineTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPlan ? "Subscription Plan" : "Service Booking",
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.originalService?.description != null ||
              state.originalPlan?.description != null) ...[
            const Gap(16),
            Text(
              state.originalService?.description ??
                  state.originalPlan?.description ??
                  '',
              style: AppTextStyle.getTitleStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern Service Details Component
class ModernServiceDetails extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;

  const ModernServiceDetails({
    super.key,
    required this.state,
    required this.isPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          _buildDetailItem(
            icon: CupertinoIcons.clock,
            title: 'Duration',
            value: '60 minutes',
          ),
          const Gap(12),
          _buildDetailItem(
            icon: CupertinoIcons.money_dollar,
            title: 'Price',
            value:
                '${_getCurrencySymbol()}${state.basePrice.toStringAsFixed(2)}',
          ),
          if (isPlan) ...[
            const Gap(12),
            _buildDetailItem(
              icon: CupertinoIcons.repeat,
              title: 'Billing Cycle',
              value: state.originalPlan?.billingCycle ?? 'Monthly',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
                title,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: AppTextStyle.getTitleStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

/// Modern Pricing Breakdown Component
class ModernPricingBreakdown extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;

  const ModernPricingBreakdown({
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.money_dollar_circle,
                color: Colors.white,
                size: 24,
              ),
              const Gap(12),
              Text(
                'Total Amount',
                style: AppTextStyle.getTitleStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_getCurrencySymbol()}${state.totalPrice.toStringAsFixed(2)}',
                style: AppTextStyle.getHeadlineTextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isPlan) ...[
                const Gap(8),
                Text(
                  '/${state.originalPlan?.billingCycle.split(' ').first.toLowerCase() ?? 'month'}',
                  style: AppTextStyle.getTitleStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ],
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

/// Modern Date Time Selector Component
class ModernDateTimeSelector extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(DateTime)? onDateChanged;
  final Function(TimeOfDay)? onTimeChanged;

  const ModernDateTimeSelector({
    super.key,
    required this.state,
    this.onDateChanged,
    this.onTimeChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const Gap(20),
          _buildDateSelector(context),
          const Gap(16),
          _buildTimeSelector(context),
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
            CupertinoIcons.calendar,
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
                'Date & Time Selection',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Choose your preferred date and time',
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

  Widget _buildDateSelector(BuildContext context) {
    final isSelected = state.selectedDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryColor.withOpacity(0.05)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryColor
              : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar_today,
              color:
                  isSelected ? AppColors.primaryColor : AppColors.secondaryText,
              size: 20,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Date',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    isSelected ? 'Date Selected' : 'Tap to select date',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    final isSelected = state.selectedTime != null;
    final isEnabled = state.selectedDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: InkWell(
        onTap: isEnabled ? () => _selectTime(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.clock,
              color: isSelected
                  ? AppColors.primaryColor
                  : isEnabled
                      ? AppColors.secondaryText
                      : Colors.grey,
              size: 20,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Time',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    isSelected
                        ? 'Time Selected'
                        : isEnabled
                            ? 'Tap to select time'
                            : 'Select a date first',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryText
                          : isEnabled
                              ? AppColors.secondaryText
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: isEnabled ? AppColors.secondaryText : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(BuildContext context) {
    // Placeholder for date selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date picker will be implemented')),
    );
  }

  void _selectTime(BuildContext context) {
    // Placeholder for time selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time picker will be implemented')),
    );
  }
}

/// Modern Availability Calendar Component
class ModernAvailabilityCalendar extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(Map<String, dynamic>)? onSlotSelected;

  const ModernAvailabilityCalendar({
    super.key,
    required this.state,
    this.onSlotSelected,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.calendar_badge_plus,
                    size: 48,
                    color: AppColors.secondaryText,
                  ),
                  Gap(12),
                  Text('Calendar will be implemented'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Attendee Manager Component
class ModernAttendeeManager extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(List<dynamic>)? onAttendeesChanged;

  const ModernAttendeeManager({
    super.key,
    required this.state,
    this.onAttendeesChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const Gap(20),
          _buildAttendeeCount(),
          const Gap(16),
          _buildSelectedAttendees(),
          const Gap(20),
          _buildAddAttendeeButton(context),
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
            color: AppColors.greenColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.person_2,
            color: AppColors.greenColor,
            size: 24,
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Attendees',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Add family members or friends',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${state.selectedAttendees.length}',
            style: AppTextStyle.getTitleStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeCount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.person_badge_plus,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Attendees',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${state.selectedAttendees.length + 1} people (including you)',
                  style: AppTextStyle.getTitleStyle(
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

  Widget _buildSelectedAttendees() {
    if (state.selectedAttendees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.person_add,
              color: Colors.grey.shade400,
              size: 32,
            ),
            const Gap(8),
            Text(
              'No attendees added yet',
              style: AppTextStyle.getTitleStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Tap the button below to add attendees',
              style: AppTextStyle.getSmallStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const Text('Selected attendees will be shown here');
  }

  Widget _buildAddAttendeeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Attendee selection will be implemented')),
          );
        },
        icon: const Icon(CupertinoIcons.person_add),
        label: const Text('Add Attendees'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
          foregroundColor: AppColors.primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}

/// Modern Family Member Selector Component
class ModernFamilyMemberSelector extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(List<dynamic>)? onSelectionChanged;

  const ModernFamilyMemberSelector({
    super.key,
    required this.state,
    this.onSelectionChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Members',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Family member selection will be implemented'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Preferences Panel Component
class ModernPreferencesPanel extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(Map<String, dynamic>)? onPreferencesChanged;

  const ModernPreferencesPanel({
    super.key,
    required this.state,
    this.onPreferencesChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const Gap(20),
          _buildPreferenceItem(
            icon: CupertinoIcons.bell,
            title: 'Notifications',
            subtitle: 'Get updates about your booking',
            value: true,
          ),
          const Gap(16),
          _buildPreferenceItem(
            icon: CupertinoIcons.alarm,
            title: 'Reminders',
            subtitle: 'Set reminders before appointment',
            value: true,
          ),
          const Gap(16),
          _buildPreferenceItem(
            icon: CupertinoIcons.share,
            title: 'Calendar Integration',
            subtitle: 'Add to your calendar automatically',
            value: false,
          ),
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
            CupertinoIcons.settings,
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
                'Preferences',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Customize your experience',
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

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                  title,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: (newValue) {
              // Handle preference change
            },
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Modern Notes Section Component
class ModernNotesSection extends StatelessWidget {
  final OptionsConfigurationState state;
  final Function(String)? onNotesChanged;

  const ModernNotesSection({
    super.key,
    required this.state,
    this.onNotesChanged,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
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
                      'Additional Notes',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Add any special requests or notes',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter any special requests, allergies, or notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.lightBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: onNotesChanged,
          ),
        ],
      ),
    );
  }
}

/// Modern Action Button Component
class ModernActionButton extends StatelessWidget {
  final bool isEnabled;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onPressed;
  final VoidCallback onPaymentPressed;

  const ModernActionButton({
    super.key,
    required this.isEnabled,
    required this.currentStep,
    required this.totalSteps,
    required this.onPressed,
    required this.onPaymentPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed:
            isEnabled ? (isLastStep ? onPaymentPressed : onPressed) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? AppColors.primaryColor : Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLastStep
                  ? CupertinoIcons.creditcard
                  : CupertinoIcons.arrow_right,
              size: 20,
            ),
            const Gap(12),
            Text(
              isLastStep ? 'Proceed to Payment' : 'Continue',
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
