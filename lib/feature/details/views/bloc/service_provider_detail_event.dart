part of 'service_provider_detail_bloc.dart';

@immutable
abstract class ServiceProviderDetailEvent extends Equatable {
  const ServiceProviderDetailEvent();
  @override
  List<Object?> get props => [];
}

/// Event to load details for a specific provider ID.
class LoadServiceProviderDetails extends ServiceProviderDetailEvent {
  final String providerId;
  const LoadServiceProviderDetails({required this.providerId});
  @override
  List<Object?> get props => [providerId];
}

/// **ADDED:** Event triggered when the user taps the favorite button.
class ToggleFavoriteStatus extends ServiceProviderDetailEvent {
  final String providerId; // ID of the provider being favorited/unfavorited
  final bool
      currentStatus; // The current favorite status (true if favorited, false if not)

  const ToggleFavoriteStatus({
    required this.providerId,
    required this.currentStatus,
  });

  @override
  List<Object?> get props => [providerId, currentStatus];
}

// Add other events later if needed (e.g., InitiateBooking)
