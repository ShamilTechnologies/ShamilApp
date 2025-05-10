part of 'subscription_list_bloc.dart';

abstract class SubscriptionListState extends Equatable {
  const SubscriptionListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SubscriptionListInitial extends SubscriptionListState {}

/// Loading state
class SubscriptionListLoading extends SubscriptionListState {}

/// Loaded state with subscriptions
class SubscriptionListLoaded extends SubscriptionListState {
  final List<SubscriptionModel> subscriptions;
  final String? message;
  final String? error;

  const SubscriptionListLoaded({
    required this.subscriptions,
    this.message,
    this.error,
  });

  @override
  List<Object?> get props => [subscriptions, message, error];
}

/// Error state
class SubscriptionListError extends SubscriptionListState {
  final String message;

  const SubscriptionListError({required this.message});

  @override
  List<Object> get props => [message];
}
