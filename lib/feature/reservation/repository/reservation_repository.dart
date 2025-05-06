// lib/feature/reservation/repository/reservation_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';

/// Abstract interface for reservation data operations.
abstract class ReservationRepository {
  /// Fetches existing confirmed reservations for a specific provider and date.
  Future<List<ReservationModel>> fetchExistingReservations(
      String providerId, String? governorateId, DateTime date);

  /// Fetches available time slots for a specific provider, date, and duration.
  /// This should ideally call a backend function for complex logic.
  // ADDED: Method signature
  Future<List<TimeOfDay>> fetchAvailableSlots({
      required String providerId,
      required String? governorateId, // Needed if backend uses partitioning
      required DateTime date,
      required int durationMinutes,
  });

  /// Calls the backend function to create a new reservation.
  Future<Map<String, dynamic>> createReservationOnBackend(
      Map<String, dynamic> payload);
}

/// Firebase implementation of the [ReservationRepository].
class FirebaseReservationRepository implements ReservationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Explicitly set Cloud Functions region
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1'); // TODO: Adjust region if needed

  @override
  Future<List<ReservationModel>> fetchExistingReservations(
      String providerId, String? governorateId, DateTime date) async {
    print(
        "FirebaseReservationRepository: Fetching existing reservations for Provider $providerId on $date (Gov ID: $governorateId)");

    // Calculate start and end Timestamps for the selected date (UTC)
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay =
        DateTime.utc(date.year, date.month, date.day, 23, 59, 59, 999);
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    print(
        "FirebaseReservationRepository: Querying reservations between $startTimestamp and $endTimestamp");

    try {
      // Decide query strategy based on governorateId availability
      Query query;
      if (governorateId != null && governorateId.isNotEmpty) {
        // Strategy 1: Query specific partition (Preferred if governorateId is reliable)
        // Requires Firestore index: reservations/{governorateId}/{providerId} -> reservationStartTime (asc), status (asc)
        print("Querying specific partition: reservations/$governorateId/$providerId");
        query = _firestore
            .collection('reservations')
            .doc(governorateId)
            .collection(providerId) // Use providerId as subcollection name here
            .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status', isEqualTo: ReservationStatus.confirmed.statusString);

      } else {
        // Strategy 2: Fallback to Collection Group Query (Requires different index)
        // Requires index: reservations (collection group) -> providerId (asc), reservationStartTime (asc), status (asc)
        print("Querying collection group 'reservations' (governorateId missing or empty)");
        query = _firestore
            .collectionGroup('reservations')
            .where('providerId', isEqualTo: providerId)
            .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status', isEqualTo: ReservationStatus.confirmed.statusString);
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

      print(
          "FirebaseReservationRepository: Found ${reservations.length} existing confirmed reservations.");
      return reservations;
    } catch (e) {
      print(
          "FirebaseReservationRepository: Error fetching existing reservations from Firestore: $e");
      // Rethrow to allow handling in the Bloc
      throw Exception("Failed to fetch existing bookings: $e");
    }
  }

  // ADDED: Implementation for fetchAvailableSlots
  @override
  Future<List<TimeOfDay>> fetchAvailableSlots({
    required String providerId,
    required String? governorateId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    print("FirebaseReservationRepository: Calling 'getAvailableSlots' Cloud Function for $providerId on $date (Duration: $durationMinutes min)");
    // --- Placeholder: Replace with actual Cloud Function Call ---
    // This simulates fetching slots from a backend function.
    try {
      final HttpsCallable callable = _functions.httpsCallable('getAvailableSlots'); // TODO: Create this Cloud Function
      final result = await callable.call(<String, dynamic>{
        'providerId': providerId,
        'governorateId': governorateId, // Pass governorateId
        'date': DateFormat('yyyy-MM-dd').format(date), // Send date as string
        'durationMinutes': durationMinutes,
      });

      // Assuming the Cloud Function returns a list of available start times as strings 'HH:mm'
      final List<dynamic> slotStrings = List<dynamic>.from(result.data['slots'] ?? []);
      final List<TimeOfDay> availableSlots = slotStrings.map((slotStr) {
        final parts = slotStr.toString().split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
        return null; // Invalid format
      }).whereType<TimeOfDay>().toList(); // Filter out nulls

      print("Cloud Function 'getAvailableSlots' returned ${availableSlots.length} slots.");
      return availableSlots;

    } on FirebaseFunctionsException catch (e) {
        print("FirebaseReservationRepository: FirebaseFunctionsException calling getAvailableSlots - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
        throw Exception("Cloud Function Error (${e.code}): ${e.message ?? 'Failed to get available slots.'}");
    } catch (e) {
      print("FirebaseReservationRepository: Error calling 'getAvailableSlots' Cloud Function: $e");
      // Fallback or rethrow
      // Example fallback: return an empty list
      // return [];
      throw Exception("Failed to get available slots: ${e.toString()}");
    }
    // --- End Placeholder ---
  }


  @override
  Future<Map<String, dynamic>> createReservationOnBackend(
      Map<String, dynamic> payload) async {
    print(
        "FirebaseReservationRepository: Calling 'createReservation' Cloud Function...");
    try {
      // TODO: Ensure 'createReservation' Cloud Function exists and matches this name/region
      final HttpsCallable callable =
          _functions.httpsCallable('createReservation');
      final result = await callable.call(payload);
      print("Cloud Function 'createReservation' result data: ${result.data}");
      // Return the data map from the function result
      return Map<String, dynamic>.from(result.data ?? {});
    } on FirebaseFunctionsException catch (e) {
       print("FirebaseReservationRepository: FirebaseFunctionsException calling createReservation - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
       // Rethrow a structured error or the original exception
       throw Exception("Cloud Function Error (${e.code}): ${e.message ?? 'Failed to create reservation.'}");
    } catch (e) {
      print("FirebaseReservationRepository: Generic error calling createReservation Cloud Function: $e");
      throw Exception("Failed to create reservation: ${e.toString()}");
    }
  }
}