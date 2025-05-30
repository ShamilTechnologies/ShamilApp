import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/providers/view/modern_providers_screen.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

/// Global Service Provider Navigation Utilities
///
/// This class provides centralized navigation methods for service provider
/// related screens that can be used throughout the app for consistency.
class ServiceProviderNavigation {
  /// Navigate to the modern providers screen with optional filters
  static Future<void> navigateToProviders(
    BuildContext context, {
    String? initialCategory,
    String? initialCity,
    String? initialSearchQuery,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: BlocProvider.of<FavoritesBloc>(context),
          child: ModernProvidersScreen(
            initialCategory: initialCategory,
            initialCity: initialCity,
            initialSearchQuery: initialSearchQuery,
          ),
        ),
      ),
    );
  }

  /// Navigate to providers with category filter
  static Future<void> navigateToProvidersWithCategory(
    BuildContext context,
    String category,
  ) async {
    await navigateToProviders(
      context,
      initialCategory: category,
    );
  }

  /// Navigate to providers with city filter
  static Future<void> navigateToProvidersWithCity(
    BuildContext context,
    String city,
  ) async {
    await navigateToProviders(
      context,
      initialCity: city,
    );
  }

  /// Navigate to providers with search query
  static Future<void> navigateToProvidersWithSearch(
    BuildContext context,
    String searchQuery,
  ) async {
    await navigateToProviders(
      context,
      initialSearchQuery: searchQuery,
    );
  }

  /// Navigate to a specific service provider detail screen
  static Future<void> navigateToProviderDetail(
    BuildContext context, {
    required String providerId,
    required String heroTag,
    ServiceProviderDisplayModel? initialProviderData,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: BlocProvider.of<FavoritesBloc>(context),
          child: ServiceProviderDetailScreen(
            providerId: providerId,
            heroTag: heroTag,
            initialProviderData: initialProviderData,
          ),
        ),
      ),
    );
  }

  /// Navigate from any service provider card press
  /// This is a convenience method that can be used as an onTap callback
  static VoidCallback createProviderCardNavigation(
    BuildContext context, {
    required ServiceProviderDisplayModel provider,
    required String heroTagPrefix,
  }) {
    return () => navigateToProviderDetail(
          context,
          providerId: provider.id,
          heroTag: '${heroTagPrefix}_${provider.id}',
          initialProviderData: provider,
        );
  }

  /// Navigate to browse providers by category
  /// Useful for category cards or buttons
  static VoidCallback createCategoryNavigation(
    BuildContext context,
    String category,
  ) {
    return () => navigateToProvidersWithCategory(context, category);
  }

  /// Navigate to browse providers by city
  /// Useful for city selection or location-based browsing
  static VoidCallback createCityNavigation(
    BuildContext context,
    String city,
  ) {
    return () => navigateToProvidersWithCity(context, city);
  }

  /// Navigate with search functionality
  /// Useful for search bars or quick search buttons
  static VoidCallback createSearchNavigation(
    BuildContext context,
    String searchQuery,
  ) {
    return () => navigateToProvidersWithSearch(context, searchQuery);
  }

  /// Map common section titles to category filters
  /// This helps maintain consistency across the app
  static String? mapSectionTitleToCategory(String title) {
    switch (title.toLowerCase()) {
      case 'fitness & gym':
      case 'fitness':
        return 'Fitness';
      case 'sports':
        return 'Sports';
      case 'entertainment':
        return 'Entertainment';
      case 'health & wellness':
      case 'health':
        return 'Health';
      case 'events':
        return 'Events';
      default:
        return null; // Show all categories
    }
  }

  /// Navigate to "See All" for a section
  /// This provides a consistent way to handle "See All" buttons
  static Future<void> navigateToSeeAll(
    BuildContext context, {
    required String sectionTitle,
    String? currentCity,
  }) async {
    await navigateToProviders(
      context,
      initialCategory: mapSectionTitleToCategory(sectionTitle),
      initialCity: (currentCity != null && currentCity != "All Cities")
          ? currentCity
          : null,
    );
  }
}
