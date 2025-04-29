part of 'subscription_bloc.dart';

@immutable
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

/// Initial state, no plan selected.
class SubscriptionInitial extends SubscriptionState {}

/// State when a plan has been selected, ready for payment initiation.
class SubscriptionPlanSelected extends SubscriptionState {
  final SubscriptionPlan plan;
  const SubscriptionPlanSelected({required this.plan});
  @override
  List<Object?> get props => [plan];
}

/// State indicating payment is being processed (e.g., waiting for gateway redirect/response).
class SubscriptionPaymentProcessing extends SubscriptionState {
    final SubscriptionPlan plan; // Keep track of the plan being processed
    const SubscriptionPaymentProcessing({required this.plan});
     @override
     List<Object?> get props => [plan];
}

/// State indicating the subscription purchase is being confirmed with the backend.
class SubscriptionConfirmationLoading extends SubscriptionState {
   final SubscriptionPlan plan; // Keep track of the plan being confirmed
   const SubscriptionConfirmationLoading({required this.plan});
    @override
    List<Object?> get props => [plan];
}


/// State indicating the subscription was successfully purchased and created.
class SubscriptionSuccess extends SubscriptionState {
    // Optionally include the created Subscription details if needed
    // final UserSubscription subscription;
    final String message;
    const SubscriptionSuccess({this.message = "Subscription successful!"});
     @override
     List<Object?> get props => [message];
}

/// State indicating an error occurred during the subscription process.
class SubscriptionError extends SubscriptionState {
  final String message;
  final SubscriptionPlan? plan; // Optionally include the plan during which error occurred
  const SubscriptionError({required this.message, this.plan});
  @override
  List<Object?> get props => [message, plan];
}