// lib/feature/home/views/bloc/home_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart'; // Not explicitly used in the provided snippet, but often needed with geolocator
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

// Models
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// --- NEW: Import business categories ---
// Assuming this file exists in your project structure:
// import 'package:shamil_mobile_app/core/constants/business_categories.dart';

// Import the data orchestrator
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

part 'home_event.dart'; // Defines HomeEvent and its subclasses
part 'home_state.dart'; // Defines HomeState and its subclasses (HomeInitial, HomeLoading, HomeDataLoaded, HomeError)

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _bannersCollection = 'banners';
  static const String _serviceProvidersCollection = 'serviceProviders';
  static const String _usersCollection =
      'endUsers'; // Assuming 'endUsers' is the correct collection name
  static const String _favoritesSubCollection = 'favorites';
  static const String _defaultCity = 'Cairo'; // Default city
  static const String _cityPrefKey = 'selectedCity';

  HomeBloc({required FirebaseDataOrchestrator dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator,
        super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<UpdateCityManually>(_onUpdateCityManually);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterBySubCategory>(_onFilterBySubCategory);
    on<SearchProviders>(_onSearchProviders);
    on<ToggleFavoriteHome>(_onToggleFavoriteHome);

    // Automatically load data when the BLoC is created if it's in the initial state.
    // This ensures data is fetched when the app starts or this screen is first visited.
    if (state is HomeInitial) {
      add(const LoadHomeData()); // isRefresh defaults to false
    }
  }

  /// Gets the current Firebase User ID. Returns null if no user is logged in.
  String? get _userId => _auth.currentUser?.uid;

  /// Retrieves the initial city to load data for.
  /// It prioritizes:
  /// 1. City stored in SharedPreferences.
  /// 2. City determined from the device's current location via geocoding.
  /// 3. A default city if the above methods fail or permissions are denied.
  Future<String> _getInitialCity() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedCity = prefs.getString(_cityPrefKey);

    if (storedCity != null && storedCity.isNotEmpty) {
      print("HomeBloc: Found stored city: $storedCity");
      return storedCity;
    }

    // --- Location & Geocoding Logic ---
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("HomeBloc: Location services disabled. Using default city.");
        return _defaultCity;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("HomeBloc: Location permission denied. Using default city.");
          return _defaultCity;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            "HomeBloc: Location permission denied forever. Using default city.");
        return _defaultCity;
      }

      print("HomeBloc: Fetching current position...");
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy
              .low, // Using low accuracy for city-level is fine and faster
          timeLimit:
              const Duration(seconds: 15) // Timeout for location fetching
          );
      print(
          "HomeBloc: Fetched position: ${position.latitude}, ${position.longitude}");

      print("HomeBloc: Performing geocoding...");
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        // .locality often gives the city name.
        // .administrativeArea might give governorate/state.
        String? fetchedCity = placemarks.first.locality;
        String? fetchedGovernorate = placemarks.first.administrativeArea;

        print(
            "HomeBloc: Geocoding result - City: $fetchedCity, Governorate: $fetchedGovernorate");

        // Prefer governorate if available and seems like a city name, otherwise use locality.
        String? cityOrGov = fetchedGovernorate?.isNotEmpty == true
            ? fetchedGovernorate
            : fetchedCity;

        if (cityOrGov != null && cityOrGov.isNotEmpty) {
          print("HomeBloc: Using '$cityOrGov' from geocoding.");
          await _storeSelectedCity(cityOrGov);
          return cityOrGov;
        } else {
          print(
              "HomeBloc: Geocoding succeeded but couldn't extract city/governorate. Using default.");
          return _defaultCity;
        }
      } else {
        print(
            "HomeBloc: Geocoding returned no placemarks. Using default city.");
        return _defaultCity;
      }
    } catch (e) {
      print(
          "HomeBloc: Error getting location or geocoding: $e. Using default city.");
      if (e is TimeoutException) {
        print("HomeBloc: Getting location timed out. Using default city.");
      }
      return _defaultCity;
    }
    // --- End Location & Geocoding Logic ---
  }

  /// Stores the selected city in SharedPreferences for persistence.
  Future<void> _storeSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPrefKey, city);
    print("HomeBloc: Stored selected city: $city");
  }

  /// Handles the [LoadHomeData] event.
  /// Fetches initial data like banners and nearby service providers for the determined city.
  /// Supports refresh functionality.
  Future<void> _onLoadHomeData(
      LoadHomeData event, Emitter<HomeState> emit) async {
    String cityToLoad = _defaultCity;
    bool isInitialLoad =
        true; // True if this is the very first load or a full refresh
    HomeDataLoaded? previousStateData;

    if (state is HomeDataLoaded) {
      previousStateData = state as HomeDataLoaded;
      if (!event.isRefresh) {
        // If not a refresh, use current city if available
        cityToLoad = previousStateData.selectedCity ?? await _getInitialCity();
        isInitialLoad =
            false; // Not an initial load if we already have data and not refreshing
      } else {
        // Is a refresh
        cityToLoad =
            await _getInitialCity(); // For refresh, re-evaluate city (e.g. location might have changed)
      }
    } else {
      // HomeInitial or HomeError state
      cityToLoad = await _getInitialCity();
    }

    // Determine if a full-screen shimmer/loader should be shown
    bool showFullScreenShimmer =
        event.isRefresh || isInitialLoad || previousStateData == null;
    emit(HomeLoading(
        isInitialLoading: showFullScreenShimmer,
        previousState: previousStateData));
    print(
        "HomeBloc: Loading home data for city: $cityToLoad. IsRefresh: ${event.isRefresh}, ShowFullScreenShimmer: $showFullScreenShimmer");

    try {
      // Check available cities for debugging
      final availableCities = await _dataOrchestrator.getAvailableCities();
      print("HomeBloc: Available cities in database: $availableCities");

      if (availableCities.isNotEmpty && !availableCities.contains(cityToLoad)) {
        print(
            "HomeBloc: City '$cityToLoad' not found in database. Available cities: $availableCities");
        print(
            "HomeBloc: Consider using one of these cities: ${availableCities.take(3).join(', ')}");

        // Try to find a smart match for the chosen location
        final bestMatch =
            await _dataOrchestrator.findBestLocationMatch(cityToLoad);
        if (bestMatch != null) {
          print("HomeBloc: Found best match for '$cityToLoad': '$bestMatch'");
          cityToLoad = bestMatch;
          await _storeSelectedCity(cityToLoad);
        } else if (!event.isRefresh && availableCities.isNotEmpty) {
          // If no match found and this is an initial load, use the first available city
          print(
              "HomeBloc: No match found. Auto-switching to available city: ${availableCities.first}");
          cityToLoad = availableCities.first;
          await _storeSelectedCity(cityToLoad);
        }
      }

      // Use the data orchestrator to fetch service providers
      final nearbyPlaces = await _dataOrchestrator.getServiceProviders(
        city: cityToLoad,
        limit: 20,
      );

      // Fetch banners
      final banners = await _dataOrchestrator.getBanners();

      final homeData = HomeData(
        banners: banners,
        nearbyPlaces: nearbyPlaces,
        popularPlaces: [], // Will be implemented later
        recommendedPlaces: [], // Will be implemented later
      );

      // Check if we have providers for the selected location
      if (nearbyPlaces.isEmpty && availableCities.isNotEmpty) {
        print(
            "HomeBloc: No providers found for '$cityToLoad'. Available cities: $availableCities");
      }

      emit(HomeDataLoaded(
        homeData: homeData,
        selectedCity: cityToLoad,
        filteredByCategory: null,
        selectedSubCategory: null,
        searchQuery: null,
      ));
    } catch (e) {
      print("HomeBloc: Error loading home data: $e");
      emit(HomeError(
        message: "Failed to load home data: ${e.toString()}",
        isInitialError: showFullScreenShimmer,
        previousState: previousStateData,
      ));
    }
  }

  /// Handles the [UpdateCityManually] event.
  /// Stores the new city and reloads home data for that city.
  Future<void> _onUpdateCityManually(
      UpdateCityManually event, Emitter<HomeState> emit) async {
    await _storeSelectedCity(event.selectedCity);
    // Trigger a refresh with the new city context
    add(const LoadHomeData(isRefresh: true));
  }

  /// Handles the [FilterByCategory] event.
  /// Fetches service providers based on the selected main category.
  /// If "All" or an empty category is selected, it effectively clears the filter
  /// and shows default (e.g., nearby) providers.
  Future<void> _onFilterByCategory(
      FilterByCategory event, Emitter<HomeState> emit) async {
    final currentState = state;
    String city = _defaultCity;
    HomeData? currentHomeData;
    HomeDataLoaded? previousStateData;

    if (currentState is HomeDataLoaded) {
      city = currentState.selectedCity ?? _defaultCity;
      currentHomeData = currentState.homeData;
      previousStateData = currentState;
      // Emit loading state, but not as initial loading if data already exists
      emit(HomeLoading(isInitialLoading: false, previousState: currentState));
    } else {
      // Should ideally not happen if LoadHomeData is called first, but handle defensively
      emit(const HomeLoading(isInitialLoading: true, previousState: null));
      city = await _getInitialCity(); // Determine city if not already loaded
    }

    final bool isClearingFilter =
        event.category.isEmpty || event.category.toLowerCase() == "all";
    final String categoryToFilter = isClearingFilter ? "" : event.category;

    print(
        "HomeBloc: Filtering by category '$categoryToFilter' in city '$city'.");

    try {
      final List<ServiceProviderDisplayModel> filteredProviders;
      if (isClearingFilter) {
        // If clearing filter, fetch default "nearby" providers for the current city
        filteredProviders = await _dataOrchestrator.getServiceProviders(
          city: city,
          limit: 20,
        );
      } else {
        // Fetch by specific main category
        filteredProviders =
            await _dataOrchestrator.getServiceProvidersByCategory(
                categoryToFilter, city, null); // subCategory is null
      }

      // Use copyWith on existing homeData if available, otherwise create new
      final updatedHomeData = currentHomeData?.copyWith(
            categoryFilteredResults: filteredProviders,
            // When clearing main filter, nearbyPlaces might become the categoryFilteredResults
            nearbyPlaces: isClearingFilter
                ? filteredProviders
                : currentHomeData.nearbyPlaces,
            searchResults: [], // Clear search results when applying category filter
            clearSearchResults: true, // Ensure search list is cleared
          ) ??
          HomeData(
            // Fallback if currentHomeData was null (e.g., error state previously)
            banners: await _dataOrchestrator
                .getBanners(), // Re-fetch banners if no current data
            nearbyPlaces: filteredProviders,
            categoryFilteredResults: filteredProviders,
          );

      emit(HomeDataLoaded(
        homeData: updatedHomeData,
        selectedCity: city,
        filteredByCategory: isClearingFilter
            ? null
            : categoryToFilter, // Set/clear main category
        selectedSubCategory:
            null, // Always clear sub-category when main category changes
        searchQuery: null, // Clear search query
      ));
      print(
          "HomeBloc: Filtered by category '${categoryToFilter.isNotEmpty ? categoryToFilter : 'All'}' successfully.");
    } catch (e) {
      print("HomeBloc: Error filtering by category: $e");
      emit(HomeError(
          message: "Failed to filter by category: ${e.toString()}",
          isInitialError: currentHomeData == null,
          previousState: previousStateData));
    }
  }

  /// Handles the [FilterBySubCategory] event.
  /// Fetches service providers based on the selected main and sub-category.
  /// If "All" sub-category is selected, it filters by the main category only.
  Future<void> _onFilterBySubCategory(
      FilterBySubCategory event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is! HomeDataLoaded) {
      print(
          "HomeBloc: Cannot filter by sub-category, initial data not loaded.");
      // Optionally emit an error or just return if state is not HomeDataLoaded
      emit(const HomeError(
          message: "Please load initial data before filtering.",
          isInitialError: false,
          previousState: null));
      return;
    }

    final city = currentState.selectedCity ?? _defaultCity;
    final mainCategory =
        event.mainCategory; // This should be the currently active main category
    final subCategory = event.subCategory;
    final bool isSelectingAllSub = subCategory.toLowerCase() == "all";

    print(
        "HomeBloc: Filtering by SubCategory '$subCategory' (Main: '$mainCategory') in city '$city'.");
    emit(HomeLoading(
        isInitialLoading: false,
        previousState: currentState)); // Show loading indicator

    try {
      // Fetch providers filtered by main category AND sub-category (if not "All")
      final filteredProviders =
          await _dataOrchestrator.getServiceProvidersByCategory(
        mainCategory,
        city,
        isSelectingAllSub
            ? null
            : subCategory, // Pass null if "All" sub-category to fetch all for main category
      );

      emit(currentState.copyWith(
        // Use HomeDataLoaded.copyWith
        homeData: currentState.homeData.copyWith(
          categoryFilteredResults: filteredProviders,
          searchResults: [], // Clear search results when applying sub-category filter
          clearSearchResults: true,
        ),
        filteredByCategory: mainCategory, // Keep main category filter active
        selectedSubCategory: isSelectingAllSub
            ? null
            : subCategory, // Set or clear sub-category filter
        searchQuery: null, // Clear search query
        // The clear flags in HomeDataLoaded.copyWith will handle list clearing in HomeData
      ));
      print("HomeBloc: Filtered by sub-category '$subCategory' successfully.");
    } catch (e) {
      print("HomeBloc: Error filtering by sub-category: $e");
      emit(HomeError(
          message: "Failed to filter by sub-category: ${e.toString()}",
          isInitialError: false,
          previousState: currentState));
    }
  }

  /// Handles the [SearchProviders] event.
  /// Fetches service providers based on a search query.
  /// Clears any active category/sub-category filters.
  Future<void> _onSearchProviders(
      SearchProviders event, Emitter<HomeState> emit) async {
    final currentState = state;
    String city = _defaultCity;
    HomeData? currentHomeData;
    HomeDataLoaded? previousStateData;

    if (currentState is HomeDataLoaded) {
      city = currentState.selectedCity ?? _defaultCity;
      currentHomeData = currentState.homeData;
      previousStateData = currentState;
      emit(HomeLoading(isInitialLoading: false, previousState: currentState));
    } else {
      emit(const HomeLoading(isInitialLoading: true, previousState: null));
      city = await _getInitialCity();
    }
    print("HomeBloc: Searching for '${event.query}' in city '$city'.");

    try {
      final List<ServiceProviderDisplayModel> searchResults;
      if (event.query.trim().isEmpty) {
        // If search query is empty, show nearby places (or clear results based on UX)
        searchResults = await _dataOrchestrator.getServiceProviders(
          city: city,
          limit: 20,
        );
      } else {
        // Perform search query
        searchResults = await _dataOrchestrator.getServiceProvidersByQuery(
            query: event.query, city: city, category: null, subCategory: null);
      }

      final updatedHomeData = currentHomeData?.copyWith(
            searchResults: searchResults,
            // If query is empty, nearbyPlaces are the searchResults. Otherwise, keep existing nearby.
            nearbyPlaces: event.query.trim().isEmpty
                ? searchResults
                : currentHomeData.nearbyPlaces,
            categoryFilteredResults: [], // Clear category results
            clearCategoryFilteredResults: true,
          ) ??
          HomeData(
            // Fallback
            banners: currentHomeData?.banners ??
                await _dataOrchestrator.getBanners(),
            nearbyPlaces: searchResults, // If query empty, these are nearby
            searchResults: searchResults,
          );

      emit(HomeDataLoaded(
        homeData: updatedHomeData,
        selectedCity: city,
        searchQuery: event.query.trim().isEmpty ? null : event.query.trim(),
        filteredByCategory: null, // Clear category filter
        selectedSubCategory: null, // Clear sub-category filter
      ));
      print("HomeBloc: Search for '${event.query}' successful.");
    } catch (e) {
      print("HomeBloc: Error searching providers: $e");
      emit(HomeError(
          message: "Search failed: ${e.toString()}",
          isInitialError: currentHomeData == null,
          previousState: previousStateData));
    }
  }

  /// Handles the [ToggleFavoriteHome] event.
  /// Updates the favorite status of a service provider in Firestore and locally in the state.
  Future<void> _onToggleFavoriteHome(
      ToggleFavoriteHome event, Emitter<HomeState> emit) async {
    final userId = _userId;
    if (userId == null) {
      // User must be logged in to manage favorites.
      // Emitting an error or a specific "login required" state might be appropriate.
      emit(HomeError(
          message: "User not logged in to update favorites.",
          isInitialError: false,
          previousState:
              state is HomeDataLoaded ? state as HomeDataLoaded : null));
      return;
    }

    final currentState = state;
    if (currentState is! HomeDataLoaded) {
      print("HomeBloc: Cannot toggle favorite, data not loaded.");
      return; // Or emit an error
    }

    final bool newFavoriteStatus = !event.currentStatus; // Toggle the status
    print(
        "HomeBloc: Toggling favorite for ${event.providerId} to $newFavoriteStatus");

    try {
      // Update Firestore
      await _dataOrchestrator.toggleFavorite(
          userId, event.providerId, newFavoriteStatus);
      print("HomeBloc: Favorite status updated in Firestore.");

      // Update local state immutably
      // Helper function to update a list of providers
      List<ServiceProviderDisplayModel> updateList(
          List<ServiceProviderDisplayModel> list) {
        return list
            .map((p) => p.id == event.providerId
                ? p.copyWith(isFavorite: newFavoriteStatus)
                : p)
            .toList();
      }

      HomeData updatedHomeData = currentState.homeData.copyWith(
        nearbyPlaces: updateList(currentState.homeData.nearbyPlaces),
        popularPlaces: updateList(currentState.homeData.popularPlaces),
        recommendedPlaces: updateList(currentState.homeData.recommendedPlaces),
        specialOffers: updateList(currentState.homeData.specialOffers),
        searchResults: updateList(currentState.homeData.searchResults),
        categoryFilteredResults:
            updateList(currentState.homeData.categoryFilteredResults),
      );

      emit(currentState.copyWith(
          // Use HomeDataLoaded.copyWith
          homeData: updatedHomeData
          // Other state properties (selectedCity, filters, searchQuery) remain the same
          ));
    } catch (e) {
      print("HomeBloc: Error toggling favorite: $e");
      // Revert optimistic UI update or show error
      emit(HomeError(
          message: "Could not update favorite status.",
          isInitialError: false,
          previousState: currentState));
    }
  }
}
