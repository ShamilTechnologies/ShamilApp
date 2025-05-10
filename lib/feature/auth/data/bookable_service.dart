/// File: lib/feature/auth/data/bookable_service.dart
/// --- Represents a service/class/resource, with nullable fields ---
library;

import 'package:equatable/equatable.dart';
// Import ReservationType enum from reservation_model
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart'
    show ReservationType, reservationTypeFromString, ReservationTypeExtension;

class BookableService extends Equatable {
  final String id; // Unique identifier for the service
  final String name;
  final String description;
  final ReservationType type; // Type of service this represents
  final int? durationMinutes; // Duration (nullable)
  final double? price; // Price (nullable)
  final int? capacity; // Max people (nullable)
  final Map<String, dynamic>? configData; // Optional type-specific config

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
    // Determine type safely
    ReservationType serviceType =
        reservationTypeFromString(map['type'] as String?);

    return BookableService(
      id: serviceId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: serviceType,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      price: (map['price'] as num?)?.toDouble(),
      capacity: (map['capacity'] as num?)?.toInt(),
      configData: map['configData'] != null
          ? Map<String, dynamic>.from(map['configData'])
          : null,
    );
  }

  /// Converts the BookableService instance to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      // ID is typically the document ID, not stored in the map
      'name': name,
      'description': description,
      'type': type.typeString, // Store enum name string
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
    bool forceDurationNull = false, // Flags to explicitly set to null
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
