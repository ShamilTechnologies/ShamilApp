// lib/feature/reservation/bloc/reservation_bloc.dart

import 'dart:async'; // Import async
import 'dart:math'; // Import for min/max

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for userId
import 'package:flutter/material.dart'; // For TimeOfDay, BuildContext (for formatting in handler)
import 'package:intl/intl.dart'; // For formatting day name and time
import 'package:meta/meta.dart';

// Import the UPDATED models
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
// Import the ReservationModel AND the extension
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
        super(ReservationInitial(provider: provider)) {
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
    // *** ADDED handler for SelectAccessPassOption ***
    on<SelectAccessPassOption>(_onSelectAccessPassOption);

    _initializeAttendees(provider);
    print("ReservationBloc Initialized for Provider ID: ${state.provider?.id}");
  }

  void _initializeAttendees(ServiceProviderModel provider) {
    if (_userId != null && _userName != null) {
      final initialState = state;
      if (initialState is ReservationInitial) {
        emit(initialState.copyWith(selectedAttendees: [
          AttendeeModel(
            userId: _userId!,
            name: _userName!,
            type: 'self',
            status: 'going',
          )
        ]));
        print("ReservationBloc: Initialized attendees with 'self'.");
      }
    } else {
      print("ReservationBloc WARN: User not logged in during initialization.");
    }
  }

  void _onSelectReservationType(
      SelectReservationType event, Emitter<ReservationState> emit) {
    print(
        "ReservationBloc: Reservation Type selected - ${event.reservationType.displayString}");
    final currentProvider = state.provider;
    if (currentProvider == null) {
      emit(ReservationError(
          message: "Provider context missing.",
          provider: null,
          selectedReservationType: null,
          selectedAttendees: state.selectedAttendees));
      return;
    }
    if (!currentProvider.supportedReservationTypes
        .contains(event.reservationType.typeString)) {
      emit(ReservationError(
        message:
            "Provider does not support '${event.reservationType.displayString}' reservations.",
        provider: currentProvider,
        selectedReservationType: state.selectedReservationType,
        selectedAttendees: state.selectedAttendees,
      ));
      return;
    }
    emit(ReservationTypeSelected(
      provider: currentProvider,
      selectedReservationType: event.reservationType,
      selectedAttendees: state.selectedAttendees,
      // Reset typeSpecificData when type changes, unless it's accessBased again
      typeSpecificData: event.reservationType == ReservationType.accessBased
          ? state.typeSpecificData
          : null,
    ));
  }

  void _onSelectReservationService(
      SelectReservationService event, Emitter<ReservationState> emit) {
    final service = event.selectedService;
    final currentProvider = state.provider;
    final currentType = state.selectedReservationType;
    print("ReservationBloc: Service selected - ${service?.name ?? 'General'}");

    if (currentProvider == null || currentType == null) {
      emit(ReservationError(
          message: "Provider or reservation type missing.",
          provider: currentProvider,
          selectedReservationType: currentType,
          selectedAttendees: state.selectedAttendees));
      return;
    }
    if (service != null &&
        service.type != ReservationType.unknown &&
        service.type != currentType) {
      print(
          "ReservationBloc: Warning - Selected service type (${service.type.displayString}) doesn't match flow type (${currentType.displayString}).");
    }
    if (service != null) {
      emit(ReservationServiceSelected(
        provider: currentProvider,
        selectedReservationType: currentType,
        service: service,
        selectedAttendees: state.selectedAttendees,
        typeSpecificData: state.typeSpecificData, // Preserve
      ));
    } else {
      // If service is deselected (e.g., for general time-based booking)
      emit(ReservationTypeSelected(
        provider: currentProvider,
        selectedReservationType: currentType,
        selectedAttendees: state.selectedAttendees,
        typeSpecificData: state.typeSpecificData, // Preserve
      ));
    }
  }

  Future<void> _onSelectReservationDate(
      SelectReservationDate event, Emitter<ReservationState> emit) async {
    final currentService = state.selectedService;
    final currentType = state.selectedReservationType;
    final currentProvider = state.provider;
    final currentAttendees = state.selectedAttendees;

    if (currentProvider == null || currentType == null) {
      emit(ReservationError(
          message: "Provider or reservation type missing.",
          provider: currentProvider,
          selectedReservationType: currentType,
          selectedAttendees: currentAttendees));
      return;
    }
    final String? govId = currentProvider.governorateId;
    bool requiresFineGrainedSlots = [
      ReservationType.timeBased,
      ReservationType.seatBased,
      ReservationType.recurring,
      ReservationType.group
    ].contains(currentType);
    int? durationMinutes;

    if (requiresFineGrainedSlots) {
      durationMinutes = currentService?.durationMinutes ??
          _getTimeBasedDefaultDuration(currentProvider);
      if (durationMinutes == null || durationMinutes <= 0) {
        emit(ReservationError(
            message: "Invalid or missing service duration for fetching slots.",
            provider: currentProvider,
            selectedReservationType: currentType,
            selectedService: currentService,
            selectedDate: event.selectedDate,
            selectedAttendees: currentAttendees));
        return;
      }
      print(
          "ReservationBloc: Using duration $durationMinutes min for slot fetching.");
    }

    print(
        "ReservationBloc: Date selected - ${event.selectedDate}, Type: ${currentType.displayString}, GovID: $govId");

    emit(ReservationDateSelected(
      provider: currentProvider,
      selectedReservationType: currentType,
      selectedService: currentService,
      date: event.selectedDate,
      availableSlots: const [], // Clear old slots
      selectedAttendees: currentAttendees,
      isLoadingSlots: requiresFineGrainedSlots,
      selectedStartTime: (currentType == ReservationType.sequenceBased)
          ? state.selectedStartTime
          : null,
      selectedEndTime: null,
      typeSpecificData: state.typeSpecificData, // Preserve
    ));

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
        print(
            "ReservationBloc: Fetched ${availableStartSlots.length} available start slots.");

        if (state is ReservationDateSelected &&
            (state as ReservationDateSelected).selectedDate ==
                event.selectedDate &&
            (state as ReservationDateSelected).selectedReservationType ==
                currentType) {
          emit((state as ReservationDateSelected).copyWith(
            availableSlots: availableStartSlots,
            isLoadingSlots: false,
          ));
        } else {
          print(
              "ReservationBloc: State changed while fetching slots. Ignoring results.");
        }
      } catch (e) {
        print("ReservationBloc: Error fetching available slots: $e");
        emit(ReservationError(
            message: "Failed to load availability: ${e.toString()}",
            provider: currentProvider,
            selectedReservationType: currentType,
            selectedService: currentService,
            selectedDate: event.selectedDate,
            availableSlots: const [],
            selectedAttendees: currentAttendees));
      }
    }
  }

  void _onSelectSequenceTimeSlot(
      SelectSequenceTimeSlot event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;

    if (currentProvider != null &&
        currentState is ReservationDateSelected &&
        currentState.selectedReservationType == ReservationType.sequenceBased) {
      String formattedTime = event.preferredHour != null
          ? "${event.preferredHour!.hour}:${event.preferredHour!.minute.toString().padLeft(2, '0')}"
          : "None";
      print(
          "ReservationBloc: Preferred sequence hour selected: $formattedTime");

      emit(currentState.copyWith(
        selectedStartTime: event.preferredHour,
        selectedEndTime: null,
      ));
    } else {
      print(
          "ReservationBloc: Cannot select sequence time slot in current state: ${currentState.runtimeType} or date not selected.");
    }
  }

  // *** ADDED: Handler for SelectAccessPassOption ***
  void _onSelectAccessPassOption(
      SelectAccessPassOption event, Emitter<ReservationState> emit) {
    final currentState = state;
    if (currentState.provider == null ||
        currentState.selectedReservationType != ReservationType.accessBased) {
      print("ReservationBloc: Cannot select access pass, invalid state.");
      // Optionally emit an error or just return
      return;
    }
    print("ReservationBloc: Access Pass selected - ${event.option.label}");
    // Update the typeSpecificData with the selected pass ID
    emit(state.copyWith(
      typeSpecificData: {'selectedAccessPassId': event.option.id},
      // Reset other time/service specific fields if necessary, though for access-based they might not be relevant
      selectedService: null,
      selectedStartTime: null,
      selectedEndTime: null,
      availableSlots: [],
    ));
  }

  int _getTimeBasedDefaultDuration(ServiceProviderModel provider) {
    if (state.selectedService?.durationMinutes != null &&
        state.selectedService!.durationMinutes! > 0) {
      return state.selectedService!.durationMinutes!;
    }
    final timeBasedConfig = provider.reservationTypeConfigs?['timeBased'];
    if (timeBasedConfig is Map &&
        timeBasedConfig['defaultDurationMinutes'] is int) {
      return timeBasedConfig['defaultDurationMinutes'];
    }
    return provider.bookableServices
            .firstWhereOrNull((s) =>
                (s.type == ReservationType.timeBased ||
                    s.type == ReservationType.group) &&
                s.durationMinutes != null &&
                s.durationMinutes! > 0)
            ?.durationMinutes ??
        provider.bookableServices
            .firstWhereOrNull(
                (s) => s.durationMinutes != null && s.durationMinutes! > 0)
            ?.durationMinutes ??
        60;
  }

  void _onUpdateSwipeSelection(
      UpdateSwipeSelection event, Emitter<ReservationState> emit) {
    final currentState = state;
    final currentProvider = currentState.provider;

    if (currentProvider == null ||
        currentState.selectedReservationType != ReservationType.timeBased ||
        currentState.selectedDate == null) {
      emit(ReservationError(
          message: "Please select type and date first.",
          provider: currentProvider,
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
        provider: currentProvider,
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
    emit(ReservationRangeSelected(
      provider: currentProvider,
      selectedReservationType: currentState.selectedReservationType!,
      selectedService: currentState.selectedService,
      date: currentState.selectedDate!,
      startTime: startTime,
      endTime: endTime,
      availableSlots: currentState.availableSlots,
      selectedAttendees: currentState.selectedAttendees,
      typeSpecificData: currentState.typeSpecificData, // Preserve
    ));
  }

  void _onAddAttendee(AddAttendee event, Emitter<ReservationState> emit) {
    final currentProvider = state.provider;
    if (currentProvider == null) return;
    final currentAttendees = List<AttendeeModel>.from(state.selectedAttendees);
    final maxGroupSize = currentProvider.maxGroupSize;
    if (currentAttendees.any((a) => a.userId == event.attendee.userId)) {
      return;
    }
    if (maxGroupSize != null && currentAttendees.length >= maxGroupSize) {
      // Emit a new state that includes the error message, rather than just calling copyWith on the abstract state
      // This requires knowing the current concrete state type or having a more flexible error state.
      // For simplicity here, we'll emit a general ReservationError.
      emit(ReservationError(
        message: "Maximum group size ($maxGroupSize) reached.",
        provider: currentProvider,
        selectedReservationType: state.selectedReservationType,
        selectedService: state.selectedService,
        selectedDate: state.selectedDate,
        selectedStartTime: state.selectedStartTime,
        selectedEndTime: state.selectedEndTime,
        availableSlots: state.availableSlots,
        selectedAttendees: state.selectedAttendees,
        typeSpecificData: state.typeSpecificData,
      ));
      return;
    }
    currentAttendees.add(event.attendee);
    emit(state.copyWith(selectedAttendees: currentAttendees));
  }

  void _onRemoveAttendee(RemoveAttendee event, Emitter<ReservationState> emit) {
    final currentProvider = state.provider;
    if (currentProvider == null) return;
    final currentAttendees = List<AttendeeModel>.from(state.selectedAttendees);
    final initialLength = currentAttendees.length;
    currentAttendees.removeWhere(
        (a) => a.userId == event.userIdToRemove && a.type != 'self');
    if (currentAttendees.length < initialLength) {
      emit(state.copyWith(selectedAttendees: currentAttendees));
    }
  }

  Future<void> _onCreateReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    final stateBeforeCreate = state;
    final userId = _userId;
    final userName = _userName;
    final currentProvider = stateBeforeCreate.provider;

    if (userId == null || userName == null) {
      emit(ReservationError(
          message: "User not authenticated.",
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    if (currentProvider == null ||
        stateBeforeCreate.selectedReservationType == null ||
        stateBeforeCreate.selectedAttendees.isEmpty) {
      emit(ReservationError(
          message: "Missing required reservation context.",
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(ReservationError(
          message:
              "Provider is missing necessary location information (Governorate ID).",
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }
    final int? maxGroup = currentProvider.maxGroupSize;
    if (maxGroup != null &&
        stateBeforeCreate.selectedAttendees.length > maxGroup) {
      emit(ReservationError(
          message:
              "Number of attendees exceeds the maximum allowed ($maxGroup).",
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedAttendees: stateBeforeCreate.selectedAttendees,
          selectedDate: stateBeforeCreate.selectedDate,
          selectedStartTime: stateBeforeCreate.selectedStartTime,
          selectedEndTime: stateBeforeCreate.selectedEndTime));
      return;
    }
    if (stateBeforeCreate.selectedReservationType ==
        ReservationType.sequenceBased) {
      print(
          "ReservationBloc: CreateReservation event ignored for sequence-based type. Use JoinQueue instead.");
      return;
    }
    bool ready = isReservationReadyToConfirm(
        stateBeforeCreate, stateBeforeCreate.selectedReservationType);
    if (!ready) {
      emit(ReservationError(
          message: "Please complete all required fields.",
          provider: currentProvider,
          selectedReservationType: stateBeforeCreate.selectedReservationType,
          selectedService: stateBeforeCreate.selectedService,
          selectedDate: stateBeforeCreate.selectedDate,
          selectedStartTime: stateBeforeCreate.selectedStartTime,
          selectedEndTime: stateBeforeCreate.selectedEndTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: stateBeforeCreate.selectedAttendees));
      return;
    }

    final reservationType = stateBeforeCreate.selectedReservationType!;
    final attendees = stateBeforeCreate.selectedAttendees;
    final service = stateBeforeCreate.selectedService;
    final date = stateBeforeCreate.selectedDate;
    final startTime = stateBeforeCreate.selectedStartTime;
    final endTime = stateBeforeCreate.selectedEndTime;

    emit(ReservationCreating(
      provider: currentProvider,
      selectedReservationType: reservationType,
      selectedService: service,
      selectedDate: date,
      selectedStartTime: startTime,
      selectedEndTime: endTime,
      availableSlots: stateBeforeCreate.availableSlots,
      selectedAttendees: attendees,
      typeSpecificData: stateBeforeCreate.typeSpecificData, // Preserve
    ));
    print(
        "ReservationBloc: Creating '${reservationType.displayString}' reservation...");

    final payload = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'providerId': currentProvider.id,
      'governorateId': govId,
      'reservationType': reservationType.typeString,
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'groupSize': attendees.length,
      if (service != null) 'serviceId': service.id,
      if (service != null) 'serviceName': service.name,
      'durationMinutes': service?.durationMinutes ??
          (reservationType == ReservationType.timeBased
              ? _getTimeBasedDefaultDuration(currentProvider)
              : null),
      'pricePerSlotOrService': service?.price,
      if (date != null)
        'reservationDateMillis': DateTime.utc(date.year, date.month, date.day)
            .millisecondsSinceEpoch,
      if ([
        ReservationType.timeBased,
        ReservationType.seatBased,
        ReservationType.recurring,
        ReservationType.group
      ].contains(reservationType)) ...{
        if (startTime != null)
          'startTimeOfDay': {
            'hour': startTime.hour,
            'minute': startTime.minute
          },
        if (endTime != null)
          'endTimeOfDay': {'hour': endTime.hour, 'minute': endTime.minute},
      },
      'typeSpecificData': _getTypeSpecificData(stateBeforeCreate),
    };

    try {
      final result =
          await _reservationRepository.createReservationOnBackend(payload);
      if (result['success'] == true) {
        final successMessage =
            result['message'] as String? ?? "Reservation confirmed!";
        emit(ReservationSuccess(
          message: successMessage,
          provider: currentProvider,
          selectedReservationType: reservationType,
          selectedService: service,
          selectedDate: date,
          selectedStartTime: startTime,
          selectedEndTime: endTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: attendees,
          typeSpecificData: stateBeforeCreate.typeSpecificData, // Preserve
        ));
      } else {
        final errorMessage =
            result['error'] as String? ?? 'Reservation failed on the server.';
        emit(ReservationError(
          message: errorMessage,
          provider: currentProvider,
          selectedReservationType: reservationType,
          selectedService: service,
          selectedDate: date,
          selectedStartTime: startTime,
          selectedEndTime: endTime,
          availableSlots: stateBeforeCreate.availableSlots,
          selectedAttendees: attendees,
          typeSpecificData: stateBeforeCreate.typeSpecificData, // Preserve
        ));
      }
    } catch (e) {
      emit(ReservationError(
        message: "Failed to create reservation: ${e.toString()}",
        provider: currentProvider,
        selectedReservationType: reservationType,
        selectedService: service,
        selectedDate: date,
        selectedStartTime: startTime,
        selectedEndTime: endTime,
        availableSlots: stateBeforeCreate.availableSlots,
        selectedAttendees: attendees,
        typeSpecificData: stateBeforeCreate.typeSpecificData, // Preserve
      ));
    }
  }

  Map<String, dynamic>? _getTypeSpecificData(ReservationState currentState) {
    if (currentState.selectedReservationType == ReservationType.accessBased &&
        currentState.typeSpecificData != null) {
      return currentState.typeSpecificData;
    }
    // Add other types if they use typeSpecificData
    return null;
  }

  void _onResetReservationFlow(
      ResetReservationFlow event, Emitter<ReservationState> emit) {
    print("ReservationBloc: Resetting flow.");
    final providerToUse = event.provider ?? state.provider;
    if (providerToUse == null) {
      emit(const ReservationError(
          message: "Cannot reset: Provider missing.", provider: null));
      return;
    }
    final initialAttendees = (_userId != null && _userName != null)
        ? [
            AttendeeModel(
                userId: _userId!,
                name: _userName!,
                type: 'self',
                status: 'going')
          ]
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
        typeSpecificData: initialType == ReservationType.accessBased
            ? state.typeSpecificData
            : null, // Preserve for access based if it was the single type
      ));
    } else {
      emit(ReservationInitial(provider: providerToUse)
          .copyWith(selectedAttendees: initialAttendees));
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _onJoinQueue(
      JoinQueue event, Emitter<ReservationState> emit) async {
    final stateBeforeJoin = state;
    final currentProvider = stateBeforeJoin.provider;
    final currentService = stateBeforeJoin.selectedService;
    final currentAttendees = stateBeforeJoin.selectedAttendees;
    final currentUserId = _userId;
    final preferredDate = stateBeforeJoin.selectedDate;
    final preferredHour = stateBeforeJoin.selectedStartTime;

    if (currentUserId == null) {
      emit(ReservationQueueError(
          message: "User not logged in.",
          provider: currentProvider,
          selectedService: currentService,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate,
          selectedReservationType: ReservationType.sequenceBased));
      return;
    }
    if (currentProvider == null ||
        stateBeforeJoin.selectedReservationType !=
            ReservationType.sequenceBased) {
      emit(ReservationQueueError(
          message: "Invalid state for joining queue.",
          provider: currentProvider,
          selectedReservationType: stateBeforeJoin.selectedReservationType,
          selectedService: currentService,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate));
      return;
    }
    if (currentService == null) {
      emit(ReservationQueueError(
          message: "Please select a service to join the queue.",
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate));
      return;
    }
    if (preferredDate == null) {
      emit(ReservationQueueError(
          message: "Please select a date.",
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: currentService,
          selectedAttendees: currentAttendees));
      return;
    }
    if (preferredHour == null) {
      emit(ReservationQueueError(
          message: "Please select a preferred hour slot.",
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: currentService,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate));
      return;
    }

    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(ReservationQueueError(
          message: "Provider location information missing.",
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: currentService,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate));
      return;
    }

    String formattedTime =
        "${preferredHour.hour}:${preferredHour.minute.toString().padLeft(2, '0')}";
    print(
        "ReservationBloc: Joining queue for service ${currentService.name} on $preferredDate at $formattedTime...");
    emit(ReservationJoiningQueue(
        provider: currentProvider,
        selectedReservationType: ReservationType.sequenceBased,
        selectedService: currentService,
        selectedAttendees: currentAttendees,
        selectedDate: preferredDate,
        selectedStartTime: preferredHour));

    try {
      final result = await _reservationRepository.joinQueue(
          userId: currentUserId,
          providerId: currentProvider.id,
          governorateId: govId,
          serviceId: currentService.id,
          attendees: currentAttendees,
          preferredDate: preferredDate,
          preferredHour: preferredHour);
      if (result['success'] == true) {
        final int position = (result['queuePosition'] as num?)?.toInt() ?? -1;
        final Timestamp? estimateTimestamp =
            result['estimatedEntryTime'] as Timestamp?;
        final DateTime? estimateDateTime = estimateTimestamp?.toDate();
        emit(ReservationInQueue(
            provider: currentProvider,
            selectedReservationType: ReservationType.sequenceBased,
            selectedService: currentService,
            selectedAttendees: currentAttendees,
            selectedDate: preferredDate,
            selectedStartTime: preferredHour,
            queuePosition: position,
            estimatedEntryTime: estimateDateTime));
      } else {
        final errorMsg =
            result['error'] as String? ?? "Failed to join the queue.";
        // Revert to ReservationDateSelected with an error message or keep specific error state
        emit(ReservationQueueError(
          message: errorMsg,
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: currentService,
          selectedAttendees: currentAttendees,
          selectedDate: preferredDate,
          selectedStartTime: preferredHour,
        ));
      }
    } catch (e) {
      emit(ReservationQueueError(
        message: "Error joining queue: ${e.toString()}",
        provider: currentProvider,
        selectedReservationType: ReservationType.sequenceBased,
        selectedService: currentService,
        selectedAttendees: currentAttendees,
        selectedDate: preferredDate,
        selectedStartTime: preferredHour,
      ));
    }
  }

  Future<void> _onCheckQueueStatus(
      CheckQueueStatus event, Emitter<ReservationState> emit) async {
    final currentState = state;
    if (currentState is! ReservationInQueue) return;
    final currentUserId = _userId;
    final currentProvider = currentState.provider;
    final currentService = currentState.selectedService;
    final preferredDate = currentState.selectedDate;
    final preferredHour = currentState.selectedStartTime;
    if (currentUserId == null ||
        currentProvider == null ||
        currentService == null ||
        preferredDate == null ||
        preferredHour == null) {
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      return;
    }
    try {
      final result = await _reservationRepository.checkQueueStatus(
          userId: currentUserId,
          providerId: currentProvider.id,
          governorateId: govId,
          serviceId: currentService.id,
          preferredDate: preferredDate,
          preferredHour: preferredHour);
      if (result['success'] == true) {
        final int position = (result['queuePosition'] as num?)?.toInt() ??
            currentState.queuePosition;
        final Timestamp? estimateTimestamp =
            result['estimatedEntryTime'] as Timestamp?;
        final DateTime? estimateDateTime =
            estimateTimestamp?.toDate() ?? currentState.estimatedEntryTime;
        emit(currentState.copyWith(
            queuePosition: position,
            estimatedEntryTime: estimateDateTime,
            forceEstimatedEntryTimeNull: estimateTimestamp == null &&
                currentState.estimatedEntryTime != null));
      }
    } catch (e) {
      print("Error calling checkQueueStatus: $e");
    }
  }

  Future<void> _onLeaveQueue(
      LeaveQueue event, Emitter<ReservationState> emit) async {
    final currentState = state;
    if (currentState is! ReservationInQueue) return;
    final currentUserId = _userId;
    final currentProvider = currentState.provider;
    final currentService = currentState.selectedService;
    final preferredDate = currentState.selectedDate;
    final preferredHour = currentState.selectedStartTime;
    if (currentUserId == null ||
        currentProvider == null ||
        currentService == null ||
        preferredDate == null ||
        preferredHour == null) {
      emit(ReservationQueueError(
          message: "Cannot leave queue: Missing context.",
          provider: currentProvider,
          selectedReservationType: currentState.selectedReservationType,
          selectedAttendees: currentState.selectedAttendees,
          selectedService: currentService,
          selectedDate: preferredDate));
      return;
    }
    final String? govId = currentProvider.governorateId;
    if (govId == null || govId.isEmpty) {
      emit(ReservationQueueError(
          message: "Cannot leave queue: Provider location missing.",
          provider: currentProvider,
          selectedReservationType: currentState.selectedReservationType,
          selectedAttendees: currentState.selectedAttendees,
          selectedService: currentService,
          selectedDate: preferredDate));
      return;
    }
    try {
      final result = await _reservationRepository.leaveQueue(
          userId: currentUserId,
          providerId: currentProvider.id,
          governorateId: govId,
          serviceId: currentService.id,
          preferredDate: preferredDate,
          preferredHour: preferredHour);
      if (result['success'] == true) {
        // Revert to the state before joining the queue, typically ReservationDateSelected
        emit(ReservationDateSelected(
            provider: currentProvider,
            selectedReservationType: ReservationType.sequenceBased,
            selectedService: currentService,
            selectedAttendees: currentState.selectedAttendees,
            date: preferredDate,
            availableSlots: const [], // Slots are not relevant for sequence based after leaving
            selectedStartTime: preferredHour, // Keep preferred hour selected
            isLoadingSlots: false));
      } else {
        final errorMsg =
            result['error'] as String? ?? "Failed to leave the queue.";
        emit(ReservationQueueError(
            message: errorMsg,
            provider: currentProvider,
            selectedReservationType: ReservationType.sequenceBased,
            selectedService: currentService,
            selectedAttendees: currentState.selectedAttendees,
            selectedDate: preferredDate));
      }
    } catch (e) {
      emit(ReservationQueueError(
          message: "Error leaving queue: ${e.toString()}",
          provider: currentProvider,
          selectedReservationType: ReservationType.sequenceBased,
          selectedService: currentService,
          selectedAttendees: currentState.selectedAttendees,
          selectedDate: preferredDate));
    }
  }

  bool isReservationReadyToConfirm(
      ReservationState currentState, ReservationType? selectedType) {
    final provider = currentState.provider;
    if (currentState.selectedAttendees.isEmpty ||
        selectedType == null ||
        provider == null) return false;
    switch (selectedType) {
      case ReservationType.timeBased:
        return currentState.selectedDate != null &&
            currentState.selectedStartTime != null &&
            currentState.selectedEndTime != null &&
            _timeOfDayToMinutes(currentState.selectedEndTime!) >
                _timeOfDayToMinutes(currentState.selectedStartTime!);
      case ReservationType.serviceBased:
        return currentState.selectedService != null;
      case ReservationType.seatBased:
        // Add seat selection check when implemented
        return currentState.selectedDate != null &&
            currentState.selectedStartTime != null;
      case ReservationType.accessBased:
        // Check if an access pass option is selected via typeSpecificData
        return currentState.selectedDate != null &&
            currentState.typeSpecificData?['selectedAccessPassId'] != null;
      case ReservationType.recurring:
        return currentState.selectedService != null &&
            currentState.selectedDate != null;
      case ReservationType.group:
        final primaryType = provider.supportedReservationTypes
            .map(reservationTypeFromString)
            .firstWhereOrNull((t) =>
                t != ReservationType.group && t != ReservationType.unknown);
        return primaryType != null
            ? isReservationReadyToConfirm(currentState, primaryType)
            : false;
      case ReservationType.sequenceBased:
        return false;
      case ReservationType.unknown:
      default:
        return false;
    }
  }
}
