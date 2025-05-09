import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

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

class ToggleFavorite extends FavoritesEvent {
  final ServiceProviderDisplayModel provider;
  const ToggleFavorite(this.provider);

  @override
  List<Object?> get props => [provider];
}
