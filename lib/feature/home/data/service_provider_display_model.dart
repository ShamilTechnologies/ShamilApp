import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart'; // Import Equatable

/// Represents the data needed to display a service provider
/// in the home screen lists (Popular, Recommended) or detail views.
class ServiceProviderDisplayModel extends Equatable { // Extend Equatable
  final String id; // Document ID from Firestore
  final String businessName;
  final String category; // e.g., "Sports & Fitness", "Entertainment"
  final String? imageUrl; // Main image URL for the card
  final double rating; // Average rating
  final int reviewCount; // Number of reviews
  final String city; // City/Governorate where the provider is located
  final String? address; // Full display address
  final GeoPoint? location; // Geographic coordinates

  const ServiceProviderDisplayModel({ // Use const constructor
    required this.id,
    required this.businessName,
    required this.category,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0, // Default review count
    required this.city,
    this.address, // Make address optional
    this.location, // Make location optional
  });

  /// Factory constructor to create a ServiceProviderDisplayModel from a Firestore document snapshot.
  factory ServiceProviderDisplayModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Safely extract data, providing defaults
    // NOTE: Adjust field names ('businessName', 'category', 'mainImageUrl', 'averageRating', 'reviewCount', 'city', 'address', 'location')
    //       to match the actual field names in your 'serviceProviders' Firestore collection!
    return ServiceProviderDisplayModel(
      id: doc.id,
      businessName: data['businessName'] as String? ?? 'Unknown Name',
      category: data['category'] as String? ?? 'Uncategorized',
      imageUrl: data['mainImageUrl'] as String?, // Assuming 'mainImageUrl'
      rating: (data['averageRating'] as num?)?.toDouble() ?? 0.0, // Assuming 'averageRating'
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0, // Assuming 'reviewCount'
      city: data['city'] as String? ?? 'Unknown City',
      address: data['address'] as String?, // Assuming 'address'
      location: data['location'] as GeoPoint?, // Assuming 'location' is a GeoPoint
    );
  }

  /// Converts the model instance to a Map. Useful for debugging or potential future use.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include ID in map
      'businessName': businessName,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'city': city,
      'address': address,
      'location': location,
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
    String? address,
    GeoPoint? location,
  }) {
    return ServiceProviderDisplayModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      // Handle potential null assignment for optional fields if needed
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      city: city ?? this.city,
      address: address ?? this.address,
      location: location ?? this.location,
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
        address,
        location,
      ];

  // Optional: Override toString for better debugging output
  @override
  String toString() {
    return 'ServiceProviderDisplayModel(id: $id, businessName: $businessName, category: $category, rating: $rating, city: $city)';
  }
}
