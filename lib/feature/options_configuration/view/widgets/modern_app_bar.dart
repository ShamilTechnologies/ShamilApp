import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

/// Modern Sliver App Bar with Gradient Background
class ModernSliverAppBar extends StatelessWidget {
  final OptionsConfigurationState state;
  final bool isPlan;
  final bool isScrolled;
  final VoidCallback onBackPressed;

  const ModernSliverAppBar({
    super.key,
    required this.state,
    required this.isPlan,
    required this.isScrolled,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isScrolled ? AppColors.primaryColor : Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildExpandedBackground(),
        collapseMode: CollapseMode.parallax,
        centerTitle: false,
        title: isScrolled ? _buildCollapsedTitle() : null,
        titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
      ),
      leading: _buildBackButton(),
      actions: [
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildExpandedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.9),
            AppColors.primaryColor.withOpacity(0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceBadge(),
            const Gap(12),
            _buildServiceTitle(),
            const Gap(8),
            _buildServiceSubtitle(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPlan ? CupertinoIcons.star_fill : CupertinoIcons.calendar,
            color: Colors.white,
            size: 14,
          ),
        ),
        const Gap(8),
        Flexible(
          child: Text(
            state.itemName,
            style: AppTextStyle.getTitleStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBackPressed,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              CupertinoIcons.chevron_left,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Handle menu action
          },
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              CupertinoIcons.ellipsis,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlan ? CupertinoIcons.star_fill : CupertinoIcons.calendar,
            color: Colors.white,
            size: 16,
          ),
          const Gap(6),
          Text(
            isPlan ? "Subscription Plan" : "Service Booking",
            style: AppTextStyle.getSmallStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTitle() {
    return Text(
      state.itemName,
      style: AppTextStyle.getHeadlineTextStyle(
        fontSize: 28,
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildServiceSubtitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            CupertinoIcons.money_dollar_circle,
            color: Colors.white,
            size: 16,
          ),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Starting from",
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                "${_getCurrencySymbol()}${state.basePrice.toStringAsFixed(2)}",
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.greenColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.greenColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            "Available",
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
