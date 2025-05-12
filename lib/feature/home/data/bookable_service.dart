/// File: lib/feature/home/data/bookable_service.dart
/// --- UPDATED TO MATCH SERVICE PROVIDER PLATFORM DEFINITION ---
library;

import 'package:equatable/equatable.dart';
// Import ReservationType enum and helpers
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show ReservationType, ReservationTypeExtension, reservationTypeFromString;

/// Represents a service or class that can be booked, potentially with a specific reservation type.
class BookableService extends Equatable {
  final String id; // Unique identifier for the service
  final String name; // Name of the service or class
  final String description; // Description of the service
  final ReservationType type; // The type of reservation this service uses
  final int?
      durationMinutes; // Duration of the service/slot in minutes (Optional)
  final double? price; // Price per booking/slot (Optional)
  final int? capacity; // Max number of people per slot (Optional)
  final Map<String, dynamic>? configData; // Optional extra config

  const BookableService({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.durationMinutes,
    this.price,
    this.capacity,
    this.configData,
  });

  /// Creates a BookableService instance from a map (e.g., Firestore data).
  factory BookableService.fromMap(Map<String, dynamic> map, String serviceId) {
    return BookableService(
      id: serviceId, // Use the provided ID
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: reservationTypeFromString(map['type'] as String?), // Parse type
      durationMinutes:
          (map['durationMinutes'] as num?)?.toInt(), // Keep optional
      price: (map['price'] as num?)?.toDouble(), // Keep optional
      capacity: (map['capacity'] as num?)?.toInt(), // Keep optional
      configData: map['configData'] != null
          ? Map<String, dynamic>.from(map['configData'])
          : null, // Parse configData
    );
  }

  /// Converts the BookableService instance to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      // ID is typically the document ID, not stored in the map
      'name': name,
      'description': description,
      'type': type.typeString, // Store enum string value using extension
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (price != null) 'price': price,
      if (capacity != null) 'capacity': capacity,
      if (configData != null) 'configData': configData,
    };
  }

  /// Creates a copy of the instance with optional updated fields.
  BookableService copyWith({
    String? id,
    String? name,
    String? description,
    ReservationType? type,
    int? durationMinutes,
    double? price,
    int? capacity,
    Map<String, dynamic>? configData,
    // Flags to explicitly set fields to null if needed
    bool forceDurationNull = false,
    bool forcePriceNull = false,
    bool forceCapacityNull = false,
    bool forceConfigDataNull = false,
  }) {
    return BookableService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      durationMinutes:
          forceDurationNull ? null : (durationMinutes ?? this.durationMinutes),
      price: forcePriceNull ? null : (price ?? this.price),
      capacity: forceCapacityNull ? null : (capacity ?? this.capacity),
      configData: forceConfigDataNull ? null : (configData ?? this.configData),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        durationMinutes,
        price,
        capacity,
        configData,
      ];

  @override
  String toString() {
    return 'BookableService(id: $id, name: $name, type: ${type.typeString}, duration: $durationMinutes min, price: $price, capacity: $capacity)';
  }
}
