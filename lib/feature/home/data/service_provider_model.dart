import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
// Import BookableService - Adjust path if necessary
// Assuming it's in lib/feature/auth/data/ based on previous context.
// If it's elsewhere, update the path.
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';

// --- Enum Definitions ---

/// Defines the possible intervals for subscription pricing.
enum PricingInterval { day, week, month, year }

/// Helper to convert string to PricingInterval enum and handle unknown values.
PricingInterval pricingIntervalFromString(String? intervalString) {
  switch (intervalString?.toLowerCase()) {
    case 'day': return PricingInterval.day;
    case 'week': return PricingInterval.week;
    case 'month': return PricingInterval.month;
    case 'year': return PricingInterval.year;
    default: return PricingInterval.month; // Default to month if null or unknown
  }
}

/// Defines the pricing model options for a service provider.
enum PricingModel { subscription, reservation, hybrid, other }

/// Helper to convert string to PricingModel enum.
PricingModel pricingModelFromString(String? modelString) {
  switch (modelString?.toLowerCase()) {
    case 'subscription': return PricingModel.subscription;
    case 'reservation': return PricingModel.reservation;
    case 'hybrid': return PricingModel.hybrid;
    case 'other': return PricingModel.other;
    default: return PricingModel.other; // Default if null or unknown
  }
}

// --- Nested Data Classes ---

/// Represents a subscription plan offered by a service provider.
/// Includes interval, intervalCount, and features fields.
class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features; // List of feature strings for the plan
  final int intervalCount;
  final PricingInterval interval;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.features = const [], // Default to empty list
    required this.intervalCount,
    required this.interval,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> data, String id) {
    return SubscriptionPlan(
      id: id, // Use provided ID (e.g., from map key or generated)
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(data['features'] as List<dynamic>? ?? []), // Parse features
      intervalCount: (data['intervalCount'] as num?)?.toInt() ?? 1,
      interval: pricingIntervalFromString(data['interval'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // Usually not stored in the map within the list
      'name': name,
      'description': description,
      'price': price,
      'features': features,
      'intervalCount': intervalCount,
      'interval': interval.name, // Store enum name as string
    };
  }

  SubscriptionPlan copyWith({
    String? id, String? name, String? description, double? price,
    List<String>? features, int? intervalCount, PricingInterval? interval,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      price: price ?? this.price, features: features ?? this.features,
      intervalCount: intervalCount ?? this.intervalCount, interval: interval ?? this.interval,
    );
  }

  @override List<Object?> get props => [id, name, description, price, features, intervalCount, interval];
}


// --- Main Service Provider Model ---

/// Represents the data fetched from Firestore for a service provider,
/// containing fields needed for display and logic.
/// (This replaces the previous simpler ServiceProvider model in the mobile app)
class ServiceProviderModel extends Equatable {
  final String id; // Document ID (usually same as Firebase Auth UID for providers)
  final String businessName;
  final String category; // Use businessCategory from Firestore
  final String businessDescription;
  final String? mainImageUrl;
  final String? logoUrl;
  final Map<String, String> address; // Includes city, governorate, street
  final GeoPoint? location;
  final double rating; // Use averageRating from Firestore
  final int ratingCount;
  final bool isActive;
  final bool isFeatured;
  final List<String> amenities;
  // --- Added Fields ---
  final PricingModel pricingModel;
  final List<SubscriptionPlan> subscriptionPlans;
  final List<BookableService> bookableServices;
  // Add any other fields from the detailed model if needed (e.g., openingHours, galleryImageUrls)

  const ServiceProviderModel({
    required this.id,
    required this.businessName,
    required this.category,
    required this.businessDescription,
    this.mainImageUrl,
    this.logoUrl,
    required this.address,
    this.location,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.isActive,
    this.isFeatured = false,
    this.amenities = const [],
    // --- Added Fields ---
    required this.pricingModel,
    this.subscriptionPlans = const [],
    this.bookableServices = const [],
    // Initialize other fields if added
  });

  /// Factory constructor to create a ServiceProviderModel from a Firestore DocumentSnapshot.
  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data

    // Safely parse address map
    Map<String, String> addressMap = {};
    if (data['address'] is Map) {
      (data['address'] as Map).forEach((key, value) {
         if (key is String && value is String) { addressMap[key] = value; }
      });
    }

    // Safely parse amenities list
    List<String> amenitiesList = [];
    if (data['amenities'] is List) {
      amenitiesList = List<String>.from((data['amenities'] as List).map((item) => item.toString()));
    }

    // Parse SubscriptionPlan list
    final List<SubscriptionPlan> subscriptionPlansList = (data['subscriptionPlans'] as List<dynamic>? ?? [])
        .map((planData) {
           if (planData is Map<String, dynamic>) {
              // Assuming plan ID might be the key in a map, or generate one if stored as list
              // If Firestore generates IDs, you might fetch them differently (e.g., subcollection)
              // For simplicity here, generating an ID if not present in the map.
              final String planId = planData['id']?.toString() ?? doc.id + DateTime.now().millisecondsSinceEpoch.toString(); // Example ID generation
              try { return SubscriptionPlan.fromMap(planData, planId); }
              catch (e) { print("Error parsing SubscriptionPlan: $e. Data: $planData"); return null; }
           } return null;
        }).whereType<SubscriptionPlan>().toList();

    // Parse BookableService list
    final List<BookableService> bookableServicesList = (data['bookableServices'] as List<dynamic>? ?? [])
        .map((serviceData) {
           if (serviceData is Map<String, dynamic>) {
              // Assuming service ID might be the key or generate one
              // final String serviceId = serviceData['id']?.toString() ?? doc.id + DateTime.now().millisecondsSinceEpoch.toString(); // Example ID generation
              try { return BookableService.fromMap(serviceData); } // Assuming fromMap handles ID
              catch (e) { print("Error parsing BookableService: $e. Data: $serviceData"); return null; }
           } return null;
        }).whereType<BookableService>().toList();

    // Parse Pricing Model
    PricingModel pricing = PricingModel.other;
     try { pricing = pricingModelFromString(data['pricingModel'] as String?); }
     catch (e) { print("Error parsing pricingModel: $e"); }


    return ServiceProviderModel(
      id: doc.id,
      businessName: data['businessName'] as String? ?? '',
      // Ensure correct Firestore field name is used for category
      category: data['businessCategory'] as String? ?? '',
      businessDescription: data['businessDescription'] as String? ?? '',
      mainImageUrl: data['mainImageUrl'] as String?,
      logoUrl: data['logoUrl'] as String?,
      address: addressMap,
      location: data['location'] as GeoPoint?,
      // Use consistent field names from detailed model for rating/count
      rating: (data['averageRating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      // Use consistent field name for active status
      isActive: (data['isActive'] as bool?) ?? (data['isPublished'] as bool?) ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      amenities: amenitiesList,
      // --- Assign Added Fields ---
      pricingModel: pricing,
      subscriptionPlans: subscriptionPlansList,
      bookableServices: bookableServicesList,
      // Assign other fields if added (e.g., openingHours, galleryImageUrls)
    );
  }

  // Helper to get street, handling potential missing key
  String? get street => address['street'];
  // Helper to get governorate, handling potential missing key
  String? get governorate => address['governorate'];
  // Helper to get city
  String? get city => address['city'];

  // Convert model to map for Firestore (optional, mainly for writing)
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessCategory': category, // Ensure field name matches Firestore read key
      'businessDescription': businessDescription,
      'mainImageUrl': mainImageUrl,
      'logoUrl': logoUrl,
      'address': address,
      'location': location,
      'averageRating': rating, // Use consistent field names
      'ratingCount': ratingCount,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'amenities': amenities,
      // --- Added Fields ---
      'pricingModel': pricingModel.name, // Store enum name as string
      'subscriptionPlans': subscriptionPlans.map((plan) => plan.toMap()..['id'] = plan.id).toList(), // Include ID if storing back
      'bookableServices': bookableServices.map((service) => service.toMap()..['id'] = service.id).toList(), // Include ID if storing back
      // Add other fields if needed for writing
    };
  }


  @override
  List<Object?> get props => [
        id, businessName, category,
        businessDescription,
        mainImageUrl, logoUrl,
        address, location,
        rating, ratingCount, isActive, isFeatured,
        amenities,
        // --- Added Fields ---
        pricingModel, subscriptionPlans, bookableServices,
      ];
}