// lib/feature/reservation/data/repositories/reservation_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'; // Updated import path

/// Abstract interface for reservation data operations.
abstract class ReservationRepository {
  /// Fetches existing confirmed reservations for a specific provider and date.
  Future<List<ReservationModel>> fetchExistingReservations(
      String providerId, String? governorateId, DateTime date);

  /// Fetches available time slots for a specific provider, date, and duration.
  /// Used primarily for time-based, seat-based, recurring types.
  Future<List<TimeOfDay>> fetchAvailableSlots({
    required String providerId,
    required String? governorateId,
    required DateTime date,
    required int durationMinutes,
  });

  /// Calls the backend function to create a new reservation (for non-queue types).
  Future<Map<String, dynamic>> createReservationOnBackend(
      Map<String, dynamic> payload);

  // --- Sequence-Based Methods ---

  /// Calls the backend function to add the user to a specific hourly queue.
  /// Expects a result map like {'success': bool, 'queuePosition': int?, 'estimatedEntryTime': timestamp?, 'error': string?}.
  Future<Map<String, dynamic>> joinQueue({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required List<AttendeeModel> attendees,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  });

  /// Calls the backend function to get the user's current queue status for a specific hour.
  /// Expects a result map like {'success': bool, 'queuePosition': int?, 'estimatedEntryTime': timestamp?, 'error': string?}.
  Future<Map<String, dynamic>> checkQueueStatus({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  });

  /// Calls the backend function to remove the user from a specific hourly queue.
  /// Expects a result map like {'success': bool, 'error': string?}.
  Future<Map<String, dynamic>> leaveQueue({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  });
}

/// Firebase implementation of the [ReservationRepository].
class FirebaseReservationRepository implements ReservationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const String _reservationsRootCollection = 'reservations';

  FirebaseReservationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'); // Adjust region if needed

  Future<Map<String, dynamic>> _callFunction(
      String functionName, Map<String, dynamic> payload) async {
    debugPrint(
        "FirebaseReservationRepository: Calling '$functionName' Cloud Function...");
    debugPrint("Payload: $payload");
    try {
      final HttpsCallable callable = _functions.httpsCallable(functionName);
      final result = await callable.call(payload);
      debugPrint("Cloud Function '$functionName' result data: ${result.data}");
      if (result.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(result.data);
      } else {
        return {
          'success': false,
          'error': 'Invalid response format from server.'
        };
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          "FirebaseReservationRepository: FirebaseFunctionsException calling $functionName - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
      return {
        'success': false,
        'error': "Server Error (${e.code}): ${e.message ?? 'Operation failed.'}"
      };
    } catch (e) {
      debugPrint(
          "FirebaseReservationRepository: Generic error calling $functionName Cloud Function: $e");
      return {'success': false, 'error': "Operation failed: ${e.toString()}"};
    }
  }

  @override
  Future<List<ReservationModel>> fetchExistingReservations(
      String providerId, String? governorateId, DateTime date) async {
    debugPrint(
        "FirebaseReservationRepository: Fetching existing reservations for Provider $providerId on $date (Gov ID: $governorateId)");
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay =
        DateTime.utc(date.year, date.month, date.day, 23, 59, 59, 999);
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);
    debugPrint(
        "FirebaseReservationRepository: Querying reservations between $startTimestamp and $endTimestamp");
    try {
      Query query;
      if (governorateId != null && governorateId.isNotEmpty) {
        debugPrint(
            "Querying specific partition: $_reservationsRootCollection/$governorateId/$providerId");
        query = _firestore
            .collection(_reservationsRootCollection)
            .doc(governorateId)
            .collection(providerId)
            .where('reservationStartTime',
                isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status',
                whereIn: [ReservationStatus.confirmed.statusString]);
      } else {
        debugPrint(
            "Querying collection group '$providerId' (governorateId missing or empty - Check Index Requirements!)");
        // This assumes subcollection name under governorate doc IS the providerId.
        // If not, adjust collectionGroup name or make governorateId mandatory.
        query = _firestore
            .collectionGroup(providerId)
            .where('providerId', isEqualTo: providerId)
            .where('reservationStartTime',
                isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status',
                whereIn: [ReservationStatus.confirmed.statusString]);
      }
      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map((doc) {
            try {
              return ReservationModel.fromFirestore(doc);
            } catch (e) {
              print("Error parsing reservation doc ${doc.id}: $e");
              return null;
            }
          })
          .whereType<ReservationModel>()
          .toList();
      debugPrint(
          "FirebaseReservationRepository: Found ${reservations.length} relevant existing reservations.");
      return reservations;
    } catch (e) {
      print(
          "FirebaseReservationRepository: Error fetching existing reservations from Firestore: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        throw Exception(
            "Database index missing for fetching reservations. Check Firestore console configuration.");
      }
      throw Exception("Failed to fetch existing bookings: ${e.toString()}");
    }
  }

  @override
  Future<List<TimeOfDay>> fetchAvailableSlots({
    required String providerId,
    required String? governorateId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    if (governorateId == null || governorateId.isEmpty) {
      throw Exception("Governorate ID is required to fetch slots.");
    }
    debugPrint(
        "FirebaseReservationRepository: Calling 'getAvailableSlots' Cloud Function for $providerId on $date (Duration: $durationMinutes min, GovID: $governorateId)");
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('getAvailableSlots');
      final result = await callable.call(<String, dynamic>{
        'providerId': providerId,
        'governorateId': governorateId,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'durationMinutes': durationMinutes,
      });
      final List<dynamic> slotStrings =
          List<dynamic>.from(result.data?['slots'] ?? []);
      final List<TimeOfDay> availableSlots = slotStrings
          .map((slotStr) {
            final parts = slotStr.toString().split(':');
            if (parts.length == 2) {
              final hour = int.tryParse(parts[0]);
              final minute = int.tryParse(parts[1]);
              if (hour != null &&
                  minute != null &&
                  hour >= 0 &&
                  hour <= 23 &&
                  minute >= 0 &&
                  minute <= 59) {
                return TimeOfDay(hour: hour, minute: minute);
              }
            }
            print(
                "Warning: Invalid time slot format received from backend: '$slotStr'");
            return null;
          })
          .whereType<TimeOfDay>()
          .toList();
      availableSlots.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
      debugPrint(
          "Cloud Function 'getAvailableSlots' returned ${availableSlots.length} valid and sorted slots.");
      return availableSlots;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
          "FirebaseReservationRepository: FirebaseFunctionsException calling getAvailableSlots - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
      if (e.code == 'not-found') {
        throw Exception("Availability check function not found on the server.");
      } else if (e.code == 'invalid-argument') {
        throw Exception(
            "Invalid data sent for availability check: ${e.message}");
      }
      throw Exception(
          "Server Error (${e.code}): ${e.message ?? 'Failed to get available slots.'}");
    } catch (e) {
      print(
          "FirebaseReservationRepository: Error calling 'getAvailableSlots' Cloud Function: $e");
      throw Exception("Failed to get available slots: ${e.toString()}");
    }
  }

  @override
  Future<Map<String, dynamic>> createReservationOnBackend(
      Map<String, dynamic> payload) async {
    if (payload['governorateId'] == null ||
        (payload['governorateId'] as String).isEmpty) {
      return {
        'success': false,
        'error': 'Internal error: Missing location context.'
      };
    }
    return await _callFunction('createReservation', payload);
  }

  @override
  Future<Map<String, dynamic>> joinQueue({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required List<AttendeeModel> attendees,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  }) async {
    if (governorateId == null || governorateId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing required location information.'
      };
    }
    final payload = {
      'userId': userId,
      'providerId': providerId,
      'governorateId': governorateId,
      if (serviceId != null) 'serviceId': serviceId,
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'groupSize': attendees.length,
      'preferredDate': DateFormat('yyyy-MM-dd')
          .format(preferredDate), // Send as yyyy-MM-dd string
      'preferredHour': preferredHour.hour, // Send just the hour (integer, 0-23)
    };
    return await _callFunction('joinQueue', payload);
  }

  @override
  Future<Map<String, dynamic>> checkQueueStatus({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  }) async {
    if (governorateId == null || governorateId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing required location information.'
      };
    }
    final payload = {
      'userId': userId,
      'providerId': providerId,
      'governorateId': governorateId,
      if (serviceId != null) 'serviceId': serviceId,
      'preferredDate': DateFormat('yyyy-MM-dd').format(preferredDate),
      'preferredHour': preferredHour.hour,
    };
    return await _callFunction('checkQueueStatus', payload);
  }

  @override
  Future<Map<String, dynamic>> leaveQueue({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
  }) async {
    if (governorateId == null || governorateId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing required location information.'
      };
    }
    final payload = {
      'userId': userId,
      'providerId': providerId,
      'governorateId': governorateId,
      if (serviceId != null) 'serviceId': serviceId,
      'preferredDate': DateFormat('yyyy-MM-dd').format(preferredDate),
      'preferredHour': preferredHour.hour,
    };
    return await _callFunction('leaveQueue', payload);
  }
}