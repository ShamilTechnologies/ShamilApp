import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String reservationId;
  final String userId;
  final String userName;
  final String providerId;
  final String? serviceId;
  final double rating;
  final String comment;
  final List<String>? photos;
  final Map<String, double>?
      categoryRatings; // e.g., {"cleanliness": 4.5, "service": 5.0}
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isAnonymous;
  final bool isVerified; // Whether the reviewer actually attended
  final Map<String, dynamic>?
      metadata; // Additional data like tags, sentiment, etc.

  const ReviewModel({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.userName,
    required this.providerId,
    this.serviceId,
    required this.rating,
    required this.comment,
    this.photos,
    this.categoryRatings,
    required this.createdAt,
    this.updatedAt,
    this.isAnonymous = false,
    this.isVerified = false,
    this.metadata,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      reservationId: data['reservationId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      serviceId: data['serviceId'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String? ?? '',
      photos: data['photos'] != null
          ? List<String>.from(data['photos'] as List)
          : null,
      categoryRatings: data['categoryRatings'] != null
          ? Map<String, double>.from(
              (data['categoryRatings'] as Map).map(
                (key, value) => MapEntry(
                  key as String,
                  (value as num).toDouble(),
                ),
              ),
            )
          : null,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      if (serviceId != null) 'serviceId': serviceId,
      'rating': rating,
      'comment': comment,
      if (photos != null) 'photos': photos,
      if (categoryRatings != null) 'categoryRatings': categoryRatings,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      'isAnonymous': isAnonymous,
      'isVerified': isVerified,
      if (metadata != null) 'metadata': metadata,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? reservationId,
    String? userId,
    String? userName,
    String? providerId,
    String? serviceId,
    double? rating,
    String? comment,
    List<String>? photos,
    Map<String, double>? categoryRatings,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isAnonymous,
    bool? isVerified,
    Map<String, dynamic>? metadata,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      providerId: providerId ?? this.providerId,
      serviceId: serviceId ?? this.serviceId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reservationId,
        userId,
        userName,
        providerId,
        serviceId,
        rating,
        comment,
        photos,
        categoryRatings,
        createdAt,
        updatedAt,
        isAnonymous,
        isVerified,
        metadata,
      ];
}
