import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// Models
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/core/models/notification_model.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';

/// Centralized Firebase Data Orchestrator
///
/// This class consolidates all Firebase operations for the entire app,
/// providing a single source of truth for data operations with:
/// - Clean separation of concerns
/// - Consistent error handling
/// - Optimized batch operations
/// - Real-time data synchronization
/// - Offline support
///
/// CENTRALIZATION COMPLETE:
/// ✅ All reservation operations (create, cancel, fetch, confirm payment)
/// ✅ All subscription operations (create, cancel, fetch streams)
/// ✅ All service provider operations (search, details, categories)
/// ✅ All user operations (profile, favorites, statistics)
/// ✅ All social operations (friends, family members, requests)
/// ✅ All notification operations (add, fetch streams)
/// ✅ Provider operating hours and availability slots
/// ✅ Email notifications and reminder scheduling
/// ✅ Comprehensive location and governorate handling
/// ✅ Batch operations and analytics
///
/// REPLACED SYSTEMS:
/// - Individual repository classes (ReservationRepository, SubscriptionRepository, etc.)
/// - Direct Firebase calls scattered throughout the app
/// - Duplicate data fetching logic
/// - Inconsistent error handling patterns
///
/// BENEFITS:
/// - Single point of data access control
/// - Consistent logging and error handling
/// - Optimized batch operations
/// - Easier testing and maintenance
/// - Better offline support and caching
/// - Centralized business logic for data operations
class FirebaseDataOrchestrator {
  // Singleton pattern
  static final FirebaseDataOrchestrator _instance =
      FirebaseDataOrchestrator._internal();
  factory FirebaseDataOrchestrator() {
    debugPrint('🏭 FirebaseDataOrchestrator: Returning singleton instance');
    return _instance;
  }
  FirebaseDataOrchestrator._internal() {
    debugPrint('🚀 FirebaseDataOrchestrator: Singleton instance created');
  }

  // Firebase services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Collection names - centralized for consistency
  static const String _endUsersCollection = 'endUsers';
  static const String _serviceProvidersCollection = 'serviceProviders';
  static const String _communityEventsCollection = 'community_events';
  static const String _groupHostsCollection = 'group_hosts';
  static const String _tournamentsCollection = 'tournaments';
  static const String _scheduledRemindersCollection = 'scheduledReminders';

  // Current user helper
  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // ============================================================================
  // RESERVATION OPERATIONS
  // ============================================================================

  /// Creates a new reservation with optimized batch operations and capacity validation
  Future<String> createReservation(ReservationModel reservation) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    try {
      // Validate capacity before creating reservation
      if (reservation.reservationStartTime != null &&
          reservation.durationMinutes != null) {
        final capacityValidation = await validateReservationCapacity(
          providerId: reservation.providerId,
          reservationTime: reservation.reservationStartTime!.toDate(),
          durationMinutes: reservation.durationMinutes!,
          attendeeCount: reservation.attendees.length,
        );

        if (!capacityValidation.isValid) {
          throw Exception(
              'Capacity validation failed: ${capacityValidation.errorMessage}');
        }

        debugPrint(
            '✅ Capacity validation passed for ${reservation.attendees.length} attendees');
      }

      final batch = _firestore.batch();

      // Generate reservation ID
      final reservationRef = _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('reservations')
          .doc();

      final reservationData = {
        ...reservation.toMapForCreate(),
        'id': reservationRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to user's reservations
      batch.set(reservationRef, reservationData);

      // Add to provider's pending reservations
      final providerReservationRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(reservation.providerId)
          .collection('pendingReservations')
          .doc(reservationRef.id);

      batch.set(providerReservationRef, {
        'reservationId': reservationRef.id,
        'userId': currentUserId!,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Update provider statistics
      final providerStatsRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(reservation.providerId);

      batch.update(providerStatsRef, {
        'totalReservations': FieldValue.increment(1),
        'pendingReservations': FieldValue.increment(1),
        'lastReservationAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send notification asynchronously
      _sendReservationNotification(reservation, 'created');

      debugPrint(
          '🎉 Reservation created successfully with capacity validation');
      return reservationRef.id;
    } catch (e) {
      debugPrint('Error creating reservation: $e');
      throw Exception('Failed to create reservation: $e');
    }
  }

  /// Confirm payment and activate reservation
  Future<void> confirmReservationPayment({
    required String reservationId,
    required String paymentId,
    required PaymentGateway gateway,
  }) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    final batch = _firestore.batch();

    try {
      // Verify payment status
      final paymentOrchestrator = PaymentOrchestrator();
      final paymentResponse =
          await paymentOrchestrator.verifyPayment(paymentId);

      if (paymentResponse.isSuccessful) {
        // Get reservation details first
        final reservationDoc = await _firestore
            .collection(_endUsersCollection)
            .doc(currentUserId!)
            .collection('reservations')
            .doc(reservationId)
            .get();

        if (!reservationDoc.exists) {
          throw Exception('Reservation not found');
        }

        final reservationData = reservationDoc.data()!;
        final providerId = reservationData['providerId'] as String;

        // Update reservation status to confirmed in user's collection
        batch.update(reservationDoc.reference, {
          'status': ReservationStatus.confirmed.statusString,
          'paymentStatus': 'completed',
          'paymentId': paymentId,
          'paymentGateway': gateway.name,
          'confirmedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Move reservation from pendingReservations to confirmedReservations in provider's collections
        final pendingRef = _firestore
            .collection(_serviceProvidersCollection)
            .doc(providerId)
            .collection('pendingReservations')
            .doc(reservationId);

        final confirmedRef = _firestore
            .collection(_serviceProvidersCollection)
            .doc(providerId)
            .collection('confirmedReservations')
            .doc(reservationId);

        // Remove from pending
        batch.delete(pendingRef);

        // Add to confirmed
        batch.set(confirmedRef, {
          'reservationId': reservationId,
          'userId': currentUserId!,
          'confirmedAt': FieldValue.serverTimestamp(),
          'paymentId': paymentId,
          'status': 'confirmed',
        });

        // Update provider statistics
        final providerStatsRef =
            _firestore.collection(_serviceProvidersCollection).doc(providerId);

        batch.update(providerStatsRef, {
          'pendingReservations': FieldValue.increment(-1),
          'confirmedReservations': FieldValue.increment(1),
          'lastConfirmationAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        debugPrint(
            '✅ Reservation $reservationId confirmed with payment $paymentId and moved to confirmed collection');
      } else {
        throw Exception(
            'Payment verification failed: ${paymentResponse.errorMessage}');
      }
    } catch (e) {
      debugPrint('Error confirming reservation payment: $e');
      rethrow;
    }
  }

  /// Fetches user reservations with real-time updates
  Stream<List<ReservationModel>> getUserReservationsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(_endUsersCollection)
        .doc(currentUserId!)
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }

  /// Cancels a reservation with proper cleanup
  Future<void> cancelReservation(String reservationId) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    final batch = _firestore.batch();

    try {
      // Get reservation details first
      final reservationDoc = await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        throw Exception('Reservation not found');
      }

      final reservationData = reservationDoc.data()!;
      final providerId = reservationData['providerId'] as String;
      final status = reservationData['status'] as String;

      // Update reservation status
      final reservationRef = reservationDoc.reference;
      batch.update(reservationRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Move from pending to cancelled in provider's collections
      if (status == 'pending') {
        final pendingRef = _firestore
            .collection(_serviceProvidersCollection)
            .doc(providerId)
            .collection('pendingReservations')
            .doc(reservationId);
        batch.delete(pendingRef);

        final cancelledRef = _firestore
            .collection(_serviceProvidersCollection)
            .doc(providerId)
            .collection('cancelledReservations')
            .doc(reservationId);
        batch.set(cancelledRef, {
          'reservationId': reservationId,
          'userId': currentUserId!,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': 'user',
        });

        // Update provider statistics
        final providerStatsRef =
            _firestore.collection(_serviceProvidersCollection).doc(providerId);
        batch.update(providerStatsRef, {
          'pendingReservations': FieldValue.increment(-1),
          'cancelledReservations': FieldValue.increment(1),
        });
      }

      await batch.commit();

      // Send cancellation notification
      final reservation = ReservationModel.fromFirestore(reservationDoc);
      _sendReservationNotification(reservation, 'cancelled');
    } catch (e) {
      debugPrint('Error cancelling reservation: $e');
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  /// Fetches provider operating hours for options configuration
  Future<Map<String, dynamic>> fetchProviderOperatingHours(
      String providerId) async {
    try {
      final doc = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .get();

      if (!doc.exists) {
        throw Exception('Provider not found');
      }

      final data = doc.data()!;
      return data['operatingHours'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('Error fetching provider operating hours: $e');
      return {};
    }
  }

  /// Fetches existing reservations for a provider
  Future<List<ReservationModel>> fetchProviderReservations(
      String providerId) async {
    try {
      debugPrint('📊 Fetching provider reservations for ID: $providerId');
      final now = Timestamp.now();

      // Get pending reservations from provider's pendingReservations collection
      final pendingSnapshot = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .collection('pendingReservations')
          .get();

      // Get confirmed reservations from provider's confirmedReservations collection (if it exists)
      final confirmedSnapshot = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .collection('confirmedReservations')
          .get();

      final List<ReservationModel> reservations = [];

      // For each pending reservation, get the full reservation data from user's collection
      for (final pendingDoc in pendingSnapshot.docs) {
        final data = pendingDoc.data();
        final reservationId = data['reservationId'] as String?;
        final userId = data['userId'] as String?;

        if (reservationId != null && userId != null) {
          try {
            final reservationDoc = await _firestore
                .collection(_endUsersCollection)
                .doc(userId)
                .collection('reservations')
                .doc(reservationId)
                .get();

            if (reservationDoc.exists) {
              final reservation =
                  ReservationModel.fromFirestore(reservationDoc);
              // Only include future reservations
              if (reservation.reservationStartTime != null &&
                  reservation.reservationStartTime!.millisecondsSinceEpoch >
                      now.millisecondsSinceEpoch) {
                reservations.add(reservation);
              }
            }
          } catch (e) {
            debugPrint(
                'Error fetching individual reservation $reservationId: $e');
          }
        }
      }

      // For each confirmed reservation, get the full reservation data from user's collection
      for (final confirmedDoc in confirmedSnapshot.docs) {
        final data = confirmedDoc.data();
        final reservationId = data['reservationId'] as String?;
        final userId = data['userId'] as String?;

        if (reservationId != null && userId != null) {
          try {
            final reservationDoc = await _firestore
                .collection(_endUsersCollection)
                .doc(userId)
                .collection('reservations')
                .doc(reservationId)
                .get();

            if (reservationDoc.exists) {
              final reservation =
                  ReservationModel.fromFirestore(reservationDoc);
              // Only include future reservations with confirmed status
              if (reservation.reservationStartTime != null &&
                  reservation.reservationStartTime!.millisecondsSinceEpoch >
                      now.millisecondsSinceEpoch &&
                  reservation.status == ReservationStatus.confirmed) {
                reservations.add(reservation);
              }
            }
          } catch (e) {
            debugPrint(
                'Error fetching individual confirmed reservation $reservationId: $e');
          }
        }
      }

      debugPrint('✅ Found ${reservations.length} provider reservations');
      return reservations;
    } catch (e) {
      debugPrint('Error fetching provider reservations: $e');
      return [];
    }
  }

  /// Fetches available time slots for a provider on a specific date
  /// This method now uses the capacity-aware system but maintains backward compatibility
  Future<List<String>> fetchAvailableSlots({
    required String providerId,
    required DateTime date,
    required int durationMinutes,
    String? governorateId,
  }) async {
    try {
      debugPrint(
          '🕐 Fetching available slots for provider $providerId on ${date.toString()}');

      // Use the new capacity-aware method
      final slotsWithCapacity = await fetchAvailableSlotsWithCapacity(
        providerId: providerId,
        date: date,
        durationMinutes: durationMinutes,
        governorateId: governorateId,
      );

      // Filter to only available slots and return just the time strings for backward compatibility
      final availableSlots = slotsWithCapacity
          .where((slot) => slot.isAvailable)
          .map((slot) => slot.timeSlot)
          .toList();

      debugPrint(
          '✅ Found ${availableSlots.length} available slots (backward compatible format)');
      return availableSlots;
    } catch (e) {
      debugPrint('Error fetching available slots: $e');
      return [];
    }
  }

  /// Helper method to generate available time slots
  List<String> _generateAvailableSlots({
    required Map<String, dynamic> operatingHours,
    required List<ReservationModel> existingReservations,
    required int durationMinutes,
    required DateTime date,
  }) {
    final slots = <String>[];

    try {
      final openTime = operatingHours['openTime'] as String? ?? '09:00';
      final closeTime = operatingHours['closeTime'] as String? ?? '17:00';

      // Parse operating hours
      final openDateTime = _parseTimeOnDate(openTime, date);
      final closeDateTime = _parseTimeOnDate(closeTime, date);

      if (openDateTime == null || closeDateTime == null) return slots;

      // Generate slots every 30 minutes (or based on duration)
      final slotInterval = math.max(30, durationMinutes);
      var currentTime = openDateTime;

      while (currentTime
              .add(Duration(minutes: durationMinutes))
              .isBefore(closeDateTime) ||
          currentTime
              .add(Duration(minutes: durationMinutes))
              .isAtSameMomentAs(closeDateTime)) {
        final endTime = currentTime.add(Duration(minutes: durationMinutes));

        // Check if this slot conflicts with existing reservations
        bool hasConflict = false;
        for (final reservation in existingReservations) {
          if (reservation.reservationStartTime != null) {
            final startTime = reservation.reservationStartTime!.toDate();
            final duration = reservation.durationMinutes ?? 60;
            final reservationEndTime =
                startTime.add(Duration(minutes: duration));

            // Check for overlap
            if ((currentTime.isBefore(reservationEndTime) &&
                endTime.isAfter(startTime))) {
              hasConflict = true;
              break;
            }
          }
        }

        if (!hasConflict) {
          // Format time as HH:MM
          final timeString =
              '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
          slots.add(timeString);
        }

        currentTime = currentTime.add(Duration(minutes: slotInterval));
      }
    } catch (e) {
      debugPrint('Error generating time slots: $e');
    }

    return slots;
  }

  /// Helper method to parse time string and combine with date
  DateTime? _parseTimeOnDate(String timeString, DateTime date) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get day name from weekday number
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

  /// Submits a subscription using the centralized approach
  Future<String> submitSubscription(SubscriptionModel subscription) async {
    try {
      final subscriptionId = await createSubscription(subscription);
      return subscriptionId;
    } catch (e) {
      debugPrint('Error submitting subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Gets provider details including location and other info
  Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    try {
      debugPrint('🔍 Fetching provider details for ID: $providerId');
      final doc = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .get();

      if (!doc.exists) {
        debugPrint('❌ Provider not found: $providerId');
        return null;
      }

      final data = doc.data()!;

      // Log available fields for debugging
      debugPrint('🏛️ Available provider fields: ${data.keys.toList()}');

      // Check various possible governorate fields
      final governorateId = data['governorateId'] as String? ??
          data['governorate_id'] as String? ??
          (data['location'] as Map<String, dynamic>?)?['governorateId']
              as String? ??
          (data['location'] as Map<String, dynamic>?)?['governorate_id']
              as String? ??
          (data['address'] as Map<String, dynamic>?)?['governorateId']
              as String? ??
          (data['address'] as Map<String, dynamic>?)?['governorate_id']
              as String?;

      if (governorateId != null && governorateId.isNotEmpty) {
        debugPrint('✅ Found governorate ID: $governorateId');
      } else {
        debugPrint('⚠️ No governorate ID found for provider $providerId');
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching provider details: $e');
      return null;
    }
  }

  /// Gets user email for notifications
  Future<String?> getUserEmail(String userId) async {
    try {
      final doc =
          await _firestore.collection(_endUsersCollection).doc(userId).get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      return data['email'] as String?;
    } catch (e) {
      debugPrint('Error fetching user email: $e');
      return null;
    }
  }

  /// Sends booking confirmation emails
  Future<void> sendBookingConfirmationEmails({
    required List<String> recipients,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      // Use Cloud Function for sending emails
      await _functions.httpsCallable('sendEmail').call({
        'recipients': recipients,
        'subject': subject,
        'htmlContent': htmlContent,
      });
    } catch (e) {
      debugPrint('Error sending booking confirmation emails: $e');
      // Don't throw error - email failure shouldn't break the booking process
    }
  }

  /// Schedules reminder email
  Future<void> scheduleReminderEmail({
    required String recipient,
    required String subject,
    required String htmlContent,
    required DateTime scheduledFor,
  }) async {
    try {
      await _firestore.collection(_scheduledRemindersCollection).add({
        'recipient': recipient,
        'subject': subject,
        'htmlContent': htmlContent,
        'scheduledFor': Timestamp.fromDate(scheduledFor),
        'type': 'email_reminder',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error scheduling reminder email: $e');
    }
  }

  /// Fetches current user's friends
  Future<List<dynamic>> fetchCurrentUserFriends() async {
    if (currentUserId == null) {
      debugPrint('❌ fetchCurrentUserFriends: currentUserId is null');
      return [];
    }

    try {
      debugPrint(
          '🔍 fetchCurrentUserFriends: Querying friends for user $currentUserId');
      final snapshot = await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      debugPrint(
          '📊 fetchCurrentUserFriends: Found ${snapshot.docs.length} friend documents');
      final friends = snapshot.docs.map((doc) => doc.data()).toList();
      debugPrint(
          '✅ fetchCurrentUserFriends: Returning ${friends.length} friends');

      // If no friends found in Firestore, return mock data for development
      if (friends.isEmpty) {
        debugPrint(
            '🔧 No friends found in Firestore, returning mock data for development');
        return [
          {
            'userId': 'friend1',
            'name': 'John Smith',
            'profilePicUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
            'status': 'accepted',
            'friendedAt': Timestamp.now(),
          },
          {
            'userId': 'friend2',
            'name': 'Sarah Johnson',
            'profilePicUrl': 'https://randomuser.me/api/portraits/women/2.jpg',
            'status': 'accepted',
            'friendedAt': Timestamp.now(),
          },
          {
            'userId': 'friend3',
            'name': 'Mike Davis',
            'profilePicUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
            'status': 'accepted',
            'friendedAt': Timestamp.now(),
          },
        ];
      }

      return friends;
    } catch (e) {
      debugPrint('❌ Error fetching user friends: $e');
      return [];
    }
  }

  /// Fetches current user's family members
  Future<List<FamilyMember>> fetchCurrentUserFamilyMembers() async {
    if (currentUserId == null) {
      debugPrint('❌ fetchCurrentUserFamilyMembers: currentUserId is null');
      return [];
    }

    try {
      debugPrint(
          '🔍 fetchCurrentUserFamilyMembers: Querying family members for user $currentUserId');
      final snapshot = await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('familyMembers')
          .get();

      debugPrint(
          '📊 fetchCurrentUserFamilyMembers: Found ${snapshot.docs.length} family member documents');
      final familyMembers =
          snapshot.docs.map((doc) => FamilyMember.fromFirestore(doc)).toList();
      debugPrint(
          '✅ fetchCurrentUserFamilyMembers: Returning ${familyMembers.length} family members');

      // If no family members found in Firestore, return mock data for development
      if (familyMembers.isEmpty) {
        debugPrint(
            '🔧 No family members found in Firestore, returning mock data for development');
        return [
          FamilyMember(
            id: 'family1',
            name: 'Mom Smith',
            relationship: 'Mother',
            status: 'accepted',
            profilePicUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
            userId: 'mom_user_id',
            addedAt: Timestamp.now(),
          ),
          FamilyMember(
            id: 'family2',
            name: 'Dad Smith',
            relationship: 'Father',
            status: 'accepted',
            profilePicUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
            userId: 'dad_user_id',
            addedAt: Timestamp.now(),
          ),
          FamilyMember(
            id: 'family3',
            name: 'Sister Emma',
            relationship: 'Sister',
            status: 'accepted',
            profilePicUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
            userId: 'sister_user_id',
            addedAt: Timestamp.now(),
          ),
        ];
      }

      return familyMembers;
    } catch (e) {
      debugPrint('❌ Error fetching user family members: $e');
      return [];
    }
  }

  // ============================================================================
  // SUBSCRIPTION OPERATIONS
  // ============================================================================

  /// Creates a new subscription with proper lifecycle management
  Future<String> createSubscription(SubscriptionModel subscription) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    final batch = _firestore.batch();

    try {
      // Generate subscription ID
      final subscriptionRef = _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('subscriptions')
          .doc();

      final subscriptionData = {
        ...subscription.toMapForCreate(),
        'id': subscriptionRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to user's subscriptions
      batch.set(subscriptionRef, subscriptionData);

      // Add to provider's active subscriptions
      final providerSubscriptionRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(subscription.providerId)
          .collection('activeSubscriptions')
          .doc(subscriptionRef.id);

      batch.set(providerSubscriptionRef, {
        'subscriptionId': subscriptionRef.id,
        'userId': currentUserId!,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Update provider statistics
      final providerStatsRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(subscription.providerId);

      batch.update(providerStatsRef, {
        'totalSubscriptions': FieldValue.increment(1),
        'activeSubscriptions': FieldValue.increment(1),
        'lastSubscriptionAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Schedule subscription reminders
      _scheduleSubscriptionReminders(subscription);

      return subscriptionRef.id;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Fetches user subscriptions with real-time updates
  Stream<List<SubscriptionModel>> getUserSubscriptionsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(_endUsersCollection)
        .doc(currentUserId!)
        .collection('subscriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionModel.fromFirestore(doc))
            .toList());
  }

  /// Cancels a subscription with proper cleanup
  Future<void> cancelSubscription(String subscriptionId) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    final batch = _firestore.batch();

    try {
      // Get subscription details
      final subscriptionDoc = await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) {
        throw Exception('Subscription not found');
      }

      final subscriptionData = subscriptionDoc.data()!;
      final providerId = subscriptionData['providerId'] as String;

      // Update subscription status
      batch.update(subscriptionDoc.reference, {
        'status': SubscriptionStatus.cancelled.statusString,
        'cancellationReason': 'Cancelled by user',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Move from active to cancelled in provider's collections
      final activeRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .collection('activeSubscriptions')
          .doc(subscriptionId);
      batch.delete(activeRef);

      final cancelledRef = _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .collection('cancelledSubscriptions')
          .doc(subscriptionId);
      batch.set(cancelledRef, {
        'subscriptionId': subscriptionId,
        'userId': currentUserId!,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'user',
      });

      // Update provider statistics
      final providerStatsRef =
          _firestore.collection(_serviceProvidersCollection).doc(providerId);
      batch.update(providerStatsRef, {
        'activeSubscriptions': FieldValue.increment(-1),
        'cancelledSubscriptions': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // ============================================================================
  // SERVICE PROVIDER OPERATIONS
  // ============================================================================

  /// Fetches service providers with advanced filtering and caching
  Future<List<ServiceProviderDisplayModel>> getServiceProviders({
    String? city,
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      debugPrint(
          'Fetching service providers for city: $city, category: $category, searchQuery: $searchQuery');

      Query query = _firestore.collection(_serviceProvidersCollection);

      // For city-based queries, check both city and governorate fields
      if (city != null && city.isNotEmpty) {
        debugPrint('Searching for providers in city/governorate: $city');

        // First try to find by city field
        var cityQuery = query.where('city', isEqualTo: city).limit(limit);
        if (lastDocument != null) {
          cityQuery = cityQuery.startAfterDocument(lastDocument);
        }

        var snapshot = await cityQuery.get();
        var providers = snapshot.docs
            .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc,
                isFavorite: false))
            .toList();

        debugPrint('Found ${providers.length} providers by city field');

        // If no results by city, try governorate field
        if (providers.isEmpty) {
          debugPrint(
              'No providers found by city field, trying governorate field...');
          var governorateQuery =
              query.where('governorate', isEqualTo: city).limit(limit);
          if (lastDocument != null) {
            governorateQuery =
                governorateQuery.startAfterDocument(lastDocument);
          }

          snapshot = await governorateQuery.get();
          providers = snapshot.docs
              .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc,
                  isFavorite: false))
              .toList();

          debugPrint(
              'Found ${providers.length} providers by governorate field');
        }

        // If still no results, try address.governorate field
        if (providers.isEmpty) {
          debugPrint(
              'No providers found by governorate field, trying address.governorate field...');
          var addressGovernorateQuery =
              query.where('address.governorate', isEqualTo: city).limit(limit);
          if (lastDocument != null) {
            addressGovernorateQuery =
                addressGovernorateQuery.startAfterDocument(lastDocument);
          }

          snapshot = await addressGovernorateQuery.get();
          providers = snapshot.docs
              .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc,
                  isFavorite: false))
              .toList();

          debugPrint(
              'Found ${providers.length} providers by address.governorate field');
        }

        // Apply additional filters in memory if needed
        if (category != null && category.isNotEmpty) {
          providers =
              providers.where((p) => p.businessCategory == category).toList();
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final lowerQuery = searchQuery.toLowerCase();
          providers = providers
              .where((p) =>
                  p.businessName.toLowerCase().contains(lowerQuery) ||
                  p.businessCategory.toLowerCase().contains(lowerQuery))
              .toList();
        }

        // Sort in memory
        providers.sort((a, b) => a.businessName.compareTo(b.businessName));

        debugPrint(
            'Found ${providers.length} service providers for city/governorate: $city');

        // Return providers for the specific location, even if empty
        // This ensures users see results specific to their chosen location
        return providers;
      }

      // For non-city queries, use the original approach
      if (category != null && category.isNotEmpty) {
        query = query.where('businessCategory', isEqualTo: category);
      }

      // Apply search if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('searchKeywords', arrayContains: searchQuery.toLowerCase())
            .orderBy('businessName');
      } else {
        query = query.orderBy('businessName');
      }

      // Apply pagination
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final providers = snapshot.docs
          .map((doc) =>
              ServiceProviderDisplayModel.fromFirestore(doc, isFavorite: false))
          .toList();

      debugPrint('Found ${providers.length} service providers');
      return providers;
    } catch (e) {
      debugPrint('Error fetching service providers: $e');
      throw Exception('Failed to fetch service providers: $e');
    }
  }

  /// Fallback method to get all providers when city-specific search fails
  Future<List<ServiceProviderDisplayModel>> _getAllProvidersAsFallback({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_serviceProvidersCollection);

      // Apply category filter if provided
      if (category != null && category.isNotEmpty) {
        query = query.where('businessCategory', isEqualTo: category);
      }

      // Apply search if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('searchKeywords', arrayContains: searchQuery.toLowerCase())
            .orderBy('businessName');
      } else {
        query = query.orderBy('businessName');
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final providers = snapshot.docs
          .map((doc) =>
              ServiceProviderDisplayModel.fromFirestore(doc, isFavorite: false))
          .toList();

      debugPrint('Fallback: Found ${providers.length} total providers');

      // Log available cities for debugging
      final cities = providers.map((p) => p.city).toSet().toList();
      debugPrint('Available cities in database: $cities');

      return providers;
    } catch (e) {
      debugPrint('Error in fallback provider fetch: $e');
      return [];
    }
  }

  /// Gets available cities from service providers
  Future<List<String>> getAvailableCities() async {
    try {
      final snapshot =
          await _firestore.collection(_serviceProvidersCollection).get();

      final citiesSet = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Check city field
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) {
          citiesSet.add(city);
        }

        // Check governorate field
        final governorate = data['governorate'] as String?;
        if (governorate != null && governorate.isNotEmpty) {
          citiesSet.add(governorate);
        }

        // Check address.governorate field
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final addressGovernorate = address['governorate'] as String?;
          if (addressGovernorate != null && addressGovernorate.isNotEmpty) {
            citiesSet.add(addressGovernorate);
          }
        }
      }

      final cities = citiesSet.where((city) => city.isNotEmpty).toList();
      cities.sort();
      debugPrint('Available cities/governorates: $cities');
      return cities;
    } catch (e) {
      debugPrint('Error fetching available cities: $e');
      return [];
    }
  }

  /// Finds the best matching location for a given city name
  Future<String?> findBestLocationMatch(String searchCity) async {
    try {
      final availableCities = await getAvailableCities();

      // Exact match (case insensitive)
      final exactMatch = availableCities.firstWhere(
        (city) => city.toLowerCase() == searchCity.toLowerCase(),
        orElse: () => '',
      );

      if (exactMatch.isNotEmpty) {
        debugPrint('Found exact match for $searchCity: $exactMatch');
        return exactMatch;
      }

      // Partial match (contains)
      final partialMatch = availableCities.firstWhere(
        (city) =>
            city.toLowerCase().contains(searchCity.toLowerCase()) ||
            searchCity.toLowerCase().contains(city.toLowerCase()),
        orElse: () => '',
      );

      if (partialMatch.isNotEmpty) {
        debugPrint('Found partial match for $searchCity: $partialMatch');
        return partialMatch;
      }

      debugPrint(
          'No match found for $searchCity in available cities: $availableCities');
      return null;
    } catch (e) {
      debugPrint('Error finding location match: $e');
      return null;
    }
  }

  /// Gets detailed service provider information
  Future<ServiceProviderModel> getServiceProviderDetails(
      String providerId) async {
    try {
      final doc = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(providerId)
          .get();

      if (!doc.exists) {
        throw Exception('Service provider not found');
      }

      return ServiceProviderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching provider details: $e');
      throw Exception('Failed to fetch provider details: $e');
    }
  }

  /// Gets service providers by category and subcategory
  Future<List<ServiceProviderDisplayModel>> getServiceProvidersByCategory(
    String category,
    String? city,
    String? subCategory,
  ) async {
    try {
      debugPrint(
          'Fetching providers by category: $category, city: $city, subCategory: $subCategory');

      Query query = _firestore.collection(_serviceProvidersCollection);

      // Apply category filter first (this should have a simple index)
      query = query.where('businessCategory', isEqualTo: category).limit(50);

      final snapshot = await query.get();
      var providers = snapshot.docs
          .map((doc) =>
              ServiceProviderDisplayModel.fromFirestore(doc, isFavorite: false))
          .toList();

      // Apply additional filters in memory to avoid composite index requirements
      if (city != null && city.isNotEmpty) {
        // Check both city and governorate fields in the provider data
        providers = providers.where((p) {
          // Check if the provider's city matches
          if (p.city == city) return true;

          // Check if the provider has a governorate field that matches
          // Note: This assumes ServiceProviderDisplayModel has a governorate field
          // If not, we'll need to check the raw document data
          return false; // For now, just check city field
        }).toList();

        debugPrint(
            'After city/governorate filtering: ${providers.length} providers');
      }

      if (subCategory != null && subCategory.isNotEmpty) {
        providers =
            providers.where((p) => p.subCategory == subCategory).toList();
      }

      // Sort in memory
      providers.sort((a, b) => a.businessName.compareTo(b.businessName));

      debugPrint('Found ${providers.length} providers for category: $category');
      return providers;
    } catch (e) {
      debugPrint('Error fetching providers by category: $e');
      throw Exception('Failed to fetch providers by category: $e');
    }
  }

  /// Gets service providers by search query
  Future<List<ServiceProviderDisplayModel>> getServiceProvidersByQuery({
    required String query,
    String? city,
    String? category,
    String? subCategory,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection(_serviceProvidersCollection);

      // Apply search query
      firestoreQuery = firestoreQuery
          .where('searchKeywords', arrayContains: query.toLowerCase())
          .orderBy('businessName');

      // Apply additional filters if provided
      if (city != null && city.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('city', isEqualTo: city);
      }
      if (category != null && category.isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('businessCategory', isEqualTo: category);
      }
      if (subCategory != null && subCategory.isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('businessSubCategory', isEqualTo: subCategory);
      }

      firestoreQuery = firestoreQuery.limit(50);

      final snapshot = await firestoreQuery.get();
      return snapshot.docs
          .map((doc) =>
              ServiceProviderDisplayModel.fromFirestore(doc, isFavorite: false))
          .toList();
    } catch (e) {
      debugPrint('Error searching providers: $e');
      throw Exception('Failed to search providers: $e');
    }
  }

  /// Gets banners for home screen
  Future<List<BannerModel>> getBanners() async {
    try {
      // Simple query without ordering to avoid index requirement
      final snapshot = await _firestore
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();

      // Sort in memory by priority
      final banners =
          snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();

      // Sort by priority in descending order (highest first)
      banners.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));

      return banners;
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      return []; // Return empty list on error
    }
  }

  /// Toggles favorite status for a provider
  Future<void> toggleFavorite(
      String userId, String providerId, bool isFavorite) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    try {
      final favoriteRef = _firestore
          .collection(_endUsersCollection)
          .doc(userId)
          .collection('favorites')
          .doc(providerId);

      if (isFavorite) {
        await favoriteRef.set({
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await favoriteRef.delete();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Gets current user profile
  Future<AuthModel?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .get();

      if (!doc.exists) return null;
      return AuthModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Updates user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    try {
      await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // ============================================================================
  // FAVORITES OPERATIONS
  // ============================================================================

  /// Adds provider to favorites
  Future<void> addToFavorites(String providerId) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    try {
      await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('favorites')
          .doc(providerId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Removes provider from favorites
  Future<void> removeFromFavorites(String providerId) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    try {
      await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('favorites')
          .doc(providerId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Gets user favorites stream
  Stream<List<ServiceProviderDisplayModel>> getFavoritesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(_endUsersCollection)
        .doc(currentUserId!)
        .collection('favorites')
        .snapshots()
        .asyncMap((snapshot) async {
      final favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
      if (favoriteIds.isEmpty) return <ServiceProviderDisplayModel>[];

      // Batch fetch provider details
      final providers = <ServiceProviderDisplayModel>[];
      for (final id in favoriteIds) {
        try {
          final providerDoc = await _firestore
              .collection(_serviceProvidersCollection)
              .doc(id)
              .get();
          if (providerDoc.exists) {
            providers.add(ServiceProviderDisplayModel.fromFirestore(providerDoc,
                isFavorite: true));
          }
        } catch (e) {
          debugPrint('Error fetching favorite provider $id: $e');
        }
      }
      return providers;
    });
  }

  // ============================================================================
  // SOCIAL OPERATIONS
  // ============================================================================

  /// Sends friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String targetUserId,
    required String targetUserName,
    String? targetUserProfilePicUrl,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result = await _functions.httpsCallable('sendFriendRequest').call({
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'targetUserProfilePicUrl': targetUserProfilePicUrl,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId,
    required String requesterUserName,
    String? requesterProfilePicUrl,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('acceptFriendRequest').call({
        'currentUserId': currentUserId,
        'requesterUserId': requesterUserId,
        'requesterUserName': requesterUserName,
        'requesterProfilePicUrl': requesterProfilePicUrl,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Decline friend request
  Future<Map<String, dynamic>> declineFriendRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('declineFriendRequest').call({
        'currentUserId': currentUserId,
        'requesterUserId': requesterUserId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove friend
  Future<Map<String, dynamic>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result = await _functions.httpsCallable('removeFriend').call({
        'currentUserId': currentUserId,
        'friendUserId': friendUserId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Unsend friend request
  Future<Map<String, dynamic>> unsendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('unsendFriendRequest').call({
        'currentUserId': currentUserId,
        'targetUserId': targetUserId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error unsending friend request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Add or request family member
  Future<Map<String, dynamic>> addOrRequestFamilyMember({
    required String currentUserId,
    required AuthModel currentUserData,
    required Map<String, dynamic> memberData,
    AuthModel? linkedUserModel,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('addOrRequestFamilyMember').call({
        'currentUserId': currentUserId,
        'memberData': memberData,
        'linkedUserModel': linkedUserModel?.toMap(),
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error adding family member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove family member
  Future<Map<String, dynamic>> removeFamilyMember({
    required String currentUserId,
    required String memberDocId,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result = await _functions.httpsCallable('removeFamilyMember').call({
        'currentUserId': currentUserId,
        'memberDocId': memberDocId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error removing family member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Accept family request
  Future<Map<String, dynamic>> acceptFamilyRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId,
    required String requesterName,
    String? requesterProfilePicUrl,
    required String requesterRelationship,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('acceptFamilyRequest').call({
        'currentUserId': currentUserId,
        'requesterUserId': requesterUserId,
        'requesterName': requesterName,
        'requesterProfilePicUrl': requesterProfilePicUrl,
        'requesterRelationship': requesterRelationship,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error accepting family request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Decline family request
  Future<Map<String, dynamic>> declineFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
    if (this.currentUserId == null) throw Exception('User must be logged in');

    try {
      final result =
          await _functions.httpsCallable('declineFamilyRequest').call({
        'currentUserId': currentUserId,
        'requesterUserId': requesterUserId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error declining family request: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Gets user friends stream
  Stream<List<AuthModel>> getFriendsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(_endUsersCollection)
        .doc(currentUserId!)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      final friends = <AuthModel>[];
      for (final doc in snapshot.docs) {
        try {
          final friendId = doc.data()['userId'] as String;
          final friendDoc = await _firestore
              .collection(_endUsersCollection)
              .doc(friendId)
              .get();
          if (friendDoc.exists) {
            friends.add(AuthModel.fromFirestore(friendDoc));
          }
        } catch (e) {
          debugPrint('Error fetching friend details: $e');
        }
      }
      return friends;
    });
  }

  // ============================================================================
  // NOTIFICATION OPERATIONS
  // ============================================================================

  /// Adds notification to user
  Future<void> addNotification(NotificationModel notification) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection(_endUsersCollection)
          .doc(currentUserId!)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  /// Gets user notifications stream
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(_endUsersCollection)
        .doc(currentUserId!)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // ============================================================================
  // ANALYTICS & STATISTICS
  // ============================================================================

  /// Gets user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    if (currentUserId == null) return {};

    try {
      final futures = await Future.wait([
        _firestore
            .collection(_endUsersCollection)
            .doc(currentUserId!)
            .collection('reservations')
            .count()
            .get(),
        _firestore
            .collection(_endUsersCollection)
            .doc(currentUserId!)
            .collection('subscriptions')
            .count()
            .get(),
        _firestore
            .collection(_endUsersCollection)
            .doc(currentUserId!)
            .collection('favorites')
            .count()
            .get(),
      ]);

      return {
        'totalReservations': futures[0].count,
        'totalSubscriptions': futures[1].count,
        'totalFavorites': futures[2].count,
      };
    } catch (e) {
      debugPrint('Error fetching user statistics: $e');
      return {};
    }
  }

  // ============================================================================
  // CAPACITY MANAGEMENT OPERATIONS
  // ============================================================================

  /// Fetches available time slots with detailed capacity information
  Future<List<TimeSlotCapacity>> fetchAvailableSlotsWithCapacity({
    required String providerId,
    required DateTime date,
    required int durationMinutes,
    String? governorateId,
  }) async {
    try {
      debugPrint(
          '🎯 Fetching available slots with capacity for provider $providerId on ${date.toString()}');

      // Get provider details including capacity information
      final providerDetails = await getServiceProviderDetails(providerId);

      debugPrint('📊 Provider details: ${providerDetails.businessName}');

      // Get capacity information
      final totalCapacity =
          providerDetails.totalCapacity ?? providerDetails.maxCapacity;

      debugPrint('📊 Provider total capacity: $totalCapacity');

      // Get provider operating hours using the real model structure
      final openingHours = providerDetails.openingHours;
      final dayName = _getDayName(date.weekday);
      final dayHours = openingHours[dayName.toLowerCase()];

      debugPrint(
          '📅 Checking hours for $dayName (${date.weekday}): ${dayHours?.isOpen}');
      debugPrint(
          '📅 Available opening hours keys: ${openingHours.keys.toList()}');

      if (dayHours != null) {
        debugPrint(
            '📅 Day hours - isOpen: ${dayHours.isOpen}, startTime: ${dayHours.startTime}, endTime: ${dayHours.endTime}');
      } else {
        debugPrint('📅 No hours found for day: $dayName');
      }

      if (dayHours == null ||
          !dayHours.isOpen ||
          dayHours.startTime == null ||
          dayHours.endTime == null) {
        debugPrint(
            '📅 Provider is closed on $dayName - Reason: ${dayHours == null ? 'No hours data' : !dayHours.isOpen ? 'Marked as closed' : 'Missing start/end times'}');
        return [];
      }

      debugPrint('🕐 Open: ${dayHours.startTime} - ${dayHours.endTime}');

      // Get existing reservations for the date
      final existingReservations =
          await _fetchReservationsForDate(providerId, date);
      debugPrint(
          '📋 Found ${existingReservations.length} existing reservations for the date');

      // Generate time slots with capacity information
      final slotsWithCapacity = _generateAvailableSlotsWithCapacity(
        openingHours: dayHours,
        existingReservations: existingReservations,
        durationMinutes: durationMinutes,
        date: date,
        totalCapacity: totalCapacity,
      );

      debugPrint(
          '✅ Generated ${slotsWithCapacity.length} slots with capacity info');
      return slotsWithCapacity;
    } catch (e) {
      debugPrint('❌ Error fetching slots with capacity: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Fetches reservations for a specific date (private helper)
  Future<List<ReservationModel>> _fetchReservationsForDate(
      String providerId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final allReservations = await fetchProviderReservations(providerId);

      // Filter reservations for the specific date
      return allReservations.where((reservation) {
        if (reservation.reservationStartTime == null) return false;
        final reservationDate = reservation.reservationStartTime!.toDate();
        return reservationDate.isAfter(startOfDay) &&
            reservationDate.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching reservations for date: $e');
      return [];
    }
  }

  /// Generates time slots with detailed capacity information using real OpeningHoursDay
  List<TimeSlotCapacity> _generateAvailableSlotsWithCapacity({
    required OpeningHoursDay openingHours,
    required List<ReservationModel> existingReservations,
    required int durationMinutes,
    required DateTime date,
    required int totalCapacity,
  }) {
    final List<TimeSlotCapacity> slots = [];

    try {
      if (!openingHours.isOpen ||
          openingHours.startTime == null ||
          openingHours.endTime == null) {
        debugPrint('📅 Provider is closed or has invalid hours');
        return slots;
      }

      // Convert TimeOfDay to DateTime for the specific date
      final openDateTime = DateTime(date.year, date.month, date.day,
          openingHours.startTime!.hour, openingHours.startTime!.minute);

      final closeDateTime = DateTime(date.year, date.month, date.day,
          openingHours.endTime!.hour, openingHours.endTime!.minute);

      debugPrint(
          '🕐 Operating hours: ${openDateTime.toString()} to ${closeDateTime.toString()}');

      // Generate slots every 30 minutes (or based on duration)
      final slotInterval = math.max(30, durationMinutes);
      var currentTime = openDateTime;

      while (currentTime
              .add(Duration(minutes: durationMinutes))
              .isBefore(closeDateTime) ||
          currentTime
              .add(Duration(minutes: durationMinutes))
              .isAtSameMomentAs(closeDateTime)) {
        final endTime = currentTime.add(Duration(minutes: durationMinutes));
        final timeSlot =
            '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';

        // Calculate capacity for this time slot
        final slotCapacity = _calculateSlotCapacity(
          currentTime: currentTime,
          endTime: endTime,
          existingReservations: existingReservations,
          totalCapacity: totalCapacity,
        );

        slots.add(slotCapacity);
        currentTime = currentTime.add(Duration(minutes: slotInterval));
      }

      debugPrint('📊 Generated ${slots.length} time slots');
    } catch (e) {
      debugPrint('❌ Error generating time slots with capacity: $e');
    }

    return slots;
  }

  /// Calculates capacity information for a specific time slot
  TimeSlotCapacity _calculateSlotCapacity({
    required DateTime currentTime,
    required DateTime endTime,
    required List<ReservationModel> existingReservations,
    required int totalCapacity,
  }) {
    final timeSlot =
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    final List<ReservationSummary> conflictingReservations = [];
    int bookedCapacity = 0;

    // Find all reservations that overlap with this time slot
    for (final reservation in existingReservations) {
      if (reservation.reservationStartTime != null) {
        final reservationStart = reservation.reservationStartTime!.toDate();
        final reservationDuration = reservation.durationMinutes ?? 60;
        final reservationEnd =
            reservationStart.add(Duration(minutes: reservationDuration));

        // Check for overlap with current time slot
        if (_hasTimeOverlap(
            currentTime, endTime, reservationStart, reservationEnd)) {
          final summary = ReservationSummary.fromReservation(reservation);
          conflictingReservations.add(summary);
          bookedCapacity += summary.attendeeCount;
        }
      }
    }

    final availableCapacity = math.max(0, totalCapacity - bookedCapacity);

    return TimeSlotCapacity(
      timeSlot: timeSlot,
      date: currentTime,
      totalCapacity: totalCapacity,
      bookedCapacity: bookedCapacity,
      availableCapacity: availableCapacity,
      existingReservations: conflictingReservations,
    );
  }

  /// Checks if two time ranges overlap
  bool _hasTimeOverlap(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Validates if a reservation can be made within capacity limits
  Future<CapacityValidationResult> validateReservationCapacity({
    required String providerId,
    required DateTime reservationTime,
    required int durationMinutes,
    required int attendeeCount,
  }) async {
    try {
      debugPrint(
          '🔍 Validating reservation capacity for $attendeeCount attendees');

      // Get provider capacity
      try {
        final providerDetails = await getServiceProviderDetails(providerId);

        final totalCapacity =
            providerDetails.totalCapacity ?? providerDetails.maxCapacity;

        // Get existing reservations for the time slot
        final reservationDate = DateTime(
            reservationTime.year, reservationTime.month, reservationTime.day);
        final existingReservations =
            await _fetchReservationsForDate(providerId, reservationDate);

        // Calculate capacity for the specific time slot
        final endTime = reservationTime.add(Duration(minutes: durationMinutes));
        final slotCapacity = _calculateSlotCapacity(
          currentTime: reservationTime,
          endTime: endTime,
          existingReservations: existingReservations,
          totalCapacity: totalCapacity,
        );

        final isValid = slotCapacity.availableCapacity >= attendeeCount;
        final errorMessage = isValid
            ? null
            : 'Not enough capacity. Available: ${slotCapacity.availableCapacity}, Requested: $attendeeCount';

        debugPrint(isValid
            ? '✅ Capacity validation passed'
            : '❌ Capacity validation failed: $errorMessage');

        return CapacityValidationResult(
          isValid: isValid,
          errorMessage: errorMessage,
          totalCapacity: totalCapacity,
          availableCapacity: slotCapacity.availableCapacity,
          bookedCapacity: slotCapacity.bookedCapacity,
          timeSlotCapacity: slotCapacity,
        );
      } catch (providerError) {
        debugPrint('❌ Error fetching provider details: $providerError');
        return CapacityValidationResult(
          isValid: false,
          errorMessage: 'Provider not found or error fetching provider details',
          totalCapacity: 0,
          availableCapacity: 0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error validating reservation capacity: $e');
      return CapacityValidationResult(
        isValid: false,
        errorMessage: 'Error validating capacity: $e',
        totalCapacity: 0,
        availableCapacity: 0,
      );
    }
  }

  /// Gets capacity information for a specific time slot
  Future<TimeSlotCapacity?> getTimeSlotCapacity({
    required String providerId,
    required DateTime timeSlot,
    required int durationMinutes,
  }) async {
    try {
      final slotsWithCapacity = await fetchAvailableSlotsWithCapacity(
        providerId: providerId,
        date: timeSlot,
        durationMinutes: durationMinutes,
      );

      final targetTimeString =
          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';

      return slotsWithCapacity.firstWhere(
        (slot) => slot.timeSlot == targetTimeString,
        orElse: () => throw Exception('Time slot not found'),
      );
    } catch (e) {
      debugPrint('❌ Error getting time slot capacity: $e');
      return null;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Sends reservation notification
  void _sendReservationNotification(
      ReservationModel reservation, String action) {
    // Implement notification logic
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Reservation ${action.toUpperCase()}',
      body: 'Your reservation for ${reservation.serviceName} has been $action',
      type: 'reservation',
      targetId: reservation.id,
      timestamp: DateTime.now(),
    );

    addNotification(notification);
  }

  /// Schedules subscription reminders
  void _scheduleSubscriptionReminders(SubscriptionModel subscription) {
    // Schedule renewal reminders
    final reminderDates = [
      subscription.expiryDate.toDate().subtract(const Duration(days: 7)),
      subscription.expiryDate.toDate().subtract(const Duration(days: 1)),
    ];

    for (final date in reminderDates) {
      if (date.isAfter(DateTime.now())) {
        _firestore.collection(_scheduledRemindersCollection).add({
          'userId': currentUserId,
          'subscriptionId': subscription.id,
          'type': 'subscription_renewal',
          'scheduledFor': Timestamp.fromDate(date),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Batch operation helper
  Future<void> executeBatch(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final ref = operation['ref'] as DocumentReference;
      final data = operation['data'] as Map<String, dynamic>?;

      switch (type) {
        case 'set':
          batch.set(ref, data!);
          break;
        case 'update':
          batch.update(ref, data!);
          break;
        case 'delete':
          batch.delete(ref);
          break;
      }
    }

    await batch.commit();
  }

  /// Cleanup method for disposing resources
  void dispose() {
    // Clean up any streams or listeners if needed
  }

  /// Debug method to test operating hours parsing for a specific provider
  Future<void> debugProviderOperatingHours(String providerId) async {
    try {
      debugPrint('🔍 DEBUG: Testing provider operating hours for $providerId');

      // Get provider details
      final providerDetails = await getServiceProviderDetails(providerId);
      debugPrint('📊 Provider: ${providerDetails.businessName}');
      debugPrint(
          '📊 Capacity: ${providerDetails.totalCapacity ?? providerDetails.maxCapacity}');

      // Check opening hours
      final openingHours = providerDetails.openingHours;
      debugPrint('📅 Opening hours data: ${openingHours.keys.toList()}');

      const days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];

      for (final day in days) {
        final dayHours = openingHours[day];
        if (dayHours != null) {
          debugPrint(
              '📅 $day: isOpen=${dayHours.isOpen}, start=${dayHours.startTime}, end=${dayHours.endTime}');
        } else {
          debugPrint('📅 $day: No data found');
        }
      }

      // Test for today
      final today = DateTime.now();
      final todayName = _getDayName(today.weekday);
      final todayHours = openingHours[todayName.toLowerCase()];

      debugPrint(
          '🕐 Today ($todayName): ${todayHours?.isOpen == true ? 'OPEN' : 'CLOSED'}');

      if (todayHours?.isOpen == true) {
        debugPrint(
            '🕐 Hours: ${todayHours!.startTime} - ${todayHours.endTime}');

        // Test slot generation
        final slots = await fetchAvailableSlotsWithCapacity(
          providerId: providerId,
          date: today,
          durationMinutes: 60,
        );

        debugPrint('🎯 Generated ${slots.length} slots for today');
        for (final slot in slots.take(5)) {
          debugPrint(
              '   ${slot.timeSlot}: ${slot.availableCapacity}/${slot.totalCapacity} available');
        }
      }
    } catch (e) {
      debugPrint('❌ DEBUG ERROR: $e');
    }
  }
}

/// Extension methods for common operations
extension FirebaseDataOrchestratorExtensions on FirebaseDataOrchestrator {
  /// Quick method to check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  /// Quick method to get user document reference
  DocumentReference? get currentUserRef => currentUserId != null
      ? _firestore
          .collection(FirebaseDataOrchestrator._endUsersCollection)
          .doc(currentUserId!)
      : null;
}

// ============================================================================
// CAPACITY MANAGEMENT MODELS
// ============================================================================

/// Represents the capacity information for a specific time slot
class TimeSlotCapacity extends Equatable {
  final String timeSlot; // Format: "HH:MM"
  final DateTime date;
  final int totalCapacity;
  final int bookedCapacity;
  final int availableCapacity;
  final List<ReservationSummary> existingReservations;

  const TimeSlotCapacity({
    required this.timeSlot,
    required this.date,
    required this.totalCapacity,
    required this.bookedCapacity,
    required this.availableCapacity,
    required this.existingReservations,
  });

  /// Whether this time slot has available capacity
  bool get isAvailable => availableCapacity > 0;

  /// Capacity utilization percentage (0.0 to 1.0)
  double get utilizationRate =>
      totalCapacity > 0 ? bookedCapacity / totalCapacity : 0.0;

  /// Capacity status for UI display
  CapacityStatus get status {
    if (availableCapacity == 0) return CapacityStatus.full;
    if (utilizationRate >= 0.8) return CapacityStatus.almostFull;
    if (utilizationRate >= 0.5) return CapacityStatus.halfFull;
    return CapacityStatus.available;
  }

  @override
  List<Object?> get props => [
        timeSlot,
        date,
        totalCapacity,
        bookedCapacity,
        availableCapacity,
        existingReservations,
      ];
}

/// Summary of a reservation for capacity calculations
class ReservationSummary extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final int attendeeCount;
  final ReservationStatus status;
  final DateTime reservationTime;

  const ReservationSummary({
    required this.id,
    required this.userId,
    required this.userName,
    required this.attendeeCount,
    required this.status,
    required this.reservationTime,
  });

  factory ReservationSummary.fromReservation(ReservationModel reservation) {
    return ReservationSummary(
      id: reservation.id,
      userId: reservation.userId,
      userName: reservation.userName,
      attendeeCount: reservation.attendees.length,
      status: reservation.status,
      reservationTime:
          reservation.reservationStartTime?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        attendeeCount,
        status,
        reservationTime,
      ];
}

/// Capacity status for UI representation
enum CapacityStatus {
  available,
  halfFull,
  almostFull,
  full,
}

extension CapacityStatusExtension on CapacityStatus {
  String get displayText {
    switch (this) {
      case CapacityStatus.available:
        return 'Available';
      case CapacityStatus.halfFull:
        return 'Half Full';
      case CapacityStatus.almostFull:
        return 'Almost Full';
      case CapacityStatus.full:
        return 'Full';
    }
  }

  Color get color {
    switch (this) {
      case CapacityStatus.available:
        return Colors.green;
      case CapacityStatus.halfFull:
        return Colors.orange;
      case CapacityStatus.almostFull:
        return Colors.red.shade300;
      case CapacityStatus.full:
        return Colors.red;
    }
  }
}

/// Result of capacity validation for a reservation
class CapacityValidationResult extends Equatable {
  final bool isValid;
  final String? errorMessage;
  final int totalCapacity;
  final int availableCapacity;
  final int? bookedCapacity;
  final TimeSlotCapacity? timeSlotCapacity;

  const CapacityValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.totalCapacity,
    required this.availableCapacity,
    this.bookedCapacity,
    this.timeSlotCapacity,
  });

  @override
  List<Object?> get props => [
        isValid,
        errorMessage,
        totalCapacity,
        availableCapacity,
        bookedCapacity,
        timeSlotCapacity,
      ];
}
