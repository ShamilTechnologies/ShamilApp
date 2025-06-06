import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';

/// Cost Split Manager Component
class CostSplitManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(CostSplitConfig) onCostSplitChanged;

  const CostSplitManager({
    super.key,
    required this.state,
    required this.onCostSplitChanged,
  });

  @override
  State<CostSplitManager> createState() => _CostSplitManagerState();
}

class _CostSplitManagerState extends State<CostSplitManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  CostSplitType _selectedSplitType = CostSplitType.splitEqually;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _fadeController.forward();

    // Initialize from state if available
    if (widget.state.costSplitConfig != null) {
      _selectedSplitType = widget.state.costSplitConfig!.type;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show if there are attendees
    if (widget.state.selectedAttendees.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Gap(20),
            _buildSplitOptions(),
            const Gap(20),
            _buildCostBreakdown(),
          ],
        ),
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
              colors: [AppColors.greenColor, AppColors.tealColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            CupertinoIcons.money_dollar_circle_fill,
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
                'Cost Splitting',
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                'How would you like to split the cost?',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.lightText.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitOptions() {
    return Column(
      children: [
        _buildSplitOption(
          CostSplitType.splitEqually,
          'Split Equally',
          'Everyone pays the same amount',
          CupertinoIcons.equal,
          AppColors.cyanColor,
        ),
        const Gap(12),
        _buildSplitOption(
          CostSplitType.payAllMyself,
          'I\'ll Pay for Everyone',
          'You cover the entire cost',
          CupertinoIcons.creditcard_fill,
          AppColors.primaryColor,
        ),
        const Gap(12),
        _buildSplitOption(
          CostSplitType.splitCustom,
          'Custom Split',
          'Set custom amounts for each person',
          CupertinoIcons.slider_horizontal_3,
          AppColors.tealColor,
        ),
      ],
    );
  }

  Widget _buildSplitOption(
    CostSplitType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedSplitType == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedSplitType = type);
          _updateCostSplit();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  )
                : null,
            color: !isSelected ? Colors.white.withOpacity(0.05) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        )
                      : null,
                  color: !isSelected ? Colors.white.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withOpacity(0.6),
                  size: 20,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.lightText.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final totalCost = widget.state.totalPrice;
    final attendeeCount =
        widget.state.selectedAttendees.length + 1; // +1 for user

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Breakdown',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          _buildBreakdownRow(
              'Total Cost', 'EGP ${totalCost.toStringAsFixed(0)}'),
          _buildBreakdownRow('Total People', '$attendeeCount'),
          const Divider(
            color: Colors.white24,
            height: 24,
          ),
          _buildPaymentBreakdown(totalCost, attendeeCount),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(double totalCost, int attendeeCount) {
    switch (_selectedSplitType) {
      case CostSplitType.splitEqually:
        final perPersonCost = totalCost / attendeeCount;
        return Column(
          children: [
            _buildPaymentRow(
              'You',
              'EGP ${perPersonCost.toStringAsFixed(0)}',
              AppColors.primaryColor,
            ),
            ...widget.state.selectedAttendees
                .map((attendee) => _buildPaymentRow(
                      attendee.name,
                      'EGP ${perPersonCost.toStringAsFixed(0)}',
                      _getAttendeeColor(attendee.type),
                    )),
          ],
        );

      case CostSplitType.payAllMyself:
        return Column(
          children: [
            _buildPaymentRow(
              'You',
              'EGP ${totalCost.toStringAsFixed(0)}',
              AppColors.primaryColor,
            ),
            ...widget.state.selectedAttendees
                .map((attendee) => _buildPaymentRow(
                      attendee.name,
                      'EGP 0',
                      _getAttendeeColor(attendee.type),
                    )),
          ],
        );

      case CostSplitType.splitCustom:
        // For now, default to equal split for custom
        final perPersonCost = totalCost / attendeeCount;
        return Column(
          children: [
            _buildPaymentRow(
              'You',
              'EGP ${perPersonCost.toStringAsFixed(0)}',
              AppColors.primaryColor,
            ),
            ...widget.state.selectedAttendees
                .map((attendee) => _buildPaymentRow(
                      attendee.name,
                      'EGP ${perPersonCost.toStringAsFixed(0)}',
                      _getAttendeeColor(attendee.type),
                    )),
            const Gap(8),
            Text(
              'Tap amounts to customize',
              style: AppTextStyle.getSmallStyle(
                color: AppColors.tealColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPaymentRow(String name, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: color,
              size: 12,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              name,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.lightText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _updateCostSplit() {
    final config = CostSplitConfig(
      type: _selectedSplitType,
      totalAmount: widget.state.totalPrice,
      isHostPaying: _selectedSplitType == CostSplitType.payAllMyself,
    );
    widget.onCostSplitChanged(config);
  }

  Color _getAttendeeColor(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return AppColors.cyanColor;
      case 'family':
        return AppColors.greenColor;
      case 'guest':
        return AppColors.tealColor;
      default:
        return AppColors.primaryColor;
    }
  }
}
