    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:equatable/equatable.dart';

    /// Represents the data fetched from Firestore for a service provider,
    /// containing fields needed by the HomeBloc for display and logic.
    class ServiceProvider extends Equatable {
      final String id; // Document ID
      final String businessName;
      final String category;
      final String? mainImageUrl;
      final Map<String, String> address; // Includes city, governorate
      final GeoPoint? location;
      final double rating;
      final int ratingCount;
      final bool isActive;
      final bool isFeatured;
      // Add other fields if needed by HomeBloc logic (e.g., openingHours for filtering)

      const ServiceProvider({
        required this.id,
        required this.businessName,
        required this.category,
        this.mainImageUrl,
        required this.address,
        this.location,
        this.rating = 0.0,
        this.ratingCount = 0,
        required this.isActive,
        this.isFeatured = false,
      });

      /// Factory constructor to create a ServiceProvider from a Firestore DocumentSnapshot.
      factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data

        // Ensure address is Map<String, String>, provide default empty map if null/wrong type
        Map<String, String> addressMap = {};
        if (data['address'] is Map) {
           // Ensure keys and values are strings
           addressMap = Map<String, String>.from(
              (data['address'] as Map).map((key, value) => MapEntry(key.toString(), value.toString()))
           );
        }

        return ServiceProvider(
          id: doc.id,
          // *** Ensure these field names MATCH your Firestore document ***
          businessName: data['businessName'] as String? ?? '',
          category: data['businessCategory'] as String? ?? '', // Check if 'category' or 'businessCategory' in Firestore
          mainImageUrl: data['mainImageUrl'] as String?,
          address: addressMap, // Use the validated/defaulted map
          location: data['location'] as GeoPoint?,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0, // Check if 'rating' or 'averageRating' in Firestore
          ratingCount: data['ratingCount'] as int? ?? 0, // Check if 'ratingCount' or 'reviewCount' in Firestore
          isActive: data['isActive'] as bool? ?? false, // Check if 'isActive' or 'isPublished' in Firestore
          isFeatured: data['isFeatured'] as bool? ?? false,
        );
      }

      // Helper to get governorate, handling potential missing key
      String? get governorate => address['governorate'];
      // Helper to get city
      String? get city => address['city'];


      @override
      List<Object?> get props => [
            id, businessName, category, mainImageUrl, address, location,
            rating, ratingCount, isActive, isFeatured
          ];
    }
    