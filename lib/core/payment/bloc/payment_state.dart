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

/// Payment system is loading
class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

/// Payment system loaded successfully
class PaymentLoaded extends PaymentState {
  final List<PaymentGateway> availableGateways;
  final List<PaymentResponse> paymentHistory;
  final Map<String, dynamic> statistics;
  final PaymentGateway selectedGateway;
  final PaymentMethod selectedMethod;
  final bool isProcessing;
  final bool isLoadingHistory;
  final PaymentResponse? lastPaymentResponse;
  final String? error;

  const PaymentLoaded({
    required this.availableGateways,
    required this.paymentHistory,
    required this.statistics,
    required this.selectedGateway,
    required this.selectedMethod,
    this.isProcessing = false,
    this.isLoadingHistory = false,
    this.lastPaymentResponse,
    this.error,
  });

  PaymentLoaded copyWith({
    List<PaymentGateway>? availableGateways,
    List<PaymentResponse>? paymentHistory,
    Map<String, dynamic>? statistics,
    PaymentGateway? selectedGateway,
    PaymentMethod? selectedMethod,
    bool? isProcessing,
    bool? isLoadingHistory,
    PaymentResponse? lastPaymentResponse,
    String? error,
  }) {
    return PaymentLoaded(
      availableGateways: availableGateways ?? this.availableGateways,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      statistics: statistics ?? this.statistics,
      selectedGateway: selectedGateway ?? this.selectedGateway,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      lastPaymentResponse: lastPaymentResponse ?? this.lastPaymentResponse,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        availableGateways,
        paymentHistory,
        statistics,
        selectedGateway,
        selectedMethod,
        isProcessing,
        isLoadingHistory,
        lastPaymentResponse,
        error,
      ];
}

/// Payment requires user action (3D Secure, redirect, etc.)
class PaymentRequiresAction extends PaymentState {
  final PaymentResponse paymentResponse;
  final String actionUrl;
  final PaymentLoaded previousState;

  const PaymentRequiresAction({
    required this.paymentResponse,
    required this.actionUrl,
    required this.previousState,
  });

  @override
  List<Object> get props => [paymentResponse, actionUrl, previousState];
}

/// Payment error state
class PaymentError extends PaymentState {
  final String message;
  final PaymentLoaded? previousState;

  const PaymentError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}
