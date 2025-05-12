// lib/feature/reservation/bloc/reservation_state.dart

part of 'reservation_bloc.dart'; // Link to the bloc file

// Base class using Equatable for state comparison
@immutable
abstract class ReservationState extends Equatable {
  // Existing fields from previous updates
  final ServiceProviderModel? provider;
  final ReservationType? selectedReservationType;
  final BookableService? selectedService;
  final DateTime? selectedDate;
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
  final List<TimeOfDay> availableSlots;
  final List<AttendeeModel> selectedAttendees;
  final Map<String, dynamic>? typeSpecificData;
  final bool isFullVenueReservation;
  final int? reservedCapacity;
  final bool isCommunityVisible;
  final String? hostingCategory;
  final String? hostingDescription;
  final Map<String, PaymentStatus> attendeePaymentStatuses;
  final Map<String, dynamic>? costSplitDetails;
  final double basePrice;
  final double addOnsPrice;
  final double totalPrice;

  // NEWLY ADDED FIELDS based on the error messages
  final String? notes;
  final Map<String, dynamic>? paymentDetails;
  final List<String>? selectedAddOnsList;

  const ReservationState({
    required this.provider,
    this.selectedReservationType,
    this.selectedService,
    this.selectedDate,
    this.selectedStartTime,
    this.selectedEndTime,
    this.availableSlots = const [],
    this.selectedAttendees = const [],
    this.typeSpecificData,
    this.isFullVenueReservation = false,
    this.reservedCapacity,
    this.isCommunityVisible = false,
    this.hostingCategory,
    this.hostingDescription,
    this.attendeePaymentStatuses = const {},
    this.costSplitDetails,
    this.basePrice = 0.0,
    this.addOnsPrice = 0.0,
    this.totalPrice = 0.0,
    // Initialize newly added fields
    this.notes,
    this.paymentDetails,
    this.selectedAddOnsList,
  });

  @override
  List<Object?> get props => [
        provider, selectedReservationType, selectedService, selectedDate,
        selectedStartTime, selectedEndTime, availableSlots, selectedAttendees,
        typeSpecificData,
        isFullVenueReservation, reservedCapacity,
        isCommunityVisible, hostingCategory, hostingDescription,
        attendeePaymentStatuses,
        costSplitDetails,
        basePrice,
        addOnsPrice,
        totalPrice,
        // Add new fields to props
        notes,
        paymentDetails,
        selectedAddOnsList,
      ];

  AttendeeModel? get bookingUser =>
      selectedAttendees.firstWhereOrNull((a) => a.type == 'self');

  ReservationState copyWith({
    ServiceProviderModel? provider,
    ReservationType? selectedReservationType,
    BookableService? selectedService,
    DateTime? selectedDate,
    TimeOfDay? selectedStartTime,
    TimeOfDay? selectedEndTime,
    List<TimeOfDay>? availableSlots,
    List<AttendeeModel>? selectedAttendees,
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields to copyWith signature
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationInitial(
      provider: provider ?? this.provider!,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationTypeSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationServiceSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      service: selectedService ?? this.selectedService!,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationDateSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      selectedStartTime: selectedStartTime,
      selectedEndTime: selectedEndTime,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.selectedService, // Service can be null for general time-based
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required super.availableSlots,
    required super.selectedAttendees,
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationRangeSelected(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      date: selectedDate ?? this.selectedDate!,
      startTime: selectedStartTime ?? this.selectedStartTime!,
      endTime: selectedEndTime ?? this.selectedEndTime!,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationCreating(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
    );
  }
}

/// Success state (for non-queue based reservations)
class ReservationSuccess extends ReservationState {
  final String message;
  final String? reservationId;

  const ReservationSuccess({
    required this.message,
    this.reservationId,
    required super.provider,
    required super.selectedReservationType,
    super.selectedService,
    required super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    super.availableSlots,
    required super.selectedAttendees,
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
  });

  @override
  List<Object?> get props => super.props..addAll([message, reservationId]);

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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    String? reservationId, // Specific to this state
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationSuccess(
      message: message ?? this.message,
      reservationId: reservationId ?? this.reservationId,
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
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
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
    );
  }
}

// --- Sequence-Based States ---

/// State indicating the user is attempting to join the queue.
class ReservationJoiningQueue extends ReservationState {
  const ReservationJoiningQueue({
    required super.provider,
    required super.selectedReservationType, // Should be sequenceBased
    super.selectedService, // Service can be null if queue is general for provider
    required super.selectedAttendees,
    super.selectedDate, // Date of the queue
    super.selectedStartTime, // Preferred hour
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationJoiningQueue(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
      selectedService: selectedService ?? this.selectedService,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.selectedService,
    required super.selectedAttendees,
    super.selectedDate,
    super.selectedStartTime,
    super.selectedEndTime,
    required this.queuePosition,
    this.estimatedEntryTime,
    super.availableSlots = const [],
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
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
    Map<String, dynamic>? typeSpecificData,
    bool? isLoadingSlots,
    String? message,
    int? queuePosition,
    DateTime? estimatedEntryTime,
    bool? forceEstimatedEntryTimeNull,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, PaymentStatus>? attendeePaymentStatuses,
    Map<String, dynamic>? costSplitDetails,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    // Add new fields
    String? notes,
    Map<String, dynamic>? paymentDetails,
    List<String>? selectedAddOnsList,
  }) {
    return ReservationInQueue(
      provider: provider ?? this.provider,
      selectedReservationType: selectedReservationType ?? this.selectedReservationType,
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
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      isFullVenueReservation: isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      attendeePaymentStatuses: attendeePaymentStatuses ?? this.attendeePaymentStatuses,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      // Pass through new fields
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
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
    super.typeSpecificData,
    super.isFullVenueReservation,
    super.reservedCapacity,
    super.isCommunityVisible,
    super.hostingCategory,
    super.hostingDescription,
    super.attendeePaymentStatuses,
    super.costSplitDetails,
    super.basePrice,
    super.addOnsPrice,
    super.totalPrice,
    // Pass new fields to super
    super.notes,
    super.paymentDetails,
    super.selectedAddOnsList,
  });

  // copyWith is inherited from ReservationError and should handle all fields.
}