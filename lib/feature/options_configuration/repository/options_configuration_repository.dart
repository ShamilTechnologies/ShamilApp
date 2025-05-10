import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/core/utils/firestore_paths.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';

abstract class OptionsConfigurationRepository {
  /// Fetch operating hours for a provider
  Future<Map<String, dynamic>> fetchProviderOperatingHours(String providerId);

  /// Fetch existing reservations for a provider
  Future<List<ReservationModel>> fetchProviderReservations(String providerId);

  /// Submit a new reservation based on configuration options
  Future<String> submitReservation(ReservationModel reservation);

  /// Submit a new subscription based on configuration options
  Future<String> submitSubscription(SubscriptionModel subscription);
}

class FirebaseOptionsConfigurationRepository
    implements OptionsConfigurationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseOptionsConfigurationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
  Future<String> submitReservation(ReservationModel reservation) async {
    try {
      // Validate user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to submit a reservation');
      }

      // Create a new document directly in the user's reservations subcollection
      final docRef = _firestore
          .collection(FirestorePaths.endUsers())
          .doc(currentUser.uid)
          .collection('reservations')
          .doc(); // Generate a new ID

      // Add the reservation data
      await docRef.set({
        ...reservation.toMapForCreate(),
        'id': docRef.id, // Set the document ID
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also add the reservation to the service provider's pending reservations list
      await _firestore
          .collection(FirestorePaths.serviceProviders())
          .doc(reservation.providerId)
          .collection('pendingReservations')
          .doc(docRef.id)
          .set({
        'reservationId': docRef.id,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error submitting reservation: $e');
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
}
