import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;

/// Shared step header component
class StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const StepHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: app_text_style.getTitleStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
        ),
        const Gap(8),
        Text(
          subtitle,
          style: app_text_style.getbodyStyle(
            fontSize: 16,
            color: AppColors.lightText.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
