// lib/feature/home/data/service_provider_display_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // For the .fromServiceProviderModel factory

class ServiceProviderDisplayModel extends Equatable {
  final String id;
  final String businessName;
  final String? imageUrl;
  final String? businessLogoUrl;
  final String businessCategory;
  final String? subCategory;
  final double averageRating;
  final int ratingCount;
  final String city;
  final bool isFavorite;
  final String? shortDescription;
  final bool isFeatured;
  final bool isActive;
  final bool isApproved;
  final String? distanceInKm;
  final String? primaryServiceExample;
  final String? startingPriceExample;

  const ServiceProviderDisplayModel({
    required this.id,
    required this.businessName,
    this.imageUrl,
    this.businessLogoUrl,
    required this.businessCategory,
    this.subCategory,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    required this.city,
    this.isFavorite = false,
    this.shortDescription,
    this.isFeatured = false,
    this.isActive = true,
    this.isApproved = true,
    this.distanceInKm,
    this.primaryServiceExample,
    this.startingPriceExample,
  });

  @override
  List<Object?> get props => [
        id, businessName, imageUrl, businessLogoUrl, businessCategory, subCategory,
        averageRating, ratingCount, city, isFavorite, shortDescription,
        isFeatured, isActive, isApproved, distanceInKm, primaryServiceExample, startingPriceExample,
      ];

  factory ServiceProviderDisplayModel.fromFirestore(
    DocumentSnapshot doc, {
    required bool isFavorite,
    double? distanceInKm,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String? getCityFromAddress(Map<String, dynamic> addressData) {
      return addressData['city'] as String?;
    }

    final Map<String, dynamic> addressData =
        data['address'] is Map<String, dynamic>
            ? data['address'] as Map<String, dynamic>
            : {};

    String description = data['businessDescription'] as String? ?? data['description'] as String? ?? '';
    if (description.length > 150) {
        description = '${description.substring(0, 147)}...';
    }

    return ServiceProviderDisplayModel(
      id: doc.id,
      businessName: data['businessName'] as String? ?? 'Unnamed Provider',
      imageUrl: data['mainImageUrl'] as String? ?? data['imageUrl'] as String?,
      businessLogoUrl: data['logoUrl'] as String? ?? data['businessLogoUrl'] as String?,
      businessCategory: data['businessCategory'] as String? ?? 'General',
      subCategory: data['subCategory'] as String?,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? (data['reviewCount'] as num?)?.toInt() ?? 0,
      city: getCityFromAddress(addressData) ?? '',
      isFavorite: isFavorite,
      shortDescription: description,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isApproved: data['isApproved'] as bool? ?? true,
      distanceInKm: distanceInKm?.toString(),
      primaryServiceExample: data['primaryServiceExample'] as String?,
      startingPriceExample: data['startingPriceExample'] as String?,
    );
  }

  factory ServiceProviderDisplayModel.fromServiceProviderModel(
      ServiceProviderModel provider, bool isFavoriteStatus, {String? calculatedDistance}) {
    String shortDesc = provider.businessDescription;
    if (shortDesc.length > 100) {
      shortDesc = '${shortDesc.substring(0, 97)}...';
    }
    return ServiceProviderDisplayModel(
      id: provider.id,
      businessName: provider.businessName,
      imageUrl: provider.mainImageUrl,
      businessLogoUrl: provider.logoUrl,
      businessCategory: provider.category,
      subCategory: provider.subCategory,
      averageRating: provider.rating,
      ratingCount: provider.ratingCount,
      city: provider.city ?? '',
      isFavorite: isFavoriteStatus,
      shortDescription: shortDesc,
      isFeatured: provider.isFeatured,
      isActive: provider.isActive,
      isApproved: provider.isApproved,
      distanceInKm: calculatedDistance,
      primaryServiceExample: provider.bookableServices.isNotEmpty ? provider.bookableServices.first.name : null,
      startingPriceExample: provider.bookableServices.isNotEmpty && provider.bookableServices.first.price != null
          ? provider.bookableServices.first.price.toString()
          : (provider.subscriptionPlans.isNotEmpty ? provider.subscriptionPlans.first.price.toString() : null)
    );
  }

  /// Factory constructor to create an instance from JSON (Map<String, dynamic>).
  factory ServiceProviderDisplayModel.fromJson(Map<String, dynamic> json) {
    String description = json['shortDescription'] as String? ??
                         json['businessDescription'] as String? ??
                         json['description'] as String? ??
                         '';
    if (description.length > 150) {
      description = '${description.substring(0, 147)}...';
    }

    return ServiceProviderDisplayModel(
      id: json['id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'N/A',
      imageUrl: json['imageUrl'] as String? ?? json['mainImageUrl'] as String?,
      businessLogoUrl: json['businessLogoUrl'] as String? ?? json['logoUrl'] as String?,
      businessCategory: json['businessCategory'] as String? ?? 'General',
      subCategory: json['subCategory'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ??
                     (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ??
                   (json['reviewCount'] as num?)?.toInt() ?? 0,
      city: json['city'] as String? ??
            (json['address'] is Map ? (json['address']['city'] as String? ?? '') : ''),
      isFavorite: json['isFavorite'] as bool? ?? false,
      shortDescription: description,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? true,
      distanceInKm: json['distanceInKm'] as String?, // Assuming it's stored as String
      primaryServiceExample: json['primaryServiceExample'] as String?,
      startingPriceExample: json['startingPriceExample'] as String?,
    );
  }

  /// Method to convert an instance to JSON (Map<String, dynamic>).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'imageUrl': imageUrl,
      'mainImageUrl': imageUrl,
      'businessLogoUrl': businessLogoUrl,
      'logoUrl': businessLogoUrl,
      'businessCategory': businessCategory,
      'subCategory': subCategory,
      'averageRating': averageRating,
      'rating': averageRating,
      'ratingCount': ratingCount,
      'reviewCount': ratingCount,
      'city': city,
      'address': {'city': city}, // Example structure if needed
      'isFavorite': isFavorite,
      'shortDescription': shortDescription,
      'businessDescription': shortDescription,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'isApproved': isApproved,
      'distanceInKm': distanceInKm,
      'primaryServiceExample': primaryServiceExample,
      'startingPriceExample': startingPriceExample,
    };
  }

  ServiceProviderDisplayModel copyWith({
    String? id,
    String? businessName,
    String? imageUrl,
    String? businessLogoUrl,
    String? businessCategory,
    String? subCategory,
    double? averageRating,
    int? ratingCount,
    String? city,
    bool? isFavorite,
    String? shortDescription,
    bool? isFeatured,
    bool? isActive,
    bool? isApproved,
    String? distanceInKm,
    String? primaryServiceExample,
    String? startingPriceExample,
  }) {
    return ServiceProviderDisplayModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      imageUrl: imageUrl ?? this.imageUrl,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      businessCategory: businessCategory ?? this.businessCategory,
      subCategory: subCategory ?? this.subCategory,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      city: city ?? this.city,
      isFavorite: isFavorite ?? this.isFavorite,
      shortDescription: shortDescription ?? this.shortDescription,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      primaryServiceExample: primaryServiceExample ?? this.primaryServiceExample,
      startingPriceExample: startingPriceExample ?? this.startingPriceExample,
    );
  }
}
