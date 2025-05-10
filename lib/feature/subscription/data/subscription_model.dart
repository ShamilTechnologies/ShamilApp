// lib/feature/subscription/data/subscription_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Enum for Subscription Status
enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  paymentFailed,
  unknown,
}

SubscriptionStatus subscriptionStatusFromString(String? status) {
  switch (status?.toLowerCase()) {
    case 'active':
      return SubscriptionStatus.active;
    case 'cancelled':
      return SubscriptionStatus.cancelled;
    case 'expired':
      return SubscriptionStatus.expired;
    case 'payment_failed':
      return SubscriptionStatus.paymentFailed; // Match guide?
    default:
      return SubscriptionStatus.unknown;
  }
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get statusString {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.paymentFailed:
        return 'payment_failed';
      default:
        return 'unknown';
    }
  }
}

/// Represents a user's subscription instance stored in Firestore.
class SubscriptionModel extends Equatable {
  final String id; // Document ID (subscriptionId)
  final String userId;
  final String userName; // Denormalized user name
  final String providerId;
  // Consider adding providerName if frequently needed without joining
  // final String providerName;
  final String planId; // ID of the SubscriptionPlan from ServiceProviderModel
  final String planName; // Denormalized plan name
  final String
      status; // Use string since SubscriptionStatus doesn't have 'pending'
  final Timestamp startDate;
  final Timestamp expiryDate;
  final Timestamp? nextBillingDate; // Optional, for recurring
  final double pricePaid; // Amount paid for the current/last cycle
  final Map<String, dynamic>? paymentDetails; // Optional transaction info
  final String? cancellationReason; // Optional
  final int groupSize; // Number of people in the subscription
  final String? notes; // User notes
  final List<dynamic> subscribers; // List of subscribers/attendees
  final List<String>? selectedAddOns; // Selected add-ons
  final String? billingCycle; // Billing cycle (monthly, yearly, etc)
  final Timestamp createdAt;
  final Timestamp updatedAt; // Use server timestamp on writes

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.providerId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    this.nextBillingDate,
    required this.pricePaid,
    this.paymentDetails,
    this.cancellationReason,
    this.groupSize = 1,
    this.notes,
    this.subscribers = const [],
    this.selectedAddOns,
    this.billingCycle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      startDate:
          data['startDate'] as Timestamp? ?? Timestamp.now(), // Provide default
      expiryDate: data['expiryDate'] as Timestamp? ??
          Timestamp.now(), // Provide default
      nextBillingDate: data['nextBillingDate'] as Timestamp?,
      pricePaid: (data['pricePaid'] as num?)?.toDouble() ?? 0.0,
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      cancellationReason: data['cancellationReason'] as String?,
      groupSize: (data['groupSize'] as num?)?.toInt() ?? 1,
      notes: data['notes'] as String?,
      subscribers: data['subscribers'] as List<dynamic>? ?? const [],
      selectedAddOns: data['selectedAddOns'] != null
          ? List<String>.from(data['selectedAddOns'] as List<dynamic>)
          : null,
      billingCycle: data['billingCycle'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'planId': planId,
      'planName': planName,
      'status': status,
      'startDate': startDate,
      'expiryDate': expiryDate,
      if (nextBillingDate != null) 'nextBillingDate': nextBillingDate,
      'pricePaid': pricePaid,
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'groupSize': groupSize,
      if (notes != null) 'notes': notes,
      'subscribers': subscribers,
      if (selectedAddOns != null) 'selectedAddOns': selectedAddOns,
      if (billingCycle != null) 'billingCycle': billingCycle,
      'createdAt': createdAt, // Use FieldValue.serverTimestamp() on creation
      'updatedAt': updatedAt, // Use FieldValue.serverTimestamp() on update
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'planId': planId,
      'planName': planName,
      'status': status,
      'startDate': startDate,
      'expiryDate': expiryDate,
      if (nextBillingDate != null) 'nextBillingDate': nextBillingDate,
      'pricePaid': pricePaid,
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'groupSize': groupSize,
      if (notes != null) 'notes': notes,
      'subscribers': subscribers,
      if (selectedAddOns != null) 'selectedAddOns': selectedAddOns,
      if (billingCycle != null) 'billingCycle': billingCycle,
      // Server timestamps will be added in the repository
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        providerId,
        planId,
        planName,
        status,
        startDate,
        expiryDate,
        nextBillingDate,
        pricePaid,
        paymentDetails,
        cancellationReason,
        groupSize,
        notes,
        subscribers,
        selectedAddOns,
        billingCycle,
        createdAt,
        updatedAt,
      ];
}
