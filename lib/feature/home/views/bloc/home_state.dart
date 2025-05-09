// lib/feature/home/views/bloc/home_state.dart

part of 'home_bloc.dart'; // Ensures this file is part of home_bloc.dart


/// Base abstract class for all states related to the Home feature.
/// Extends Equatable to allow for easy value comparison.
abstract class HomeState extends Equatable {
  const HomeState();

  /// Returns a list of properties that Equatable will use for comparison.
  /// By default, it's an empty list, meaning different instances are not equal
  /// unless overridden in subclasses.
  @override
  List<Object?> get props => [];
}

/// Represents the initial state of the Home screen, typically before any
/// data fetching operations have begun.
class HomeInitial extends HomeState {}

/// Represents the state where data for the Home screen is currently being loaded.
class HomeLoading extends HomeState {
  /// Indicates if this loading operation is the very first one for the screen.
  /// This can be used, for example, to show a full-screen loading indicator
  /// on initial load, versus a smaller indicator for subsequent loads (e.g., refresh).
  final bool isInitialLoading;

  /// Holds the previously loaded data, if any.
  /// This allows the UI to continue displaying stale data while new data is fetched,
  /// providing a smoother user experience by avoiding blank screens or full shimmers
  /// during refreshes or filter changes.
  final HomeDataLoaded? previousState;

  const HomeLoading({
    required this.isInitialLoading,
    this.previousState,
  });

  @override
  List<Object?> get props => [isInitialLoading, previousState];
}

/// Represents the state where data for the Home screen has been successfully loaded.
class HomeDataLoaded extends HomeState {
  /// The core data for the home screen, expected to be an instance of `HomeData`.
  /// This object likely contains various lists like nearby service providers,
  /// search results, category-filtered results, etc.
  final HomeData homeData;

  /// The currently selected city for which the data is relevant.
  final String? selectedCity;

  /// The category by which the data is currently filtered, if any.
  final String? filteredByCategory;

  /// The sub-category by which the data is currently filtered, if any.
  /// This could be "All" or a specific sub-category name.
  final String? selectedSubCategory;

  /// The current search query string, if a search is active.
  final String? searchQuery;

  const HomeDataLoaded({
    required this.homeData,
    this.selectedCity,
    this.filteredByCategory,
    this.selectedSubCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [homeData, selectedCity, filteredByCategory, selectedSubCategory, searchQuery];

  /// Creates a new `HomeDataLoaded` instance with updated values.
  /// This method is crucial for state management, allowing for immutable updates.
  ///
  /// It includes flags to specifically manage the clearing of lists within the
  /// nested `HomeData` object, promoting cleaner state transitions.
  HomeDataLoaded copyWith({
    HomeData? homeData,
    String? selectedCity,
    String? filteredByCategory,
    String? selectedSubCategory,
    String? searchQuery,
    // Flags to control clearing of specific data lists within `this.homeData`
    bool clearFilter = false,        // If true, clears main category, sub-category, and categoryFilteredResults list.
    bool clearSubCategoryFilter = false, // If true, clears only sub-category filter and categoryFilteredResults list.
    bool clearSearch = false,        // If true, clears search query and searchResults list.
    // Optional: Directly pass new lists. These are typically used when new data is fetched,
    // and will be overridden by the clear flags if both are set (clear takes precedence).
    List<ServiceProviderDisplayModel>? newSearchResults,
    List<ServiceProviderDisplayModel>? newCategoryFilteredResults,
  }) {
    // Determine the base HomeData instance to work from.
    // If a new `homeData` object is provided, use it; otherwise, use the current state's `homeData`.
    final HomeData baseHomeData = homeData ?? this.homeData;

    // Create the updated HomeData instance by calling its own `copyWith` method.
    // This delegates the logic for updating or clearing lists to the `HomeData` class itself.
    final HomeData updatedHomeData = baseHomeData.copyWith(
      // Pass the clear flags to `HomeData.copyWith`.
      clearSearchResults: clearSearch,
      clearCategoryFilteredResults: clearFilter || clearSubCategoryFilter, // If either main or sub-category filter is cleared, clear the results.
      // Pass new lists if provided. `HomeData.copyWith` should handle
      // whether to use these new lists or ignore them if a clear flag is true.
      searchResults: newSearchResults,
      categoryFilteredResults: newCategoryFilteredResults,
    );

    // Return a new HomeDataLoaded state.
    return HomeDataLoaded(
      homeData: updatedHomeData, // Use the modified `HomeData` instance.
      selectedCity: selectedCity ?? this.selectedCity, // Update selectedCity if provided, else keep current.
      // Update filter and search state strings.
      // If a clear flag is true, set the corresponding string to null.
      // Otherwise, if a new value is provided, use it; else, keep the current value.
      filteredByCategory: clearFilter ? null : (filteredByCategory ?? this.filteredByCategory),
      selectedSubCategory: clearFilter || clearSubCategoryFilter ? null : (selectedSubCategory ?? this.selectedSubCategory),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Represents the state where an error occurred while trying to fetch or process
/// data for the Home screen.
class HomeError extends HomeState {
  /// A descriptive message about the error that occurred.
  final String message;

  /// Indicates if the error occurred during the initial data load for the screen.
  /// This helps the UI decide how to display the error (e.g., full-screen error
  /// message for initial errors vs. a snackbar for errors during refresh).
  final bool isInitialError;

  /// Holds the previously loaded data, if any, before the error occurred.
  /// This allows the UI to continue displaying stale data while showing an error
  /// notification for non-initial errors, improving user experience.
  final HomeDataLoaded? previousState;

  const HomeError({
    required this.message,
    required this.isInitialError,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, isInitialError, previousState];
}
