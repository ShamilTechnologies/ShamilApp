part of 'home_bloc.dart'; // Ensures this is part of the home_bloc library

// Removed the import as it is now in home_bloc.dart

@immutable // It's good practice to mark events/states as immutable
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => []; // Default props for events without specific data
}

/// Event to trigger loading initial home data (location, providers, etc.)
class LoadHomeData extends HomeEvent {
  // Optionally add parameters if loading needs specific context, e.g., initial city
  // final String? initialCity;
  // const LoadHomeData({this.initialCity});
  // @override List<Object?> get props => [initialCity];

  // Keep default constructor if no parameters needed initially
  const LoadHomeData();
}

/// Event triggered when the user manually selects a city from the dropdown.
class UpdateCityManually extends HomeEvent {
  final String newCity;

  const UpdateCityManually({required this.newCity});

  @override
  List<Object?> get props => [newCity]; // Include newCity in props for comparison
}

// --- Added Events ---

/// Event triggered when a category is selected for filtering.
class FilterByCategory extends HomeEvent {
  final String category; // The category name selected (e.g., "Gym", "Spa")

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category]; // Include category in props
}

/// Event triggered when the user submits a search query from the search bar.
class SearchProviders extends HomeEvent {
  final String query; // The search term entered by the user

  const SearchProviders({required this.query});

  @override
  List<Object?> get props => [query]; // Include query in props
}
