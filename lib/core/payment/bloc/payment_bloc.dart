import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_models.dart';
import '../gateways/stripe/stripe_service.dart';
import '../payment_orchestrator.dart';

part 'payment_event.dart';
part 'payment_state.dart';

/// Comprehensive Payment BLoC for managing all payment operations
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentOrchestrator _paymentOrchestrator;
  final StripeService _stripeService;
  StreamSubscription? _paymentHistorySubscription;

  PaymentBloc({
    PaymentOrchestrator? paymentOrchestrator,
    StripeService? stripeService,
  })  : _paymentOrchestrator = paymentOrchestrator ?? PaymentOrchestrator(),
        _stripeService = stripeService ?? StripeService(),
        super(const PaymentInitial()) {
    // Register event handlers
    on<InitializePayments>(_onInitializePayments);
    on<CreatePayment>(_onCreatePayment);
    on<ProcessPaymentWithSavedMethod>(_onProcessPaymentWithSavedMethod);
    on<ProcessPayment>(_onProcessPayment);
    on<ValidatePaymentMethod>(_onValidatePaymentMethod);
    on<VerifyPayment>(_onVerifyPayment);
    on<RefundPayment>(_onRefundPayment);
    on<CancelPayment>(_onCancelPayment);
    on<RetryPayment>(_onRetryPayment);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<LoadSavedPaymentMethods>(_onLoadSavedPaymentMethods);
    on<SavePaymentMethod>(_onSavePaymentMethod);
    on<DeleteSavedPaymentMethod>(_onDeleteSavedPaymentMethod);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
    on<LoadPaymentStatistics>(_onLoadPaymentStatistics);
    on<PaymentHistoryUpdated>(_onPaymentHistoryUpdated);
    on<SelectPaymentGateway>(_onSelectPaymentGateway);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<SelectSavedPaymentMethod>(_onSelectSavedPaymentMethod);
    on<ClearPaymentError>(_onClearPaymentError);
    on<ClearPaymentSuccess>(_onClearPaymentSuccess);
    on<ResetPaymentState>(_onResetPaymentState);
    on<HandlePaymentAction>(_onHandlePaymentAction);
    on<PaymentActionCompleted>(_onPaymentActionCompleted);
  }

  /// Initialize payments system
  Future<void> _onInitializePayments(
    InitializePayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentInitializing());

    try {
      // Initialize payment orchestrator and Stripe service
      await _paymentOrchestrator.initialize();
      await _stripeService.initialize();

      debugPrint('✅ Payment system initialized successfully');

      // Create initial loaded state
      final initialState = PaymentLoaded(
        availableGateways: const [PaymentGateway.stripe],
        paymentHistory: const [],
        savedPaymentMethods: const [],
        statistics: const {},
        selectedGateway: PaymentGateway.stripe,
        selectedMethod: PaymentMethod.creditCard,
      );

      emit(initialState);

      // Load saved payment methods if customer ID provided
      if (event.customerId != null && event.loadSavedMethods) {
        add(LoadSavedPaymentMethods(customerId: event.customerId!));
      }

      // Load payment statistics
      add(LoadPaymentStatistics(customerId: event.customerId));
    } catch (e) {
      debugPrint('❌ Error initializing payments: $e');
      emit(PaymentError(
        'Failed to initialize payment system. Please try again.',
        code: 'INIT_ERROR',
        isCritical: true,
      ));
    }
  }

  /// Create a new payment
  Future<void> _onCreatePayment(
    CreatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    // Create payment request
    final paymentRequest = PaymentRequest(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      amount: event.amount,
      customer: event.customer,
      method: event.method,
      gateway: event.preferredGateway ?? PaymentGateway.stripe,
      description: event.description,
      metadata: {
        'save_payment_method': event.savePaymentMethod,
        ...?event.metadata,
      },
      createdAt: DateTime.now(),
    );

    emit(PaymentProcessing(
      request: paymentRequest,
      previousState: currentState,
      processingMessage: 'Creating payment...',
    ));

    try {
      final response =
          await _paymentOrchestrator.processPayment(paymentRequest);

      if (response.isSuccessful) {
        emit(PaymentSuccess(
          paymentResponse: response,
          previousState: currentState.copyWith(
            lastPaymentResponse: response,
            paymentHistory: [response, ...currentState.paymentHistory],
          ),
          successMessage: 'Payment completed successfully!',
        ));

        // Save payment method if requested
        if (event.savePaymentMethod && response.gatewayResponse != null) {
          add(SavePaymentMethod(
            method: event.method,
            methodData: response.gatewayResponse!,
            customerId: event.customer.id,
          ));
        }
      } else {
        // Check if payment requires action
        if (response.paymentUrl != null) {
          emit(PaymentRequiresAction(
            paymentResponse: response,
            actionUrl: response.paymentUrl!,
            previousState: currentState,
            actionType: response.gatewayResponse?['action_type'] ?? '3d_secure',
            actionData: response.gatewayResponse,
          ));
        } else {
          emit(PaymentFailure(
            errorMessage: response.errorMessage ?? 'Payment failed',
            errorCode: response.errorCode,
            failedPaymentResponse: response,
            previousState: currentState,
            isRetryable: _isRetryableError(response.errorCode),
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating payment: $e');
      emit(PaymentFailure(
        errorMessage: 'Failed to process payment. Please try again.',
        previousState: currentState,
        isRetryable: true,
      ));
    }
  }

  /// Process payment with saved method
  Future<void> _onProcessPaymentWithSavedMethod(
    ProcessPaymentWithSavedMethod event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    final paymentRequest = PaymentRequest(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      amount: event.amount,
      customer: event.customer,
      method: PaymentMethod.creditCard,
      gateway: PaymentGateway.stripe,
      description: event.description,
      metadata: {
        'payment_method_id': event.savedMethod.id,
        'use_saved_method': true,
        ...?event.metadata,
      },
      createdAt: DateTime.now(),
    );

    emit(PaymentProcessing(
      request: paymentRequest,
      previousState: currentState,
      processingMessage: 'Processing payment with saved method...',
    ));

    try {
      final response =
          await _paymentOrchestrator.processPayment(paymentRequest);

      if (response.isSuccessful) {
        emit(PaymentSuccess(
          paymentResponse: response,
          previousState: currentState.copyWith(
            lastPaymentResponse: response,
            paymentHistory: [response, ...currentState.paymentHistory],
          ),
        ));
      } else {
        emit(PaymentFailure(
          errorMessage: response.errorMessage ?? 'Payment failed',
          errorCode: response.errorCode,
          failedPaymentResponse: response,
          previousState: currentState,
          isRetryable: _isRetryableError(response.errorCode),
        ));
      }
    } catch (e) {
      debugPrint('❌ Error processing payment with saved method: $e');
      emit(PaymentFailure(
        errorMessage: 'Failed to process payment. Please try again.',
        previousState: currentState,
        isRetryable: true,
      ));
    }
  }

  /// Validate payment method
  Future<void> _onValidatePaymentMethod(
    ValidatePaymentMethod event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    emit(PaymentMethodValidating(
      method: event.method,
      previousState: currentState,
    ));

    try {
      // Simulate validation logic
      await Future.delayed(const Duration(milliseconds: 500));

      // Basic validation rules
      final errors = <String>[];

      if (event.method == PaymentMethod.creditCard) {
        if (event.methodData['card_number']?.isEmpty ?? true) {
          errors.add('Card number is required');
        }
        if (event.methodData['expiry_date']?.isEmpty ?? true) {
          errors.add('Expiry date is required');
        }
        if (event.methodData['cvc']?.isEmpty ?? true) {
          errors.add('CVC is required');
        }
        if (event.methodData['cardholder_name']?.isEmpty ?? true) {
          errors.add('Cardholder name is required');
        }
      }

      if (errors.isNotEmpty) {
        emit(PaymentMethodInvalid(
          method: event.method,
          errorMessage: errors.first,
          fieldErrors: errors,
          previousState: currentState,
        ));
      } else {
        emit(PaymentMethodValid(
          method: event.method,
          validationData: event.methodData,
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(PaymentMethodInvalid(
        method: event.method,
        errorMessage: 'Validation failed. Please check your details.',
        previousState: currentState,
      ));
    }
  }

  /// Load saved payment methods
  Future<void> _onLoadSavedPaymentMethods(
    LoadSavedPaymentMethods event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    if (!event.isRefresh) {
      emit(currentState.copyWith(isLoadingSavedMethods: true));
    }

    try {
      final savedMethods = await _stripeService.getSavedPaymentMethods(
        customerId: event.customerId,
      );

      emit(currentState.copyWith(
        savedPaymentMethods: savedMethods,
        isLoadingSavedMethods: false,
      ));
    } catch (e) {
      debugPrint('❌ Error loading saved payment methods: $e');
      emit(currentState.copyWith(
        isLoadingSavedMethods: false,
        error: 'Failed to load saved payment methods',
      ));
    }
  }

  /// Load payment history
  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    if (!event.isRefresh) {
      emit(currentState.copyWith(isLoadingHistory: true));
    }

    try {
      final history = await _paymentOrchestrator.getPaymentHistory(
        event.customerId ?? 'default_customer',
      );

      emit(currentState.copyWith(
        paymentHistory: history,
        isLoadingHistory: false,
      ));
    } catch (e) {
      debugPrint('❌ Error loading payment history: $e');
      emit(currentState.copyWith(
        isLoadingHistory: false,
        error: 'Failed to load payment history',
      ));
    }
  }

  /// Load payment statistics
  Future<void> _onLoadPaymentStatistics(
    LoadPaymentStatistics event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is! PaymentLoaded) return;

    final currentState = state as PaymentLoaded;

    try {
      final statistics = await _paymentOrchestrator.getPaymentStatistics(
        event.customerId ?? 'default_customer',
      );

      emit(currentState.copyWith(statistics: statistics));
    } catch (e) {
      debugPrint('❌ Error loading payment statistics: $e');
      // Don't emit error for statistics as it's not critical
    }
  }

  /// Handle other events with simplified implementations
  Future<void> _onProcessPayment(
      ProcessPayment event, Emitter<PaymentState> emit) async {
    // Implementation for processing payment after user action
  }

  Future<void> _onVerifyPayment(
      VerifyPayment event, Emitter<PaymentState> emit) async {
    // Implementation for verifying payment status
  }

  Future<void> _onRefundPayment(
      RefundPayment event, Emitter<PaymentState> emit) async {
    // Implementation for refunding payment
  }

  Future<void> _onCancelPayment(
      CancelPayment event, Emitter<PaymentState> emit) async {
    // Implementation for cancelling payment
  }

  Future<void> _onRetryPayment(
      RetryPayment event, Emitter<PaymentState> emit) async {
    // Implementation for retrying failed payment
  }

  Future<void> _onSavePaymentMethod(
      SavePaymentMethod event, Emitter<PaymentState> emit) async {
    // Implementation for saving payment method
  }

  Future<void> _onDeleteSavedPaymentMethod(
      DeleteSavedPaymentMethod event, Emitter<PaymentState> emit) async {
    // Implementation for deleting saved payment method
  }

  Future<void> _onSetDefaultPaymentMethod(
      SetDefaultPaymentMethod event, Emitter<PaymentState> emit) async {
    // Implementation for setting default payment method
  }

  Future<void> _onPaymentHistoryUpdated(
      PaymentHistoryUpdated event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(paymentHistory: event.payments));
    }
  }

  Future<void> _onSelectPaymentGateway(
      SelectPaymentGateway event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(selectedGateway: event.gateway));
    }
  }

  Future<void> _onSelectPaymentMethod(
      SelectPaymentMethod event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(
        selectedMethod: event.method,
        clearSelectedSavedMethod: true,
      ));
    }
  }

  Future<void> _onSelectSavedPaymentMethod(
      SelectSavedPaymentMethod event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(selectedSavedMethod: event.savedMethod));
    }
  }

  Future<void> _onClearPaymentError(
      ClearPaymentError event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(clearError: true));
    }
  }

  Future<void> _onClearPaymentSuccess(
      ClearPaymentSuccess event, Emitter<PaymentState> emit) async {
    if (state is PaymentLoaded) {
      final currentState = state as PaymentLoaded;
      emit(currentState.copyWith(clearSuccess: true));
    }
  }

  Future<void> _onResetPaymentState(
      ResetPaymentState event, Emitter<PaymentState> emit) async {
    emit(const PaymentInitial());
  }

  Future<void> _onHandlePaymentAction(
      HandlePaymentAction event, Emitter<PaymentState> emit) async {
    // Implementation for handling payment actions (3D Secure, etc.)
  }

  Future<void> _onPaymentActionCompleted(
      PaymentActionCompleted event, Emitter<PaymentState> emit) async {
    // Implementation for handling completed payment actions
  }

  /// Helper method to determine if an error is retryable
  bool _isRetryableError(String? errorCode) {
    if (errorCode == null) return true;

    final nonRetryableErrors = [
      'card_declined',
      'insufficient_funds',
      'expired_card',
      'incorrect_cvc',
      'invalid_number',
    ];

    return !nonRetryableErrors.contains(errorCode.toLowerCase());
  }

  @override
  Future<void> close() {
    _paymentHistorySubscription?.cancel();
    return super.close();
  }
}
