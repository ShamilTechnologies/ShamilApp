// lib/feature/reservation/bloc/reservation_bloc.dart

import 'dart:async'; // Import async
import 'dart:math'; // Import for min/max

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for userId
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:intl/intl.dart'; // For formatting day name
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
// Import the ReservationModel AND the extension
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/repository/reservation_repository.dart';

// Define the parts for Bloc structure
part 'reservation_event.dart';
part 'reservation_state.dart';

/// Manages the state for the reservation booking process. Delegates data
/// fetching and backend calls to a [ReservationRepository].
class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReservationRepository _reservationRepository;

  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.displayName;

  ReservationBloc({
    required ServiceProviderModel provider,
    required ReservationRepository reservationRepository,
  })  : _reservationRepository = reservationRepository,
        super(ReservationInitial(provider: provider)) {
    on<SelectReservationType>(_onSelectReservationType);
    on<SelectReservationService>(_onSelectReservationService);
    on<SelectReservationDate>(_onSelectReservationDate);
    on<UpdateSwipeSelection>(_onUpdateSwipeSelection);
    on<AddAttendee>(_onAddAttendee);
    on<RemoveAttendee>(_onRemoveAttendee);
    on<CreateReservation>(_onCreateReservation);
    on<ResetReservationFlow>(_onResetReservationFlow);

    _initializeAttendees(provider);
    print("ReservationBloc Initialized for Provider ID: ${state.provider?.id}");
  }

  void _initializeAttendees(ServiceProviderModel provider) {
    if (_userId != null && _userName != null) {
      if (state is ReservationInitial) {
        // Use emit directly as this is initialization logic
        emit((state as ReservationInitial).copyWith(// Use the specific copyWith
            selectedAttendees: [
          AttendeeModel(
            userId: _userId!,
            name: _userName!,
            type: 'self',
            status: 'going',
          )
        ]));
      }
    } else {
      print("ReservationBloc WARN: User not logged in during initialization.");
    }
  }

  void _onSelectReservationType(
      SelectReservationType event, Emitter<ReservationState> emit) {
    print(
        "ReservationBloc: Reservation Type selected - ${event.reservationType.displayString}");
    if (state.provider == null) {
      emit(ReservationError(
          message: "Provider context missing.",
          provider: state.provider,
          selectedReservationType: null,
          selectedAttendees: state.selectedAttendees));
      return;
    }
    emit(ReservationTypeSelected(
      provider: state.provider!,
      selectedReservationType: event.reservationType,
      selectedAttendees: state.selectedAttendees,
    ));
  }

  void _onSelectReservationService(
      SelectReservationService event, Emitter<ReservationState> emit) {
    final service = event.selectedService;
    print("ReservationBloc: Service selected - ${service?.name ?? 'General'}");
    if (state.provider == null || state.selectedReservationType == null) {
      emit(ReservationError(
          message: "Provider or reservation type missing.",
          provider: state.provider,
          selectedReservationType: state.selectedReservationType,
          selectedAttendees: state.selectedAttendees));
      return;
    }
    if (service != null) {
      emit(ReservationServiceSelected(
        provider: state.provider!,
        selectedReservationType: state.selectedReservationType,
        service: service,
        selectedAttendees: state.selectedAttendees,
      ));
    } else {
      emit(ReservationTypeSelected(
        // Revert to type selected, clearing service
        provider: state.provider!,
        selectedReservationType: state.selectedReservationType,
        selectedAttendees: state.selectedAttendees,
      ));
    }
  }

  Future<void> _onSelectReservationDate(
      SelectReservationDate event, Emitter<ReservationState> emit) async {
    final currentService = state.selectedService;
    final currentType = state.selectedReservationType;
    final currentProvider = state.provider;
    final currentAttendees =
        state.selectedAttendees; // Capture current attendees

    if (currentProvider == null || currentType == null) {
      emit(ReservationError(
          message: "Provider or reservation type missing.",
          provider: currentProvider,
          selectedReservationType: currentType,
          selectedAttendees: currentAttendees));
      return;
    }
    int? durationMinutes = currentService?.durationMinutes ??
        currentProvider.bookableServices.firstOrNull?.durationMinutes;
    if (currentType == ReservationType.timeBased &&
        (durationMinutes == null || durationMinutes <= 0)) {
      durationMinutes = currentProvider.bookableServices
              .firstWhereOrNull((s) =>
                  s.type == ReservationType.timeBased &&
                  s.durationMinutes != null &&
                  s.durationMinutes! > 0)
              ?.durationMinutes ??
          60;
      if (durationMinutes <= 0) {
        emit(ReservationError(
            message: "Invalid or missing service duration for time slots.",
            provider: currentProvider,
            selectedReservationType: currentType,
            selectedService: currentService,
            selectedDate: event.selectedDate,
            selectedAttendees: currentAttendees));
        return;
      }
      print(
          "ReservationBloc: Using default/fallback duration $durationMinutes min for time slot fetching.");
    }

    print(
        "ReservationBloc: Date selected - ${event.selectedDate}, Type: ${currentType.displayString}");

    // Emit loading state
    emit(ReservationDateSelected(
        provider: currentProvider,
        selectedReservationType: currentType,
        selectedService: currentService,
        date: event.selectedDate,
        availableSlots: [], // Clear old slots
        selectedAttendees: currentAttendees, // Keep attendees
        isLoadingSlots: true));

    try {
      List<TimeOfDay> availableStartSlots = [];
      if (currentType == ReservationType.timeBased) {
        if (currentProvider.governorateId == null ||
            currentProvider.governorateId!.isEmpty) {
          throw Exception(
              "Provider's governorate ID is missing, cannot fetch slots.");
        }
        if (durationMinutes == null || durationMinutes <= 0) {
          throw Exception("Cannot fetch time slots without a valid duration.");
        }
        availableStartSlots = await _reservationRepository.fetchAvailableSlots(
          providerId: currentProvider.id,
          governorateId: currentProvider.governorateId!,
          date: event.selectedDate,
          durationMinutes: durationMinutes,
        );
        print(
            "ReservationBloc: Fetched ${availableStartSlots.length} available start slots from repository.");
      } else {
        print(
            "ReservationBloc: Slot fetching skipped for type ${currentType.displayString}");
      }

      // *** Check state type AGAIN before emitting ***
      // Ensure the state hasn't changed to something else (e.g., user changed type)
      // while we were fetching slots.
      if (state is ReservationDateSelected &&
          state.selectedDate == event.selectedDate &&
          state.selectedReservationType == currentType) {
        // Use copyWith on the *current* ReservationDateSelected state
        emit((state as ReservationDateSelected).copyWith(
          availableSlots: availableStartSlots,
          isLoadingSlots: false,
          selectedStartTime: null, // Reset time selection
          selectedEndTime: null,
        ));
      } else {
        print(
            "ReservationBloc: State changed while fetching slots (ignoring fetched slots). Current state: ${state.runtimeType}");
      }
    } catch (e) {
      print("ReservationBloc: Error during date selection processing: $e");
      // *** Explicitly emit ReservationError ***
      // Carry over context from the state *before* the error occurred
      emit(ReservationError(
        message: "Failed to load availability: ${e.toString()}",
        provider: currentProvider, // Context from before error
        selectedReservationType: currentType,
        selectedService: currentService,
        selectedDate: event.selectedDate, // Date that caused error
        availableSlots: const [],
        selectedAttendees: currentAttendees, // Attendees from before error
      ));
    }
  }

  void _onUpdateSwipeSelection(
      UpdateSwipeSelection event, Emitter<ReservationState> emit) {
    final currentState = state; // Capture current state
    if (currentState.provider == null ||
        currentState.selectedReservationType != ReservationType.timeBased ||
        currentState.selectedDate == null) {
      emit(ReservationError(
          message: "Please select type and date first for time-based booking.",
          provider: currentState.provider,
          selectedReservationType: currentState.selectedReservationType,
          selectedDate: currentState.selectedDate,
          selectedAttendees: currentState.selectedAttendees));
      return;
    }
    final startTime = event.startTime;
    final endTime = event.endTime;
    if (_timeOfDayToMinutes(endTime) <= _timeOfDayToMinutes(startTime)) {
      emit(ReservationError(
        message: "Invalid time range: End time must be after start time.",
        provider: currentState.provider!,
        selectedReservationType: currentState.selectedReservationType,
        selectedService: currentState.selectedService,
        selectedDate: currentState.selectedDate!,
        availableSlots: currentState.availableSlots,
        selectedAttendees: currentState.selectedAttendees,
        selectedStartTime: null,
        selectedEndTime: null,
      ));
      return;
    }

    // Emit the specific ReservationRangeSelected state
    emit(ReservationRangeSelected(
      provider: currentState.provider!,
      selectedReservationType: currentState.selectedReservationType!,
      selectedService: currentState.selectedService,
      date: currentState.selectedDate!,
      startTime: startTime,
      endTime: endTime,
      availableSlots: currentState.availableSlots,
      selectedAttendees: currentState.selectedAttendees,
    ));
  }

  void _onAddAttendee(AddAttendee event, Emitter<ReservationState> emit) {
    if (state.provider == null) return;
    final currentAttendees = List<AttendeeModel>.from(state.selectedAttendees);
    final maxGroupSize = state.provider!.maxGroupSize;
    if (currentAttendees.any((a) => a.userId == event.attendee.userId)) return;
    if (maxGroupSize != null && currentAttendees.length >= maxGroupSize) {
      emit(ReservationError(
        message: "Maximum group size ($maxGroupSize) reached.",
        provider: state.provider,
        selectedReservationType: state.selectedReservationType,
        selectedService: state.selectedService,
        selectedDate: state.selectedDate,
        selectedStartTime: state.selectedStartTime,
        selectedEndTime: state.selectedEndTime,
        availableSlots: state.availableSlots,
        selectedAttendees: state.selectedAttendees,
      ));
      return;
    }
    currentAttendees.add(event.attendee);
    print(
        "Attendee added: ${event.attendee.name}. New count: ${currentAttendees.length}");
    // Use the specific copyWith method of the current state
    emit(state.copyWith(selectedAttendees: currentAttendees));
  }

  void _onRemoveAttendee(RemoveAttendee event, Emitter<ReservationState> emit) {
    if (state.provider == null) return;
    final currentAttendees = List<AttendeeModel>.from(state.selectedAttendees);
    final initialLength = currentAttendees.length;
    currentAttendees.removeWhere(
        (a) => a.userId == event.userIdToRemove && a.type != 'self');
    if (currentAttendees.length < initialLength) {
      print(
          "Attendee removed: ${event.userIdToRemove}. New count: ${currentAttendees.length}");
      emit(state.copyWith(selectedAttendees: currentAttendees));
    } else {
      print(
          "Could not remove attendee: ${event.userIdToRemove} (not found or 'self')");
    }
  }

  Future<void> _onCreateReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    // Capture state before starting async operation
    final stateBeforeCreate = state;

    // --- Validation Checks ---
    final userId = _userId;
    final userName = _userName;
    if (userId == null || userName == null) {
      emit(ReservationError(
          message: "User not authenticated.",
          provider: stateBeforeCreate.provider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    if (stateBeforeCreate.provider == null ||
        stateBeforeCreate.selectedReservationType == null ||
        stateBeforeCreate.selectedAttendees.isEmpty) {
      emit(ReservationError(
          message: "Missing required reservation context.",
          provider: stateBeforeCreate.provider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    if (stateBeforeCreate.provider?.governorateId == null ||
        stateBeforeCreate.provider!.governorateId!.isEmpty) {
      emit(ReservationError(
          message:
              "Provider is missing necessary location information (Governorate ID).",
          provider: stateBeforeCreate.provider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    bool ready = isReservationReadyToConfirm(
        stateBeforeCreate, stateBeforeCreate.selectedReservationType);
    if (!ready) {
      emit(ReservationError(
          message: "Please complete all required fields.",
          provider: stateBeforeCreate.provider!,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedService: stateBeforeCreate.selectedService,
          selectedDate: stateBeforeCreate.selectedDate,
          selectedStartTime: stateBeforeCreate.selectedStartTime,
          selectedEndTime: stateBeforeCreate.selectedEndTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    // --- End Validation ---

    // --- Get Data from State ---
    final currentProvider = stateBeforeCreate.provider!;
    final reservationType = stateBeforeCreate.selectedReservationType!;
    final attendees = stateBeforeCreate.selectedAttendees;
    final service = stateBeforeCreate.selectedService;
    final date = stateBeforeCreate.selectedDate;
    final startTime = stateBeforeCreate.selectedStartTime;
    final endTime = stateBeforeCreate.selectedEndTime;

    // --- Emit Loading State ---
    emit(ReservationCreating(
      provider: currentProvider,
      selectedReservationType: reservationType,
      selectedService: service,
      selectedDate: date,
      selectedStartTime: startTime,
      selectedEndTime: endTime,
      availableSlots: stateBeforeCreate.availableSlots,
      selectedAttendees: attendees,
    ));
    print(
        "ReservationBloc: Creating '${reservationType.displayString}' reservation...");

    // --- Prepare Payload ---
    final payload = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'providerId': currentProvider.id,
      'governorateId': currentProvider.governorateId!,
      'reservationType': reservationType.typeString,
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'groupSize': attendees.length,
      if (service != null) 'serviceId': service.id,
      if (service != null) 'serviceName': service.name,
      if (service != null) 'serviceDurationMinutes': service.durationMinutes,
      if (service != null) 'servicePrice': service.price,
      if (date != null)
        'reservationDateMillis': DateTime.utc(date.year, date.month, date.day)
            .millisecondsSinceEpoch,
      if (reservationType == ReservationType.timeBased) ...{
        if (startTime != null)
          'startTimeOfDay': {
            'hour': startTime.hour,
            'minute': startTime.minute
          },
        if (endTime != null)
          'endTimeOfDay': {'hour': endTime.hour, 'minute': endTime.minute},
      }, /* TODO: Add typeSpecificData */
    };

    // --- Call Repository ---
    try {
      final result =
          await _reservationRepository.createReservationOnBackend(payload);
      if (result['success'] == true) {
        final successMessage =
            result['message'] as String? ?? "Reservation confirmed!";
        print("ReservationBloc: Reservation successful - $successMessage");
        emit(ReservationSuccess(
            message: successMessage,
            provider: currentProvider,
            selectedReservationType: reservationType,
            selectedService: service,
            selectedDate: date,
            selectedStartTime: startTime,
            selectedEndTime: endTime,
            availableSlots: stateBeforeCreate.availableSlots,
            selectedAttendees: attendees));
      } else {
        final errorMessage =
            result['error'] as String? ?? 'Reservation failed on the server.';
        print("ReservationBloc: Reservation failed - $errorMessage");
        // *** Emit ReservationError with context from *before* creation attempt ***
        emit(ReservationError(
            message: errorMessage,
            provider: currentProvider,
            selectedReservationType: reservationType,
            selectedService: service,
            selectedDate: date,
            selectedStartTime: startTime,
            selectedEndTime: endTime,
            availableSlots: stateBeforeCreate.availableSlots,
            selectedAttendees: attendees));
      }
    } catch (e) {
      print(
          "ReservationBloc: Error calling createReservation repository method: $e");
      // *** Emit ReservationError with context from *before* creation attempt ***
      emit(ReservationError(
          message: "Failed to create reservation: ${e.toString()}",
          provider: currentProvider,
          selectedReservationType: reservationType,
          selectedService: service,
          selectedDate: date,
          selectedStartTime: startTime,
          selectedEndTime: endTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: attendees));
    }
  } // End of _onCreateReservation

  /// Resets the Bloc to its initial state, keeping the provider context.
  void _onResetReservationFlow(
      ResetReservationFlow event, Emitter<ReservationState> emit) {
    print("ReservationBloc: Resetting flow.");
    final providerToUse = event.provider ?? state.provider;
    if (providerToUse == null) {
      emit(const ReservationError(
          message: "Cannot reset: Provider missing.", provider: null));
      return;
    }
    final initialAttendees = event.initialAttendee != null
        ? [event.initialAttendee!]
        : <AttendeeModel>[];
    final supportedTypes = providerToUse.supportedReservationTypes
        .map((s) => reservationTypeFromString(s))
        .where((t) => t != ReservationType.unknown)
        .toList();
    ReservationType? initialType;
    if (supportedTypes.length == 1) {
      initialType = supportedTypes.first;
      print(
          "ReservationBloc Reset: Auto-selecting type ${initialType.displayString}");
    }

    if (initialType != null) {
      emit(ReservationTypeSelected(
        provider: providerToUse,
        selectedReservationType: initialType,
        selectedAttendees: initialAttendees,
      ));
    } else {
      // Use the specific copyWith for ReservationInitial
      emit(ReservationInitial(provider: providerToUse)
          .copyWith(selectedAttendees: initialAttendees));
    }
  }

  // --- Helper Functions ---

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  bool isReservationReadyToConfirm(
      ReservationState currentState, ReservationType? selectedType) {
    if (currentState.selectedAttendees.isEmpty ||
        selectedType == null ||
        currentState.provider == null) return false;
    switch (selectedType) {
      case ReservationType.timeBased:
        return currentState.selectedDate != null &&
            currentState.selectedStartTime != null &&
            currentState.selectedEndTime != null;
      case ReservationType.serviceBased:
        return currentState.selectedService != null;
      case ReservationType.seatBased:
        return currentState.selectedDate !=
            null /* && currentState.selectedSeatInfo != null */;
      case ReservationType.accessBased:
        return currentState.selectedDate !=
            null /* && currentState.selectedAccessOption != null */;
      case ReservationType.recurring:
        return false;
      case ReservationType.group:
        final otherTypes = currentState.provider!.supportedReservationTypes
            .map((s) => reservationTypeFromString(s))
            .where((t) =>
                t != ReservationType.unknown && t != ReservationType.group);
        if (otherTypes.contains(ReservationType.timeBased)) {
          return currentState.selectedDate != null &&
              currentState.selectedStartTime != null &&
              currentState.selectedEndTime != null;
        } else if (otherTypes.contains(ReservationType.serviceBased)) {
          return currentState.selectedService != null;
        }
        return false;
      case ReservationType.unknown:
      default:
        return false;
    }
  }
} // End of ReservationBloc
