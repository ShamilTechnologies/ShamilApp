// lib/feature/reservation/data/repositories/reservation_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart'; // Required for TimeOfDay
// For debugPrint
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

  // --- New Methods ---

  /// Updates an attendee's payment status within a specific reservation.
  Future<void> updateAttendeePaymentStatus({
    required String reservationId,
    required String attendeeUserId,
    required PaymentStatus paymentStatus,
    double? amount,
  });

  /// Updates a reservation's community visibility settings.
  Future<void> updateCommunityVisibility({
    required String reservationId,
    required bool isVisible,
    String? hostingCategory,
    String? description,
  });

  /// Gets reservations available for community joining based on filters.
  Future<List<ReservationModel>> getCommunityHostedReservations({
    required String category, // Can be empty string for all categories
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  });

  /// Sends a request to join a specific community-hosted reservation.
  Future<Map<String, dynamic>> requestToJoinReservation({
    required String reservationId,
    required String userId, // User requesting to join
    required String userName,
  });

  /// Allows the host to respond (approve/deny) a join request.
  Future<void> respondToJoinRequest({
    required String reservationId,
    required String requestUserId, // User whose request is being responded to
    required bool isApproved,
  });
}

/// Firebase implementation of the [ReservationRepository].
class FirebaseReservationRepository implements ReservationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  // Updated collection names as per your snippet
  static const String _reservationsCollection = 'reservations';
  static const String _usersCollection = 'endUsers';

  FirebaseReservationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(
                region: 'us-central1'); // Adjust region if needed

  // Helper function to call Cloud Functions
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
        // Handle cases where the function might return non-map data or null
        return {
          'success': false, // Assume failure if format is wrong
          'error': 'Invalid response format from server for $functionName.',
          'data': result.data // Include original data for debugging
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

  // --- Existing Methods Implementation ---

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
      // Assuming reservations are structured under governorateId/providerId subcollections
      // Modify this logic if your Firestore structure is different (e.g., top-level collection)
      if (governorateId != null && governorateId.isNotEmpty) {
        debugPrint(
            "Querying specific partition: $_reservationsCollection/$governorateId/$providerId");
        // This path might be incorrect based on how reservations are stored.
        // If reservations are top-level:
        // query = _firestore.collection(_reservationsCollection)
        //     .where('providerId', isEqualTo: providerId)
        //     .where('governorateId', isEqualTo: governorateId)
        //     ... date and status filters ...

        // Assuming subcollection structure for now:
        query = _firestore
            .collection(_reservationsCollection) // Top-level 'reservations'
            .doc(governorateId)                  // Document for governorate
            .collection(providerId)              // Subcollection for provider
            .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status', whereIn: [ReservationStatus.confirmed.statusString]); // Only confirmed
      } else {
         // If governorateId is missing, query the entire collection group
         // Requires a composite index on providerId, reservationStartTime, status
        debugPrint(
            "Querying collection group '$providerId' (governorateId missing - Check Index Requirements!)");
        // IMPORTANT: Collection group name MUST match the subcollection name (providerId here).
        query = _firestore
            .collectionGroup(providerId) // Query across all subcollections named providerId
            .where('providerId', isEqualTo: providerId) // Ensure it's the correct provider
            .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
            .where('status', whereIn: [ReservationStatus.confirmed.statusString]);
      }

      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map((doc) {
            try {
              return ReservationModel.fromFirestore(doc);
            } catch (e) {
              print("Error parsing reservation doc ${doc.id}: $e");
              return null; // Skip problematic documents
            }
          })
          .whereType<ReservationModel>() // Filter out nulls
          .toList();
      debugPrint(
          "FirebaseReservationRepository: Found ${reservations.length} relevant existing reservations.");
      return reservations;
    } catch (e) {
      print("FirebaseReservationRepository: Error fetching existing reservations from Firestore: $e");
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
      // Consider if fetching without governorate is possible/desirable
      throw Exception("Governorate ID is required to fetch slots.");
    }
    debugPrint(
        "FirebaseReservationRepository: Calling 'getAvailableSlots' Cloud Function for $providerId on $date (Duration: $durationMinutes min, GovID: $governorateId)");
    try {
      // Assuming a Cloud Function handles slot calculation logic
      final result = await _callFunction('getAvailableSlots', {
        'providerId': providerId,
        'governorateId': governorateId,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'durationMinutes': durationMinutes,
      });

      if (result['success'] == false) {
         throw Exception(result['error'] ?? 'Failed to get slots from backend.');
      }

      final List<dynamic> slotStrings = List<dynamic>.from(result['slots'] ?? []);
      final List<TimeOfDay> availableSlots = slotStrings
          .map((slotStr) {
            try {
               final parts = slotStr.toString().split(':');
               if (parts.length == 2) {
                 final hour = int.parse(parts[0]);
                 final minute = int.parse(parts[1]);
                 if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
                   return TimeOfDay(hour: hour, minute: minute);
                 }
               }
            } catch (e) {
               print("Warning: Invalid time slot format received from backend: '$slotStr' - $e");
            }
            return null;
          })
          .whereType<TimeOfDay>()
          .toList();

      // Sort slots chronologically
      availableSlots.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });

      debugPrint("Cloud Function 'getAvailableSlots' returned ${availableSlots.length} valid and sorted slots.");
      return availableSlots;

    } on FirebaseFunctionsException catch (e) {
       debugPrint(
          "FirebaseReservationRepository: FirebaseFunctionsException calling getAvailableSlots - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
      if (e.code == 'not-found') {
        throw Exception("Availability check function not found on the server.");
      } else if (e.code == 'invalid-argument') {
        throw Exception("Invalid data sent for availability check: ${e.message}");
      }
      throw Exception("Server Error (${e.code}): ${e.message ?? 'Failed to get available slots.'}");
    } catch (e) {
       print("FirebaseReservationRepository: Error calling 'getAvailableSlots' Cloud Function or processing slots: $e");
       throw Exception("Failed to get available slots: ${e.toString()}");
    }
  }

  // --- Sequence-Based Methods Implementation ---

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
        'error': 'Missing required location information (Governorate ID).'
      };
    }
    final payload = {
      'userId': userId,
      'providerId': providerId,
      'governorateId': governorateId,
      if (serviceId != null) 'serviceId': serviceId,
      // Map attendees to simple maps for the payload
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'groupSize': attendees.length,
      'preferredDate': DateFormat('yyyy-MM-dd').format(preferredDate),
      'preferredHour': preferredHour.hour, // Send only the hour (0-23)
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
        'error': 'Missing required location information (Governorate ID).'
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
        'error': 'Missing required location information (Governorate ID).'
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


  // --- New Methods Implementation ---

  @override
  Future<void> updateAttendeePaymentStatus({
    required String reservationId,
    required String attendeeUserId,
    required PaymentStatus paymentStatus,
    double? amount,
  }) async {
     // *** IMPORTANT: Need to know the correct path to the reservation document ***
     // This assumes reservations are directly under _reservationsCollection.
     // If they are nested (e.g., under governorate/provider), this path needs adjustment.
    // Example: _firestore.collection(_reservationsCollection).doc(govId).collection(providerId).doc(reservationId);

    DocumentReference reservationRef;
    try {
        // Attempt direct access first (assuming top-level collection)
        reservationRef = _firestore.collection(_reservationsCollection).doc(reservationId);
        final reservationSnapshot = await reservationRef.get();

        if (!reservationSnapshot.exists) {
            // If not found directly, potentially search across collection groups
            // This requires knowing the subcollection structure or having a way to find the doc.
            // For now, we'll assume direct access or throw.
            print("Reservation $reservationId not found directly in $_reservationsCollection.");
             // Example: Search using collection group (requires providerId or common subcollection name)
             // Need governorateId and providerId to construct path if nested. Without them, direct access is the only reliable way unless indexed differently.
             // query = _firestore.collectionGroup(...).where(FieldPath.documentId, isEqualTo: reservationId) ...
            throw Exception('Reservation $reservationId not found.');
        }

        final data = reservationSnapshot.data() as Map<String, dynamic>? ?? {};
        final attendees = List<Map<String, dynamic>>.from(data['attendees'] ?? []);

        // Find and update the specific attendee
        bool found = false;
        final updatedAttendees = attendees.map((attendee) {
          if (attendee['userId'] == attendeeUserId) {
            found = true;
            // Create a mutable copy before modifying
            final mutableAttendee = Map<String, dynamic>.from(attendee);
            mutableAttendee['paymentStatus'] = paymentStatus.name; // Store enum name as string
             if (amount != null) {
                mutableAttendee['amountToPay'] = amount;
             } else {
                // Optionally remove amount if setting to pending/hosted/waived and no amount provided?
                // mutableAttendee.remove('amountToPay');
             }
            return mutableAttendee;
          }
          return attendee;
        }).toList();

        if (!found) {
          throw Exception('Attendee $attendeeUserId not found in reservation $reservationId');
        }

        // Update the reservation document
        await reservationRef.update({
          'attendees': updatedAttendees,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("Successfully updated payment status for $attendeeUserId in $reservationId");

    } catch (e) {
      print("Error updating attendee payment status for reservation $reservationId: $e");
      // Rethrow a more specific or user-friendly error if needed
      throw Exception('Failed to update payment status: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCommunityVisibility({
    required String reservationId,
    required bool isVisible,
    String? hostingCategory,
    String? description,
  }) async {
     // *** Path assumption same as updateAttendeePaymentStatus ***
    DocumentReference reservationRef;
    try {
        reservationRef = _firestore.collection(_reservationsCollection).doc(reservationId);
        // Check existence? Optional, update will fail if it doesn't exist.
        // final reservationSnapshot = await reservationRef.get();
        // if (!reservationSnapshot.exists) throw Exception('Reservation not found');

        final updateData = <String, dynamic>{
          'isCommunityVisible': isVisible,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (isVisible) {
          // Only add hosting fields if making visible AND they are provided
          if (hostingCategory != null) {
            updateData['hostingCategory'] = hostingCategory;
          }
          if (description != null) {
            updateData['hostingDescription'] = description;
          }
        } else {
          // If making not visible, explicitly remove hosting fields
          updateData['hostingCategory'] = FieldValue.delete();
          updateData['hostingDescription'] = FieldValue.delete();
        }

        await reservationRef.update(updateData);
         debugPrint("Successfully updated community visibility for $reservationId to $isVisible");

    } catch (e) {
      print("Error updating community visibility for reservation $reservationId: $e");
      throw Exception('Failed to update community visibility: ${e.toString()}');
    }
  }

  @override
  Future<List<ReservationModel>> getCommunityHostedReservations({
    required String category, // Can be empty string for all
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      // Assuming reservations are in the top-level collection for community queries
      Query query = _firestore
          .collection(_reservationsCollection)
          .where('isCommunityVisible', isEqualTo: true)
          .where('status', isEqualTo: ReservationStatus.confirmed.statusString) // Only confirmed ones
          // Optionally filter out reservations that are full? Requires capacity tracking.
          // .where('attendees.length', isLessThan: 'reservedCapacity') // Complex query
          ;

      // Filter by hosting category if provided
      if (category.isNotEmpty) {
        query = query.where('hostingCategory', isEqualTo: category);
      }

      // Filter by date range - ensure timestamps are handled correctly (UTC recommended)
      DateTime now = DateTime.now().toUtc(); // Use UTC for comparison
      // Default start date to now if not provided, to only show future events
      DateTime effectiveStartDate = startDate?.toUtc() ?? now;

       // Only show reservations starting from effectiveStartDate onwards
      query = query.where('reservationStartTime', isGreaterThanOrEqualTo: Timestamp.fromDate(effectiveStartDate));

      if (endDate != null) {
        query = query.where('reservationStartTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate.toUtc()));
      }

      // Order by start time (ascending) and limit
      // Requires composite index on isCommunityVisible, status, [hostingCategory], reservationStartTime
      query = query.orderBy('reservationStartTime', descending: false)
                   .limit(limit);

       debugPrint("Fetching community reservations with query: ${query.parameters}");
      final querySnapshot = await query.get();

      final reservations = querySnapshot.docs
          .map((doc) {
              try {
                  return ReservationModel.fromFirestore(doc);
              } catch(e) {
                  print("Error parsing community reservation doc ${doc.id}: $e");
                  return null;
              }
          })
          .whereType<ReservationModel>()
          .toList();

        debugPrint("Found ${reservations.length} community reservations.");
        return reservations;

    } catch (e) {
      print("Error fetching community-hosted reservations: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
         throw Exception("Database index missing for fetching community reservations. Check Firestore console configuration.");
      }
      throw Exception('Failed to fetch community reservations: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> requestToJoinReservation({
    required String reservationId,
    required String userId,
    required String userName,
  }) async {
    // Best handled by Cloud Function for validation (is reservation joinable?),
    // updating reservation subcollection/field, and sending notification to host.
    try {
      final payload = {
        'reservationId': reservationId,
        'userId': userId,
        'userName': userName,
      };
      // Assuming Cloud Function name is 'requestToJoinReservation'
      return await _callFunction('requestToJoinReservation', payload);
    } catch (e) {
      // Catch errors from _callFunction or other issues
      print("Error requesting to join reservation $reservationId: $e");
      return {
        'success': false,
        'error': 'Failed to submit join request: ${e.toString()}',
      };
    }
  }

  @override
  Future<void> respondToJoinRequest({
    required String reservationId,
    required String requestUserId,
    required bool isApproved,
  }) async {
    // Best handled by Cloud Function for validation (is user the host?),
    // updating reservation (attendee list, request status), and notifying requester.
    try {
      final payload = {
        'reservationId': reservationId,
        'requestUserId': requestUserId,
        'isApproved': isApproved,
      };
      // Assuming Cloud Function name is 'respondToJoinRequest'
      // This function might not return anything significant on success, just potential errors.
      final result = await _callFunction('respondToJoinRequest', payload);
       if (result['success'] == false) {
          // Throw exception if function indicated failure
          throw Exception(result['error'] ?? 'Cloud function failed to respond to join request.');
       }
       // If successful, no need to return anything from a Future<void>
        debugPrint("Successfully responded to join request for $requestUserId in $reservationId");

    } catch (e) {
      print("Error responding to join request for $requestUserId in reservation $reservationId: $e");
      // Rethrow to signal failure
      throw Exception('Failed to respond to join request: ${e.toString()}');
    }
  }

  // --- Updated createReservationOnBackend ---

  // Override the existing createReservationOnBackend to include new fields defaults
  @override
  Future<Map<String, dynamic>> createReservationOnBackend(
    Map<String, dynamic> payload
  ) async {
    // Ensure necessary fields have defaults if not provided by the BLoC state
    // (Though the BLoC state should ideally provide all needed fields)
    payload.putIfAbsent('isFullVenueReservation', () => false);
    payload.putIfAbsent('isCommunityVisible', () => false);

    // If reservedCapacity isn't explicitly set (e.g., for non-venue types),
    // default it based on groupSize if available.
    if (!payload.containsKey('reservedCapacity') && payload.containsKey('groupSize')) {
      payload['reservedCapacity'] = payload['groupSize'];
    }

    // Ensure governorateId is present (already checked in BLoC, but good fallback)
     if (payload['governorateId'] == null || (payload['governorateId'] as String).isEmpty) {
      return {
        'success': false,
        'error': 'Internal error: Missing location context (Governorate ID) in final payload.'
      };
    }

    // Call the Cloud Function with the potentially augmented payload
    return await _callFunction('createReservation', payload);
  }
}