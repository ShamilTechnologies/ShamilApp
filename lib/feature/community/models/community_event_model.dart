import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CommunityEventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String organizerId;
  final String organizerName;
  final DateTime date;
  final String location;
  final String governorateId;
  final int participantsCount;
  final int maxParticipants;
  final bool isFeatured;
  final List<String> participantIds;
  final List<String> tags;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final DateTime createdAt;

  const CommunityEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    required this.date,
    required this.location,
    required this.governorateId,
    required this.participantsCount,
    required this.maxParticipants,
    this.isFeatured = false,
    required this.participantIds,
    required this.tags,
    required this.status,
    required this.createdAt,
  });

  factory CommunityEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityEventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      governorateId: data['governorateId'] ?? '',
      participantsCount: data['participantsCount'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 50,
      isFeatured: data['isFeatured'] ?? false,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'upcoming',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'date': Timestamp.fromDate(date),
      'location': location,
      'governorateId': governorateId,
      'participantsCount': participantsCount,
      'maxParticipants': maxParticipants,
      'isFeatured': isFeatured,
      'participantIds': participantIds,
      'tags': tags,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CommunityEventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? organizerId,
    String? organizerName,
    DateTime? date,
    String? location,
    String? governorateId,
    int? participantsCount,
    int? maxParticipants,
    bool? isFeatured,
    List<String>? participantIds,
    List<String>? tags,
    String? status,
    DateTime? createdAt,
  }) {
    return CommunityEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      date: date ?? this.date,
      location: location ?? this.location,
      governorateId: governorateId ?? this.governorateId,
      participantsCount: participantsCount ?? this.participantsCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isFeatured: isFeatured ?? this.isFeatured,
      participantIds: participantIds ?? this.participantIds,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        organizerId,
        organizerName,
        date,
        location,
        governorateId,
        participantsCount,
        maxParticipants,
        isFeatured,
        participantIds,
        tags,
        status,
        createdAt,
      ];
}
