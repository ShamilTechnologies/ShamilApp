// lib/feature/options_configuration/bloc/options_configuration_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/repository/options_configuration_repository.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'
    show OpeningHoursDay;

part 'options_configuration_state.dart';

class OptionsConfigurationBloc
    extends Bloc<OptionsConfigurationEvent, OptionsConfigurationState> {
  final OptionsConfigurationRepository repository;
  Map<String, OpeningHoursDay> operatingHours = {};
  List<ReservationModel> existingReservations = [];
  bool _isLoadingOperatingHours = false;
  bool _isLoadingReservations = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  OptionsConfigurationBloc({required this.repository})
      : super(OptionsConfigurationInitial()) {
    on<InitializeOptionsConfiguration>(_onInitializeOptionsConfiguration);
    on<DateSelected>(_onDateSelected);
    on<TimeSelected>(_onTimeSelected);
    on<QuantityChanged>(_onQuantityChanged);
    on<AddOnToggled>(_onAddOnToggled);
    on<NotesUpdated>(_onNotesUpdated);
    on<AddOptionAttendee>(_onAddOptionAttendee);
    on<RemoveOptionAttendee>(_onRemoveOptionAttendee);
    on<ConfirmConfiguration>(_onConfirmConfiguration);
    on<ClearErrorMessage>(_onClearErrorMessage);
    on<LoadProviderOperatingHours>(_onLoadProviderOperatingHours);
    on<LoadProviderReservations>(_onLoadProviderReservations);
  }

  Future<void> _onInitializeOptionsConfiguration(
    InitializeOptionsConfiguration event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    double initialBasePrice = event.plan?.price ?? event.service?.price ?? 0.0;
    int initialGroupSize = 1;
    final options = event.optionsDefinition;

    if (options != null && options['quantityDetails'] is Map) {
      final qtyDetails = options['quantityDetails'] as Map;
      initialGroupSize = (qtyDetails['default'] as int?) ??
          (qtyDetails['initial'] as int?) ??
          initialGroupSize;
    }

    Map<String, bool> initialSelectedAddOns = {};
    double initialAddOnsPrice = 0;
    if (options != null && options['availableAddOns'] is List) {
      for (var addOnData in (options['availableAddOns'] as List<dynamic>)) {
        if (addOnData is Map<String, dynamic>) {
          final String id = addOnData['id'] as String? ?? '';
          final bool defaultSelected =
              addOnData['defaultSelected'] as bool? ?? false;
          final double price = (addOnData['price'] as num?)?.toDouble() ?? 0.0;
          if (id.isNotEmpty) {
            initialSelectedAddOns[id] = defaultSelected;
            if (defaultSelected) {
              initialAddOnsPrice += price;
            }
          }
        }
      }
    }

    double initialTotalPrice = _calculateTotalPrice(
        basePrice: initialBasePrice,
        groupSize: initialGroupSize,
        addOnsPrice: initialAddOnsPrice,
        selectedAttendees: const [], // Start with no attendees
        options: options);

    emit(OptionsConfigurationState(
      providerId: event.providerId,
      originalPlan: event.plan,
      originalService: event.service,
      basePrice: initialBasePrice,
      groupSize: initialGroupSize,
      totalPrice: initialTotalPrice,
      selectedAddOns: initialSelectedAddOns,
      addOnsPrice: initialAddOnsPrice,
      selectedAttendees: const [],
      isLoading: false,
      canConfirm: _checkCanConfirm(
        options: event.optionsDefinition,
        selectedDate: null,
        selectedTime: null,
        groupSize: initialGroupSize,
        selectedAttendees: const [],
      ),
    ));

    // Load provider data after initializing
    add(LoadProviderOperatingHours(providerId: event.providerId));
    add(LoadProviderReservations(providerId: event.providerId));
  }

  Future<void> _onLoadProviderOperatingHours(
    LoadProviderOperatingHours event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    if (_isLoadingOperatingHours) return;
    _isLoadingOperatingHours = true;
    emit(state.copyWith(isLoading: true));

    try {
      final openingHoursData =
          await repository.fetchProviderOperatingHours(event.providerId);
      final Map<String, OpeningHoursDay> hours = {};

      openingHoursData.forEach((dayKey, dayData) {
        if (dayData is Map<String, dynamic>) {
          try {
            hours[dayKey.toLowerCase()] = OpeningHoursDay.fromMap(dayData);
          } catch (e) {
            hours[dayKey.toLowerCase()] = const OpeningHoursDay(isOpen: false);
          }
        } else {
          hours[dayKey.toLowerCase()] = const OpeningHoursDay(isOpen: false);
        }
      });

      operatingHours = hours;
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading operating hours: ${e.toString()}',
      ));
    } finally {
      _isLoadingOperatingHours = false;
    }
  }

  Future<void> _onLoadProviderReservations(
    LoadProviderReservations event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    if (_isLoadingReservations) return;
    _isLoadingReservations = true;
    emit(state.copyWith(isLoading: true));

    try {
      final reservations =
          await repository.fetchProviderReservations(event.providerId);
      existingReservations = reservations;
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading existing reservations: ${e.toString()}',
      ));
    } finally {
      _isLoadingReservations = false;
    }
  }

  void _onDateSelected(
      DateSelected event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    emit(state.copyWith(
      selectedDate: event.selectedDate,
      selectedTime: null, // Clear time when date changes
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: event.selectedDate,
        selectedTime: null,
        groupSize: state.groupSize,
        selectedAttendees: state.selectedAttendees,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onTimeSelected(
      TimeSelected event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    emit(state.copyWith(
      selectedTime: event.selectedTime,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: event.selectedTime,
        groupSize: state.groupSize,
        selectedAttendees: state.selectedAttendees,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onQuantityChanged(
      QuantityChanged event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    int newGroupSize = event.quantity;
    final qtyDetails =
        state.optionsDefinition?['quantityDetails'] as Map<String, dynamic>?;
    if (qtyDetails != null) {
      final minQty = (qtyDetails['min'] as num?)?.toInt();
      final maxQty = (qtyDetails['max'] as num?)?.toInt();
      if (minQty != null && newGroupSize < minQty) newGroupSize = minQty;
      if (maxQty != null && newGroupSize > maxQty) newGroupSize = maxQty;
    }
    if (newGroupSize < 1) newGroupSize = 1;

    final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: newGroupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: state.selectedAttendees,
        options: state.optionsDefinition);

    emit(state.copyWith(
      groupSize: newGroupSize,
      totalPrice: newTotalPrice,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: newGroupSize,
        selectedAttendees: state.selectedAttendees,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onAddOnToggled(
      AddOnToggled event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    final newSelectedAddOns = Map<String, bool>.from(state.selectedAddOns);
    newSelectedAddOns[event.addOnId] = event.isSelected;

    double newAddOnsPrice = 0;
    final availableAddOns =
        state.optionsDefinition?['availableAddOns'] as List<dynamic>?;
    if (availableAddOns != null) {
      for (var addOnData in availableAddOns) {
        if (addOnData is Map<String, dynamic>) {
          final String id = addOnData['id'] as String? ?? '';
          final double price = (addOnData['price'] as num?)?.toDouble() ?? 0.0;
          if (newSelectedAddOns[id] == true) {
            newAddOnsPrice += price;
          }
        }
      }
    }

    final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: state.groupSize,
        addOnsPrice: newAddOnsPrice,
        selectedAttendees: state.selectedAttendees,
        options: state.optionsDefinition);

    emit(state.copyWith(
      selectedAddOns: newSelectedAddOns,
      addOnsPrice: newAddOnsPrice,
      totalPrice: newTotalPrice,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: state.groupSize,
        selectedAttendees: state.selectedAttendees,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onNotesUpdated(
      NotesUpdated event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    emit(state.copyWith(notes: event.notes));
  }

  void _onAddOptionAttendee(
      AddOptionAttendee event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    final List<AttendeeModel> updatedAttendees =
        List.from(state.selectedAttendees);
    if (!updatedAttendees.any((att) => att.userId == event.attendee.userId)) {
      updatedAttendees.add(event.attendee);
    }

    final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: state.groupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: updatedAttendees,
        options: state.optionsDefinition);

    emit(state.copyWith(
      selectedAttendees: updatedAttendees,
      totalPrice: newTotalPrice,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: state.groupSize,
        selectedAttendees: updatedAttendees,
      ),
    ));
  }

  void _onRemoveOptionAttendee(
      RemoveOptionAttendee event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    final List<AttendeeModel> updatedAttendees =
        List.from(state.selectedAttendees)
          ..removeWhere((att) => att.userId == event.attendeeUserId);

    final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: state.groupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: updatedAttendees,
        options: state.optionsDefinition);

    emit(state.copyWith(
      selectedAttendees: updatedAttendees,
      totalPrice: newTotalPrice,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: state.groupSize,
        selectedAttendees: updatedAttendees,
      ),
    ));
  }

  Future<void> _onConfirmConfiguration(
    ConfirmConfiguration event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    if (state is OptionsConfigurationInitial) {
      emit(state.copyWith(errorMessage: "Configuration not initialized."));
      return;
    }

    if (!_checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: state.groupSize,
        selectedAttendees: state.selectedAttendees)) {
      emit(state.copyWith(
          errorMessage: "Please complete all required options."));
      return;
    }

    // Set loading state
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("You must be logged in to proceed");
      }

      String confirmationId;

      // Process submission based on whether it's a service or plan
      if (state.originalService != null) {
        // Create reservation model
        final reservation = _createReservationFromState(state, currentUser);
        confirmationId = await repository.submitReservation(reservation);
      } else if (state.originalPlan != null) {
        // Create subscription model
        final subscription = _createSubscriptionFromState(state, currentUser);
        confirmationId = await repository.submitSubscription(subscription);
      } else {
        throw Exception("No service or plan to configure");
      }

      // Emit success state
      emit(OptionsConfigurationConfirmed(
        providerId: state.providerId,
        originalPlan: state.originalPlan,
        originalService: state.originalService,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: state.groupSize,
        selectedAddOns: state.selectedAddOns,
        notes: state.notes,
        selectedAttendees: state.selectedAttendees,
        basePrice: state.basePrice,
        addOnsPrice: state.addOnsPrice,
        totalPrice: state.totalPrice,
        confirmationId: confirmationId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "Failed to submit configuration: ${e.toString()}",
      ));
    }
  }

  ReservationModel _createReservationFromState(
      OptionsConfigurationState state, User currentUser) {
    // Parse time string to TimeOfDay
    final timeParts = state.selectedTime?.split(':') ?? ['0', '0'];
    final hours = int.tryParse(timeParts[0]) ?? 0;
    final minutes = int.tryParse(timeParts[1]) ?? 0;

    // Combine date and time
    final dateTime = state.selectedDate != null
        ? DateTime(
            state.selectedDate!.year,
            state.selectedDate!.month,
            state.selectedDate!.day,
            hours,
            minutes,
          )
        : DateTime.now().add(const Duration(days: 1));

    // Duration in minutes from service
    final durationMinutes = state.originalService?.estimatedDurationMinutes ??
        (state.optionsDefinition?['defaultDurationMinutes'] as int?) ??
        60;

    // Get addons list from selected addons map
    final selectedAddOnsList = state.selectedAddOns.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Determine reservation type based on service or options
    ReservationType reservationType = ReservationType.timeBased;
    if (state.optionsDefinition?['reservationType'] != null) {
      final typeString = state.optionsDefinition?['reservationType'] as String?;
      reservationType = reservationTypeFromString(typeString);
    }

    // Create reservation model
    return ReservationModel(
      id: '', // Will be assigned by Firestore
      providerId: state.providerId,
      serviceId: state.originalService?.id ?? '',
      serviceName: state.originalService?.name ?? 'Service Reservation',
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'User',
      governorateId: '', // Will be filled by backend or through repository
      status: ReservationStatus.pending,
      type: reservationType,
      notes: state.notes,
      groupSize: state.groupSize,
      attendees: state.selectedAttendees,
      reservationStartTime: Timestamp.fromDate(dateTime),
      durationMinutes: durationMinutes,
      createdAt: Timestamp.now(),
      totalPrice: state.totalPrice,
      selectedAddOnsList: selectedAddOnsList,
      // Additional fields to fulfill model requirements
      reservationCode: '', // Will be generated on the server
    );
  }

  SubscriptionModel _createSubscriptionFromState(
      OptionsConfigurationState state, User currentUser) {
    // Determine start date - either selected date or today
    final startDate = state.selectedDate ?? DateTime.now();
    final expiryDate = DateTime(
      startDate.year + 1, // Default to 1 year from start
      startDate.month,
      startDate.day,
    );

    // Get addons list from selected addons map
    final selectedAddOnsList = state.selectedAddOns.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Create subscription model
    return SubscriptionModel(
      id: '', // Will be assigned by Firestore
      providerId: state.providerId,
      planId: state.originalPlan?.id ?? '',
      planName: state.originalPlan?.name ?? 'Subscription Plan',
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'User',
      status: SubscriptionStatus.active.statusString,
      pricePaid: state.totalPrice,
      notes: state.notes,
      groupSize: state.groupSize,
      subscribers: state.selectedAttendees.map((a) => a.toMap()).toList(),
      startDate: Timestamp.fromDate(startDate),
      expiryDate: Timestamp.fromDate(expiryDate),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      billingCycle: state.originalPlan?.billingCycle ?? 'monthly',
      selectedAddOns: selectedAddOnsList,
    );
  }

  void _onClearErrorMessage(
      ClearErrorMessage event, Emitter<OptionsConfigurationState> emit) {
    if (state is OptionsConfigurationInitial) return;
    emit(state.copyWith(clearErrorMessage: true));
  }

  double _calculateTotalPrice(
      {required double basePrice,
      required int groupSize,
      required double addOnsPrice,
      required List<AttendeeModel> selectedAttendees,
      required Map<String, dynamic>? options}) {
    double price = (basePrice * groupSize) + addOnsPrice;
    // Price per attendee logic (if defined in optionsDefinition)
    final attendeeDetails =
        options?['attendeeDetails'] as Map<String, dynamic>?;
    final pricePerAttendee =
        (attendeeDetails?['pricePerAttendee'] as num?)?.toDouble();
    if (pricePerAttendee != null && pricePerAttendee > 0) {
      // Only add per-attendee price if groupSize is 1 (base price is per item/service, not per person)
      // OR if the basePrice itself is already per person (this needs clear definition in options).
      // For now, let's assume basePrice is for the item, and attendees are extra.
      // This might need adjustment based on how `basePrice` is meant to be interpreted with attendees.
      if (groupSize == 1 && selectedAttendees.isNotEmpty) {
        price += pricePerAttendee * selectedAttendees.length;
      } else if (groupSize > 1 && selectedAttendees.length > groupSize) {
        // If groupSize is e.g. 2 rooms, and 3 attendees, charge for the extra attendee
        price += pricePerAttendee * (selectedAttendees.length - groupSize);
      }
      // If basePrice is per person, then it should be basePrice * selectedAttendees.length (or groupSize, whichever is primary unit)
    }
    return price;
  }

  bool _checkCanConfirm({
    required Map<String, dynamic>? options,
    required DateTime? selectedDate,
    required String? selectedTime,
    required int groupSize,
    required List<AttendeeModel> selectedAttendees,
  }) {
    if (options == null) return true;

    bool dateRequirementMet = true;
    if (options['allowDateSelection'] == true) {
      dateRequirementMet = selectedDate != null;
    }

    bool timeRequirementMet = true;
    if (options['allowTimeSelection'] == true && dateRequirementMet) {
      // Time is only relevant if date is also selected or required
      timeRequirementMet = selectedTime != null && selectedTime.isNotEmpty;
    } else if (options['allowTimeSelection'] == true &&
        options['allowDateSelection'] != true) {
      timeRequirementMet = selectedTime != null && selectedTime.isNotEmpty;
    }

    bool groupSizeRequirementMet = true;
    if (options['allowQuantitySelection'] == true) {
      final qtyDetails = options['quantityDetails'] as Map<String, dynamic>?;
      final minQty = (qtyDetails?['min'] as num?)?.toInt() ?? 1;
      final maxQty = (qtyDetails?['max'] as num?)?.toInt();
      if (groupSize < minQty) groupSizeRequirementMet = false;
      if (maxQty != null && groupSize > maxQty) groupSizeRequirementMet = false;
    }

    bool attendeeRequirementMet = true;
    if (options['allowAttendeeSelection'] == true) {
      final attendeeDetails =
          options['attendeeDetails'] as Map<String, dynamic>?;
      final minAttendees = (attendeeDetails?['min'] as num?)?.toInt() ?? 0;
      final maxAttendees = (attendeeDetails?['max'] as num?)?.toInt();

      if (selectedAttendees.length < minAttendees)
        attendeeRequirementMet = false;
      if (maxAttendees != null && selectedAttendees.length > maxAttendees)
        attendeeRequirementMet = false;

      // If groupSize represents people and attendees are also selected, ensure they are consistent
      // This logic depends on how 'groupSize' and 'attendees' are used together.
      // For example, if 'groupSize' is "number of tickets", then 'selectedAttendees' should match 'groupSize'.
      final qtyIsPeople = (options['quantityDetails']?['label'] as String?)
              ?.toLowerCase()
              .contains('people') ??
          false;
      if (qtyIsPeople &&
          options['allowQuantitySelection'] == true &&
          selectedAttendees.isNotEmpty &&
          selectedAttendees.length != groupSize) {
        // If groupSize means people, and attendees are also being selected, they should match
        // This is a complex case and might need a specific validation error message.
        // For now, just making it a factor.
        // attendeeRequirementMet = false; // Uncomment if strict matching is required
      }
    }

    return dateRequirementMet &&
        timeRequirementMet &&
        groupSizeRequirementMet &&
        attendeeRequirementMet;
  }

  // Helper methods to expose operating hours and reservations to the UI
  Map<String, OpeningHoursDay> getOperatingHours() => operatingHours;
  List<ReservationModel> getExistingReservations() => existingReservations;
  bool isLoadingOperatingHours() => _isLoadingOperatingHours;
  bool isLoadingReservations() => _isLoadingReservations;
}
