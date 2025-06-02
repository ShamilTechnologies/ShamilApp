import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

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
  final String? checkedProviderId;
  final bool? isProviderFavorite;
  final String? operationInProgressId;

  const FavoritesLoaded({
    required this.favorites,
    this.checkedProviderId,
    this.isProviderFavorite,
    this.operationInProgressId,
  });

  bool isProviderInFavorites(String providerId) {
    return favorites.any((provider) => provider.id == providerId);
  }

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

// Internal events
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
  final FirebaseDataOrchestrator _dataOrchestrator;
  StreamSubscription? _favoritesSubscription;

  FavoritesBloc({required FirebaseDataOrchestrator dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator,
        super(FavoritesInitial()) {
    print('FavoritesBloc initialized');
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<_UpdateFavoritesFromStream>(_onUpdateFavoritesFromStream);
    on<_FavoritesStreamError>(_onFavoritesStreamError);
  }

  bool _isUserLoggedIn() {
    return _dataOrchestrator.isAuthenticated;
  }

  bool isProviderFavorite(String providerId) {
    if (state is FavoritesLoaded) {
      return (state as FavoritesLoaded).isProviderInFavorites(providerId);
    }
    return false;
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavoritesState> emit) async {
    print('LoadFavorites event received');

    if (!_isUserLoggedIn()) {
      emit(const FavoritesError("User not logged in"));
      return;
    }

    try {
      emit(const FavoritesLoading(isGlobalLoading: true));

      await _favoritesSubscription?.cancel();

      // Set up the subscription for real-time updates
      _favoritesSubscription = _dataOrchestrator.getFavoritesStream().listen(
        (updatedFavorites) {
          print('Received ${updatedFavorites.length} favorites from stream');
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

  void _onUpdateFavoritesFromStream(
      _UpdateFavoritesFromStream event, Emitter<FavoritesState> emit) {
    emit(FavoritesLoaded(favorites: event.favorites));
  }

  void _onFavoritesStreamError(
      _FavoritesStreamError event, Emitter<FavoritesState> emit) {
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
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

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

      await _dataOrchestrator.addToFavorites(event.provider.id);

      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final updatedFavorites =
            List<ServiceProviderDisplayModel>.from(currentState.favorites);

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
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

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

      await _dataOrchestrator.removeFromFavorites(event.providerId);

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
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

      // For now, just check the current state
      if (state is FavoritesLoaded) {
        final currentState = state as FavoritesLoaded;
        final isFavorite = currentState.isProviderInFavorites(event.providerId);

        emit(currentState.copyWith(
          checkedProviderId: event.providerId,
          isProviderFavorite: isFavorite,
        ));
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<FavoritesState> emit) async {
    try {
      if (!_isUserLoggedIn()) {
        emit(const FavoritesError("User not logged in"));
        return;
      }

      final isFavorite = isProviderFavorite(event.provider.id);

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
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }
}
