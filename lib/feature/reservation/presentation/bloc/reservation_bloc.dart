import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../../home/data/service_provider_model.dart';

// Events
abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class SelectReservationType extends ReservationEvent {
  final ReservationType type;

  const SelectReservationType(this.type);

  @override
  List<Object?> get props => [type];
}

class UpdateTypeSpecificData extends ReservationEvent {
  final Map<String, dynamic> data;

  const UpdateTypeSpecificData(this.data);

  @override
  List<Object?> get props => [data];
}

class CreateReservation extends ReservationEvent {
  final String userId;
  final String userName;
  final ServiceProviderModel provider;
  final ReservationType type;
  final DateTime selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<AttendeeModel> selectedAttendees;
  final Map<String, dynamic> typeSpecificData;
  final bool isRecurring;

  const CreateReservation({
    required this.userId,
    required this.userName,
    required this.provider,
    required this.type,
    required this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    required this.selectedAttendees,
    required this.typeSpecificData,
    this.isRecurring = false,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        provider,
        type,
        selectedDate,
        selectedStartTime,
        selectedEndTime,
        selectedAttendees,
        typeSpecificData,
        isRecurring,
      ];
}

// States
abstract class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ReservationState {}

class ReservationLoading extends ReservationState {}

class ReservationTypeSelected extends ReservationState {
  final ServiceProviderModel provider;
  final ReservationType selectedType;
  final Map<String, dynamic> typeSpecificData;

  const ReservationTypeSelected({
    required this.provider,
    required this.selectedType,
    this.typeSpecificData = const {},
  });

  @override
  List<Object?> get props => [provider, selectedType, typeSpecificData];
}

class ReservationRangeSelected extends ReservationState {
  final ServiceProviderModel provider;
  final ReservationType selectedType;
  final BookableService? selectedService;
  final DateTime selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<AttendeeModel> selectedAttendees;
  final Map<String, dynamic> typeSpecificData;

  const ReservationRangeSelected({
    required this.provider,
    required this.selectedType,
    this.selectedService,
    required this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    this.selectedAttendees = const [],
    this.typeSpecificData = const {},
  });

  @override
  List<Object?> get props => [
        provider,
        selectedType,
        selectedService,
        selectedDate,
        selectedStartTime,
        selectedEndTime,
        selectedAttendees,
        typeSpecificData,
      ];
}

class ReservationSuccess extends ReservationState {
  final String message;
  final ServiceProviderModel provider;
  final ReservationType selectedType;
  final BookableService? selectedService;
  final DateTime selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<AttendeeModel> selectedAttendees;
  final Map<String, dynamic> typeSpecificData;

  const ReservationSuccess({
    required this.message,
    required this.provider,
    required this.selectedType,
    this.selectedService,
    required this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    required this.selectedAttendees,
    required this.typeSpecificData,
  });

  @override
  List<Object?> get props => [
        message,
        provider,
        selectedType,
        selectedService,
        selectedDate,
        selectedStartTime,
        selectedEndTime,
        selectedAttendees,
        typeSpecificData,
      ];
}

class ReservationError extends ReservationState {
  final String message;
  final ServiceProviderModel provider;
  final ReservationType selectedType;
  final BookableService? selectedService;
  final DateTime selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<AttendeeModel> selectedAttendees;
  final Map<String, dynamic> typeSpecificData;

  const ReservationError({
    required this.message,
    required this.provider,
    required this.selectedType,
    this.selectedService,
    required this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    required this.selectedAttendees,
    required this.typeSpecificData,
  });

  @override
  List<Object?> get props => [
        message,
        provider,
        selectedType,
        selectedService,
        selectedDate,
        selectedStartTime,
        selectedEndTime,
        selectedAttendees,
        typeSpecificData,
      ];
}

// Bloc
class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationRepository _reservationRepository;
  final String? _userId;
  final String? _userName;

  ReservationBloc({
    required ReservationRepository reservationRepository,
    String? userId,
    String? userName,
  })  : _reservationRepository = reservationRepository,
        _userId = userId,
        _userName = userName,
        super(ReservationInitial()) {
    on<SelectReservationType>(_onSelectReservationType);
    on<UpdateTypeSpecificData>(_onUpdateTypeSpecificData);
    on<CreateReservation>(_onCreateReservation);
  }

  void _onSelectReservationType(
    SelectReservationType event,
    Emitter<ReservationState> emit,
  ) {
    final state = this.state;
    if (state is! ReservationRangeSelected) return;

    emit(ReservationTypeSelected(
      provider: state.provider,
      selectedType: event.type,
      typeSpecificData: state.typeSpecificData,
    ));
  }

  void _onUpdateTypeSpecificData(
    UpdateTypeSpecificData event,
    Emitter<ReservationState> emit,
  ) {
    final state = this.state;
    if (state is! ReservationRangeSelected) return;

    final updatedData = Map<String, dynamic>.from(state.typeSpecificData)
      ..addAll(event.data);

    emit(ReservationRangeSelected(
      provider: state.provider,
      selectedType: state.selectedType,
      selectedService: state.selectedService,
      selectedDate: state.selectedDate,
      selectedStartTime: state.selectedStartTime,
      selectedEndTime: state.selectedEndTime,
      selectedAttendees: state.selectedAttendees,
      typeSpecificData: updatedData,
    ));
  }

  Future<void> _onCreateReservation(
    CreateReservation event,
    Emitter<ReservationState> emit,
  ) async {
    final state = this.state;
    if (state is! ReservationRangeSelected) return;

    try {
      // Validate reservation
      final validationResult = await _reservationRepository.validateReservation(
        event.provider.id,
        event.provider.governorateId!,
        event.type,
        event.typeSpecificData,
      );

      if (validationResult['isValid'] != true) {
        emit(ReservationError(
          message: validationResult['message'] ?? 'Invalid reservation',
          provider: state.provider,
          selectedType: state.selectedType,
          selectedService: state.selectedService,
          selectedDate: state.selectedDate,
          selectedStartTime: state.selectedStartTime,
          selectedEndTime: state.selectedEndTime,
          selectedAttendees: state.selectedAttendees,
          typeSpecificData: state.typeSpecificData,
        ));
        return;
      }

      // Create reservation
      final reservation = ReservationModel(
        id: const Uuid().v4(),
        userId: event.userId,
        userName: event.userName,
        providerId: event.provider.id,
        governorateId: event.provider.governorateId!,
        type: event.type,
        groupSize: event.selectedAttendees.length,
        serviceId: state.selectedService?.id,
        serviceName: state.selectedService?.name,
        durationMinutes: state.selectedService?.durationMinutes,
        reservationStartTime: Timestamp.fromDate(event.selectedDate),
        endTime: event.selectedEndTime != null
            ? Timestamp.fromDate(event.selectedDate.add(
                Duration(minutes: _timeOfDayToMinutes(event.selectedEndTime!)),
              ))
            : null,
        status: ReservationStatus.pending,
        typeSpecificData: event.typeSpecificData,
        attendees: event.selectedAttendees,
        createdAt: Timestamp.now(),
      );

      await _reservationRepository.createReservationOnBackend(
        reservation.toMapForCreate(),
      );

      emit(ReservationSuccess(
        message: 'Reservation created successfully',
        provider: state.provider,
        selectedType: state.selectedType,
        selectedService: state.selectedService,
        selectedDate: state.selectedDate,
        selectedStartTime: state.selectedStartTime,
        selectedEndTime: state.selectedEndTime,
        selectedAttendees: state.selectedAttendees,
        typeSpecificData: state.typeSpecificData,
      ));
    } catch (e) {
      emit(ReservationError(
        message: 'Failed to create reservation: $e',
        provider: state.provider,
        selectedType: state.selectedType,
        selectedService: state.selectedService,
        selectedDate: state.selectedDate,
        selectedStartTime: state.selectedStartTime,
        selectedEndTime: state.selectedEndTime,
        selectedAttendees: state.selectedAttendees,
        typeSpecificData: state.typeSpecificData,
      ));
    }
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}
