// lib/feature/service_details/data/service_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents an individual service offered by a service provider.
/// This is typically for on-demand or schedulable tasks.
class ServiceModel extends Equatable {
  final String id; // Document ID from Firestore
  final String providerId; // ID of the service provider offering this service
  final String name;
  final String description;
  final double price; // Can be fixed, per hour, per unit, etc.
  final String priceType; // e.g., "fixed", "hourly", "per_unit"
  final String? priceUnit; // e.g., "room", "item", if priceType is "per_unit"
  final String currency; // e.g., "USD", "EUR", "EGP"
  final int? estimatedDurationMinutes; // Optional: estimated time to complete
  final String category; // Specific category of the service (e.g., "Standard Cleaning", "Haircut")
  final List<String>? imageUrls; // Optional images for the service
  final bool isActive; // Whether the service is currently available
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Defines what aspects of this service can be configured by the user.
  // This helps the "Options Configuration Screen" know what UI to render.
  // Example:
  // {
  //   "allowDateSelection": true,
  //   "allowTimeSelection": true,
  //   "timeSelectionType": "slots", // "slots" or "preference"
  //   "availableTimeSlots": ["09:00-11:00", "14:00-16:00"],
  //   "allowQuantitySelection": true,
  //   "quantityDetails": {"min": 1, "max": 5, "label": "Number of rooms"},
  //   "availableAddOns": ["addon_id_clean_oven", "addon_id_wash_windows"],
  //   "customizableNotes": "Any specific requests for this service?"
  // }
  final Map<String, dynamic>? optionsDefinition;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    this.priceUnit,
    this.currency = 'EGP', // Default currency
    this.estimatedDurationMinutes,
    required this.category,
    this.imageUrls,
    this.isActive = true,
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
        priceType,
        priceUnit,
        currency,
        estimatedDurationMinutes,
        category,
        imageUrls,
        isActive,
        optionsDefinition,
        createdAt,
        updatedAt,
      ];

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
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

    return ServiceModel(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unnamed Service',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      priceType: data['priceType'] as String? ?? 'fixed',
      priceUnit: data['priceUnit'] as String?,
      currency: data['currency'] as String? ?? 'EGP',
      estimatedDurationMinutes: data['estimatedDurationMinutes'] as int?,
      category: data['category'] as String? ?? 'General',
      imageUrls: data['imageUrls'] != null ? _toListString(data['imageUrls']) : null,
      isActive: data['isActive'] as bool? ?? true,
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
      'priceType': priceType,
      if (priceUnit != null) 'priceUnit': priceUnit,
      'currency': currency,
      if (estimatedDurationMinutes != null) 'estimatedDurationMinutes': estimatedDurationMinutes,
      'category': category,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'isActive': isActive,
      if (optionsDefinition != null) 'optionsDefinition': optionsDefinition,
    };
  }
}
