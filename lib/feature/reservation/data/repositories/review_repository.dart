import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'reviews';

  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new review
  Future<ReviewModel> createReview(ReviewModel review) async {
    final docRef = await _firestore.collection(_collection).add(review.toMap());
    return review.copyWith(id: docRef.id);
  }

  // Get review by ID
  Future<ReviewModel?> getReview(String reviewId) async {
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (doc.exists) {
      return ReviewModel.fromFirestore(doc);
    }
    return null;
  }

  // Get reviews for a reservation
  Future<List<ReviewModel>> getReservationReviews(String reservationId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('reservationId', isEqualTo: reservationId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  // Get reviews for a provider
  Future<List<ReviewModel>> getProviderReviews(
    String providerId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  // Get reviews for a service
  Future<List<ReviewModel>> getServiceReviews(
    String serviceId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();
  }

  // Update a review
  Future<void> updateReview(ReviewModel review) async {
    await _firestore
        .collection(_collection)
        .doc(review.id)
        .update(review.toMap());
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection(_collection).doc(reviewId).delete();
  }

  // Get average rating for a provider
  Future<double> getProviderAverageRating(String providerId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .get();

    if (querySnapshot.docs.isEmpty) return 0.0;

    final totalRating = querySnapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );

    return totalRating / querySnapshot.docs.length;
  }

  // Get average rating for a service
  Future<double> getServiceAverageRating(String serviceId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .get();

    if (querySnapshot.docs.isEmpty) return 0.0;

    final totalRating = querySnapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );

    return totalRating / querySnapshot.docs.length;
  }

  // Get category ratings for a provider
  Future<Map<String, double>> getProviderCategoryRatings(
      String providerId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .get();

    if (querySnapshot.docs.isEmpty) return {};

    final categoryRatings = <String, List<double>>{};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['categoryRatings'] != null) {
        final ratings = data['categoryRatings'] as Map<String, dynamic>;
        ratings.forEach((category, rating) {
          categoryRatings
              .putIfAbsent(category, () => [])
              .add(rating.toDouble());
        });
      }
    }

    return categoryRatings.map((category, ratings) {
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return MapEntry(category, average);
    });
  }

  // Check if user has reviewed a reservation
  Future<bool> hasUserReviewed(String userId, String reservationId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('reservationId', isEqualTo: reservationId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
