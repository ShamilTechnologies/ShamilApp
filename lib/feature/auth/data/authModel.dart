// lib/feature/auth/data/authModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Aliased

class AuthModel extends Equatable {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String? nationalId;
  final String? phone;
  final String? gender;
  final String? dob;
  final String? image; // Legacy or general image
  final String? profilePicUrl; // Preferred for Cloudinary/CDN
  final bool uploadedId;
  final bool isVerified;
  final bool isBlocked;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastSeen;

  const AuthModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    this.nationalId,
    this.phone,
    this.gender,
    this.dob,
    this.image,
    this.profilePicUrl,
    this.uploadedId = false,
    this.isVerified = false,
    this.isBlocked = false,
    required this.createdAt,
    this.updatedAt,
    this.lastSeen,
  });

  // Getter for backward compatibility
  String? get phoneNumber => phone;

  factory AuthModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    // Prioritize Firebase's real-time email verification status if available for the current user
    final bool firebaseVerified =
        (currentUser != null && currentUser.uid == doc.id)
            ? currentUser.emailVerified
            : data['isVerified'] as bool? ?? false;

    return AuthModel(
      uid: data['uid'] as String? ??
          doc.id, // Use doc.id if 'uid' field is missing
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ??
          (data['email'] as String? ?? '')
              .split('@')
              .first, // Fallback username
      email: data['email'] as String? ?? '',
      nationalId: data['nationalId'] as String?,
      phone: data['phone'] as String?,
      gender: data['gender'] as String?,
      dob: data['dob'] as String?,
      image: data['image'] as String?,
      profilePicUrl: data['profilePicUrl'] as String?,
      uploadedId: data['uploadedId'] as bool? ?? false,
      isVerified: firebaseVerified,
      isBlocked: data['isBlocked'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ??
          Timestamp.now(), // Fallback for createdAt
      updatedAt: data['updatedAt'] as Timestamp?,
      lastSeen: data['lastSeen'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      if (nationalId != null) 'nationalId': nationalId,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob,
      if (image != null) 'image': image,
      if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
      'uploadedId': uploadedId,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'createdAt':
          createdAt, // Should ideally be FieldValue.serverTimestamp() on create
      'updatedAt':
          updatedAt, // Should be FieldValue.serverTimestamp() on update
      'lastSeen':
          lastSeen, // Should be FieldValue.serverTimestamp() on activity
    };
  }

  AuthModel copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? nationalId,
    String? phone,
    String? gender,
    String? dob,
    String? image,
    String? profilePicUrl,
    bool? uploadedId,
    bool? isVerified,
    bool? isBlocked,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? lastSeen,
  }) {
    return AuthModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      image: image ?? this.image,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      uploadedId: uploadedId ?? this.uploadedId,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        username,
        email,
        nationalId,
        phone,
        gender,
        dob,
        image,
        profilePicUrl,
        uploadedId,
        isVerified,
        isBlocked,
        createdAt,
        updatedAt,
        lastSeen,
      ];
}
