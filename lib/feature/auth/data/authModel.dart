import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for emailVerified check

class AuthModel extends Equatable {
  final String uid;
  final String name;
  // *** ADDED: username field ***
  final String username;
  final String email;
  final String nationalId;
  final String phone;
  final String gender;
  final String dob;
  final String image; // Original image field (keep for potential fallback)
  final String? profilePicUrl; // Specific field for Cloudinary profile picture URL
  final bool uploadedId;
  final bool isVerified; // Firebase email verification status
  final bool isBlocked; // App-specific blocking flag
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp lastSeen;
  // final bool isApproved; // Assuming this field exists based on previous context

  const AuthModel({
    required this.uid,
    required this.name,
    // *** ADDED: username required ***
    required this.username,
    required this.email,
    required this.nationalId,
    required this.phone,
    required this.gender,
    required this.dob,
    this.image = '', // Default empty string
    this.profilePicUrl, // Default null
    this.uploadedId = false,
    this.isVerified = false,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
    // this.isApproved = false,
  });

  // Factory method to create an AuthModel from Firestore document.
  factory AuthModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data
    final currentUser = FirebaseAuth.instance.currentUser;
    // Get current verification status directly from Firebase Auth if possible
    final bool firebaseVerified = (currentUser != null && currentUser.uid == doc.id)
                                   ? currentUser.emailVerified
                                   : data['isVerified'] as bool? ?? false; // Fallback to stored value

    return AuthModel(
      uid: data['uid'] as String? ?? doc.id, // Use doc.id as fallback
      name: data['name'] as String? ?? '',
      // *** ADDED: Read username, provide default if missing ***
      username: data['username'] as String? ?? '', // Default to empty if missing
      email: data['email'] as String? ?? '',
      nationalId: data['nationalId'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      dob: data['dob'] as String? ?? '',
      image: data['image'] as String? ?? '', // Read original image field
      profilePicUrl: data['profilePicUrl'] as String?, // Read profilePicUrl field
      uploadedId: data['uploadedId'] as bool? ?? false,
      isVerified: firebaseVerified, // Use potentially refreshed status
      isBlocked: data['isBlocked'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      lastSeen: data['lastSeen'] as Timestamp? ?? Timestamp.now(),
      // isApproved: data['isApproved'] as bool? ?? false,
    );
  }

  // Converts the AuthModel into a Map for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username, // *** ADDED: username ***
      'email': email,
      'nationalId': nationalId,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'image': image,
      'profilePicUrl': profilePicUrl,
      'uploadedId': uploadedId,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      // Timestamps handled by server on write/update
      // 'createdAt': createdAt,
      // 'updatedAt': updatedAt,
      // 'lastSeen': lastSeen,
      // 'isApproved': isApproved,
    };
  }

   // Add copyWith for easier updates
   AuthModel copyWith({
    String? uid, String? name, String? username, String? email, String? nationalId,
    String? phone, String? gender, String? dob, String? image, String? profilePicUrl,
    bool? uploadedId, bool? isVerified, bool? isBlocked, Timestamp? createdAt,
    Timestamp? updatedAt, Timestamp? lastSeen, bool? isApproved,
  }) {
    return AuthModel(
      uid: uid ?? this.uid, name: name ?? this.name,
      username: username ?? this.username, // *** ADDED: username ***
      email: email ?? this.email, nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone, gender: gender ?? this.gender, dob: dob ?? this.dob,
      image: image ?? this.image, profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      uploadedId: uploadedId ?? this.uploadedId, isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, lastSeen: lastSeen ?? this.lastSeen,
      // isApproved: isApproved ?? this.isApproved,
    );
  }


  // Implement props for Equatable
  @override
  List<Object?> get props => [
        uid, name, username, email, nationalId, phone, gender, dob, image, profilePicUrl, // *** ADDED: username ***
        uploadedId, isVerified, isBlocked, createdAt, updatedAt, lastSeen, //isApproved
      ];
}
