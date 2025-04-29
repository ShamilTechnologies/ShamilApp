// lib/feature/reservation/bloc/reservation_state.dart

part of 'reservation_bloc.dart';

// Helper function to convert TimeOfDay to minutes since midnight for comparison
int _timeOfDayToMinutes(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

// Helper function to check if a list of TimeOfDay is sorted and consecutive
bool _areSlotsConsecutive(List<TimeOfDay> slots, int durationMinutes) {
  if (slots.length <= 1) return true;
  // Sort first (create a copy to avoid modifying original)
  final sortedSlots = List<TimeOfDay>.from(slots)..sort((a, b) => _timeOfDayToMinutes(a).compareTo(_timeOfDayToMinutes(b)));
  for (int i = 0; i < sortedSlots.length - 1; i++) {
    final currentMinutes = _timeOfDayToMinutes(sortedSlots[i]);
    final nextMinutes = _timeOfDayToMinutes(sortedSlots[i + 1]);
    // Check if the next slot starts exactly after the current one ends
    if (nextMinutes != currentMinutes + durationMinutes) {
      return false;
    }
  }
  return true;
}


@immutable
sealed class ReservationState extends Equatable {
   // Common properties
   final BookableService? selectedService;
   final DateTime? selectedDate;
   // *** CHANGED: Use a List for selected slots ***
   final List<TimeOfDay> selectedSlots; // Store multiple selected slots

  const ReservationState({
    this.selectedService,
    this.selectedDate,
    this.selectedSlots = const [], // Default to empty list
  });

  @override
  // *** UPDATED props ***
  List<Object?> get props => [selectedService, selectedDate, selectedSlots];
}

/// Initial state, nothing selected.
final class ReservationInitial extends ReservationState {
   const ReservationInitial() : super();
}

/// State after a service is selected.
final class ReservationServiceSelected extends ReservationState {
    const ReservationServiceSelected({required BookableService service})
       : super(selectedService: service);
}

/// State after a date is selected (fetches/includes available slots).
final class ReservationDateSelected extends ReservationState {
    final List<TimeOfDay> availableSlots;
    final bool isLoadingSlots;

    const ReservationDateSelected({
      required BookableService service,
      required DateTime date,
      required this.availableSlots, // Available slots are now required here
      this.isLoadingSlots = false,
      // selectedSlots remains empty initially after date selection
    }) : super(selectedService: service, selectedDate: date, selectedSlots: const []);

     @override
     List<Object?> get props => super.props..addAll([availableSlots, isLoadingSlots]);

     // Helper for immutable updates
     ReservationDateSelected copyWith({
        List<TimeOfDay>? availableSlots,
        bool? isLoadingSlots,
        // Allow updating selectedSlots within this state during swipe interaction maybe?
        // Or transition to a different state like ReservationSlotsUpdating
        List<TimeOfDay>? selectedSlots,
     }) {
       return ReservationDateSelected(
         service: selectedService!,
         date: selectedDate!,
         availableSlots: availableSlots ?? this.availableSlots,
         isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
         // If selectedSlots is passed, update it (used carefully)
         // selectedSlots: selectedSlots ?? this.selectedSlots,
       );
     }
}

/// State when one or more consecutive slots are selected.
final class ReservationSlotsSelected extends ReservationState {
   final List<TimeOfDay> availableSlots; // Keep available slots for UI context

   const ReservationSlotsSelected({
      required BookableService service,
      required DateTime date,
      required List<TimeOfDay> slots, // Pass the list of selected slots
      required this.availableSlots,
    // Add assertion to ensure slots are consecutive if needed, or handle in Bloc
    // assert(slots.isNotEmpty && _areSlotsConsecutive(slots, service.durationMinutes)),
    }) : super(selectedService: service, selectedDate: date, selectedSlots: slots);

     @override
     List<Object?> get props => super.props..addAll([availableSlots]);
}


/// State indicating the reservation creation is in progress (calling backend).
final class ReservationCreating extends ReservationState {
    // Keep previous selections for context
    const ReservationCreating({
      required BookableService service,
      required DateTime date,
      required List<TimeOfDay> slots, // Pass the list of slots being created
    }) : super(selectedService: service, selectedDate: date, selectedSlots: slots);
}

/// State indicating the reservation(s) were successfully created.
final class ReservationSuccess extends ReservationState {
    final String message;
    // Keep selected slots for potential display on success message?
    const ReservationSuccess({
        this.message = "Reservation confirmed!",
        List<TimeOfDay> slots = const []
      }) : super(selectedSlots: slots); // Pass empty list or confirmed slots

     @override
     List<Object?> get props => [message];
}

/// State indicating an error occurred during the reservation process.
final class ReservationError extends ReservationState {
  final String message;
  // Keep previous selections for context if needed for retry logic
  const ReservationError({
     required this.message,
     BookableService? service,
     DateTime? date,
     List<TimeOfDay> slots = const [],
    }) : super(selectedService: service, selectedDate: date, selectedSlots: slots);

  @override
  List<Object?> get props => super.props..addAll([message]);
}