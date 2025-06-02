import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:gap/gap.dart';

class ReminderSettingsSection extends StatelessWidget {
  final OptionsConfigurationState state;

  const ReminderSettingsSection({
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
                    CupertinoIcons.bell_fill,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Reminders",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Reminder toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Enable Reminders",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              subtitle: Text(
                "Get notifications before your booking",
                style: AppTextStyle.getSmallStyle(
                  color: Colors.grey,
                ),
              ),
              value: state.enableReminders,
              activeColor: AppColors.primaryColor,
              onChanged: (value) {
                context.read<OptionsConfigurationBloc>().add(
                      UpdateReminderSettings(
                        enableReminders: value,
                        reminderTimes: state.reminderTimes,
                      ),
                    );
              },
            ),

            if (state.enableReminders) ...[
              const Divider(),
              const Gap(8),
              Text(
                "Reminder Times",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              const Gap(8),

              // Reminder options
              Wrap(
                spacing: 8,
                children: [
                  _buildReminderChip(context, 15, "15 minutes before"),
                  _buildReminderChip(context, 30, "30 minutes before"),
                  _buildReminderChip(context, 60, "1 hour before"),
                  _buildReminderChip(context, 180, "3 hours before"),
                  _buildReminderChip(context, 1440, "1 day before"),
                ],
              ),

              const Gap(8),
              // Info about permissions
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
                        "You'll be asked for notification permissions if not already granted",
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderChip(BuildContext context, int minutes, String label) {
    final bool isSelected = state.reminderTimes.contains(minutes);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        List<int> updatedTimes = List.from(state.reminderTimes);

        if (selected) {
          if (!updatedTimes.contains(minutes)) {
            updatedTimes.add(minutes);
          }
        } else {
          updatedTimes.remove(minutes);
        }

        // Sort by time (ascending)
        updatedTimes.sort();

        context.read<OptionsConfigurationBloc>().add(
              UpdateReminderSettings(
                enableReminders: state.enableReminders,
                reminderTimes: updatedTimes,
              ),
            );
      },
      backgroundColor: Colors.grey.withOpacity(0.1),
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      checkmarkColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
