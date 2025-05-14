// lib/feature/details/bloc/service_details_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/reservation_repository.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/bloc/reservation_bloc.dart';

part 'service_details_event.dart';
part 'service_details_state.dart';

/// BLoC to manage service details, plans, and services, integrated with reservations.
///
/// Provides state management for the service provider detail screen, including
/// loading provider details, handling favorites, and now managing reservations,
/// with enhanced features like venue capacity, cost splitting, and community hosting.
class ServiceDetailsBloc
    extends Bloc<ServiceDetailsEvent, ServiceDetailsState> {
  final ServiceProviderDetailRepository _detailRepository;
  final FavoritesBloc _favoritesBloc;
  final ReservationRepository _reservationRepository;
  StreamSubscription? _favoriteStatusSubscription;
  StreamSubscription? _reservationStatusSubscription;

  ServiceDetailsBloc({
    required ServiceProviderDetailRepository detailRepository,
    required FavoritesBloc favoritesBloc,
    required ReservationRepository reservationRepository,
  })  : _detailRepository = detailRepository,
        _favoritesBloc = favoritesBloc,
        _reservationRepository = reservationRepository,
        super(ServiceDetailsInitial()) {
    // Register event handlers
    on<LoadServiceDetails>(_onLoadServiceDetails);
    on<ToggleFavoriteStatus>(_onToggleFavoriteStatus);
    on<PlanSelected>(_onPlanSelected);
    on<ServiceSelected>(_onServiceSelected);
    on<SetReservationCapacity>(_onSetReservationCapacity);
    on<SetAttendeePayment>(_onSetAttendeePayment);
    on<SetCommunityVisibility>(_onSetCommunityVisibility);
    on<UpdateCostSplitting>(_onUpdateCostSplitting);
    on<InitiateReservation>(_onInitiateReservation);
    on<CancelReservation>(_onCancelReservation);
    on<AddAttendee>(_onAddAttendee);
    on<RemoveAttendee>(_onRemoveAttendee);
    on<UpdateAttendeePayment>(_onUpdateAttendeePayment);

    // Listen to changes in favorites state
    _favoriteStatusSubscription = _favoritesBloc.stream.listen((favState) {
      if (favState is FavoritesLoaded && state is ServiceDetailsLoaded) {
        final currentState = state as ServiceDetailsLoaded;
        final provider = currentState.providerDetails;

        if (provider.id.isNotEmpty) {
          final newFavoriteStatus = favState.isProviderInFavorites(provider.id);
          if (currentState.isFavorite != newFavoriteStatus) {
            emit(currentState.copyWith(isFavorite: newFavoriteStatus));
          }
        }
      }
    });

    // Optional: Listen to reservation updates if needed
    // This could notify the user of changes to their reservations
    // _reservationStatusSubscription = ...
  }

  /// Loads service provider details including plans and services
  Future<void> _onLoadServiceDetails(
    LoadServiceDetails event,
    Emitter<ServiceDetailsState> emit,
  ) async {
    emit(ServiceDetailsLoading());
    try {
      // Fetch provider details from repository
      final provider =
          await _detailRepository.fetchServiceProviderDetails(event.providerId);

      // Check favorite status
      bool isFavorite = false;
      try {
        isFavorite = _favoritesBloc.isProviderFavorite(event.providerId);
      } catch (e) {
        print('Error checking favorite status: $e');
      }

      // Fetch plans and services if available
      List<PlanModel> plans = [];
      List<ServiceModel> services = [];

      try {
        if (provider.hasSubscriptionsEnabled) {
          plans = await _detailRepository.fetchProviderPlans(event.providerId);
        }

        if (provider.hasReservationsEnabled) {
          services =
              await _detailRepository.fetchProviderServices(event.providerId);
        }
      } catch (e) {
        print('Error fetching plans or services: $e');
        // Continue with partial data rather than failing completely
      }

      // Emit loaded state with all data
      emit(ServiceDetailsLoaded(
        providerDetails: provider,
        plans: plans,
        services: services,
        isFavorite: isFavorite,
      ));

      // Also request a check to ensure we have the latest favorite status
      _favoritesBloc.add(CheckFavoriteStatus(event.providerId));
    } catch (e) {
      emit(ServiceDetailsError(message: e.toString()));
    }
  }

  /// Toggles the favorite status of a provider
  void _onToggleFavoriteStatus(
    ToggleFavoriteStatus event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      // Update UI immediately for responsiveness
      emit(currentState.copyWith(isFavorite: !currentState.isFavorite));

      // Use the centralized FavoritesBloc to handle the actual toggle
      final displayModel = ServiceProviderDisplayModel.fromServiceProviderModel(
          currentState.providerDetails, true);
      _favoritesBloc.add(ToggleFavorite(displayModel));
    }
  }

  /// Handles plan selection for subscriptions
  void _onPlanSelected(
    PlanSelected event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;
      final selectedPlan = currentState.plans.firstWhere(
        (plan) => plan.id == event.planId,
        orElse: () => throw Exception('Plan not found'),
      );

      emit(currentState.copyWith(
        selectedPlan: selectedPlan,
        selectedService: null, // Clear service selection
      ));
    }
  }

  /// Handles service selection for reservations
  void _onServiceSelected(
    ServiceSelected event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;
      final selectedService = currentState.services.firstWhere(
        (service) => service.id == event.serviceId,
        orElse: () => throw Exception('Service not found'),
      );

      emit(currentState.copyWith(
        selectedService: selectedService,
        selectedPlan: null, // Clear plan selection
        reservationDetails: ReservationDetails(
          reservedCapacity: currentState.providerDetails.minGroupSize ?? 1,
          isFullVenue: false,
          basePrice: selectedService.price,
          totalPrice: selectedService.price,
          isCommunityVisible: false,
        ),
      ));
    }
  }

  /// Handles setting venue capacity and full venue status
  void _onSetReservationCapacity(
    SetReservationCapacity event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Calculate new total price based on capacity
      final basePrice = currentState.reservationDetails!.basePrice;
      final newTotalPrice = event.isFullVenue
          ? basePrice * 1.5
          : // Full venue premium
          basePrice *
              (event.capacity / currentState.providerDetails.maxCapacity);

      // Update reservation details
      final newDetails = currentState.reservationDetails!.copyWith(
        isFullVenue: event.isFullVenue,
        reservedCapacity: event.capacity,
        totalPrice: newTotalPrice,
      );

      // Recalculate attendee payments if cost splitting is enabled
      if (newDetails.costSplitDetails != null) {
        _recalculateAttendeePayments(newDetails);
      }

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Updates payment status for an attendee
  void _onSetAttendeePayment(
    SetAttendeePayment event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Update attendee list with new payment status
      final currentAttendees = currentState.reservationDetails!.attendees ?? [];
      List<AttendeeModel> updatedAttendees = [];

      bool found = false;
      for (var attendee in currentAttendees) {
        if (attendee.userId == event.attendeeId) {
          found = true;

          // Calculate amount if needed
          double? finalAmount = event.amount;
          if ((event.status == PaymentStatus.complete ||
                  event.status == PaymentStatus.partial) &&
              finalAmount == null) {
            // Calculate based on split settings or default
            finalAmount = _calculateAttendeeAmount(
              attendee,
              currentState.reservationDetails!.totalPrice,
              currentAttendees.length,
              currentState.reservationDetails!.costSplitDetails,
            );
          }

          updatedAttendees.add(attendee.copyWith(
            paymentStatus: event.status,
            amountToPay: finalAmount,
          ));
        } else {
          updatedAttendees.add(attendee);
        }
      }

      // If attendee not found, might need to add them
      if (!found && event.attendee != null) {
        updatedAttendees.add(event.attendee!);
      }

      // Update reservation details with new attendee list
      final newDetails = currentState.reservationDetails!.copyWith(
        attendees: updatedAttendees,
      );

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Sets community visibility for social reservations
  void _onSetCommunityVisibility(
    SetCommunityVisibility event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Update community visibility settings
      final newDetails = currentState.reservationDetails!.copyWith(
        isCommunityVisible: event.isVisible,
        hostingCategory: event.isVisible ? event.category : null,
        hostingDescription: event.isVisible ? event.description : null,
      );

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Updates cost splitting settings between attendees
  void _onUpdateCostSplitting(
    UpdateCostSplitting event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Don't allow cost splitting for full venue
      if (currentState.reservationDetails!.isFullVenue && event.enabled) {
        return;
      }

      // Create cost split details
      final costSplitDetails = {
        'enabled': event.enabled,
        'splitMethod': event.method,
        if (event.method == 'custom' && event.customRatios != null)
          'customSplitRatio': event.customRatios,
      };

      // Update attendee amounts based on new split settings
      final attendees = currentState.reservationDetails!.attendees ?? [];
      final updatedAttendees = attendees.map((attendee) {
        final amount = _calculateAttendeeAmount(
          attendee,
          currentState.reservationDetails!.totalPrice,
          attendees.length,
          costSplitDetails,
        );

        return attendee.copyWith(amountToPay: amount);
      }).toList();

      // Update reservation details
      final newDetails = currentState.reservationDetails!.copyWith(
        costSplitDetails: costSplitDetails,
        attendees: updatedAttendees,
      );

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Initiates a reservation or subscription
  Future<void> _onInitiateReservation(
    InitiateReservation event,
    Emitter<ServiceDetailsState> emit,
  ) async {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      // Validate we have either a service or plan selected
      if (currentState.selectedService == null &&
          currentState.selectedPlan == null) {
        emit(ServiceDetailsError(
          message: "Please select a service or plan first",
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
        ));
        return;
      }

      // Update state to show loading
      emit(ServiceDetailsProcessing(
        providerDetails: currentState.providerDetails,
        plans: currentState.plans,
        services: currentState.services,
        isFavorite: currentState.isFavorite,
        selectedPlan: currentState.selectedPlan,
        selectedService: currentState.selectedService,
        reservationDetails: currentState.reservationDetails,
      ));

      try {
        // Determine if this is for a service or plan
        if (currentState.selectedService != null) {
          // Handle reservation creation
          await _createReservation(currentState, event.date, event.timeSlot);
        } else if (currentState.selectedPlan != null) {
          // Handle subscription creation
          await _createSubscription(currentState, event.date);
        }

        // Success - emit confirmation state
        emit(ServiceDetailsConfirmed(
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
          selectedPlan: currentState.selectedPlan,
          selectedService: currentState.selectedService,
          reservationDetails: currentState.reservationDetails,
          message:
              "Your ${currentState.selectedService != null ? 'reservation' : 'subscription'} has been confirmed!",
        ));
      } catch (e) {
        print('Error creating reservation: $e');
        // Revert to loaded state with error
        emit(ServiceDetailsError(
          message:
              "Failed to ${currentState.selectedService != null ? 'make reservation' : 'create subscription'}: ${e.toString()}",
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
          selectedPlan: currentState.selectedPlan,
          selectedService: currentState.selectedService,
          reservationDetails: currentState.reservationDetails,
        ));
      }
    }
  }

  /// Cancels an existing reservation
  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ServiceDetailsState> emit,
  ) async {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      // Update state to show loading
      emit(ServiceDetailsProcessing(
        providerDetails: currentState.providerDetails,
        plans: currentState.plans,
        services: currentState.services,
        isFavorite: currentState.isFavorite,
        selectedPlan: currentState.selectedPlan,
        selectedService: currentState.selectedService,
        reservationDetails: currentState.reservationDetails,
      ));

      try {
        // Call repository to cancel reservation
        await _reservationRepository.cancelReservation(event.reservationId);

        // Success - emit confirmed state
        emit(ServiceDetailsConfirmed(
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
          message: "Your reservation has been cancelled",
        ));
      } catch (e) {
        // Revert to loaded state with error
        emit(ServiceDetailsError(
          message: "Failed to cancel reservation: ${e.toString()}",
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
        ));
      }
    }
  }

  /// Helper method to create a reservation through the repository
  Future<String> _createReservation(
    ServiceDetailsLoaded state,
    DateTime date,
    String timeSlot,
  ) async {
    if (state.selectedService == null || state.reservationDetails == null) {
      throw Exception("Missing service or reservation details");
    }

    // Parse time slot into start/end times
    final timeParts = timeSlot.split('-');
    if (timeParts.length != 2) {
      throw Exception("Invalid time slot format");
    }

    // Parse start and end times
    final startTimeParts = timeParts[0].trim().split(':');
    final endTimeParts = timeParts[1].trim().split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    // Create start and end timestamps
    final startDateTime =
        DateTime(date.year, date.month, date.day, startHour, startMinute);
    final endDateTime =
        DateTime(date.year, date.month, date.day, endHour, endMinute);

    // Convert to timestamps
    final startTimestamp = Timestamp.fromDate(startDateTime);
    final endTimestamp = Timestamp.fromDate(endDateTime);

    // Build reservation payload
    final payload = {
      'providerId': state.providerDetails.id,
      'governorateId': state.providerDetails.governorateId,
      'serviceId': state.selectedService!.id,
      'serviceName': state.selectedService!.name,
      'type': state.selectedService!.category.contains('Time')
          ? 'time-based'
          : state.selectedService!.category.toLowerCase().replaceAll(' ', '-'),
      'reservationStartTime': startTimestamp,
      'endTime': endTimestamp,
      'groupSize': state.reservationDetails!.reservedCapacity,
      'isFullVenueReservation': state.reservationDetails!.isFullVenue,
      'reservedCapacity': state.reservationDetails!.reservedCapacity,
      'durationMinutes': state.selectedService!.estimatedDurationMinutes,
      'totalPrice': state.reservationDetails!.totalPrice,
      'isCommunityVisible': state.reservationDetails!.isCommunityVisible,
      if (state.reservationDetails!.isCommunityVisible) ...{
        'hostingCategory': state.reservationDetails!.hostingCategory,
        'hostingDescription': state.reservationDetails!.hostingDescription,
      },
      if (state.reservationDetails!.costSplitDetails != null)
        'costSplitDetails': state.reservationDetails!.costSplitDetails,
      if (state.reservationDetails!.attendees != null &&
          state.reservationDetails!.attendees!.isNotEmpty)
        'attendees':
            state.reservationDetails!.attendees!.map((a) => a.toMap()).toList(),
    };

    // Call the repository to create the reservation
    final result =
        await _reservationRepository.createReservationOnBackend(payload);

    if (result['success'] != true) {
      throw Exception(result['error'] ?? "Unknown error creating reservation");
    }

    return result['reservationId'] as String? ?? '';
  }

  /// Helper method to create a subscription through the repository
  Future<String> _createSubscription(
    ServiceDetailsLoaded state,
    DateTime startDate,
  ) async {
    if (state.selectedPlan == null) {
      throw Exception("Missing subscription plan");
    }

    // Build subscription payload
    final payload = {
      'providerId': state.providerDetails.id,
      'planId': state.selectedPlan!.id,
      'planName': state.selectedPlan!.name,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(
          _calculateExpiryDate(startDate, state.selectedPlan!)),
      'pricePaid': state.selectedPlan!.price,
      'billingCycle': state.selectedPlan!.billingCycle,
      // Add other subscription-specific fields here
    };

    // Call repository to create subscription
    final result = await _reservationRepository.createSubscription(payload);

    if (result['success'] != true) {
      throw Exception(result['error'] ?? "Unknown error creating subscription");
    }

    return result['subscriptionId'] as String? ?? '';
  }

  /// Calculates the expiry date based on billing cycle
  DateTime _calculateExpiryDate(DateTime startDate, PlanModel plan) {
    final cycle = plan.billingCycle.toLowerCase();

    if (cycle.contains('day')) {
      return startDate.add(const Duration(days: 1));
    } else if (cycle.contains('week')) {
      return startDate.add(const Duration(days: 7));
    } else if (cycle.contains('month')) {
      // Simple month calculation (not exact for variable length months)
      return DateTime(startDate.year, startDate.month + 1, startDate.day);
    } else if (cycle.contains('year') || cycle.contains('annual')) {
      return DateTime(startDate.year + 1, startDate.month, startDate.day);
    } else {
      // Default to 30 days if unknown
      return startDate.add(const Duration(days: 30));
    }
  }

  /// Helper method to calculate attendee amount based on split settings
  double _calculateAttendeeAmount(
    AttendeeModel attendee,
    double totalPrice,
    int totalAttendees,
    Map<String, dynamic>? costSplitDetails,
  ) {
    if (totalPrice <= 0 || totalAttendees <= 0) return 0.0;

    // If attendee has already fully paid or is covered, their amount is 0
    if (attendee.paymentStatus == PaymentStatus.complete ||
        attendee.paymentStatus == PaymentStatus.hosted ||
        attendee.paymentStatus == PaymentStatus.waived) {
      return 0.0;
    }

    bool splitEnabled = costSplitDetails?['enabled'] ?? false;
    String splitMethod = costSplitDetails?['splitMethod'] ?? 'equal';

    // If splitting is explicitly disabled, assume the primary booker ('self') pays all
    if (!splitEnabled) {
      return attendee.type == 'self' ? totalPrice : 0.0;
    }

    // If attendee is the host ('self')
    bool isSelf = attendee.type == 'self';

    switch (splitMethod) {
      case 'host_pays':
        // Host pays everything, others pay 0
        return isSelf ? totalPrice : 0.0;
      case 'equal':
        // Equal split among all attendees
        return totalPrice / totalAttendees;
      case 'custom':
        Map<String, double>? customRatios =
            (costSplitDetails?['customSplitRatio'] as Map?)
                ?.cast<String, double>();
        // Default to equal share if custom ratio is missing for the user
        double ratio = customRatios?[attendee.userId] ?? (1.0 / totalAttendees);
        return totalPrice * ratio;
      case 'self_pays':
        // Each person pays an equal share (same as 'equal')
        return totalPrice / totalAttendees;
      default:
        // Default to equal split
        return totalPrice / totalAttendees;
    }
  }

  /// Handles adding a new attendee
  void _onAddAttendee(
    AddAttendee event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Check capacity limit
      final currentAttendees = currentState.reservationDetails!.attendees ?? [];
      if (currentAttendees.length >=
          currentState.reservationDetails!.reservedCapacity) {
        emit(ServiceDetailsError(
          message: "Maximum capacity reached",
          providerDetails: currentState.providerDetails,
          plans: currentState.plans,
          services: currentState.services,
          isFavorite: currentState.isFavorite,
        ));
        return;
      }

      // Add new attendee
      final updatedAttendees = [...currentAttendees, event.attendee];

      // Update reservation details
      final newDetails = currentState.reservationDetails!.copyWith(
        attendees: updatedAttendees,
      );

      // Recalculate payments if cost splitting is enabled
      if (newDetails.costSplitDetails != null) {
        _recalculateAttendeePayments(newDetails);
      }

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Handles removing an attendee
  void _onRemoveAttendee(
    RemoveAttendee event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Remove attendee
      final currentAttendees = currentState.reservationDetails!.attendees ?? [];
      final updatedAttendees =
          currentAttendees.where((a) => a.userId != event.attendeeId).toList();

      // Update reservation details
      final newDetails = currentState.reservationDetails!.copyWith(
        attendees: updatedAttendees,
      );

      // Recalculate payments if cost splitting is enabled
      if (newDetails.costSplitDetails != null) {
        _recalculateAttendeePayments(newDetails);
      }

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Handles updating an attendee's payment status
  void _onUpdateAttendeePayment(
    UpdateAttendeePayment event,
    Emitter<ServiceDetailsState> emit,
  ) {
    if (state is ServiceDetailsLoaded) {
      final currentState = state as ServiceDetailsLoaded;

      if (currentState.reservationDetails == null) {
        return;
      }

      // Update attendee payment
      final currentAttendees = currentState.reservationDetails!.attendees ?? [];
      final updatedAttendees = currentAttendees.map((attendee) {
        if (attendee.userId == event.attendeeId) {
          return attendee.copyWith(
            paymentStatus: event.status,
            amountPaid: event.amountPaid,
          );
        }
        return attendee;
      }).toList();

      // Update reservation details
      final newDetails = currentState.reservationDetails!.copyWith(
        attendees: updatedAttendees,
      );

      emit(currentState.copyWith(reservationDetails: newDetails));
    }
  }

  /// Helper method to recalculate attendee payments based on cost splitting settings
  void _recalculateAttendeePayments(ReservationDetails details) {
    if (details.costSplitDetails == null || details.attendees == null) {
      return;
    }

    final splitType = details.costSplitDetails!['type'] as String;
    final attendees = details.attendees!;

    switch (splitType) {
      case 'equal':
        final perPersonAmount = details.totalPrice / attendees.length;
        for (var i = 0; i < attendees.length; i++) {
          attendees[i] = attendees[i].copyWith(amountToPay: perPersonAmount);
        }
        break;

      case 'host_pays':
        // Host (first attendee) pays all
        if (attendees.isNotEmpty) {
          attendees[0] = attendees[0].copyWith(amountToPay: details.totalPrice);
          for (var i = 1; i < attendees.length; i++) {
            attendees[i] = attendees[i].copyWith(amountToPay: 0.0);
          }
        }
        break;

      case 'custom':
        final ratios =
            details.costSplitDetails!['ratios'] as Map<String, double>;
        for (var i = 0; i < attendees.length; i++) {
          final ratio = ratios[attendees[i].userId] ?? 1.0;
          attendees[i] =
              attendees[i].copyWith(amountToPay: details.totalPrice * ratio);
        }
        break;
    }
  }

  @override
  Future<void> close() {
    _favoriteStatusSubscription?.cancel();
    _reservationStatusSubscription?.cancel();
    return super.close();
  }
}
