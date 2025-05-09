// lib/feature/home/data/service_provider_display_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a service provider in a display-friendly format for lists and detail headers.
class ServiceProviderDisplayModel extends Equatable {
  final String id; // Document ID from Firestore
  final String businessName;
  final String? imageUrl; // <<< Main image for Card/Header
  final String? businessLogoUrl; // <<< Specific logo, e.g., for overlay
  final String businessCategory;
  final String? subCategory;
  final double averageRating; // <<< Standardized field
  final int ratingCount; // <<< Standardized field
  final String city;
  final bool isFavorite;
  final String shortDescription;
  final bool isFeatured;
  final bool isActive;
  final bool isApproved;

  // Optional: For displaying distance if calculated
  final double? distanceInKm;

  // Optional: For displaying a primary service or offer prominently
  final String? primaryServiceExample;
  final String? startingPriceExample;

  const ServiceProviderDisplayModel({
    required this.id,
    required this.businessName,
    this.imageUrl, // <<< Added/Verified
    this.businessLogoUrl,
    required this.businessCategory,
    this.subCategory,
    required this.averageRating,
    required this.ratingCount,
    required this.city,
    required this.isFavorite,
    required this.shortDescription,
    required this.isFeatured,
    required this.isActive,
    required this.isApproved,
    this.distanceInKm,
    this.primaryServiceExample,
    this.startingPriceExample,
  });

  @override
  List<Object?> get props => [
        id,
        businessName,
        imageUrl, // <<< Added
        businessLogoUrl,
        businessCategory,
        subCategory,
        averageRating, // <<< Standardized
        ratingCount, // <<< Standardized
        city,
        isFavorite,
        shortDescription,
        isFeatured,
        isActive,
        isApproved,
        distanceInKm,
        primaryServiceExample,
        startingPriceExample,
      ];

  /// Factory constructor to create a `ServiceProviderDisplayModel` from a Firestore document.
  factory ServiceProviderDisplayModel.fromFirestore(
    DocumentSnapshot doc, {
    required bool isFavorite,
    double? distanceInKm,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String? _getCity(Map<String, dynamic> addressData) {
      return addressData['city'] as String?;
    }

    final Map<String, dynamic> addressData =
        data['address'] is Map<String, dynamic>
            ? data['address'] as Map<String, dynamic>
            : {};

    // Determine main image URL - prioritize a specific field if available, fallback
    String? mainImageUrl = data['imageUrl'] as String? ??
        data['mainImageUrl'] as String?; // <<< Read imageUrl or mainImageUrl

    return ServiceProviderDisplayModel(
      id: doc.id,
      businessName: data['businessName'] as String? ?? 'N/A',
      imageUrl: mainImageUrl, // <<< Assign main image URL
      businessLogoUrl: data['businessLogoUrl'] as String? ??
          data['logoUrl'] as String?, // <<< Read logo URL
      businessCategory: data['businessCategory'] as String? ?? 'Uncategorized',
      subCategory: data['subCategory'] as String?,
      averageRating: (data['averageRating'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0.0, // <<< Read averageRating or rating
      ratingCount: data['ratingCount'] as int? ??
          data['reviewCount'] as int? ??
          0, // <<< Read ratingCount or reviewCount
      city: _getCity(addressData) ?? '',
      isFavorite: isFavorite,
      shortDescription: data['shortDescription'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isApproved: data['isApproved'] as bool? ?? true,
      distanceInKm: distanceInKm,
      primaryServiceExample: data['primaryServiceExample'] as String?,
      startingPriceExample: data['startingPriceExample'] as String?,
    );
  }

  /// Creates a new `ServiceProviderDisplayModel` instance with updated values.
  ServiceProviderDisplayModel copyWith({
    String? id,
    String? businessName,
    String? imageUrl, // <<< Added
    String? businessLogoUrl,
    String? businessCategory,
    String? subCategory,
    double? averageRating, // <<< Standardized
    int? ratingCount, // <<< Standardized
    String? city,
    bool? isFavorite,
    String? shortDescription,
    bool? isFeatured,
    bool? isActive,
    bool? isApproved,
    double? distanceInKm,
    String? primaryServiceExample,
    String? startingPriceExample,
  }) {
    return ServiceProviderDisplayModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      imageUrl: imageUrl ?? this.imageUrl, // <<< Added
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      businessCategory: businessCategory ?? this.businessCategory,
      subCategory: subCategory ?? this.subCategory,
      averageRating: averageRating ?? this.averageRating, // <<< Standardized
      ratingCount: ratingCount ?? this.ratingCount, // <<< Standardized
      city: city ?? this.city,
      isFavorite: isFavorite ?? this.isFavorite,
      shortDescription: shortDescription ?? this.shortDescription,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      primaryServiceExample:
          primaryServiceExample ?? this.primaryServiceExample,
      startingPriceExample: startingPriceExample ?? this.startingPriceExample,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'imageUrl': imageUrl,
      'businessLogoUrl': businessLogoUrl,
      'businessCategory': businessCategory,
      'subCategory': subCategory,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'city': city,
      'isFavorite': isFavorite,
      'shortDescription': shortDescription,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'isApproved': isApproved,
    };
  }

  factory ServiceProviderDisplayModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderDisplayModel(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      imageUrl: json['imageUrl'] as String?,
      businessLogoUrl: json['businessLogoUrl'] as String?,
      businessCategory: json['businessCategory'] as String,
      subCategory: json['subCategory'] as String?,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      city: json['city'] as String,
      isFavorite: json['isFavorite'] as bool,
      shortDescription: json['shortDescription'] as String,
      isFeatured: json['isFeatured'] as bool,
      isActive: json['isActive'] as bool,
      isApproved: json['isApproved'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessName': businessName,
      'imageUrl': imageUrl,
      'businessLogoUrl': businessLogoUrl,
      'businessCategory': businessCategory,
      'subCategory': subCategory,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'city': city,
      'isFavorite': isFavorite,
      'shortDescription': shortDescription,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'isApproved': isApproved,
    };
  }
}
