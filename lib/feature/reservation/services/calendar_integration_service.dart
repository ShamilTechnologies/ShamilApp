import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/services/email_template_service.dart';

class CalendarIntegrationService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  // Enhanced calendar permission request with fallback to permission_handler
  Future<bool> requestCalendarPermission() async {
    try {
      // Try device_calendar plugin's permission request first
      final permissions = await _deviceCalendarPlugin.requestPermissions();
      final bool hasPermissions = permissions.isSuccess ?? false;

      // If that fails and we're on Android, try permission_handler as fallback
      if (!hasPermissions && Platform.isAndroid) {
        final status = await Permission.calendar.request();
        return status.isGranted;
      }

      return hasPermissions;
    } catch (e) {
      debugPrint('Error requesting calendar permissions: $e');
      // Try permission_handler as a fallback
      if (Platform.isAndroid) {
        final status = await Permission.calendar.request();
        return status.isGranted;
      }
      return false;
    }
  }

  // Get list of available calendars with better error handling
  Future<List<Calendar>> getAvailableCalendars() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess ?? false) {
        final calendars = calendarsResult.data ?? <Calendar>[];

        // Log calendars for debugging
        if (calendars.isEmpty) {
          debugPrint('No calendars found on device');
        } else {
          debugPrint('Found ${calendars.length} calendars on device');
          for (var cal in calendars) {
            debugPrint('Calendar: ${cal.name} (${cal.id})');
          }
        }

        return calendars;
      } else {
        debugPrint(
            'Failed to retrieve calendars: ${calendarsResult.errors.join(", ")}');
      }
      return <Calendar>[];
    } catch (e) {
      debugPrint('Exception while retrieving calendars: $e');
      return <Calendar>[];
    }
  }

  // Add reservation to calendar using the new template service
  Future<bool> addReservationToCalendar({
    required ReservationModel reservation,
    required String calendarId,
    required String providerName,
    String? locationAddress,
    String? locationName,
  }) async {
    try {
      debugPrint('Starting calendar event creation process...');

      // Generate calendar event data using the email template service
      final eventData = EmailTemplateService.generateCalendarEventData(
        reservation: reservation,
        providerName: providerName,
        locationAddress: locationAddress,
        locationName: locationName,
      );

      // Check if we have valid start time
      if (eventData['start'] == null) {
        debugPrint('Invalid start time for calendar event');
        return false;
      }

      final startTime =
          tz.TZDateTime.from(eventData['start'] as DateTime, tz.local);
      final endTime = eventData['end'] != null
          ? tz.TZDateTime.from(eventData['end'] as DateTime, tz.local)
          : startTime.add(const Duration(minutes: 60));

      // Create explicit attendees list
      final List<Attendee> attendeesList = [];
      for (var attendee in reservation.attendees) {
        // Only add if we have a valid email-like userId or a name
        if (attendee.name.isNotEmpty) {
          attendeesList.add(Attendee(
            name: attendee.name,
            emailAddress:
                attendee.userId.contains('@') ? attendee.userId : null,
            role: null,
          ));
        }
      }

      debugPrint('Creating event for calendar: $calendarId');
      debugPrint('Event title: ${eventData['title']}');
      debugPrint('Event time: $startTime to $endTime');

      final event = Event(
        calendarId,
        title: eventData['title'] as String,
        description: eventData['description'] as String,
        start: startTime,
        end: endTime,
        location: eventData['address'] as String?,
        attendees: attendeesList,
        // Android requires additional URL field for some calendar apps
        url: Platform.isAndroid && reservation.id.isNotEmpty
            ? Uri.parse('https://shamil.app/booking/${reservation.id}')
            : null,
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (result?.isSuccess ?? false) {
        debugPrint('Calendar event created successfully');
        return true;
      } else {
        debugPrint(
            'Failed to create calendar event: ${result?.errors.join(", ")}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception while creating calendar event: $e');
      return false;
    }
  }

  // Remove reservation from calendar
  Future<bool> removeReservationFromCalendar(
      String eventId, String calendarId) async {
    try {
      final result =
          await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      return result.isSuccess ?? false;
    } catch (e) {
      debugPrint('Error removing calendar event: $e');
      return false;
    }
  }

  // Legacy method for backward compatibility
  Future<bool> addReservationToCalendarLegacy(
    ReservationModel reservation,
    String calendarId,
  ) async {
    if (reservation.reservationStartTime == null) {
      return false;
    }

    final startTime = tz.TZDateTime.from(
        reservation.reservationStartTime!.toDate(), tz.local);
    final endTime = reservation.endTime != null
        ? tz.TZDateTime.from(reservation.endTime!.toDate(), tz.local)
        : startTime.add(Duration(minutes: reservation.durationMinutes ?? 60));

    final event = Event(
      calendarId,
      title: 'Reservation: ${reservation.serviceName ?? "Service"}',
      description: _generateEventDescription(reservation),
      start: startTime,
      end: endTime,
      attendees: reservation.attendees
          .map((a) => Attendee(name: a.name, emailAddress: a.userId))
          .toList(),
    );

    final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    return result?.isSuccess ?? false;
  }

  // Generate event description (legacy method)
  String _generateEventDescription(ReservationModel reservation) {
    final buffer = StringBuffer();

    // Add service details
    if (reservation.serviceName != null) {
      buffer.writeln('Service: ${reservation.serviceName}');
    }

    // Add location if available
    if (reservation.typeSpecificData?['location'] != null) {
      buffer.writeln('Location: ${reservation.typeSpecificData!['location']}');
    }

    // Add attendees
    if (reservation.attendees.isNotEmpty) {
      buffer.writeln('\nAttendees:');
      for (var attendee in reservation.attendees) {
        buffer.writeln('- ${attendee.name}');
      }
    }

    // Add notes if available
    if (reservation.notes != null && reservation.notes!.isNotEmpty) {
      buffer.writeln('\nNotes:');
      buffer.writeln(reservation.notes);
    }

    // Add reservation code
    if (reservation.reservationCode != null) {
      buffer.writeln('\nReservation Code: ${reservation.reservationCode}');
    }

    return buffer.toString();
  }

  // Check if event exists in calendar
  Future<bool> eventExistsInCalendar(String eventId, String calendarId) async {
    try {
      final result = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 365)),
          endDate: DateTime.now().add(const Duration(days: 365)),
        ),
      );
      if (result.isSuccess ?? false) {
        return result.data?.any((event) => event.eventId == eventId) ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if event exists: $e');
      return false;
    }
  }

  // Update existing event with the new template service
  Future<bool> updateCalendarEvent({
    required String eventId,
    required String calendarId,
    required ReservationModel reservation,
    required String providerName,
    String? locationAddress,
    String? locationName,
  }) async {
    try {
      // Generate calendar event data using the email template service
      final eventData = EmailTemplateService.generateCalendarEventData(
        reservation: reservation,
        providerName: providerName,
        locationAddress: locationAddress,
        locationName: locationName,
      );

      // Check if we have valid start time
      if (eventData['start'] == null) {
        return false;
      }

      final startTime =
          tz.TZDateTime.from(eventData['start'] as DateTime, tz.local);
      final endTime = eventData['end'] != null
          ? tz.TZDateTime.from(eventData['end'] as DateTime, tz.local)
          : startTime.add(const Duration(minutes: 60));

      // Create explicit attendees list
      final List<Attendee> attendeesList = [];
      for (var attendee in reservation.attendees) {
        // Only add if we have a valid email-like userId or a name
        if (attendee.name.isNotEmpty) {
          attendeesList.add(Attendee(
            name: attendee.name,
            emailAddress:
                attendee.userId.contains('@') ? attendee.userId : null,
            role: null,
          ));
        }
      }

      final event = Event(
        calendarId,
        eventId: eventId,
        title: eventData['title'] as String,
        description: eventData['description'] as String,
        start: startTime,
        end: endTime,
        location: eventData['address'] as String?,
        attendees: attendeesList,
        // Android requires additional URL field for some calendar apps
        url: Platform.isAndroid && reservation.id.isNotEmpty
            ? Uri.parse('https://shamil.app/booking/${reservation.id}')
            : null,
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return result?.isSuccess ?? false;
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return false;
    }
  }
}
