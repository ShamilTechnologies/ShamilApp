// lib/feature/home/data/banner_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Firestore Timestamps and DocumentSnapshot
import 'package:equatable/equatable.dart'; // For value-based equality

/// Represents a banner displayed in the application, typically for promotions,
/// navigation, or highlighting specific content.
class BannerModel extends Equatable {
  /// The unique identifier for the banner, typically the Firestore document ID.
  final String id;

  /// The URL of the image to be displayed for the banner.
  /// This is expected to be a valid URL pointing to an image resource.
  final String imageUrl;

  /// Describes the type of action or destination the banner leads to when tapped.
  /// Standardized strings are recommended for consistent handling.
  /// Examples: 'serviceProvider', 'category', 'externalUrl', 'internalScreen', 'offer'.
  final String? targetType;

  /// If the [targetType] refers to a specific entity (like 'serviceProvider' or 'category'),
  /// this field holds the unique identifier of that entity (e.g., provider ID, category name/slug).
  final String? targetId;

  /// If the [targetType] is 'externalUrl', this field holds the complete URL
  /// that the application should navigate to (e.g., using `url_launcher`).
  final String? targetUrl;

  /// Optional title text that could be displayed on or associated with the banner.
  final String? title;

  /// Optional descriptive text providing more context for the banner.
  final String? description;

  /// Determines the display order of the banner relative to others.
  /// Higher values typically indicate higher priority (displayed first).
  final int priority;

  /// Flag indicating whether the banner is currently active and should be displayed.
  final bool isActive;

  /// Timestamp indicating when the banner document was created in Firestore.
  final Timestamp? createdAt;

  /// Timestamp indicating when the banner document was last updated in Firestore.
  final Timestamp? updatedAt;

  /// Creates an instance of [BannerModel].
  ///
  /// Requires [id] and [imageUrl]. Other fields are optional.
  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.targetType,
    this.targetId,
    this.targetUrl,
    this.title,
    this.description,
    this.priority = 0, // Default priority is 0
    this.isActive = true, // Default to active
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a [BannerModel] instance from a Firestore [DocumentSnapshot].
  /// Handles potential null values and type casting safely.
  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    // Cast the document data to a Map, providing an empty map as fallback.
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to safely get a value and cast it to a specific type.
    T? safeGet<T>(String key) {
      final value = data[key];
      if (value is T) {
        return value;
      }
      // Optional: Add more specific type checks if needed (e.g., num to int/double)
      // if (T == int && value is num) return value.toInt() as T?;
      // if (T == double && value is num) return value.toDouble() as T?;
      return null;
    }

    return BannerModel(
      id: doc.id, // Use the Firestore document ID as the banner ID
      imageUrl: safeGet<String>('imageUrl') ?? '', // Default to empty string if missing
      targetType: safeGet<String>('targetType'),
      targetId: safeGet<String>('targetId'),
      targetUrl: safeGet<String>('targetUrl'),
      title: safeGet<String>('title'),
      description: safeGet<String>('description'),
      priority: (data['priority'] as num?)?.toInt() ?? 0, // Safe parsing for priority
      isActive: safeGet<bool>('isActive') ?? true, // Default to true if missing
      createdAt: safeGet<Timestamp>('createdAt'),
      updatedAt: safeGet<Timestamp>('updatedAt'),
    );
  }

  /// Converts this [BannerModel] instance into a map structure,
  /// suitable for JSON serialization or debugging.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'targetType': targetType,
      'targetId': targetId,
      'targetUrl': targetUrl,
      'title': title,
      'description': description,
      'priority': priority,
      'isActive': isActive,
      // Timestamps are often handled differently depending on serialization needs
      // (e.g., convert to ISO string or milliseconds). Keeping as Timestamp here.
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // --- Equatable Implementation ---

  /// Returns a list of the properties that will be used for comparing
  /// instances of [BannerModel] for equality.
  @override
  List<Object?> get props => [
        id,
        imageUrl,
        targetType,
        targetId,
        targetUrl,
        title,
        description,
        priority,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Setting `stringify` to true enhances the default `toString()` output
  /// for easier debugging, including all properties listed in `props`.
  @override
  bool get stringify => true;
}