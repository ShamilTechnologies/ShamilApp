// lib/feature/details/bloc/service_details_state.dart

part of 'service_details_bloc.dart';

/// Represents the reservation-specific details for an in-progress reservation
class ReservationDetails extends Equatable {
  final double basePrice;
  final double totalPrice;
  final double? addOnsPrice;
  final bool isFullVenue;
  final int reservedCapacity;
  final bool isCommunityVisible;
  final String? hostingCategory;
  final String? hostingDescription;
  final List<AttendeeModel>? attendees;
  final Map<String, dynamic>? costSplitDetails;
  final String? notes;

  const ReservationDetails({
    required this.basePrice,
    required this.totalPrice,
    this.addOnsPrice,
    required this.isFullVenue,
    required this.reservedCapacity,
    required this.isCommunityVisible,
    this.hostingCategory,
    this.hostingDescription,
    this.attendees,
    this.costSplitDetails,
    this.notes,
  });

  ReservationDetails copyWith({
    double? basePrice,
    double? totalPrice,
    double? addOnsPrice,
    bool? isFullVenue,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    List<AttendeeModel>? attendees,
    Map<String, dynamic>? costSplitDetails,
    String? notes,
    bool clearCostSplitDetails = false,
  }) {
    return ReservationDetails(
      basePrice: basePrice ?? this.basePrice,
      totalPrice: totalPrice ?? this.totalPrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      isFullVenue: isFullVenue ?? this.isFullVenue,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendees: attendees ?? this.attendees,
      costSplitDetails: clearCostSplitDetails
          ? null
          : (costSplitDetails ?? this.costSplitDetails),
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        basePrice,
        totalPrice,
        addOnsPrice,
        isFullVenue,
        reservedCapacity,
        isCommunityVisible,
        hostingCategory,
        hostingDescription,
        attendees,
        costSplitDetails,
        notes,
      ];
}

/// Base state class for service details states
abstract class ServiceDetailsState extends Equatable {
  const ServiceDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class ServiceDetailsInitial extends ServiceDetailsState {}

/// State indicating that service provider details are being loaded.
class ServiceDetailsLoading extends ServiceDetailsState {}

/// State when details have been successfully loaded.
class ServiceDetailsLoaded extends ServiceDetailsState {
  /// The full details of the service provider.
  final ServiceProviderModel providerDetails;

  /// Available subscription plans
  final List<PlanModel> plans;

  /// Available services
  final List<ServiceModel> services;

  /// Whether the provider is favorited by the user
  final bool isFavorite;

  /// Currently selected plan (if any)
  final PlanModel? selectedPlan;

  /// Currently selected service (if any)
  final ServiceModel? selectedService;

  /// Reservation configuration details (if a service is selected)
  final ReservationDetails? reservationDetails;

  const ServiceDetailsLoaded({
    required this.providerDetails,
    required this.plans,
    required this.services,
    required this.isFavorite,
    this.selectedPlan,
    this.selectedService,
    this.reservationDetails,
  });

  @override
  List<Object?> get props => [
        providerDetails,
        plans,
        services,
        isFavorite,
        selectedPlan,
        selectedService,
        reservationDetails,
      ];

  ServiceDetailsLoaded copyWith({
    ServiceProviderModel? providerDetails,
    List<PlanModel>? plans,
    List<ServiceModel>? services,
    bool? isFavorite,
    PlanModel? selectedPlan,
    ServiceModel? selectedService,
    ReservationDetails? reservationDetails,
    bool clearSelectedPlan = false,
    bool clearSelectedService = false,
    bool clearReservationDetails = false,
  }) {
    return ServiceDetailsLoaded(
      providerDetails: providerDetails ?? this.providerDetails,
      plans: plans ?? this.plans,
      services: services ?? this.services,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedPlan:
          clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
      selectedService: clearSelectedService
          ? null
          : (selectedService ?? this.selectedService),
      reservationDetails: clearReservationDetails
          ? null
          : (reservationDetails ?? this.reservationDetails),
    );
  }
}

/// State when a processing operation is in progress
class ServiceDetailsProcessing extends ServiceDetailsLoaded {
  const ServiceDetailsProcessing({
    required super.providerDetails,
    required super.plans,
    required super.services,
    required super.isFavorite,
    super.selectedPlan,
    super.selectedService,
    super.reservationDetails,
  });
}

/// State when an operation has been confirmed
class ServiceDetailsConfirmed extends ServiceDetailsLoaded {
  final String message;
  final String? confirmationId;

  const ServiceDetailsConfirmed({
    required super.providerDetails,
    required super.plans,
    required super.services,
    required super.isFavorite,
    super.selectedPlan,
    super.selectedService,
    super.reservationDetails,
    required this.message,
    this.confirmationId,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        message,
        confirmationId,
      ];
}

/// State indicating an error occurred while loading service details.
class ServiceDetailsError extends ServiceDetailsLoaded {
  final String message;

  ServiceDetailsError({
    required this.message,
    ServiceProviderModel? providerDetails,
    List<PlanModel> plans = const [],
    List<ServiceModel> services = const [],
    bool isFavorite = false,
    PlanModel? selectedPlan,
    ServiceModel? selectedService,
    ReservationDetails? reservationDetails,
  }) : super(
          providerDetails: providerDetails ?? ServiceProviderModel.empty,
          plans: plans,
          services: services,
          isFavorite: isFavorite,
          selectedPlan: selectedPlan,
          selectedService: selectedService,
          reservationDetails: reservationDetails,
        );

  @override
  List<Object?> get props => [...super.props, message];
}
