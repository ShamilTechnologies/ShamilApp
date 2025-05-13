import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/favorites/repository/favorites_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shamil_mobile_app/feature/favorites/repository/firebase_favorites_repository.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites();
}

class AddToFavorites extends FavoritesEvent {
  final ServiceProviderDisplayModel provider;
  const AddToFavorites(this.provider);

  @override
  List<Object?> get props => [provider];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String providerId;
  const RemoveFromFavorites(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class CheckFavoriteStatus extends FavoritesEvent {
  final String providerId;
  const CheckFavoriteStatus(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

class ToggleFavorite extends FavoritesEvent {
  final ServiceProviderDisplayModel provider;
  const ToggleFavorite(this.provider);

  @override
  List<Object?> get props => [provider];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {
  final bool isGlobalLoading;
  final String? operationProviderId;

  const FavoritesLoading({
    this.isGlobalLoading = true,
    this.operationProviderId,
  });

  @override
  List<Object?> get props => [isGlobalLoading, operationProviderId];
}

class FavoritesLoaded extends FavoritesState {
  final List<ServiceProviderDisplayModel> favorites;

  // For favorite status checks
  final String? checkedProviderId;
  final bool? isProviderFavorite;

  // For operations in progress
  final String? operationInProgressId;

  const FavoritesLoaded({
    required this.favorites,
    this.checkedProviderId,
    this.isProviderFavorite,
    this.operationInProgressId,
  });

  // Helper method to check if a provider is in favorites
  bool isProviderInFavorites(String providerId) {
    return favorites.any((provider) => provider.id == providerId);
  }

  // Create a copy with updated operation status
  FavoritesLoaded copyWith({
    List<ServiceProviderDisplayModel>? favorites,
    String? checkedProviderId,
    bool? isProviderFavorite,
    String? operationInProgressId,
  }) {
    return FavoritesLoaded(
      favorites: favorites ?? this.favorites,
      checkedProviderId: checkedProviderId ?? this.checkedProviderId,
      isProviderFavorite: isProviderFavorite ?? this.isProviderFavorite,
      operationInProgressId: operationInProgressId,
    );
  }

  @override
  List<Object?> get props => [
        favorites,
        checkedProviderId,
        isProviderFavorite,
        operationInProgressId,
      ];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Add internal events at the end of the file
class _UpdateFavoritesFromStream extends FavoritesEvent {
  final List<ServiceProviderDisplayModel> favorites;
  const _UpdateFavoritesFromStream(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

class _FavoritesStreamError extends FavoritesEvent {
  final String message;
  const _FavoritesStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;
  StreamSubscription? _favoritesSubscription;

  // Create a factory constructor to initialize with the current user
  factory FavoritesBloc.fromCurrentUser() {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest_placeholder';
    return FavoritesBloc(FirebaseFavoritesRepository(userId: userId));
  }

  FavoritesBloc(this._repository) : super(FavoritesInitial()) {
    print('FavoritesBloc initialized');
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    // Register handlers for internal events
    on<_UpdateFavoritesFromStream>(_onUpdateFavoritesFromStream);
    on<_FavoritesStreamError>(_onFavoritesStreamError);
  }

  // Helper method to check if user is logged in
  bool _isUserLoggedIn() {
    return fb_auth.FirebaseAuth.instance.currentUser != null;
  }

  // Helper method to check if a provider is in favorites
  bool isProviderFavorite(String providerId) {
    if (state is FavoritesLoaded) {
      return (state as FavoritesLoaded).isProviderInFavorites(providerId);
    }
    return false;
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavoritesState> emit) async {
    print('LoadFavorites event received');

    // Check if user is logged in
    if (!_isUserLoggedIn()) {
      emit(const FavoritesError("User not logged in"));
      return;
    }

    try {
      // Emit loading state first
      emit(const FavoritesLoading(isGlobalLoading: true));

      // Cancel any existing subscription to avoid duplicate streams
      await _favoritesSubscription?.cancel();

      // Get favorites directly first
      final favorites = await _repository.getFavoritesList();

      // Emit the loaded state with the initial data
      emit(FavoritesLoaded(favorites: favorites));

      // Set up the subscription for future updates
      _favoritesSubscription = _repository.getFavorites().listen(
        (updatedFavorites) {
          print('Received ${updatedFavorites.length} favorites from stream');
          // Use add instead of emit for stream updates
          if (!isClosed) {
            add(_UpdateFavoritesFromStream(updatedFavorites));
          }
        },
        onError: (error) {
          print('Error in favorites stream: $error');
          if (!isClosed) {
            add(_FavoritesStreamError(error.toString()));
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error loading favorites: $e');
      if (!isClosed) {
        emit(FavoritesError(e.toString()));
      }
    }
  }

  // Add handlers for internal events
  void _onUpdateFavoritesFromStream(
      _UpdateFavoritesFromStream event, Emitter<FavoritesState> emit) {
    emit(FavoritesLoaded(favorites: event.favorites));
  }

  void _onFavoritesStreamError(
      _FavoritesStreamError event, Emitter<FavoritesState> emit) {
    // Don't emit error state if we already have data
    if (state is FavoritesLoaded) {
      print(
          'Favorites stream error, but keeping existing data: ${event.message}');
    } else {
      emit(FavoritesError(event.message));
    }
  }

  Future<void> _onAddToFavorites(
      AddToFavorites event, Emitter<FavoritesState> emit) async {
    try {
      // Check if user is logged in
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

      // Prepare loading state with operation ID
      if (state is FavoritesLoaded) {
        emit((state as FavoritesLoaded).copyWith(
          operationInProgressId: event.provider.id,
        ));
      } else {
        emit(FavoritesLoading(
          isGlobalLoading: false,
          operationProviderId: event.provider.id,
        ));
      }

      // Add to favorites
      await _repository.addToFavorites(event.provider);

      // If we're still in loaded state, update immediately
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedFavorites =
            List<ServiceProviderDisplayModel>.from(currentState.favorites);

        // Only add if not already there
        if (!updatedFavorites.any((p) => p.id == event.provider.id)) {
          updatedFavorites.add(event.provider);
        }

        emit(FavoritesLoaded(
          favorites: updatedFavorites,
          checkedProviderId: event.provider.id,
          isProviderFavorite: true,
        ));
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onRemoveFromFavorites(
      RemoveFromFavorites event, Emitter<FavoritesState> emit) async {
    try {
      // Check if user is logged in
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

      // Prepare loading state with operation ID
      if (state is FavoritesLoaded) {
        emit((state as FavoritesLoaded).copyWith(
          operationInProgressId: event.providerId,
        ));
      } else {
        emit(FavoritesLoading(
          isGlobalLoading: false,
          operationProviderId: event.providerId,
        ));
      }

      // Remove from favorites
      await _repository.removeFromFavorites(event.providerId);

      // Update state immediately
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedFavorites = currentState.favorites
            .where((p) => p.id != event.providerId)
            .toList();

        emit(FavoritesLoaded(
          favorites: updatedFavorites,
          checkedProviderId: event.providerId,
          isProviderFavorite: false,
        ));
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onCheckFavoriteStatus(
      CheckFavoriteStatus event, Emitter<FavoritesState> emit) async {
    try {
      // If we already have favorites loaded, just check the list
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final isFavorite = currentState.isProviderInFavorites(event.providerId);

        emit(currentState.copyWith(
          checkedProviderId: event.providerId,
          isProviderFavorite: isFavorite,
        ));
        return;
      }

      // Otherwise check from the repository directly
      if (_isUserLoggedIn()) {
        bool isFavorite = false;
        try {
          isFavorite = await _repository.isFavorite(event.providerId);
        } catch (e) {
          print('Error in isFavorite check: $e');
          // Default to false on error
          isFavorite = false;
        }

        if (state is FavoritesLoaded) {
          // If state changed while we were checking
          final currentState = state as FavoritesLoaded;
          emit(currentState.copyWith(
            checkedProviderId: event.providerId,
            isProviderFavorite: isFavorite,
          ));
        } else {
          // Create a new loaded state with just this info
          emit(FavoritesLoaded(
            favorites: const [],
            checkedProviderId: event.providerId,
            isProviderFavorite: isFavorite,
          ));
        }
      } else {
        // Always emit a valid state even when user isn't logged in
        emit(FavoritesLoaded(
          favorites: const [],
          checkedProviderId: event.providerId,
          isProviderFavorite: false,
        ));
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      // Don't emit error - just return a valid result with false
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        emit(currentState.copyWith(
          checkedProviderId: event.providerId,
          isProviderFavorite: false,
        ));
      } else {
        emit(FavoritesLoaded(
          favorites: const [],
          checkedProviderId: event.providerId,
          isProviderFavorite: false,
        ));
      }
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<FavoritesState> emit) async {
    try {
      // Check current favorite status
      final bool isFavorite = isProviderFavorite(event.provider.id);

      // Add or remove based on current status
      if (isFavorite) {
        add(RemoveFromFavorites(event.provider.id));
      } else {
        add(AddToFavorites(event.provider));
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _favoritesSubscription?.cancel();
    return super.close();
  }
}
