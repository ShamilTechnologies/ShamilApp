import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:intl/intl.dart';

/// Modern Date and Time Selector Component
class DateTimeSelector extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final Function(DateTime) onDateChanged;
  final Function(String) onTimeChanged;

  const DateTimeSelector({
    super.key,
    required this.state,
    required this.provider,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  State<DateTimeSelector> createState() => _DateTimeSelectorState();
}

class _DateTimeSelectorState extends State<DateTimeSelector>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _showTimeSlots = false;

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM'
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
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController.forward();
  }

  void _setupInitialState() {
    if (widget.state.selectedDate != null) {
      _selectedDate = widget.state.selectedDate!;
      _showTimeSlots = true;
      _scaleController.forward();
    }
    if (widget.state.selectedTime != null) {
      _selectedTimeSlot = widget.state.selectedTime;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSection(),
          if (_showTimeSlots) ...[
            const Gap(24),
            _buildTimeSection(),
          ],
          const Gap(24),
          _buildQuickDateOptions(),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
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
                        'Select Date',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _selectedDate == DateTime.now()
                            ? 'Choose your preferred date'
                            : DateFormat('EEEE, MMMM d, y')
                                .format(_selectedDate),
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
          ),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryColor,
                onPrimary: Colors.white,
                surface: Colors.transparent,
                onSurface: AppColors.lightText,
              ),
        ),
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onDateChanged: _onDateSelected,
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cyanColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.clock_fill,
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
                        'Select Time',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _selectedTimeSlot != null
                            ? 'Selected: $_selectedTimeSlot'
                            : 'Choose your preferred time slot',
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
            _buildTimeSlotGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) => _buildTimeSlot(_timeSlots[index]),
    );
  }

  Widget _buildTimeSlot(String timeSlot) {
    final isSelected = _selectedTimeSlot == timeSlot;
    final isAvailable = _isTimeSlotAvailable(timeSlot);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable
            ? () {
                HapticFeedback.lightImpact();
                setState(() => _selectedTimeSlot = timeSlot);
                widget.onTimeChanged(timeSlot);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.tealColor],
                  )
                : null,
            color: !isSelected
                ? (isAvailable
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05))
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : (isAvailable
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              timeSlot,
              style: AppTextStyle.getSmallStyle(
                color: isAvailable
                    ? AppColors.lightText
                    : AppColors.lightText.withOpacity(0.4),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateOptions() {
    final quickOptions = [
      {'label': 'Today', 'date': DateTime.now()},
      {
        'label': 'Tomorrow',
        'date': DateTime.now().add(const Duration(days: 1))
      },
      {'label': 'This Weekend', 'date': _getNextWeekend()},
      {
        'label': 'Next Week',
        'date': DateTime.now().add(const Duration(days: 7))
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Options',
          style: AppTextStyle.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: quickOptions
              .map((option) => _buildQuickOption(
                    option['label'] as String,
                    option['date'] as DateTime,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickOption(String label, DateTime date) {
    final isSelected = _isSameDay(_selectedDate, date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _onDateSelected(date);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.tealColor],
                  )
                : null,
            color: !isSelected ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.lightText,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null; // Reset time selection
      if (!_showTimeSlots) {
        _showTimeSlots = true;
        _scaleController.forward();
      }
    });
    widget.onDateChanged(date);
  }

  bool _isTimeSlotAvailable(String timeSlot) {
    // For demo purposes, make some slots unavailable
    final unavailableSlots = ['11:00 AM', '02:00 PM', '05:30 PM'];
    return !unavailableSlots.contains(timeSlot);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now
        .add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }
}
