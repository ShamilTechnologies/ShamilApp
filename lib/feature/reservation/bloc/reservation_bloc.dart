// lib/feature/reservation/bloc/reservation_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp and queries
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for userId
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:intl/intl.dart'; // For formatting day name
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
// Import ServiceProviderModel which includes OpeningHours
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
// Import the ReservationModel we defined
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';

// Import Cloud Functions
import 'package:cloud_functions/cloud_functions.dart';

part 'reservation_event.dart';
part 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  // Dependencies (Inject these properly later if needed beyond provider)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Initialize Cloud Functions instance
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Store the provider model passed via constructor
  final ServiceProviderModel provider;

  // Helper to get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Constructor requires ServiceProviderModel
  ReservationBloc({required this.provider})
      : super(const ReservationInitial()) {
    on<SelectReservationService>(_onSelectReservationService);
    on<SelectReservationDate>(_onSelectReservationDate);
    on<UpdateSlotSelection>(_onUpdateSlotSelection);
    on<CreateReservation>(_onCreateReservation); // Handler registration
    on<ResetReservationFlow>(_onResetReservationFlow);
    print("ReservationBloc Initialized for Provider ID: ${provider.id}");
  }

  void _onSelectReservationService(
      SelectReservationService event, Emitter<ReservationState> emit) {
    print("ReservationBloc: Service selected - ${event.selectedService.name}");
    // Reset date and selected slots when service changes
    emit(ReservationServiceSelected(service: event.selectedService));
  }

  Future<void> _onSelectReservationDate(
      SelectReservationDate event, Emitter<ReservationState> emit) async {
    final currentService = state.selectedService;
    if (currentService == null) {
      emit(const ReservationError(message: "Please select a service first."));
      return;
    }

    // --- Get Opening Hours for the selected day ---
    // Uses the stored provider's openingHours map
    print("ReservationBloc: Opening hours data being used:");
    this.provider.openingHours.forEach((key, value) {
      print(
          "  $key: isOpen=${value.isOpen}, start=${value.startTime}, end=${value.endTime}");
    });
    final OpeningHours? dailyHours = _getOpeningHoursForDate(
        event.selectedDate, this.provider.openingHours); // Use OpeningHours
    // --- End Opening Hours retrieval ---

    if (dailyHours == null ||
        !dailyHours.isOpen ||
        dailyHours.startTime == null ||
        dailyHours.endTime == null) {
      print(
          "ReservationBloc: Provider ${provider.id} is closed on ${DateFormat('EEEE').format(event.selectedDate)} based on looked up hours.");
      emit(ReservationDateSelected(
          service: currentService,
          date: event.selectedDate,
          availableSlots: [], // No slots available
          isLoadingSlots: false));
      return;
    }

    print(
        "ReservationBloc: Date selected - ${event.selectedDate}, Service: ${currentService.name}");
    emit(ReservationDateSelected(
        service: currentService,
        date: event.selectedDate,
        availableSlots: [], // Start with empty list while loading
        isLoadingSlots: true)); // Indicate loading

    try {
      // --- Fetch Existing Reservations ---
      final List<ReservationModel> existingReservations =
          await _fetchExistingReservations(
              this.provider.id, // Use stored provider ID
              event.selectedDate);
      // --- End Fetch Existing Reservations ---

      // --- Generate Available Slots ---
      final List<TimeOfDay> availableSlots = _generateTimeSlots(
        startTime: dailyHours.startTime!,
        endTime: dailyHours.endTime!,
        durationMinutes: currentService.durationMinutes,
        existingBookings: existingReservations,
        selectedDate: event.selectedDate,
      );
      // --- End Slot Generation ---

      print(
          "ReservationBloc: Generated ${availableSlots.length} available slots for ${event.selectedDate}.");

      // Check if the state is still relevant before emitting
      final currentState = state;
      if (currentState is ReservationDateSelected &&
          currentState.selectedDate == event.selectedDate &&
          currentState.selectedService == currentService) {
        emit(currentState.copyWith(
            availableSlots: availableSlots, isLoadingSlots: false));
      } else {
        print(
            "ReservationBloc: State changed while fetching slots, discarding result.");
      }
    } catch (e) {
      print(
          "ReservationBloc: Error fetching existing reservations or generating slots: $e");
      final currentState = state;
      // Only update state if it's still the relevant date/service selection
      if (currentState is ReservationDateSelected &&
          currentState.selectedDate == event.selectedDate &&
          currentState.selectedService == currentService) {
        emit(currentState.copyWith(
          availableSlots: [], // Clear slots on error
          isLoadingSlots: false,
        ));
        // Optionally emit a specific error state here if needed for UI feedback
        emit(ReservationError(
            message: "Failed to load slots: ${e.toString()}",
            service: currentService,
            date: event.selectedDate,
            slots: const []));
      }
    }
  }

  /// Gets opening hours for a specific date from the schedule map.
  OpeningHours? _getOpeningHoursForDate(
      // Updated return type
      DateTime date,
      Map<String, OpeningHours> schedule) {
    // Updated map type
    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    print("ReservationBloc: Getting opening hours for day key: '$dayName'");
    return schedule[dayName] ??
        const OpeningHours(isOpen: false); // Updated class name
  }

  /// Fetches existing reservations for a provider on a specific date.
  Future<List<ReservationModel>> _fetchExistingReservations(
      String providerId, DateTime date) async {
    print(
        "ReservationBloc: Fetching existing reservations for Provider $providerId on $date");

    // Calculate start and end Timestamps for the selected date (UTC)
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay =
        DateTime.utc(date.year, date.month, date.day, 23, 59, 59, 999);
    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    print(
        "ReservationBloc: Querying reservations between $startTimestamp and $endTimestamp");

    try {
      // TODO: Replace 'reservations' with your actual top-level collection name if different
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('providerId', isEqualTo: providerId)
          .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('reservationStartTime',
              isLessThanOrEqualTo:
                  endTimestamp) // Use lessThanOrEqualTo end of day
          .where('status',
              isEqualTo: ReservationStatus
                  .confirmed.statusString) // Only fetch confirmed bookings
          .get();

      final reservations = querySnapshot.docs
          .map((doc) {
            try {
              return ReservationModel.fromFirestore(doc);
            } catch (e) {
              print("Error parsing reservation doc ${doc.id}: $e");
              return null;
            }
          })
          .whereType<ReservationModel>()
          .toList();

      print(
          "ReservationBloc: Found ${reservations.length} existing confirmed reservations.");
      return reservations;
    } catch (e) {
      print(
          "ReservationBloc: Error fetching existing reservations from Firestore: $e");
      // Consider how to handle this error - rethrow or return empty?
      // Returning empty might lead to double bookings if the fetch fails.
      throw Exception("Failed to fetch existing bookings: $e");
      // return [];
    }
  }

  /// Generates list of available TimeOfDay slots based on parameters.
  List<TimeOfDay> _generateTimeSlots({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int durationMinutes,
    required List<ReservationModel> existingBookings,
    required DateTime selectedDate,
  }) {
    if (durationMinutes <= 0) return [];
    final List<TimeOfDay> slots = [];
    final int startTotalMinutes = startTime.hour * 60 + startTime.minute;
    final int endTotalMinutes = endTime.hour * 60 + endTime.minute;
    int currentStartMinutes = startTotalMinutes;

    // Convert existing bookings to busy intervals in minutes since midnight
    // IMPORTANT: Ensure timezone consistency between selectedDate and Timestamps
    final busyIntervals = existingBookings
        .map((booking) {
          final bookingStart = booking.reservationStartTime
              .toDate()
              .toLocal(); // Convert to local for comparison
          final bookingEnd = booking.reservationEndTime
              .toDate()
              .toLocal(); // Convert to local for comparison
          // Check if the booking is on the selected date (local comparison)
          if (bookingStart.year == selectedDate.year &&
              bookingStart.month == selectedDate.month &&
              bookingStart.day == selectedDate.day) {
            return {
              'start': TimeOfDay.fromDateTime(bookingStart).hour * 60 +
                  TimeOfDay.fromDateTime(bookingStart).minute,
              'end': TimeOfDay.fromDateTime(bookingEnd).hour * 60 +
                  TimeOfDay.fromDateTime(bookingEnd).minute
            };
          }
          return null;
        })
        .whereType<Map<String, int>>()
        .toList();

    while (currentStartMinutes < endTotalMinutes) {
      final currentEndMinutes = currentStartMinutes + durationMinutes;
      // Slot must end on or before the closing time
      if (currentEndMinutes > endTotalMinutes) break;

      // Check for conflict with existing bookings
      bool conflict = false;
      for (final interval in busyIntervals) {
        // Check for overlap: (SlotStart < IntervalEnd) and (SlotEnd > IntervalStart)
        if (currentStartMinutes < interval['end']! &&
            currentEndMinutes > interval['start']!) {
          conflict = true;
          break;
        }
      }

      // If no conflict, add the slot
      if (!conflict) {
        slots.add(TimeOfDay(
            hour: currentStartMinutes ~/ 60, minute: currentStartMinutes % 60));
      }

      // Move to the next potential slot start time
      // *** FIX: Increment by duration, not end time ***
      currentStartMinutes += durationMinutes; // Move by the slot duration
    }
    return slots;
  }

  /// Handles the updating of the selected slots list.
  void _onUpdateSlotSelection(
      UpdateSlotSelection event, Emitter<ReservationState> emit) {
    // Check if the current state has the necessary data
    if (state.selectedService == null || state.selectedDate == null) {
      print(
          "ReservationBloc: Cannot update slots without selected service and date.");
      return; // Or emit an error
    }

    List<TimeOfDay> currentAvailableSlots = [];
    // Safely get available slots from the current state
    if (state is ReservationDateSelected) {
      currentAvailableSlots = (state as ReservationDateSelected).availableSlots;
    } else if (state is ReservationSlotsSelected) {
      currentAvailableSlots =
          (state as ReservationSlotsSelected).availableSlots;
    } else {
      print(
          "ReservationBloc: UpdateSlotSelection called in unexpected state: ${state.runtimeType}");
      return; // Cannot proceed without available slots context
    }

    final currentService = state.selectedService!;
    final currentDate = state.selectedDate!;
    // Filter the newly selected slots to ensure they are actually available
    final validatedSelection = List<TimeOfDay>.from(event.newlySelectedSlots)
      ..removeWhere((slot) => !currentAvailableSlots.contains(slot));

    // Sort the validated selection for consecutiveness check
    validatedSelection.sort(
        (a, b) => _timeOfDayToMinutes(a).compareTo(_timeOfDayToMinutes(b)));

    bool consecutive = true;
    if (validatedSelection.length > 1) {
      for (int i = 0; i < validatedSelection.length - 1; i++) {
        final currentMinutes = _timeOfDayToMinutes(validatedSelection[i]);
        final nextMinutes = _timeOfDayToMinutes(validatedSelection[i + 1]);
        // Check if the next slot starts exactly after the current one ends
        if (nextMinutes != currentMinutes + currentService.durationMinutes) {
          consecutive = false;
          break;
        }
      }
    }

    // If slots are not consecutive, emit an error and revert selection
    if (!consecutive) {
      print("ReservationBloc: Non-consecutive slots selected.");
      // Emit error state, keeping context but clearing selected slots
      emit(ReservationError(
        message: "Please select consecutive time slots.",
        service: currentService,
        date: currentDate,
        slots: const [], // Clear selection on error
      ));
      // Schedule a revert back to the date selected state after a short delay
      // This allows the error message to be seen before the UI resets
      Future.delayed(const Duration(milliseconds: 2000), () {
        // Check if the state is still the error state for this date/service before reverting
        if (state is ReservationError &&
            state.selectedDate == currentDate &&
            state.selectedService == currentService) {
          emit(ReservationDateSelected(
              service: currentService,
              date: currentDate,
              availableSlots: currentAvailableSlots,
              isLoadingSlots: false // Ensure loading is false
              ));
        }
      });
      return; // Stop processing this event
    }

    // If selection is valid (empty or consecutive)
    if (validatedSelection.isEmpty) {
      // If selection is now empty, go back to DateSelected state
      emit(ReservationDateSelected(
          service: currentService,
          date: currentDate,
          availableSlots: currentAvailableSlots,
          isLoadingSlots: false));
    } else {
      // If selection is valid and not empty, emit SlotsSelected state
      emit(ReservationSlotsSelected(
          service: currentService,
          date: currentDate,
          slots: validatedSelection,
          availableSlots: currentAvailableSlots));
    }
  }

  /// Handles the creation of reservations by calling the Cloud Function.
  Future<void> _onCreateReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    if (state.selectedSlots.isEmpty) {
      emit(const ReservationError(
          message: "Please select at least one time slot."));
      // Optionally revert to DateSelected state after delay
      if (state.selectedDate != null && state.selectedService != null) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (state.selectedSlots.isEmpty) {
            // Check again in case state changed
            add(SelectReservationDate(selectedDate: state.selectedDate!));
          }
        });
      }
      return;
    }

    // Ensure we have user ID
    final userId = _userId;
    if (userId == null) {
      emit(const ReservationError(
          message: "User not authenticated. Please log in."));
      return;
    }

    final selectedSlots = state.selectedSlots;
    final providerId = this.provider.id; // Use provider ID from constructor

    emit(ReservationCreating(
        service: event.service, date: event.date, slots: selectedSlots));
    print(
        "ReservationBloc: Creating reservation(s) for ${selectedSlots.length} slots...");
    print(
        "   Provider: $providerId, Service: ${event.service.name}, Date: ${event.date}");
    for (var slot in selectedSlots) {
      print("   Slot: $slot");
    }

    try {
      // *** FIX: Convert Timestamps to millisecondsSinceEpoch ***
      final List<Map<String, dynamic>> reservationRequests =
          selectedSlots.map((slot) {
        final startDateTimeLocal = DateTime(event.date.year, event.date.month,
            event.date.day, slot.hour, slot.minute);
        final endDateTimeLocal = startDateTimeLocal
            .add(Duration(minutes: event.service.durationMinutes));
        return {
          // Convert UTC DateTime to milliseconds since epoch (int)
          'startTimeMillis': startDateTimeLocal.toUtc().millisecondsSinceEpoch,
          'endTimeMillis': endDateTimeLocal.toUtc().millisecondsSinceEpoch,
        };
      }).toList();

      // Prepare the payload for the Cloud Function
      final payload = <String, dynamic>{
        'userId': userId,
        'providerId': providerId,
        'serviceId': event.service.id,
        'serviceName': event.service.name,
        'serviceDurationMinutes': event.service.durationMinutes,
        'servicePrice': event.service.price,
        // Convert the reservation date (start of day) to milliseconds since epoch (UTC)
        'reservationDateMillis':
            DateTime.utc(event.date.year, event.date.month, event.date.day)
                .millisecondsSinceEpoch,
        'requestedSlots': reservationRequests, // List of maps with milliseconds
      };

      // --- Actual Cloud Function Call ---
      print(
          "ReservationBloc: Calling 'createReservation' Cloud Function with payload: $payload");
      final HttpsCallable callable =
          _functions.httpsCallable('createReservation');

      final result = await callable.call(payload); // Pass the converted payload

      print("Cloud Function 'createReservation' result: ${result.data}");

      // Check the result from the Cloud Function
      if (result.data?['success'] == true) {
        print("ReservationBloc: Backend reservation successful.");
        // Extract success message or use default
        final successMessage = result.data?['message'] as String? ??
            "${selectedSlots.length} reservation(s) confirmed!";
        emit(ReservationSuccess(message: successMessage, slots: selectedSlots));
        // Optionally: Dispatch event to refresh user's bookings list elsewhere
        // context.read<UserBookingsBloc>().add(FetchUserBookings());
      } else {
        // Backend returned an error
        final errorMessage = result.data?['error'] as String? ??
            'Reservation failed on the server.';
        print("ReservationBloc: Backend reservation failed - $errorMessage");
        emit(ReservationError(
            message: errorMessage,
            service: event.service,
            date: event.date,
            slots: selectedSlots // Keep context on error
            ));
      }
      // --- End Cloud Function Call ---
    } on FirebaseFunctionsException catch (e) {
      print(
          "ReservationBloc: FirebaseFunctionsException during reservation creation - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
      // Check for the specific assertion error if details are available
      String displayMessage =
          "Reservation Error (${e.code}): ${e.message ?? 'Please try again.'}";
      if (e.details is Map &&
          (e.details as Map).containsKey('message') &&
          (e.details['message'] as String).contains('assertion was thrown')) {
        displayMessage =
            "Reservation Error: Invalid data sent to server. Please check inputs.";
      }
      emit(ReservationError(
          message: displayMessage,
          service: event.service,
          date: event.date,
          slots: selectedSlots));
    } catch (e) {
      print("ReservationBloc: Generic error during reservation creation - $e");
      emit(ReservationError(
          message: "An unexpected error occurred: ${e.toString()}",
          service: event.service,
          date: event.date,
          slots: selectedSlots));
    }
  }

  /// Resets the Bloc to its initial state.
  void _onResetReservationFlow(
      ResetReservationFlow event, Emitter<ReservationState> emit) {
    print("ReservationBloc: Resetting flow.");
    emit(const ReservationInitial());
  }

  // Helper function
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
} // End of ReservationBloc
