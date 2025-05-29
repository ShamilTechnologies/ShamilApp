import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shamil_mobile_app/core/payment/payment_orchestrator.dart';

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
class FirebaseDataOrchestrator {
  // Singleton pattern
  static final FirebaseDataOrchestrator _instance =
      FirebaseDataOrchestrator._internal();
  factory FirebaseDataOrchestrator() => _instance;
  FirebaseDataOrchestrator._internal();

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

  /// Creates a new reservation with optimized batch operations
  Future<String> createReservation(ReservationModel reservation) async {
    if (currentUserId == null) throw Exception('User must be logged in');

    final batch = _firestore.batch();

    try {
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

    try {
      // Verify payment status
      final paymentOrchestrator = PaymentOrchestrator();
      final paymentResponse =
          await paymentOrchestrator.verifyPayment(paymentId);

      if (paymentResponse.isSuccessful) {
        // Update reservation status to confirmed
        await _firestore
            .collection(_endUsersCollection)
            .doc(currentUserId!)
            .collection('reservations')
            .doc(reservationId)
            .update({
          'status': ReservationStatus.confirmed.statusString,
          'paymentStatus': 'completed',
          'paymentId': paymentId,
          'paymentGateway': gateway.name,
          'confirmedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
            'Reservation $reservationId confirmed with payment $paymentId');
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
