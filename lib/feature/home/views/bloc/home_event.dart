part of 'home_bloc.dart'; // Ensures this is part of the home_bloc library

@immutable
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger loading initial home data (location, providers, etc.)
class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

/// Event triggered when the user manually selects a city from the dropdown.
class UpdateCityManually extends HomeEvent {
  final String newCity;
  const UpdateCityManually({required this.newCity});
  @override
  List<Object?> get props => [newCity];
}

/// Event triggered when a category is selected for filtering.
class FilterByCategory extends HomeEvent {
  final String category;
  const FilterByCategory({required this.category});
  @override
  List<Object?> get props => [category];
}

/// Event triggered when the user submits a search query from the search bar.
class SearchProviders extends HomeEvent {
  final String query;
  const SearchProviders({required this.query});
  @override
  List<Object?> get props => [query];
}

/// **ADDED:** Event triggered when favorite button is tapped on a home screen card.
class ToggleFavoriteHome extends HomeEvent {
  final String providerId;   // ID of the provider being toggled
  final bool currentStatus; // Is it currently favorited?

  const ToggleFavoriteHome({required this.providerId, required this.currentStatus});

  @override
  List<Object?> get props => [providerId, currentStatus];
}