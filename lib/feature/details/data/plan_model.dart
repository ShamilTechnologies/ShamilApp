// lib/feature/service_details/data/plan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a service plan offered by a service provider.
/// This could be a subscription, a package deal, or a bundled set of services.
class PlanModel extends Equatable {
  final String id; // Document ID from Firestore
  final String providerId; // ID of the service provider offering this plan
  final String name;
  final String description;
  final double price; // Base price of the plan
  final String currency; // e.g., "USD", "EUR", "EGP"
  final String billingCycle; // e.g., "one-time", "monthly", "annually", "per_session"
  final List<String> features; // List of features or benefits included in the plan
  final List<String>? imageUrls; // Optional images for the plan
  final bool isActive; // Whether the plan is currently available
  final String? termsAndConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Defines what aspects of this plan can be configured by the user.
  // This helps the "Options Configuration Screen" know what UI to render.
  // Example:
  // {
  //   "allowDateSelection": true,
  //   "allowTimeSelection": true, // Could be specific slots or general preference
  //   "availableDurations": ["3_months", "6_months", "12_months"], // If plan has variable duration
  //   "customizableNotes": "Provide any specific instructions."
  // }
  final Map<String, dynamic>? optionsDefinition;

  const PlanModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'EGP', // Default currency
    required this.billingCycle,
    this.features = const [],
    this.imageUrls,
    this.isActive = true,
    this.termsAndConditions,
    this.optionsDefinition,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        providerId,
        name,
        description,
        price,
        currency,
        billingCycle,
        features,
        imageUrls,
        isActive,
        termsAndConditions,
        optionsDefinition,
        createdAt,
        updatedAt,
      ];

  factory PlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? _toDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    List<String> _toListString(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PlanModel(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Plan',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'EGP',
      billingCycle: data['billingCycle'] as String? ?? 'one-time',
      features: _toListString(data['features']),
      imageUrls: data['imageUrls'] != null ? _toListString(data['imageUrls']) : null,
      isActive: data['isActive'] as bool? ?? true,
      termsAndConditions: data['termsAndConditions'] as String?,
      optionsDefinition: data['optionsDefinition'] is Map<String, dynamic>
          ? data['optionsDefinition'] as Map<String, dynamic>
          : null,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle,
      'features': features,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'isActive': isActive,
      if (termsAndConditions != null) 'termsAndConditions': termsAndConditions,
      if (optionsDefinition != null) 'optionsDefinition': optionsDefinition,
      // Let Firestore handle timestamps on create/update
      // 'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      // 'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
