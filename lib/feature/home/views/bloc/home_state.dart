part of 'home_bloc.dart';

// Import the necessary models


abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading starts.
class HomeInitial extends HomeState {}

/// State indicating that home data (location, providers, etc.) is being loaded.
class HomeLoading extends HomeState {}

/// State indicating that home data has been successfully loaded.
class HomeLoaded extends HomeState {
  final HomeModel homeModel; // Contains user ID, city, and last update time
  final List<ServiceProviderDisplayModel> popularProviders; // List of popular providers
  final List<ServiceProviderDisplayModel> recommendedProviders; // List of recommended providers
  // Add other lists if needed (e.g., categories fetched dynamically)

  const HomeLoaded({
    required this.homeModel,
    this.popularProviders = const [], // Default to empty list
    this.recommendedProviders = const [], // Default to empty list
  });

  @override
  List<Object?> get props => [
        homeModel,
        popularProviders,
        recommendedProviders,
      ]; // Include new lists in props

  /// Creates a copy of the HomeLoaded state with potentially updated values.
  /// Useful for immutable state updates in the Bloc.
  HomeLoaded copyWith({
    HomeModel? homeModel,
    List<ServiceProviderDisplayModel>? popularProviders,
    List<ServiceProviderDisplayModel>? recommendedProviders,
  }) {
    return HomeLoaded(
      homeModel: homeModel ?? this.homeModel,
      popularProviders: popularProviders ?? this.popularProviders,
      recommendedProviders: recommendedProviders ?? this.recommendedProviders,
    );
  }

   // Optional: Override toString for better debugging output
  @override
  String toString() {
    return 'HomeLoaded(homeModel: $homeModel, popularProviders: ${popularProviders.length}, recommendedProviders: ${recommendedProviders.length})';
  }
}

/// State indicating an error occurred while loading home data.
class HomeError extends HomeState {
  final String message; // Error message description

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
