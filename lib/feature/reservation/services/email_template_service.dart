import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:intl/intl.dart';

class EmailTemplateService {
  /// Generates HTML content for booking confirmation emails
  static String generateBookingConfirmationEmail({
    required ReservationModel reservation,
    required String providerName,
    String? logoUrl,
    String? primaryColor = '#5D4037',
    String? accentColor = '#8D6E63',
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Format date and time
    final bookingDate = reservation.reservationStartTime?.toDate();
    final formattedDate = bookingDate != null
        ? dateFormat.format(bookingDate)
        : 'Date not specified';
    final formattedTime = bookingDate != null
        ? timeFormat.format(bookingDate)
        : 'Time not specified';

    // Generate attendee list if any
    String attendeeSection = '';
    if (reservation.attendees.isNotEmpty) {
      attendeeSection = '''
      <tr>
        <td style="padding: 15px 0; border-top: 1px solid #e0e0e0;">
          <h3 style="margin: 0; color: #333;">Attendees</h3>
          <ul style="padding-left: 20px; margin-top: 10px;">
      ''';

      for (var attendee in reservation.attendees) {
        attendeeSection += '''
          <li>${attendee.name} (${attendee.type})</li>
        ''';
      }

      attendeeSection += '''
          </ul>
        </td>
      </tr>
      ''';
    }

    // Generate add-ons section if any
    String addOnsSection = '';
    if (reservation.selectedAddOnsList != null &&
        reservation.selectedAddOnsList!.isNotEmpty) {
      addOnsSection = '''
      <tr>
        <td style="padding: 15px 0; border-top: 1px solid #e0e0e0;">
          <h3 style="margin: 0; color: #333;">Add-ons</h3>
          <ul style="padding-left: 20px; margin-top: 10px;">
      ''';

      for (var addOn in reservation.selectedAddOnsList!) {
        addOnsSection += '''
          <li>${addOn}</li>
        ''';
      }

      addOnsSection += '''
          </ul>
        </td>
      </tr>
      ''';
    }

    // Generate special notes section if any
    String notesSection = '';
    if (reservation.notes != null && reservation.notes!.isNotEmpty) {
      notesSection = '''
      <tr>
        <td style="padding: 15px 0; border-top: 1px solid #e0e0e0;">
          <h3 style="margin: 0; color: #333;">Special Notes</h3>
          <p style="margin-top: 10px; color: #555; font-style: italic;">${reservation.notes}</p>
        </td>
      </tr>
      ''';
    }

    // Generate payment details
    String paymentSection = '''
    <tr>
      <td style="padding: 15px 0; border-top: 1px solid #e0e0e0;">
        <h3 style="margin: 0; color: #333;">Payment Information</h3>
        <p style="margin: 10px 0 0; color: #555;">
          Status: <strong>${_getPaymentStatusText(reservation.paymentStatus)}</strong><br>
          Method: ${(reservation.paymentDetails?['method'] as String?)?.toUpperCase() ?? 'Not specified'}<br>
          Total Amount: ${reservation.totalPrice != null ? '\$${reservation.totalPrice!.toStringAsFixed(2)}' : 'Not specified'}
        </p>
      </td>
    </tr>
    ''';

    // Main HTML template
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Booking Confirmation</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: Arial, sans-serif; color: #333; background-color: #f4f4f4;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #fff; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
        <!-- Header -->
        <div style="background-color: ${primaryColor}; padding: 20px; text-align: center; color: white;">
          ${logoUrl != null ? '<img src="$logoUrl" alt="Logo" style="max-height: 60px; margin-bottom: 15px;">' : ''}
          <h1 style="margin: 0; font-size: 24px;">Booking Confirmation</h1>
        </div>
        
        <!-- Content -->
        <div style="padding: 20px;">
          <p style="font-size: 16px; line-height: 1.5; margin-bottom: 20px;">
            Dear ${_getReservationUserName(reservation)},
          </p>
          <p style="font-size: 16px; line-height: 1.5; margin-bottom: 20px;">
            Your booking has been confirmed! Here are the details of your reservation:
          </p>
          
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 15px 0;">
                <h3 style="margin: 0; color: #333;">Booking Details</h3>
                <p style="margin: 10px 0 0; color: #555;">
                  <strong>Confirmation ID:</strong> ${reservation.id}<br>
                  <strong>Service:</strong> ${reservation.serviceName ?? 'Not specified'}<br>
                  <strong>Provider:</strong> ${providerName}<br>
                  <strong>Date:</strong> ${formattedDate}<br>
                  <strong>Time:</strong> ${formattedTime}<br>
                  <strong>Group Size:</strong> ${reservation.groupSize}
                </p>
              </td>
            </tr>
            
            ${attendeeSection}
            ${addOnsSection}
            ${notesSection}
            ${paymentSection}
            
            <!-- Venue Details -->
            ${_getVenueDetailsSection(reservation)}
            
            <!-- QR Code Placeholder -->
            <tr>
              <td style="padding: 20px 0; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="margin: 0 0 10px; color: #333; font-weight: bold;">Your Booking QR Code</p>
                <div style="border: 1px dashed #ccc; padding: 15px; display: inline-block;">
                  <p style="margin: 0; color: #777; font-size: 12px;">QR Code Placeholder</p>
                </div>
                <p style="margin: 10px 0 0; color: #555; font-size: 14px;">Present this code at arrival</p>
              </td>
            </tr>
          </table>
        </div>
        
        <!-- Footer -->
        <div style="background-color: ${accentColor}; color: white; padding: 15px; text-align: center; font-size: 14px;">
          <p style="margin: 0 0 10px;">
            For any questions or changes, please contact us at:<br>
            <a href="mailto:support@shamil.app" style="color: white; text-decoration: underline;">support@shamil.app</a>
          </p>
          <p style="margin: 0; font-size: 12px;">
            &copy; ${DateTime.now().year} ShamilApp. All rights reserved.
          </p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Generates a simple reminder email template
  static String generateReminderEmail({
    required ReservationModel reservation,
    required String providerName,
    required int minutesBeforeEvent,
    String? primaryColor = '#5D4037',
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Format date and time
    final bookingDate = reservation.reservationStartTime?.toDate();
    final formattedDate = bookingDate != null
        ? dateFormat.format(bookingDate)
        : 'Date not specified';
    final formattedTime = bookingDate != null
        ? timeFormat.format(bookingDate)
        : 'Time not specified';

    // Format reminder time (e.g., "1 hour" or "24 hours")
    final String reminderTimeText = minutesBeforeEvent >= 60
        ? '${minutesBeforeEvent ~/ 60} ${minutesBeforeEvent ~/ 60 == 1 ? 'hour' : 'hours'}'
        : '$minutesBeforeEvent minutes';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Booking Reminder</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: Arial, sans-serif; color: #333; background-color: #f4f4f4;">
      <div style="max-width: 600px; margin: 0 auto; background-color: #fff; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
        <!-- Header -->
        <div style="background-color: ${primaryColor}; padding: 20px; text-align: center; color: white;">
          <h1 style="margin: 0; font-size: 24px;">Booking Reminder</h1>
        </div>
        
        <!-- Content -->
        <div style="padding: 20px;">
          <p style="font-size: 16px; line-height: 1.5; margin-bottom: 20px;">
            Dear ${_getReservationUserName(reservation)},
          </p>
          <p style="font-size: 16px; line-height: 1.5; margin-bottom: 20px;">
            This is a reminder that your booking is coming up in <strong>${reminderTimeText}</strong>. Here are the details:
          </p>
          
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
            <tr>
              <td style="padding: 15px; background-color: #f9f9f9; border-radius: 5px;">
                <p style="margin: 0; color: #555;">
                  <strong>Service:</strong> ${reservation.serviceName ?? 'Not specified'}<br>
                  <strong>Provider:</strong> ${providerName}<br>
                  <strong>Date:</strong> ${formattedDate}<br>
                  <strong>Time:</strong> ${formattedTime}<br>
                  <strong>Confirmation ID:</strong> ${reservation.id}
                </p>
              </td>
            </tr>
          </table>
          
          <p style="font-size: 16px; line-height: 1.5; color: #555;">
            We look forward to seeing you soon!
          </p>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #eaeaea; color: #555; padding: 15px; text-align: center; font-size: 14px;">
          <p style="margin: 0;">
            &copy; ${DateTime.now().year} ShamilApp
          </p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Generates calendar event data for calendar integration
  static Map<String, dynamic> generateCalendarEventData({
    required ReservationModel reservation,
    required String providerName,
    String? locationAddress,
    String? locationName,
  }) {
    // Get event start and end times
    final DateTime? startTime = reservation.reservationStartTime?.toDate();

    // Calculate end time (default to 1 hour if duration not specified)
    final int durationMinutes = reservation.durationMinutes ?? 60;
    final DateTime? endTime =
        startTime?.add(Duration(minutes: durationMinutes));

    // Generate description with all details
    final StringBuffer description = StringBuffer();
    description.write('Booking at $providerName\n');
    description.write('Confirmation ID: ${reservation.id}\n');

    if (reservation.serviceName != null &&
        reservation.serviceName!.isNotEmpty) {
      description.write('Service: ${reservation.serviceName}\n');
    }

    if (reservation.notes != null && reservation.notes!.isNotEmpty) {
      description.write('\nNotes: ${reservation.notes}\n');
    }

    // Add attendees info if available
    if (reservation.attendees.isNotEmpty) {
      description.write('\nAttendees:\n');
      for (var attendee in reservation.attendees) {
        description.write('- ${attendee.name} (${attendee.type})\n');
      }
    }

    // Create event data map
    return {
      'title': 'Booking: ${reservation.serviceName ?? providerName}',
      'description': description.toString(),
      'start': startTime,
      'end': endTime,
      'location': locationName ?? providerName,
      'address': locationAddress,
      'allDay': false,
      'reservationId': reservation.id,
    };
  }

  // Helper methods

  static String _getReservationUserName(ReservationModel reservation) {
    // Try to find the host attendee first
    final hostAttendee = reservation.attendees.firstWhere((att) => att.isHost,
        orElse: () => reservation.attendees.isNotEmpty
            ? reservation.attendees.first
            : AttendeeModel(
                userId: '',
                name: 'Valued Customer',
                type: 'self',
                status: 'going'));

    // Return the host's name or fall back to reservation username
    return hostAttendee.name.isNotEmpty
        ? hostAttendee.name
        : (reservation.userName.isNotEmpty
            ? reservation.userName
            : 'Valued Customer');
  }

  static String _getPaymentStatusText(String? status) {
    if (status == null) return 'Pending';

    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partially Paid';
      case 'complete':
        return 'Paid';
      case 'hosted':
        return 'Host Paying';
      case 'waived':
        return 'Payment Waived';
      default:
        return 'Pending';
    }
  }

  static String _getVenueDetailsSection(ReservationModel reservation) {
    // Check for typeSpecificData since venueBookingDetails is stored there
    if (reservation.typeSpecificData == null ||
        reservation.typeSpecificData!['venueBookingDetails'] == null) {
      return '';
    }

    final venueDetails = reservation.typeSpecificData!['venueBookingDetails']
        as Map<String, dynamic>?;
    if (venueDetails == null) return '';

    final isFullVenue = reservation.isFullVenueReservation;
    final capacity = isFullVenue
        ? venueDetails['maxCapacity']
        : venueDetails['selectedCapacity'];
    final isPrivate = venueDetails['isPrivate'] ?? false;

    return '''
    <tr>
      <td style="padding: 15px 0; border-top: 1px solid #e0e0e0;">
        <h3 style="margin: 0; color: #333;">Venue Information</h3>
        <p style="margin: 10px 0 0; color: #555;">
          <strong>Booking Type:</strong> ${isFullVenue ? 'Full Venue' : 'Partial Capacity'}<br>
          <strong>Capacity:</strong> ${capacity ?? 'Not specified'} people<br>
          <strong>Privacy:</strong> ${isPrivate ? 'Private Event' : 'Public Event'}
        </p>
      </td>
    </tr>
    ''';
  }
}
