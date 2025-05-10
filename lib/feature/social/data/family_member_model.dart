// lib/feature/social/data/family_member_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';

class FamilyMember extends Equatable {
  final String
      id; // Firestore document ID within the user's familyMembers subcollection
  final String name;
  final String relationship;
  final String? phone;
  final String? email;
  final String? gender;
  final String? nationalId;
  final String?
      userId; // UID of the linked app user, if status is 'accepted' or 'pending_sent'
  final String? profilePicUrl;
  final Timestamp?
      addedAt; // Timestamp of when the entry was created or request was made/accepted
  final String
      status; // 'external', 'pending_sent', 'pending_received', 'accepted'
  final String? dob;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.email,
    this.gender,
    this.nationalId,
    this.userId,
    this.profilePicUrl,
    this.addedAt,
    required this.status,
    this.dob,
  });

  factory FamilyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FamilyMember(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Name',
      relationship: data['relationship'] as String? ?? 'Relative',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      gender: data['gender'] as String?,
      nationalId: data['nationalId'] as String?,
      userId: data['userId'] as String?,
      profilePicUrl: data['profilePicUrl'] as String?,
      addedAt: data['addedAt'] as Timestamp?,
      status: data['status'] as String? ?? 'external',
      dob: data['dob'] as String?,
    );
  }

  // Factory to create a FamilyMember model from an AuthModel (e.g., when linking an existing user)
  // The 'id' for this FamilyMember document in the subcollection could be the linked authUser's UID.
  factory FamilyMember.fromAuthModel(
    AuthModel authUser, {
    required String relationship,
    required String status, // e.g., 'pending_sent' or 'accepted'
    Timestamp? customAddedAt,
  }) {
    return FamilyMember(
      id: authUser
          .uid, // Use the authUser's UID as the document ID in the subcollection
      name: authUser.name,
      relationship: relationship,
      phone: authUser.phone,
      email: authUser.email,
      gender: authUser.gender,
      nationalId: authUser.nationalId,
      userId: authUser.uid, // Explicitly the linked user's UID
      profilePicUrl: authUser.profilePicUrl ?? authUser.image,
      addedAt: customAddedAt ?? Timestamp.now(),
      status: status,
      dob: authUser.dob,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' is the document ID, not part of the map data itself
      'name': name,
      'relationship': relationship,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (gender != null) 'gender': gender,
      if (nationalId != null) 'nationalId': nationalId,
      if (userId != null) 'userId': userId,
      if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
      'addedAt': addedAt ??
          FieldValue.serverTimestamp(), // Use server timestamp if not provided
      'status': status,
      if (dob != null) 'dob': dob,
    };
  }

  // Used when creating a request entry in *another user's* familyMembers subcollection
  Map<String, dynamic> toRequestMap({
    required String
        requesterId, // The ID of the current user (the one sending the request)
    required String requesterName,
    String? requesterProfilePicUrl,
    required String
        relationshipToTargetUser, // The relationship current user has with the target
  }) {
    return {
      'name': requesterName, // Name of the user sending the request
      'relationship':
          relationshipToTargetUser, // e.g., "Son", "Mother" (target user's relation to requester)
      'userId': requesterId, // UID of the user sending the request
      'profilePicUrl': requesterProfilePicUrl,
      'addedAt': FieldValue.serverTimestamp(),
      'status':
          'pending_received', // The target user receives this as a 'pending_received'
      // DOB is not typically part of the request map, but could be if needed
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        relationship,
        phone,
        email,
        gender,
        nationalId,
        userId,
        profilePicUrl,
        addedAt,
        status,
        dob
      ];
}
