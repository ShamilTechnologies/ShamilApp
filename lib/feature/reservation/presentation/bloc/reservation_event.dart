// lib/feature/reservation/bloc/reservation_event.dart

part of 'reservation_bloc.dart'; // Link to the bloc file

@immutable
abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

/// Event when user selects the type of reservation (if multiple options)
class SelectReservationType extends ReservationEvent {
  final ReservationType reservationType;
  const SelectReservationType({required this.reservationType});
  @override
  List<Object?> get props => [reservationType];
}

/// Event when user selects a service (for service/time based/sequence based)
class SelectReservationService extends ReservationEvent {
  // Allow service to be nullable for general time-based booking
  final BookableService? selectedService;
  const SelectReservationService({required this.selectedService});
  @override
  List<Object?> get props => [selectedService];
}

/// Event when user selects a date
class SelectReservationDate extends ReservationEvent {
  final DateTime selectedDate;
  const SelectReservationDate({required this.selectedDate});
  @override
  List<Object?> get props => [selectedDate];
}

/// Event from UI after swipe gesture completes (for time-based)
class UpdateSwipeSelection extends ReservationEvent {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  const UpdateSwipeSelection({required this.startTime, required this.endTime});
  @override
  List<Object?> get props => [startTime, endTime];
}

// --- Attendee Events ---
/// Event to add an attendee (self, family, or friend invite)
class AddAttendee extends ReservationEvent {
  final AttendeeModel attendee;
  const AddAttendee({required this.attendee});
  @override
  List<Object?> get props => [attendee];
}

/// Event to remove an attendee (identified by userId)
class RemoveAttendee extends ReservationEvent {
  final String userIdToRemove;
  const RemoveAttendee({required this.userIdToRemove});
  @override
  List<Object?> get props => [userIdToRemove];
}
// --- End Attendee Events ---

/// Event to trigger reservation creation (for non-queue based types)
class CreateReservation extends ReservationEvent {
  const CreateReservation();
}

/// Event to reset the reservation flow state.
class ResetReservationFlow extends ReservationEvent {
  // Optionally pass provider context and initial attendee when resetting
  final ServiceProviderModel? provider;
  final AttendeeModel? initialAttendee;

  const ResetReservationFlow({this.provider, this.initialAttendee});

  @override
  List<Object?> get props => [provider, initialAttendee];
}

// --- Sequence-Based Events ---

/// Event triggered when the user selects a preferred hour slot for the queue.
class SelectSequenceTimeSlot extends ReservationEvent {
  final TimeOfDay? preferredHour; // Nullable to allow clearing the selection
  const SelectSequenceTimeSlot({required this.preferredHour});
  @override
  List<Object?> get props => [preferredHour];
}

/// Event triggered when the user taps "Join Queue".
class JoinQueue extends ReservationEvent {
  const JoinQueue();
  // No specific parameters here, data is read from state (service, date, preferredHour)
}

/// Event to periodically check the user's queue status (optional).
class CheckQueueStatus extends ReservationEvent {
  const CheckQueueStatus();
  // Reads context (service, date, preferredHour) from state
}

/// Event triggered when the user wants to leave the queue.
class LeaveQueue extends ReservationEvent {
  const LeaveQueue();
  // Reads context (service, date, preferredHour) from state
}

// --- Access-Based Event ---
/// Event triggered when user selects an AccessPassOption
class SelectAccessPassOption extends ReservationEvent {
  final AccessPassOption option;
  const SelectAccessPassOption({required this.option});
  @override
  List<Object?> get props => [option];
}
class SetAttendeePaymentStatus extends ReservationEvent {
  final String attendeeUserId;
  final PaymentStatus paymentStatus;
  final double? amount;
  
  const SetAttendeePaymentStatus({
    required this.attendeeUserId,
    required this.paymentStatus,
    this.amount,
  });
  
  @override
  List<Object?> get props => [attendeeUserId, paymentStatus, amount];
}

class SetVenueCapacity extends ReservationEvent {
  final bool isFullVenue;
  final int reservedCapacity;
  
  const SetVenueCapacity({
    required this.isFullVenue,
    required this.reservedCapacity,
  });
  
  @override
  List<Object?> get props => [isFullVenue, reservedCapacity];
}

class SetCommunityVisibility extends ReservationEvent {
  final bool isVisible;
  final String? hostingCategory;
  final String? description;
  
  const SetCommunityVisibility({
    required this.isVisible,
    this.hostingCategory,
    this.description,
  });
  
  @override
  List<Object?> get props => [isVisible, hostingCategory, description];
}