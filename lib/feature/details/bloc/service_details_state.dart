// lib/feature/service_details/bloc/service_details_state.dart

part of 'service_details_bloc.dart';

abstract class ServiceDetailsState extends Equatable {
  const ServiceDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class ServiceDetailsInitial extends ServiceDetailsState {}

/// State indicating that service provider details, plans, and services are being loaded.
class ServiceDetailsLoading extends ServiceDetailsState {
  final String providerId; // Keep track of which provider is being loaded

  const ServiceDetailsLoading({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

/// State representing successfully loaded service provider details, plans, and services.
class ServiceDetailsLoaded extends ServiceDetailsState {
  /// The full details of the service provider.
  /// This could be your existing ServiceProviderDisplayModel if it's comprehensive enough,
  /// or a more detailed model specific to this screen.
  /// For now, let's assume it's the ServiceProviderDisplayModel from the home feature,
  /// but you might need to fetch more data or have a dedicated model.
  final ServiceProviderDisplayModel providerDetails;

  final List<PlanModel> plans;
  final List<ServiceModel> services;

  const ServiceDetailsLoaded({
    required this.providerDetails,
    required this.plans,
    required this.services,
  });

  @override
  List<Object?> get props => [providerDetails, plans, services];

  ServiceDetailsLoaded copyWith({
    ServiceProviderDisplayModel? providerDetails,
    List<PlanModel>? plans,
    List<ServiceModel>? services,
  }) {
    return ServiceDetailsLoaded(
      providerDetails: providerDetails ?? this.providerDetails,
      plans: plans ?? this.plans,
      services: services ?? this.services,
    );
  }
}

/// State indicating an error occurred while loading service details.
class ServiceDetailsError extends ServiceDetailsState {
  final String message;
  final String providerId; // ID of the provider for which loading failed

  const ServiceDetailsError({required this.message, required this.providerId});

  @override
  List<Object?> get props => [message, providerId];
}

/// Optional: State to indicate navigation to the Options Configuration Screen.
/// This can be useful if the BLoC needs to manage navigation triggers or pass complex data.
/// Alternatively, the UI can handle navigation directly upon user interaction.
class NavigatingToOptionsConfiguration extends ServiceDetailsState {
  final String providerId;
  final String? selectedPlanId;
  final String? selectedServiceId;
  // You can add the actual PlanModel or ServiceModel here if needed for the next screen
  final PlanModel? plan;
  final ServiceModel? service;


  const NavigatingToOptionsConfiguration({
    required this.providerId,
    this.selectedPlanId,
    this.selectedServiceId,
    this.plan,
    this.service,
  }) : assert(selectedPlanId != null || selectedServiceId != null,
            'Either selectedPlanId or selectedServiceId must be provided');


  @override
  List<Object?> get props => [providerId, selectedPlanId, selectedServiceId, plan, service];
}
