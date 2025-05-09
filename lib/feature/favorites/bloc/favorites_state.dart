import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

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

class FavoriteStatusUpdated extends FavoritesState {
  final String providerId;
  final bool isFavorite;
  const FavoriteStatusUpdated({
    required this.providerId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [providerId, isFavorite];
}
