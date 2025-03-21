import 'package:cloud_firestore/cloud_firestore.dart';

class AuthModel {
  final String uid;
  final String name;
  final String email;
  final String nationalId;
  final String phone;
  final String gender;
  final String dob; // Date of Birth field (formatted as yyyy-MM-dd)
  final String image;
  final bool uploadedId;
  final bool isVerified;
  final bool isBlocked;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp lastSeen;

  AuthModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.nationalId,
    required this.phone,
    required this.gender,
    required this.dob,
    this.image = '',
    this.uploadedId = false,
    this.isVerified = false,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
  });

  // Factory method to create an AuthModel from Firestore document.
  factory AuthModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuthModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nationalId: data['nationalId'] ?? '',
      phone: data['phone'] ?? '',
      gender: data['gender'] ?? '',
      dob: data['dob'] ?? '',
      image: data['image'] ?? '',
      uploadedId: data['uploadedId'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
    );
  }

  // Converts the AuthModel into a Map for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'nationalId': nationalId,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'image': image,
      'uploadedId': uploadedId,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastSeen': lastSeen,
    };
  }
}
