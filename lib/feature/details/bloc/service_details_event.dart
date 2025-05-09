// lib/feature/service_details/bloc/service_details_event.dart

part of 'service_details_bloc.dart';

abstract class ServiceDetailsEvent extends Equatable {
  const ServiceDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all details for a specific service provider,
/// including their profile information, plans, and services.
class LoadServiceDetails extends ServiceDetailsEvent {
  final String providerId;

  const LoadServiceDetails({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

/// Event triggered when a user selects a specific plan.
/// This might be used to pre-fetch or prepare data for the options configuration screen.
/// Alternatively, navigation might handle passing the plan ID directly.
class PlanSelected extends ServiceDetailsEvent {
  final String planId;
  final String providerId; // For context

  const PlanSelected({required this.planId, required this.providerId});

  @override
  List<Object?> get props => [planId, providerId];
}

/// Event triggered when a user selects a specific service.
class ServiceSelected extends ServiceDetailsEvent {
  final String serviceId;
  final String providerId; // For context

  const ServiceSelected({required this.serviceId, required this.providerId});

  @override
  List<Object?> get props => [serviceId, providerId];
}

// Add other events if needed, for example, to toggle favorite status
// directly on the details page if that functionality exists there too.
// class ToggleFavoriteServiceDetails extends ServiceDetailsEvent {
//   final String providerId;
//   final bool currentStatus;
//
//   const ToggleFavoriteServiceDetails({required this.providerId, required this.currentStatus});
//
//   @override
//   List<Object?> get props => [providerId, currentStatus];
// }
