// lib/feature/home/data/homeModel.dart

import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

/// Represents the consolidated data for the Home/Explore screen.
class HomeData extends Equatable {
  final List<BannerModel> banners;
  final List<ServiceProviderDisplayModel> nearbyPlaces;
  final List<ServiceProviderDisplayModel> popularPlaces;
  final List<ServiceProviderDisplayModel> recommendedPlaces;
  final List<ServiceProviderDisplayModel> specialOffers;

  // --- ADDED: Lists for distinct search or filter results ---
  final List<ServiceProviderDisplayModel> searchResults;
  final List<ServiceProviderDisplayModel> categoryFilteredResults;

  const HomeData({
    this.banners = const [],
    this.nearbyPlaces = const [],
    this.popularPlaces = const [],
    this.recommendedPlaces = const [],
    this.specialOffers = const [],
    this.searchResults = const [], // Default to empty list
    this.categoryFilteredResults = const [], // Default to empty list
  });

  /// Creates an empty HomeData object.
  factory HomeData.empty() {
    return const HomeData(
      banners: [],
      nearbyPlaces: [],
      popularPlaces: [],
      recommendedPlaces: [],
      specialOffers: [],
      searchResults: [],
      categoryFilteredResults: [],
    );
  }

  /// Creates a copy of this HomeData object with the given fields replaced
  /// with the new values.
  HomeData copyWith({
    List<BannerModel>? banners,
    List<ServiceProviderDisplayModel>? nearbyPlaces,
    List<ServiceProviderDisplayModel>? popularPlaces,
    List<ServiceProviderDisplayModel>? recommendedPlaces,
    List<ServiceProviderDisplayModel>? specialOffers,
    // --- MODIFIED: Accept new lists and clear flags ---
    List<ServiceProviderDisplayModel>? searchResults,
    List<ServiceProviderDisplayModel>? categoryFilteredResults,
    bool clearSearchResults = false, // Flag to clear this list
    bool clearCategoryFilteredResults = false, // Flag to clear this list
    // --- END MODIFICATION ---
  }) {
    return HomeData(
      banners: banners ?? this.banners,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      popularPlaces: popularPlaces ?? this.popularPlaces,
      recommendedPlaces: recommendedPlaces ?? this.recommendedPlaces,
      specialOffers: specialOffers ?? this.specialOffers,
      // --- MODIFIED: Apply new lists or clear based on flags ---
      searchResults: clearSearchResults
          ? [] // Clear if flag is true
          : (searchResults ?? this.searchResults), // Otherwise use new or existing
      categoryFilteredResults: clearCategoryFilteredResults
          ? [] // Clear if flag is true
          : (categoryFilteredResults ?? this.categoryFilteredResults), // Otherwise use new or existing
      // --- END MODIFICATION ---
    );
  }

  @override
  List<Object?> get props => [
        banners,
        nearbyPlaces,
        popularPlaces,
        recommendedPlaces,
        specialOffers,
        searchResults, // Added to props
        categoryFilteredResults, // Added to props
      ];

  @override
  String toString() {
    return 'HomeData(banners: ${banners.length}, nearby: ${nearbyPlaces.length}, popular: ${popularPlaces.length}, recommended: ${recommendedPlaces.length}, offers: ${specialOffers.length}, searchResults: ${searchResults.length}, categoryFilteredResults: ${categoryFilteredResults.length})';
  }
}