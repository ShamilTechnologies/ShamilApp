// lib/feature/reservation/bloc/reservation_state.dart

part of 'reservation_bloc.dart'; // Link to the bloc file

// Base class using Equatable for state comparison
@immutable
abstract class ReservationState extends Equatable {
  final ServiceProviderModel? provider;
  final ReservationType? selectedReservationType;
  final BookableService? selectedService;
  final DateTime? selectedDate;
  final TimeOfDay?
      selectedStartTime; // For time-based start, OR sequence-based preferred hour
  final TimeOfDay? selectedEndTime; // For time-based end
  final List<TimeOfDay> availableSlots; // For time-based slots
  final List<AttendeeModel> selectedAttendees;
  // *** ADDED typeSpecificData field ***
  final Map<String, dynamic>?
      typeSpecificData; // For access-based pass ID, etc.

  const ReservationState({
    required this.provider,
    this.selectedReservationType,
    this.selectedService,
    this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    this.availableSlots = const [],
    this.selectedAttendees = const [],
    this.typeSpecificData, // Added to constructor
  });

  @override
  List<Object?> get props => [
        provider, selectedReservationType, selectedService, selectedDate,
        selectedStartTime, selectedEndTime, availableSlots, selectedAttendees,
        typeSpecificData, // Added to props
      ];

  AttendeeModel? get bookingUser =>
      selectedAttendees.firstWhereOrNull((a) => a.type == 'self');

  // Base copyWith method - Subclasses MUST override this correctly
  // Includes all possible fields from all subclasses for a consistent signature.
  ReservationState copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added to copyWith
    // Fields from specific states
    bool? isLoadingSlots,
    String? message, // For ReservationError and ReservationSuccess
    int? queuePosition, // For ReservationInQueue
    DateTime? estimatedEntryTime, // For ReservationInQueue
    bool?
        forceEstimatedEntryTimeNull, // Specific for ReservationInQueue.copyWith
  }) {
    throw UnimplementedError(
        'copyWith must be implemented by concrete subclasses of ReservationState: ${this.runtimeType}');
  }
}

// --- Concrete State Classes ---

/// Initial state
class ReservationInitial extends ReservationState {
  const ReservationInitial({
    required super.provider,
    super.selectedAttendees = const [],
    super.typeSpecificData, // Pass to super
  });

  @override
  ReservationInitial copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationInitial(
      provider: provider ?? this.provider!,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// Type selected state
class ReservationTypeSelected extends ReservationState {
  const ReservationTypeSelected({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedAttendees,
    super.selectedService,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots = const [],
    super.typeSpecificData, // Pass to super, reset if type changes significantly
  });

  @override
  ReservationTypeSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationTypeSelected(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// Service selected state
class ReservationServiceSelected extends ReservationState {
  const ReservationServiceSelected({
    required super.provider,
    required super.selectedReservationType,
    required BookableService service,
    required super.selectedAttendees,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots = const [],
    super.typeSpecificData, // Pass to super
  }) : super(selectedService: service);

  @override
  ReservationServiceSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationServiceSelected(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      service: selectedService ?? this.selectedService!,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// Date selected state
class ReservationDateSelected extends ReservationState {
  final bool isLoadingSlots;

  const ReservationDateSelected({
    required super.provider,
    required super.selectedReservationType,
    super.selectedService,
    required DateTime date,
    super.availableSlots = const [],
    required super.selectedAttendees,
    this.isLoadingSlots = false,
    super.selectedStartTime,
    super.selectedEndTime,
    super.typeSpecificData, // Pass to super
  }) : super(selectedDate: date);

  @override
  ReservationDateSelected copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationDateSelected(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      selectedStartTime: selectedStartTime,
      selectedEndTime: selectedEndTime,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }

  @override
  List<Object?> get props => super.props..add(isLoadingSlots);
}

/// Time range selected state (primarily for time-based)
class ReservationRangeSelected extends ReservationState {
  const ReservationRangeSelected({
    required super.provider,
    required super.selectedReservationType,
    required super.selectedService,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required super.availableSlots,
    required super.selectedAttendees,
    super.typeSpecificData, // Pass to super
  }) : super(
            selectedDate: date,
            selectedStartTime: startTime,
            selectedEndTime: endTime);

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
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationRangeSelected(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!,
      startTime: selectedStartTime ?? this.selectedStartTime!,
      endTime: selectedEndTime ?? this.selectedEndTime!,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// Creating state (for non-queue based reservations)
class ReservationCreating extends ReservationState {
  const ReservationCreating({
    required super.provider,
    required super.selectedReservationType,
    super.selectedService,
    required super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots,
    required super.selectedAttendees,
    super.typeSpecificData, // Pass to super
  });

  @override
  ReservationCreating copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationCreating(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// Success state (for non-queue based reservations)
class ReservationSuccess extends ReservationState {
  final String message;
  const ReservationSuccess({
    required this.message,
    required super.provider,
    required super.selectedReservationType,
    super.selectedService,
    required super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots,
    required super.selectedAttendees,
    super.typeSpecificData, // Pass to super
  });

  @override
  List<Object?> get props => super.props..add(message);

  @override
  ReservationSuccess copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    // Typically, success state isn't copied with new data, but rather a new success state is emitted.
    // However, if needed for some edge case:
    return ReservationSuccess(
      message: message ?? this.message,
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// General Error state
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
    super.typeSpecificData, // Pass to super
  });

  @override
  List<Object?> get props => super.props..add(message);

  @override
  ReservationError copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationError(
      message: message ?? this.message,
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

// --- Sequence-Based States ---

/// State indicating the user is attempting to join the queue.
class ReservationJoiningQueue extends ReservationState {
  const ReservationJoiningQueue({
    required super.provider,
    required super.selectedReservationType, // Should be sequenceBased
    required super.selectedService, // Service being queued for
    required super.selectedAttendees,
    super.selectedDate, // Date of the queue
    super.selectedStartTime, // Preferred hour
    super.typeSpecificData, // Pass to super
  });

  @override
  ReservationJoiningQueue copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationJoiningQueue(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// State indicating the user has successfully joined the queue.
class ReservationInQueue extends ReservationState {
  final int queuePosition;
  final DateTime? estimatedEntryTime;

  const ReservationInQueue({
    required super.provider,
    required super.selectedReservationType, // Should be sequenceBased
    required super.selectedService,
    required super.selectedAttendees,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    required this.queuePosition,
    this.estimatedEntryTime,
    super.availableSlots = const [],
    super.typeSpecificData, // Pass to super
  });

  @override
  List<Object?> get props =>
      super.props..addAll([queuePosition, estimatedEntryTime]);

  @override
  ReservationInQueue copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData, // Added
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
  }) {
    return ReservationInQueue(
      provider: provider ?? this.provider,
      selectedReservationType:
          selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedEntryTime: (forceEstimatedEntryTimeNull ?? false)
          ? null
          : (estimatedEntryTime ?? this.estimatedEntryTime),
      availableSlots: availableSlots ?? this.availableSlots,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData, // Added
    );
  }
}

/// State indicating an error occurred specifically during queue operations.
class ReservationQueueError extends ReservationError {
  const ReservationQueueError({
    required super.message,
    required super.provider,
    super.selectedReservationType,
    super.selectedService,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedAttendees,
    super.typeSpecificData, // Pass to super
  });
}
