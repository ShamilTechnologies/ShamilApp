import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GroupHostModel extends Equatable {
  final String id;
  final String hostId;
  final String hostName;
  final String hostImageUrl;
  final String title;
  final String description;
  final String serviceId;
  final String serviceName;
  final String providerId;
  final String providerName;
  final String governorateId;
  final String governorateName;
  final DateTime dateTime;
  final int maxParticipants;
  final int currentParticipants;
  final double pricePerPerson;
  final String currency;
  final String status; // 'open', 'full', 'completed', 'cancelled'
  final List<ParticipantModel> participants;
  final DateTime createdAt;

  const GroupHostModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostImageUrl,
    required this.title,
    required this.description,
    required this.serviceId,
    required this.serviceName,
    required this.providerId,
    required this.providerName,
    required this.governorateId,
    required this.governorateName,
    required this.dateTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.pricePerPerson,
    this.currency = 'EGP',
    required this.status,
    required this.participants,
    required this.createdAt,
  });

  factory GroupHostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupHostModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostImageUrl: data['hostImageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      governorateId: data['governorateId'] ?? '',
      governorateName: data['governorateName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      pricePerPerson: (data['pricePerPerson'] as num).toDouble(),
      currency: data['currency'] ?? 'EGP',
      status: data['status'] ?? 'open',
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'hostImageUrl': hostImageUrl,
      'title': title,
      'description': description,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'providerId': providerId,
      'providerName': providerName,
      'governorateId': governorateId,
      'governorateName': governorateName,
      'dateTime': Timestamp.fromDate(dateTime),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'pricePerPerson': pricePerPerson,
      'currency': currency,
      'status': status,
      'participants': participants.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupHostModel copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostImageUrl,
    String? title,
    String? description,
    String? serviceId,
    String? serviceName,
    String? providerId,
    String? providerName,
    String? governorateId,
    String? governorateName,
    DateTime? dateTime,
    int? maxParticipants,
    int? currentParticipants,
    double? pricePerPerson,
    String? currency,
    String? status,
    List<ParticipantModel>? participants,
    DateTime? createdAt,
  }) {
    return GroupHostModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostImageUrl: hostImageUrl ?? this.hostImageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      dateTime: dateTime ?? this.dateTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostName,
        hostImageUrl,
        title,
        description,
        serviceId,
        serviceName,
        providerId,
        providerName,
        governorateId,
        governorateName,
        dateTime,
        maxParticipants,
        currentParticipants,
        pricePerPerson,
        currency,
        status,
        participants,
        createdAt,
      ];
}

class ParticipantModel extends Equatable {
  final String userId;
  final String name;
  final String imageUrl;
  final DateTime joinedAt;
  final String status; // 'confirmed', 'pending', 'declined'
  final bool isPaid;

  const ParticipantModel({
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.joinedAt,
    required this.status,
    this.isPaid = false,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
      'isPaid': isPaid,
    };
  }

  ParticipantModel copyWith({
    String? userId,
    String? name,
    String? imageUrl,
    DateTime? joinedAt,
    String? status,
    bool? isPaid,
  }) {
    return ParticipantModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  List<Object?> get props => [userId, name, imageUrl, joinedAt, status, isPaid];
}
