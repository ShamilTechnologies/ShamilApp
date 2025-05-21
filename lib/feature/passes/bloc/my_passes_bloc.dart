// lib/feature/passes/bloc/my_passes_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/queue_reservation_repository_impl.dart';

part 'my_passes_event.dart';
part 'my_passes_state.dart';

class MyPassesBloc extends Bloc<MyPassesEvent, MyPassesState> {
  final UserRepository _userRepository;
  final QueueReservationRepository _queueRepository =
      QueueReservationRepository();

  // Timer for periodic updates of queue status
  Timer? _queueUpdateTimer;

  MyPassesBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(MyPassesInitial()) {
    on<LoadMyPasses>(_onLoadMyPasses);
    on<CancelReservationPass>(_onCancelReservationPass);
    on<CancelSubscriptionPass>(_onCancelSubscriptionPass);
    on<RefreshMyPasses>(_onRefreshMyPasses);
    on<ChangePassFilter>(_onChangePassFilter);
    on<UpdateQueueStatus>(_onUpdateQueueStatus);
    on<StartQueueStatusUpdates>(_onStartQueueStatusUpdates);
    on<StopQueueStatusUpdates>(_onStopQueueStatusUpdates);
  }

  @override
  Future<void> close() {
    _stopQueueStatusUpdates();
    return super.close();
  }

  Future<void> _onLoadMyPasses(
    LoadMyPasses event,
    Emitter<MyPassesState> emit,
  ) async {
    emit(MyPassesLoading());

    try {
      final reservations = await _userRepository.fetchUserReservations();
      final subscriptions = await _userRepository.fetchUserSubscriptions();

      // Start queue status updates if there are queue-based reservations
      final hasQueueBasedReservations = reservations.any((r) =>
          r.queueBased &&
          (r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.pending));

      if (hasQueueBasedReservations) {
        add(const StartQueueStatusUpdates());
      }

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
    // Preserve the current filter if it exists
    PassFilter? currentFilter;
    if (currentState is MyPassesLoaded) {
      currentFilter = currentState.currentFilter;
    }

    try {
      final reservations = await _userRepository.fetchUserReservations();
      final subscriptions = await _userRepository.fetchUserSubscriptions();

      // Update queue statuses for all queue-based reservations
      final hasQueueBasedReservations = reservations.any((r) =>
          r.queueBased &&
          (r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.pending));

      if (hasQueueBasedReservations) {
        add(const StartQueueStatusUpdates());
      } else {
        add(const StopQueueStatusUpdates());
      }

      emit(MyPassesLoaded(
        reservations: reservations,
        subscriptions: subscriptions,
        successMessage:
            event.showSuccessMessage ? 'Passes refreshed successfully' : null,
        // Use the preserved filter or default to All
        currentFilter: currentFilter ?? PassFilter.all,
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

  void _onChangePassFilter(
    ChangePassFilter event,
    Emitter<MyPassesState> emit,
  ) {
    if (state is MyPassesLoaded) {
      final currentState = state as MyPassesLoaded;
      // Ensure we're not passing null to copyWith
      final PassFilter filter = event.filter ?? PassFilter.all;
      emit(currentState.copyWith(currentFilter: filter));
    }
  }

  // Handle periodic updates of queue status
  void _onStartQueueStatusUpdates(
    StartQueueStatusUpdates event,
    Emitter<MyPassesState> emit,
  ) {
    _stopQueueStatusUpdates(); // Stop any existing timer

    // Start a new timer to update queue status every 30 seconds
    _queueUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(const UpdateQueueStatus());
    });

    // Also trigger an immediate update
    add(const UpdateQueueStatus());
  }

  void _onStopQueueStatusUpdates(
    StopQueueStatusUpdates event,
    Emitter<MyPassesState> emit,
  ) {
    _stopQueueStatusUpdates();
  }

  void _stopQueueStatusUpdates() {
    _queueUpdateTimer?.cancel();
    _queueUpdateTimer = null;
  }

  // Update queue status for all active queue-based reservations
  Future<void> _onUpdateQueueStatus(
    UpdateQueueStatus event,
    Emitter<MyPassesState> emit,
  ) async {
    final currentState = state;
    if (currentState is MyPassesLoaded) {
      try {
        // Get queue-based reservations
        final queueBasedReservations = currentState.reservations
            .where((r) =>
                r.queueBased &&
                (r.status == ReservationStatus.confirmed ||
                    r.status == ReservationStatus.pending))
            .toList();

        if (queueBasedReservations.isEmpty) {
          return;
        }

        // Get all queue reservations for the current user
        final activeQueueEntries = await _queueRepository
            .getUserQueueEntries(queueBasedReservations.first.userId);

        // If there are active queue entries, update reservations with queue info
        if (activeQueueEntries.isNotEmpty) {
          final updatedReservations =
              List<ReservationModel>.from(currentState.reservations);

          for (var queueEntry in activeQueueEntries) {
            // Find the matching reservation by date and provider
            final matchIndex = updatedReservations.indexWhere((r) =>
                r.queueBased &&
                r.providerId == queueEntry['providerId'] &&
                r.reservationStartTime?.toDate().hour ==
                    queueEntry['preferredHour'] &&
                _isSameDay(r.reservationStartTime?.toDate() ?? DateTime.now(),
                    DateTime.parse(queueEntry['preferredDate'].toString())));

            if (matchIndex != -1) {
              // Update the reservation with queue status
              final updatedReservation =
                  updatedReservations[matchIndex].copyWith(
                queueStatus: QueueStatus(
                  id: queueEntry['id'],
                  position: queueEntry['queuePosition'],
                  status: queueEntry['status'],
                  estimatedEntryTime: DateTime.parse(
                      queueEntry['estimatedEntryTime'].toString()),
                  peopleAhead: queueEntry['peopleAhead'] ?? 0,
                ),
              );

              updatedReservations[matchIndex] = updatedReservation;
            }
          }

          // Emit updated state with queue information
          emit(currentState.copyWith(reservations: updatedReservations));
        }
      } catch (e) {
        // Silent error handling for background updates
        print('Error updating queue status: $e');
      }
    }
  }

  // Helper to compare if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
