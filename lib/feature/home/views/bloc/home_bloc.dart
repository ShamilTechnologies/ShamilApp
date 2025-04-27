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
      final doc = await _firestore.collection("endUsers").doc(uid).get();
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
      await _firestore.collection("endUsers").doc(uid).set({
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
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get(const GetOptions(source: Source.cache));
      print(
          "HomeBloc: Fetched ${snapshot.docs.length} favorite IDs for $userId from cache/server.");
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
    // ... (Full implementation as provided previously, ensures helpers are called) ...
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
      try {
        final Set<String> favoriteIds = await _fetchUserFavoriteIds(userId);
        Query query = _firestore
            .collection("serviceProviders")
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
        popularForDisplay = popularProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        recommendedForDisplay = recommendedProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
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
          recommendedProviders: recommendedForDisplay));
      print("HomeBloc: HomeLoaded emitted successfully.");
    } catch (e, stacktrace) {
      print("HomeBloc: Critical Error in _onLoadHomeData: $e\n$stacktrace");
      emit(HomeError(message: "Failed to load home data: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateCityManually(
      UpdateCityManually event, Emitter<HomeState> emit) async {
    // ... (Full implementation as provided previously, ensures helpers are called) ...
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(const HomeError(message: "User not logged in."));
      return;
    }
    final userId = currentUser.uid;
    final newCity = event.newCity;
    print("HomeBloc: Starting _onUpdateCityManually for city: $newCity");
    emit(HomeLoading());
    try {
      final lastUpdated = Timestamp.now();
      await _updateCityInFirestore(userId, newCity, lastUpdated);
      final Set<String> favoriteIds =
          await _fetchUserFavoriteIds(userId); // Fetch favorites
      Query query = _firestore
          .collection("serviceProviders")
          .where('isActive', isEqualTo: true)
          .where('address.governorate', isEqualTo: newCity);
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
      // Map using helper
      final popularForDisplay = popularProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList();
      final recommendedForDisplay = recommendedProvidersFull
          .take(10)
          .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
          .toList();
      final updatedHomeModel = HomeModel(
        uid: userId,
        city: newCity,
        lastUpdatedLocation: lastUpdated,
      );
      emit(HomeLoaded(
        homeModel: updatedHomeModel,
        popularProviders: popularForDisplay,
        recommendedProviders: recommendedForDisplay,
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
    // ... (Full implementation as provided previously, ensures helpers are called) ...
    print(
        "HomeBloc: FilterByCategory event received for category: ${event.category}");
    final currentState = state;
    final currentUser = _auth.currentUser;
    if (currentState is HomeLoaded && currentUser != null) {
      final userId = currentUser.uid;
      emit(HomeLoading());
      try {
        final Set<String> favoriteIds =
            await _fetchUserFavoriteIds(userId); // Fetch favorites
        Query query = _firestore
            .collection("serviceProviders")
            .where('isActive', isEqualTo: true)
            .where('address.governorate',
                isEqualTo: currentState.homeModel.city)
            .where('businessCategory',
                isEqualTo: event.category); // Use correct field name
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
        // Map using helper
        final popularForDisplay = popularProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        final recommendedForDisplay = recommendedProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        emit(HomeLoaded(
          homeModel: currentState.homeModel,
          popularProviders: popularForDisplay,
          recommendedProviders: recommendedForDisplay,
        ));
        print(
            "HomeBloc: Emitted HomeLoaded with category filter '${event.category}' applied.");
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
    // ... (Full implementation as provided previously, ensures helpers are called) ...
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
      emit(HomeLoading());
      try {
        final Set<String> favoriteIds =
            await _fetchUserFavoriteIds(userId); // Fetch favorites
        Query query = _firestore
            .collection("serviceProviders")
            .where('isActive', isEqualTo: true)
            .where('address.governorate',
                isEqualTo: currentState.homeModel.city)
            .where('businessName', isGreaterThanOrEqualTo: searchQuery)
            .where('businessName',
                isLessThanOrEqualTo:
                    '$searchQuery\uf8ff'); // \uf8ff is a high code point for prefix matching
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
        final popularProvidersFull = allProviders
            .where((p) => p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final recommendedProvidersFull = allProviders
            .where((p) => !p.isFeatured)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        // Map using helper
        final popularForDisplay = popularProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        final recommendedForDisplay = recommendedProvidersFull
            .take(10)
            .map((p) => _mapProviderToDisplayModel(p, favoriteIds))
            .toList();
        emit(HomeLoaded(
          homeModel: currentState.homeModel,
          popularProviders: popularForDisplay,
          recommendedProviders: recommendedForDisplay,
        ));
        print(
            "HomeBloc: Emitted HomeLoaded with search results for '${event.query}'.");
      } catch (e, s) {
        print("HomeBloc: Error searching providers: $e\n$s");
        emit(HomeError(message: "Failed to search providers: ${e.toString()}"));
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

      // *** ADD LOGGING HERE to check state *before* mapping/copyWith ***
      ServiceProviderDisplayModel? providerBeingToggled;
      providerBeingToggled = currentState.popularProviders
          .firstWhereOrNull((p) => p.id == providerId);
      providerBeingToggled ??= currentState.recommendedProviders
          .firstWhereOrNull((p) => p.id == providerId);

      if (providerBeingToggled != null) {
        print(
            "HomeBloc(Toggle-DEBUG): Found provider in currentState. ImageUrl = '${providerBeingToggled.imageUrl}', isFavorite = ${providerBeingToggled.isFavorite}");
      } else {
        print(
            "HomeBloc(Toggle-DEBUG): Provider $providerId NOT FOUND in currentState lists before update.");
      }
      // *********************************************************************

      final favoriteDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(providerId);
      try {
        // Firestore Update First
        if (newFavoriteStatus == true) {
          await favoriteDocRef.set({});
        } else {
          await favoriteDocRef.delete();
        }
        print("HomeBloc: Firestore favorite status updated successfully.");

        // Update Local State IMMUTABLY
        ServiceProviderDisplayModel?
            updatedProviderCheck; // For logging after update

        final updatedPopular = currentState.popularProviders.map((provider) {
          if (provider.id == providerId) {
            final updated = provider.copyWith(isFavorite: newFavoriteStatus);
            updatedProviderCheck = updated; // Store for logging
            return updated;
          }
          return provider;
        }).toList();

        final updatedRecommended =
            currentState.recommendedProviders.map((provider) {
          if (provider.id == providerId) {
            final updated = provider.copyWith(isFavorite: newFavoriteStatus);
            updatedProviderCheck ??= updated; // Store if not found in popular
            return updated;
          }
          return provider;
        }).toList();

        // Log the state *after* copyWith but before emitting
        if (updatedProviderCheck != null) {
          print(
              "HomeBloc(Toggle): Provider data **before emitting** new state: ID=${updatedProviderCheck!.id}, Name=${updatedProviderCheck!.businessName}, ImageUrl=${updatedProviderCheck!.imageUrl}, IsFavorite=${updatedProviderCheck!.isFavorite}");
        } else {
          print(
              "HomeBloc(Toggle): Provider with ID $providerId not found during update mapping.");
        }

        // Emit the new state with the updated lists
        emit(currentState.copyWith(
          popularProviders: updatedPopular,
          recommendedProviders: updatedRecommended,
        ));
        print(
            "HomeBloc: Emitted updated HomeLoaded state after favorite toggle.");
      } catch (e, s) {
        print(
            "HomeBloc: Error toggling favorite in Firestore for home: $e\n$s");
        // Don't change state if Firestore fails
      }
    } else {
      print(
          "HomeBloc: Cannot toggle favorite - State is not Loaded or user is null.");
    }
  }
}
