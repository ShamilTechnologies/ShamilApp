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
    case 'active': return SubscriptionStatus.active;
    case 'cancelled': return SubscriptionStatus.cancelled;
    case 'expired': return SubscriptionStatus.expired;
    case 'payment_failed': return SubscriptionStatus.paymentFailed; // Match guide?
    default: return SubscriptionStatus.unknown;
  }
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get statusString {
    switch (this) {
      case SubscriptionStatus.active: return 'active';
      case SubscriptionStatus.cancelled: return 'cancelled';
      case SubscriptionStatus.expired: return 'expired';
      case SubscriptionStatus.paymentFailed: return 'payment_failed';
      default: return 'unknown';
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
  final SubscriptionStatus status;
  final Timestamp startDate;
  final Timestamp expiryDate;
  final Timestamp? nextBillingDate; // Optional, for recurring
  final double pricePaid; // Amount paid for the current/last cycle
  final Map<String, dynamic>? paymentDetails; // Optional transaction info
  final String? cancellationReason; // Optional
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
      status: subscriptionStatusFromString(data['status'] as String?),
      startDate: data['startDate'] as Timestamp? ?? Timestamp.now(), // Provide default
      expiryDate: data['expiryDate'] as Timestamp? ?? Timestamp.now(), // Provide default
      nextBillingDate: data['nextBillingDate'] as Timestamp?,
      pricePaid: (data['pricePaid'] as num?)?.toDouble() ?? 0.0,
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      cancellationReason: data['cancellationReason'] as String?,
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
      'status': status.statusString,
      'startDate': startDate,
      'expiryDate': expiryDate,
      if (nextBillingDate != null) 'nextBillingDate': nextBillingDate,
      'pricePaid': pricePaid,
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'createdAt': createdAt, // Use FieldValue.serverTimestamp() on creation
      'updatedAt': updatedAt, // Use FieldValue.serverTimestamp() on update
    };
  }

  @override
  List<Object?> get props => [
        id, userId, userName, providerId, planId, planName, status,
        startDate, expiryDate, nextBillingDate, pricePaid, paymentDetails,
        cancellationReason, createdAt, updatedAt,
      ];
}