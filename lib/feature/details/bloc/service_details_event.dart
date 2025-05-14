// lib/feature/details/bloc/service_details_event.dart

part of 'service_details_bloc.dart';

/// Events that can be dispatched to the ServiceDetailsBloc
abstract class ServiceDetailsEvent extends Equatable {
  const ServiceDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all details for a specific service provider,
/// including their profile information, plans, and services.
class LoadServiceDetails extends ServiceDetailsEvent {
  final String providerId;

  const LoadServiceDetails({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

/// Event triggered when a user selects a specific plan.
class PlanSelected extends ServiceDetailsEvent {
  final String planId;
  final String providerId; // For context

  const PlanSelected({required this.planId, required this.providerId});

  @override
  List<Object?> get props => [planId, providerId];
}

/// Event triggered when a user selects a specific service.
class ServiceSelected extends ServiceDetailsEvent {
  final String serviceId;
  final String providerId; // For context

  const ServiceSelected({required this.serviceId, required this.providerId});

  @override
  List<Object?> get props => [serviceId, providerId];
}

/// Event triggered when the user toggles the favorite status.
class ToggleFavoriteStatus extends ServiceDetailsEvent {
  final String providerId; // ID of the provider being favorited/unfavorited
  final bool
      currentStatus; // The current favorite status (true if favorited, false if not)

  const ToggleFavoriteStatus({
    required this.providerId,
    required this.currentStatus,
  });

  @override
  List<Object?> get props => [providerId, currentStatus];
}

/// Event for setting the reservation venue capacity
class SetReservationCapacity extends ServiceDetailsEvent {
  final bool isFullVenue;
  final int capacity;

  const SetReservationCapacity({
    required this.isFullVenue,
    required this.capacity,
  });

  @override
  List<Object?> get props => [isFullVenue, capacity];
}

/// Event for setting an attendee's payment status
class SetAttendeePayment extends ServiceDetailsEvent {
  final String attendeeId;
  final PaymentStatus status;
  final double? amount;
  final AttendeeModel? attendee; // Provided if adding a new attendee

  const SetAttendeePayment({
    required this.attendeeId,
    required this.status,
    this.amount,
    this.attendee,
  });

  @override
  List<Object?> get props => [attendeeId, status, amount, attendee];
}

/// Event for setting community visibility options
class SetCommunityVisibility extends ServiceDetailsEvent {
  final bool isVisible;
  final String? category;
  final String? description;

  const SetCommunityVisibility({
    required this.isVisible,
    this.category,
    this.description,
  });

  @override
  List<Object?> get props => [isVisible, category, description];
}

/// Event for updating cost splitting settings
class UpdateCostSplitting extends ServiceDetailsEvent {
  final bool enabled;
  final String method; // 'equal', 'custom', 'host_pays', 'self_pays'
  final Map<String, double>? customRatios; // userId -> ratio (0-1)

  const UpdateCostSplitting({
    required this.enabled,
    required this.method,
    this.customRatios,
  });

  @override
  List<Object?> get props => [enabled, method, customRatios];
}

/// Event to initiate a reservation or subscription
class InitiateReservation extends ServiceDetailsEvent {
  final DateTime date;
  final String timeSlot; // Format: "HH:MM-HH:MM"
  final String? notes;

  const InitiateReservation({
    required this.date,
    required this.timeSlot,
    this.notes,
  });

  @override
  List<Object?> get props => [date, timeSlot, notes];
}

/// Event to cancel an existing reservation
class CancelReservation extends ServiceDetailsEvent {
  final String reservationId;

  const CancelReservation({required this.reservationId});

  @override
  List<Object?> get props => [reservationId];
}

/// Event for adding a new attendee to the reservation
class AddAttendee extends ServiceDetailsEvent {
  final AttendeeModel attendee;

  const AddAttendee({required this.attendee});

  @override
  List<Object?> get props => [attendee];
}

/// Event for removing an attendee from the reservation
class RemoveAttendee extends ServiceDetailsEvent {
  final String attendeeId;

  const RemoveAttendee({required this.attendeeId});

  @override
  List<Object?> get props => [attendeeId];
}

/// Event for updating an attendee's payment status
class UpdateAttendeePayment extends ServiceDetailsEvent {
  final String attendeeId;
  final PaymentStatus status;
  final double? amountPaid;

  const UpdateAttendeePayment({
    required this.attendeeId,
    required this.status,
    this.amountPaid,
  });

  @override
  List<Object?> get props => [attendeeId, status, amountPaid];
}
