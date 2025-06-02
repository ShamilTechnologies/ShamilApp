import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:gap/gap.dart';

class CalendarIntegrationSection extends StatelessWidget {
  final OptionsConfigurationState state;

  const CalendarIntegrationSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar_badge_plus,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Calendar Integration",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Calendar integration toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Add to Calendar",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              subtitle: Text(
                "Automatically add this event to your device calendar",
                style: AppTextStyle.getSmallStyle(
                  color: Colors.grey,
                ),
              ),
              value: state.addToCalendar,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                context.read<OptionsConfigurationBloc>().add(
                      ToggleAddToCalendar(addToCalendar: value),
                    );
              },
            ),

            // Info about calendar permissions
            if (state.addToCalendar)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        "You'll be asked for calendar permissions when confirming your booking",
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
