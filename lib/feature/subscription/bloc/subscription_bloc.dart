// lib/feature/subscription/bloc/subscription_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For getting userId
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // For SubscriptionPlan model

// ACTION: Import the SubscriptionRepository (Create this file next)
// import 'package:shamil_mobile_app/feature/subscription/repository/subscription_repository.dart';

// ACTION: Import Payment Service if/when implemented
// import 'package:shamil_mobile_app/core/services/payment_service.dart';


part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  // ACTION: Inject dependencies
  // final SubscriptionRepository _subscriptionRepository; // Uncomment when repository is created
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final PaymentService _paymentService; // Uncomment when payment service is ready

  // Helper to get current user ID
  String? get _userId => _auth.currentUser?.uid;

  SubscriptionBloc(
    // ACTION: Add required repository parameter
    // {required SubscriptionRepository subscriptionRepository} // Uncomment when repository is created
    /*{required PaymentService paymentService}*/
  ) : //_subscriptionRepository = subscriptionRepository, // Uncomment
      // _paymentService = paymentService,
      super(SubscriptionInitial()) {

    on<SelectSubscriptionPlan>(_onSelectSubscriptionPlan);
    on<InitiateSubscriptionPayment>(_onInitiateSubscriptionPayment);
    on<ConfirmSubscriptionPurchase>(_onConfirmSubscriptionPurchase);
    on<ResetSubscriptionFlow>(_onResetSubscriptionFlow);
  }

  /// Handles the selection of a subscription plan.
  void _onSelectSubscriptionPlan(
      SelectSubscriptionPlan event, Emitter<SubscriptionState> emit) {
     print("SubscriptionBloc: Plan selected - ${event.selectedPlan.name} (ID: ${event.selectedPlan.id})");
     // Emit state indicating a plan is selected and ready for payment initiation
     emit(SubscriptionPlanSelected(plan: event.selectedPlan));
  }

  /// Handles the initiation of the payment process.
  Future<void> _onInitiateSubscriptionPayment(
      InitiateSubscriptionPayment event, Emitter<SubscriptionState> emit) async {
     final currentState = state;
     final userId = _userId;

     // Ensure a plan has been selected and user is logged in
     if (currentState is SubscriptionPlanSelected && userId != null) {
        final plan = currentState.plan;
        emit(SubscriptionPaymentProcessing(plan: plan)); // Show loading
        print("SubscriptionBloc: Initiating payment for plan - ${plan.name}");

        // --- Placeholder: Payment Gateway Integration ---
        // ACTION: Replace this block with actual Payment Gateway SDK integration.
        try {
           // Example (needs PaymentService implementation):
           // final paymentResult = await _paymentService.startPayment(
           //    amount: plan.price,
           //    currency: 'EGP', // Or fetch from config/plan
           //    description: 'Subscription: ${plan.name}',
           //    userId: userId,
           //    // Add other necessary parameters (email, providerId for metadata?)
           // );

           // Based on paymentResult:
           // if (paymentResult.isSuccess) {
           //    // If payment confirmed directly by SDK, move to backend confirmation
           //    add(ConfirmSubscriptionPurchase(paymentConfirmationToken: paymentResult.token!));
           // } else if (paymentResult.requiresRedirect) {
           //    // Handle redirection if needed (e.g., emit a specific state for UI)
           //    emit(SubscriptionRequiresRedirect(url: paymentResult.redirectUrl!, plan: plan));
           // } else {
           //    // Payment failed during initiation
           //    throw Exception(paymentResult.errorMessage ?? 'Payment initiation failed');
           // }

           // Simulate a delay and then placeholder for error/next step
           await Future.delayed(const Duration(seconds: 2));
           // Simulate payment success -> trigger confirmation
           // ACTION: Replace 'DUMMY_PAYMENT_TOKEN_123' with actual token from payment gateway
           add(const ConfirmSubscriptionPurchase(paymentConfirmationToken: 'DUMMY_PAYMENT_TOKEN_123'));
           // OR simulate failure:
           // throw Exception("Payment Gateway Not Implemented Yet");

        } catch (e) {
           print("SubscriptionBloc: Error during payment initiation - $e");
           emit(SubscriptionError(message: "Payment initiation failed: $e", plan: plan));
        }
        // --- End Placeholder ---

     } else {
         // This shouldn't happen if UI flow is correct, but handle defensively
         String errorMsg = userId == null ? "User not logged in." : "No plan selected.";
         print("SubscriptionBloc: Error - InitiateSubscriptionPayment called incorrectly: $errorMsg");
         emit(SubscriptionError(message: "$errorMsg Please try again.", plan: currentState is SubscriptionPlanSelected ? currentState.plan : null));
     }
  }

  /// Handles the confirmation step after payment is supposedly successful.
   Future<void> _onConfirmSubscriptionPurchase(
      ConfirmSubscriptionPurchase event, Emitter<SubscriptionState> emit) async {
      SubscriptionPlan? planBeingConfirmed;
      String? userId = _userId;
      // ACTION: Need providerId context here! This needs to be passed down
      // from the detail screen / options sheet or stored in the state.
      // For now, using a placeholder.
      String? providerId = "PLACEHOLDER_PROVIDER_ID"; // <<<----- ACTION: Replace this

      // Determine the plan being confirmed from the previous state
      if (state is SubscriptionPaymentProcessing) {
        planBeingConfirmed = (state as SubscriptionPaymentProcessing).plan;
      } else if (state is SubscriptionError && (state as SubscriptionError).plan != null) {
        planBeingConfirmed = (state as SubscriptionError).plan;
      }
      // Add other states if payment flow involves redirects, etc.

      // Validate context
      if (planBeingConfirmed == null || userId == null || providerId == "PLACEHOLDER_PROVIDER_ID") {
         print("SubscriptionBloc: Error - ConfirmSubscriptionPurchase missing context (Plan: ${planBeingConfirmed?.id}, User: $userId, Provider: $providerId).");
         emit(SubscriptionError(message: "Cannot confirm purchase due to missing context. Please try again.", plan: planBeingConfirmed));
         return;
      }

      // Emit loading state for backend confirmation
      emit(SubscriptionConfirmationLoading(plan: planBeingConfirmed));
      print("SubscriptionBloc: Confirming purchase with backend. Token: ${event.paymentConfirmationToken}, Plan: ${planBeingConfirmed.name}");

      // --- Placeholder: Backend Confirmation (Cloud Function Call via Repository) ---
      // ACTION: Replace this block with the actual Repository call
      try {
          // Example using a (to be created) repository method:
          // final Map<String, dynamic> result = await _subscriptionRepository.createSubscriptionOnBackend(
          //    userId: userId,
          //    providerId: providerId, // Pass the actual providerId
          //    planId: planBeingConfirmed.id,
          //    paymentToken: event.paymentConfirmationToken,
          //    // Add other relevant details like price paid if needed for server validation
          // );

          // Mock result for now:
          await Future.delayed(const Duration(seconds: 2)); // Simulate network call
          // final result = {'success': true, 'message': 'Subscription activated! (Simulated)'};
          final result = {'success': false, 'error': 'Backend Confirmation Not Implemented Yet'}; // Simulate error

          // Check the result from the backend/repository
          if (result['success'] == true) {
              print("SubscriptionBloc: Backend confirmation successful.");
              emit(SubscriptionSuccess(message: result['message'] as String? ?? "Subscription activated!"));
              // Optionally: Dispatch event to refresh user profile/data if needed
              // context.read<AuthBloc>().add(FetchUserProfile()); // Example
          } else {
              // Backend returned an error
              final errorMsg = result['error'] is String ? result['error'] as String : 'Backend confirmation failed.';
              print("SubscriptionBloc: Backend confirmation failed - $errorMsg");
              emit(SubscriptionError(message: errorMsg, plan: planBeingConfirmed));
          }

      } catch (e) {
          print("SubscriptionBloc: Error during backend confirmation - $e");
          // Handle repository/function call errors or other exceptions
          emit(SubscriptionError(message: "Subscription confirmation failed: ${e.toString()}", plan: planBeingConfirmed));
      }
      // --- End Placeholder ---
  }

  /// Resets the Bloc to its initial state.
  void _onResetSubscriptionFlow(
      ResetSubscriptionFlow event, Emitter<SubscriptionState> emit) {
      print("SubscriptionBloc: Resetting flow.");
      emit(SubscriptionInitial());
  }
}