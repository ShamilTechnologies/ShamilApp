import 'package:cloud_firestore/cloud_firestore.dart'; // Keep for GeoPoint if needed, or remove if location removed
import 'package:equatable/equatable.dart';

/// Represents the data needed specifically to display a service provider
/// in the home screen lists (Popular, Recommended).
/// This model is typically created by mapping data from the full ServiceProvider model.
class ServiceProviderDisplayModel extends Equatable {
  final String id; // Document ID from Firestore
  final String businessName;
  final String category; // e.g., "Sports & Fitness", "Entertainment"
  final String? imageUrl; // Main image URL for the card
  final double rating; // Average rating
  final int reviewCount; // Number of reviews
  final String city; // City/Governorate where the provider is located
  // Removed address and location as they are less likely needed for card display

  const ServiceProviderDisplayModel({
    required this.id,
    required this.businessName,
    required this.category,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.city,
  });

  // Removed fromFirestore factory - mapping should happen in the Bloc

  /// Converts the model instance to a Map. Useful for debugging.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'city': city,
    };
  }

  /// Creates a copy of this instance with potentially modified fields.
  ServiceProviderDisplayModel copyWith({
    String? id,
    String? businessName,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    String? city,
  }) {
    return ServiceProviderDisplayModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      city: city ?? this.city,
    );
  }

  // Override props for Equatable comparison
  @override
  List<Object?> get props => [
        id,
        businessName,
        category,
        imageUrl,
        rating,
        reviewCount,
        city,
        // Removed address, location
      ];

  // Optional: Override toString for better debugging output
  @override
  String toString() {
    return 'ServiceProviderDisplayModel(id: $id, name: $businessName, category: $category, rating: $rating, city: $city)';
  }
}
