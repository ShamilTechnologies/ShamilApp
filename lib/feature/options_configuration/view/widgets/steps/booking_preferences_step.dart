import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import '../shared/premium_card.dart';
import '../shared/step_header.dart';

/// Second step: Preferences and cost splitting
class BookingPreferencesStep extends StatelessWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final String costSplitMethod;
  final Function(String) onCostSplitChanged;
  final Animation<double> contentAnimation;

  const BookingPreferencesStep({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    required this.costSplitMethod,
    required this.onCostSplitChanged,
    required this.contentAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: contentAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - contentAnimation.value)),
          child: Opacity(
            opacity: contentAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepHeader(
                    title: 'Preferences & Splitting',
                    subtitle: 'Customize your experience and payment',
                  ),
                  const Gap(24),
                  _buildPreferencesCard(),
                  const Gap(24),
                  _buildCostSplittingCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreferencesCard() {
    return PremiumCard(
      icon: CupertinoIcons.slider_horizontal_3,
      title: 'Preferences',
      subtitle: 'Customize your booking experience',
      gradient: [
        const Color(0xFF0A0E1A),
        AppColors.cyanColor.withOpacity(0.15),
        AppColors.premiumBlue.withOpacity(0.1),
      ],
      shadowColor: AppColors.cyanColor,
      child: _buildPreferencesContent(),
    );
  }

  Widget _buildPreferencesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special Notes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            maxLines: 3,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Add any special requests or notes...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostSplittingCard() {
    return PremiumCard(
      icon: CupertinoIcons.money_dollar_circle,
      title: 'Cost Splitting',
      subtitle: 'How would you like to split the cost?',
      gradient: [
        const Color(0xFF0A0E1A),
        AppColors.successColor.withOpacity(0.15),
        AppColors.tealColor.withOpacity(0.1),
      ],
      shadowColor: AppColors.successColor,
      child: _buildCostSplittingOptions(),
    );
  }

  Widget _buildCostSplittingOptions() {
    return Column(
      children: [
        _buildCostSplitOption(
          'Split Equally',
          'Everyone pays the same amount',
          CupertinoIcons.equal,
          costSplitMethod == 'equal',
          () => onCostSplitChanged('equal'),
        ),
        const Gap(16),
        _buildCostSplitOption(
          'I\'ll Pay Everything',
          'You cover the full cost',
          CupertinoIcons.creditcard_fill,
          costSplitMethod == 'full',
          () => onCostSplitChanged('full'),
        ),
      ],
    );
  }

  Widget _buildCostSplitOption(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.premiumBlue.withOpacity(0.3),
                    AppColors.premiumBlue.withOpacity(0.1),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.premiumBlue.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.premiumBlue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.premiumConfigGradient
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.premiumBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Gap(20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successColor,
                      AppColors.tealColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
