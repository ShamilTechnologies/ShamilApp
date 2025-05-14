// lib/feature/reservation/bloc/reservation_bloc.dart

import 'dart:async'; // Import async
import 'dart:math'; // Import for min/max

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for userId
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/material.dart'; // For TimeOfDay, BuildContext (for formatting in handler)
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';

// Import the UPDATED models and repository
// Assuming AccessPassOption model exists and is imported correctly if used
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/reservation_repository.dart';

// Define the parts for Bloc structure
part 'reservation_event.dart';
part 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReservationRepository _reservationRepository;

  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.displayName;

  ReservationBloc({
    required ServiceProviderModel provider,
    required ReservationRepository reservationRepository,
  })  : _reservationRepository = reservationRepository,
        // Initialize with provider and potentially default price/capacity info
        super(ReservationInitial(
            provider: provider,
            reservedCapacity: provider.minGroupSize ??
                1, // Default to min capacity if available
            basePrice: _calculateBasePrice(
                provider,
                null,
                provider.minGroupSize ?? 1,
                false), // Initial price based on min capacity
            totalPrice: _calculateTotalPrice(
                basePrice: _calculateBasePrice(
                    provider, null, provider.minGroupSize ?? 1, false),
                addOnsPrice: 0.0))) {
    // Existing event handlers
    on<SelectReservationType>(_onSelectReservationType);
    on<SelectReservationService>(_onSelectReservationService);
    on<SelectReservationDate>(_onSelectReservationDate);
    on<UpdateSwipeSelection>(_onUpdateSwipeSelection);
    on<AddAttendee>(_onAddAttendee);
    on<RemoveAttendee>(_onRemoveAttendee);
    on<CreateReservation>(_onCreateReservation);
    on<ResetReservationFlow>(_onResetReservationFlow);
    on<SelectSequenceTimeSlot>(_onSelectSequenceTimeSlot);
    on<JoinQueue>(_onJoinQueue);
    on<CheckQueueStatus>(_onCheckQueueStatus);
    on<LeaveQueue>(_onLeaveQueue);
    on<SelectAccessPassOption>(_onSelectAccessPassOption);

    // New event handlers
    on<SetVenueCapacity>(_onSetVenueCapacity);
    on<SetAttendeePaymentStatus>(_onSetAttendeePaymentStatus);
    on<SetCommunityVisibility>(_onSetCommunityVisibility);
    on<UpdateCostSplitSettings>(_onUpdateCostSplitSettings);

    _initializeAttendees(provider);
    debugPrint(
        "ReservationBloc Initialized for Provider ID: ${state.provider?.id}");
  }

  void _initializeAttendees(ServiceProviderModel provider) {
    if (_userId != null && _userName != null) {
      final initialState = state;
      final initialAttendee = AttendeeModel(
        userId: _userId!,
        name: _userName!,
        type: 'self',
        status: 'going', // Default status
        paymentStatus: PaymentStatus.pending, // Default payment status
        amountToPay: state.totalPrice, // Initially, self pays total
      );

      // Update state with initial attendee and recalculated amounts
      final attendees = [initialAttendee];
      final updatedState = initialState.copyWith(
          selectedAttendees: attendees,
          // Recalculate amounts based on initial state (likely just self paying total)
          totalPrice: _calculateTotalPrice(
              basePrice: state.basePrice, addOnsPrice: state.addOnsPrice));

      // Ensure amounts are updated in attendees list based on potentially updated total price and split settings
      final attendeesWithAmounts = _updateAttendeeAmounts(updatedState);

      emit(updatedState.copyWith(selectedAttendees: attendeesWithAmounts));
      debugPrint("ReservationBloc: Initialized attendees with 'self'.");
    } else {
      debugPrint(
          "ReservationBloc WARN: User not logged in during initialization.");
      // Emit error state? Or allow anonymous booking? Depends on requirements.
      emit(ReservationError(
          message: "User not logged in. Cannot initialize reservation.",
          provider: provider));
    }
  }

  // --- Helper Functions ---

  static int _getProviderCapacity(ServiceProviderModel? provider) {
    return provider?.totalCapacity ??
        provider?.maxGroupSize ??
        999; // Use totalCapacity first
  }

  static double _calculateBasePrice(ServiceProviderModel? provider,
      BookableService? service, int capacity, bool isFullVenue) {
    if (provider == null) return 0.0;

    if (isFullVenue) {
      // Use explicit full venue price if available, otherwise estimate
      return provider.fullVenuePrice ??
          (provider.pricePerPerson ?? service?.pricePerPerson ?? 20.0) *
              _getProviderCapacity(provider); // Example fallback
    } else {
      // Use service's per-person price first, then provider's, then service's base price, then fallback
      double unitPrice = service?.pricePerPerson ??
          provider.pricePerPerson ??
          20.0; // Example fallback price per unit
      // If service has a fixed price, it might override per-person calculation for that service
      if (service?.price != null && service?.price != 0) {
        // Decide if fixed service price applies regardless of capacity for partial booking
        // Let's assume fixed price is for the *service instance* (e.g., a specific class)
        // and per-person applies otherwise or if service price is zero/null.
        // If service price exists, use it; otherwise use unit * capacity.
        return service!
            .price!; // Assuming fixed price takes precedence if present
      }
      return unitPrice * capacity;
    }
  }

  // TODO: Implement Add-on price calculation based on selected add-ons
  static double _calculateAddOnsPrice(/* List<AddOn> selectedAddOns */) {
    // Sum prices of selected add-ons
    return 0.0; // Placeholder
  }

  static double _calculateTotalPrice(
      {required double basePrice, required double addOnsPrice}) {
    return basePrice + addOnsPrice;
  }

  static double _calculateAttendeeAmount(
      AttendeeModel attendee,
      double totalPrice,
      int totalAttendees,
      Map<String, dynamic>? costSplitDetails) {
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
        // Ensure ratios don't lead to over/under charging (optional, depends on validation)
        return totalPrice * ratio;
      case 'self_pays': // Interpretation: Each person pays an equal share (same as 'equal')
        return totalPrice / totalAttendees;
      default: // Default to equal split
        return totalPrice / totalAttendees;
    }
  }

  // Function to update attendee list with calculated amounts based on current state
  List<AttendeeModel> _updateAttendeeAmounts(ReservationState state) {
    if (state.selectedAttendees.isEmpty) return [];
    return state.selectedAttendees.map((attendee) {
      final amount = _calculateAttendeeAmount(
        attendee,
        state.totalPrice,
        state.selectedAttendees.length,
        state.costSplitDetails,
      );
      // Return new attendee model with updated amount
      return attendee.copyWith(amountToPay: amount);
    }).toList();
  }

  /// Checks if the reservation is ready to confirm based on the current state and type.
  /// Updated logic based on state properties.
  bool isReservationReadyToConfirm(ReservationState state) {
    final type = state.selectedReservationType;
    if (type == null) return false; // Need a type selected

    switch (type) {
      case ReservationType.timeBased:
        // Ready if a valid time range has been selected
        return state is ReservationRangeSelected &&
            state.selectedDate != null &&
            state.selectedStartTime != null &&
            state.selectedEndTime != null;
      case ReservationType.serviceBased:
        // Ready if service and date are selected. Time might be implicit or not needed.
        return state.selectedService != null && state.selectedDate != null;
      // Add check for selectedStartTime if specific slots are required for service-based too
      // && state.selectedStartTime != null;
      case ReservationType.seatBased:
        // Ready if service, date are selected. Needs seat selection logic added to state.
        // Placeholder: Assume ready if service and date selected for now.
        return state.selectedService != null && state.selectedDate != null;
      case ReservationType.recurring:
        // Ready if service, date (start date), and recurrence rule selected. Needs rule logic.
        // Placeholder: Assume ready if service and date selected for now.
        return state.selectedService != null && state.selectedDate != null;
      case ReservationType.group:
        // Similar to time-based or service-based depending on setup.
        // Let's assume requires date and service (if applicable) or time range.
        bool dateSelected = state.selectedDate != null;
        bool serviceSelected = state.selectedService != null;
        bool timeRangeSelected = state is ReservationRangeSelected &&
            state.selectedStartTime != null &&
            state.selectedEndTime != null;
        // Ready if date is selected AND (either a service is selected OR a time range is selected)
        return dateSelected && (serviceSelected || timeRangeSelected);
      case ReservationType.accessBased:
        // Ready if an access pass option has been selected.
        return state.typeSpecificData?['selectedAccessPassId'] != null;
      case ReservationType.sequenceBased:
        // Ready to *join* the queue if date and preferred hour are selected.
        // The actual reservation happens later. So "readyToConfirm" is not applicable here?
        // Let's interpret "ready" as ready to hit "Join Queue".
        return state.selectedDate != null &&
            state.selectedStartTime != null &&
            state.selectedService != null;
      case ReservationType.unknown:
        return false;
    }
  }

  // --- Event Handlers ---

  void _onSelectReservationType(
      SelectReservationType event, Emitter<ReservationState> emit) {
    debugPrint(
        "ReservationBloc: Reservation Type selected - ${event.reservationType.displayString}");
    final currentState = state;
    final currentProvider = currentState.provider;

    if (currentProvider == null) {
      emit(const ReservationError(
          message: "Provider context missing.", provider: null));
      return;
    }
    if (!currentProvider.supportedReservationTypes
        .contains(event.reservationType.typeString)) {
      // Use helper to emit error, preserving context
      emit(_emitError(
          "Provider does not support '${event.reservationType.displayString}' reservations.",
          currentState));
      return;
    }

    // Emit new state, potentially resetting some fields depending on type change
    emit(ReservationTypeSelected(
      provider: currentProvider,
      selectedReservationType: event.reservationType,
      selectedAttendees: currentState.selectedAttendees,
      typeSpecificData: currentState.typeSpecificData,
      // Pass other fields
      isFullVenueReservation: currentState.isFullVenueReservation,
      reservedCapacity: currentState.reservedCapacity,
      isCommunityVisible: currentState.isCommunityVisible,
      hostingCategory: currentState.hostingCategory,
      hostingDescription: currentState.hostingDescription,
      attendeePaymentStatuses: currentState.attendeePaymentStatuses,
      costSplitDetails: currentState.costSplitDetails,
      basePrice: currentState.basePrice,
      addOnsPrice: currentState.addOnsPrice,
      totalPrice: currentState.totalPrice,
    ));
  }

  void _onSelectReservationService(
      SelectReservationService event, Emitter<ReservationState> emit) {
    final currentState = state;
    final service = event.selectedService;
    final currentProvider = currentState.provider;
    final currentType = currentState.selectedReservationType;
    debugPrint(
        "ReservationBloc: Service selected - ${service?.name ?? 'General'}");

    if (currentProvider == null || currentType == null) {
      emit(_emitError("Provider or reservation type missing.", currentState));
      return;
    }
    // Optional: Check if service type matches flow type
    if (service != null &&
        service.type != ReservationType.unknown &&
        service.type != currentType) {
      debugPrint(
          "ReservationBloc: Warning - Selected service type (${service.type.displayString}) doesn't match flow type (${currentType.displayString}).");
    }

    // Recalculate price based on selected service and current capacity settings
    final newBasePrice = _calculateBasePrice(
        currentProvider,
        service,
        currentState.reservedCapacity ?? currentState.selectedAttendees.length,
        currentState.isFullVenueReservation);
    final newTotalPrice = _calculateTotalPrice(
        basePrice: newBasePrice, addOnsPrice: currentState.addOnsPrice);

    // Create the next state (either ServiceSelected or back to TypeSelected if service is null)
    final nextState = service != null
        ? ReservationServiceSelected(
            provider: currentProvider,
            selectedReservationType: currentType,
            service: service,
            selectedAttendees:
                currentState.selectedAttendees, // Keep attendees for now
            typeSpecificData: currentState.typeSpecificData,
            // Pass other fields
            isFullVenueReservation: currentState.isFullVenueReservation,
            reservedCapacity: currentState.reservedCapacity,
            isCommunityVisible: currentState.isCommunityVisible,
            hostingCategory: currentState.hostingCategory,
            hostingDescription: currentState.hostingDescription,
            attendeePaymentStatuses: currentState.attendeePaymentStatuses,
            costSplitDetails: currentState.costSplitDetails,
            basePrice: newBasePrice,
            addOnsPrice:
                currentState.addOnsPrice, // Add-ons price doesn't change here
            totalPrice: newTotalPrice,
          )
        : ReservationTypeSelected(
            // Go back if service deselected
            provider: currentProvider,
            selectedReservationType: currentType,
            selectedAttendees: currentState.selectedAttendees,
            typeSpecificData: currentState.typeSpecificData,
            // Pass other fields
            isFullVenueReservation: currentState.isFullVenueReservation,
            reservedCapacity: currentState.reservedCapacity,
            isCommunityVisible: currentState.isCommunityVisible,
            hostingCategory: currentState.hostingCategory,
            hostingDescription: currentState.hostingDescription,
            attendeePaymentStatuses: currentState.attendeePaymentStatuses,
            costSplitDetails: currentState.costSplitDetails,
            basePrice:
                newBasePrice, // Base price might revert if service deselected
            addOnsPrice: currentState.addOnsPrice,
            totalPrice: newTotalPrice,
          );

    // Update attendee amounts in the new state
    final attendeesWithAmounts = _updateAttendeeAmounts(nextState);
    emit(nextState.copyWith(selectedAttendees: attendeesWithAmounts));
  }

  Future<void> _onSelectReservationDate(
      SelectReservationDate event, Emitter<ReservationState> emit) async {
    final currentState = state;
    final currentService = currentState.selectedService;
    final currentType = currentState.selectedReservationType;
    final currentProvider = currentState.provider;
    final currentAttendees = currentState.selectedAttendees;

    if (currentProvider == null || currentType == null) {
      emit(_emitError("Provider or reservation type missing.", currentState));
      return;
    }
    final String? govId = currentProvider.governorateId;
    // Determine if fine-grained slots are needed
    bool requiresFineGrainedSlots = [
      ReservationType.timeBased,
      ReservationType.seatBased,
      ReservationType.recurring,
    ].contains(currentType);

    int? durationMinutes;
    if (requiresFineGrainedSlots) {
      durationMinutes = currentService?.durationMinutes ??
          _getTimeBasedDefaultDuration(currentProvider);
      if (durationMinutes <= 0) {
        emit(_emitError(
            "Invalid or missing service duration for fetching slots.",
            currentState.copyWith(selectedDate: event.selectedDate)));
        return;
      }
      debugPrint(
          "ReservationBloc: Using duration $durationMinutes min for slot fetching.");
    }

    debugPrint(
        "ReservationBloc: Date selected - ${event.selectedDate}, Type: ${currentType.displayString}, GovID: $govId");

    // Emit loading state for slots if needed
    emit(ReservationDateSelected(
      provider: currentProvider,
      selectedReservationType: currentType,
      selectedService: currentService,
      date: event.selectedDate,
      availableSlots: const [], // Clear old slots
      selectedAttendees: currentAttendees,
      isLoadingSlots: requiresFineGrainedSlots, // Set loading flag
      selectedStartTime: (currentType == ReservationType.sequenceBased)
          ? currentState.selectedStartTime
          : null, // Preserve queue hour
      selectedEndTime: null, // Reset end time
      typeSpecificData: currentState.typeSpecificData,
      // Pass other fields
      isFullVenueReservation: currentState.isFullVenueReservation,
      reservedCapacity: currentState.reservedCapacity,
      isCommunityVisible: currentState.isCommunityVisible,
      hostingCategory: currentState.hostingCategory,
      hostingDescription: currentState.hostingDescription,
      attendeePaymentStatuses: currentState.attendeePaymentStatuses,
      costSplitDetails: currentState.costSplitDetails,
      basePrice: currentState.basePrice,
      addOnsPrice: currentState.addOnsPrice,
      totalPrice: currentState.totalPrice,
    ));

    // Fetch slots if required
    if (requiresFineGrainedSlots) {
      try {
        if (govId == null || govId.isEmpty) {
          throw Exception(
              "Provider's governorate ID is missing, cannot fetch slots.");
        }
        final availableStartSlots =
            await _reservationRepository.fetchAvailableSlots(
          providerId: currentProvider.id,
          governorateId: govId,
          date: event.selectedDate,
          durationMinutes: durationMinutes!,
        );
        debugPrint(
            "ReservationBloc: Fetched ${availableStartSlots.length} available start slots.");

        // Check if state is still relevant before emitting
        final maybeCurrentState = state; // Capture state before async gap
        if (maybeCurrentState is ReservationDateSelected &&
            maybeCurrentState.selectedDate == event.selectedDate &&
            maybeCurrentState.selectedReservationType == currentType) {
          emit(maybeCurrentState.copyWith(
            availableSlots: availableStartSlots,
            isLoadingSlots: false, // Turn off loading
          ));
        } else {
          debugPrint(
              "ReservationBloc: State changed while fetching slots. Ignoring results.");
        }
      } catch (e) {
        debugPrint("ReservationBloc: Error fetching available slots: $e");
        // Emit error state, preserving context
        emit(_emitError("Failed to load availability: ${e.toString()}",
            state.copyWith(selectedDate: event.selectedDate)));
      }
    }
  }

  void _onSelectSequenceTimeSlot(
      SelectSequenceTimeSlot event, Emitter<ReservationState> emit) {
    final currentState = state;

    // Ensure we are in a state where selecting a sequence time makes sense
    if (currentState is ReservationDateSelected &&
        currentState.selectedReservationType == ReservationType.sequenceBased) {
      String formattedTime = event.preferredHour != null
          ? "${event.preferredHour!.hour}:${event.preferredHour!.minute.toString().padLeft(2, '0')}"
          : "None";
      debugPrint(
          "ReservationBloc: Preferred sequence hour selected: $formattedTime");

      // Update only the selectedStartTime (preferredHour)
      emit(currentState.copyWith(
        selectedStartTime:
            event.preferredHour, // This updates the preferred hour
        selectedEndTime: null, // Ensure end time is null for sequence-based
      ));
    } else {
      debugPrint(
          "ReservationBloc: Cannot select sequence time slot in current state: ${currentState.runtimeType} or incorrect reservation type/state.");
    }
  }

  void _onSelectAccessPassOption(
      SelectAccessPassOption event, Emitter<ReservationState> emit) {
    final currentState = state;
    if (currentState.provider == null ||
        currentState.selectedReservationType != ReservationType.accessBased) {
      debugPrint("ReservationBloc: Cannot select access pass, invalid state.");
      emit(_emitError("Cannot select access pass option in the current state.",
          currentState));
      return;
    }
    debugPrint(
        "ReservationBloc: Access Pass selected - ${event.option.label} (ID: ${event.option.id})");

    // Update the typeSpecificData with the selected pass ID
    // Also potentially update pricing if the pass affects it
    final newBasePrice = event.option.price ??
        currentState.basePrice; // Example: pass might have its own price
    final newTotalPrice = _calculateTotalPrice(
        basePrice: newBasePrice, addOnsPrice: currentState.addOnsPrice);

    final nextState = currentState.copyWith(
      typeSpecificData: {'selectedAccessPassId': event.option.id},
      // Reset other time/service specific fields if necessary for access-based
      selectedService: null,
      selectedDate: null,
      selectedStartTime: null,
      selectedEndTime: null,
      availableSlots: [],
      // Update price if needed
      basePrice: newBasePrice,
      totalPrice: newTotalPrice,
    );

    // Update attendee amounts based on potentially new total price
    final attendeesWithAmounts = _updateAttendeeAmounts(nextState);
    emit(nextState.copyWith(selectedAttendees: attendeesWithAmounts));
  }

  int _getTimeBasedDefaultDuration(ServiceProviderModel provider) {
    // Prioritize selected service duration
    if (state.selectedService?.durationMinutes != null &&
        state.selectedService!.durationMinutes! > 0) {
      return state.selectedService!.durationMinutes!;
    }
    // Check provider's config for time-based default
    final timeBasedConfig = provider.reservationTypeConfigs?['timeBased'];
    if (timeBasedConfig is Map &&
        timeBasedConfig['defaultDurationMinutes'] is int) {
      return timeBasedConfig['defaultDurationMinutes'];
    }
    // Fallback: find first suitable service duration from provider's list
    return provider.bookableServices
            .firstWhereOrNull((s) =>
                (s.type == ReservationType.timeBased ||
                    s.type == ReservationType.group) &&
                s.durationMinutes != null &&
                s.durationMinutes! > 0)
            ?.durationMinutes ??
        provider.bookableServices // Absolute fallback
            .firstWhereOrNull(
                (s) => s.durationMinutes != null && s.durationMinutes! > 0)
            ?.durationMinutes ??
        60; // Final fallback: 60 minutes
  }

  void _onUpdateSwipeSelection(
      UpdateSwipeSelection event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;

    // Ensure correct state for swipe selection
    if (currentProvider == null ||
        (currentState.selectedReservationType != ReservationType.timeBased &&
            currentState.selectedReservationType !=
                ReservationType.group) || // Allow for group too?
        currentState.selectedDate == null) {
      emit(_emitError("Please select type and date first.", currentState));
      return;
    }

    final startTime = event.startTime;
    final endTime = event.endTime;

    // Validate time range
    if (_timeOfDayToMinutes(endTime) <= _timeOfDayToMinutes(startTime)) {
      emit(_emitError(
          "Invalid time range: End time must be after start time.",
          currentState.copyWith(
              selectedStartTime: null, selectedEndTime: null)));
      return;
    }

    // TODO: Validate selected range against available slots if necessary

    // Emit Range Selected state
    emit(ReservationRangeSelected(
      provider: currentProvider,
      selectedReservationType: currentState.selectedReservationType!,
      selectedService: currentState.selectedService,
      date: currentState.selectedDate!,
      startTime: startTime,
      endTime: endTime,
      availableSlots: currentState.availableSlots, // Keep slots
      selectedAttendees: currentState.selectedAttendees, // Keep attendees
      typeSpecificData: currentState.typeSpecificData,
      // Pass other fields
      isFullVenueReservation: currentState.isFullVenueReservation,
      reservedCapacity: currentState.reservedCapacity,
      isCommunityVisible: currentState.isCommunityVisible,
      hostingCategory: currentState.hostingCategory,
      hostingDescription: currentState.hostingDescription,
      attendeePaymentStatuses: currentState.attendeePaymentStatuses,
      costSplitDetails: currentState.costSplitDetails,
      basePrice: currentState.basePrice, // Price likely doesn't change on swipe
      addOnsPrice: currentState.addOnsPrice,
      totalPrice: currentState.totalPrice,
    ));
  }

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  void _onAddAttendee(AddAttendee event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;
    if (currentProvider == null) {
      emit(_emitError("Provider context missing.", currentState));
      return;
    }

    final currentAttendees =
        List<AttendeeModel>.from(currentState.selectedAttendees);

    // Prevent adding duplicate user IDs
    if (currentAttendees.any((a) => a.userId == event.attendee.userId)) {
      debugPrint("Attendee with ID ${event.attendee.userId} already exists.");
      // Optionally emit a state with a temporary message if state supports it
      return;
    }

    // Determine max capacity based on current settings
    final int maxCapacity = currentState.isFullVenueReservation
        ? _getProviderCapacity(currentProvider)
        : currentState.reservedCapacity ??
            _getProviderCapacity(currentProvider); // Use reserved or total/max

    // Check against max capacity
    if (currentAttendees.length >= maxCapacity) {
      emit(
          _emitError("Maximum capacity ($maxCapacity) reached.", currentState));
      return;
    }

    // Add the new attendee
    currentAttendees.add(event.attendee.copyWith(
        paymentStatus: PaymentStatus.pending // Ensure new attendees are pending
        ));

    // Recalculate amounts for all attendees
    final updatedAttendeesWithAmounts = _updateAttendeeAmounts(
        currentState.copyWith(
            selectedAttendees: currentAttendees) // Use temp state with new list
        );

    emit(currentState.copyWith(selectedAttendees: updatedAttendeesWithAmounts));
    debugPrint(
        "Added attendee: ${event.attendee.name}. Total: ${currentAttendees.length}");
  }

  void _onRemoveAttendee(RemoveAttendee event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;
    if (currentProvider == null) return;

    // Cannot remove 'self' attendee
    if (currentState.selectedAttendees
            .firstWhereOrNull((a) => a.type == 'self')
            ?.userId ==
        event.userIdToRemove) {
      debugPrint("Cannot remove the primary booking user ('self').");
      return;
    }

    final currentAttendees =
        List<AttendeeModel>.from(currentState.selectedAttendees);
    final initialLength = currentAttendees.length;

    currentAttendees.removeWhere((a) => a.userId == event.userIdToRemove);

    if (currentAttendees.length < initialLength) {
      // Recalculate amounts for remaining attendees
      final updatedAttendeesWithAmounts = _updateAttendeeAmounts(currentState
              .copyWith(selectedAttendees: currentAttendees) // Use temp state
          );
      emit(currentState.copyWith(
          selectedAttendees: updatedAttendeesWithAmounts));
      debugPrint(
          "Removed attendee ID: ${event.userIdToRemove}. Total: ${currentAttendees.length}");
    } else {
      debugPrint("Attendee ID ${event.userIdToRemove} not found for removal.");
    }
  }

  void _onSetVenueCapacity(
      SetVenueCapacity event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;

    if (currentProvider == null) {
      emit(_emitError("Provider context missing.", currentState));
      return;
    }

    // Validate capacity if not full venue
    final totalCapacity = _getProviderCapacity(currentProvider);
    int newReservedCapacity = event.isFullVenue
        ? totalCapacity // Full venue uses total capacity
        : event.reservedCapacity.clamp(
            currentProvider.minGroupSize ?? 1, totalCapacity); // Clamp partial

    // Recalculate price based on new capacity setting
    final newBasePrice = _calculateBasePrice(currentProvider,
        currentState.selectedService, newReservedCapacity, event.isFullVenue);
    final newTotalPrice = _calculateTotalPrice(
        basePrice: newBasePrice, addOnsPrice: currentState.addOnsPrice);

    // Handle cost splitting changes (e.g., disable if full venue)
    Map<String, dynamic>? newCostSplitDetails = currentState.costSplitDetails;
    if (event.isFullVenue && (newCostSplitDetails?['enabled'] ?? false)) {
      newCostSplitDetails = {
        ...newCostSplitDetails!, // Keep existing details like method/ratios
        'enabled': false, // Just disable it
      };
      debugPrint("Cost splitting disabled due to full venue selection.");
    }

    // Create temporary next state to calculate attendee amounts
    var tempNextState = currentState.copyWith(
        isFullVenueReservation: event.isFullVenue,
        reservedCapacity: newReservedCapacity,
        basePrice: newBasePrice,
        totalPrice: newTotalPrice,
        costSplitDetails: newCostSplitDetails);

    // Ensure attendee count doesn't exceed new capacity limit
    List<AttendeeModel> finalAttendees =
        List.from(currentState.selectedAttendees);
    final maxAttendees = newReservedCapacity; // Max is the reserved capacity

    if (finalAttendees.length > maxAttendees) {
      // Truncate attendees, preserving 'self'
      final selfAttendee =
          finalAttendees.firstWhereOrNull((a) => a.type == 'self');
      final List<AttendeeModel> truncatedAttendees = [];
      if (selfAttendee != null) {
        truncatedAttendees.add(selfAttendee);
      }
      // Add others up to the limit
      truncatedAttendees.addAll(finalAttendees
          .where((a) => a.type != 'self')
          .take(maxAttendees - truncatedAttendees.length));
      finalAttendees = truncatedAttendees;
      debugPrint("Truncated attendees to fit new capacity: $maxAttendees");
    }

    // Update attendee amounts based on final attendee list and new price/split settings
    final finalAttendeesWithAmounts = _updateAttendeeAmounts(
        tempNextState.copyWith(selectedAttendees: finalAttendees));

    // Emit the final state
    emit(currentState.copyWith(
      isFullVenueReservation: event.isFullVenue,
      reservedCapacity: newReservedCapacity,
      basePrice: newBasePrice,
      totalPrice: newTotalPrice,
      costSplitDetails: newCostSplitDetails,
      selectedAttendees:
          finalAttendeesWithAmounts, // Use final list with updated amounts
    ));
  }

  void _onSetAttendeePaymentStatus(
      SetAttendeePaymentStatus event, Emitter<ReservationState> emit) {
    final currentState = state;
    if (currentState.selectedAttendees.isEmpty) return;

    bool attendeeFound = false;
    final List<AttendeeModel> updatedAttendees =
        currentState.selectedAttendees.map((attendee) {
      if (attendee.userId == event.attendeeUserId) {
        attendeeFound = true;
        // Calculate amount if not provided and status implies payment needed
        double? finalAmount = event.amount;
        if ((event.paymentStatus == PaymentStatus.complete ||
                event.paymentStatus == PaymentStatus.partial) &&
            finalAmount == null) {
          finalAmount = _calculateAttendeeAmount(
              attendee,
              currentState.totalPrice,
              currentState.selectedAttendees.length,
              currentState.costSplitDetails);
        } else if (event.paymentStatus == PaymentStatus.hosted ||
            event.paymentStatus == PaymentStatus.waived) {
          finalAmount = 0.0;
        } else if (event.paymentStatus == PaymentStatus.pending) {
          // Recalculate pending amount
          finalAmount = _calculateAttendeeAmount(
              attendee,
              currentState.totalPrice,
              currentState.selectedAttendees.length,
              currentState.costSplitDetails);
        }

        return attendee.copyWith(
          paymentStatus: event.paymentStatus,
          amountToPay: finalAmount,
          // Use clearAmountToPay flag if amount should explicitly be nullified
          // clearAmountToPay: finalAmount == null && event.paymentStatus != PaymentStatus.partial && event.paymentStatus != PaymentStatus.complete,
        );
      }
      return attendee;
    }).toList();

    if (attendeeFound) {
      // Also update the separate attendeePaymentStatuses map if it's being used
      final newPaymentStatuses =
          Map<String, PaymentStatus>.from(currentState.attendeePaymentStatuses);
      newPaymentStatuses[event.attendeeUserId] = event.paymentStatus;

      emit(currentState.copyWith(
        selectedAttendees: updatedAttendees,
        attendeePaymentStatuses: newPaymentStatuses,
      ));
      debugPrint(
          "Updated payment status for ${event.attendeeUserId} to ${event.paymentStatus}");
    } else {
      debugPrint(
          "Attendee ${event.attendeeUserId} not found to update payment status.");
    }
  }

  void _onSetCommunityVisibility(
      SetCommunityVisibility event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;
    if (currentProvider == null) return;

    emit(currentState.copyWith(
      isCommunityVisible: event.isVisible,
      hostingCategory: event.isVisible
          ? (event.hostingCategory ?? currentProvider.category)
          : null,
      hostingDescription: event.isVisible ? event.description : null,
    ));
    debugPrint("Community visibility set to ${event.isVisible}");
  }

  void _onUpdateCostSplitSettings(
      UpdateCostSplitSettings event, Emitter<ReservationState> emit) {
    final currentState = state;

    // Prevent enabling splitting for full venue reservations
    if (currentState.isFullVenueReservation && event.enabled) {
      emit(_emitError(
          "Cost splitting cannot be enabled for full venue reservations.",
          currentState));
      return;
    }

    // TODO: Add validation for customSplitRatio if needed

    // Update cost splitting details
    final newCostSplitDetails = {
      'enabled': event.enabled,
      'splitMethod': event.splitMethod,
      if (event.splitMethod == 'custom' && event.customSplitRatio != null)
        'customSplitRatio': event.customSplitRatio,
    };

    // Recalculate attendee amounts based on the new split settings
    final updatedAttendeesWithAmounts = _updateAttendeeAmounts(currentState
            .copyWith(costSplitDetails: newCostSplitDetails) // Use temp state
        );

    emit(currentState.copyWith(
      costSplitDetails: newCostSplitDetails,
      selectedAttendees: updatedAttendeesWithAmounts,
    ));
    debugPrint(
        "Updated cost split settings: Enabled=${event.enabled}, Method=${event.splitMethod}");
  }

  void _onResetReservationFlow(
      ResetReservationFlow event, Emitter<ReservationState> emit) {
    debugPrint("Resetting reservation flow.");
    final provider =
        event.provider ?? state.provider; // Use provided or existing provider
    if (provider == null) {
      emit(const ReservationInitial(
          provider: null)); // Cannot reset without provider context
      return;
    }

    // Re-initialize state similar to constructor
    final resetState = ReservationInitial(
        provider: provider,
        reservedCapacity: provider.minGroupSize ?? 1,
        basePrice: _calculateBasePrice(
            provider, null, provider.minGroupSize ?? 1, false),
        totalPrice: _calculateTotalPrice(
            basePrice: _calculateBasePrice(
                provider, null, provider.minGroupSize ?? 1, false),
            addOnsPrice: 0.0)
        // All other fields default to initial values from ReservationInitial constructor
        );

    // Initialize attendees again (if user is logged in)
    if (_userId != null && _userName != null) {
      final initialAttendee = AttendeeModel(
        userId: _userId!,
        name: _userName!,
        type: 'self',
        status: 'going',
        paymentStatus: PaymentStatus.pending,
        amountToPay: resetState.totalPrice, // Self pays total initially
      );
      final attendees = [initialAttendee];
      final attendeesWithAmounts = _updateAttendeeAmounts(
          resetState.copyWith(selectedAttendees: attendees));
      emit(resetState.copyWith(selectedAttendees: attendeesWithAmounts));
    } else {
      emit(resetState); // Emit reset state without attendees if user logged out
    }
  }

  // --- Backend Interaction ---

  Future<void> _onCreateReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    final stateBeforeCreate = state;
    final userId = _userId;
    final userName = _userName;
    final currentProvider = stateBeforeCreate.provider;

    // --- Validation ---
    if (userId == null || userName == null) {
      emit(_emitError("User not authenticated.", stateBeforeCreate));
      return;
    }
    if (currentProvider == null ||
        stateBeforeCreate.selectedReservationType == null ||
        stateBeforeCreate.selectedAttendees.isEmpty) {
      emit(_emitError(
          "Missing required reservation context (provider, type, or attendees).",
          stateBeforeCreate));
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(_emitError(
          "Provider is missing necessary location information (Governorate ID).",
          stateBeforeCreate));
      return;
    }

    // Use the readiness check method
    if (!isReservationReadyToConfirm(stateBeforeCreate)) {
      emit(_emitError(
          "Please complete all required selections before confirming.",
          stateBeforeCreate));
      return;
    }

    // Validate capacity vs attendees one last time
    final maxCapacity = stateBeforeCreate.isFullVenueReservation
        ? _getProviderCapacity(currentProvider)
        : stateBeforeCreate.reservedCapacity ??
            _getProviderCapacity(currentProvider);
    if (stateBeforeCreate.selectedAttendees.length > maxCapacity) {
      emit(_emitError(
          "Number of attendees (${stateBeforeCreate.selectedAttendees.length}) exceeds the maximum allowed ($maxCapacity).",
          stateBeforeCreate));
      return;
    }
    // --- End Validation ---

    // Emit Creating State
    emit(ReservationCreating(
      provider: currentProvider,
      selectedReservationType: stateBeforeCreate.selectedReservationType!,
      selectedAttendees: stateBeforeCreate.selectedAttendees,
      selectedService: stateBeforeCreate.selectedService,
      selectedDate: stateBeforeCreate.selectedDate,
      selectedStartTime: stateBeforeCreate.selectedStartTime,
      selectedEndTime: stateBeforeCreate.selectedEndTime,
      availableSlots: stateBeforeCreate.availableSlots,
      typeSpecificData: stateBeforeCreate.typeSpecificData,
      // Pass new fields
      isFullVenueReservation: stateBeforeCreate.isFullVenueReservation,
      reservedCapacity: stateBeforeCreate.reservedCapacity,
      isCommunityVisible: stateBeforeCreate.isCommunityVisible,
      hostingCategory: stateBeforeCreate.hostingCategory,
      hostingDescription: stateBeforeCreate.hostingDescription,
      attendeePaymentStatuses: stateBeforeCreate.attendeePaymentStatuses,
      costSplitDetails: stateBeforeCreate.costSplitDetails,
      basePrice: stateBeforeCreate.basePrice,
      addOnsPrice: stateBeforeCreate.addOnsPrice,
      totalPrice: stateBeforeCreate.totalPrice,
    ));

    // --- Prepare Payload ---
    Timestamp? startTimestamp;
    Timestamp? endTimestamp;
    if (stateBeforeCreate.selectedDate != null) {
      if (stateBeforeCreate.selectedStartTime != null) {
        final startDateTime = DateTime.utc(
          // Use UTC
          stateBeforeCreate.selectedDate!.year,
          stateBeforeCreate.selectedDate!.month,
          stateBeforeCreate.selectedDate!.day,
          stateBeforeCreate.selectedStartTime!.hour,
          stateBeforeCreate.selectedStartTime!.minute,
        );
        startTimestamp = Timestamp.fromDate(startDateTime);
      }
      if (stateBeforeCreate.selectedEndTime != null) {
        final endDateTime = DateTime.utc(
          // Use UTC
          stateBeforeCreate.selectedDate!.year,
          stateBeforeCreate.selectedDate!.month,
          stateBeforeCreate.selectedDate!.day,
          stateBeforeCreate.selectedEndTime!.hour,
          stateBeforeCreate.selectedEndTime!.minute,
        );
        endTimestamp = Timestamp.fromDate(endDateTime);
      } else if (startTimestamp != null &&
          stateBeforeCreate.selectedService?.durationMinutes != null) {
        // Calculate end time from start + duration if end time not directly selected
        final duration = Duration(
            minutes: stateBeforeCreate.selectedService!.durationMinutes!);
        endTimestamp =
            Timestamp.fromDate(startTimestamp.toDate().add(duration));
      }
    }

    // Ensure attendee list has final calculated amounts and correct status for payload
    final finalAttendeesPayload = stateBeforeCreate.selectedAttendees.map((a) {
      // Amount is already calculated and stored in stateBeforeCreate.selectedAttendees
      // Status should reflect current state (e.g., 'going', 'invited')
      return a.toMap(); // Convert final attendee state to map
    }).toList();

    final payload = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'providerId': currentProvider.id,
      'governorateId': govId,
      'type': stateBeforeCreate.selectedReservationType!.typeString,
      'groupSize': stateBeforeCreate.selectedAttendees.length,
      if (stateBeforeCreate.selectedService?.id != null)
        'serviceId': stateBeforeCreate.selectedService!.id,
      if (stateBeforeCreate.selectedService?.name != null)
        'serviceName': stateBeforeCreate.selectedService!.name,
      if (stateBeforeCreate.selectedService?.durationMinutes != null)
        'durationMinutes': stateBeforeCreate.selectedService!.durationMinutes,
      if (startTimestamp != null) 'reservationStartTime': startTimestamp,
      if (endTimestamp != null) 'endTime': endTimestamp,
      'status': ReservationStatus.pending.statusString, // Initial status
      'attendees': finalAttendeesPayload,
      'typeSpecificData': stateBeforeCreate.typeSpecificData,
      'totalPrice': stateBeforeCreate.totalPrice,
      'isFullVenueReservation': stateBeforeCreate.isFullVenueReservation,
      if (stateBeforeCreate.reservedCapacity != null)
        'reservedCapacity': stateBeforeCreate.reservedCapacity,
      'isCommunityVisible': stateBeforeCreate.isCommunityVisible,
      if (stateBeforeCreate.hostingCategory != null)
        'hostingCategory': stateBeforeCreate.hostingCategory,
      if (stateBeforeCreate.hostingDescription != null)
        'hostingDescription': stateBeforeCreate.hostingDescription,
      if (stateBeforeCreate.costSplitDetails != null)
        'costSplitDetails': stateBeforeCreate.costSplitDetails,
      // Notes, PaymentDetails, AddOns etc. could be added here if present in state
      if (stateBeforeCreate.notes != null) 'notes': stateBeforeCreate.notes,
      if (stateBeforeCreate.paymentDetails != null)
        'paymentDetails': stateBeforeCreate.paymentDetails,
      if (stateBeforeCreate.selectedAddOnsList != null)
        'selectedAddOnsList': stateBeforeCreate.selectedAddOnsList,
    };

    // --- Call Repository ---
    try {
      debugPrint("Calling createReservationOnBackend with payload: $payload");
      final result =
          await _reservationRepository.createReservationOnBackend(payload);

      if (result['success'] == true) {
        debugPrint("Reservation creation successful: ${result['message']}");
        emit(ReservationSuccess(
          message: result['message'] ?? 'Reservation created successfully!',
          reservationId: result['reservationId'] as String?,
          // Carry over final state details for success screen context
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType!,
          selectedService: stateBeforeCreate.selectedService,
          selectedDate: stateBeforeCreate.selectedDate,
          selectedStartTime: stateBeforeCreate.selectedStartTime,
          selectedEndTime: stateBeforeCreate.selectedEndTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: stateBeforeCreate.selectedAttendees,
          typeSpecificData: stateBeforeCreate.typeSpecificData,
          isFullVenueReservation: stateBeforeCreate.isFullVenueReservation,
          reservedCapacity: stateBeforeCreate.reservedCapacity,
          isCommunityVisible: stateBeforeCreate.isCommunityVisible,
          hostingCategory: stateBeforeCreate.hostingCategory,
          hostingDescription: stateBeforeCreate.hostingDescription,
          attendeePaymentStatuses: stateBeforeCreate.attendeePaymentStatuses,
          costSplitDetails: stateBeforeCreate.costSplitDetails,
          basePrice: stateBeforeCreate.basePrice,
          addOnsPrice: stateBeforeCreate.addOnsPrice,
          totalPrice: stateBeforeCreate.totalPrice,
        ));
      } else {
        debugPrint("Reservation creation failed: ${result['error']}");
        emit(_emitError(result['error'] ?? 'Failed to create reservation.',
            stateBeforeCreate));
      }
    } catch (e) {
      debugPrint("Error calling createReservationOnBackend: $e");
      emit(_emitError(
          "An unexpected error occurred: ${e.toString()}", stateBeforeCreate));
    }
  }

  // --- Queue Specific Handlers ---

  Future<void> _onJoinQueue(
      JoinQueue event, Emitter<ReservationState> emit) async {
    final stateBeforeJoin = state;
    final userId = _userId;
    final currentProvider = stateBeforeJoin.provider;
    final service = stateBeforeJoin.selectedService;
    final date = stateBeforeJoin.selectedDate;
    final hour = stateBeforeJoin.selectedStartTime; // Preferred hour

    // --- Validation ---
    if (userId == null) {
      emit(_emitError("User not authenticated.", stateBeforeJoin));
      return;
    }
    if (currentProvider == null ||
        service == null ||
        date == null ||
        hour == null) {
      emit(_emitError(
          "Missing required context (provider, service, date, or hour) to join queue.",
          stateBeforeJoin));
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(_emitError(
          "Provider is missing necessary location information (Governorate ID).",
          stateBeforeJoin));
      return;
    }
    if (stateBeforeJoin.selectedAttendees.isEmpty) {
      emit(_emitError("Cannot join queue without attendees.", stateBeforeJoin));
      return;
    }
    // --- End Validation ---

    emit(ReservationJoiningQueue(
      // Emit joining state
      provider: currentProvider,
      selectedReservationType: ReservationType.sequenceBased,
      selectedService: service,
      selectedAttendees: stateBeforeJoin.selectedAttendees,
      selectedDate: date,
      selectedStartTime: hour,
      // Pass other fields...
      typeSpecificData: stateBeforeJoin.typeSpecificData,
      isFullVenueReservation: stateBeforeJoin.isFullVenueReservation,
      reservedCapacity: stateBeforeJoin.reservedCapacity,
      isCommunityVisible: stateBeforeJoin.isCommunityVisible,
      hostingCategory: stateBeforeJoin.hostingCategory,
      hostingDescription: stateBeforeJoin.hostingDescription,
      attendeePaymentStatuses: stateBeforeJoin.attendeePaymentStatuses,
      costSplitDetails: stateBeforeJoin.costSplitDetails,
      basePrice: stateBeforeJoin.basePrice,
      addOnsPrice: stateBeforeJoin.addOnsPrice,
      totalPrice: stateBeforeJoin.totalPrice,
    ));

    try {
      final result = await _reservationRepository.joinQueue(
        userId: userId,
        providerId: currentProvider.id,
        governorateId: govId,
        serviceId: service.id,
        attendees: stateBeforeJoin.selectedAttendees,
        preferredDate: date,
        preferredHour: hour,
      );

      if (result['success'] == true) {
        final position = result['queuePosition'] as int?;
        final estimatedTime =
            (result['estimatedEntryTime'] as Timestamp?)?.toDate();

        if (position != null) {
          emit(ReservationInQueue(
            provider: currentProvider,
            selectedReservationType: ReservationType.sequenceBased,
            selectedService: service,
            selectedAttendees: stateBeforeJoin.selectedAttendees,
            selectedDate: date,
            selectedStartTime: hour,
            queuePosition: position,
            estimatedEntryTime: estimatedTime,
            // Pass other fields...
            typeSpecificData: stateBeforeJoin.typeSpecificData,
            isFullVenueReservation: stateBeforeJoin.isFullVenueReservation,
            reservedCapacity: stateBeforeJoin.reservedCapacity,
            isCommunityVisible: stateBeforeJoin.isCommunityVisible,
            hostingCategory: stateBeforeJoin.hostingCategory,
            hostingDescription: stateBeforeJoin.hostingDescription,
            attendeePaymentStatuses: stateBeforeJoin.attendeePaymentStatuses,
            costSplitDetails: stateBeforeJoin.costSplitDetails,
            basePrice: stateBeforeJoin.basePrice,
            addOnsPrice: stateBeforeJoin.addOnsPrice,
            totalPrice: stateBeforeJoin.totalPrice,
          ));
        } else {
          emit(_emitQueueError(
              "Successfully joined queue, but position is unavailable.",
              stateBeforeJoin));
        }
      } else {
        emit(_emitQueueError(
            result['error'] ?? "Failed to join the queue.", stateBeforeJoin));
      }
    } catch (e) {
      debugPrint("Error joining queue: $e");
      emit(_emitQueueError(
          "An error occurred while joining the queue: ${e.toString()}",
          stateBeforeJoin));
    }
  }

  Future<void> _onCheckQueueStatus(
      CheckQueueStatus event, Emitter<ReservationState> emit) async {
    final currentState = state;
    // Only check if currently in queue
    if (currentState is! ReservationInQueue) {
      debugPrint("Not in queue, cannot check status.");
      return;
    }

    final userId = _userId;
    final currentProvider = currentState.provider;
    final service = currentState.selectedService;
    final date = currentState.selectedDate;
    final hour = currentState.selectedStartTime;

    // --- Validation ---
    if (userId == null) {
      debugPrint("User not logged in.");
      return;
    }
    if (currentProvider == null ||
        service == null ||
        date == null ||
        hour == null) {
      debugPrint("Missing context to check queue status.");
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      debugPrint("Provider missing governorate ID.");
      return;
    }
    // --- End Validation ---

    try {
      final result = await _reservationRepository.checkQueueStatus(
        userId: userId,
        providerId: currentProvider.id,
        governorateId: govId,
        serviceId: service.id,
        preferredDate: date,
        preferredHour: hour,
      );

      if (result['success'] == true) {
        final position = result['queuePosition'] as int?;
        final estimatedTime =
            (result['estimatedEntryTime'] as Timestamp?)?.toDate();

        if (position != null) {
          // Update the existing InQueue state
          emit(currentState.copyWith(
              queuePosition: position,
              estimatedEntryTime: estimatedTime,
              forceEstimatedEntryTimeNull: estimatedTime == null));
          debugPrint(
              "Queue status updated: Pos=$position, EstTime=$estimatedTime");
        } else {
          // If status check returns success:false or no position, maybe user was removed?
          emit(_emitQueueError(
              "Queue status check failed or user not found in queue.",
              currentState,
              revertToDateSelected: true));
          debugPrint("User likely not in queue anymore.");
        }
      } else {
        debugPrint("Queue status check returned error: ${result['error']}");
        emit(_emitQueueError(
            "Failed to check queue status: ${result['error']}", currentState));
      }
    } catch (e) {
      debugPrint("Error checking queue status: $e");
      emit(_emitQueueError(
          "Error checking queue status: ${e.toString()}", currentState));
    }
  }

  Future<void> _onLeaveQueue(
      LeaveQueue event, Emitter<ReservationState> emit) async {
    final stateBeforeLeave = state;
    // Ensure user is actually in a queue state
    if (stateBeforeLeave is! ReservationInQueue) {
      debugPrint("Cannot leave queue, not currently in queue state.");
      return;
    }

    final userId = _userId;
    final currentProvider = stateBeforeLeave.provider;
    final service = stateBeforeLeave.selectedService;
    final date = stateBeforeLeave.selectedDate;
    final hour = stateBeforeLeave.selectedStartTime;

    // --- Validation ---
    if (userId == null) {
      emit(_emitError("User not authenticated.", stateBeforeLeave));
      return;
    }
    if (currentProvider == null ||
        service == null ||
        date == null ||
        hour == null) {
      emit(_emitError(
          "Missing required context to leave queue.", stateBeforeLeave));
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(_emitError("Provider is missing necessary location information.",
          stateBeforeLeave));
      return;
    }
    // --- End Validation ---

    try {
      final result = await _reservationRepository.leaveQueue(
        userId: userId,
        providerId: currentProvider.id,
        governorateId: govId,
        serviceId: service.id,
        preferredDate: date,
        preferredHour: hour,
      );

      if (result['success'] == true) {
        debugPrint("Successfully left the queue.");
        // Revert to the DateSelected state
        emit(ReservationDateSelected(
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: service,
          date: date,
          selectedAttendees: stateBeforeLeave.selectedAttendees,
          isLoadingSlots: false,
          selectedStartTime: null, // Clear preferred hour
          selectedEndTime: null,
          // Pass other fields...
          typeSpecificData: stateBeforeLeave.typeSpecificData,
          isFullVenueReservation: stateBeforeLeave.isFullVenueReservation,
          reservedCapacity: stateBeforeLeave.reservedCapacity,
          isCommunityVisible: stateBeforeLeave.isCommunityVisible,
          hostingCategory: stateBeforeLeave.hostingCategory,
          hostingDescription: stateBeforeLeave.hostingDescription,
          attendeePaymentStatuses: stateBeforeLeave.attendeePaymentStatuses,
          costSplitDetails: stateBeforeLeave.costSplitDetails,
          basePrice: stateBeforeLeave.basePrice,
          addOnsPrice: stateBeforeLeave.addOnsPrice,
          totalPrice: stateBeforeLeave.totalPrice,
        ));
      } else {
        debugPrint("Failed to leave queue: ${result['error']}");
        emit(_emitQueueError(
            result['error'] ?? "Failed to leave the queue.", stateBeforeLeave));
      }
    } catch (e) {
      debugPrint("Error leaving queue: $e");
      emit(_emitQueueError(
          "An error occurred while leaving the queue: ${e.toString()}",
          stateBeforeLeave));
    }
  }

  // --- Helper to emit ReservationError consistently ---
  ReservationState _emitError(String message, ReservationState currentState) {
    // Create a ReservationError state preserving the current context
    return ReservationError(
      message: message,
      provider: currentState.provider,
      selectedReservationType: currentState.selectedReservationType,
      selectedService: currentState.selectedService,
      selectedDate: currentState.selectedDate,
      selectedStartTime: currentState.selectedStartTime,
      selectedEndTime: currentState.selectedEndTime,
      availableSlots: currentState.availableSlots,
      selectedAttendees: currentState.selectedAttendees,
      typeSpecificData: currentState.typeSpecificData,
      isFullVenueReservation: currentState.isFullVenueReservation,
      reservedCapacity: currentState.reservedCapacity,
      isCommunityVisible: currentState.isCommunityVisible,
      hostingCategory: currentState.hostingCategory,
      hostingDescription: currentState.hostingDescription,
      attendeePaymentStatuses: currentState.attendeePaymentStatuses,
      costSplitDetails: currentState.costSplitDetails,
      basePrice: currentState.basePrice,
      addOnsPrice: currentState.addOnsPrice,
      totalPrice: currentState.totalPrice,
    );
  }

  // --- Helper to emit ReservationQueueError consistently ---
  ReservationState _emitQueueError(
      String message, ReservationState currentState,
      {bool revertToDateSelected = false}) {
    if (revertToDateSelected &&
        currentState.provider != null &&
        currentState.selectedDate != null) {
      // Option to revert to DateSelected state on certain queue errors
      // Don't pass the message here as ReservationDateSelected doesn't support it.
      return ReservationDateSelected(
        provider: currentState.provider!,
        selectedReservationType: ReservationType.sequenceBased,
        selectedService: currentState.selectedService,
        date: currentState.selectedDate!,
        selectedAttendees: currentState.selectedAttendees,
        isLoadingSlots: false,
        selectedStartTime: null, // Clear preferred hour
        // Pass other fields...
        typeSpecificData: currentState.typeSpecificData,
        isFullVenueReservation: currentState.isFullVenueReservation,
        reservedCapacity: currentState.reservedCapacity,
        isCommunityVisible: currentState.isCommunityVisible,
        hostingCategory: currentState.hostingCategory,
        hostingDescription: currentState.hostingDescription,
        attendeePaymentStatuses: currentState.attendeePaymentStatuses,
        costSplitDetails: currentState.costSplitDetails,
        basePrice: currentState.basePrice,
        addOnsPrice: currentState.addOnsPrice,
        totalPrice: currentState.totalPrice,
      );
    }

    // Otherwise, emit specific QueueError state which *does* support message
    return ReservationQueueError(
      message: message,
      provider: currentState.provider,
      selectedReservationType: currentState.selectedReservationType,
      selectedService: currentState.selectedService,
      selectedDate: currentState.selectedDate,
      selectedStartTime: currentState.selectedStartTime,
      selectedAttendees: currentState.selectedAttendees,
      // Pass other fields...
      typeSpecificData: currentState.typeSpecificData,
      isFullVenueReservation: currentState.isFullVenueReservation,
      reservedCapacity: currentState.reservedCapacity,
      isCommunityVisible: currentState.isCommunityVisible,
      hostingCategory: currentState.hostingCategory,
      hostingDescription: currentState.hostingDescription,
      attendeePaymentStatuses: currentState.attendeePaymentStatuses,
      costSplitDetails: currentState.costSplitDetails,
      basePrice: currentState.basePrice,
      addOnsPrice: currentState.addOnsPrice,
      totalPrice: currentState.totalPrice,
    );
  }
}
