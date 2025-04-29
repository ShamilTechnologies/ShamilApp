// lib/feature/home/data/service_provider_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import for TimeOfDay
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';

// --- Enum Definitions ---
enum PricingInterval { day, week, month, year }

PricingInterval pricingIntervalFromString(String? intervalString) {
  /* ... */
  switch (intervalString?.toLowerCase()) {
    case 'day':
      return PricingInterval.day;
    case 'week':
      return PricingInterval.week;
    case 'month':
      return PricingInterval.month;
    case 'year':
      return PricingInterval.year;
    default:
      return PricingInterval.month;
  }
}

enum PricingModel { subscription, reservation, hybrid, other }

PricingModel pricingModelFromString(String? modelString) {
  /* ... */
  switch (modelString?.toLowerCase()) {
    case 'subscription':
      return PricingModel.subscription;
    case 'reservation':
      return PricingModel.reservation;
    case 'hybrid':
      return PricingModel.hybrid;
    default:
      return PricingModel.other;
  }
}

// --- Nested Models ---
class SubscriptionPlan extends Equatable {
  /* ... (no changes needed) ... */
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final int intervalCount;
  final PricingInterval interval;
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.features = const [],
    required this.intervalCount,
    required this.interval,
  });
  factory SubscriptionPlan.fromMap(Map<String, dynamic> data, String id) {
    return SubscriptionPlan(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(data['features'] ?? []),
      intervalCount: (data['intervalCount'] as num?)?.toInt() ?? 1,
      interval: pricingIntervalFromString(data['interval']),
    );
  }
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'features': features,
        'intervalCount': intervalCount,
        'interval': interval.name,
      };
  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    List<String>? features,
    int? intervalCount,
    PricingInterval? interval,
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
  List<Object?> get props =>
      [id, name, description, price, features, intervalCount, interval];
}

// Renamed class from OperatingHours to OpeningHours
class OpeningHours extends Equatable {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isOpen;

  // Updated constructor name
  const OpeningHours({this.startTime, this.endTime, this.isOpen = true});

  // Updated factory name and return type
  factory OpeningHours.fromMap(Map<String, dynamic>? data) {
    print("  OpeningHours.fromMap received data (Simplified Logic + Trim): $data"); // Log input
    if (data == null) {
      print("    -> Returning default closed (data is null)");
      // Updated return type
      return const OpeningHours(isOpen: false);
    }

    // Helper function to parse time string 'HH:mm' into TimeOfDay
    TimeOfDay? parseTime(String? timeString) {
      print("      parseTime called with: '$timeString'");
      if (timeString == null) {
          print("        -> Returning null (input string is null)");
          return null;
      }
      // *** ADDED TRIM HERE ***
      final trimmedTimeString = timeString.trim();
      print("      trimmedTimeString: '$trimmedTimeString'");

      if (!trimmedTimeString.contains(':')) {
        print("        -> Returning null (trimmed string missing colon)");
        return null;
      }
      final parts = trimmedTimeString.split(':');
      if (parts.length != 2) {
         print("        -> Returning null (split length != 2)");
         return null;
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) {
        print("        -> Returning null (hour or minute parse failed on trimmed parts)");
        return null;
      }
      // Validate hour and minute ranges
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        print("        -> Returning null (hour/minute out of range)");
        return null;
      }
      final result = TimeOfDay(hour: hour, minute: minute);
      print("        -> Returning TimeOfDay: $result");
      return result;
    }

    // *** SIMPLIFIED LOGIC: Only rely on successful time parsing ***
    print("    -> Attempting to parse 'open': ${data['open']}");
    final TimeOfDay? startTimeValue = parseTime(data['open'] as String?);
    print("    -> Attempting to parse 'close': ${data['close']}");
    final TimeOfDay? endTimeValue = parseTime(data['close'] as String?);
    print("    -> Parsed startTimeValue: $startTimeValue");
    print("    -> Parsed endTimeValue: $endTimeValue");


    // Consider open ONLY if BOTH times were successfully parsed
    final bool isEffectivelyOpen = startTimeValue != null && endTimeValue != null;
    print("    -> Calculated isEffectivelyOpen (Simplified + Trim): $isEffectivelyOpen");


    if (isEffectivelyOpen) {
      print("    -> Returning open with startTime: $startTimeValue, endTime: $endTimeValue");
      // Updated return type
      return OpeningHours(
        startTime: startTimeValue, // Already confirmed not null
        endTime: endTimeValue,   // Already confirmed not null
        isOpen: true,
      );
    } else {
      // If either time parsing failed
      print("    -> Returning closed (time parsing failed or data missing)");
      // Updated return type
      return const OpeningHours(isOpen: false);
    }
  }

  Map<String, dynamic> toMap() {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      'open': formatTime(startTime),
      'close': formatTime(endTime),
      'isOpen': isOpen,
    };
  }

  @override
  List<Object?> get props => [startTime, endTime, isOpen];
}

// --- Main Model ---
class ServiceProviderModel extends Equatable {
  final String id;
  final String businessName;
  final String category;
  final String businessDescription;
  final String? mainImageUrl;
  final String? logoUrl;
  final Map<String, String> address;
  final GeoPoint? location;
  final double rating;
  final int ratingCount;
  final bool isActive;
  final bool isFeatured;
  final List<String> amenities;
  final PricingModel pricingModel;
  final List<SubscriptionPlan> subscriptionPlans;
  final List<BookableService> bookableServices;
  // Renamed field and type
  final Map<String, OpeningHours> openingHours;

  // Updated constructor parameter name and type
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
    required this.pricingModel,
    this.subscriptionPlans = const [],
    this.bookableServices = const [],
    this.openingHours = const {}, // Updated field name
  });

  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    print("\n--- ServiceProviderModel.fromFirestore (ID: ${doc.id}) ---");
    print("Raw Firestore Data Keys: ${data.keys.toList()}"); // Log all keys received

    // ... (parsing for address, amenities, plans, services remains the same) ...
    final addressMap = (data['address'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        {};
    final amenitiesList =
        (data['amenities'] as List?)?.map((item) => item.toString()).toList() ??
            [];
    final subscriptionPlansList = (data['subscriptionPlans'] as List?)
            ?.map((planData) {
              if (planData is Map<String, dynamic>) {
                final planId = planData['id']?.toString() ??
                    doc.id + DateTime.now().millisecondsSinceEpoch.toString();
                return SubscriptionPlan.fromMap(planData, planId);
              }
              return null;
            })
            .whereType<SubscriptionPlan>()
            .toList() ??
        [];
    final bookableServicesList = (data['bookableServices'] as List?)
            ?.map((serviceData) {
              if (serviceData is Map<String, dynamic>) {
                return BookableService.fromMap(serviceData);
              }
              return null;
            })
            .whereType<BookableService>()
            .toList() ??
        [];

    // *** UPDATED Opening Hours Parsing Logic with EXTRA LOGGING ***
    // Renamed field being accessed
    print("Attempting to access 'openingHours' field from Firestore data...");
    final dynamic rawOpeningHoursValue = data['openingHours']; // Get the raw value first
    print("Raw value for 'openingHours' field: $rawOpeningHoursValue");
    print("Type of raw value for 'openingHours': ${rawOpeningHoursValue?.runtimeType}");

    final openingHoursData = rawOpeningHoursValue as Map?; // Cast to Map AFTER checking
    print("Casted openingHoursData (as Map?): $openingHoursData");

    // Updated map type
    final Map<String, OpeningHours> parsedOpeningHours = {};
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    // Iterate through standard days to ensure all are processed
    for (var dayKey in days) {
      // Check if data exists for this day in the Firestore map
      // Updated variable name
      if (openingHoursData != null &&
          openingHoursData.containsKey(dayKey)) {
        final dayData = openingHoursData[dayKey];
        if (dayData is Map<String, dynamic>) {
          // print("  Parsing day: '$dayKey', data: $dayData"); // Keep for debugging
          try {
            // Use the most recent defensive OpeningHours.fromMap
            // Updated class name
            parsedOpeningHours[dayKey] = OpeningHours.fromMap(dayData);
            // print("    -> Parsed successfully: ${parsedOpeningHours[dayKey]}"); // Keep for debugging
          } catch (e) {
            print("    -> ERROR parsing day '$dayKey': $e");
            // Updated class name
            parsedOpeningHours[dayKey] =
                const OpeningHours(isOpen: false); // Default closed on error
          }
        } else {
          // Data for the day exists but is not a map (invalid structure)
           print("  Invalid data type for day '$dayKey': ${dayData?.runtimeType}. Setting to closed."); // Log type
           // Updated class name
          parsedOpeningHours[dayKey] = const OpeningHours(isOpen: false);
        }
      } else {
        // Day key is completely missing from Firestore data OR openingHoursData itself was null
        // print("  Day '$dayKey' was missing in openingHoursData or data was null. Setting to closed."); // Keep for debugging
        // Updated class name
        parsedOpeningHours[dayKey] = const OpeningHours(isOpen: false);
      }
    }
    print("Final parsedOpeningHours map: $parsedOpeningHours");
    // --- End Opening Hours Parsing ---

    final model = ServiceProviderModel(
      id: doc.id,
      businessName: data['businessName'] ?? '',
      category: data['businessCategory'] ?? '',
      businessDescription: data['businessDescription'] ?? '',
      mainImageUrl: data['mainImageUrl'],
      logoUrl: data['logoUrl'],
      address: addressMap,
      location: data['location'],
      rating: (data['averageRating'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] ?? data['isPublished'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      amenities: amenitiesList,
      pricingModel: pricingModelFromString(data['pricingModel']),
      subscriptionPlans: subscriptionPlansList,
      bookableServices: bookableServicesList,
      openingHours: parsedOpeningHours, // Updated field name
    );
    print("--- End ServiceProviderModel.fromFirestore ---");
    return model;
  }

  String? get street => address['street'];
  String? get governorate => address['governorate'];
  String? get city => address['city'];

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessCategory': category,
      'businessDescription': businessDescription,
      'mainImageUrl': mainImageUrl,
      'logoUrl': logoUrl,
      'address': address,
      'location': location,
      'averageRating': rating,
      'ratingCount': ratingCount,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'amenities': amenities,
      'pricingModel': pricingModel.name,
      'subscriptionPlans': subscriptionPlans
          .map((plan) => plan.toMap()..['id'] = plan.id)
          .toList(),
      'bookableServices': bookableServices
          .map((service) => service.toMap()..['id'] = service.id)
          .toList(),
      // Updated field name
      'openingHours':
          openingHours.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        category,
        businessDescription,
        mainImageUrl,
        logoUrl,
        address,
        location,
        rating,
        ratingCount,
        isActive,
        isFeatured,
        amenities,
        pricingModel,
        subscriptionPlans,
        bookableServices,
        openingHours, // Updated field name
      ];
}
