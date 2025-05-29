import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

// Events
abstract class ModernSubscriptionEvent extends Equatable {
  const ModernSubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptions extends ModernSubscriptionEvent {
  const LoadSubscriptions();
}

class CreateSubscription extends ModernSubscriptionEvent {
  final SubscriptionModel subscription;

  const CreateSubscription(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class CancelSubscription extends ModernSubscriptionEvent {
  final String subscriptionId;

  const CancelSubscription(this.subscriptionId);

  @override
  List<Object?> get props => [subscriptionId];
}

class RefreshSubscriptions extends ModernSubscriptionEvent {
  const RefreshSubscriptions();
}

// States
abstract class ModernSubscriptionState extends Equatable {
  const ModernSubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends ModernSubscriptionState {}

class SubscriptionLoading extends ModernSubscriptionState {
  final bool isInitialLoad;

  const SubscriptionLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

class SubscriptionLoaded extends ModernSubscriptionState {
  final List<SubscriptionModel> subscriptions;
  final String? message;

  const SubscriptionLoaded({
    required this.subscriptions,
    this.message,
  });

  // Helper getters for different subscription types
  List<SubscriptionModel> get activeSubscriptions => subscriptions
      .where((s) => s.status == SubscriptionStatus.active.statusString)
      .toList();

  List<SubscriptionModel> get expiredSubscriptions => subscriptions
      .where((s) => s.status == SubscriptionStatus.expired.statusString)
      .toList();

  List<SubscriptionModel> get cancelledSubscriptions => subscriptions
      .where((s) => s.status == SubscriptionStatus.cancelled.statusString)
      .toList();

  @override
  List<Object?> get props => [subscriptions, message];
}

class SubscriptionOperationInProgress extends ModernSubscriptionState {
  final List<SubscriptionModel> subscriptions;
  final String operationType; // 'creating', 'cancelling'
  final String? targetSubscriptionId;

  const SubscriptionOperationInProgress({
    required this.subscriptions,
    required this.operationType,
    this.targetSubscriptionId,
  });

  @override
  List<Object?> get props =>
      [subscriptions, operationType, targetSubscriptionId];
}

class SubscriptionError extends ModernSubscriptionState {
  final String message;
  final List<SubscriptionModel>? subscriptions; // Keep existing data on error

  const SubscriptionError({
    required this.message,
    this.subscriptions,
  });

  @override
  List<Object?> get props => [message, subscriptions];
}

// BLoC
class ModernSubscriptionBloc
    extends Bloc<ModernSubscriptionEvent, ModernSubscriptionState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  StreamSubscription? _subscriptionsSubscription;

  ModernSubscriptionBloc({required FirebaseDataOrchestrator dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator,
        super(SubscriptionInitial()) {
    on<LoadSubscriptions>(_onLoadSubscriptions);
    on<CreateSubscription>(_onCreateSubscription);
    on<CancelSubscription>(_onCancelSubscription);
    on<RefreshSubscriptions>(_onRefreshSubscriptions);
  }

  Future<void> _onLoadSubscriptions(
    LoadSubscriptions event,
    Emitter<ModernSubscriptionState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const SubscriptionError(message: 'User must be logged in'));
      return;
    }

    emit(const SubscriptionLoading(isInitialLoad: true));

    try {
      // Cancel any existing subscription
      await _subscriptionsSubscription?.cancel();

      // Set up real-time stream
      _subscriptionsSubscription =
          _dataOrchestrator.getUserSubscriptionsStream().listen(
        (subscriptions) {
          if (!isClosed) {
            emit(SubscriptionLoaded(subscriptions: subscriptions));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(SubscriptionError(
              message: 'Failed to load subscriptions: $error',
              subscriptions: state is SubscriptionLoaded
                  ? (state as SubscriptionLoaded).subscriptions
                  : null,
            ));
          }
        },
      );
    } catch (e) {
      emit(SubscriptionError(
          message: 'Failed to initialize subscriptions stream: $e'));
    }
  }

  Future<void> _onCreateSubscription(
    CreateSubscription event,
    Emitter<ModernSubscriptionState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const SubscriptionError(message: 'User must be logged in'));
      return;
    }

    // Show operation in progress
    final currentSubscriptions = state is SubscriptionLoaded
        ? (state as SubscriptionLoaded).subscriptions
        : <SubscriptionModel>[];

    emit(SubscriptionOperationInProgress(
      subscriptions: currentSubscriptions,
      operationType: 'creating',
    ));

    try {
      final subscriptionId =
          await _dataOrchestrator.createSubscription(event.subscription);

      // Success message will be shown when stream updates
      // The stream will automatically provide the updated list
      print('Subscription created successfully: $subscriptionId');
    } catch (e) {
      emit(SubscriptionError(
        message: 'Failed to create subscription: $e',
        subscriptions: currentSubscriptions,
      ));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<ModernSubscriptionState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const SubscriptionError(message: 'User must be logged in'));
      return;
    }

    // Show operation in progress
    final currentSubscriptions = state is SubscriptionLoaded
        ? (state as SubscriptionLoaded).subscriptions
        : <SubscriptionModel>[];

    emit(SubscriptionOperationInProgress(
      subscriptions: currentSubscriptions,
      operationType: 'cancelling',
      targetSubscriptionId: event.subscriptionId,
    ));

    try {
      await _dataOrchestrator.cancelSubscription(event.subscriptionId);

      // Success message will be shown when stream updates
      print('Subscription cancelled successfully: ${event.subscriptionId}');
    } catch (e) {
      emit(SubscriptionError(
        message: 'Failed to cancel subscription: $e',
        subscriptions: currentSubscriptions,
      ));
    }
  }

  Future<void> _onRefreshSubscriptions(
    RefreshSubscriptions event,
    Emitter<ModernSubscriptionState> emit,
  ) async {
    // For refresh, we don't need to do anything special
    // The stream will automatically provide fresh data
    if (state is SubscriptionLoaded) {
      emit(const SubscriptionLoading(isInitialLoad: false));
    }

    // The stream subscription will handle the rest
  }

  // Helper methods for UI
  bool hasActiveSubscriptions() {
    if (state is SubscriptionLoaded) {
      return (state as SubscriptionLoaded).activeSubscriptions.isNotEmpty;
    }
    return false;
  }

  int getActiveSubscriptionsCount() {
    if (state is SubscriptionLoaded) {
      return (state as SubscriptionLoaded).activeSubscriptions.length;
    }
    return 0;
  }

  List<SubscriptionModel> getSubscriptionsByProvider(String providerId) {
    if (state is SubscriptionLoaded) {
      return (state as SubscriptionLoaded)
          .subscriptions
          .where((s) => s.providerId == providerId)
          .toList();
    }
    return [];
  }

  @override
  Future<void> close() {
    _subscriptionsSubscription?.cancel();
    return super.close();
  }
}
