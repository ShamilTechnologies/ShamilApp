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
// Calendar Integration Imports
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';

/// Enhanced Calendar Integration Manager with Full Device Calendar Support
class CalendarIntegrationManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final Function(bool) onCalendarIntegrationChanged;
  final String? userId;
  final String? userName;
  final String? userEmail;

  const CalendarIntegrationManager({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    required this.onCalendarIntegrationChanged,
    this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  State<CalendarIntegrationManager> createState() =>
      _CalendarIntegrationManagerState();
}

class _CalendarIntegrationManagerState extends State<CalendarIntegrationManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _addToCalendar = true;
  bool _hasCalendarPermission = false;
  bool _isCheckingPermissions = true;
  List<Calendar> _availableCalendars = [];
  String? _selectedCalendarId;
  bool _syncWithProvider = false;
  bool _enableNotifications = true;

  late DeviceCalendarPlugin _deviceCalendarPlugin;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCalendar();
    _addToCalendar = true; // Default to enabled
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeCalendar() async {
    try {
      _deviceCalendarPlugin = DeviceCalendarPlugin();
      await _checkCalendarPermissions();
      if (_hasCalendarPermission) {
        await _loadCalendars();
      }
    } catch (e) {
      debugPrint('Failed to initialize calendar: $e');
    } finally {
      setState(() => _isCheckingPermissions = false);
    }
  }

  Future<void> _checkCalendarPermissions() async {
    try {
      final permissionResult = await _deviceCalendarPlugin.hasPermissions();
      setState(() {
        _hasCalendarPermission =
            permissionResult.isSuccess && (permissionResult.data ?? false);
      });
    } catch (e) {
      debugPrint('Error checking calendar permissions: $e');
      setState(() => _hasCalendarPermission = false);
    }
  }

  Future<void> _loadCalendars() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        setState(() {
          _availableCalendars = calendarsResult.data!
              .where((calendar) => !(calendar.isReadOnly ?? true))
              .toList();

          // Select default calendar
          if (_availableCalendars.isNotEmpty && _selectedCalendarId == null) {
            final defaultCalendar = _availableCalendars.firstWhere(
              (calendar) => calendar.isDefault ?? false,
              orElse: () => _availableCalendars.first,
            );
            _selectedCalendarId = defaultCalendar.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading calendars: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
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
              _buildHeader(),
              if (_isCheckingPermissions) _buildLoadingState(),
              if (!_isCheckingPermissions && !_hasCalendarPermission)
                _buildPermissionPrompt(),
              if (!_isCheckingPermissions && _hasCalendarPermission) ...[
                _buildCalendarToggle(),
                if (_addToCalendar) ...[
                  const Gap(20),
                  _buildCalendarSelector(),
                  const Gap(20),
                  _buildAdvancedOptions(),
                ],
              ],
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyanColor, AppColors.primaryColor],
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
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Add this booking to your calendar',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_hasCalendarPermission)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.greenColor,
                    size: 14,
                  ),
                  const Gap(4),
                  Text(
                    'Connected',
                    style: app_text_style.getSmallStyle(
                      color: AppColors.greenColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator.adaptive(),
            const Gap(16),
            Text(
              'Checking calendar permissions...',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.orangeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orangeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 48,
              color: AppColors.orangeColor,
            ),
            const Gap(16),
            Text(
              'Calendar Access Required',
              style: app_text_style.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'Allow access to add your booking to your device calendar and set reminders.',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestCalendarPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Grant Calendar Access',
                  style: app_text_style.getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar_today,
              color: _addToCalendar
                  ? AppColors.cyanColor
                  : AppColors.lightText.withValues(alpha: 0.6),
              size: 24,
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to Calendar',
                    style: app_text_style.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Automatically add this booking to your calendar',
                    style: app_text_style.getSmallStyle(
                      color: AppColors.lightText.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _addToCalendar,
              onChanged: _toggleCalendarIntegration,
              activeColor: AppColors.cyanColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSelector() {
    if (_availableCalendars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'No writable calendars found',
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Calendar',
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          ..._availableCalendars.map(_buildCalendarOption),
        ],
      ),
    );
  }

  Widget _buildCalendarOption(Calendar calendar) {
    final isSelected = _selectedCalendarId == calendar.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCalendar(calendar.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyanColor.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.cyanColor.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(calendar.color ?? 0xFF2196F3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calendar.name ?? 'Unknown Calendar',
                        style: app_text_style.getbodyStyle(
                          color: AppColors.lightText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (calendar.accountName?.isNotEmpty == true) ...[
                        const Gap(2),
                        Text(
                          calendar.accountName!,
                          style: app_text_style.getSmallStyle(
                            color: AppColors.lightText.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: isSelected
                      ? AppColors.cyanColor
                      : AppColors.lightText.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),
            _buildAdvancedOption(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: 'Sync with Provider',
              subtitle: 'Update calendar if booking changes',
              value: _syncWithProvider,
              onChanged: (value) => setState(() => _syncWithProvider = value),
            ),
            const Gap(12),
            _buildAdvancedOption(
              icon: CupertinoIcons.bell_fill,
              title: 'Push Notifications',
              subtitle: 'Get app notifications for reminders',
              value: _enableNotifications,
              onChanged: (value) =>
                  setState(() => _enableNotifications = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: value
              ? AppColors.cyanColor
              : AppColors.lightText.withValues(alpha: 0.6),
          size: 20,
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              Text(
                subtitle,
                style: app_text_style.getSmallStyle(
                  color: AppColors.lightText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.cyanColor,
        ),
      ],
    );
  }

  Future<void> _requestCalendarPermissions() async {
    try {
      final permissionResult = await _deviceCalendarPlugin.requestPermissions();
      if (permissionResult.isSuccess && (permissionResult.data ?? false)) {
        setState(() => _hasCalendarPermission = true);
        await _loadCalendars();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error requesting calendar permissions: $e');
    }
  }

  void _toggleCalendarIntegration(bool value) {
    HapticFeedback.lightImpact();
    setState(() => _addToCalendar = value);
    widget.onCalendarIntegrationChanged(value);
  }

  void _selectCalendar(String? calendarId) {
    HapticFeedback.lightImpact();
    setState(() => _selectedCalendarId = calendarId);
  }

  /// Create calendar event from current booking data
  Future<String?> createCalendarEvent() async {
    if (!_addToCalendar ||
        !_hasCalendarPermission ||
        _selectedCalendarId == null) {
      return null;
    }

    try {
      final serviceName =
          widget.service?.name ?? widget.plan?.name ?? 'Service Booking';
      final startDateTime = _combineDateTime(
        widget.state.selectedDate!,
        widget.state.selectedTime!,
      );

      // Estimate duration (default 1 hour if not specified)
      final estimatedDuration = widget.service?.estimatedDurationMinutes ?? 60;
      final endDateTime =
          startDateTime.add(Duration(minutes: estimatedDuration));

      // Create default reminders (1 hour and 1 day before)
      final reminders = <Reminder>[
        Reminder(minutes: 60), // 1 hour before
        Reminder(minutes: 1440), // 1 day before
      ];

      final event = Event(
        _selectedCalendarId,
        title: serviceName,
        description: _buildEventDescription(),
        start: TZDateTime.from(startDateTime, _getLocalTimeZone()),
        end: TZDateTime.from(endDateTime, _getLocalTimeZone()),
        allDay: false,
        location: _buildLocationString(),
        reminders: reminders,
      );

      final createResult =
          await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (createResult?.isSuccess == true) {
        return createResult?.data;
      } else {
        debugPrint('Failed to create calendar event');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return null;
    }
  }

  String _buildEventDescription() {
    final buffer = StringBuffer();

    buffer.writeln('🏢 Provider: ${widget.provider.businessName}');
    buffer.writeln('📋 Service: ${widget.service?.name ?? widget.plan?.name}');

    if (widget.service?.description.isNotEmpty == true) {
      buffer.writeln('📝 Description: ${widget.service!.description}');
    }

    buffer.writeln(
        '💰 Total Cost: EGP ${widget.state.totalPrice.toStringAsFixed(2)}');

    if (widget.state.selectedAttendees.isNotEmpty) {
      buffer.writeln(
          '👥 Attendees: ${widget.state.selectedAttendees.length + (widget.state.includeUserInBooking ? 1 : 0)} people');
    }

    if (widget.state.notes?.isNotEmpty == true) {
      buffer.writeln('📋 Notes: ${widget.state.notes}');
    }

    buffer.writeln('\n📱 Booked via Shamil App');

    return buffer.toString();
  }

  String _buildLocationString() {
    if (widget.state.venueBookingConfig != null) {
      return 'Location details available in booking';
    }

    if (widget.provider.address['street']?.isNotEmpty == true) {
      return '${widget.provider.address['street']}, ${widget.provider.address['city']}';
    }

    return widget.provider.businessName;
  }

  DateTime _combineDateTime(DateTime date, String timeString) {
    try {
      // Parse time string (assumes format like "09:30 AM")
      final timeFormat = DateFormat('hh:mm a');
      final timeOnly = timeFormat.parse(timeString);

      return DateTime(
        date.year,
        date.month,
        date.day,
        timeOnly.hour,
        timeOnly.minute,
      );
    } catch (e) {
      debugPrint('Error parsing time: $e');
      // Fallback to 9 AM
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }

  dynamic _getLocalTimeZone() {
    return null; // Use device local timezone
  }
}
