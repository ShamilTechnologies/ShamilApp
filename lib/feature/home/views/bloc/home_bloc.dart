import 'dart:async'; // Ensure async is imported
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:geocoding/geocoding.dart'; // Import Geocoding
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:permission_handler/permission_handler.dart' as perm_handler; // Alias for permission_handler
import 'package:meta/meta.dart'; // For @immutable
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// *** Import BOTH models ***
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // Import the detailed model

// Define parts for Bloc library structure
part 'home_event.dart';
part 'home_state.dart';


class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth instance

  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<UpdateCityManually>(_onUpdateCityManually);
    // Register handlers for new events
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchProviders>(_onSearchProviders);
  }

  // Helper function to format the city name (removes "Governorate").
  String _formatCity(String rawCity) {
    // Regex to find "Governorate" potentially surrounded by spaces, case-insensitive
    final regex = RegExp(r'\s*Governorate\s*', caseSensitive: false);
    return rawCity.replaceAll(regex, '').trim(); // Replace and trim whitespace
  }

  // Handles loading initial home data (fetches location, providers, updates Firestore).
  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    // Avoid reloading if already loaded, unless forced (add force parameter to event?)
    // if (state is HomeLoaded && !event.forceReload) return;

    emit(HomeLoading()); // Indicate loading started
    print("HomeBloc: Starting LoadHomeData...");
    try {
      // Ensure user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("HomeBloc: Error - User not logged in during LoadHomeData.");
        throw Exception("User not logged in"); // Throw to be caught below
      }
      print("HomeBloc: User authenticated: ${currentUser.uid}");

      // --- Location Fetching Logic ---
      String city = "Unknown"; // Default city
      Timestamp lastUpdated = Timestamp.now(); // Timestamp for location update

      // 1. Check Location Services Enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If disabled, try fetching last known city from Firestore
        city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Off";
        print("HomeBloc: Location services disabled. Using last known city: $city");
        // Note: Consider emitting a state to inform UI about disabled services
      } else {
        print("HomeBloc: Location services enabled.");
        // 2. Check and Request Location Permissions
        var permissionStatus = await perm_handler.Permission.locationWhenInUse.status;
        print("HomeBloc: Initial Location Permission Status: $permissionStatus");

        // If permission is denied, request it
        if (permissionStatus.isDenied) {
          permissionStatus = await perm_handler.Permission.locationWhenInUse.request();
          print("HomeBloc: Requested Location Permission Status: $permissionStatus");
        }

        // Handle different permission statuses
        if (permissionStatus.isPermanentlyDenied) {
           city = await _fetchLastKnownCity(currentUser.uid) ?? "Permission Denied";
           print("HomeBloc: Location permission permanently denied. Using last known city: $city");
           // TODO: Consider prompting the user to open app settings via UI
        } else if (permissionStatus.isGranted || permissionStatus.isLimited) {
           print("HomeBloc: Location permission granted or limited.");
           // 3. Get Current Position
           try {
             print("HomeBloc: Fetching current position...");
             // Get position with medium accuracy and a timeout
             final Position position = await Geolocator.getCurrentPosition(
                 desiredAccuracy: LocationAccuracy.medium,
                 timeLimit: const Duration(seconds: 10) // Prevent indefinite wait
             );
             print("HomeBloc: Position fetched: Lat ${position.latitude}, Lon ${position.longitude}");

             // 4. Reverse Geocode to get Placemark (City/Governorate)
             List<Placemark> placemarks = await placemarkFromCoordinates(
                 position.latitude, position.longitude);

             if (placemarks.isNotEmpty) {
               final placemark = placemarks.first;
               // Prefer administrativeArea (Governorate in many regions), fallback to locality (City)
               city = placemark.administrativeArea ?? placemark.locality ?? "Unknown";
               city = _formatCity(city); // Format the fetched city name
               print("HomeBloc: City determined from location: $city");

               // 5. Update Firestore with the newly fetched city and timestamp
               lastUpdated = Timestamp.now();
               await _updateCityInFirestore(currentUser.uid, city, lastUpdated);

             } else {
                // If geocoding returns no results, use last known city
                city = await _fetchLastKnownCity(currentUser.uid) ?? "Geocode Failed";
                print("HomeBloc: Placemarks list empty. Using last known city: $city");
             }
           } on TimeoutException {
              // Handle timeout getting location
              city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Timeout";
              print("HomeBloc: Getting location timed out. Using last known city: $city");
           } catch (e) {
              // Handle other location/geocoding errors
              city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Error";
              print("HomeBloc: Error getting location/geocoding: $e. Using last known city: $city");
           }
        } else {
           // Handle other permission statuses (e.g., restricted)
           city = await _fetchLastKnownCity(currentUser.uid) ?? "Permission Issue";
           print("HomeBloc: Unhandled location permission status: $permissionStatus. Using last known city: $city");
        }
      }
      // --- End Location Fetching Logic ---

      // --- Fetch Service Providers ---
      List<ServiceProviderDisplayModel> popularForDisplay = [];
      List<ServiceProviderDisplayModel> recommendedForDisplay = [];

      try {
        print("HomeBloc: Fetching active service providers from Firestore...");
        // Base query: Fetch only active providers from the correct collection
        Query query = _firestore.collection("serviceProviders")
            .where('isActive', isEqualTo: true); // Use 'isActive' field

        // --- Apply City/Governorate Filter ---
        // Determine if the fetched/stored city is valid for filtering
        bool isValidCityForFilter = city != "Unknown" && city != "Location Off" && city != "Permission Denied" && city != "Geocode Failed" && city != "Location Error" && city != "Location Timeout" && city != "Permission Issue";

        if (isValidCityForFilter) {
            print("HomeBloc: Applying governorate filter: $city");
            // Filter using the 'governorate' field inside the 'address' map
            // Ensure Firestore index exists for address.governorate
            query = query.where('address.governorate', isEqualTo: city);
        } else {
            print("HomeBloc: No valid city determined, fetching providers from all locations.");
            // Decide if you want to show *all* providers or none if location fails
            // Current implementation proceeds without city filter if city is invalid.
        }

        // Fetch all matching providers
        final querySnapshot = await query.limit(50).get(); // Limit total fetched initially
        print("HomeBloc: Found ${querySnapshot.docs.length} active providers matching filter.");

        // Deserialize into the *full* ServiceProvider model first
        final allProviders = querySnapshot.docs
            .map((doc) {
                try {
                    // Use the detailed model's factory constructor
                    return ServiceProvider.fromFirestore(doc);
                } catch (e) {
                    print("Error deserializing provider ${doc.id}: $e");
                    return null; // Skip documents that fail deserialization
                }
            })
            .whereType<ServiceProvider>() // Filter out any nulls from failed deserialization
            .toList();

        // --- Logic for Popular/Recommended (Example - Apply in Dart) ---
        // This logic can be customized based on business rules
        // Example: Featured providers are "Popular", others sorted by rating are "Recommended"
        final popularProvidersFull = allProviders.where((p) => p.isFeatured).toList();
        // Optionally sort popular providers further (e.g., by rating)
        popularProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));

        final recommendedProvidersFull = allProviders.where((p) => !p.isFeatured).toList();
        // Sort recommended by rating
        recommendedProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));

        // --- Map to Display Model for UI ---
        // Take top N results and map to the simpler model used by UI cards
        popularForDisplay = popularProvidersFull
            .take(10) // Limit how many are shown in the popular list
            .map((p) => ServiceProviderDisplayModel( // *** Correct Constructor Usage ***
                  id: p.id,
                  businessName: p.businessName,
                  category: p.category,
                  imageUrl: p.mainImageUrl, // Already handles null
                  rating: p.rating,
                  reviewCount: p.ratingCount, // Map ratingCount
                  // Use city from address map, fallback to governorate
                  city: p.address['city'] ?? p.address['governorate'] ?? '',
                ))
            .toList();

        recommendedForDisplay = recommendedProvidersFull
             .take(10) // Limit how many are shown in the recommended list
            .map((p) => ServiceProviderDisplayModel( // *** Correct Constructor Usage ***
                  id: p.id,
                  businessName: p.businessName,
                  category: p.category,
                  imageUrl: p.mainImageUrl,
                  rating: p.rating,
                  reviewCount: p.ratingCount,
                  city: p.address['city'] ?? p.address['governorate'] ?? '',
                ))
            .toList();
         print("HomeBloc: Mapped to ${popularForDisplay.length} popular, ${recommendedForDisplay.length} recommended display models.");

      } catch (e, stacktrace) {
        print("HomeBloc: Error fetching/processing service providers: $e\n$stacktrace");
        // If fetching providers fails, emit error state
        emit(HomeError(message: "Could not load places: ${e.toString()}"));
        return; // Stop processing
      }
      // --- End Fetch Service Providers ---

      // Create HomeModel with the determined city
      final homeModel = HomeModel(
        uid: currentUser.uid,
        city: city, // Use the city determined earlier
        lastUpdatedLocation: lastUpdated,
      );

      // Emit loaded state with fetched data
      emit(HomeLoaded(
        homeModel: homeModel,
        popularProviders: popularForDisplay,
        recommendedProviders: recommendedForDisplay,
      ));
      print("HomeBloc: HomeLoaded emitted successfully.");

    } catch (e, stacktrace) {
      print("HomeBloc: Critical Error in _onLoadHomeData: $e\n$stacktrace");
      // Emit error state if something critical failed (like auth check)
      emit(HomeError(message: "Failed to load home data: ${e.toString()}"));
    }
  }

  // Handles manual city update event (triggered from UI dropdown).
  Future<void> _onUpdateCityManually( UpdateCityManually event, Emitter<HomeState> emit) async {
     final currentState = state;
     // Ensure we have a user before proceeding
     final currentUser = _auth.currentUser;
     if (currentUser == null) {
        print("HomeBloc: Cannot update city manually, user is null.");
        emit(const HomeError(message: "User not logged in.")); // Emit error if user is null
        return;
     }

     final newCity = event.newCity;
     print("HomeBloc: Starting _onUpdateCityManually for city: $newCity");
     emit(HomeLoading()); // Show loading while re-fetching

     try {
        final lastUpdated = Timestamp.now();
        // Update Firestore with the new city
        await _updateCityInFirestore(currentUser.uid, newCity, lastUpdated);

        // --- Re-fetch providers based on the NEW city ---
        print("HomeBloc: Re-fetching providers for manually updated city: $newCity");
        Query query = _firestore.collection("serviceProviders")
            .where('isActive', isEqualTo: true)
            .where('address.governorate', isEqualTo: newCity);

        final querySnapshot = await query.limit(50).get();
        final allProviders = querySnapshot.docs
           .map((doc) { try { return ServiceProvider.fromFirestore(doc); } catch (e) { print("Error deserializing provider ${doc.id}: $e"); return null; } })
           .whereType<ServiceProvider>()
           .toList();

        // Apply same Popular/Recommended logic
        final popularProvidersFull = allProviders.where((p) => p.isFeatured).toList();
        popularProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));
        final recommendedProvidersFull = allProviders.where((p) => !p.isFeatured).toList();
        recommendedProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));

        // Map to Display Model
        final popularForDisplay = popularProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***
        final recommendedForDisplay = recommendedProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***
        // --- End Re-fetch ---

        final updatedHomeModel = HomeModel( uid: currentUser.uid, city: newCity, lastUpdatedLocation: lastUpdated, );
        emit(HomeLoaded( homeModel: updatedHomeModel, popularProviders: popularForDisplay, recommendedProviders: recommendedForDisplay, ));
        print("HomeBloc: HomeLoaded emitted after manual city update: $newCity");
     } catch (e, stacktrace) {
        print("HomeBloc: Error updating city manually or re-fetching: $e\n$stacktrace");
        emit(HomeError(message: "Failed to update city: ${e.toString()}"));
        // if (currentState is HomeLoaded) emit(currentState); // Optionally revert
     }
  }

  // --- Placeholder Handlers for New Events ---

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<HomeState> emit) async {
    print("HomeBloc: FilterByCategory event received for category: ${event.category}");
    final currentState = state;
    if (currentState is HomeLoaded) {
       emit(HomeLoading());
       try {
         print("HomeBloc: Filtering providers for category: ${event.category}");
         Query query = _firestore.collection("serviceProviders")
            .where('isActive', isEqualTo: true)
            .where('address.governorate', isEqualTo: currentState.homeModel.city)
            .where('category', isEqualTo: event.category);

         final querySnapshot = await query.limit(50).get();
         final allProviders = querySnapshot.docs
            .map((doc) { try { return ServiceProvider.fromFirestore(doc); } catch (e) { print("Error deserializing provider ${doc.id}: $e"); return null; } })
            .whereType<ServiceProvider>()
            .toList();

         // Apply same Popular/Recommended logic
         final popularProvidersFull = allProviders.where((p) => p.isFeatured).toList();
         popularProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));
         final recommendedProvidersFull = allProviders.where((p) => !p.isFeatured).toList();
         recommendedProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));

         // Map to Display Model
         final popularForDisplay = popularProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***
         final recommendedForDisplay = recommendedProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***

         emit(HomeLoaded( homeModel: currentState.homeModel, popularProviders: popularForDisplay, recommendedProviders: recommendedForDisplay, ));
         print("HomeBloc: Emitted HomeLoaded with category filter '${event.category}' applied.");

       } catch (e, s) {
          print("HomeBloc: Error filtering by category: $e\n$s");
          emit(HomeError(message: "Failed to filter by category: ${e.toString()}"));
          emit(currentState); // Re-emit previous state on error
       }
    } else { print("HomeBloc: Cannot filter by category, state is not HomeLoaded."); }
  }

  Future<void> _onSearchProviders(SearchProviders event, Emitter<HomeState> emit) async {
    print("HomeBloc: SearchProviders event received for query: ${event.query}");
     final currentState = state;
     final searchQuery = event.query.trim();
     if (searchQuery.isEmpty) { add(LoadHomeData()); return; }

    if (currentState is HomeLoaded) {
       emit(HomeLoading());
       try {
         print("HomeBloc: Searching providers for query: ${searchQuery}");
         Query query = _firestore.collection("serviceProviders")
            .where('isActive', isEqualTo: true)
            .where('address.governorate', isEqualTo: currentState.homeModel.city)
            .where('businessName', isGreaterThanOrEqualTo: searchQuery)
            .where('businessName', isLessThanOrEqualTo: '$searchQuery\uf8ff');

         final querySnapshot = await query.limit(20).get();
         final allProviders = querySnapshot.docs
            .map((doc) { try { return ServiceProvider.fromFirestore(doc); } catch (e) { print("Error deserializing provider ${doc.id}: $e"); return null; } })
            .whereType<ServiceProvider>()
            .toList();

         // Apply same Popular/Recommended logic TO SEARCH RESULTS
         final popularProvidersFull = allProviders.where((p) => p.isFeatured).toList();
         popularProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));
         final recommendedProvidersFull = allProviders.where((p) => !p.isFeatured).toList();
         recommendedProvidersFull.sort((a, b) => b.rating.compareTo(a.rating));

         // Map to Display Model
         final popularForDisplay = popularProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***
         final recommendedForDisplay = recommendedProvidersFull.take(10).map((p) => ServiceProviderDisplayModel( id: p.id, businessName: p.businessName, category: p.category, imageUrl: p.mainImageUrl, rating: p.rating, reviewCount: p.ratingCount, city: p.city ?? p.governorate ?? '', )).toList(); // *** Correct Constructor Usage ***

         emit(HomeLoaded( homeModel: currentState.homeModel, popularProviders: popularForDisplay, recommendedProviders: recommendedForDisplay, ));
         print("HomeBloc: Emitted HomeLoaded with search results for '${event.query}'.");

       } catch (e, s) {
          print("HomeBloc: Error searching providers: $e\n$s");
          emit(HomeError(message: "Failed to search providers: ${e.toString()}"));
          emit(currentState); // Re-emit previous state on error
       }
    } else { print("HomeBloc: Cannot search providers, state is not HomeLoaded."); }
  }


  // Helper to fetch the last known city from Firestore.
  Future<String?> _fetchLastKnownCity(String uid) async {
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

   // Helper to update Firestore (used by both automatic and manual updates).
  Future<void> _updateCityInFirestore(String uid, String city, Timestamp timestamp) async {
    try {
       await _firestore
           .collection("endUsers")
           .doc(uid)
           .set({ 'city': city, 'lastUpdatedLocation': timestamp, }, SetOptions(merge: true));
       print("HomeBloc: User city updated/set in Firestore to: $city at $timestamp for UID $uid");
    } catch (e) {
       print("HomeBloc: Error updating/setting city in Firestore for UID $uid: $e");
    }
  }
}
