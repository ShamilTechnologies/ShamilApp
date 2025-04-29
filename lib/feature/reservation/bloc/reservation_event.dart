part of 'reservation_bloc.dart';

@immutable
abstract class ReservationEvent extends Equatable {
  const ReservationEvent();
  @override
  List<Object?> get props => [];
}

/// Event triggered when a user selects a specific bookable service.
class SelectReservationService extends ReservationEvent {
  final BookableService selectedService;
  // Potentially add providerId if needed
  const SelectReservationService({required this.selectedService});
  @override
  List<Object?> get props => [selectedService];
}

/// Event triggered when a user selects a date.
class SelectReservationDate extends ReservationEvent {
  final DateTime selectedDate;
  const SelectReservationDate({required this.selectedDate});
  @override
  List<Object?> get props => [selectedDate];
}

/// Event triggered to update the list of selected time slots.
/// This could be triggered during a swipe gesture update or at the end of the gesture.
class UpdateSlotSelection extends ReservationEvent {
  final List<TimeOfDay> newlySelectedSlots;
  const UpdateSlotSelection({required this.newlySelectedSlots});
  @override
  List<Object?> get props => [newlySelectedSlots];
}

/// Event to initiate the creation of the reservation(s) for the currently selected slots.
/// The Bloc handler will read the selected slots from the current state.
class CreateReservation extends ReservationEvent {
  // Information needed by the backend function, implicitly uses selected slots from state
  final String providerId;
  final BookableService service; // Pass service for duration/details needed by backend
  final DateTime date;       // Pass date context

  const CreateReservation({
    required this.providerId,
    required this.service,
    required this.date,
  });
  @override
  List<Object?> get props => [providerId, service, date];
}


/// Event to reset the reservation flow state.
class ResetReservationFlow extends ReservationEvent {}

// REMOVED: SelectReservationTime - No longer used for single selection.
// class SelectReservationTime extends ReservationEvent { ... }