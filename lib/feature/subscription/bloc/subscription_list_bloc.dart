import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';

part 'subscription_list_event.dart';
part 'subscription_list_state.dart';

class SubscriptionListBloc
    extends Bloc<SubscriptionListEvent, SubscriptionListState> {
  final UserRepository _userRepository;

  SubscriptionListBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(SubscriptionListInitial()) {
    on<LoadSubscriptionList>(_onLoadSubscriptionList);
    on<CancelSubscription>(_onCancelSubscription);
    on<SubscriptionRefresh>(_onSubscriptionRefresh);
  }

  Future<void> _onLoadSubscriptionList(
    LoadSubscriptionList event,
    Emitter<SubscriptionListState> emit,
  ) async {
    emit(SubscriptionListLoading());

    try {
      final subscriptions = await _userRepository.fetchUserSubscriptions();
      emit(SubscriptionListLoaded(subscriptions: subscriptions));
    } catch (e) {
      emit(SubscriptionListError(message: e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<SubscriptionListState> emit,
  ) async {
    if (state is SubscriptionListLoaded) {
      final currentState = state as SubscriptionListLoaded;
      emit(SubscriptionListLoading());

      try {
        await _userRepository.cancelSubscription(event.subscriptionId);

        // Refresh the list after cancellation
        final updatedSubscriptions =
            await _userRepository.fetchUserSubscriptions();
        emit(SubscriptionListLoaded(
          subscriptions: updatedSubscriptions,
          message: 'Subscription cancelled successfully',
        ));
      } catch (e) {
        emit(SubscriptionListLoaded(
          subscriptions: currentState.subscriptions,
          error: 'Failed to cancel subscription: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onSubscriptionRefresh(
    SubscriptionRefresh event,
    Emitter<SubscriptionListState> emit,
  ) async {
    final currentState = state;

    try {
      final subscriptions = await _userRepository.fetchUserSubscriptions();
      emit(SubscriptionListLoaded(subscriptions: subscriptions));
    } catch (e) {
      if (currentState is SubscriptionListLoaded) {
        emit(SubscriptionListLoaded(
          subscriptions: currentState.subscriptions,
          error: 'Failed to refresh: ${e.toString()}',
        ));
      } else {
        emit(SubscriptionListError(message: e.toString()));
      }
    }
  }
}
