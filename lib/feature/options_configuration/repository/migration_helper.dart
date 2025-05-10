import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/core/utils/firestore_paths.dart';

/// Helper class to migrate data from old collection structure to new user-based structure
class MigrationHelper {
  final FirebaseFirestore _firestore;

  MigrationHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Migrates reservation data from global 'reservations' collection to user subcollections
  Future<void> migrateReservationData() async {
    try {
      // Get all reservations from old collection
      final oldReservations = await _firestore.collection('reservations').get();

      // Track successful migrations
      int successCount = 0;

      // Move each to user subcollection
      for (final doc in oldReservations.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;

        if (userId != null && userId.isNotEmpty) {
          await _firestore
              .collection(FirestorePaths.endUsers())
              .doc(userId)
              .collection('reservations')
              .doc(doc.id)
              .set({
            ...data,
            'id': doc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Add to provider's pending or confirmed reservations based on status
          final providerId = data['providerId'] as String?;
          final status = data['status'] as String?;

          if (providerId != null && providerId.isNotEmpty) {
            final collectionName = (status == 'pending')
                ? 'pendingReservations'
                : 'confirmedReservations';

            await _firestore
                .collection(FirestorePaths.serviceProviders())
                .doc(providerId)
                .collection(collectionName)
                .doc(doc.id)
                .set({
              'reservationId': doc.id,
              'userId': userId,
              'timestamp': data['createdAt'] ?? FieldValue.serverTimestamp(),
            });
          }

          successCount++;
        }
      }

      print(
          'Successfully migrated $successCount of ${oldReservations.docs.length} reservations');
    } catch (e) {
      print('Error during reservation migration: $e');
    }
  }

  /// Migrates subscription data from global 'subscriptions' collection to user subcollections
  Future<void> migrateSubscriptionData() async {
    try {
      // Get all subscriptions from old collection
      final oldSubscriptions =
          await _firestore.collection('subscriptions').get();

      // Track successful migrations
      int successCount = 0;

      // Move each to user subcollection
      for (final doc in oldSubscriptions.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;

        if (userId != null && userId.isNotEmpty) {
          await _firestore
              .collection(FirestorePaths.endUsers())
              .doc(userId)
              .collection('subscriptions')
              .doc(doc.id)
              .set({
            ...data,
            'id': doc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Add to provider's active subscriptions list
          final providerId = data['providerId'] as String?;

          if (providerId != null && providerId.isNotEmpty) {
            await _firestore
                .collection(FirestorePaths.serviceProviders())
                .doc(providerId)
                .collection('activeSubscriptions')
                .doc(doc.id)
                .set({
              'subscriptionId': doc.id,
              'userId': userId,
              'timestamp': data['createdAt'] ?? FieldValue.serverTimestamp(),
            });
          }

          successCount++;
        }
      }

      print(
          'Successfully migrated $successCount of ${oldSubscriptions.docs.length} subscriptions');
    } catch (e) {
      print('Error during subscription migration: $e');
    }
  }
}
