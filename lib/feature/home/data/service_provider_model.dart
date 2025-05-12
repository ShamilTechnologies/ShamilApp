// Suggested Updates for: lib/feature/home/data/service_provider_model.dart
// Add the following fields and update the constructor, fromFirestore, and props.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming these imports are correct
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show ReservationType, reservationTypeFromString, ReservationTypeExtension;
// ADDED: Import Review Model (define this class separately)
// import 'package:shamil_mobile_app/feature/details/data/review_model.dart';

// --- Enums (Keep existing definitions) ---
enum PricingInterval { day, week, month, year }

PricingInterval pricingIntervalFromString(String? intervalString) {
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
  switch (modelString?.toLowerCase()) {
    case 'subscription':
      return PricingModel.subscription;
    case 'reservation':
      return PricingModel.reservation;
    case 'hybrid':
      return PricingModel.hybrid;
    case 'other':
      return PricingModel.other;
    default:
      return PricingModel.other;
  }
}

// --- Nested Classes (Keep existing definitions: OpeningHoursDay, SubscriptionPlan, AccessPassOption) ---
class OpeningHoursDay extends Equatable {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isOpen;
  const OpeningHoursDay({this.startTime, this.endTime, this.isOpen = true});

  factory OpeningHoursDay.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const OpeningHoursDay(isOpen: false);
    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      final trimmed = timeString.trim();
      if (!trimmed.contains(':')) return null;
      final parts = trimmed.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final startTimeValue = parseTime(data['open'] as String?);
    final endTimeValue = parseTime(data['close'] as String?);
    final bool explicitIsOpen = data['isOpen'] as bool? ?? true;
    final bool hasValidTimes = startTimeValue != null && endTimeValue != null;
    final bool isEffectivelyOpen = explicitIsOpen && hasValidTimes;
    return OpeningHoursDay(
      startTime: startTimeValue,
      endTime: endTimeValue,
      isOpen: isEffectivelyOpen,
    );
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

class SubscriptionPlan extends Equatable {
  /* ... Keep existing implementation ... */
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
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(
        data['features'] as List<dynamic>? ?? [],
      ),
      intervalCount: (data['intervalCount'] as num?)?.toInt() ?? 1,
      interval: pricingIntervalFromString(data['interval'] as String?),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'features': features,
      'intervalCount': intervalCount,
      'interval': interval.name,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, price, features, intervalCount, interval];
}

class AccessPassOption extends Equatable {
  /* ... Keep existing implementation ... */
  final String id;
  final String label;
  final double price;
  final int durationHours;
  const AccessPassOption({
    required this.id,
    required this.label,
    required this.price,
    required this.durationHours,
  });
  factory AccessPassOption.fromMap(Map<String, dynamic> data) {
    /* ... */
    return AccessPassOption(
      id: data['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: data['label'] as String? ?? 'Pass',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      durationHours: (data['durationHours'] as num?)?.toInt() ?? 0,
    );
  }
  Map<String, dynamic> toMap() {
    /* ... */
    return {
      'id': id,
      'label': label,
      'price': price,
      'durationHours': durationHours,
    };
  }

  @override
  List<Object?> get props => [id, label, price, durationHours];
}
// --- End Nested Classes ---

/// Represents the main data model for a Service Provider entity.
/// Includes details and configurations for reservations and subscriptions.
class ServiceProviderModel extends Equatable {
  // Existing Fields
  final String id;
  final String businessName;
  final String category;
  final String? subCategory;
  final String businessDescription; // Used for Detailed Desc
  final String? mainImageUrl;
  final String? logoUrl;
  final List<String>? galleryImageUrls; // Used for Gallery
  final Map<String, String> address;
  final String? governorateId;
  final GeoPoint? location;
  final double rating; // averageRating
  final int ratingCount;
  final bool isActive;
  final bool isApproved;
  final bool isFeatured;
  final List<String> amenities;
  final PricingModel pricingModel;
  final List<SubscriptionPlan> subscriptionPlans;
  final List<BookableService>
      bookableServices; // Corresponds to "Specific Services"
  final Map<String, OpeningHoursDay> openingHours; // Used for Operating Hours
  final List<String> supportedReservationTypes;
  final Map<String, dynamic>? reservationTypeConfigs;
  final String? seatMapUrl;
  final int? maxGroupSize;
  final List<AccessPassOption>? accessOptions;
  final Map<String, dynamic>? serviceSpecificConfigs;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  // --- NEW FIELDS from Plan ---
  final String? website; // Added for Contact Info/Action Bar
  final String? primaryPhoneNumber; // For Call button
  final List<String>? additionalPhoneNumbers; // For Contact Info
  final String? primaryEmail; // For Email button
  final List<String>? additionalEmails; // For Contact Info
  final Map<String, String>?
      socialMediaLinks; // e.g., {'facebook': 'url', 'instagram': 'url'}
  final int? yearsInBusiness; // For Overview
  final List<String>? certifications; // For Business Info
  final List<String>? awards; // For Business Info
  final List<String>? paymentMethodsAccepted; // For Business Info
  final String? verificationStatus; // e.g., "Verified", "Pending", "None"
  final String?
      averageResponseTime; // e.g., "Within an hour", "1-2 business days"
  // Full reviews need a separate model and likely separate fetching mechanism
  // final List<ReviewModel>? reviews; // See note below

  const ServiceProviderModel({
    // Existing required
    required this.id,
    required this.businessName,
    required this.category,
    required this.businessDescription,
    required this.address,
    required this.isActive,
    required this.isApproved,
    required this.pricingModel,
    required this.createdAt,
    // Existing optional
    this.subCategory,
    this.mainImageUrl,
    this.logoUrl,
    this.galleryImageUrls,
    this.governorateId,
    this.location,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFeatured = false,
    this.amenities = const [],
    this.subscriptionPlans = const [],
    this.bookableServices = const [],
    this.openingHours = const {},
    this.supportedReservationTypes = const [],
    this.reservationTypeConfigs,
    this.seatMapUrl,
    this.maxGroupSize,
    this.accessOptions,
    this.serviceSpecificConfigs,
    this.updatedAt,
    // New optional fields
    this.website,
    this.primaryPhoneNumber,
    this.additionalPhoneNumbers,
    this.primaryEmail,
    this.additionalEmails,
    this.socialMediaLinks,
    this.yearsInBusiness,
    this.certifications,
    this.awards,
    this.paymentMethodsAccepted,
    this.verificationStatus,
    this.averageResponseTime,
    // this.reviews, // Reviews likely fetched separately
  });

  /// Creates a [ServiceProviderModel] from a Firestore document snapshot.
  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // --- Re-use existing parsing logic ---
    final Map<String, String> addressMap = {};
    (data['address'] as Map?)?.forEach((key, value) {
      if (key is String && value is String?) {
        addressMap[key] = value ?? '';
      }
    });
    final List<String> amenitiesList =
        List<String>.from(data['amenities'] as List? ?? []);
    final Map<String, OpeningHoursDay> parsedOpeningHours = {};
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final openingHoursData = data['openingHours'] as Map?;
    if (openingHoursData != null) {
      days.forEach((dayKey) {
        final actualKey = openingHoursData.keys.firstWhere(
            (k) => k.toString().toLowerCase() == dayKey,
            orElse: () => '');
        if (actualKey.isNotEmpty &&
            openingHoursData[actualKey] is Map<String, dynamic>) {
          try {
            parsedOpeningHours[dayKey] =
                OpeningHoursDay.fromMap(openingHoursData[actualKey]);
          } catch (e) {
            print("Error parsing OpeningHoursDay for $dayKey: $e");
            parsedOpeningHours[dayKey] = const OpeningHoursDay(isOpen: false);
          }
        } else {
          parsedOpeningHours[dayKey] = const OpeningHoursDay(isOpen: false);
        }
      });
    } else {
      days.forEach((dayKey) =>
          parsedOpeningHours[dayKey] = const OpeningHoursDay(isOpen: false));
    }
    final List<SubscriptionPlan> subscriptionPlansList =
        (data['subscriptionPlans'] as List?)
                ?.map((planData) {
                  if (planData is Map<String, dynamic>) {
                    final String planId = planData['id']?.toString() ??
                        '${doc.id}_plan_${DateTime.now().microsecondsSinceEpoch}';
                    try {
                      return SubscriptionPlan.fromMap(planData, planId);
                    } catch (e) {
                      print(
                          "Error parsing SubscriptionPlan (ID: ${planData['id']}): $e");
                      return null;
                    }
                  }
                  return null;
                })
                .whereType<SubscriptionPlan>()
                .toList() ??
            [];
    final List<BookableService> bookableServicesList =
        (data['bookableServices'] as List?)
                ?.map((serviceData) {
                  if (serviceData is Map<String, dynamic>) {
                    final String serviceId = serviceData['id']?.toString() ??
                        '${doc.id}_service_${DateTime.now().microsecondsSinceEpoch}';
                    try {
                      return BookableService.fromMap(serviceData, serviceId);
                    } catch (e) {
                      print(
                          "Error parsing BookableService (ID: ${serviceData['id']}): $e");
                      return null;
                    }
                  }
                  return null;
                })
                .whereType<BookableService>()
                .toList() ??
            [];
    final List<AccessPassOption>? accessOptionsList = (data['accessOptions']
            as List?)
        ?.map((optionData) {
          if (optionData is Map<String, dynamic>) {
            try {
              return AccessPassOption.fromMap(optionData);
            } catch (e) {
              print("Error parsing AccessPassOption: $e. Data: $optionData");
              return null;
            }
          }
          return null;
        })
        .whereType<AccessPassOption>()
        .toList();
    // --- End re-used parsing logic ---

    // Safely parse new fields
    final Map<String, String> socialLinksMap = {};
    (data['socialMediaLinks'] as Map?)?.forEach((key, value) {
      if (key is String && value is String) {
        socialLinksMap[key] = value;
      }
    });

    return ServiceProviderModel(
      id: doc.id,
      businessName: data['businessName'] as String? ?? '',
      category: data['businessCategory'] as String? ?? '',
      subCategory: data['businessSubCategory'] as String?,
      businessDescription: data['businessDescription'] as String? ??
          data['description'] as String? ??
          '', // Allow fallback from 'description'
      mainImageUrl: data['mainImageUrl'] as String?,
      logoUrl: data['logoUrl'] as String?,
      galleryImageUrls: List<String>.from(data['galleryImageUrls'] ?? []),
      address: addressMap,
      governorateId: data['governorateId'] as String?,
      location: data['location'] as GeoPoint?,
      rating: (data['averageRating'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      amenities: amenitiesList,
      pricingModel: pricingModelFromString(data['pricingModel']),
      subscriptionPlans: subscriptionPlansList,
      bookableServices: bookableServicesList,
      openingHours: parsedOpeningHours,
      supportedReservationTypes:
          List<String>.from(data['supportedReservationTypes'] ?? []),
      reservationTypeConfigs:
          data['reservationTypeConfigs'] as Map<String, dynamic>?,
      seatMapUrl: data['seatMapUrl'] as String?,
      maxGroupSize: (data['maxGroupSize'] as num?)?.toInt(),
      accessOptions: accessOptionsList,
      serviceSpecificConfigs:
          data['serviceSpecificConfigs'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,

      // Parse new fields
      website: data['website'] as String?,
      primaryPhoneNumber: data['primaryPhoneNumber'] as String?,
      additionalPhoneNumbers:
          List<String>.from(data['additionalPhoneNumbers'] ?? []),
      primaryEmail: data['primaryEmail'] as String?,
      additionalEmails: List<String>.from(data['additionalEmails'] ?? []),
      socialMediaLinks: socialLinksMap,
      yearsInBusiness: (data['yearsInBusiness'] as num?)?.toInt(),
      certifications: List<String>.from(data['certifications'] ?? []),
      awards: List<String>.from(data['awards'] ?? []),
      paymentMethodsAccepted:
          List<String>.from(data['paymentMethodsAccepted'] ?? []),
      verificationStatus: data['verificationStatus'] as String?,
      averageResponseTime: data['averageResponseTime'] as String?,
      // Reviews are likely fetched separately
    );
  }

  // Helper Getters (keep existing)
  String? get street => address['street'];
  String? get city => address['city'];
  String? get governorate => address['governorate'];
  String? get postalCode => address['postalCode'];

  @override
  List<Object?> get props => [
        // Existing props
        id, businessName, category, subCategory, businessDescription,
        mainImageUrl, logoUrl, galleryImageUrls, address, governorateId,
        location, rating, ratingCount, isActive, isApproved, isFeatured,
        amenities, pricingModel, subscriptionPlans, bookableServices,
        openingHours,
        supportedReservationTypes, reservationTypeConfigs, seatMapUrl,
        maxGroupSize,
        accessOptions, serviceSpecificConfigs, createdAt, updatedAt,
        // New props
        website, primaryPhoneNumber, additionalPhoneNumbers, primaryEmail,
        additionalEmails, socialMediaLinks, yearsInBusiness, certifications,
        awards, paymentMethodsAccepted, verificationStatus, averageResponseTime,
      ];
}

// TODO: Define ReviewModel separately (e.g., in feature/details/data/review_model.dart)
// class ReviewModel extends Equatable {
//   final String id;
//   final String reviewerId;
//   final String reviewerName;
//   final String? reviewerAvatarUrl;
//   final int rating; // 1-5
//   final String comment;
//   final Timestamp createdAt;
//   // Optional: Provider response
//   final String? providerResponse;
//   final Timestamp? responseCreatedAt;
//   // ... constructor, fromFirestore, props
// }
