import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/core/utils/firestore_paths.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';

abstract class UserRepository {
  /// Fetch the current user's reservations
  Future<List<ReservationModel>> fetchUserReservations();

  /// Fetch the current user's subscriptions
  Future<List<SubscriptionModel>> fetchUserSubscriptions();

  /// Fetch a specific reservation by ID
  Future<ReservationModel?> fetchReservationById(String reservationId);

  /// Fetch a specific subscription by ID
  Future<SubscriptionModel?> fetchSubscriptionById(String subscriptionId);

  /// Cancel a reservation
  Future<void> cancelReservation(String reservationId);

  /// Cancel a subscription
  Future<void> cancelSubscription(String subscriptionId);
}

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<ReservationModel>> fetchUserReservations() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to fetch reservations');
    }

    try {
      final querySnapshot = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('reservations')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching reservations: $e');
    }
  }

  @override
  Future<List<SubscriptionModel>> fetchUserSubscriptions() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to fetch subscriptions');
    }

    try {
      final querySnapshot = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('subscriptions')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching subscriptions: $e');
    }
  }

  @override
  Future<ReservationModel?> fetchReservationById(String reservationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to fetch reservation details');
    }

    try {
      final docSnapshot = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      return ReservationModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Error fetching reservation details: $e');
    }
  }

  @override
  Future<SubscriptionModel?> fetchSubscriptionById(
      String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to fetch subscription details');
    }

    try {
      final docSnapshot = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      return SubscriptionModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Error fetching subscription details: $e');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to cancel a reservation');
    }

    try {
      // Get the reservation to find the provider ID
      final reservationDoc = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('reservations')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists || reservationDoc.data() == null) {
        throw Exception('Reservation not found');
      }

      final reservationData = reservationDoc.data()!;
      final providerId = reservationData['providerId'] as String?;

      // Transaction to update reservation status and remove from provider's pending list
      await _firestore.runTransaction((transaction) async {
        // Update reservation status to cancelled by user
        transaction.update(reservationDoc.reference, {
          'status': ReservationStatus.cancelledByUser.statusString,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If provider ID exists, update provider's records
        if (providerId != null && providerId.isNotEmpty) {
          // Remove from pending reservations
          final pendingRef = _firestore
              .collection(FirestorePaths.serviceProviders())
              .doc(providerId)
              .collection('pendingReservations')
              .doc(reservationId);

          final pendingDoc = await transaction.get(pendingRef);
          if (pendingDoc.exists) {
            transaction.delete(pendingRef);
          }

          // Add to cancelled reservations
          transaction.set(
              _firestore
                  .collection(FirestorePaths.serviceProviders())
                  .doc(providerId)
                  .collection('cancelledReservations')
                  .doc(reservationId),
              {
                'reservationId': reservationId,
                'userId': user.uid,
                'cancelledAt': FieldValue.serverTimestamp(),
                'cancelledBy': 'user',
              });
        }
      });
    } catch (e) {
      throw Exception('Error cancelling reservation: $e');
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to cancel a subscription');
    }

    try {
      // Get the subscription to find the provider ID
      final subscriptionDoc = await _firestore
          .collection(FirestorePaths.endUsers())
          .doc(user.uid)
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists || subscriptionDoc.data() == null) {
        throw Exception('Subscription not found');
      }

      final subscriptionData = subscriptionDoc.data()!;
      final providerId = subscriptionData['providerId'] as String?;

      // Transaction to update subscription status
      await _firestore.runTransaction((transaction) async {
        // Update subscription status to cancelled
        transaction.update(subscriptionDoc.reference, {
          'status': SubscriptionStatus.cancelled.statusString,
          'cancellationReason': 'Cancelled by user',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If provider ID exists, update provider's records
        if (providerId != null && providerId.isNotEmpty) {
          // Remove from active subscriptions
          final activeRef = _firestore
              .collection(FirestorePaths.serviceProviders())
              .doc(providerId)
              .collection('activeSubscriptions')
              .doc(subscriptionId);

          final activeDoc = await transaction.get(activeRef);
          if (activeDoc.exists) {
            transaction.delete(activeRef);
          }

          // Add to cancelled subscriptions
          transaction.set(
              _firestore
                  .collection(FirestorePaths.serviceProviders())
                  .doc(providerId)
                  .collection('cancelledSubscriptions')
                  .doc(subscriptionId),
              {
                'subscriptionId': subscriptionId,
                'userId': user.uid,
                'cancelledAt': FieldValue.serverTimestamp(),
                'cancelledBy': 'user',
              });
        }
      });
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }
}
