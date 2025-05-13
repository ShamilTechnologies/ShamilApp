// lib/feature/service_details/bloc/service_details_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
import 'package:shamil_mobile_app/feature/details/views/bloc/service_provider_detail_bloc.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart'; // Re-use from home for provider details

part 'service_details_event.dart';
part 'service_details_state.dart';

class ServiceProviderDetailBloc
    extends Bloc<ServiceProviderDetailEvent, ServiceProviderDetailState> {
  final ServiceProviderDetailRepository detailRepository;
  final FavoritesBloc _favoritesBloc;
  StreamSubscription? _favoriteStatusSubscription;

  ServiceProviderDetailBloc({
    required this.detailRepository,
    required FavoritesBloc favoritesBloc,
  })  : _favoritesBloc = favoritesBloc,
        super(ServiceProviderDetailInitial()) {
    on<LoadServiceProviderDetails>(_onLoadServiceProviderDetails);
    on<ToggleFavoriteStatus>(_onToggleFavoriteStatus);

    // Listen to changes in favorites state
    _favoriteStatusSubscription = _favoritesBloc.stream.listen((favState) {
      try {
        if (favState is FavoritesLoaded &&
            state is ServiceProviderDetailLoaded) {
          final currentState = state as ServiceProviderDetailLoaded;
          final provider = currentState.provider;

          if (provider.id.isNotEmpty) {
            // Update our state if the status of this provider has changed
            final newFavoriteStatus =
                favState.isProviderInFavorites(provider.id);
            if (currentState.isFavorite != newFavoriteStatus) {
              emit(ServiceProviderDetailLoaded(
                provider: provider,
                isFavorite: newFavoriteStatus,
              ));
            }
          }
        }
      } catch (e) {
        print('Error in favorite status subscription: $e');
        // Don't emit error to avoid disrupting the UI
      }
    });
  }

  Future<void> _onLoadServiceProviderDetails(
    LoadServiceProviderDetails event,
    Emitter<ServiceProviderDetailState> emit,
  ) async {
    emit(ServiceProviderDetailLoading());
    try {
      final provider =
          await detailRepository.fetchServiceProviderDetails(event.providerId);

      // Check favorite status from FavoritesBloc with null safety
      bool isFavorite = false;
      try {
        isFavorite = _favoritesBloc.isProviderFavorite(event.providerId);
      } catch (e) {
        print('Error checking favorite status: $e');
        // Default to false on error
      }

      emit(ServiceProviderDetailLoaded(
          provider: provider, isFavorite: isFavorite));

      // Also request a check to ensure we have the latest status
      _favoritesBloc.add(CheckFavoriteStatus(event.providerId));
    } catch (e) {
      emit(ServiceProviderDetailError(message: e.toString()));
    }
  }

  void _onToggleFavoriteStatus(
    ToggleFavoriteStatus event,
    Emitter<ServiceProviderDetailState> emit,
  ) {
    if (state is ServiceProviderDetailLoaded) {
      final currentState = state as ServiceProviderDetailLoaded;

      // Update UI immediately for responsiveness
      emit(ServiceProviderDetailLoaded(
        provider: currentState.provider,
        isFavorite: !currentState.isFavorite,
      ));

      // Use the centralized FavoritesBloc to handle the actual toggle
      final displayModel = ServiceProviderDisplayModel.fromServiceProviderModel(
          currentState.provider, true);
      _favoritesBloc.add(ToggleFavorite(displayModel));
    }
  }

  @override
  Future<void> close() {
    _favoriteStatusSubscription?.cancel();
    return super.close();
  }
}
