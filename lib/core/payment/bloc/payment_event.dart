part of 'payment_bloc.dart';

/// Base class for all payment events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize payments system
class InitializePayments extends PaymentEvent {
  const InitializePayments();
}

/// Create a new payment
class CreatePayment extends PaymentEvent {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final PaymentMethod method;
  final String description;
  final PaymentGateway? preferredGateway;
  final Map<String, dynamic>? metadata;
  final String? returnUrl;
  final String? cancelUrl;

  const CreatePayment({
    required this.amount,
    required this.customer,
    required this.method,
    required this.description,
    this.preferredGateway,
    this.metadata,
    this.returnUrl,
    this.cancelUrl,
  });

  @override
  List<Object?> get props => [
        amount,
        customer,
        method,
        description,
        preferredGateway,
        metadata,
        returnUrl,
        cancelUrl,
      ];
}

/// Process a payment (after user action)
class ProcessPayment extends PaymentEvent {
  final String paymentId;
  final PaymentGateway gateway;
  final Map<String, dynamic> paymentData;

  const ProcessPayment({
    required this.paymentId,
    required this.gateway,
    required this.paymentData,
  });

  @override
  List<Object> get props => [paymentId, gateway, paymentData];
}

/// Verify payment status
class VerifyPayment extends PaymentEvent {
  final String paymentId;
  final PaymentGateway gateway;

  const VerifyPayment({
    required this.paymentId,
    required this.gateway,
  });

  @override
  List<Object> get props => [paymentId, gateway];
}

/// Refund a payment
class RefundPayment extends PaymentEvent {
  final String paymentId;
  final PaymentGateway gateway;
  final double? amount;
  final String? reason;

  const RefundPayment({
    required this.paymentId,
    required this.gateway,
    this.amount,
    this.reason,
  });

  @override
  List<Object?> get props => [paymentId, gateway, amount, reason];
}

/// Cancel a payment
class CancelPayment extends PaymentEvent {
  final String paymentId;
  final PaymentGateway gateway;
  final String? reason;

  const CancelPayment({
    required this.paymentId,
    required this.gateway,
    this.reason,
  });

  @override
  List<Object?> get props => [paymentId, gateway, reason];
}

/// Load payment history
class LoadPaymentHistory extends PaymentEvent {
  final bool isRefresh;

  const LoadPaymentHistory({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

/// Load payment statistics
class LoadPaymentStatistics extends PaymentEvent {
  const LoadPaymentStatistics();
}

/// Payment history updated (from stream)
class PaymentHistoryUpdated extends PaymentEvent {
  final List<PaymentResponse> payments;

  const PaymentHistoryUpdated(this.payments);

  @override
  List<Object> get props => [payments];
}

/// Select payment gateway
class SelectPaymentGateway extends PaymentEvent {
  final PaymentGateway gateway;

  const SelectPaymentGateway(this.gateway);

  @override
  List<Object> get props => [gateway];
}

/// Select payment method
class SelectPaymentMethod extends PaymentEvent {
  final PaymentMethod method;

  const SelectPaymentMethod(this.method);

  @override
  List<Object> get props => [method];
}
