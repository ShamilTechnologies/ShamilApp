import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_models.dart';
import '../gateways/stripe/stripe_service.dart';

part 'payment_event.dart';
part 'payment_state.dart';

/// Simplified Payment BLoC for Stripe-only operations
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final StripeService _stripeService;

  PaymentBloc({StripeService? stripeService})
      : _stripeService = stripeService ?? StripeService(),
        super(PaymentInitial()) {
    on<InitializePayments>(_onInitializePayments);
    on<CreatePayment>(_onCreatePayment);
    on<ProcessPayment>(_onProcessPayment);
    on<VerifyPayment>(_onVerifyPayment);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
  }

  /// Initialize payments
  Future<void> _onInitializePayments(
    InitializePayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    try {
      // Initialize Stripe service
      await _stripeService.initialize();

      emit(PaymentLoaded(
        availableGateways: const [PaymentGateway.stripe],
        paymentHistory: const [],
        statistics: const {},
        selectedGateway: PaymentGateway.stripe,
        selectedMethod: PaymentMethod.creditCard,
      ));
    } catch (e) {
      debugPrint('Error initializing payments: $e');
      emit(PaymentError('Failed to initialize payments: $e'));
    }
  }

  /// Create a new payment
  Future<void> _onCreatePayment(
    CreatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;
    emit(currentState.copyWith(isProcessing: true));

    try {
      PaymentResponse response;

      // Create payment based on type
      if (event.metadata?['type'] == 'reservation') {
        response = await _stripeService.createReservationPayment(
          reservationId: event.metadata?['reservation_id'] ?? '',
          amount: event.amount.amount,
          currency: event.amount.currency,
          customer: event.customer,
          description: event.description,
          metadata: event.metadata,
        );
      } else if (event.metadata?['type'] == 'subscription') {
        response = await _stripeService.createSubscriptionPayment(
          subscriptionId: event.metadata?['subscription_id'] ?? '',
          amount: event.amount.amount,
          currency: event.amount.currency,
          customer: event.customer,
          description: event.description,
          metadata: event.metadata,
        );
      } else {
        throw Exception('Unknown payment type');
      }

      emit(currentState.copyWith(
        isProcessing: false,
        lastPaymentResponse: response,
      ));

      // If payment requires user action (like 3D Secure), emit special state
      if (response.paymentUrl != null) {
        emit(PaymentRequiresAction(
          paymentResponse: response,
          actionUrl: response.paymentUrl!,
          previousState: currentState,
        ));
      }
    } catch (e) {
      debugPrint('Error creating payment: $e');
      emit(currentState.copyWith(
        isProcessing: false,
        error: 'Failed to create payment: $e',
      ));
    }
  }

  /// Process a payment (after user action)
  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded && state is! PaymentRequiresAction) return;

    PaymentLoaded currentState;
    if (state is PaymentRequiresAction) {
      currentState = (state as PaymentRequiresAction).previousState;
    } else {
      currentState = state as PaymentLoaded;
    }

    emit(currentState.copyWith(isProcessing: true));

    try {
      final response = await _stripeService.verifyPayment(
        paymentIntentId: event.paymentId,
      );

      emit(currentState.copyWith(
        isProcessing: false,
        lastPaymentResponse: response,
      ));
    } catch (e) {
      debugPrint('Error processing payment: $e');
      emit(currentState.copyWith(
        isProcessing: false,
        error: 'Failed to process payment: $e',
      ));
    }
  }

  /// Verify payment status
  Future<void> _onVerifyPayment(
    VerifyPayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;
    emit(currentState.copyWith(isProcessing: true));

    try {
      final response = await _stripeService.verifyPayment(
        paymentIntentId: event.paymentId,
      );

      emit(currentState.copyWith(
        isProcessing: false,
        lastPaymentResponse: response,
      ));
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      emit(currentState.copyWith(
        isProcessing: false,
        error: 'Failed to verify payment: $e',
      ));
    }
  }

  /// Select payment method
  Future<void> _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;
    emit(currentState.copyWith(selectedMethod: event.method));
  }
}
