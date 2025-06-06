import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

class ReminderSettingsManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(bool, List<int>) onReminderSettingsChanged;

  const ReminderSettingsManager({
    super.key,
    required this.state,
    required this.onReminderSettingsChanged,
  });

  @override
  State<ReminderSettingsManager> createState() =>
      _ReminderSettingsManagerState();
}

class _ReminderSettingsManagerState extends State<ReminderSettingsManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _slideAnimation;

  bool _enableReminders = true;
  List<int> _selectedReminderTimes = [
    60,
    15
  ]; // Default: 1 hour and 15 minutes before

  final List<ReminderOption> _reminderOptions = [
    ReminderOption(
      minutes: 5,
      label: '5 minutes before',
      icon: CupertinoIcons.clock,
      color: AppColors.orangeColor,
    ),
    ReminderOption(
      minutes: 15,
      label: '15 minutes before',
      icon: CupertinoIcons.clock_fill,
      color: AppColors.yellowColor,
    ),
    ReminderOption(
      minutes: 30,
      label: '30 minutes before',
      icon: CupertinoIcons.alarm,
      color: AppColors.tealColor,
    ),
    ReminderOption(
      minutes: 60,
      label: '1 hour before',
      icon: CupertinoIcons.alarm_fill,
      color: AppColors.primaryColor,
    ),
    ReminderOption(
      minutes: 120,
      label: '2 hours before',
      icon: CupertinoIcons.bell,
      color: AppColors.cyanColor,
    ),
    ReminderOption(
      minutes: 1440,
      label: '1 day before',
      icon: CupertinoIcons.bell_fill,
      color: AppColors.greenColor,
    ),
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
    if (widget.state.enableReminders != null) {
      _enableReminders = widget.state.enableReminders!;
    }
    if (widget.state.reminderTimes != null &&
        widget.state.reminderTimes!.isNotEmpty) {
      _selectedReminderTimes = List.from(widget.state.reminderTimes!);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _updateReminderSettings() {
    widget.onReminderSettingsChanged(_enableReminders, _selectedReminderTimes);
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
            _buildReminderToggle(),
            if (_enableReminders) ...[
              const Gap(20),
              _buildReminderTimesSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderToggle() {
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
                CupertinoIcons.bell_fill,
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
                    'Event Reminders',
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _enableReminders
                        ? 'Get notified before your booking'
                        : 'No reminder notifications',
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
              value: _enableReminders,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _enableReminders = value;
                  if (!value) {
                    _selectedReminderTimes.clear();
                  } else if (_selectedReminderTimes.isEmpty) {
                    _selectedReminderTimes = [60, 15]; // Default reminders
                  }
                });
                _updateReminderSettings();
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTimesSelector() {
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
                        'Reminder Times',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Select when to receive notifications',
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
              children: _reminderOptions.map((option) {
                return _buildReminderOptionCard(option);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOptionCard(ReminderOption option) {
    final isSelected = _selectedReminderTimes.contains(option.minutes);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selectedReminderTimes.remove(option.minutes);
          } else {
            _selectedReminderTimes.add(option.minutes);
            _selectedReminderTimes.sort(); // Keep them sorted
          }
        });
        _updateReminderSettings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    option.color.withOpacity(0.2),
                    option.color.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? option.color.withOpacity(0.6)
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
                  color:
                      isSelected ? option.color : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withOpacity(0.7),
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTextStyle.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: option.color,
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
}

class ReminderOption {
  final int minutes;
  final String label;
  final IconData icon;
  final Color color;

  const ReminderOption({
    required this.minutes,
    required this.label,
    required this.icon,
    required this.color,
  });
}
