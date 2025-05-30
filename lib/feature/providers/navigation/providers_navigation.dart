import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/providers/view/modern_providers_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';

/// Navigation helper for the providers feature
class ProvidersNavigation {
  /// Navigate to the modern providers screen
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
}
