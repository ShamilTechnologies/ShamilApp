import 'package:equatable/equatable.dart';

/// Enum for different payment methods
enum PaymentMethod {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  wallet,
  vodafoneCash,
  orangeMoney,
  etisalatCash,
  bankTransfer,
  fawry,
  cash,
}

/// Enum for payment method types (for setup intents)
enum PaymentMethodType {
  card,
  applePay,
  googlePay,
}

/// Enum for payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

/// Enum for supported currencies
enum Currency {
  egp, // Egyptian Pound
  usd, // US Dollar
  eur, // Euro
  sar, // Saudi Riyal
  aed, // UAE Dirham
}

/// Extension to add currency symbol getter
extension CurrencyExtension on Currency {
  String get symbol {
    switch (this) {
      case Currency.egp:
        return 'EGP';
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.sar:
        return 'SAR';
      case Currency.aed:
        return 'AED';
    }
  }
}

/// Enum for payment gateway providers (Stripe only)
enum PaymentGateway {
  stripe,
}

/// Enum for payment environments
enum PaymentEnvironment {
  development,
  staging,
  production,
}

/// Payment amount model
class PaymentAmount extends Equatable {
  final double amount;
  final Currency currency;
  final double? taxAmount;
  final double? discountAmount;
  final double? shippingAmount;

  const PaymentAmount({
    required this.amount,
    required this.currency,
    this.taxAmount,
    this.discountAmount,
    this.shippingAmount,
  });

  double get totalAmount {
    return amount +
        (taxAmount ?? 0) +
        (shippingAmount ?? 0) -
        (discountAmount ?? 0);
  }

  String get currencySymbol {
    switch (currency) {
      case Currency.egp:
        return 'EGP';
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.sar:
        return 'SAR';
      case Currency.aed:
        return 'AED';
    }
  }

  /// Add toStringAsFixed method for amount formatting
  String toStringAsFixed(int fractionDigits) {
    return totalAmount.toStringAsFixed(fractionDigits);
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency.name,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'shippingAmount': shippingAmount,
      'totalAmount': totalAmount,
    };
  }

  factory PaymentAmount.fromJson(Map<String, dynamic> json) {
    return PaymentAmount(
      amount: (json['amount'] as num).toDouble(),
      currency: Currency.values.firstWhere(
        (c) => c.name == json['currency'],
        orElse: () => Currency.egp,
      ),
      taxAmount: json['taxAmount']?.toDouble(),
      discountAmount: json['discountAmount']?.toDouble(),
      shippingAmount: json['shippingAmount']?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        amount,
        currency,
        taxAmount,
        discountAmount,
        shippingAmount,
      ];
}

/// Customer information for payment
class PaymentCustomer extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final PaymentAddress? billingAddress;
  final PaymentAddress? shippingAddress;

  const PaymentCustomer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.billingAddress,
    this.shippingAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'billingAddress': billingAddress?.toJson(),
      'shippingAddress': shippingAddress?.toJson(),
    };
  }

  factory PaymentCustomer.fromJson(Map<String, dynamic> json) {
    return PaymentCustomer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      billingAddress: json['billingAddress'] != null
          ? PaymentAddress.fromJson(json['billingAddress'])
          : null,
      shippingAddress: json['shippingAddress'] != null
          ? PaymentAddress.fromJson(json['shippingAddress'])
          : null,
    );
  }

  /// Add copyWith method for creating modified copies
  PaymentCustomer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    PaymentAddress? billingAddress,
    PaymentAddress? shippingAddress,
  }) {
    return PaymentCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, email, phone, billingAddress, shippingAddress];
}

/// Address model for payment
class PaymentAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  const PaymentAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory PaymentAddress.fromJson(Map<String, dynamic> json) {
    return PaymentAddress(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
    );
  }

  @override
  List<Object> get props => [street, city, state, country, postalCode];
}

/// Payment request model
class PaymentRequest extends Equatable {
  final String id;
  final PaymentAmount amount;
  final PaymentCustomer customer;
  final PaymentMethod method;
  final PaymentGateway gateway;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? returnUrl;
  final String? cancelUrl;
  final DateTime createdAt;
  final String? paymentMethodId;
  final bool savePaymentMethod;

  const PaymentRequest({
    required this.id,
    required this.amount,
    required this.customer,
    required this.method,
    required this.gateway,
    required this.description,
    this.metadata,
    this.returnUrl,
    this.cancelUrl,
    required this.createdAt,
    this.paymentMethodId,
    this.savePaymentMethod = false,
  });

  /// Add currency getter for convenience
  Currency get currency => amount.currency;

  /// Add copyWith method
  PaymentRequest copyWith({
    String? id,
    PaymentAmount? amount,
    PaymentCustomer? customer,
    PaymentMethod? method,
    PaymentGateway? gateway,
    String? description,
    Map<String, dynamic>? metadata,
    String? returnUrl,
    String? cancelUrl,
    DateTime? createdAt,
    String? paymentMethodId,
    bool? savePaymentMethod,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      customer: customer ?? this.customer,
      method: method ?? this.method,
      gateway: gateway ?? this.gateway,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      returnUrl: returnUrl ?? this.returnUrl,
      cancelUrl: cancelUrl ?? this.cancelUrl,
      createdAt: createdAt ?? this.createdAt,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      savePaymentMethod: savePaymentMethod ?? this.savePaymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount.toJson(),
      'customer': customer.toJson(),
      'method': method.name,
      'gateway': gateway.name,
      'description': description,
      'metadata': metadata,
      'returnUrl': returnUrl,
      'cancelUrl': cancelUrl,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethodId': paymentMethodId,
      'savePaymentMethod': savePaymentMethod,
    };
  }

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'],
      amount: PaymentAmount.fromJson(json['amount']),
      customer: PaymentCustomer.fromJson(json['customer']),
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      gateway: PaymentGateway.values.firstWhere(
        (g) => g.name == json['gateway'],
        orElse: () => PaymentGateway.stripe,
      ),
      description: json['description'],
      metadata: json['metadata'],
      returnUrl: json['returnUrl'],
      cancelUrl: json['cancelUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      paymentMethodId: json['paymentMethodId'],
      savePaymentMethod: json['savePaymentMethod'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        customer,
        method,
        gateway,
        description,
        metadata,
        returnUrl,
        cancelUrl,
        createdAt,
        paymentMethodId,
        savePaymentMethod,
      ];
}

/// Payment response model
class PaymentResponse extends Equatable {
  final String id;
  final PaymentStatus status;
  final double amount;
  final Currency currency;
  final PaymentGateway gateway;
  final String? transactionId;
  final String? gatewayTransactionId;
  final String? paymentUrl;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? gatewayResponse;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final DateTime? completedAt;

  const PaymentResponse({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    required this.gateway,
    this.transactionId,
    this.gatewayTransactionId,
    this.paymentUrl,
    this.errorMessage,
    this.errorCode,
    this.gatewayResponse,
    this.metadata,
    required this.timestamp,
    this.completedAt,
  });

  bool get isSuccessful => status == PaymentStatus.completed;
  bool get isSuccessfulOrProcessing =>
      status == PaymentStatus.completed || status == PaymentStatus.processing;
  bool get isPending =>
      status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get isFailed =>
      status == PaymentStatus.failed || status == PaymentStatus.cancelled;

  /// Check if payment is confirmed based on Stripe gateway response
  bool get isConfirmedByGateway {
    if (gateway == PaymentGateway.stripe && gatewayResponse != null) {
      final stripeStatus = gatewayResponse!['status'] as String?;
      return stripeStatus == 'succeeded' || stripeStatus == 'processing';
    }
    return isSuccessful;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'amount': amount,
      'currency': currency.name,
      'gateway': gateway.name,
      'transactionId': transactionId,
      'gatewayTransactionId': gatewayTransactionId,
      'paymentUrl': paymentUrl,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'gatewayResponse': gatewayResponse,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'],
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: Currency.values.firstWhere(
        (c) => c.name == json['currency'],
        orElse: () => Currency.egp,
      ),
      gateway: PaymentGateway.values.firstWhere(
        (g) => g.name == json['gateway'],
        orElse: () => PaymentGateway.stripe,
      ),
      transactionId: json['transactionId'],
      gatewayTransactionId: json['gatewayTransactionId'],
      paymentUrl: json['paymentUrl'],
      errorMessage: json['errorMessage'],
      errorCode: json['errorCode'],
      gatewayResponse: json['gatewayResponse'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        amount,
        currency,
        gateway,
        transactionId,
        gatewayTransactionId,
        paymentUrl,
        errorMessage,
        errorCode,
        gatewayResponse,
        metadata,
        timestamp,
        completedAt,
      ];
}

/// Payment configuration model
class PaymentConfig extends Equatable {
  final PaymentGateway gateway;
  final String apiKey;
  final String secretKey;
  final bool isTestMode;
  final String? webhookSecret;
  final Map<String, dynamic>? additionalConfig;

  const PaymentConfig({
    required this.gateway,
    required this.apiKey,
    required this.secretKey,
    required this.isTestMode,
    this.webhookSecret,
    this.additionalConfig,
  });

  @override
  List<Object?> get props => [
        gateway,
        apiKey,
        secretKey,
        isTestMode,
        webhookSecret,
        additionalConfig,
      ];
}

/// Saved payment method model
class SavedPaymentMethod extends Equatable {
  final String id;
  final PaymentMethod method;
  final String? last4Digits;
  final String? brand;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  const SavedPaymentMethod({
    required this.id,
    required this.method,
    this.last4Digits,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    required this.isDefault,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.name,
      'last4Digits': last4Digits,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'],
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      last4Digits: json['last4Digits'],
      brand: json['brand'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        method,
        last4Digits,
        brand,
        expiryMonth,
        expiryYear,
        isDefault,
        createdAt,
      ];
}

/// Service for managing saved payment methods
class SavedPaymentService {
  /// Get saved payment methods for the current user
  Future<List<SavedPaymentMethod>> getSavedPaymentMethods() async {
    try {
      // In a real implementation, this would fetch from your backend
      // For now, return a demo list
      return [
        SavedPaymentMethod(
          id: 'pm_demo_1',
          method: PaymentMethod.creditCard,
          last4Digits: '4242',
          brand: 'Visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        SavedPaymentMethod(
          id: 'pm_demo_2',
          method: PaymentMethod.vodafoneCash,
          last4Digits: '1234',
          brand: 'Vodafone',
          isDefault: false,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// Set a payment method as default
  Future<void> setAsDefault(String paymentMethodId) async {
    // In a real implementation, this would update your backend
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    // In a real implementation, this would delete from your backend
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Add a new payment method
  Future<SavedPaymentMethod> addPaymentMethod({
    required PaymentMethod method,
    required Map<String, dynamic> details,
  }) async {
    // In a real implementation, this would save to your backend
    await Future.delayed(const Duration(seconds: 1));

    return SavedPaymentMethod(
      id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
      method: method,
      last4Digits: details['last4'] ?? '****',
      brand: details['brand'],
      expiryMonth: details['exp_month'],
      expiryYear: details['exp_year'],
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }
}
