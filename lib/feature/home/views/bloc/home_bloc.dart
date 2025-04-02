import 'dart:async'; // Ensure async is imported
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler; // Alias for permission_handler
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';
// Import the display model and state/event parts
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
part 'home_event.dart';
part 'home_state.dart';


class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance; // Auth instance

  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<UpdateCityManually>(_onUpdateCityManually); // Handle manual city update
  }

  // Helper function to format the city name (removes "Governorate").
  String _formatCity(String rawCity) {
    final regex = RegExp(r'\s*Governorate\s*', caseSensitive: false);
    return rawCity.replaceAll(regex, '').trim();
  }

  // Handles loading initial home data (fetches location, providers, updates Firestore).
  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    print("HomeBloc: Starting LoadHomeData...");
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("HomeBloc: Error - User not logged in during LoadHomeData.");
        throw Exception("User not logged in");
      }
      print("HomeBloc: User authenticated: ${currentUser.uid}");

      // --- Location Fetching Logic ---
      String city = "Unknown"; // Default city
      Timestamp lastUpdated = Timestamp.now();

      // 1. Check Location Services Enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Off";
        print("HomeBloc: Location services disabled. Using last known city: $city");
        // Optionally emit a specific state or show a message to the user
        // emit(HomeError(message: "Please enable location services."));
        // return; // Or continue with last known city / default
      } else {
        print("HomeBloc: Location services enabled.");
        // 2. Check and Request Location Permissions
        var permissionStatus = await perm_handler.Permission.locationWhenInUse.status;
        print("HomeBloc: Initial Location Permission Status: $permissionStatus");

        if (permissionStatus.isDenied) {
          permissionStatus = await perm_handler.Permission.locationWhenInUse.request();
          print("HomeBloc: Requested Location Permission Status: $permissionStatus");
        }

        if (permissionStatus.isPermanentlyDenied) {
           city = await _fetchLastKnownCity(currentUser.uid) ?? "Permission Denied";
           print("HomeBloc: Location permission permanently denied. Using last known city: $city");
           // TODO: Consider prompting the user to open app settings
        } else if (permissionStatus.isGranted || permissionStatus.isLimited) {
            print("HomeBloc: Location permission granted or limited.");
            // 3. Get Current Position
            try {
              print("HomeBloc: Fetching current position...");
              final Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.medium, // Medium accuracy is often sufficient and faster
                  timeLimit: const Duration(seconds: 10) // Add a timeout
              );
              print("HomeBloc: Position fetched: Lat ${position.latitude}, Lon ${position.longitude}");

              // 4. Reverse Geocode to get Placemark
              List<Placemark> placemarks = await placemarkFromCoordinates(
                  position.latitude, position.longitude);

              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                // Use administrativeArea (Governorate/State) or locality (City)
                city = placemark.administrativeArea ?? placemark.locality ?? "Unknown";
                city = _formatCity(city); // Format the fetched city name
                print("HomeBloc: City determined from location: $city");

                // 5. Update Firestore with the fetched city (only if different from last known?)
                // Consider checking if the city actually changed before updating Firestore
                lastUpdated = Timestamp.now();
                await _updateCityInFirestore(currentUser.uid, city, lastUpdated);

              } else {
                 city = await _fetchLastKnownCity(currentUser.uid) ?? "Geocode Failed";
                 print("HomeBloc: Placemarks list empty. Using last known city: $city");
              }
            } on TimeoutException {
               city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Timeout";
               print("HomeBloc: Getting location timed out. Using last known city: $city");
            } catch (e) {
               city = await _fetchLastKnownCity(currentUser.uid) ?? "Location Error";
               print("HomeBloc: Error getting location/geocoding: $e. Using last known city: $city");
            }
        } else {
           // Handle other permission statuses if necessary (e.g., restricted)
           city = await _fetchLastKnownCity(currentUser.uid) ?? "Permission Issue";
           print("HomeBloc: Unhandled location permission status: $permissionStatus. Using last known city: $city");
        }
      }
      // --- End Location Fetching Logic ---

      // --- Fetch Service Providers ---
      List<ServiceProviderDisplayModel> popular = [];
      List<ServiceProviderDisplayModel> recommended = [];

      try {
        print("HomeBloc: Fetching service providers from Firestore...");
        // Base query: Fetch only published/active providers
        // *** Adjust 'isPublished' field name if needed ***
        Query query = _firestore.collection("serviceProviders")
                         .where('isPublished', isEqualTo: true);

        // Filter by city if a valid city is determined and not 'Unknown' etc.
        bool isValidCity = city != "Unknown" && city != "Location Off" && city != "Permission Denied" && city != "Geocode Failed" && city != "Location Error" && city != "Location Timeout" && city != "Permission Issue";

        if (isValidCity) {
             print("HomeBloc: Applying city filter: $city");
             // *** Adjust 'city' field name if needed ***
             query = query.where('city', isEqualTo: city);
        } else {
            print("HomeBloc: No valid city determined, fetching providers from all cities (or none based on requirements).");
            // If you DON'T want to show anything when location fails, you could stop here or return empty lists.
            // For now, it proceeds without the city filter.
        }


        // Fetch Popular (e.g., order by rating descending, limit results)
        // *** Adjust 'averageRating' field name and logic as needed ***
        final popularSnapshot = await query
                                     .orderBy('averageRating', descending: true)
                                     .limit(10) // Limit popular results
                                     .get();

        popular = popularSnapshot.docs
            .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc))
            .toList();
        print("HomeBloc: Fetched ${popular.length} popular providers.");

        // Fetch Recommended (e.g., order by creation date or another metric, limit results)
        // *** Adjust 'createdAt' field name and logic as needed ***
         final recommendedSnapshot = await query
                                     .orderBy('createdAt', descending: true) // Example: newest first
                                     .limit(10) // Limit recommended results
                                     .get();

         recommended = recommendedSnapshot.docs
            .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc))
            // Example: Simple filter to avoid showing the exact same items in both lists if overlap occurs
            .where((rec) => !popular.any((pop) => pop.id == rec.id))
            .take(10) // Ensure we don't exceed the limit after filtering
            .toList();

        print("HomeBloc: Fetched ${recommended.length} recommended providers (after filtering duplicates).");


      } catch (e, stacktrace) {
        print("HomeBloc: Error fetching service providers: $e\n$stacktrace");
        // Don't throw, allow state emission with empty lists but log error
        // Optionally emit HomeError here if fetching providers is critical
        // emit(HomeError(message: "Could not load places: ${e.toString()}"));
        // return;
      }
      // --- End Fetch Service Providers ---


      // Create HomeModel with the determined city
      final homeModel = HomeModel(
        uid: currentUser.uid,
        city: city,
        lastUpdatedLocation: lastUpdated, // Use the timestamp from when location was fetched/updated
      );

      // Emit loaded state with fetched data
      emit(HomeLoaded(
        homeModel: homeModel,
        popularProviders: popular,
        recommendedProviders: recommended,
      ));
      print("HomeBloc: HomeLoaded emitted with city: ${homeModel.city} and ${popular.length} popular, ${recommended.length} recommended providers.");

    } catch (e, stacktrace) {
      print("HomeBloc: Critical Error in _onLoadHomeData: $e\n$stacktrace");
      // Emit error state if something critical failed (like auth check or initial location setup)
      emit(HomeError(message: "Failed to load home data: ${e.toString()}"));
    }
  }

   // Handles manual city update event (triggered from UI dropdown).
  Future<void> _onUpdateCityManually(UpdateCityManually event, Emitter<HomeState> emit) async {
     final currentState = state;
     // Ensure we have a user and current data before proceeding
     if (currentState is HomeLoaded && _auth.currentUser != null) {
        final currentUser = _auth.currentUser!;
        final currentHomeModel = currentState.homeModel;
        final newCity = event.newCity;
        print("HomeBloc: Starting _onUpdateCityManually for city: $newCity");

        // Show loading state while re-fetching
        emit(HomeLoading());

        try {
            final lastUpdated = Timestamp.now();
            // Update Firestore with the new city
            await _updateCityInFirestore(currentUser.uid, newCity, lastUpdated);

            // --- Re-fetch providers based on the NEW city ---
            List<ServiceProviderDisplayModel> popular = [];
            List<ServiceProviderDisplayModel> recommended = [];
            try {
                print("HomeBloc: Re-fetching providers for manually updated city: $newCity");
                 // *** Adjust field names and logic as needed ***
                 Query query = _firestore.collection("serviceProviders")
                                   .where('isApproved', isEqualTo: true)
                                   .where('city', isEqualTo: newCity); // Filter by new city

                final popularSnapshot = await query
                                   .orderBy('averageRating', descending: true)
                                   .limit(10).get();
                popular = popularSnapshot.docs.map((doc) => ServiceProviderDisplayModel.fromFirestore(doc)).toList();

                final recommendedSnapshot = await query
                                   .orderBy('createdAt', descending: true)
                                   .limit(10).get();
                recommended = recommendedSnapshot.docs
                                   .map((doc) => ServiceProviderDisplayModel.fromFirestore(doc))
                                   .where((rec) => !popular.any((pop) => pop.id == rec.id))
                                   .take(10)
                                   .toList();
                 print("HomeBloc: Re-fetched ${popular.length} popular, ${recommended.length} recommended providers for $newCity.");
            } catch (e, stacktrace) {
               print("HomeBloc: Error re-fetching providers after manual city update: $e\n$stacktrace");
               // Emit error or continue with empty lists? Let's continue with empty lists for now.
            }
            // --- End Re-fetch ---


            // Create updated HomeModel
            final updatedHomeModel = HomeModel(
               uid: currentUser.uid,
               city: newCity,
               lastUpdatedLocation: lastUpdated,
            );
            // Emit new loaded state with updated city and re-fetched providers
            emit(HomeLoaded(
                homeModel: updatedHomeModel,
                popularProviders: popular,
                recommendedProviders: recommended,
            ));
             print("HomeBloc: HomeLoaded emitted after manual city update: $newCity");
         } catch (e, stacktrace) {
            print("HomeBloc: Error updating city manually: $e\n$stacktrace");
            // Emit error state, potentially reverting to previous loaded state?
            // Or just show a generic error.
            emit(HomeError(message: "Failed to update city: ${e.toString()}"));
            // Optionally re-emit the previous state if available:
            // emit(currentState);
         }
     } else {
        // If state is not HomeLoaded or user is null, trigger a full reload
        print("HomeBloc: Cannot update city manually, current state is not HomeLoaded or user is null. Triggering full reload.");
        add(LoadHomeData());
     }
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
              .set({ // Use set with merge:true to create if not exists, or update
            'city': city,
            'lastUpdatedLocation': timestamp, // Use provided timestamp
          }, SetOptions(merge: true)); // Merge ensures other fields aren't overwritten
        print("HomeBloc: User city updated/set in Firestore to: $city at $timestamp for UID $uid");
    } catch (e) {
       print("HomeBloc: Error updating/setting city in Firestore for UID $uid: $e");
       // Consider how to handle this error - maybe retry? For now, just log.
    }
  }
}
