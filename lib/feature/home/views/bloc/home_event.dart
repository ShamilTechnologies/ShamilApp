// lib/feature/home/views/bloc/home_event.dart

part of 'home_bloc.dart'; // Ensures this file is part of home_bloc.dart

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all initial data for the home screen.
class LoadHomeData extends HomeEvent {
  final bool isRefresh;

  const LoadHomeData({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Event to update the city manually (e.g., from user selection).
class UpdateCityManually extends HomeEvent {
  final String selectedCity;

  const UpdateCityManually({required this.selectedCity});

  @override
  List<Object?> get props => [selectedCity];
}

/// Event to filter service providers by main category.
class FilterByCategory extends HomeEvent {
  final String category; // Main category name or "" for "All"

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

// --- NEW: Event to filter by sub-category ---
class FilterBySubCategory extends HomeEvent {
  final String mainCategory; // The parent category
  final String subCategory; // The selected sub-category ("All" or specific)

  const FilterBySubCategory({required this.mainCategory, required this.subCategory});

  @override
  List<Object?> get props => [mainCategory, subCategory];
}
// --- END NEW ---

/// Event to search for service providers based on a query.
class SearchProviders extends HomeEvent {
  final String query;

  const SearchProviders({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to toggle the favorite status of a service provider.
class ToggleFavoriteHome extends HomeEvent {
  final String providerId;
  final bool currentStatus;

  const ToggleFavoriteHome({required this.providerId, required this.currentStatus});

  @override
  List<Object?> get props => [providerId, currentStatus];
}