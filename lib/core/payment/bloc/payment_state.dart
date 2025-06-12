part of 'payment_bloc.dart';

/// Base class for all payment states
abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Initial payment state
class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

/// Payment system is initializing
class PaymentInitializing extends PaymentState {
  final String message;

  const PaymentInitializing({this.message = 'Initializing payment system...'});

  @override
  List<Object?> get props => [message];
}

/// Payment system is loading
class PaymentLoading extends PaymentState {
  final String loadingMessage;
  final double? progress;

  const PaymentLoading({
    this.loadingMessage = 'Loading...',
    this.progress,
  });

  @override
  List<Object?> get props => [loadingMessage, progress];
}

/// Payment system loaded successfully
class PaymentLoaded extends PaymentState {
  final List<PaymentGateway> availableGateways;
  final List<PaymentResponse> paymentHistory;
  final List<PaymentMethodData> savedPaymentMethods;
  final Map<String, dynamic> statistics;
  final PaymentGateway selectedGateway;
  final PaymentMethod selectedMethod;
  final PaymentMethodData? selectedSavedMethod;
  final bool isProcessing;
  final bool isLoadingHistory;
  final bool isLoadingSavedMethods;
  final PaymentResponse? lastPaymentResponse;
  final String? error;
  final String? successMessage;

  const PaymentLoaded({
    required this.availableGateways,
    required this.paymentHistory,
    required this.savedPaymentMethods,
    required this.statistics,
    required this.selectedGateway,
    required this.selectedMethod,
    this.selectedSavedMethod,
    this.isProcessing = false,
    this.isLoadingHistory = false,
    this.isLoadingSavedMethods = false,
    this.lastPaymentResponse,
    this.error,
    this.successMessage,
  });

  PaymentLoaded copyWith({
    List<PaymentGateway>? availableGateways,
    List<PaymentResponse>? paymentHistory,
    List<PaymentMethodData>? savedPaymentMethods,
    Map<String, dynamic>? statistics,
    PaymentGateway? selectedGateway,
    PaymentMethod? selectedMethod,
    PaymentMethodData? selectedSavedMethod,
    bool? isProcessing,
    bool? isLoadingHistory,
    bool? isLoadingSavedMethods,
    PaymentResponse? lastPaymentResponse,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelectedSavedMethod = false,
  }) {
    return PaymentLoaded(
      availableGateways: availableGateways ?? this.availableGateways,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      savedPaymentMethods: savedPaymentMethods ?? this.savedPaymentMethods,
      statistics: statistics ?? this.statistics,
      selectedGateway: selectedGateway ?? this.selectedGateway,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      selectedSavedMethod: clearSelectedSavedMethod
          ? null
          : (selectedSavedMethod ?? this.selectedSavedMethod),
      isProcessing: isProcessing ?? this.isProcessing,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingSavedMethods:
          isLoadingSavedMethods ?? this.isLoadingSavedMethods,
      lastPaymentResponse: lastPaymentResponse ?? this.lastPaymentResponse,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        availableGateways,
        paymentHistory,
        savedPaymentMethods,
        statistics,
        selectedGateway,
        selectedMethod,
        selectedSavedMethod,
        isProcessing,
        isLoadingHistory,
        isLoadingSavedMethods,
        lastPaymentResponse,
        error,
        successMessage,
      ];
}

/// Payment is being processed
class PaymentProcessing extends PaymentState {
  final PaymentRequest request;
  final String processingMessage;
  final double? progress;
  final PaymentLoaded previousState;

  const PaymentProcessing({
    required this.request,
    required this.previousState,
    this.processingMessage = 'Processing payment...',
    this.progress,
  });

  @override
  List<Object?> get props =>
      [request, processingMessage, progress, previousState];
}

/// Payment requires user action (3D Secure, redirect, etc.)
class PaymentRequiresAction extends PaymentState {
  final PaymentResponse paymentResponse;
  final String actionUrl;
  final String actionType;
  final Map<String, dynamic>? actionData;
  final PaymentLoaded previousState;

  const PaymentRequiresAction({
    required this.paymentResponse,
    required this.actionUrl,
    required this.previousState,
    this.actionType = '3d_secure',
    this.actionData,
  });

  @override
  List<Object?> get props =>
      [paymentResponse, actionUrl, actionType, actionData, previousState];
}

/// Payment completed successfully
class PaymentSuccess extends PaymentState {
  final PaymentResponse paymentResponse;
  final String successMessage;
  final PaymentLoaded previousState;

  const PaymentSuccess({
    required this.paymentResponse,
    required this.previousState,
    this.successMessage = 'Payment completed successfully!',
  });

  @override
  List<Object> get props => [paymentResponse, successMessage, previousState];
}

/// Payment failed
class PaymentFailure extends PaymentState {
  final String errorMessage;
  final String? errorCode;
  final PaymentResponse? failedPaymentResponse;
  final PaymentLoaded previousState;
  final bool isRetryable;

  const PaymentFailure({
    required this.errorMessage,
    required this.previousState,
    this.errorCode,
    this.failedPaymentResponse,
    this.isRetryable = true,
  });

  @override
  List<Object?> get props => [
        errorMessage,
        errorCode,
        failedPaymentResponse,
        previousState,
        isRetryable,
      ];
}

/// Payment was cancelled by user
class PaymentCancelled extends PaymentState {
  final String reason;
  final PaymentLoaded previousState;

  const PaymentCancelled({
    required this.previousState,
    this.reason = 'Payment cancelled by user',
  });

  @override
  List<Object> get props => [reason, previousState];
}

/// Payment method validation state
class PaymentMethodValidating extends PaymentState {
  final PaymentMethod method;
  final String validationMessage;
  final PaymentLoaded previousState;

  const PaymentMethodValidating({
    required this.method,
    required this.previousState,
    this.validationMessage = 'Validating payment method...',
  });

  @override
  List<Object> get props => [method, validationMessage, previousState];
}

/// Payment method validation success
class PaymentMethodValid extends PaymentState {
  final PaymentMethod method;
  final Map<String, dynamic> validationData;
  final PaymentLoaded previousState;

  const PaymentMethodValid({
    required this.method,
    required this.validationData,
    required this.previousState,
  });

  @override
  List<Object> get props => [method, validationData, previousState];
}

/// Payment method validation failed
class PaymentMethodInvalid extends PaymentState {
  final PaymentMethod method;
  final String errorMessage;
  final List<String> fieldErrors;
  final PaymentLoaded previousState;

  const PaymentMethodInvalid({
    required this.method,
    required this.errorMessage,
    required this.previousState,
    this.fieldErrors = const [],
  });

  @override
  List<Object> get props => [method, errorMessage, fieldErrors, previousState];
}

/// Payment error state
class PaymentError extends PaymentState {
  final String message;
  final String? code;
  final PaymentLoaded? previousState;
  final bool isCritical;

  const PaymentError(
    this.message, {
    this.code,
    this.previousState,
    this.isCritical = false,
  });

  @override
  List<Object?> get props => [message, code, previousState, isCritical];
}
