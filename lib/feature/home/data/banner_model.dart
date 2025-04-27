import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart'; // For immutable annotation

@immutable // Mark the class as immutable
class BannerModel extends Equatable {
  final String id;          // Unique identifier for the banner (e.g., Firestore document ID)
  final String imageUrl;    // URL of the banner image
  final String title;       // Title or short description (optional, could be used for accessibility or overlay)
  final String? targetId;   // ID of the entity to navigate to (e.g., providerId, offerId)
  final String? targetType; // Type of the target entity ('provider', 'offer', 'external_link', etc.)

  // Use a const constructor for better performance with immutable classes
  const BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.targetId,
    this.targetType,
  });

  // Factory constructor for creating from a map (e.g., Firestore data)
  factory BannerModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BannerModel(
      id: documentId,
      imageUrl: data['imageUrl'] as String? ?? '', // Provide default empty string
      title: data['title'] as String? ?? '',       // Provide default empty string
      targetId: data['targetId'] as String?,       // Nullable
      targetType: data['targetType'] as String?,   // Nullable
    );
  }

  // Method to convert to a map (useful for debugging or writing back)
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'targetId': targetId,
      'targetType': targetType,
      // ID is usually the document ID, not stored within the map itself
    };
  }

  // Implement props for Equatable comparison
  @override
  List<Object?> get props => [id, imageUrl, title, targetId, targetType];

  // Optional: Override toString for better debugging
  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, imageUrl: $imageUrl, targetType: $targetType, targetId: $targetId)';
  }
}
