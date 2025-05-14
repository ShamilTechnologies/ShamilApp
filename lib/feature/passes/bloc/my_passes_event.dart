// lib/feature/passes/bloc/my_passes_event.dart

part of 'my_passes_bloc.dart'; // Link to the Bloc file

abstract class MyPassesEvent extends Equatable {
  const MyPassesEvent();

  @override
  List<Object> get props => [];
}

/// Event to load all passes (reservations and subscriptions)
class LoadMyPasses extends MyPassesEvent {
  const LoadMyPasses();
}

/// Event to cancel a reservation
class CancelReservationPass extends MyPassesEvent {
  final String reservationId;

  const CancelReservationPass({required this.reservationId});

  @override
  List<Object> get props => [reservationId];
}

/// Event to cancel a subscription
class CancelSubscriptionPass extends MyPassesEvent {
  final String subscriptionId;

  const CancelSubscriptionPass({required this.subscriptionId});

  @override
  List<Object> get props => [subscriptionId];
}

/// Event to refresh all passes
class RefreshMyPasses extends MyPassesEvent {
  final bool showSuccessMessage;

  const RefreshMyPasses({this.showSuccessMessage = false});

  @override
  List<Object> get props => [showSuccessMessage];
}

/// Event to change the pass filter
class ChangePassFilter extends MyPassesEvent {
  final PassFilter filter;

  const ChangePassFilter(this.filter);

  @override
  List<Object> get props => [filter];
}

// Add other events later if needed (e.g., CancelReservation, ViewDetails)
