// lib/feature/home/data/service_provider_display_model.dart
import 'package:equatable/equatable.dart';

/// Represents the data needed specifically to display a service provider
/// in the home screen lists (Popular, Recommended, Nearby, Offers).
/// This model is typically created by mapping data from the full ServiceProvider model
/// and merging user-specific data like favorite status and calculated distance in the Bloc.
class ServiceProviderDisplayModel extends Equatable {
  final String id;
  final String businessName;
  final String category;
  final String? imageUrl;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final String city;
  final bool isFavorite;
  final double? distanceInKm; // <<< ADDED: Distance from user (nullable)

  const ServiceProviderDisplayModel({
    required this.id,
    required this.businessName,
    required this.category,
    this.imageUrl,
    this.logoUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.city,
    this.isFavorite = false,
    this.distanceInKm, // <<< ADDED (optional)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'category': category,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'city': city,
      'isFavorite': isFavorite,
      'distanceInKm': distanceInKm, // <<< ADDED
    };
  }

  /// Creates a copy of this instance with potentially modified fields.
  ServiceProviderDisplayModel copyWith({
    String? id,
    String? businessName,
    String? category,
    String? imageUrl,
    String? logoUrl,
    double? rating,
    int? reviewCount,
    String? city,
    bool? isFavorite,
    double? distanceInKm, // <<< ADDED
    bool clearDistance = false, // Flag to explicitly set distance to null
  }) {
    return ServiceProviderDisplayModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      city: city ?? this.city,
      isFavorite: isFavorite ?? this.isFavorite,
      // Handle distance update or clearing
      distanceInKm: clearDistance ? null : (distanceInKm ?? this.distanceInKm), // <<< UPDATED
    );
  }

  @override
  List<Object?> get props => [
        id, businessName, category, imageUrl, logoUrl,
        rating, reviewCount, city, isFavorite,
        distanceInKm, // <<< ADDED
      ];

  @override
  String toString() {
    // Format distance nicely if it exists
    final distanceString = distanceInKm != null ? ', distance: ${distanceInKm!.toStringAsFixed(1)}km' : '';
    return 'ServiceProviderDisplayModel(id: $id, name: $businessName, category: $category, rating: $rating, city: $city, isFavorite: $isFavorite, logo: $logoUrl, image: $imageUrl$distanceString)'; // <<< UPDATED
  }
}
