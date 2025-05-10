import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';

part 'reservation_list_event.dart';
part 'reservation_list_state.dart';

class ReservationListBloc
    extends Bloc<ReservationListEvent, ReservationListState> {
  final UserRepository _userRepository;

  ReservationListBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(ReservationListInitial()) {
    on<LoadReservationList>(_onLoadReservationList);
    on<CancelReservation>(_onCancelReservation);
    on<ReservationRefresh>(_onReservationRefresh);
  }

  Future<void> _onLoadReservationList(
    LoadReservationList event,
    Emitter<ReservationListState> emit,
  ) async {
    emit(ReservationListLoading());

    try {
      final reservations = await _userRepository.fetchUserReservations();
      emit(ReservationListLoaded(reservations: reservations));
    } catch (e) {
      emit(ReservationListError(message: e.toString()));
    }
  }

  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ReservationListState> emit,
  ) async {
    if (state is ReservationListLoaded) {
      final currentState = state as ReservationListLoaded;
      emit(ReservationListLoading());

      try {
        await _userRepository.cancelReservation(event.reservationId);

        // Refresh the list after cancellation
        final updatedReservations =
            await _userRepository.fetchUserReservations();
        emit(ReservationListLoaded(
          reservations: updatedReservations,
          message: 'Reservation cancelled successfully',
        ));
      } catch (e) {
        emit(ReservationListLoaded(
          reservations: currentState.reservations,
          error: 'Failed to cancel reservation: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onReservationRefresh(
    ReservationRefresh event,
    Emitter<ReservationListState> emit,
  ) async {
    final currentState = state;

    try {
      final reservations = await _userRepository.fetchUserReservations();
      emit(ReservationListLoaded(reservations: reservations));
    } catch (e) {
      if (currentState is ReservationListLoaded) {
        emit(ReservationListLoaded(
          reservations: currentState.reservations,
          error: 'Failed to refresh: ${e.toString()}',
        ));
      } else {
        emit(ReservationListError(message: e.toString()));
      }
    }
  }
}
