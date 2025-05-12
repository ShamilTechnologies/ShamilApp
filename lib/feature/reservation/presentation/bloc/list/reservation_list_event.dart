// lib/feature/reservation/presentation/bloc/list/reservation_list_event.dart

part of 'reservation_list_bloc.dart';

abstract class ReservationListEvent extends Equatable {
  const ReservationListEvent();

  @override
  List<Object> get props => [];
}

/// Event to load all reservations for the user
class LoadReservationList extends ReservationListEvent {
  const LoadReservationList();
}

/// Event to cancel a specific reservation
class CancelReservation extends ReservationListEvent {
  final String reservationId;

  const CancelReservation({required this.reservationId});

  @override
  List<Object> get props => [reservationId];
}

/// Event to refresh the list of reservations
class ReservationRefresh extends ReservationListEvent {
  const ReservationRefresh();
}