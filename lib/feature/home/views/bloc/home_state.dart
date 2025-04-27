part of 'home_bloc.dart'; // Ensures this is part of the home_bloc library

// Import necessary models

@immutable // Mark states as immutable
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => []; // Default props for states without specific data
}

/// Initial state before any loading starts.
class HomeInitial extends HomeState {}

/// State indicating that home data (location, providers, etc.) is being loaded.
class HomeLoading extends HomeState {}

/// State indicating that home data has been successfully loaded.
class HomeLoaded extends HomeState {
  final HomeModel homeModel; // Contains user ID, city, and last update time
  final List<ServiceProviderDisplayModel> popularProviders;
  final List<ServiceProviderDisplayModel> recommendedProviders;
  // *** ADDED fields for other sections ***
  final List<BannerModel> banners;
  final List<ServiceProviderDisplayModel> offers; // Assuming offers use DisplayModel
  final List<ServiceProviderDisplayModel> nearbyProviders;

  const HomeLoaded({
    required this.homeModel,
    this.popularProviders = const [],
    this.recommendedProviders = const [],
    this.banners = const [],          // <<< ADDED with default
    this.offers = const [],           // <<< ADDED with default
    this.nearbyProviders = const [],  // <<< ADDED with default
  });

  @override
  List<Object?> get props => [
        homeModel,
        popularProviders,
        recommendedProviders,
        banners,          // <<< ADDED to props
        offers,           // <<< ADDED to props
       nearbyProviders,  // <<< ADDED to props
      ];

  /// Creates a copy of the HomeLoaded state with potentially updated values.
  HomeLoaded copyWith({
    HomeModel? homeModel,
    List<ServiceProviderDisplayModel>? popularProviders,
    List<ServiceProviderDisplayModel>? recommendedProviders,
    List<BannerModel>? banners,          // <<< ADDED
    List<ServiceProviderDisplayModel>? offers,           // <<< ADDED
    List<ServiceProviderDisplayModel>? nearbyProviders,  // <<< ADDED
  }) {
    return HomeLoaded(
      homeModel: homeModel ?? this.homeModel,
      popularProviders: popularProviders ?? this.popularProviders,
      recommendedProviders: recommendedProviders ?? this.recommendedProviders,
      banners: banners ?? this.banners,                   // <<< ADDED
      offers: offers ?? this.offers,                      // <<< ADDED
      nearbyProviders: nearbyProviders ?? this.nearbyProviders, // <<< ADDED
    );
  }

   // Optional: Override toString for better debugging output
  @override
  String toString() {
    return 'HomeLoaded(city: ${homeModel.city}, popular: ${popularProviders.length}, recommended: ${recommendedProviders.length}, banners: ${banners.length}, offers: ${offers.length}, nearby: ${nearbyProviders.length})'; // <<< UPDATED toString
  }
}

/// State indicating an error occurred while loading home data.
class HomeError extends HomeState {
  final String message; // Error message description

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message]; // Include message in props
}

// Optional: Consider adding specific states for actions like favorite toggle success/error
// if you want to show specific feedback (e.g., Snackbars) via BlocListener.
// class HomeFavoriteToggleSuccess extends HomeState { ... }
// class HomeFavoriteToggleError extends HomeState { ... }
