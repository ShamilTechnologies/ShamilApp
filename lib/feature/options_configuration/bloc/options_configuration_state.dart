// lib/feature/options_configuration/bloc/options_configuration_state.dart
part of 'options_configuration_bloc.dart'; // Ensures this is part of the BLoC file

class OptionsConfigurationState extends Equatable {
  final String providerId;
  final PlanModel? originalPlan;
  final ServiceModel? originalService;

  final DateTime? selectedDate;
  final String? selectedTime;
  final int groupSize;
  final Map<String, bool> selectedAddOns;
  final String? notes;
  final List<AttendeeModel> selectedAttendees;

  // New properties for social integration
  final List<dynamic> availableFriends;
  final List<FamilyMember> availableFamilyMembers;
  final bool loadingFriends;
  final bool loadingFamilyMembers;

  // Venue booking configuration
  final VenueBookingConfig? venueBookingConfig;

  // Cost splitting configuration
  final CostSplitConfig? costSplitConfig;

  // Calendar integration
  final bool addToCalendar;

  // Payment method
  final String paymentMethod;

  // Reminder settings
  final bool enableReminders;
  final List<int> reminderTimes;

  // Sharing settings
  final bool enableSharing;
  final bool shareWithAttendees;
  final List<String>? additionalEmails;

  // User self-inclusion in booking
  final bool includeUserInBooking;
  final bool payForAllAttendees;

  final double basePrice;
  final double addOnsPrice;
  final double totalPrice;

  final bool isLoading;
  final String? errorMessage;
  final bool canConfirm;

  const OptionsConfigurationState({
    required this.providerId,
    this.originalPlan,
    this.originalService,
    this.selectedDate,
    this.selectedTime,
    this.groupSize = 1,
    this.selectedAddOns = const {},
    this.notes,
    this.selectedAttendees = const [],
    this.availableFriends = const [],
    this.availableFamilyMembers = const [],
    this.loadingFriends = false,
    this.loadingFamilyMembers = false,
    this.venueBookingConfig,
    this.costSplitConfig,
    this.addToCalendar = false,
    this.paymentMethod = 'creditCard', // Default payment method
    this.enableReminders = true, // Default to enabled
    this.reminderTimes = const [60, 1440], // Default to 1h and 24h before
    this.enableSharing = true, // Default to enabled
    this.shareWithAttendees = true, // Default to share with attendees
    this.additionalEmails,
    this.includeUserInBooking = false,
    this.payForAllAttendees = false,
    this.basePrice = 0.0,
    this.addOnsPrice = 0.0,
    this.totalPrice = 0.0,
    this.isLoading = false,
    this.errorMessage,
    this.canConfirm = false,
  });

  Map<String, dynamic>? get optionsDefinition =>
      originalPlan?.optionsDefinition ?? originalService?.optionsDefinition;

  String get itemName => originalPlan?.name ?? originalService?.name ?? 'Item';
  String get itemId => originalPlan?.id ?? originalService?.id ?? '';

  // Validation getters for step completion
  bool get isDateTimeStepComplete {
    if (optionsDefinition?['allowDateSelection'] == true &&
        selectedDate == null) {
      return false;
    }
    if (optionsDefinition?['allowTimeSelection'] == true &&
        (selectedTime == null || selectedTime!.isEmpty)) {
      return false;
    }
    return true;
  }

  bool get isAttendeesStepComplete {
    // At least one person should be attending (user or attendees)
    if (!includeUserInBooking && selectedAttendees.isEmpty) {
      return false;
    }
    return true;
  }

  bool get isPaymentDataValid {
    // Check if payment amount is valid
    if (totalPrice <= 0) {
      return false;
    }

    // Check if attendee configuration is consistent
    if (includeUserInBooking || selectedAttendees.isNotEmpty) {
      return true;
    }

    return false;
  }

  bool get canProceedToPayment {
    return isDateTimeStepComplete &&
        isAttendeesStepComplete &&
        isPaymentDataValid;
  }

  // Enhanced validation for payment-confirmed scenarios
  bool get canConfirmWithPayment {
    // More lenient validation when payment is already processed
    return isAttendeesStepComplete && // At least someone attending
        totalPrice > 0; // Valid payment amount
  }

  // Detailed validation messages
  List<String> get validationErrors {
    final errors = <String>[];

    // Date/Time validation
    if (optionsDefinition?['allowDateSelection'] == true &&
        selectedDate == null) {
      errors.add('Please select a booking date');
    }
    if (optionsDefinition?['allowTimeSelection'] == true &&
        (selectedTime == null || selectedTime!.isEmpty)) {
      errors.add('Please select a booking time');
    }

    // Attendees validation
    if (!includeUserInBooking && selectedAttendees.isEmpty) {
      errors.add(
          'At least one person must attend (include yourself or invite others)');
    }

    // Payment validation
    if (totalPrice <= 0) {
      errors.add('Invalid payment amount calculated');
    }

    return errors;
  }

  // Step-specific validation
  bool isStepValid(int stepIndex) {
    switch (stepIndex) {
      case 0: // Details/Date/Time step
        return isDateTimeStepComplete;
      case 1: // Attendees/Configuration step
        return isAttendeesStepComplete;
      case 2: // Payment step
        return canProceedToPayment;
      default:
        return false;
    }
  }

  String? getStepValidationMessage(int stepIndex) {
    switch (stepIndex) {
      case 0:
        if (!isDateTimeStepComplete) {
          if (optionsDefinition?['allowDateSelection'] == true &&
              selectedDate == null) {
            return 'Please select a booking date';
          }
          if (optionsDefinition?['allowTimeSelection'] == true &&
              (selectedTime == null || selectedTime!.isEmpty)) {
            return 'Please select a booking time';
          }
        }
        return null;
      case 1:
        if (!isAttendeesStepComplete) {
          return 'Please ensure at least one person is attending';
        }
        return null;
      case 2:
        if (!canProceedToPayment) {
          return validationErrors.isNotEmpty
              ? validationErrors.first
              : 'Complete all required fields';
        }
        return null;
      default:
        return null;
    }
  }

  OptionsConfigurationState copyWith({
    String? providerId,
    PlanModel? originalPlan,
    ServiceModel? originalService,
    DateTime? selectedDate,
    String? selectedTime,
    int? groupSize,
    Map<String, bool>? selectedAddOns,
    String? notes,
    List<AttendeeModel>? selectedAttendees,
    List<dynamic>? availableFriends,
    List<FamilyMember>? availableFamilyMembers,
    bool? loadingFriends,
    bool? loadingFamilyMembers,
    VenueBookingConfig? venueBookingConfig,
    CostSplitConfig? costSplitConfig,
    bool? addToCalendar,
    String? paymentMethod,
    bool? enableReminders,
    List<int>? reminderTimes,
    bool? enableSharing,
    bool? shareWithAttendees,
    List<String>? additionalEmails,
    bool? includeUserInBooking,
    bool? payForAllAttendees,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    bool? isLoading,
    String? errorMessage,
    bool? clearErrorMessage,
    bool? canConfirm,
  }) {
    return OptionsConfigurationState(
      providerId: providerId ?? this.providerId,
      originalPlan: originalPlan ?? this.originalPlan,
      originalService: originalService ?? this.originalService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      groupSize: groupSize ?? this.groupSize,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      notes: notes ?? this.notes,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      availableFriends: availableFriends ?? this.availableFriends,
      availableFamilyMembers:
          availableFamilyMembers ?? this.availableFamilyMembers,
      loadingFriends: loadingFriends ?? this.loadingFriends,
      loadingFamilyMembers: loadingFamilyMembers ?? this.loadingFamilyMembers,
      venueBookingConfig: venueBookingConfig ?? this.venueBookingConfig,
      costSplitConfig: costSplitConfig ?? this.costSplitConfig,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      enableSharing: enableSharing ?? this.enableSharing,
      shareWithAttendees: shareWithAttendees ?? this.shareWithAttendees,
      additionalEmails: additionalEmails ?? this.additionalEmails,
      includeUserInBooking: includeUserInBooking ?? this.includeUserInBooking,
      payForAllAttendees: payForAllAttendees ?? this.payForAllAttendees,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: (clearErrorMessage == true)
          ? null
          : (errorMessage ?? this.errorMessage),
      canConfirm: canConfirm ?? this.canConfirm,
    );
  }

  @override
  List<Object?> get props => [
        providerId,
        originalPlan,
        originalService,
        selectedDate,
        selectedTime,
        groupSize,
        selectedAddOns,
        notes,
        selectedAttendees,
        availableFriends,
        availableFamilyMembers,
        loadingFriends,
        loadingFamilyMembers,
        venueBookingConfig,
        costSplitConfig,
        addToCalendar,
        paymentMethod,
        enableReminders,
        reminderTimes,
        enableSharing,
        shareWithAttendees,
        additionalEmails,
        includeUserInBooking,
        payForAllAttendees,
        basePrice,
        addOnsPrice,
        totalPrice,
        isLoading,
        errorMessage,
        canConfirm,
      ];
}

class OptionsConfigurationConfirmed extends OptionsConfigurationState {
  final String confirmationId;

  const OptionsConfigurationConfirmed({
    required super.providerId,
    super.originalPlan,
    super.originalService,
    super.selectedDate,
    super.selectedTime,
    required super.groupSize,
    required super.selectedAddOns,
    super.notes,
    required super.selectedAttendees,
    required super.basePrice,
    required super.addOnsPrice,
    required super.totalPrice,
    required this.confirmationId,
  }) : super(canConfirm: true, isLoading: false);

  @override
  List<Object?> get props => [...super.props, confirmationId];
}

class OptionsConfigurationInitial extends OptionsConfigurationState {
  const OptionsConfigurationInitial()
      : super(
            providerId: '',
            isLoading: true,
            basePrice: 0.0,
            addOnsPrice: 0.0,
            totalPrice: 0.0);
}
