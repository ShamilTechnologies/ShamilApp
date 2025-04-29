// lib/feature/home/views/bloc/home_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull if used
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart'; // Updated model
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

part 'home_event.dart'; // Ensure ToggleFavoriteHome event is defined here
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Firestore Collection Name Constants (Added for fix consistency) ---
  static const String _usersCollection = 'endUsers';
  static const String _providersCollection = 'serviceProviders';
  static const String _favoritesSubCollection = 'favorites';
  // --- End Constants ---

  HomeBloc() : super(HomeInitial()) {
    // --- ENSURE ALL HANDLERS ARE REGISTERED HERE ---
    on<LoadHomeData>(_onLoadHomeData);
    on<UpdateCityManually>(_onUpdateCityManually);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchProviders>(_onSearchProviders);
    on<ToggleFavoriteHome>(
        _onToggleFavoriteHome); // <<< *** THIS LINE IS CRUCIAL ***
    // -----------------------------------------------
  }

  // --- Helper Function Section ---

  String _formatCity(String rawCity) {
    /* ... */
    final regex = RegExp(r'\s*Governorate\s*', caseSensitive: false);
    return rawCity.replaceAll(regex, '').trim();
  }

  Future<String?> _fetchLastKnownCity(String uid) async {
    /* ... */
    try {
      // *** Use Constant ***
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('city')) {
        final city = doc.data()!['city'] as String?;
        print("HomeBloc: Fetched last known city '$city' for UID $uid");
        return city;
      } else {
        print("HomeBloc: No last known city found in Firestore for UID $uid");
      }
    } catch (e) {
      print("HomeBloc: Error fetching last known city: $e");
    }
    return null;
  }

  Future<void> _updateCityInFirestore(
      String uid, String city, Timestamp timestamp) async {
    /* ... */
    try {
      // *** Use Constant ***
      await _firestore.collection(_usersCollection).doc(uid).set({
        'city': city,
        'lastUpdatedLocation': timestamp,
      }, SetOptions(merge: true));
      print(
          "HomeBloc: User city updated/set in Firestore to: $city at $timestamp for UID $uid");
    } catch (e) {
      print(
          "HomeBloc: Error updating/setting city in Firestore for UID $uid: $e");
    }
  }

  Future<Set<String>> _fetchUserFavoriteIds(String userId) async {
    /* ... */
    try {
      // *** FIX: Use Constants for correct path ***
      final snapshot = await _firestore
          .collection(_usersCollection) // <<< CORRECTED
          .doc(userId)
          .collection(_favoritesSubCollection) // <<< CORRECTED (using constant)
          .get(const GetOptions(source: Source.cache));
      print(
          "HomeBloc: Fetched ${snapshot.docs.length} favorite IDs for $userId from $_usersCollection/$_favoritesSubCollection."); // Updated log
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("HomeBloc: Error fetching user favorite IDs for $userId: $e");
      return <String>{};
    }
  }

  /// Helper to map ServiceProvider to ServiceProviderDisplayModel including favorite status.
  ServiceProviderDisplayModel _mapProviderToDisplayModel(
      ServiceProviderModel p, Set<String> favoriteIds) {
    // *** ADD LOGGING HERE ***
    print(
        "HomeBloc(Mapping): Mapping provider ID=${p.id}, Name=${p.businessName}. Raw mainImageUrl from Firestore model = '${p.mainImageUrl}'");
    // *************************

    final displayModel = ServiceProviderDisplayModel(
      id: p.id,
      businessName: p.businessName,
      category: p.category,
      imageUrl: p.mainImageUrl, // Map mainImageUrl to imageUrl
      logoUrl: p.logoUrl, // Map logoUrl
      rating: p.rating,
      reviewCount: p.ratingCount,
      city: p.city ?? p.governorate ?? '',
      isFavorite: favoriteIds.contains(p.id),
    );

    // *** ADD LOGGING HERE (Optional but helpful) ***
    // print("HomeBloc(Mapping): Resulting DisplayModel imageUrl = '${displayModel.imageUrl}'");
    // *********************************************

    return displayModel;
  }
  // --- Event Handlers ---

  Future<void> _onLoadHomeData(
      LoadHomeData event, Emitter<HomeState> emit) async {
    // (Keep existing implementation - it uses the updated helpers)
    emit(HomeLoading());
    print("HomeBloc: Starting LoadHomeData...");
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");
      final userId = currentUser.uid;
      print("HomeBloc: User authenticated: $userId");
      String city = "Unknown";
      Timestamp lastUpdated = Timestamp.now();
      // Location Logic... (shortened for brevity)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        city = await _fetchLastKnownCity(userId) ?? "Location Off";
      } else {
        var permissionStatus =
            await perm_handler.Permission.locationWhenInUse.status;
        if (permissionStatus.isDenied) {
          permissionStatus =
              await perm_handler.Permission.locationWhenInUse.request();
        }
        if (permissionStatus.isPermanentlyDenied) {
          city = await _fetchLastKnownCity(userId) ?? "Permission Denied";
        } else if (permissionStatus.isGranted || permissionStatus.isLimited) {
          try {
            final Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 10));
            List<Placemark> placemarks = await placemarkFromCoordinates(
                position.latitude, position.longitude);
            if (placemarks.isNotEmpty) {
              city = _formatCity(placemarks.first.administrativeArea ??
                  placemarks.first.locality ??
                  "Unknown");
              lastUpdated = Timestamp.now();
              await _updateCityInFirestore(userId, city, lastUpdated);
            } else {
              city = await _fetchLastKnownCity(userId) ?? "Geocode Failed";
            }
          } catch (e) {
            city = await _fetchLastKnownCity(userId) ?? "Location Error";
          }
        } else {
          city = await _fetchLastKnownCity(userId) ?? "Permission Issue";
        }
      }
      // Fetch Providers
      List<ServiceProviderDisplayModel> popularForDisplay = [];
      List<ServiceProviderDisplayModel> recommendedForDisplay = [];
      // *** Added lists for consistency with HomeLoaded state ***
      List<BannerModel> banners = [];
      List<ServiceProviderDisplayModel> offersForDisplay = [];
      List<ServiceProviderDisplayModel> nearbyForDisplay = [];
      try {
        final Set<String> favoriteIds =
            await _fetchUserFavoriteIds(userId); // Uses updated helper
        // --- Fetch Banners (Example Query - kept from previous full rewrite) ---
        try {
          final bannerSnapshot = await _firestore
              .collection('banners') // Example collection name
              .where('isActive', isEqualTo: true) // Filter for active banners
              .orderBy('priority',
                  descending: true) // Optional: order by priority
              .limit(5) // Limit number of banners
              .get();
          banners = bannerSnapshot.docs
              .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
              .toList();
          print("HomeBloc: Fetched ${banners.length} banners.");
        } catch (e) {
          print(
              "HomeBloc: Error fetching banners: $e"); // Log error but continue
        }
        // --- End Fetch Banners ---

        // --- Fetch Providers (Main Query) ---
        Query query = _firestore
            .collection(_providersCollection) // *** Use Constant ***
            .where('isActive', isEqualTo: true);
        bool isValidCityForFilter = city != "Unknown" &&
            city != "Location Off" &&
            city != "Permission Denied" &&
            city != "Geocode Failed" &&
            city != "Location Error" &&
            city != "Location Timeout" &&
            city != "Permission Issue";
        if (isValidCityForFilter) {
          query = query.where('address.governorate', isEqualTo: city);
        }
        final querySnapshot = await query.limit(50).get();
        final allProviders = querySnapshot.docs
            .map((doc) {
              try {
                return ServiceProviderModel.fromFirestore(doc);
              } catch (e) {
                print("Error parsing provider ${doc.id}: $e");
                return null;
              }
            })
            .whereType<ServiceProviderModel>()
            .toList();
        // --- Process fetched providers ---
        final popularProvidersFull = allProviders
            .where((p) => p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final recommendedProvidersFull = allProviders
            .where((p) => !p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        // --- TODO: Add specific logic for offers/nearby ---
        final offersProvidersFull = popularProvidersFull; // Placeholder
        final nearbyProvidersFull = recommendedProvidersFull; // Placeholder

        // --- Map to Display Models ---
        popularForDisplay = popularProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(
                p, favoriteIds)) // Uses updated helper
            .toList();
        recommendedForDisplay = recommendedProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(
                p, favoriteIds)) // Uses updated helper
            .toList();
        offersForDisplay = offersProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(
                p, favoriteIds)) // Uses updated helper
            .toList(); // Placeholder
        nearbyForDisplay = nearbyProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(
                p, favoriteIds)) // Uses updated helper
            .toList(); // Placeholder
      } catch (e, stacktrace) {
        print("HomeBloc: Error fetching/processing providers: $e\n$stacktrace");
        emit(HomeError(message: "Could not load places: ${e.toString()}"));
        return;
      }
      final homeModel =
          HomeModel(uid: userId, city: city, lastUpdatedLocation: lastUpdated);
      emit(HomeLoaded(
        homeModel: homeModel,
        popularProviders: popularForDisplay,
        recommendedProviders: recommendedForDisplay,
        // *** Pass other lists ***
        banners: banners,
        offers: offersForDisplay,
        nearbyProviders: nearbyForDisplay,
      ));
      print("HomeBloc: HomeLoaded emitted successfully.");
    } catch (e, stacktrace) {
      print("HomeBloc: Critical Error in _onLoadHomeData: $e\n$stacktrace");
      emit(HomeError(message: "Failed to load home data: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateCityManually(
      UpdateCityManually event, Emitter<HomeState> emit) async {
    // (Keep existing implementation - it uses the updated helpers)
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(const HomeError(message: "User not logged in."));
      return;
    }
    final userId = currentUser.uid;
    final newCity = event.newCity;
    print("HomeBloc: Starting _onUpdateCityManually for city: $newCity");
    emit(HomeLoading()); // Show loading while fetching new city data
    try {
      final lastUpdated = Timestamp.now();
      await _updateCityInFirestore(
          userId, newCity, lastUpdated); // Uses constant
      final Set<String> favoriteIds =
          await _fetchUserFavoriteIds(userId); // Uses constant

      List<BannerModel> currentBanners =
          (state is HomeLoaded) ? (state as HomeLoaded).banners : [];

      Query query = _firestore
          .collection(_providersCollection) // *** Use Constant ***
          .where('isActive', isEqualTo: true)
          .where('address.governorate',
              isEqualTo: newCity); // Filter by NEW city
      final querySnapshot = await query.limit(50).get();
      final allProviders = querySnapshot.docs
          .map((doc) {
            try {
              return ServiceProviderModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<ServiceProviderModel>()
          .toList();

      final popularProvidersFull = allProviders
          .where((p) => p.isFeatured)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      final recommendedProvidersFull = allProviders
          .where((p) => !p.isFeatured)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      final offersProvidersFull = popularProvidersFull; // Placeholder
      final nearbyProvidersFull = recommendedProvidersFull; // Placeholder

      final popularForDisplay = popularProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList();
      final recommendedForDisplay = recommendedProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList();
      final offersForDisplay = offersProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList(); // Placeholder
      final nearbyForDisplay = nearbyProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList(); // Placeholder

      final updatedHomeModel = HomeModel(
        uid: userId,
        city: newCity,
        lastUpdatedLocation: lastUpdated,
      );

      emit(HomeLoaded(
        homeModel: updatedHomeModel,
        popularProviders: popularForDisplay,
        recommendedProviders: recommendedForDisplay,
        banners: currentBanners,
        offers: offersForDisplay,
        nearbyProviders: nearbyForDisplay,
      ));
      print("HomeBloc: HomeLoaded emitted after manual city update: $newCity");
    } catch (e, stacktrace) {
      print(
          "HomeBloc: Error updating city manually or re-fetching: $e\n$stacktrace");
      emit(HomeError(message: "Failed to update city: ${e.toString()}"));
    }
  }

  Future<void> _onFilterByCategory(
      FilterByCategory event, Emitter<HomeState> emit) async {
    // (Keep existing implementation - it uses the updated helpers)
    print(
        "HomeBloc: FilterByCategory event received for category: ${event.category}");
    final currentState = state;
    final currentUser = _auth.currentUser;
    if (currentState is HomeLoaded && currentUser != null) {
      final userId = currentUser.uid;
      final String currentCity = currentState.homeModel.city;
      final String categoryToFilter = event.category;

      emit(HomeLoading());
      try {
        final Set<String> favoriteIds =
            await _fetchUserFavoriteIds(userId); // Uses constant

        Query query = _firestore
            .collection(_providersCollection) // *** Use Constant ***
            .where('isActive', isEqualTo: true)
            .where('address.governorate', isEqualTo: currentCity);

        if (categoryToFilter.isNotEmpty && categoryToFilter != 'All') {
          query = query.where('businessCategory', isEqualTo: categoryToFilter);
        }

        final querySnapshot = await query.limit(50).get();
        final allProviders = querySnapshot.docs
            .map((doc) {
              try {
                return ServiceProviderModel.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .whereType<ServiceProviderModel>()
            .toList();

        final popularProvidersFull = allProviders
            .where((p) => p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final recommendedProvidersFull = allProviders
            .where((p) => !p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final offersProvidersFull = popularProvidersFull; // Placeholder
        final nearbyProvidersFull = recommendedProvidersFull; // Placeholder

        final popularForDisplay = popularProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        final recommendedForDisplay = recommendedProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        final offersForDisplay = offersProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList(); // Placeholder
        final nearbyForDisplay = nearbyProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList(); // Placeholder

        emit(HomeLoaded(
          homeModel: currentState.homeModel,
          popularProviders: popularForDisplay,
          recommendedProviders: recommendedForDisplay,
          banners: currentState.banners,
          offers: offersForDisplay,
          nearbyProviders: nearbyForDisplay,
        ));
        print(
            "HomeBloc: Emitted HomeLoaded with category filter '$categoryToFilter' applied.");
      } catch (e, s) {
        print("HomeBloc: Error filtering by category: $e\n$s");
        emit(HomeError(
            message: "Failed to filter by category: ${e.toString()}"));
        emit(currentState);
      }
    } else {
      print(
          "HomeBloc: Cannot filter by category, state is not HomeLoaded or user is null.");
    }
  }

  Future<void> _onSearchProviders(
      SearchProviders event, Emitter<HomeState> emit) async {
    // (Keep existing implementation - it uses the updated helpers)
    print("HomeBloc: SearchProviders event received for query: ${event.query}");
    final currentState = state;
    final currentUser = _auth.currentUser;
    final searchQuery = event.query.trim();

    if (searchQuery.isEmpty) {
      add(const LoadHomeData());
      return;
    }

    if (currentState is HomeLoaded && currentUser != null) {
      final userId = currentUser.uid;
      final String currentCity = currentState.homeModel.city;
      emit(HomeLoading());
      try {
        final Set<String> favoriteIds =
            await _fetchUserFavoriteIds(userId); // Uses constant
        final lowercaseQuery = searchQuery.toLowerCase();
        Query query = _firestore
            .collection(_providersCollection) // *** Use Constant ***
            .where('isActive', isEqualTo: true)
            .where('address.governorate', isEqualTo: currentCity)
            .where('name_lowercase', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('name_lowercase',
                isLessThanOrEqualTo: '$lowercaseQuery\uf8ff');

        final querySnapshot = await query.limit(20).get();
        final allProviders = querySnapshot.docs
            .map((doc) {
              try {
                return ServiceProviderModel.fromFirestore(doc);
              } catch (e) {
                return null;
              }
            })
            .whereType<ServiceProviderModel>()
            .toList();

        final searchResultsForDisplay = allProviders
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList()
          ..sort((a, b) => a.businessName.compareTo(b.businessName));

        emit(HomeLoaded(
          homeModel: currentState.homeModel,
          popularProviders:
              searchResultsForDisplay, // Show search results in popular
          recommendedProviders: const [], // Clear others
          banners: currentState.banners,
          offers: const [],
          nearbyProviders: const [],
        ));
        print(
            "HomeBloc: Emitted HomeLoaded with search results for '$searchQuery'. Found ${searchResultsForDisplay.length} results.");
      } catch (e, s) {
        print("HomeBloc: Error searching providers: $e\n$s");
        if (e is FirebaseException && e.code == 'failed-precondition') {
          emit(const HomeError(
              message:
                  "Search requires a database index. Please check Firestore configuration for 'name_lowercase'."));
        } else {
          emit(HomeError(
              message: "Failed to search providers: ${e.toString()}"));
        }
        emit(currentState);
      }
    } else {
      print(
          "HomeBloc: Cannot search providers, state is not HomeLoaded or user is null.");
    }
  }

  /// **Handler for toggling favorite status from Home screen.**
  Future<void> _onToggleFavoriteHome(
      ToggleFavoriteHome event, Emitter<HomeState> emit) async {
    final currentState = state;
    final currentUser = _auth.currentUser;

    if (currentState is HomeLoaded && currentUser != null) {
      final userId = currentUser.uid;
      final providerId = event.providerId;
      final currentStatus = event.currentStatus;
      final newFavoriteStatus = !currentStatus;

      print(
          "HomeBloc: Toggling favorite for $providerId. Current: $currentStatus -> New: $newFavoriteStatus");

      // *** Use Constants for Firestore Path ***
      final favoriteDocRef = _firestore
          .collection(_usersCollection) // <<< CORRECTED
          .doc(userId)
          .collection(_favoritesSubCollection) // <<< CORRECTED (using constant)
          .doc(providerId);

      try {
        // Perform Firestore Update FIRST
        if (newFavoriteStatus == true) {
          await favoriteDocRef.set({}); // Add to favorites
        } else {
          await favoriteDocRef.delete(); // Remove from favorites
        }
        print(
            "HomeBloc: Firestore favorite status updated successfully using path: ${favoriteDocRef.path}"); // Log path

        // Update Local State IMMUTABLY
        List<ServiceProviderDisplayModel> updateList(
            List<ServiceProviderDisplayModel> list) {
          return list.map((provider) {
            if (provider.id == providerId) {
              print(
                  "HomeBloc(Toggle): Updating provider ${provider.id} in list. OldFav: ${provider.isFavorite}, NewFav: $newFavoriteStatus");
              return provider.copyWith(isFavorite: newFavoriteStatus);
            }
            return provider;
          }).toList();
        }

        // Apply the update to all relevant lists
        final updatedPopular = updateList(currentState.popularProviders);
        final updatedRecommended =
            updateList(currentState.recommendedProviders);
        final updatedOffers = updateList(currentState.offers);
        final updatedNearby = updateList(currentState.nearbyProviders);

        // Emit the new state with ALL updated lists
        emit(currentState.copyWith(
          popularProviders: updatedPopular,
          recommendedProviders: updatedRecommended,
          offers: updatedOffers,
          nearbyProviders: updatedNearby,
        ));
        print(
            "HomeBloc: Emitted updated HomeLoaded state after favorite toggle.");
      } catch (e, s) {
        print(
            "HomeBloc: Error toggling favorite in Firestore for home: $e\n$s");
        // If Firestore update fails, emit an error state and revert
        emit(HomeError(
            message: "Could not update favorite status: ${e.toString()}"));
        await Future.delayed(const Duration(
            milliseconds: 100)); // Allow time for error message display
        emit(currentState); // Re-emit previous state
      }
    } else {
      print(
          "HomeBloc: Cannot toggle favorite - State is not Loaded or user is null.");
    }
  }
}
// --- End of HomeBloc Class ---