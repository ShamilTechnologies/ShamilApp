import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/feature/favorites/repository/favorites_repository.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

class FirebaseFavoritesRepository implements FavoritesRepository {
  final FirebaseFirestore _firestore;
  final String _userId;

  FirebaseFavoritesRepository({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance {
    print('FirebaseFavoritesRepository initialized with userId: $_userId');
  }

  @override
  Stream<List<ServiceProviderDisplayModel>> getFavorites() {
    print('Getting favorites for user: $_userId');
    try {
      // Get the favorites collection reference
      final favoritesRef =
          _firestore.collection('users').doc(_userId).collection('favorites');

      // Listen to changes in the favorites collection
      return favoritesRef.snapshots().asyncMap((favoritesSnapshot) async {
        print(
            'Favorites snapshot received with ${favoritesSnapshot.docs.length} documents');

        if (favoritesSnapshot.docs.isEmpty) {
          print('No favorites found');
          return [];
        }

        final List<ServiceProviderDisplayModel> favorites = [];
        final List<Future<void>> fetchFutures = [];

        // For each favorite document, fetch the corresponding service provider
        for (var favoriteDoc in favoritesSnapshot.docs) {
          final providerId = favoriteDoc.id;
          final future = _firestore
              .collection('service_providers')
              .doc(providerId)
              .get()
              .then((providerDoc) {
            if (providerDoc.exists) {
              try {
                final provider = ServiceProviderDisplayModel.fromFirestore(
                  providerDoc,
                  isFavorite: true,
                );
                favorites.add(provider);
                print(
                    'Added provider to favorites list: ${provider.businessName}');
              } catch (e) {
                print('Error processing provider document ${providerId}: $e');
              }
            } else {
              print('Provider document not found: $providerId');
            }
          }).catchError((error) {
            print('Error fetching provider document ${providerId}: $error');
          });

          fetchFutures.add(future);
        }

        // Wait for all provider documents to be fetched
        await Future.wait(fetchFutures);

        print('Returning ${favorites.length} favorites');
        return favorites;
      });
    } catch (e) {
      print('Error in getFavorites: $e');
      rethrow;
    }
  }

  @override
  Future<void> addToFavorites(ServiceProviderDisplayModel provider) async {
    print('Adding to favorites: ${provider.id}');
    try {
      // First check if the provider exists in the main collection
      final providerDoc = await _firestore
          .collection('service_providers')
          .doc(provider.id)
          .get();

      if (!providerDoc.exists) {
        print('Provider not found in main collection: ${provider.id}');
        throw Exception('Service provider not found');
      }

      print('Provider found, adding to favorites');
      // Add to favorites collection
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(provider.id)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
      print('Successfully added to favorites');
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String providerId) async {
    print('Removing from favorites: $providerId');
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(providerId)
          .delete();
      print('Successfully removed from favorites');
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isFavorite(String providerId) async {
    print('Checking if favorite: $providerId');
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(providerId)
          .get();
      print('Is favorite: ${doc.exists}');
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      rethrow;
    }
  }

  // Add a stream for checking favorite status
  Stream<bool> isFavoriteStream(String providerId) {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(providerId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
