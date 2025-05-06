// lib/feature/home/data/service_provider_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import for TimeOfDay
// Assuming BookableService is in the same directory or adjust the path
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
// Import ReservationType enum
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart' show ReservationType, reservationTypeFromString;


// --- Enum Definitions ---

/// Defines the interval for subscription pricing (e.g., daily, monthly).
enum PricingInterval { day, week, month, year }

/// Converts a string representation to a [PricingInterval] enum value.
/// Defaults to [PricingInterval.month] if the string is unrecognized.
PricingInterval pricingIntervalFromString(String? intervalString) {
  switch (intervalString?.toLowerCase()) {
    case 'day': return PricingInterval.day;
    case 'week': return PricingInterval.week;
    case 'month': return PricingInterval.month;
    case 'year': return PricingInterval.year;
    default: return PricingInterval.month; // Default
  }
}

/// Defines the primary pricing model for a service provider.
enum PricingModel { subscription, reservation, hybrid, other }

/// Converts a string representation to a [PricingModel] enum value.
/// Defaults to [PricingModel.other] if the string is unrecognized.
PricingModel pricingModelFromString(String? modelString) {
  switch (modelString?.toLowerCase()) {
    case 'subscription': return PricingModel.subscription;
    case 'reservation': return PricingModel.reservation;
    case 'hybrid': return PricingModel.hybrid; // Supports both
    default: return PricingModel.other; // Default
  }
}

// --- Nested Models ---

/// Represents a subscription plan offered by a provider.
class SubscriptionPlan extends Equatable {
  final String id; // Unique ID for the plan (e.g., Firestore doc ID or generated)
  final String name; // Name of the plan (e.g., "Gold Membership")
  final String description; // Description of what the plan includes
  final double price; // Cost of the plan
  final List<String> features; // List of features/benefits included
  final int intervalCount; // Number of intervals (e.g., 1 for monthly, 3 for quarterly)
  final PricingInterval interval; // The interval unit (e.g., month)

  const SubscriptionPlan({
    required this.id, required this.name, required this.description,
    required this.price, this.features = const [], required this.intervalCount,
    required this.interval,
  });

  /// Creates a [SubscriptionPlan] from a map (e.g., Firestore data).
  factory SubscriptionPlan.fromMap(Map<String, dynamic> data, String id) {
    return SubscriptionPlan(
      id: id, // Use the provided document ID
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(data['features'] ?? []), // Safely cast list
      intervalCount: (data['intervalCount'] as num?)?.toInt() ?? 1, // Default to 1
      interval: pricingIntervalFromString(data['interval']), // Use helper
    );
  }

  /// Converts this [SubscriptionPlan] object into a map suitable for Firestore.
  /// Note: 'id' is typically not stored within the map itself.
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'features': features,
        'intervalCount': intervalCount,
        'interval': interval.name, // Store enum name as string
      };

  /// Creates a copy of this plan with optional updated fields.
  SubscriptionPlan copyWith({
    String? id, String? name, String? description, double? price,
    List<String>? features, int? intervalCount, PricingInterval? interval,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      features: features ?? this.features,
      intervalCount: intervalCount ?? this.intervalCount,
      interval: interval ?? this.interval,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, features, intervalCount, interval];
}

/// Represents the opening hours for a specific day (e.g., Monday).
class OpeningHours extends Equatable {
  final TimeOfDay? startTime; // Time the provider opens
  final TimeOfDay? endTime;   // Time the provider closes
  final bool isOpen;          // Whether the provider is open on this day

  const OpeningHours({this.startTime, this.endTime, this.isOpen = true});

  /// Creates [OpeningHours] from a map (e.g., Firestore data for a specific day).
  /// Handles potentially missing or malformed time strings.
  factory OpeningHours.fromMap(Map<String, dynamic>? data) {
     if (data == null) return const OpeningHours(isOpen: false); // Closed if no data

     // Helper to parse 'HH:mm' strings robustly
     TimeOfDay? parseTime(String? timeString) {
       if (timeString == null) return null;
       final trimmed = timeString.trim(); // Remove leading/trailing whitespace
       if (!trimmed.contains(':')) return null; // Must contain ':'
       final parts = trimmed.split(':');
       if (parts.length != 2) return null; // Must have exactly two parts
       final hour = int.tryParse(parts[0]);
       final minute = int.tryParse(parts[1]);
       // Validate parsing and time ranges
       if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
       return TimeOfDay(hour: hour, minute: minute);
     }

     // Parse 'open' and 'close' times
     final startTimeValue = parseTime(data['open'] as String?);
     final endTimeValue = parseTime(data['close'] as String?);

     // Consider the day effectively open only if BOTH start and end times are valid
     // AND if an explicit 'isOpen' flag exists and is true (or default to true if flag is missing)
     final bool explicitIsOpen = data['isOpen'] as bool? ?? true; // Assume open if flag is missing
     final bool hasValidTimes = startTimeValue != null && endTimeValue != null;
     final bool isEffectivelyOpen = explicitIsOpen && hasValidTimes;

     return OpeningHours(
       startTime: startTimeValue,
       endTime: endTimeValue,
       isOpen: isEffectivelyOpen, // Use calculated openness
     );
  }

  /// Converts this [OpeningHours] object into a map suitable for Firestore.
  Map<String, dynamic> toMap() {
     // Helper to format TimeOfDay back to 'HH:mm' string
     String? formatTime(TimeOfDay? time) {
       if (time == null) return null;
       return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
     }
     return {
       'open': formatTime(startTime),
       'close': formatTime(endTime),
       'isOpen': isOpen, // Store the explicit isOpen flag
     };
  }

  @override
  List<Object?> get props => [startTime, endTime, isOpen];
}

// --- Main ServiceProviderModel ---

/// Represents a service provider entity with its details and configurations.
/// Includes fields to support multiple reservation types and partitioning.
class ServiceProviderModel extends Equatable {
  final String id; // Firestore document ID (matches provider's auth uid)
  final String businessName;
  final String category; // Main category
  final String? subCategory; // ADDED: Subcategory
  final String businessDescription;
  final String? mainImageUrl; // URL for the main display image
  final String? logoUrl; // URL for the provider's logo
  final List<String>? galleryImageUrls; // ADDED: List of gallery image URLs
  final Map<String, String> address; // Map: street, city, governorate, postalCode
  final String? governorateId; // ADDED: Crucial for finding partitioned data
  final GeoPoint? location; // Geographic coordinates
  final double rating; // Average user rating
  final int ratingCount; // Number of ratings received
  final bool isActive; // Whether the provider is active/published in the app
  final bool isApproved; // ADDED: Whether the provider is approved by admin
  final bool isFeatured; // Flag for featuring the provider (e.g., on home screen)
  final List<String> amenities; // List of amenities offered (e.g., "WiFi", "Parking")
  final PricingModel pricingModel; // Primary pricing model (Subscription, Reservation, Hybrid)
  final List<SubscriptionPlan> subscriptionPlans; // List of subscription plans offered
  final List<BookableService> bookableServices; // List of bookable services/classes
  final Map<String, OpeningHours> openingHours; // Map of day name (lowercase) to OpeningHours

  // --- Fields for Multi-Reservation Support (as per Guide) ---
  final List<String> supportedReservationTypes; // List of ReservationType enum names
  final Map<String, dynamic>? reservationTypeConfigs; // ADDED: Provider-specific settings (e.g., buffer time)
  final String? seatMapUrl; // Optional, relevant for seatBased type
  final int? maxGroupSize; // Optional, relevant for group type
  final List<Map<String, dynamic>>? accessOptions; // Optional, relevant for accessBased type
  final Map<String, dynamic>? serviceSpecificConfigs; // Generic map for additional configurations

  const ServiceProviderModel({
    required this.id,
    required this.businessName,
    required this.category,
    this.subCategory, // ADDED
    required this.businessDescription,
    this.mainImageUrl,
    this.logoUrl,
    this.galleryImageUrls, // ADDED
    required this.address,
    this.governorateId, // ADDED
    this.location,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.isActive,
    required this.isApproved, // ADDED
    this.isFeatured = false,
    this.amenities = const [],
    required this.pricingModel,
    this.subscriptionPlans = const [],
    this.bookableServices = const [],
    this.openingHours = const {},
    // Initialize new fields from Guide
    this.supportedReservationTypes = const [],
    this.reservationTypeConfigs, // ADDED
    this.seatMapUrl,
    this.maxGroupSize,
    this.accessOptions,
    this.serviceSpecificConfigs,
  });

  /// Creates a [ServiceProviderModel] from a Firestore document snapshot.
  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Safe access to data

    // --- Parse Existing Fields (with Safety Checks) ---
    final addressMap = (data['address'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''), // Handle null values in map
        ) ?? {};
    final amenitiesList = (data['amenities'] as List?)?.map((item) => item.toString()).toList() ?? [];
    final subscriptionPlansList = (data['subscriptionPlans'] as List?)
        ?.map((planData) {
          if (planData is Map<String, dynamic>) {
            final planId = planData['id']?.toString() ?? doc.id + DateTime.now().millisecondsSinceEpoch.toString();
            try { return SubscriptionPlan.fromMap(planData, planId); }
            catch (e) { print("Error parsing SubscriptionPlan (ID: ${planData['id']}): $e"); return null; }
          } return null;
        }).whereType<SubscriptionPlan>().toList() ?? [];
    final bookableServicesList = (data['bookableServices'] as List?)
        ?.map((serviceData) {
          if (serviceData is Map<String, dynamic>) {
             final serviceId = serviceData['id']?.toString() ?? doc.id + DateTime.now().microsecondsSinceEpoch.toString();
             try { return BookableService.fromMap(serviceData, serviceId); }
             catch (e) { print("Error parsing BookableService (ID: ${serviceData['id']}): $e"); return null; }
          } return null;
        }).whereType<BookableService>().toList() ?? [];
    final openingHoursData = data['openingHours'] as Map?;
    final Map<String, OpeningHours> parsedOpeningHours = {};
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    if (openingHoursData != null) {
       days.forEach((dayKey) {
          final actualKey = openingHoursData.keys.firstWhere((k) => k.toLowerCase() == dayKey, orElse: () => '');
          if (actualKey.isNotEmpty && openingHoursData[actualKey] is Map<String, dynamic>) {
             try { parsedOpeningHours[dayKey] = OpeningHours.fromMap(openingHoursData[actualKey]); }
             catch (e) { print("Error parsing OpeningHours for $dayKey: $e"); parsedOpeningHours[dayKey] = const OpeningHours(isOpen: false); }
          } else { parsedOpeningHours[dayKey] = const OpeningHours(isOpen: false); } // Missing or invalid data for the day
       });
    } else { days.forEach((dayKey) => parsedOpeningHours[dayKey] = const OpeningHours(isOpen: false)); }
    // --- End Parse Existing Fields ---

    // --- Construct the Model ---
    return ServiceProviderModel(
      id: doc.id, // Use doc.id as the provider's uid
      businessName: data['businessName'] as String? ?? '',
      category: data['businessCategory'] as String? ?? '', // Use correct key
      subCategory: data['businessSubCategory'] as String?, // ADDED: Parse subCategory
      businessDescription: data['businessDescription'] as String? ?? '',
      mainImageUrl: data['mainImageUrl'] as String?,
      logoUrl: data['logoUrl'] as String?,
      galleryImageUrls: List<String>.from(data['galleryImageUrls'] ?? []), // ADDED: Parse gallery URLs
      address: addressMap,
      governorateId: data['governorateId'] as String?, // ADDED: Parse governorateId
      location: data['location'] as GeoPoint?,
      rating: (data['averageRating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0, // Use 'averageRating' preferentially
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false, // Default to false if missing
      isApproved: data['isApproved'] as bool? ?? false, // ADDED: Parse approval status, default false
      isFeatured: data['isFeatured'] as bool? ?? false,
      amenities: amenitiesList,
      pricingModel: pricingModelFromString(data['pricingModel']),
      subscriptionPlans: subscriptionPlansList,
      bookableServices: bookableServicesList,
      openingHours: parsedOpeningHours,

      // Parse new fields for multi-reservation support based on Guide
      supportedReservationTypes: List<String>.from(data['supportedReservationTypes'] ?? []),
      reservationTypeConfigs: data['reservationTypeConfigs'] as Map<String, dynamic>?, // ADDED
      seatMapUrl: data['seatMapUrl'] as String?,
      maxGroupSize: (data['maxGroupSize'] as num?)?.toInt(),
      accessOptions: (data['accessOptions'] as List?)?.map((opt) {
         return opt is Map<String, dynamic> ? opt : null; // Ensure items are maps
      }).whereType<Map<String, dynamic>>().toList(), // Filter out nulls
      serviceSpecificConfigs: data['serviceSpecificConfigs'] as Map<String, dynamic>?,
    );
  }

  // --- Helper Getters for Address ---
  String? get street => address['street'];
  String? get city => address['city'];
  String? get governorate => address['governorate'];
  String? get postalCode => address['postalCode']; // ADDED: Postal code getter

  /// Converts this [ServiceProviderModel] object into a map suitable for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessCategory': category,
      'businessSubCategory': subCategory, // ADDED
      'businessDescription': businessDescription,
      'mainImageUrl': mainImageUrl,
      'logoUrl': logoUrl,
      'galleryImageUrls': galleryImageUrls, // ADDED
      'address': address,
      'governorateId': governorateId, // ADDED
      'location': location,
      'averageRating': rating, // Use consistent key 'averageRating'
      'ratingCount': ratingCount,
      'isActive': isActive,
      'isApproved': isApproved, // ADDED
      'isFeatured': isFeatured,
      'amenities': amenities,
      'pricingModel': pricingModel.name,
      // Store nested lists/maps using their toMap methods
      'subscriptionPlans': subscriptionPlans.map((plan) => plan.toMap()..['id'] = plan.id).toList(), // Include ID in map for clarity if needed elsewhere
      'bookableServices': bookableServices.map((service) => service.toMap()..['id'] = service.id).toList(),
      'openingHours': openingHours.map((key, value) => MapEntry(key, value.toMap())),
      // Include new fields in the map
      'supportedReservationTypes': supportedReservationTypes,
      'reservationTypeConfigs': reservationTypeConfigs, // ADDED
      'seatMapUrl': seatMapUrl,
      'maxGroupSize': maxGroupSize,
      'accessOptions': accessOptions,
      'serviceSpecificConfigs': serviceSpecificConfigs,
    };
  }

  /// Defines the properties used for Equatable comparison.
  @override
  List<Object?> get props => [
        id, businessName, category, subCategory, businessDescription, // ADDED subCategory
        mainImageUrl, logoUrl, galleryImageUrls, address, governorateId, // ADDED galleryImageUrls, governorateId
        location, rating, ratingCount, isActive, isApproved, isFeatured, // ADDED isApproved
        amenities, pricingModel, subscriptionPlans, bookableServices, openingHours,
        // Add new fields to props for comparison
        supportedReservationTypes, reservationTypeConfigs, seatMapUrl, maxGroupSize, // ADDED reservationTypeConfigs
        accessOptions, serviceSpecificConfigs,
      ];
}