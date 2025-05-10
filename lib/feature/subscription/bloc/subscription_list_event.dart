part of 'subscription_list_bloc.dart';

abstract class SubscriptionListEvent extends Equatable {
  const SubscriptionListEvent();

  @override
  List<Object> get props => [];
}

/// Event to load all subscriptions for the user
class LoadSubscriptionList extends SubscriptionListEvent {
  const LoadSubscriptionList();
}

/// Event to cancel a specific subscription
class CancelSubscription extends SubscriptionListEvent {
  final String subscriptionId;

  const CancelSubscription({required this.subscriptionId});

  @override
  List<Object> get props => [subscriptionId];
}

/// Event to refresh the list of subscriptions
class SubscriptionRefresh extends SubscriptionListEvent {
  const SubscriptionRefresh();
}
