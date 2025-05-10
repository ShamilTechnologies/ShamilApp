import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';

class ReservationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String _reservationsRootCollection = 'reservations';

  ReservationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<List<ReservationModel>> fetchExistingReservations(
    String providerId,
    String governorateId,
    DateTime date,
  ) async {
    final startTimestamp = Timestamp.fromDate(date);
    final endTimestamp = Timestamp.fromDate(date.add(const Duration(days: 1)));

    final query = _firestore
        .collection(_reservationsRootCollection)
        .doc(governorateId)
        .collection(providerId)
        .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
        .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
        .where('status', whereIn: [ReservationStatus.confirmed.statusString]);

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => ReservationModel.fromFirestore(doc))
        .toList();
  }

  Future<Map<String, dynamic>> createReservationOnBackend(
    Map<String, dynamic> payload,
  ) async {
    final callable = _functions.httpsCallable('createReservation');
    try {
      final result = await callable.call(payload);
      return result.data;
    } catch (e) {
      print('Error calling createReservation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateAccess(
    String accessCode,
    String providerId,
    String governorateId,
  ) async {
    final callable = _functions.httpsCallable('validateAccess');
    try {
      final result = await callable.call({
        'accessCode': accessCode,
        'providerId': providerId,
        'governorateId': governorateId,
      });
      return result.data;
    } catch (e) {
      print('Error calling validateAccess: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateReservation(
    String providerId,
    String governorateId,
    ReservationType type,
    Map<String, dynamic> typeSpecificData,
  ) async {
    final callable = _functions.httpsCallable('validateReservation');
    try {
      final result = await callable.call({
        'providerId': providerId,
        'governorateId': governorateId,
        'type': type.typeString,
        'typeSpecificData': typeSpecificData,
      });
      return result.data;
    } catch (e) {
      print('Error calling validateReservation: $e');
      rethrow;
    }
  }

  Future<void> updateReservationStatus(
    String reservationId,
    String governorateId,
    String providerId,
    ReservationStatus status,
  ) async {
    await _firestore
        .collection(_reservationsRootCollection)
        .doc(governorateId)
        .collection(providerId)
        .doc(reservationId)
        .update({
      'status': status.statusString,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReservation(
    String reservationId,
    String governorateId,
    String providerId,
  ) async {
    await _firestore
        .collection(_reservationsRootCollection)
        .doc(governorateId)
        .collection(providerId)
        .doc(reservationId)
        .delete();
  }

  Stream<List<ReservationModel>> streamReservations(
    String providerId,
    String governorateId,
  ) {
    return _firestore
        .collection(_reservationsRootCollection)
        .doc(governorateId)
        .collection(providerId)
        .orderBy('reservationStartTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromFirestore(doc))
            .toList());
  }
}
