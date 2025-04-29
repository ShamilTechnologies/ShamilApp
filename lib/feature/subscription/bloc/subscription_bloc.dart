import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // For SubscriptionPlan model

// Import Firebase/Cloud Functions dependencies when needed
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_functions/cloud_functions.dart';

// Import Payment Service interface/implementation when created
// import 'package:shamil_mobile_app/core/services/payment_service.dart';


part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  // TODO: Inject dependencies (Firestore, Auth, Functions, Payment SDK Service) via constructor
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFunctions _functions = FirebaseFunctions.instance;
  // final PaymentService _paymentService;

  SubscriptionBloc(/*{required PaymentService paymentService}*/)
    : /*_paymentService = paymentService,*/ super(SubscriptionInitial()) {

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
     // Ensure a plan has been selected before proceeding
     if (currentState is SubscriptionPlanSelected) {
        emit(SubscriptionPaymentProcessing(plan: currentState.plan));
        print("SubscriptionBloc: Initiating payment for plan - ${currentState.plan.name}");

        // --- Placeholder: Payment Gateway Integration ---
        // TODO: Replace this block with actual Payment Gateway SDK integration.
        try {
           // Example:
           // final paymentResult = await _paymentService.startPayment(
           //    amount: currentState.plan.price,
           //    currency: 'EGP', // Or fetch from config/plan
           //    description: 'Subscription: ${currentState.plan.name}',
           //    // Add other necessary parameters (userId, email, etc.)
           // );

           // Based on paymentResult (e.g., success token, redirect URL, failure):
           // if (paymentResult.isSuccess) {
           //    // If payment confirmed directly by SDK, move to backend confirmation
           //    add(ConfirmSubscriptionPurchase(paymentConfirmationToken: paymentResult.token!));
           // } else if (paymentResult.requiresRedirect) {
           //    // Handle redirection if needed by the payment gateway
           //    // The UI listening to this state might trigger the redirect.
           //    emit(SubscriptionRequiresRedirect(url: paymentResult.redirectUrl!, plan: currentState.plan));
           // } else {
           //    // Payment failed during initiation
           //    throw Exception(paymentResult.errorMessage ?? 'Payment initiation failed');
           // }

           // Simulate a delay and then placeholder for error/next step
           await Future.delayed(const Duration(seconds: 2));
           // Simulate payment success (replace with actual logic) -> trigger confirmation
           // add(const ConfirmSubscriptionPurchase(paymentConfirmationToken: 'DUMMY_PAYMENT_TOKEN_123'));
           // OR simulate failure:
           throw Exception("Payment Gateway Not Implemented Yet");

        } catch (e) {
           print("SubscriptionBloc: Error during payment initiation - $e");
           emit(SubscriptionError(message: "Payment initiation failed: $e", plan: currentState.plan));
        }
        // --- End Placeholder ---

     } else {
         // This shouldn't happen if UI flow is correct, but handle defensively
         print("SubscriptionBloc: Error - InitiateSubscriptionPayment called without a plan selected.");
         emit(const SubscriptionError(message: "No plan selected to initiate payment."));
     }
  }

  /// Handles the confirmation step after payment is supposedly successful.
   Future<void> _onConfirmSubscriptionPurchase(
      ConfirmSubscriptionPurchase event, Emitter<SubscriptionState> emit) async {
      SubscriptionPlan? planBeingConfirmed;

      // Determine the plan being confirmed from the previous state
      if (state is SubscriptionPaymentProcessing) {
        planBeingConfirmed = (state as SubscriptionPaymentProcessing).plan;
      } else if (state is SubscriptionError && (state as SubscriptionError).plan != null) {
        // Allow retry/confirmation if coming from an error state that had plan context
        planBeingConfirmed = (state as SubscriptionError).plan;
      }
      // Add other states if payment flow involves redirects, etc.
      // else if (state is SubscriptionRequiresRedirect) { planBeingConfirmed = state.plan; }

      if(planBeingConfirmed != null){
         // Emit loading state for backend confirmation
         emit(SubscriptionConfirmationLoading(plan: planBeingConfirmed));
         print("SubscriptionBloc: Confirming purchase with backend. Token: ${event.paymentConfirmationToken}, Plan: ${planBeingConfirmed.name}");

         // --- Placeholder: Backend Confirmation (Cloud Function Call) ---
         // TODO: Replace this block with the actual Cloud Functions call
         try {
            // final user = _auth.currentUser;
            // if (user == null) throw Exception("User not authenticated.");

            // final HttpsCallable callable = _functions.httpsCallable('createSubscription'); // Ensure function name matches
            // final result = await callable.call(<String, dynamic>{
            //    'paymentToken': event.paymentConfirmationToken, // Token from payment gateway
            //    'planId': planBeingConfirmed.id, // ID of the selected plan
            //    'providerId': 'PROVIDER_ID_HERE', // <<< IMPORTANT: Need Provider ID context here! Pass it down or fetch it.
            //    'userId': user.uid, // Pass user ID
            //    // Add any other necessary data (e.g., price, currency for server-side validation)
            // });

            // // Check the result from the Cloud Function
            // if (result.data['success'] == true) {
            //     print("SubscriptionBloc: Backend confirmation successful.");
            //     emit(const SubscriptionSuccess(message: "Subscription activated!"));
            //     // Optionally: Dispatch event to refresh user profile/data if needed
            //     // context.read<AuthBloc>().add(FetchUserProfile());
            // } else {
            //     // Backend returned an error
            //     print("SubscriptionBloc: Backend confirmation failed - ${result.data['error']}");
            //     emit(SubscriptionError(message: result.data['error'] ?? 'Backend confirmation failed.', plan: planBeingConfirmed));
            // }

            // Simulate a delay and then placeholder for error/success
            await Future.delayed(const Duration(seconds: 2));
            // Simulate Success:
            // emit(const SubscriptionSuccess(message: "Subscription activated! (Simulated)"));
            // OR Simulate Failure:
            throw Exception("Backend Confirmation Not Implemented Yet");

         } catch (e) {
            print("SubscriptionBloc: Error during backend confirmation - $e");
            // Handle Cloud Function call errors or other exceptions
            emit(SubscriptionError(message: "Subscription confirmation failed: $e", plan: planBeingConfirmed));
         }
         // --- End Placeholder ---

      } else {
         // Should not happen if state flow is correct
         print("SubscriptionBloc: Error - ConfirmSubscriptionPurchase called without plan context.");
         emit(const SubscriptionError(message: "Cannot confirm purchase without plan context. Please select a plan again."));
      }
  }

  /// Resets the Bloc to its initial state.
  void _onResetSubscriptionFlow(
      ResetSubscriptionFlow event, Emitter<SubscriptionState> emit) {
      print("SubscriptionBloc: Resetting flow.");
      emit(SubscriptionInitial());
  }
}