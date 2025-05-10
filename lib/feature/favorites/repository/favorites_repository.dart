import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

abstract class FavoritesRepository {
  // Stream for real-time updates of favorites
  Stream<List<ServiceProviderDisplayModel>> getFavorites();

  // Direct Future-based method to get favorites once
  Future<List<ServiceProviderDisplayModel>> getFavoritesList();

  // Add a service provider to favorites
  Future<void> addToFavorites(ServiceProviderDisplayModel provider);

  // Remove a service provider from favorites
  Future<void> removeFromFavorites(String providerId);

  // Check if a service provider is in favorites
  Future<bool> isFavorite(String providerId);
}

class LocalFavoritesRepository implements FavoritesRepository {
  static const String _favoritesKey = 'favorites';
  final SharedPreferences _prefs;
  final _favoritesController =
      StreamController<List<ServiceProviderDisplayModel>>.broadcast();

  LocalFavoritesRepository(this._prefs) {
    _loadAndEmitFavorites();
  }

  void _loadAndEmitFavorites() async {
    final favorites = await _getFavoritesList();
    _favoritesController.add(favorites);
  }

  Future<List<ServiceProviderDisplayModel>> _getFavoritesList() async {
    final favoritesJson = _prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson
        .map((json) => ServiceProviderDisplayModel.fromJson(jsonDecode(json)))
        .toList();
  }

  @override
  Stream<List<ServiceProviderDisplayModel>> getFavorites() {
    return _favoritesController.stream;
  }

  @override
  Future<List<ServiceProviderDisplayModel>> getFavoritesList() async {
    return await _getFavoritesList();
  }

  @override
  Future<void> addToFavorites(ServiceProviderDisplayModel provider) async {
    final favorites = await _getFavoritesList();
    if (!favorites.any((p) => p.id == provider.id)) {
      favorites.add(provider);
      await _saveFavorites(favorites);
      _favoritesController.add(favorites);
    }
  }

  @override
  Future<void> removeFromFavorites(String providerId) async {
    final favorites = await _getFavoritesList();
    favorites.removeWhere((p) => p.id == providerId);
    await _saveFavorites(favorites);
    _favoritesController.add(favorites);
  }

  @override
  Future<bool> isFavorite(String providerId) async {
    final favorites = await _getFavoritesList();
    return favorites.any((p) => p.id == providerId);
  }

  Future<void> _saveFavorites(
      List<ServiceProviderDisplayModel> favorites) async {
    final favoritesJson =
        favorites.map((provider) => jsonEncode(provider.toJson())).toList();
    await _prefs.setStringList(_favoritesKey, favoritesJson);
  }

  void dispose() {
    _favoritesController.close();
  }
}
