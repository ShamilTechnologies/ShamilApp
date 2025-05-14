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
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as Math;
import 'package:shamil_mobile_app/feature/reservation/services/calendar_integration_service.dart';
import 'package:shamil_mobile_app/feature/reservation/services/email_template_service.dart';
import 'package:shamil_mobile_app/feature/reservation/services/notification_service.dart';

part 'options_configuration_state.dart';

class OptionsConfigurationBloc
    extends Bloc<OptionsConfigurationEvent, OptionsConfigurationState> {
  final OptionsConfigurationRepository repository;
  Map<String, OpeningHoursDay> operatingHours = {};
  List<ReservationModel> existingReservations = [];
  bool _isLoadingOperatingHours = false;
  bool _isLoadingReservations = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = Uuid();
  final CalendarIntegrationService _calendarService =
      CalendarIntegrationService();

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
    on<LoadCurrentUserFriends>(_onLoadCurrentUserFriends);
    on<LoadCurrentUserFamilyMembers>(_onLoadCurrentUserFamilyMembers);
    on<AddFriendAsAttendee>(_onAddFriendAsAttendee);
    on<AddFamilyMemberAsAttendee>(_onAddFamilyMemberAsAttendee);
    on<AddExternalAttendee>(_onAddExternalAttendee);
    on<ChangeVenueBookingType>(_onChangeVenueBookingType);
    on<UpdateSelectedCapacity>(_onUpdateSelectedCapacity);
    on<UpdateVenueIsPrivate>(_onUpdateVenueIsPrivate);
    on<ChangeCostSplitType>(_onChangeCostSplitType);
    on<UpdateHostPaying>(_onUpdateHostPaying);
    on<UpdateCustomCostSplit>(_onUpdateCustomCostSplit);
    on<ToggleAddToCalendar>(_onToggleAddToCalendar);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<UpdateReminderSettings>(_onUpdateReminderSettings);
    on<UpdateSharingSettings>(_onUpdateSharingSettings);
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
    AddOptionAttendee event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state is OptionsConfigurationInitial) return;
    // Check if attendee already exists
    bool alreadyExists = state.selectedAttendees
        .any((att) => att.userId == event.attendee.userId);
    if (alreadyExists) {
      emit(state.copyWith(
        errorMessage: 'This attendee has already been added',
      ));
      return;
    }

    // Check venue capacity if venue booking is enabled
    if (state.venueBookingConfig != null) {
      final venueConfig = state.venueBookingConfig!;
      final int currentAttendeeCount = state.selectedAttendees.length;

      // For full venue booking
      if (venueConfig.type == VenueBookingType.fullVenue) {
        // Check if adding an attendee would exceed max capacity
        if (currentAttendeeCount + 1 > venueConfig.maxCapacity) {
          emit(state.copyWith(
            errorMessage:
                'Maximum venue capacity reached (${venueConfig.maxCapacity} people)',
          ));
          return;
        }
      }
      // For partial capacity booking
      else if (venueConfig.type == VenueBookingType.partialCapacity &&
          venueConfig.selectedCapacity != null) {
        // Check if adding an attendee would exceed selected capacity
        if (currentAttendeeCount + 1 > venueConfig.selectedCapacity!) {
          emit(state.copyWith(
            errorMessage:
                'Selected capacity reached (${venueConfig.selectedCapacity} people)',
          ));
          return;
        }
      }
    }

    // Always add the attendee to the list
    List<AttendeeModel> newAttendees = List.from(state.selectedAttendees);
    newAttendees.add(event.attendee);

    // Create attendee config for venue booking
    final attendeeConfig = AttendeeConfig.fromAttendeeModel(event.attendee);

    // Add to venue booking if it exists
    VenueBookingConfig? updatedVenueConfig;
    if (state.venueBookingConfig != null) {
      try {
        updatedVenueConfig =
            state.venueBookingConfig!.addAttendee(attendeeConfig);
      } catch (e) {
        emit(state.copyWith(
          errorMessage: e.toString(),
        ));
        return;
      }
    }

    // Always adjust groupSize to match attendee count - this is key for counting people
    final int newGroupSize = newAttendees.length;

    // Calculate new price with the updated groupSize
    final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: newGroupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: newAttendees,
        options: state.optionsDefinition);

    // Update cost splits if necessary
    CostSplitConfig? updatedCostSplit;
    if (state.costSplitConfig != null) {
      final attendeeConfigs = updatedVenueConfig?.attendees ?? [];

      if (attendeeConfigs.isNotEmpty) {
        updatedCostSplit = state.costSplitConfig!;
        // Recalculate splits if needed
        if (updatedCostSplit.type != CostSplitType.splitCustom) {
          // For automatic splits, recalculate
          final attendeesWithAmounts =
              updatedCostSplit.applyCostSharesToAttendees(attendeeConfigs);
          updatedVenueConfig =
              updatedVenueConfig!.copyWith(attendees: attendeesWithAmounts);
        }
      }
    }

    emit(state.copyWith(
      selectedAttendees: newAttendees,
      groupSize: newGroupSize,
      totalPrice: newTotalPrice,
      venueBookingConfig: updatedVenueConfig,
      costSplitConfig: updatedCostSplit,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        groupSize: newGroupSize,
        selectedAttendees: newAttendees,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onRemoveOptionAttendee(
    RemoveOptionAttendee event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    try {
      // Remove attendee from list
      final updatedAttendees = state.selectedAttendees
          .where((attendee) => attendee.userId != event.attendeeUserId)
          .toList();

      // Also remove from venue booking if it exists
      VenueBookingConfig? updatedVenueConfig;
      if (state.venueBookingConfig != null) {
        updatedVenueConfig =
            state.venueBookingConfig!.removeAttendee(event.attendeeUserId);
      }

      // Update cost splits if needed
      CostSplitConfig? updatedCostSplit;
      if (state.costSplitConfig != null &&
          state.costSplitConfig!.type == CostSplitType.splitCustom) {
        // Remove this attendee from custom splits
        final customSplits = state.costSplitConfig!.customSplits;
        if (customSplits != null &&
            customSplits.containsKey(event.attendeeUserId)) {
          final updatedSplits = Map<String, double>.from(customSplits);
          updatedSplits.remove(event.attendeeUserId);
          updatedCostSplit =
              state.costSplitConfig!.copyWith(customSplits: updatedSplits);
        }
      }

      // Update group size to match attendee count - this ensures price and capacity tracking
      final newGroupSize = updatedAttendees.length;

      // Calculate new price with the updated groupSize
      final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: newGroupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: updatedAttendees,
        options: state.optionsDefinition,
      );

      emit(state.copyWith(
        selectedAttendees: updatedAttendees,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        venueBookingConfig: updatedVenueConfig,
        costSplitConfig: updatedCostSplit,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: updatedAttendees,
        ),
        clearErrorMessage: true,
      ));

      // Recalculate costs for remaining attendees
      if (state.costSplitConfig != null &&
          updatedVenueConfig != null &&
          state.costSplitConfig!.type != CostSplitType.splitCustom) {
        add(ChangeCostSplitType(splitType: state.costSplitConfig!.type));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error removing attendee: $e',
      ));
    }
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
      ReservationModel? newReservation;

      // Process submission based on whether it's a service or plan
      if (state.originalService != null) {
        // Create reservation model
        final reservation = _createReservationFromState(state, currentUser);
        newReservation = reservation;
        confirmationId = await repository.submitReservation(reservation);

        // Add to calendar if enabled
        if (state.addToCalendar && state.selectedDate != null) {
          await _addToCalendar(reservation);
        }

        // Handle sharing if enabled
        if (state.enableSharing) {
          await _handleBookingSharing(reservation);
        }

        // Schedule reminders if enabled
        if (state.enableReminders && state.reminderTimes.isNotEmpty) {
          await _scheduleReminders(reservation, state.reminderTimes);
        }
      } else if (state.originalPlan != null) {
        // Create subscription model
        final subscription = _createSubscriptionFromState(state, currentUser);
        confirmationId = await repository.submitSubscription(subscription);

        // Handle subscription-specific actions
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

  // Handle sharing the booking details via email
  Future<void> _handleBookingSharing(ReservationModel reservation) async {
    try {
      // Get provider name
      final providerData =
          await repository.getProviderDetails(reservation.providerId);
      final providerName =
          providerData?['name'] as String? ?? 'Service Provider';

      // Generate email HTML content
      final emailHtml = EmailTemplateService.generateBookingConfirmationEmail(
        reservation: reservation,
        providerName: providerName,
      );

      // Collect email recipients
      List<String> recipients = [];

      // Add host's email if available
      if (reservation.userId.isNotEmpty) {
        final userEmail = await repository.getUserEmail(reservation.userId);
        if (userEmail != null && userEmail.isNotEmpty) {
          recipients.add(userEmail);
        }
      }

      // Add attendee emails if shareWithAttendees is true
      if (state.shareWithAttendees) {
        for (var attendee in reservation.attendees) {
          if (attendee.userId != reservation.userId) {
            // Skip host
            final attendeeEmail =
                await repository.getUserEmail(attendee.userId);
            if (attendeeEmail != null && attendeeEmail.isNotEmpty) {
              recipients.add(attendeeEmail);
            }
          }
        }
      }

      // Add additional emails if any
      if (state.additionalEmails != null) {
        recipients.addAll(state.additionalEmails!);
      }

      // Send confirmation emails
      if (recipients.isNotEmpty) {
        await repository.sendBookingConfirmationEmails(
          recipients: recipients,
          subject: "Booking Confirmation: ${reservation.serviceName}",
          htmlContent: emailHtml,
        );
      }
    } catch (e) {
      print('Error sharing booking details: $e');
      // Don't throw - we don't want sharing errors to block the reservation process
    }
  }

  // Schedule reminders for the booking
  Future<void> _scheduleReminders(
      ReservationModel reservation, List<int> reminderTimes) async {
    try {
      // Sort reminder times in ascending order
      final sortedReminderTimes = List<int>.from(reminderTimes)..sort();

      // Get provider name
      final providerData =
          await repository.getProviderDetails(reservation.providerId);
      final providerName =
          providerData?['name'] as String? ?? 'Service Provider';

      // Initialize notification service for local device reminders
      final notificationService = NotificationService();
      bool localNotificationsEnabled =
          await notificationService.checkPermissions();
      if (!localNotificationsEnabled) {
        localNotificationsEnabled =
            await notificationService.requestPermissions();
      }

      // Schedule each reminder
      for (final minutes in sortedReminderTimes) {
        // Generate reminder email content
        final emailHtml = EmailTemplateService.generateReminderEmail(
          reservation: reservation,
          providerName: providerName,
          minutesBeforeEvent: minutes,
        );

        // Get host's email
        String? userEmail;
        if (reservation.userId.isNotEmpty) {
          userEmail = await repository.getUserEmail(reservation.userId);
        }

        if (userEmail != null && userEmail.isNotEmpty) {
          // Calculate when to send the reminder
          final DateTime? eventTime =
              reservation.reservationStartTime?.toDate();
          if (eventTime != null) {
            final reminderTime = eventTime.subtract(Duration(minutes: minutes));

            // Only schedule if reminder time is in the future
            if (reminderTime.isAfter(DateTime.now())) {
              // Schedule email reminder
              await repository.scheduleReminderEmail(
                recipient: userEmail,
                subject:
                    "Reminder: Your Booking for ${reservation.serviceName}",
                htmlContent: emailHtml,
                sendTime: reminderTime,
              );

              // Also schedule local notification on the device if permissions granted
              if (localNotificationsEnabled) {
                await notificationService.scheduleReminderNotification(
                  reservation: reservation,
                  providerName: providerName,
                  minutesBeforeEvent: minutes,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error scheduling reminders: $e');
      // Don't throw - we don't want reminder errors to block the reservation process
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

    // Build attendees list ensuring current user is included
    List<AttendeeModel> finalAttendees = [...state.selectedAttendees];

    // Make sure at least one attendee is marked as host
    bool hasHost = finalAttendees.any((att) => att.isHost == true);
    if (!hasHost && finalAttendees.isNotEmpty) {
      // Make the first user the host
      var firstAttendee = finalAttendees.first;
      finalAttendees = [
        AttendeeModel(
          userId: firstAttendee.userId,
          name: firstAttendee.name,
          type: firstAttendee.type,
          status: firstAttendee.status,
          paymentStatus: firstAttendee.paymentStatus,
          amountToPay: firstAttendee.amountToPay,
          amountPaid: firstAttendee.amountPaid,
          isHost: true, // Set as host
        ),
        ...finalAttendees.skip(1)
      ];
    }

    // Prepare venue booking details if available
    Map<String, dynamic>? venueBookingDetails;
    if (state.venueBookingConfig != null) {
      venueBookingDetails = {
        'type': state.venueBookingConfig!.type.toString(),
        'isPrivate': state.venueBookingConfig!.isPrivateEvent,
        'selectedCapacity': state.venueBookingConfig!.selectedCapacity,
        'maxCapacity': state.venueBookingConfig!.maxCapacity,
      };
    }

    // Prepare cost split details if available
    Map<String, dynamic>? costSplitDetails;
    if (state.costSplitConfig != null) {
      costSplitDetails = {
        'type': state.costSplitConfig!.type.toString(),
        'hostPaying': state.costSplitConfig!.isHostPaying,
        'customSplits': state.costSplitConfig!.customSplits,
      };
    }

    // Create payment details including the selected payment method
    Map<String, dynamic> paymentDetails = {
      'method': state.paymentMethod,
      'status': PaymentStatus.pending.name, // Start with pending status
    };

    // Create reservation
    return ReservationModel(
      id: Uuid().v4(),
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'User',
      providerId: state.providerId,
      governorateId: '', // Will be filled by backend
      type: ReservationType.serviceBased,
      groupSize: state.groupSize,
      serviceId: state.originalService?.id,
      serviceName: state.originalService?.name,
      durationMinutes: durationMinutes,
      reservationStartTime: Timestamp.fromDate(dateTime),
      status: ReservationStatus.pending,
      paymentStatus: PaymentStatus.pending.name, // Use string representation
      paymentDetails: paymentDetails,
      notes: state.notes,
      attendees: finalAttendees,
      createdAt: Timestamp.now(),
      totalPrice: state.totalPrice,
      selectedAddOnsList: state.selectedAddOns.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList(),
      // Add venue booking settings
      isFullVenueReservation: state.venueBookingConfig?.type.toString() ==
          'VenueBookingType.fullVenue',
      reservedCapacity: state.venueBookingConfig?.selectedCapacity,
      isCommunityVisible: false, // Default to private
      typeSpecificData: {
        'venueBookingDetails': venueBookingDetails,
        'costSplitDetails': costSplitDetails,
        'addToCalendar': state.addToCalendar,
      },
      // Include cost split details if available
      costSplitDetails: costSplitDetails,
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
    // Determine effective person count - prioritize actual attendees
    int effectivePersonCount =
        selectedAttendees.isEmpty ? groupSize : selectedAttendees.length;

    // Base calculation: (base price * person count) + add-ons
    double price = (basePrice * effectivePersonCount) + addOnsPrice;

    // If venue booking is configured, respect venue pricing logic
    if (options?['allowVenueBooking'] == true &&
        state.venueBookingConfig != null) {
      VenueBookingConfig venueConfig = state.venueBookingConfig!;

      // For full venue booking, use the full venue price
      if (venueConfig.type == VenueBookingType.fullVenue) {
        // If a specific full venue price exists, use it
        price = venueConfig.price + addOnsPrice;
      }
      // For partial capacity, calculate based on selected capacity
      else if (venueConfig.type == VenueBookingType.partialCapacity &&
          venueConfig.selectedCapacity != null) {
        // If per-person pricing is available, use it
        if (venueConfig.pricePerPerson != null) {
          double capacityPrice =
              effectivePersonCount * venueConfig.pricePerPerson!;
          // Apply minimum price if specified
          if (venueConfig.minCapacityPrice != null &&
              capacityPrice < venueConfig.minCapacityPrice!) {
            capacityPrice = venueConfig.minCapacityPrice!;
          }
          price = capacityPrice + addOnsPrice;
        } else {
          // Otherwise use the base calculation with effectivePersonCount
          price = (basePrice * effectivePersonCount) + addOnsPrice;
        }
      }
    }
    // Standard price calculation
    else {
      // Price per attendee logic (if defined in optionsDefinition)
      final attendeeDetails =
          options?['attendeeDetails'] as Map<String, dynamic>?;
      final pricePerAttendee =
          (attendeeDetails?['pricePerAttendee'] as num?)?.toDouble();

      if (pricePerAttendee != null && pricePerAttendee > 0) {
        // Base price calculation if attendees are the primary unit of count
        if (selectedAttendees.isNotEmpty) {
          price = (basePrice * effectivePersonCount) + addOnsPrice;
        }
      }
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

      if (selectedAttendees.length < minAttendees) {
        attendeeRequirementMet = false;
      }
      if (maxAttendees != null && selectedAttendees.length > maxAttendees) {
        attendeeRequirementMet = false;
      }

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

  Future<void> _onLoadCurrentUserFriends(
    LoadCurrentUserFriends event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(loadingFriends: true, clearErrorMessage: true));
      final friends = await repository.fetchCurrentUserFriends();
      emit(state.copyWith(
        availableFriends: friends,
        loadingFriends: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error loading friends: $e',
        loadingFriends: false,
      ));
    }
  }

  Future<void> _onLoadCurrentUserFamilyMembers(
    LoadCurrentUserFamilyMembers event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(loadingFamilyMembers: true, clearErrorMessage: true));
      final familyMembers = await repository.fetchCurrentUserFamilyMembers();
      emit(state.copyWith(
        availableFamilyMembers: familyMembers,
        loadingFamilyMembers: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error loading family members: $e',
        loadingFamilyMembers: false,
      ));
    }
  }

  Future<void> _onAddFriendAsAttendee(
    AddFriendAsAttendee event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      final attendeeConfig = AttendeeConfig.fromFriend(event.friend);

      // Add to venue booking if it exists
      VenueBookingConfig? updatedVenueConfig;
      if (state.venueBookingConfig != null) {
        try {
          updatedVenueConfig =
              state.venueBookingConfig!.addAttendee(attendeeConfig);
        } catch (e) {
          emit(state.copyWith(
            errorMessage: e.toString(),
          ));
          return;
        }
      }

      // Create AttendeeModel for the selectedAttendees list
      final AttendeeModel attendeeModel = attendeeConfig.toAttendeeModel();
      final List<AttendeeModel> updatedAttendees =
          List.from(state.selectedAttendees)..add(attendeeModel);

      // Always update group size to match attendee count
      final newGroupSize = updatedAttendees.length;

      // Calculate new price with updated group size
      final newTotalPrice = _calculateTotalPrice(
          basePrice: state.basePrice,
          groupSize: newGroupSize,
          addOnsPrice: state.addOnsPrice,
          selectedAttendees: updatedAttendees,
          options: state.optionsDefinition);

      // Update cost splits if necessary
      CostSplitConfig? updatedCostSplit;
      if (state.costSplitConfig != null) {
        final attendeeConfigs = updatedVenueConfig?.attendees ??
            []; // If no venue config, we don't have attendeeConfigs to recalculate

        if (attendeeConfigs.isNotEmpty) {
          updatedCostSplit = state.costSplitConfig!;
          // Recalculate splits if needed
          if (updatedCostSplit.type != CostSplitType.splitCustom) {
            // For automatic splits, recalculate
            final attendeesWithAmounts =
                updatedCostSplit.applyCostSharesToAttendees(attendeeConfigs);
            updatedVenueConfig =
                updatedVenueConfig!.copyWith(attendees: attendeesWithAmounts);
          }
        }
      }

      emit(state.copyWith(
        selectedAttendees: updatedAttendees,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        venueBookingConfig: updatedVenueConfig,
        costSplitConfig: updatedCostSplit,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: updatedAttendees,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error adding friend as attendee: $e',
      ));
    }
  }

  Future<void> _onAddFamilyMemberAsAttendee(
    AddFamilyMemberAsAttendee event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      final attendeeConfig =
          AttendeeConfig.fromFamilyMember(event.familyMember);

      // Add to venue booking if it exists
      VenueBookingConfig? updatedVenueConfig;
      if (state.venueBookingConfig != null) {
        try {
          updatedVenueConfig =
              state.venueBookingConfig!.addAttendee(attendeeConfig);
        } catch (e) {
          emit(state.copyWith(
            errorMessage: e.toString(),
          ));
          return;
        }
      }

      // Create AttendeeModel for the selectedAttendees list
      final AttendeeModel attendeeModel = attendeeConfig.toAttendeeModel();
      final List<AttendeeModel> updatedAttendees =
          List.from(state.selectedAttendees)..add(attendeeModel);

      // Always update group size to match attendee count
      final newGroupSize = updatedAttendees.length;

      // Calculate new price with updated group size
      final newTotalPrice = _calculateTotalPrice(
          basePrice: state.basePrice,
          groupSize: newGroupSize,
          addOnsPrice: state.addOnsPrice,
          selectedAttendees: updatedAttendees,
          options: state.optionsDefinition);

      // Update cost splits if necessary
      CostSplitConfig? updatedCostSplit;
      if (state.costSplitConfig != null) {
        final attendeeConfigs = updatedVenueConfig?.attendees ??
            []; // If no venue config, we don't have attendeeConfigs to recalculate

        if (attendeeConfigs.isNotEmpty) {
          updatedCostSplit = state.costSplitConfig!;
          // Recalculate splits if needed
          if (updatedCostSplit.type != CostSplitType.splitCustom) {
            // For automatic splits, recalculate
            final attendeesWithAmounts =
                updatedCostSplit.applyCostSharesToAttendees(attendeeConfigs);
            updatedVenueConfig =
                updatedVenueConfig!.copyWith(attendees: attendeesWithAmounts);
          }
        }
      }

      emit(state.copyWith(
        selectedAttendees: updatedAttendees,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        venueBookingConfig: updatedVenueConfig,
        costSplitConfig: updatedCostSplit,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: updatedAttendees,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error adding family member as attendee: $e',
      ));
    }
  }

  Future<void> _onAddExternalAttendee(
    AddExternalAttendee event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Generate a temporary ID for this external attendee
      final tempId = _uuid.v4();

      final attendeeConfig = AttendeeConfig(
        id: tempId,
        name: event.name,
        type: AttendeeType.external,
        profilePictureUrl: null,
        paymentStatus: PaymentStatus.pending,
        amountOwed: 0.0,
        relationship: event.relationship,
      );

      // Add to venue booking if it exists
      VenueBookingConfig? updatedVenueConfig;
      if (state.venueBookingConfig != null) {
        try {
          updatedVenueConfig =
              state.venueBookingConfig!.addAttendee(attendeeConfig);
        } catch (e) {
          emit(state.copyWith(
            errorMessage: e.toString(),
          ));
          return;
        }
      }

      // Create AttendeeModel for the selectedAttendees list
      final attendeeModel = AttendeeModel(
        userId: tempId,
        name: event.name,
        type: 'guest',
        status: 'invited',
      );

      final List<AttendeeModel> updatedAttendees =
          List.from(state.selectedAttendees)..add(attendeeModel);

      // Always update group size to match attendee count
      final newGroupSize = updatedAttendees.length;

      // Calculate new price with updated group size
      final newTotalPrice = _calculateTotalPrice(
          basePrice: state.basePrice,
          groupSize: newGroupSize,
          addOnsPrice: state.addOnsPrice,
          selectedAttendees: updatedAttendees,
          options: state.optionsDefinition);

      // Update cost splits if necessary
      CostSplitConfig? updatedCostSplit;
      if (state.costSplitConfig != null) {
        final attendeeConfigs = updatedVenueConfig?.attendees ??
            []; // If no venue config, we don't have attendeeConfigs to recalculate

        if (attendeeConfigs.isNotEmpty) {
          updatedCostSplit = state.costSplitConfig!;
          // Recalculate splits if needed
          if (updatedCostSplit.type != CostSplitType.splitCustom) {
            // For automatic splits, recalculate
            final attendeesWithAmounts =
                updatedCostSplit.applyCostSharesToAttendees(attendeeConfigs);
            updatedVenueConfig =
                updatedVenueConfig!.copyWith(attendees: attendeesWithAmounts);
          }
        }
      }

      emit(state.copyWith(
        selectedAttendees: updatedAttendees,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        venueBookingConfig: updatedVenueConfig,
        costSplitConfig: updatedCostSplit,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: updatedAttendees,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error adding external attendee: $e',
      ));
    }
  }

  Future<void> _onChangeVenueBookingType(
    ChangeVenueBookingType event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Ensure venue booking config exists
      if (state.venueBookingConfig == null) {
        emit(state.copyWith(
          errorMessage: 'Venue booking configuration not initialized',
        ));
        return;
      }

      // Update booking type
      VenueBookingConfig updatedConfig =
          state.venueBookingConfig!.copyWith(type: event.bookingType);

      // When switching to full venue, set groupSize to maxCapacity
      int newGroupSize = state.groupSize;
      if (event.bookingType == VenueBookingType.fullVenue) {
        newGroupSize = updatedConfig.maxCapacity;
      }
      // When switching to partial capacity, set groupSize to selectedCapacity if available
      else if (event.bookingType == VenueBookingType.partialCapacity) {
        // If switching to partial capacity, set a default
        if (updatedConfig.selectedCapacity == null) {
          // Set a default capacity value (minimum group size or 2)
          final defaultCapacity = Math.max(state.groupSize, 2);
          updatedConfig = updatedConfig.copyWith(
            selectedCapacity: defaultCapacity,
          );
          newGroupSize = defaultCapacity;
        } else {
          newGroupSize = updatedConfig.selectedCapacity!;
        }
      }

      // Calculate new price with the updated groupSize
      final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: newGroupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: state.selectedAttendees,
        options: state.optionsDefinition,
      );

      emit(state.copyWith(
        venueBookingConfig: updatedConfig,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: state.selectedAttendees,
        ),
      ));

      // Recalculate cost splits if necessary
      if (state.costSplitConfig != null) {
        add(ChangeCostSplitType(splitType: state.costSplitConfig!.type));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error changing venue booking type: $e',
      ));
    }
  }

  Future<void> _onUpdateSelectedCapacity(
    UpdateSelectedCapacity event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Ensure venue booking config exists
      if (state.venueBookingConfig == null) {
        emit(state.copyWith(
          errorMessage: 'Venue booking configuration not initialized',
        ));
        return;
      }

      // Ensure we're in partial capacity mode
      if (state.venueBookingConfig!.type != VenueBookingType.partialCapacity) {
        emit(state.copyWith(
          errorMessage: 'Can only update capacity in partial capacity mode',
        ));
        return;
      }

      // Check if requested capacity is valid
      if (event.capacity <= 0 ||
          event.capacity > state.venueBookingConfig!.maxCapacity) {
        emit(state.copyWith(
          errorMessage: 'Invalid capacity selected',
        ));
        return;
      }

      // Update venue booking configuration with new capacity
      final updatedVenueConfig = state.venueBookingConfig!.copyWith(
        selectedCapacity: event.capacity,
      );

      // Update state with new venue configuration and synchronize groupSize
      final newGroupSize = event.capacity;

      // Calculate new price with the updated groupSize
      final newTotalPrice = _calculateTotalPrice(
        basePrice: state.basePrice,
        groupSize: newGroupSize,
        addOnsPrice: state.addOnsPrice,
        selectedAttendees: state.selectedAttendees,
        options: state.optionsDefinition,
      );

      emit(state.copyWith(
        venueBookingConfig: updatedVenueConfig,
        groupSize: newGroupSize,
        totalPrice: newTotalPrice,
        canConfirm: _checkCanConfirm(
          options: state.optionsDefinition,
          selectedDate: state.selectedDate,
          selectedTime: state.selectedTime,
          groupSize: newGroupSize,
          selectedAttendees: state.selectedAttendees,
        ),
      ));

      // Update cost splits if necessary
      if (state.costSplitConfig != null) {
        add(ChangeCostSplitType(splitType: state.costSplitConfig!.type));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error updating capacity: $e',
      ));
    }
  }

  Future<void> _onUpdateVenueIsPrivate(
    UpdateVenueIsPrivate event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Ensure venue booking config exists
      if (state.venueBookingConfig == null) {
        emit(state.copyWith(
          errorMessage: 'Venue booking configuration not initialized',
        ));
        return;
      }

      // Update privacy setting
      emit(state.copyWith(
        venueBookingConfig: state.venueBookingConfig!.copyWith(
          isPrivateEvent: event.isPrivate,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error updating venue privacy: $e',
      ));
    }
  }

  Future<void> _onChangeCostSplitType(
    ChangeCostSplitType event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Get current price if available
      final totalAmount = state.totalPrice > 0.0
          ? state.totalPrice
          : (state.venueBookingConfig?.price ?? 0.0);

      // Get current config or create a new one
      final currentConfig = state.costSplitConfig;

      // Create a cost split config with default values if not exists
      final updatedConfig = (currentConfig ??
              CostSplitConfig(
                type: CostSplitType.splitEqually,
                totalAmount: totalAmount,
              ))
          .copyWith(
        type: event.splitType,
        // Clear custom splits if switching away from custom
        customSplits: event.splitType == CostSplitType.splitCustom
            ? currentConfig?.customSplits
            : null,
      );

      // Get attendees from venue booking if available
      if (state.venueBookingConfig != null &&
          state.venueBookingConfig!.attendees.isNotEmpty) {
        // Apply cost calculation to attendees
        final attendees = updatedConfig
            .applyCostSharesToAttendees(state.venueBookingConfig!.attendees);

        // Update venue booking with new attendee costs
        final updatedVenueConfig = state.venueBookingConfig!.copyWith(
          attendees: attendees,
        );

        emit(state.copyWith(
          costSplitConfig: updatedConfig,
          venueBookingConfig: updatedVenueConfig,
        ));
      } else {
        // Just update the split config
        emit(state.copyWith(
          costSplitConfig: updatedConfig,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error changing cost split type: $e',
      ));
    }
  }

  Future<void> _onUpdateHostPaying(
    UpdateHostPaying event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Ensure cost split config exists
      if (state.costSplitConfig == null) {
        emit(state.copyWith(
          errorMessage: 'Cost split configuration not initialized',
        ));
        return;
      }

      // Update host paying setting
      final updatedConfig = state.costSplitConfig!.copyWith(
        isHostPaying: event.isHostPaying,
      );

      // Recalculate attendee costs
      if (state.venueBookingConfig != null &&
          state.venueBookingConfig!.attendees.isNotEmpty) {
        // Apply cost calculation to attendees
        final attendees = updatedConfig
            .applyCostSharesToAttendees(state.venueBookingConfig!.attendees);

        // Update venue booking with new attendee costs
        final updatedVenueConfig = state.venueBookingConfig!.copyWith(
          attendees: attendees,
        );

        emit(state.copyWith(
          costSplitConfig: updatedConfig,
          venueBookingConfig: updatedVenueConfig,
        ));
      } else {
        // Just update the split config
        emit(state.copyWith(
          costSplitConfig: updatedConfig,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error updating host paying setting: $e',
      ));
    }
  }

  Future<void> _onUpdateCustomCostSplit(
    UpdateCustomCostSplit event,
    Emitter<OptionsConfigurationState> emit,
  ) async {
    try {
      emit(state.copyWith(clearErrorMessage: true));

      // Ensure cost split config exists and is in custom mode
      if (state.costSplitConfig == null) {
        emit(state.copyWith(
          errorMessage: 'Cost split configuration not initialized',
        ));
        return;
      }

      if (state.costSplitConfig!.type != CostSplitType.splitCustom) {
        emit(state.copyWith(
          errorMessage:
              'Must be in custom split mode to update individual amounts',
        ));
        return;
      }

      // Get current custom splits or create new map
      final currentSplits = state.costSplitConfig!.customSplits ?? {};
      final updatedSplits = Map<String, double>.from(currentSplits);
      updatedSplits[event.attendeeId] = event.amount;

      // Update cost split config
      final updatedConfig = state.costSplitConfig!.copyWith(
        customSplits: updatedSplits,
      );

      // Update venue booking attendee cost if possible
      if (state.venueBookingConfig != null) {
        // Find the attendee and update cost
        final attendeeIndex = state.venueBookingConfig!.attendees
            .indexWhere((a) => a.id == event.attendeeId);

        if (attendeeIndex >= 0) {
          // Clone the attendees list
          final attendees =
              List<AttendeeConfig>.from(state.venueBookingConfig!.attendees);
          // Update the specific attendee's amount
          attendees[attendeeIndex] = attendees[attendeeIndex].copyWith(
            amountOwed: event.amount,
          );

          // Update venue booking with new attendee costs
          final updatedVenueConfig = state.venueBookingConfig!.copyWith(
            attendees: attendees,
          );

          emit(state.copyWith(
            costSplitConfig: updatedConfig,
            venueBookingConfig: updatedVenueConfig,
          ));
          return;
        }
      }

      // If we can't update venue booking, just update the cost split
      emit(state.copyWith(
        costSplitConfig: updatedConfig,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error updating custom cost split: $e',
      ));
    }
  }

  // Add calendar integration handler
  void _onToggleAddToCalendar(
    ToggleAddToCalendar event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state is OptionsConfigurationInitial) return;

    emit(state.copyWith(
      addToCalendar: event.addToCalendar,
      clearErrorMessage: true,
    ));
  }

  // Add reservation to the device calendar
  Future<void> _addToCalendar(ReservationModel reservation) async {
    try {
      // Import necessary service
      final calendarService = CalendarIntegrationService();

      // Request calendar permissions
      final hasPermission = await calendarService.requestCalendarPermission();
      if (!hasPermission) {
        print('Calendar permission denied');
        return;
      }

      // Get available calendars
      final calendars = await calendarService.getAvailableCalendars();
      if (calendars.isEmpty) {
        print('No calendars available');
        return;
      }

      // Use the default calendar (first one)
      final calendarId = calendars.first.id;

      // Get provider details for the event
      final providerData =
          await repository.getProviderDetails(reservation.providerId);
      final providerName =
          providerData?['name'] as String? ?? 'Service Provider';
      final locationAddress = providerData?['address'] as String?;
      final locationName = providerData?['location_name'] as String?;

      // Add event to calendar
      final success = await calendarService.addReservationToCalendar(
        reservation: reservation,
        calendarId:
            calendarId!, // Non-null assertion because we've checked calendars.isNotEmpty
        providerName: providerName,
        locationAddress: locationAddress,
        locationName: locationName,
      );

      if (success) {
        print('Event added to calendar successfully');
      } else {
        print('Failed to add event to calendar');
      }
    } catch (e) {
      print('Error adding to calendar: $e');
      // Don't throw - we don't want calendar errors to block the reservation process
    }
  }

  // Add payment method handler
  void _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state is OptionsConfigurationInitial) return;

    emit(state.copyWith(
      paymentMethod: event.paymentMethod,
      clearErrorMessage: true,
    ));
  }

  // Add reminder settings handler
  void _onUpdateReminderSettings(
    UpdateReminderSettings event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state is OptionsConfigurationInitial) return;

    emit(state.copyWith(
      enableReminders: event.enableReminders,
      reminderTimes: event.reminderTimes,
      clearErrorMessage: true,
    ));
  }

  // Add sharing settings handler
  void _onUpdateSharingSettings(
    UpdateSharingSettings event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state is OptionsConfigurationInitial) return;

    emit(state.copyWith(
      enableSharing: event.enableSharing,
      shareWithAttendees: event.shareWithAttendees,
      additionalEmails: event.additionalEmails,
      clearErrorMessage: true,
    ));
  }
}
