import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:flutter/foundation.dart';

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
  final FirebaseDataOrchestrator _orchestrator;

  FirebaseUserRepository({
    FirebaseDataOrchestrator? orchestrator,
  }) : _orchestrator = orchestrator ?? FirebaseDataOrchestrator() {
    debugPrint(
        '🔧 FirebaseUserRepository initialized with orchestrator: ${_orchestrator.runtimeType}');
  }

  @override
  Future<List<ReservationModel>> fetchUserReservations() async {
    try {
      debugPrint(
          '📊 UserRepository: Fetching user reservations via orchestrator');
      // Use the centralized orchestrator which has proper timestamp handling
      final stream = _orchestrator.getUserReservationsStream();
      final result = await stream.first;
      debugPrint('✅ UserRepository: Fetched ${result.length} reservations');
      return result;
    } catch (e) {
      debugPrint('❌ UserRepository: Error fetching reservations: $e');
      throw Exception('Error fetching reservations: $e');
    }
  }

  @override
  Future<List<SubscriptionModel>> fetchUserSubscriptions() async {
    try {
      debugPrint(
          '📊 UserRepository: Fetching user subscriptions via orchestrator');
      // Use the centralized orchestrator
      final stream = _orchestrator.getUserSubscriptionsStream();
      final result = await stream.first;
      debugPrint('✅ UserRepository: Fetched ${result.length} subscriptions');
      return result;
    } catch (e) {
      debugPrint('❌ UserRepository: Error fetching subscriptions: $e');
      throw Exception('Error fetching subscriptions: $e');
    }
  }

  @override
  Future<ReservationModel?> fetchReservationById(String reservationId) async {
    try {
      final reservations = await fetchUserReservations();
      return reservations.firstWhere(
        (reservation) => reservation.id == reservationId,
        orElse: () => throw Exception('Reservation not found'),
      );
    } catch (e) {
      if (e.toString().contains('Reservation not found')) {
        return null;
      }
      throw Exception('Error fetching reservation details: $e');
    }
  }

  @override
  Future<SubscriptionModel?> fetchSubscriptionById(
      String subscriptionId) async {
    try {
      final subscriptions = await fetchUserSubscriptions();
      return subscriptions.firstWhere(
        (subscription) => subscription.id == subscriptionId,
        orElse: () => throw Exception('Subscription not found'),
      );
    } catch (e) {
      if (e.toString().contains('Subscription not found')) {
        return null;
      }
      throw Exception('Error fetching subscription details: $e');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    try {
      // Use the centralized orchestrator which handles all the proper database structure
      await _orchestrator.cancelReservation(reservationId);
    } catch (e) {
      throw Exception('Error cancelling reservation: $e');
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      // Use the centralized orchestrator
      await _orchestrator.cancelSubscription(subscriptionId);
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }
}
