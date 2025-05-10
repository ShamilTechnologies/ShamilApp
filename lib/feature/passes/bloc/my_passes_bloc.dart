// lib/feature/passes/bloc/my_passes_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';

part 'my_passes_event.dart';
part 'my_passes_state.dart';

class MyPassesBloc extends Bloc<MyPassesEvent, MyPassesState> {
  final UserRepository _userRepository;

  MyPassesBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(MyPassesInitial()) {
    on<LoadMyPasses>(_onLoadMyPasses);
    on<CancelReservationPass>(_onCancelReservationPass);
    on<CancelSubscriptionPass>(_onCancelSubscriptionPass);
    on<RefreshMyPasses>(_onRefreshMyPasses);
  }

  Future<void> _onLoadMyPasses(
    LoadMyPasses event,
    Emitter<MyPassesState> emit,
  ) async {
    emit(MyPassesLoading());

    try {
      final reservations = await _userRepository.fetchUserReservations();
      final subscriptions = await _userRepository.fetchUserSubscriptions();

      emit(MyPassesLoaded(
        reservations: reservations,
        subscriptions: subscriptions,
      ));
    } catch (e) {
      emit(MyPassesError(message: e.toString()));
    }
  }

  Future<void> _onCancelReservationPass(
    CancelReservationPass event,
    Emitter<MyPassesState> emit,
  ) async {
    try {
      await _userRepository.cancelReservation(event.reservationId);
      add(const RefreshMyPasses());
    } catch (e) {
      final currentState = state;
      if (currentState is MyPassesLoaded) {
        emit(currentState.copyWith(
            errorMessage: 'Failed to cancel reservation: ${e.toString()}'));
      }
    }
  }

  Future<void> _onCancelSubscriptionPass(
    CancelSubscriptionPass event,
    Emitter<MyPassesState> emit,
  ) async {
    try {
      await _userRepository.cancelSubscription(event.subscriptionId);
      add(const RefreshMyPasses());
    } catch (e) {
      final currentState = state;
      if (currentState is MyPassesLoaded) {
        emit(currentState.copyWith(
            errorMessage: 'Failed to cancel subscription: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRefreshMyPasses(
    RefreshMyPasses event,
    Emitter<MyPassesState> emit,
  ) async {
    final currentState = state;

    try {
      final reservations = await _userRepository.fetchUserReservations();
      final subscriptions = await _userRepository.fetchUserSubscriptions();

      emit(MyPassesLoaded(
        reservations: reservations,
        subscriptions: subscriptions,
        successMessage:
            event.showSuccessMessage ? 'Passes refreshed successfully' : null,
      ));
    } catch (e) {
      if (currentState is MyPassesLoaded) {
        emit(currentState.copyWith(
            errorMessage: 'Failed to refresh passes: ${e.toString()}'));
      } else {
        emit(MyPassesError(message: e.toString()));
      }
    }
  }
}
