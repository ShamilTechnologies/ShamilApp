part of 'payment_bloc.dart';

/// Base class for all payment events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize payments system
class InitializePayments extends PaymentEvent {
  final String? customerId;
  final bool loadSavedMethods;

  const InitializePayments({
    this.customerId,
    this.loadSavedMethods = true,
  });

  @override
  List<Object?> get props => [customerId, loadSavedMethods];
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
  final bool savePaymentMethod;

  const CreatePayment({
    required this.amount,
    required this.customer,
    required this.method,
    required this.description,
    this.preferredGateway,
    this.metadata,
    this.returnUrl,
    this.cancelUrl,
    this.savePaymentMethod = false,
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
        savePaymentMethod,
      ];
}

/// Process payment with saved method
class ProcessPaymentWithSavedMethod extends PaymentEvent {
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final PaymentMethodData savedMethod;
  final String description;
  final Map<String, dynamic>? metadata;

  const ProcessPaymentWithSavedMethod({
    required this.amount,
    required this.customer,
    required this.savedMethod,
    required this.description,
    this.metadata,
  });

  @override
  List<Object?> get props =>
      [amount, customer, savedMethod, description, metadata];
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

/// Validate payment method
class ValidatePaymentMethod extends PaymentEvent {
  final PaymentMethod method;
  final Map<String, dynamic> methodData;

  const ValidatePaymentMethod({
    required this.method,
    required this.methodData,
  });

  @override
  List<Object> get props => [method, methodData];
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

/// Retry failed payment
class RetryPayment extends PaymentEvent {
  final PaymentResponse failedPayment;
  final PaymentMethod? newMethod;

  const RetryPayment({
    required this.failedPayment,
    this.newMethod,
  });

  @override
  List<Object?> get props => [failedPayment, newMethod];
}

/// Load payment history
class LoadPaymentHistory extends PaymentEvent {
  final bool isRefresh;
  final String? customerId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadPaymentHistory({
    this.isRefresh = false,
    this.customerId,
    this.limit,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [isRefresh, customerId, limit, startDate, endDate];
}

/// Load saved payment methods
class LoadSavedPaymentMethods extends PaymentEvent {
  final String customerId;
  final bool isRefresh;

  const LoadSavedPaymentMethods({
    required this.customerId,
    this.isRefresh = false,
  });

  @override
  List<Object> get props => [customerId, isRefresh];
}

/// Save payment method
class SavePaymentMethod extends PaymentEvent {
  final PaymentMethod method;
  final Map<String, dynamic> methodData;
  final String customerId;
  final bool setAsDefault;

  const SavePaymentMethod({
    required this.method,
    required this.methodData,
    required this.customerId,
    this.setAsDefault = false,
  });

  @override
  List<Object> get props => [method, methodData, customerId, setAsDefault];
}

/// Delete saved payment method
class DeleteSavedPaymentMethod extends PaymentEvent {
  final String paymentMethodId;
  final String customerId;

  const DeleteSavedPaymentMethod({
    required this.paymentMethodId,
    required this.customerId,
  });

  @override
  List<Object> get props => [paymentMethodId, customerId];
}

/// Set default payment method
class SetDefaultPaymentMethod extends PaymentEvent {
  final String paymentMethodId;
  final String customerId;

  const SetDefaultPaymentMethod({
    required this.paymentMethodId,
    required this.customerId,
  });

  @override
  List<Object> get props => [paymentMethodId, customerId];
}

/// Load payment statistics
class LoadPaymentStatistics extends PaymentEvent {
  final String? customerId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadPaymentStatistics({
    this.customerId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [customerId, startDate, endDate];
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

/// Select saved payment method
class SelectSavedPaymentMethod extends PaymentEvent {
  final PaymentMethodData? savedMethod;

  const SelectSavedPaymentMethod(this.savedMethod);

  @override
  List<Object?> get props => [savedMethod];
}

/// Clear payment error
class ClearPaymentError extends PaymentEvent {
  const ClearPaymentError();
}

/// Clear payment success message
class ClearPaymentSuccess extends PaymentEvent {
  const ClearPaymentSuccess();
}

/// Reset payment state
class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}

/// Handle payment action (3D Secure, redirect, etc.)
class HandlePaymentAction extends PaymentEvent {
  final String actionType;
  final Map<String, dynamic> actionData;
  final String paymentId;

  const HandlePaymentAction({
    required this.actionType,
    required this.actionData,
    required this.paymentId,
  });

  @override
  List<Object> get props => [actionType, actionData, paymentId];
}

/// Payment action completed
class PaymentActionCompleted extends PaymentEvent {
  final String paymentId;
  final bool success;
  final Map<String, dynamic>? resultData;

  const PaymentActionCompleted({
    required this.paymentId,
    required this.success,
    this.resultData,
  });

  @override
  List<Object?> get props => [paymentId, success, resultData];
}
