// lib/feature/details/bloc/service_provider_detail_state.dart

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
  // *** USE THE UPDATED ServiceProviderModel TYPE ***
  final ServiceProviderModel provider;
  final bool isFavorite; // Keep favorite status

  const ServiceProviderDetailLoaded({
    required this.provider, // Use the updated model type
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [provider, isFavorite]; // Include provider in props

  // Optional: copyWith method for immutable updates if needed elsewhere
  ServiceProviderDetailLoaded copyWith({
    ServiceProviderModel? provider, // Use updated model type
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

// Optional: Add state for action errors like favorite toggle failure
// class ServiceProviderDetailActionError extends ServiceProviderDetailState {
//   final String message;
//   final ServiceProviderModel provider; // Keep provider data
//   final bool previousFavoriteStatus; // Keep previous status for potential revert
//   const ServiceProviderDetailActionError({
//       required this.message,
//       required this.provider,
//       required this.previousFavoriteStatus
//   });
//   @override List<Object?> get props => [message, provider, previousFavoriteStatus];
// }