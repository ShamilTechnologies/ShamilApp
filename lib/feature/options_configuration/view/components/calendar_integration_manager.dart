import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

class CalendarIntegrationManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(bool) onCalendarSettingChanged;

  const CalendarIntegrationManager({
    super.key,
    required this.state,
    required this.onCalendarSettingChanged,
  });

  @override
  State<CalendarIntegrationManager> createState() =>
      _CalendarIntegrationManagerState();
}

class _CalendarIntegrationManagerState extends State<CalendarIntegrationManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _slideAnimation;

  bool _addToCalendar = true;
  String _selectedCalendarApp = 'default';
  bool _enableReminders = true;
  bool _syncWithContacts = false;
  List<int> _reminderMinutes = [15, 60]; // 15 minutes and 1 hour before

  final List<CalendarApp> _calendarApps = [
    CalendarApp(
      id: 'default',
      name: 'Default Calendar',
      icon: CupertinoIcons.calendar,
      color: AppColors.primaryColor,
      description: 'System default calendar app',
    ),
    CalendarApp(
      id: 'google',
      name: 'Google Calendar',
      icon: CupertinoIcons.calendar_circle,
      color: const Color(0xFF4285F4),
      description: 'Sync with Google Calendar',
    ),
    CalendarApp(
      id: 'outlook',
      name: 'Outlook',
      icon: CupertinoIcons.mail,
      color: const Color(0xFF0078D4),
      description: 'Microsoft Outlook Calendar',
    ),
    CalendarApp(
      id: 'apple',
      name: 'Apple Calendar',
      icon: CupertinoIcons.calendar_today,
      color: const Color(0xFF007AFF),
      description: 'Built-in iOS Calendar app',
    ),
  ];

  final List<ReminderTime> _availableReminders = [
    ReminderTime(minutes: 5, label: '5 minutes'),
    ReminderTime(minutes: 15, label: '15 minutes'),
    ReminderTime(minutes: 30, label: '30 minutes'),
    ReminderTime(minutes: 60, label: '1 hour'),
    ReminderTime(minutes: 120, label: '2 hours'),
    ReminderTime(minutes: 1440, label: '1 day'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialState();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_cardAnimation);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  void _setupInitialState() {
    // Initialize with default values
    // These could be loaded from user preferences in a real app
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _updateCalendarSettings() {
    widget.onCalendarSettingChanged(_addToCalendar);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarToggle(),
            if (_addToCalendar) ...[
              const Gap(20),
              _buildCalendarAppSelector(),
              const Gap(20),
              _buildReminderSettings(),
              const Gap(20),
              _buildAdditionalOptions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarToggle() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.cyanColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.calendar_badge_plus,
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
                    'Calendar Integration',
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _addToCalendar
                        ? 'Add booking to your calendar'
                        : 'Don\'t add to calendar',
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            CupertinoSwitch(
              value: _addToCalendar,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _addToCalendar = value;
                });
                _updateCalendarSettings();
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarAppSelector() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.tealColor, AppColors.cyanColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.device_phone_portrait,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar App',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Choose your preferred calendar app',
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.lightText.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: _calendarApps.map((app) {
                return _buildCalendarAppCard(app);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarAppCard(CalendarApp app) {
    final isSelected = _selectedCalendarApp == app.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCalendarApp = app.id;
        });
        _updateCalendarSettings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    app.color.withOpacity(0.2),
                    app.color.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? app.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? app.color : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  app.icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withOpacity(0.7),
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: AppTextStyle.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      app.description,
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.7),
                        fontSize: 13,
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
                    color: app.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSettings() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.alarm,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar Reminders',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        _enableReminders
                            ? 'Event reminders in calendar'
                            : 'No calendar reminders',
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.lightText.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _enableReminders,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _enableReminders = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
          ),
          if (_enableReminders) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Times',
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableReminders.map((reminder) {
                      final isSelected =
                          _reminderMinutes.contains(reminder.minutes);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _reminderMinutes.remove(reminder.minutes);
                            } else {
                              _reminderMinutes.add(reminder.minutes);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.tealColor,
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            reminder.label,
                            style: AppTextStyle.getbodyStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.lightText.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Options',
              style: AppTextStyle.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.person_2,
                    color: AppColors.lightText.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync with Contacts',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Include attendee contact info',
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.lightText.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _syncWithContacts,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _syncWithContacts = value;
                    });
                  },
                  activeColor: AppColors.tealColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarApp {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const CalendarApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ReminderTime {
  final int minutes;
  final String label;

  const ReminderTime({
    required this.minutes,
    required this.label,
  });
}
