import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/core/services/time_slot_service.dart';
import 'package:intl/intl.dart';

/// Enhanced Date and Time Selector with Capacity Management
class DateTimeSelector extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final Function(DateTime) onDateChanged;
  final Function(String) onTimeChanged;

  const DateTimeSelector({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
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
  late AnimationController _timeSlotController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _timeSlotAnimation;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _showTimeSlots = false;
  bool _isLoadingTimeSlots = false;
  List<TimeSlotCapacity> _timeSlots = [];
  final List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialState();
    _generateAvailableDates();
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
    _timeSlotController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    _timeSlotAnimation = CurvedAnimation(
      parent: _timeSlotController,
      curve: Curves.easeOutCubic,
    );

    _fadeController.forward();
  }

  void _setupInitialState() {
    if (widget.state.selectedDate != null) {
      _selectedDate = widget.state.selectedDate!;
      _showTimeSlots = true;
      _scaleController.forward();
      _generateTimeSlots(_selectedDate);
    }
    if (widget.state.selectedTime != null) {
      _selectedTimeSlot = widget.state.selectedTime;
    }
  }

  @override
  void dispose() {
    _capacityRefreshTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _timeSlotController.dispose();
    super.dispose();
  }

  void _generateAvailableDates() {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 60)); // 60 days in advance

    _availableDates.clear();
    for (var date = now;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      if (_isDateAvailable(date)) {
        _availableDates.add(date);
      }
    }
  }

  bool _isDateAvailable(DateTime date) {
    final dayName = _getDayName(date.weekday);
    final openingHours = widget.provider.openingHours[dayName.toLowerCase()];

    // Check if provider is open on this day
    if (openingHours == null || !openingHours.isOpen) {
      return false;
    }

    // Don't allow booking for past dates
    if (date.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
      return false;
    }

    return true;
  }

  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  void _generateTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingTimeSlots = true;
    });

    _timeSlotController.forward();

    try {
      // Use the enhanced TimeSlotService with real Firebase data
      final timeSlotService = TimeSlotService();

      debugPrint(
          '🔄 Generating time slots for ${widget.provider.businessName} on ${DateFormat('yyyy-MM-dd').format(date)}');

      final slots = await timeSlotService.generateTimeSlots(
        date: date,
        provider: widget.provider,
        service: widget.service,
        plan: widget.plan,
        forceRefresh: true, // Always get fresh data for better UX
      );

      if (mounted) {
        setState(() {
          _timeSlots = slots;
          _isLoadingTimeSlots = false;
        });

        debugPrint(
            '✅ Generated ${slots.length} time slots with real capacity data');

        // Show helpful message if no slots available
        if (slots.isEmpty) {
          _showNoSlotsMessage();
        } else {
          // Auto-refresh capacity every 30 seconds for real-time updates
          _startCapacityRefresh();
        }
      }
    } catch (e) {
      debugPrint('❌ Error generating time slots: $e');
      if (mounted) {
        setState(() {
          _timeSlots = [];
          _isLoadingTimeSlots = false;
        });
        _showErrorMessage(
            'Failed to load available time slots. Please try again.');
      }
    }
  }

  void _showNoSlotsMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                color: AppColors.orangeColor,
                size: 20,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'No available time slots for this date. Try selecting another date.',
                  style: app_text_style.getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.orangeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: AppColors.redColor,
                size: 20,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  message,
                  style: app_text_style.getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.redColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _generateTimeSlots(_selectedDate),
          ),
        ),
      );
    }
  }

  Timer? _capacityRefreshTimer;

  void _startCapacityRefresh() {
    _capacityRefreshTimer?.cancel();
    _capacityRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _timeSlots.isNotEmpty) {
        _refreshCapacityOnly();
      }
    });
  }

  Future<void> _refreshCapacityOnly() async {
    try {
      final timeSlotService = TimeSlotService();
      final updatedSlots = await timeSlotService.refreshSlots(
        date: _selectedDate,
        provider: widget.provider,
        service: widget.service,
        plan: widget.plan,
      );

      if (mounted && updatedSlots.isNotEmpty) {
        setState(() {
          // Update capacity data while preserving selection
          final currentSelection = _selectedTimeSlot;
          _timeSlots = updatedSlots;

          // Restore selection if slot still exists and is available
          if (currentSelection != null) {
            final selectedSlot = _timeSlots.firstWhere(
              (slot) => slot.time == currentSelection,
              orElse: () => _timeSlots.first,
            );

            if (!selectedSlot.isAvailable || selectedSlot.isFull) {
              // Clear selection if slot is no longer available
              _selectedTimeSlot = null;
              widget.onTimeChanged('');
            }
          }
        });

        debugPrint('🔄 Refreshed capacity data for ${_timeSlots.length} slots');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing capacity: $e');
      // Silently fail for background refresh
    }
  }

  void _onDateSelected(DateTime date) {
    if (date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
      _showTimeSlots = true;
    });

    widget.onDateChanged(date);
    _scaleController.forward();
    _generateTimeSlots(date);
  }

  void _onTimeSlotSelected(TimeSlotCapacity slot) {
    if (slot.isFull) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedTimeSlot = slot.time;
    });
    widget.onTimeChanged(slot.time);
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
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
                      colors: [AppColors.primaryColor, AppColors.cyanColor],
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
                        style: app_text_style.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: app_text_style.getbodyStyle(
                          color: AppColors.lightText.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.greenColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_availableDates.length} available',
                    style: app_text_style.getSmallStyle(
                      color: AppColors.greenColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDateGrid(),
        ],
      ),
    );
  }

  Widget _buildDateGrid() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDateSelected(date),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.cyanColor
                            ],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : isToday
                            ? AppColors.tealColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isToday
                              ? AppColors.tealColor
                              : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(date),
                        style: app_text_style.getSmallStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.lightText.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        date.day.toString(),
                        style: app_text_style.getTitleStyle(
                          color:
                              isSelected ? Colors.white : AppColors.lightText,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        DateFormat('EEE').format(date),
                        style: app_text_style.getSmallStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.lightText.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSectionHeader(),
            if (_isLoadingTimeSlots)
              _buildLoadingState()
            else if (_timeSlots.isEmpty)
              _buildEmptyState()
            else
              _buildTimeSlotGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSectionHeader() {
    final availableSlots = _timeSlots.where((slot) => slot.isAvailable).length;
    final totalSlots = _timeSlots.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
              CupertinoIcons.clock,
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
                  'Available Time Slots',
                  style: app_text_style.getTitleStyle(
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
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (totalSlots > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: availableSlots > 0
                    ? AppColors.greenColor.withValues(alpha: 0.2)
                    : AppColors.orangeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$availableSlots/$totalSlots slots',
                style: app_text_style.getSmallStyle(
                  color: availableSlots > 0
                      ? AppColors.greenColor
                      : AppColors.orangeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(_timeSlotAnimation),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced capacity legend
            _buildEnhancedCapacityLegend(),
            const Gap(20),

            // Real-time update indicator
            if (_timeSlots.isNotEmpty) _buildRealTimeIndicator(),

            // Time slots grid with improved design - wrapped in Flexible to prevent overflow
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _timeSlots[index];
                  return _buildEnhancedTimeSlotCard(slot, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCapacityLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability Legend',
            style: app_text_style.getbodyStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              _buildLegendItem(AppColors.greenColor, 'Available'),
              const Gap(16),
              _buildLegendItem(AppColors.orangeColor, 'Filling Up'),
              const Gap(16),
              _buildLegendItem(AppColors.redColor, 'Full'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: app_text_style.getSmallStyle(
            fontSize: 12,
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRealTimeIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.greenColor.withValues(alpha: 0.2),
            AppColors.greenColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.greenColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.greenColor,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(8),
          Text(
            'Live availability • Updated ${_getLastUpdateTime()}',
            style: app_text_style.getSmallStyle(
              fontSize: 11,
              color: AppColors.greenColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLastUpdateTime() {
    if (_timeSlots.isEmpty) return 'now';
    final lastUpdate = _timeSlots.first.lastUpdated;
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }

  Widget _buildEnhancedTimeSlotCard(TimeSlotCapacity slot, int index) {
    final isSelected = _selectedTimeSlot == slot.time;
    final canBook = slot.isAvailable && !slot.isFull;

    Color getStatusColor() {
      if (slot.isFull) return AppColors.redColor;
      if (slot.isAlmostFull) return AppColors.orangeColor;
      return AppColors.greenColor;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canBook ? () => _onTimeSlotSelected(slot) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: canBook ? 0.12 : 0.06),
                        Colors.white.withValues(alpha: canBook ? 0.08 : 0.04),
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.5)
                    : canBook
                        ? getStatusColor().withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : canBook
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time and status indicator - more compact
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot.time,
                        style: app_text_style.getbodyStyle(
                          color: isSelected
                              ? Colors.white
                              : canBook
                                  ? AppColors.lightText
                                  : AppColors.lightText.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getSlotStatusColor(slot),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const Gap(4),

                // Capacity info - simplified
                Text(
                  '${slot.availableSpots}/${slot.totalCapacity}',
                  style: app_text_style.getSmallStyle(
                    fontSize: 10,
                    color: AppColors.lightText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          const Gap(16),
          Text(
            'Loading available time slots...',
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.clock_fill,
            size: 48,
            color: AppColors.lightText.withValues(alpha: 0.5),
          ),
          const Gap(16),
          Text(
            'No Available Time Slots',
            style: app_text_style.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'The provider is not available on this date. Please select another date.',
            textAlign: TextAlign.center,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Get status color for time slot
  Color _getSlotStatusColor(TimeSlotCapacity slot) {
    if (slot.isFull) {
      return Colors.red;
    } else if (slot.isAlmostFull) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
