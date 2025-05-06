// lib/feature/reservation/bloc/reservation_event.dart

part of 'reservation_bloc.dart'; // Link to the bloc file

@immutable
abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

// Event when user selects the type of reservation (if multiple options)
class SelectReservationType extends ReservationEvent {
  final ReservationType reservationType;
  const SelectReservationType({required this.reservationType});
  @override List<Object?> get props => [reservationType];
}

// Event when user selects a service (for service/time based)
class SelectReservationService extends ReservationEvent {
  // Allow service to be nullable for general time-based booking
  final BookableService? selectedService;
  const SelectReservationService({required this.selectedService});
  @override List<Object?> get props => [selectedService];
}

// Event when user selects a date (for time/seat based)
class SelectReservationDate extends ReservationEvent {
  final DateTime selectedDate;
  const SelectReservationDate({required this.selectedDate});
  @override List<Object?> get props => [selectedDate];
}

// Event from UI after swipe gesture completes (for time based)
class UpdateSwipeSelection extends ReservationEvent {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  const UpdateSwipeSelection({required this.startTime, required this.endTime});
  @override List<Object?> get props => [startTime, endTime];
}

// --- Attendee Events ---
// Event to add an attendee (self, family, or friend invite)
class AddAttendee extends ReservationEvent {
  final AttendeeModel attendee;
  const AddAttendee({required this.attendee});
  @override List<Object?> get props => [attendee];
}

// Event to remove an attendee (identified by userId)
class RemoveAttendee extends ReservationEvent {
  final String userIdToRemove;
  const RemoveAttendee({required this.userIdToRemove});
  @override List<Object?> get props => [userIdToRemove];
}
// --- End Attendee Events ---


// Event to trigger reservation creation
class CreateReservation extends ReservationEvent {
  // No longer needs specific parameters here, reads from state
  const CreateReservation();
}

// Event to reset the flow
class ResetReservationFlow extends ReservationEvent {
  // Optionally pass provider context and initial attendee when resetting
  final ServiceProviderModel? provider;
  final AttendeeModel? initialAttendee;

  const ResetReservationFlow({this.provider, this.initialAttendee});

  @override List<Object?> get props => [provider, initialAttendee];
}

// ACTION: Add events for seat selection, access pass selection if needed
// class SelectSeat extends ReservationEvent { ... }
// class SelectAccessOption extends ReservationEvent { ... }
