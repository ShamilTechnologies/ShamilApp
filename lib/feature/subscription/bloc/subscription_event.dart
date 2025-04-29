part of 'subscription_bloc.dart';

@immutable
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

/// Event triggered when a user selects a specific subscription plan.
class SelectSubscriptionPlan extends SubscriptionEvent {
  final SubscriptionPlan selectedPlan;
  // Potentially add providerId if needed contextually
  // final String providerId;

  const SelectSubscriptionPlan({required this.selectedPlan});
  @override
  List<Object?> get props => [selectedPlan];
}

/// Event to initiate the payment process for the selected plan.
class InitiateSubscriptionPayment extends SubscriptionEvent {
   // May need payment method details, amount, currency etc. later
   const InitiateSubscriptionPayment();
}

/// Event triggered after payment gateway confirmation.
class ConfirmSubscriptionPurchase extends SubscriptionEvent {
    final String paymentConfirmationToken; // Example token from payment gateway
    // Include selectedPlanId and providerId if needed for backend function
    const ConfirmSubscriptionPurchase({required this.paymentConfirmationToken});
     @override
     List<Object?> get props => [paymentConfirmationToken];
}

/// Event to reset the subscription flow state.
class ResetSubscriptionFlow extends SubscriptionEvent {}