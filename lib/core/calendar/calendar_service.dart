import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';

/// Comprehensive Calendar Integration Service for Booking Management
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  late DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar>? _calendars;
  bool _isInitialized = false;

  /// Initialize the calendar service
  Future<bool> initialize() async {
    try {
      _deviceCalendarPlugin = DeviceCalendarPlugin();

      // Request calendar permissions
      final permissionResult = await _deviceCalendarPlugin.requestPermissions();

      if (permissionResult.isSuccess && permissionResult.data == true) {
        await _loadCalendars();
        _isInitialized = true;
        debugPrint('✅ Calendar service initialized successfully');
        return true;
      } else {
        debugPrint('❌ Calendar permissions denied');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize calendar service: $e');
      return false;
    }
  }

  /// Load available calendars from the device
  Future<void> _loadCalendars() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if ((calendarsResult.isSuccess ?? false) &&
          calendarsResult.data != null) {
        _calendars = calendarsResult.data!
            .where((calendar) => !(calendar.isReadOnly ?? false))
            .toList();
        debugPrint('📅 Found ${_calendars?.length ?? 0} writable calendars');
      }
    } catch (e) {
      debugPrint('❌ Failed to load calendars: $e');
    }
  }

  /// Get list of available calendars
  List<Calendar> getAvailableCalendars() {
    return _calendars ?? [];
  }

  /// Get the default calendar (usually the primary calendar)
  Calendar? getDefaultCalendar() {
    if (_calendars == null || _calendars!.isEmpty) return null;

    // Try to find the primary calendar
    Calendar? primaryCalendar;
    try {
      primaryCalendar = _calendars!.firstWhere(
        (calendar) => (calendar.isDefault ?? false) == true,
      );
    } catch (e) {
      primaryCalendar = _calendars!.first;
    }

    return primaryCalendar;
  }

  /// Add a booking to the device calendar
  Future<CalendarEventResult> addBookingToCalendar({
    required OptionsConfigurationState bookingState,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
    String? calendarId,
    List<String>? reminderMinutes,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return CalendarEventResult(
          success: false,
          message: 'Calendar service not available',
        );
      }
    }

    try {
      final calendar = calendarId != null
          ? _calendars?.firstWhere((cal) => cal.id == calendarId)
          : getDefaultCalendar();

      if (calendar == null) {
        return CalendarEventResult(
          success: false,
          message: 'No suitable calendar found',
        );
      }

      final event = await _createCalendarEvent(
        bookingState: bookingState,
        provider: provider,
        service: service,
        plan: plan,
        reminderMinutes: reminderMinutes,
      );

      final createResult =
          await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (createResult?.isSuccess == true) {
        return CalendarEventResult(
          success: true,
          eventId: createResult?.data,
          message: 'Event added to calendar successfully',
        );
      } else {
        return CalendarEventResult(
          success: false,
          message: 'Failed to add event to calendar',
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding event to calendar: $e');
      return CalendarEventResult(
        success: false,
        message: 'Error adding event to calendar: $e',
      );
    }
  }

  /// Create a calendar event from booking data
  Future<Event> _createCalendarEvent({
    required OptionsConfigurationState bookingState,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
    List<String>? reminderMinutes,
  }) async {
    final serviceName = service?.name ?? plan?.name ?? 'Service Booking';
    final startDateTime = _combineDateTime(
      bookingState.selectedDate!,
      bookingState.selectedTime!,
    );

    // Estimate duration (default 1 hour if not specified)
    final estimatedDuration = service?.estimatedDurationMinutes ?? 60;
    final endDateTime = startDateTime.add(Duration(minutes: estimatedDuration));

    // Create attendees list
    final attendees = <Attendee>[];
    for (final attendee in bookingState.selectedAttendees) {
      attendees.add(Attendee(
        name: attendee.name,
        emailAddress: attendee.userId, // Use userId as email placeholder
        role: AttendeeRole.Required,
      ));
    }

    // Add the user if included in booking
    if (bookingState.includeUserInBooking) {
      attendees.add(Attendee(
        name: 'You',
        emailAddress: '', // Would come from user profile
        role: AttendeeRole.Required,
      ));
    }

    // Create reminders
    final reminders = <Reminder>[];
    if (reminderMinutes != null) {
      for (final minuteStr in reminderMinutes) {
        final minutes = int.tryParse(minuteStr);
        if (minutes != null) {
          reminders.add(Reminder(minutes: minutes));
        }
      }
    } else {
      // Default reminders: 1 hour and 24 hours before
      reminders.addAll([
        Reminder(minutes: 60),
        Reminder(minutes: 1440),
      ]);
    }

    return Event(
      getDefaultCalendar()?.id,
      title: serviceName,
      description: _buildEventDescription(
        bookingState: bookingState,
        provider: provider,
        service: service,
        plan: plan,
      ),
      start: TZDateTime.from(startDateTime, _getLocalTimeZone()),
      end: TZDateTime.from(endDateTime, _getLocalTimeZone()),
      allDay: false,
      location: _buildLocationString(bookingState, provider),
      attendees: attendees.isNotEmpty ? attendees : null,
      reminders: reminders,
      availability: Availability.Busy,
      status: EventStatus.Confirmed,
    );
  }

  /// Build event description with booking details
  String _buildEventDescription({
    required OptionsConfigurationState bookingState,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🏢 Provider: ${provider.businessName}');
    buffer.writeln('📋 Service: ${service?.name ?? plan?.name}');

    if (service?.description.isNotEmpty == true) {
      buffer.writeln('📝 Description: ${service!.description}');
    }

    buffer.writeln(
        '💰 Total Cost: EGP ${bookingState.totalPrice.toStringAsFixed(2)}');

    if (bookingState.selectedAttendees.isNotEmpty) {
      buffer.writeln(
          '👥 Attendees: ${bookingState.selectedAttendees.length + (bookingState.includeUserInBooking ? 1 : 0)} people');
    }

    if (bookingState.notes?.isNotEmpty == true) {
      buffer.writeln('📋 Notes: ${bookingState.notes}');
    }

    buffer.writeln('\n📱 Booked via Shamil App');

    return buffer.toString();
  }

  /// Build location string from booking data
  String _buildLocationString(
    OptionsConfigurationState bookingState,
    ServiceProviderModel provider,
  ) {
    if (bookingState.venueBookingConfig != null) {
      // Use venue booking configuration when available
      return 'Location details available in booking';
    }

    // Fallback to provider's business address
    if (provider.address['street']?.isNotEmpty == true) {
      return '${provider.address['street']}, ${provider.address['city']}';
    }

    return provider.businessName;
  }

  /// Combine date and time strings into DateTime
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
      debugPrint('❌ Error parsing time: $e');
      // Fallback to 9 AM
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }

  /// Get local timezone (simplified)
  dynamic _getLocalTimeZone() {
    // For production, you'd use proper timezone handling
    // For now, return null to use device local timezone
    return null;
  }

  /// Update an existing calendar event
  Future<CalendarEventResult> updateCalendarEvent({
    required String eventId,
    required OptionsConfigurationState bookingState,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
    String? calendarId,
  }) async {
    try {
      final calendar = calendarId != null
          ? _calendars?.firstWhere((cal) => cal.id == calendarId)
          : getDefaultCalendar();

      if (calendar == null) {
        return CalendarEventResult(
          success: false,
          message: 'No suitable calendar found',
        );
      }

      final event = await _createCalendarEvent(
        bookingState: bookingState,
        provider: provider,
        service: service,
        plan: plan,
      );

      event.eventId = eventId;
      event.calendarId = calendar.id;

      final updateResult =
          await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (updateResult?.isSuccess == true) {
        return CalendarEventResult(
          success: true,
          eventId: eventId,
          message: 'Event updated successfully',
        );
      } else {
        return CalendarEventResult(
          success: false,
          message: 'Failed to update event',
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating calendar event: $e');
      return CalendarEventResult(
        success: false,
        message: 'Error updating event: $e',
      );
    }
  }

  /// Delete a calendar event
  Future<CalendarEventResult> deleteCalendarEvent({
    required String eventId,
    required String calendarId,
  }) async {
    try {
      final deleteResult = await _deviceCalendarPlugin.deleteEvent(
        calendarId,
        eventId,
      );

      if (deleteResult?.isSuccess == true) {
        return CalendarEventResult(
          success: true,
          message: 'Event deleted successfully',
        );
      } else {
        return CalendarEventResult(
          success: false,
          message: 'Failed to delete event',
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting calendar event: $e');
      return CalendarEventResult(
        success: false,
        message: 'Error deleting event: $e',
      );
    }
  }

  /// Get upcoming events for a specific date range
  Future<List<Event>> getUpcomingBookings({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
  }) async {
    try {
      final calendar = calendarId != null
          ? _calendars?.firstWhere((cal) => cal.id == calendarId)
          : getDefaultCalendar();

      if (calendar == null) return [];

      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(
          startDate: start,
          endDate: end,
        ),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        // Filter events that contain "Shamil" in description (our app events)
        return eventsResult.data!
            .where((event) =>
                event.description?.contains('Shamil App') == true ||
                event.title?.contains('Shamil') == true)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error retrieving events: $e');
      return [];
    }
  }

  /// Check if calendar service is available and has permissions
  Future<bool> hasCalendarPermissions() async {
    try {
      final permissionResult = await _deviceCalendarPlugin.hasPermissions();
      return permissionResult.isSuccess && permissionResult.data == true;
    } catch (e) {
      debugPrint('❌ Error checking calendar permissions: $e');
      return false;
    }
  }

  /// Request calendar permissions
  Future<bool> requestCalendarPermissions() async {
    try {
      final permissionResult = await _deviceCalendarPlugin.requestPermissions();
      if (permissionResult.isSuccess && permissionResult.data == true) {
        await _loadCalendars();
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting calendar permissions: $e');
      return false;
    }
  }

  /// Get calendar statistics (number of upcoming bookings, etc.)
  Future<CalendarStats> getCalendarStats() async {
    try {
      final upcomingEvents = await getUpcomingBookings();
      final thisWeekEvents = await getUpcomingBookings(
        endDate: DateTime.now().add(const Duration(days: 7)),
      );
      final thisMonthEvents = await getUpcomingBookings(
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      return CalendarStats(
        totalUpcomingBookings: upcomingEvents.length,
        thisWeekBookings: thisWeekEvents.length,
        thisMonthBookings: thisMonthEvents.length,
        availableCalendars: _calendars?.length ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error getting calendar stats: $e');
      return CalendarStats(
        totalUpcomingBookings: 0,
        thisWeekBookings: 0,
        thisMonthBookings: 0,
        availableCalendars: 0,
      );
    }
  }
}

/// Result class for calendar operations
class CalendarEventResult {
  final bool success;
  final String? eventId;
  final String message;

  CalendarEventResult({
    required this.success,
    this.eventId,
    required this.message,
  });
}

/// Calendar statistics
class CalendarStats {
  final int totalUpcomingBookings;
  final int thisWeekBookings;
  final int thisMonthBookings;
  final int availableCalendars;

  CalendarStats({
    required this.totalUpcomingBookings,
    required this.thisWeekBookings,
    required this.thisMonthBookings,
    required this.availableCalendars,
  });
}
