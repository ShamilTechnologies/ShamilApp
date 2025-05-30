import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/core/utils/firestore_paths.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/social/repository/social_repository.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';

abstract class OptionsConfigurationRepository {
  /// Fetch operating hours for a provider
  Future<Map<String, dynamic>> fetchProviderOperatingHours(String providerId);

  /// Fetch existing reservations for a provider
  Future<List<ReservationModel>> fetchProviderReservations(String providerId);

  /// Submit a new subscription based on configuration options
  /// Note: Reservations should use ReservationRepository instead
  Future<String> submitSubscription(SubscriptionModel subscription);

  /// Fetch the current user's friends
  Future<List<dynamic>> fetchCurrentUserFriends();

  /// Fetch the current user's family members
  Future<List<FamilyMember>> fetchCurrentUserFamilyMembers();

  /// Check if a venue has sufficient capacity for the booking
  Future<bool> checkVenueCapacity(
      String providerId, DateTime date, String timeSlot, int requestedCapacity);

  /// Get the current user's data
  Future<AuthModel?> getCurrentUserData();

  /// Get provider details by provider ID
  Future<Map<String, dynamic>?> getProviderDetails(String providerId);

  /// Get user email from Firebase Auth/Firestore
  Future<String?> getUserEmail(String userId);

  /// Send booking confirmation emails
  Future<void> sendBookingConfirmationEmails({
    required List<String> recipients,
    required String subject,
    required String htmlContent,
  });

  /// Schedule a reminder email to be sent at a later time
  Future<void> scheduleReminderEmail({
    required String recipient,
    required String subject,
    required String htmlContent,
    required DateTime sendTime,
  });

  /// Check if a time slot is available for a provider
  Future<bool> isTimeSlotAvailable(String providerId, DateTime dateTime);
}

class FirebaseOptionsConfigurationRepository
    implements OptionsConfigurationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SocialRepository _socialRepository;

  FirebaseOptionsConfigurationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SocialRepository? socialRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _socialRepository = socialRepository ?? FirebaseSocialRepository();

  @override
  Future<Map<String, dynamic>> fetchProviderOperatingHours(
      String providerId) async {
    try {
      final providerDoc = await _firestore
          .collection(FirestorePaths.serviceProviders())
          .doc(providerId)
          .get();

      if (!providerDoc.exists || providerDoc.data() == null) {
        throw Exception('Provider details not found.');
      }

      final data = providerDoc.data()!;
      final openingHoursData =
          data['openingHours'] as Map<String, dynamic>? ?? {};

      return openingHoursData;
    } catch (e) {
      throw Exception('Error fetching operating hours: $e');
    }
  }

  @override
  Future<List<ReservationModel>> fetchProviderReservations(
      String providerId) async {
    try {
      // Query all users' reservations that match the providerId
      final usersSnapshot =
          await _firestore.collection(FirestorePaths.endUsers()).get();
      List<ReservationModel> reservations = [];

      for (final userDoc in usersSnapshot.docs) {
        final reservationsSnapshot = await userDoc.reference
            .collection('reservations')
            .where('providerId', isEqualTo: providerId)
            .where('status', whereIn: [
          ReservationStatus.confirmed.statusString,
          ReservationStatus.pending.statusString,
        ]).get();

        for (final doc in reservationsSnapshot.docs) {
          reservations.add(ReservationModel.fromFirestore(doc));
        }
      }

      return reservations;
    } catch (e) {
      throw Exception('Error fetching reservations: $e');
    }
  }

  @override
  Future<String> submitSubscription(SubscriptionModel subscription) async {
    try {
      // Validate user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to submit a subscription');
      }

      // Create a new document directly in the user's subscriptions subcollection
      final docRef = _firestore
          .collection(FirestorePaths.endUsers())
          .doc(currentUser.uid)
          .collection('subscriptions')
          .doc(); // Generate a new ID

      // Add the subscription data
      await docRef.set({
        ...subscription.toMapForCreate(),
        'id': docRef.id, // Set the document ID
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also add the subscription to the service provider's pending subscriptions list
      await _firestore
          .collection(FirestorePaths.serviceProviders())
          .doc(subscription.providerId)
          .collection('pendingSubscriptions')
          .doc(docRef.id)
          .set({
        'subscriptionId': docRef.id,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error submitting subscription: $e');
    }
  }

  @override
  Future<List<dynamic>> fetchCurrentUserFriends() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to fetch friends');
      }

      return await _socialRepository.fetchFriends(currentUser.uid);
    } catch (e) {
      throw Exception('Error fetching friends: $e');
    }
  }

  @override
  Future<List<FamilyMember>> fetchCurrentUserFamilyMembers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to fetch family members');
      }

      return await _socialRepository.fetchFamilyMembers(currentUser.uid);
    } catch (e) {
      throw Exception('Error fetching family members: $e');
    }
  }

  @override
  Future<bool> checkVenueCapacity(String providerId, DateTime date,
      String timeSlot, int requestedCapacity) async {
    try {
      // Get all reservations for this provider on this date and time
      final List<ReservationModel> reservations =
          await fetchProviderReservations(providerId);

      // Filter reservations for the specific date and time
      final dateString =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final reservationsAtTime = reservations.where((res) {
        // Check if reservation is at this date and time
        if (res.reservationStartTime == null) return false;

        final resDate = res.reservationStartTime!.toDate();
        final resDateString =
            "${resDate.year}-${resDate.month.toString().padLeft(2, '0')}-${resDate.day.toString().padLeft(2, '0')}";
        final resTime =
            "${resDate.hour.toString().padLeft(2, '0')}:${resDate.minute.toString().padLeft(2, '0')}";

        return resDateString == dateString && resTime == timeSlot;
      }).toList();

      // Calculate total capacity used
      int totalCapacityUsed = 0;
      for (var res in reservationsAtTime) {
        if (res.isFullVenueReservation) {
          // If someone already has a full venue booking, no availability
          return false;
        }

        // Add the reserved capacity or group size
        totalCapacityUsed += res.reservedCapacity ?? res.groupSize;
      }

      // Get the venue's capacity
      final providerDoc = await _firestore
          .collection(FirestorePaths.serviceProviders())
          .doc(providerId)
          .get();

      if (!providerDoc.exists || providerDoc.data() == null) {
        throw Exception('Provider details not found.');
      }

      final data = providerDoc.data()!;
      final venueCapacity =
          data['capacity'] as int? ?? 50; // Default to 50 if not specified

      // Check if there's enough capacity
      return (totalCapacityUsed + requestedCapacity) <= venueCapacity;
    } catch (e) {
      throw Exception('Error checking venue capacity: $e');
    }
  }

  @override
  Future<AuthModel?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final docRef =
          _firestore.collection(FirestorePaths.endUsers()).doc(currentUser.uid);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      return AuthModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Error fetching current user data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    try {
      final doc = await _firestore
          .collection('service_providers')
          .doc(providerId)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      print('Error fetching provider details: $e');
      return null;
    }
  }

  @override
  Future<String?> getUserEmail(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['email'] as String?;
      }

      return null;
    } catch (e) {
      print('Error fetching user email: $e');
      return null;
    }
  }

  @override
  Future<void> sendBookingConfirmationEmails({
    required List<String> recipients,
    required String subject,
    required String htmlContent,
  }) async {
    // Implementation depends on your email service
    // For now, just log the action
    print('Sending booking confirmation emails to: $recipients');
  }

  @override
  Future<void> scheduleReminderEmail({
    required String recipient,
    required String subject,
    required String htmlContent,
    required DateTime sendTime,
  }) async {
    // Implementation depends on your scheduled email service
    // For now, just log the action
    print('Scheduling reminder email for $recipient at $sendTime');
  }

  @override
  Future<bool> isTimeSlotAvailable(String providerId, DateTime dateTime) async {
    // Implementation needed
    throw UnimplementedError();
  }
}
