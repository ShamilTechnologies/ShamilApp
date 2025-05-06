/// File: lib/feature/home/data/bookable_service.dart
/// Represents a service or class that can be booked.
library;

import 'package:equatable/equatable.dart';
// Import ReservationType enum
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart'
    show ReservationType, ReservationTypeExtension, reservationTypeFromString;

/// Represents a service or class that can be booked, potentially with a specific reservation type.
class BookableService extends Equatable {
  final String id; // Unique identifier for the service
  final String
      name; // Name of the service or class (e.g., "Personal Training", "Yoga Class")
  final String description; // Description of the service
  final ReservationType
      type; // ADDED: The type of reservation this service uses
  final int?
      durationMinutes; // Duration of the service/slot in minutes (Optional)
  final double? price; // Price per booking/slot (Optional)
  final int?
      capacity; // Max number of people per slot (Optional, defaults based on type?)
  final Map<String, dynamic>? configData; // ADDED: Optional extra config

  const BookableService({
    required this.id,
    required this.name,
    required this.description,
    required this.type, // ADDED: Make type required
    this.durationMinutes,
    this.price,
    this.capacity,
    this.configData, // ADDED
  });

  /// Creates a BookableService instance from a map (e.g., Firestore data).
  factory BookableService.fromMap(Map<String, dynamic> map, String serviceId) {
    return BookableService(
      id: serviceId, // Use the provided ID
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: reservationTypeFromString(
          map['type'] as String?), // ADDED: Parse type
      durationMinutes:
          (map['durationMinutes'] as num?)?.toInt(), // Keep optional
      price: (map['price'] as num?)?.toDouble(), // Keep optional
      capacity: (map['capacity'] as num?)?.toInt(), // Keep optional
      configData:
          map['configData'] as Map<String, dynamic>?, // ADDED: Parse configData
    );
  }

  /// Converts the BookableService instance to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      // ID is typically the document ID, not stored in the map
      'name': name,
      'description': description,
      'type': type.typeString, // ADDED: Store enum string value
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (price != null) 'price': price,
      if (capacity != null) 'capacity': capacity,
      if (configData != null) 'configData': configData, // ADDED
    };
  }

  /// Creates a copy of the instance with optional updated fields.
  BookableService copyWith({
    String? id,
    String? name,
    String? description,
    ReservationType? type, // ADDED
    int? durationMinutes,
    double? price,
    int? capacity,
    Map<String, dynamic>? configData, // ADDED
  }) {
    return BookableService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type, // ADDED
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      configData: configData ?? this.configData, // ADDED
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type, // ADDED
        durationMinutes,
        price,
        capacity,
        configData, // ADDED
      ];

  @override
  String toString() {
    return 'BookableService(id: $id, name: $name, type: $type, duration: $durationMinutes min, price: $price, capacity: $capacity)';
  }
}
