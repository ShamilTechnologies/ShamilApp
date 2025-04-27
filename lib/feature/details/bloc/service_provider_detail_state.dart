part of 'service_provider_detail_bloc.dart';

@immutable
abstract class ServiceProviderDetailState extends Equatable {
  const ServiceProviderDetailState();
  @override
  List<Object?> get props => [];
}

/// Initial state before loading.
class ServiceProviderDetailInitial extends ServiceProviderDetailState {}

/// State while details are being loaded.
class ServiceProviderDetailLoading extends ServiceProviderDetailState {}

/// State when details are successfully loaded.
class ServiceProviderDetailLoaded extends ServiceProviderDetailState {
  final ServiceProviderModel provider;
  final bool isFavorite; // <<< Field added

  const ServiceProviderDetailLoaded({
    required this.provider,
    required this.isFavorite, // <<< Added to constructor
  });

  @override
  List<Object?> get props => [provider, isFavorite]; // <<< Added to props

  // Optional: copyWith method for immutable updates if needed elsewhere
  ServiceProviderDetailLoaded copyWith({
    ServiceProviderModel? provider,
    bool? isFavorite,
  }) {
    return ServiceProviderDetailLoaded(
      provider: provider ?? this.provider,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// State when an error occurs during loading.
class ServiceProviderDetailError extends ServiceProviderDetailState {
  final String message;
  const ServiceProviderDetailError({required this.message});
  @override
  List<Object?> get props => [message];
}