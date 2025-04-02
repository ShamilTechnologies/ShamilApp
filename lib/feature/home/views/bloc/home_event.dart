part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger loading initial home data (location, providers, etc.)
class LoadHomeData extends HomeEvent {}

/// Event triggered when the user manually selects a city from the dropdown.
class UpdateCityManually extends HomeEvent {
  final String newCity;

  const UpdateCityManually({required this.newCity});

  @override
  List<Object?> get props => [newCity];
}

/* // --- Placeholder for Future Events ---

/// Event triggered when a category is selected for filtering.
class FilterByCategory extends HomeEvent {
  final String category;

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Event triggered when the user submits a search query.
class SearchProviders extends HomeEvent {
  final String query;

  const SearchProviders({required this.query});

  @override
  List<Object?> get props => [query];
}

*/
