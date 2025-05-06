// lib/feature/reservation/bloc/reservation_state.dart

part of 'reservation_bloc.dart'; // Link to the bloc file


// Base class using Equatable for state comparison
@immutable
abstract class ReservationState extends Equatable {
  // Common properties available in most states AFTER initial state
  final ServiceProviderModel? provider;
  final ReservationType? selectedReservationType;
  final BookableService? selectedService;
  final DateTime? selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<TimeOfDay> availableSlots;
  final List<AttendeeModel> selectedAttendees;

  // Note: isLoadingSlots is NOT defined here in the base class

  const ReservationState({
    this.provider,
    this.selectedReservationType,
    this.selectedService,
    this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    this.availableSlots = const [],
    this.selectedAttendees = const [],
  });

  // Properties included for Equatable comparison
  @override
  List<Object?> get props => [
        provider,
        selectedReservationType,
        selectedService,
        selectedDate,
        selectedStartTime,
        selectedEndTime,
        availableSlots,
        selectedAttendees,
      ];

  // Helper to easily get the primary user making the booking
  AttendeeModel? get bookingUser =>
      selectedAttendees.firstWhereOrNull((a) => a.type == 'self');

  // Base copyWith method - MUST be overridden by concrete subclasses
  ReservationState copyWith({
    ServiceProviderModel? provider,
    List<AttendeeModel>? selectedAttendees,
  }) {
    throw UnimplementedError(
        'copyWith must be implemented by concrete subclasses of ReservationState');
  }
}

// --- Concrete State Classes ---

/// Initial state when the reservation flow starts. Requires provider context.
class ReservationInitial extends ReservationState {
  const ReservationInitial({required ServiceProviderModel provider})
      : super(provider: provider);

  @override
  ReservationInitial copyWith({
    ServiceProviderModel? provider,
    List<AttendeeModel>? selectedAttendees,
  }) {
    // Create a new instance, passing attendees to the super constructor
    return ReservationInitial(
      provider: provider ?? this.provider!,
    ).._internalSetAttendees(selectedAttendees ?? this.selectedAttendees);
  }

   ReservationInitial _internalSetAttendees(List<AttendeeModel> attendees) {
      // This helper is a bit redundant as the super constructor handles attendees.
      // We just need to return a new instance of the correct type.
      return ReservationInitial(provider: provider!);
   }
}

/// State after the user selects the reservation type (if multiple options).
class ReservationTypeSelected extends ReservationState {
  const ReservationTypeSelected({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedAttendees,
  });

  @override
  ReservationTypeSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    List<AttendeeModel>? selectedAttendees,
  }) {
    return ReservationTypeSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
    );
  }
}

/// State after a specific service is selected.
class ReservationServiceSelected extends ReservationState {
  // Service is guaranteed non-null in this state via constructor
  const ReservationServiceSelected({
    required super.provider,
    required super.selectedReservationType,
    required BookableService service,
    required super.selectedAttendees,
  }) : super(selectedService: service);

  @override
  ReservationServiceSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    List<AttendeeModel>? selectedAttendees,
  }) {
    return ReservationServiceSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      service: selectedService ?? this.selectedService!, // Use non-null assertion
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
    );
  }
}

/// State after a date is selected, potentially loading available slots/seats.
class ReservationDateSelected extends ReservationState {
  // *** isLoadingSlots is DEFINED HERE ***
  final bool isLoadingSlots;

  // Date is guaranteed non-null in this state via constructor
  const ReservationDateSelected({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedService,
    required DateTime date,
    required super.availableSlots,
    required super.selectedAttendees,
    this.isLoadingSlots = false,
  }) : super(selectedDate: date);

  @override
  ReservationDateSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    bool? isLoadingSlots,
    // Reset times when copying
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
  }) {
    return ReservationDateSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!, // Use non-null assertion
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      // selectedStartTime and selectedEndTime are implicitly reset
    );
  }

  @override
  List<Object?> get props => super.props..add(isLoadingSlots);
}

/// State after a valid time range is selected (for time-based reservations).
class ReservationRangeSelected extends ReservationState {
  // Date, StartTime, EndTime are guaranteed non-null via constructor
  const ReservationRangeSelected({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedService,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required super.availableSlots,
    required super.selectedAttendees,
  }) : super(selectedDate: date, selectedStartTime: startTime, selectedEndTime: endTime);

  @override
  ReservationRangeSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
  }) {
    return ReservationRangeSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!, // Use non-null assertion
      startTime: selectedStartTime ?? this.selectedStartTime!, // Use non-null assertion
      endTime: selectedEndTime ?? this.selectedEndTime!, // Use non-null assertion
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
    );
  }
}


/// State indicating the reservation creation is in progress (calling backend).
class ReservationCreating extends ReservationState {
  const ReservationCreating({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedService,
    required super.selectedDate,
    required super.selectedStartTime,
    required super.selectedEndTime,
    required super.availableSlots,
    required super.selectedAttendees,
  });

   @override
   ReservationCreating copyWith({ ServiceProviderModel? provider, List<AttendeeModel>? selectedAttendees}) {
       throw UnimplementedError('Cannot copy ReservationCreating state.');
   }
}

/// State indicating the reservation was successfully created.
class ReservationSuccess extends ReservationState {
  final String message;
  const ReservationSuccess({
    required this.message,
    required super.provider,
    required super.selectedReservationType,
    required super.selectedService,
    required super.selectedDate,
    required super.selectedStartTime,
    required super.selectedEndTime,
    required super.availableSlots,
    required super.selectedAttendees,
  });

  @override List<Object?> get props => super.props..add(message);

   @override
   ReservationSuccess copyWith({ ServiceProviderModel? provider, List<AttendeeModel>? selectedAttendees}) {
       throw UnimplementedError('Cannot copy ReservationSuccess state.');
   }
}

/// State indicating an error occurred during the reservation process.
class ReservationError extends ReservationState {
  final String message;
  const ReservationError({
    required this.message,
    required super.provider,
    super.selectedReservationType,
    super.selectedService,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots = const [],
    super.selectedAttendees = const [],
  });

  @override List<Object?> get props => super.props..add(message);

  @override
  ReservationError copyWith({
    ServiceProviderModel? provider,
    List<AttendeeModel>? selectedAttendees,
    String? message,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
  }) {
    return ReservationError(
      message: message ?? this.message,
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
    );
  }
}
