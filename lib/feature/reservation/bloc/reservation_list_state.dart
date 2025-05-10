part of 'reservation_list_bloc.dart';

abstract class ReservationListState extends Equatable {
  const ReservationListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReservationListInitial extends ReservationListState {}

/// Loading state
class ReservationListLoading extends ReservationListState {}

/// Loaded state with reservations
class ReservationListLoaded extends ReservationListState {
  final List<ReservationModel> reservations;
  final String? message;
  final String? error;

  const ReservationListLoaded({
    required this.reservations,
    this.message,
    this.error,
  });

  @override
  List<Object?> get props => [reservations, message, error];
}

/// Error state
class ReservationListError extends ReservationListState {
  final String message;

  const ReservationListError({required this.message});

  @override
  List<Object> get props => [message];
}
