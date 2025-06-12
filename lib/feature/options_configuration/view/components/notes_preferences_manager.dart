import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

/// Notes and Preferences Manager Component
class NotesPreferencesManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(String) onNotesChanged;

  const NotesPreferencesManager({
    super.key,
    required this.state,
    required this.onNotesChanged,
  });

  @override
  State<NotesPreferencesManager> createState() =>
      _NotesPreferencesManagerState();
}

class _NotesPreferencesManagerState extends State<NotesPreferencesManager> {
  late TextEditingController _notesController;
  final Map<String, bool> _preferences = {
    'notifications': true,
    'reminders': true,
    'calendar': false,
    'sharing': true,
  };

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.state.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildNotesSection();
  }

  Widget _buildNotesSection() {
    return Container(
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealColor, AppColors.cyanColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_fill,
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
                      'Special Notes',
                      style: AppTextStyle.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Any special requests or requirements?',
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              onChanged: widget.onNotesChanged,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.lightText,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:
                    'Enter any special requirements, dietary restrictions, accessibility needs, or other notes...',
                hintStyle: AppTextStyle.getbodyStyle(
                  color: AppColors.lightText.withOpacity(0.5),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
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
          Row(
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
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
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
                      'Preferences',
                      style: AppTextStyle.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Customize your booking experience',
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          _buildPreferenceToggle(
            'notifications',
            'Push Notifications',
            'Get booking updates and reminders',
            CupertinoIcons.bell_fill,
            AppColors.primaryColor,
          ),
          _buildPreferenceToggle(
            'reminders',
            'Email Reminders',
            'Receive reminder emails before your booking',
            CupertinoIcons.mail_solid,
            AppColors.cyanColor,
          ),
          _buildPreferenceToggle(
            'calendar',
            'Add to Calendar',
            'Automatically add to your calendar app',
            CupertinoIcons.calendar,
            AppColors.tealColor,
          ),
          _buildPreferenceToggle(
            'sharing',
            'Allow Sharing',
            'Let attendees share booking details',
            CupertinoIcons.share,
            AppColors.greenColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceToggle(
    String key,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isEnabled = _preferences[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    )
                  : null,
              color: isEnabled ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isEnabled
                  ? Colors.white
                  : AppColors.lightText.withOpacity(0.6),
              size: 18,
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
          CupertinoSwitch(
            value: isEnabled,
            activeColor: color,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _preferences[key] = value);
            },
          ),
        ],
      ),
    );
  }
}
