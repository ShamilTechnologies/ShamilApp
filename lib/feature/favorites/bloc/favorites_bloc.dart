import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/favorites/repository/favorites_repository.dart';

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

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<ServiceProviderDisplayModel> favorites;
  const FavoritesLoaded(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;
  StreamSubscription? _favoritesSubscription;

  FavoritesBloc(this._repository) : super(FavoritesInitial()) {
    print('FavoritesBloc initialized');
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavoritesState> emit) async {
    print('LoadFavorites event received');
    try {
      // Emit loading state first
      print('Emitting FavoritesLoading state');
      emit(FavoritesLoading());

      // Cancel any existing subscription
      if (_favoritesSubscription != null) {
        print('Cancelling existing favorites subscription');
        _favoritesSubscription?.cancel();
      }

      // Set up new subscription with proper error handling
      print('Setting up new favorites subscription');
      _favoritesSubscription = _repository.getFavorites().listen(
        (favorites) {
          print(
              'Received ${favorites.length} favorites from repository stream');
          emit(FavoritesLoaded(favorites));
          print(
              'Emitted FavoritesLoaded state with ${favorites.length} favorites');
        },
        onError: (error) {
          print('Error in favorites stream: $error');
          emit(FavoritesError(error.toString()));
          print('Emitted FavoritesError state: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error setting up favorites stream: $e');
      emit(FavoritesError(e.toString()));
      print('Emitted FavoritesError state: $e');
    }
  }

  Future<void> _onAddToFavorites(
      AddToFavorites event, Emitter<FavoritesState> emit) async {
    print('Adding provider to favorites: ${event.provider.id}');
    try {
      await _repository.addToFavorites(event.provider);
      print('Successfully added to favorites');
      // The stream will handle updating the UI
    } catch (e) {
      print('Error adding to favorites: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onRemoveFromFavorites(
      RemoveFromFavorites event, Emitter<FavoritesState> emit) async {
    print('Removing provider from favorites: ${event.providerId}');
    try {
      await _repository.removeFromFavorites(event.providerId);
      print('Successfully removed from favorites');
      // The stream will handle updating the UI
    } catch (e) {
      print('Error removing from favorites: $e');
      emit(FavoritesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    print('Closing FavoritesBloc');
    _favoritesSubscription?.cancel();
    return super.close();
  }
}
