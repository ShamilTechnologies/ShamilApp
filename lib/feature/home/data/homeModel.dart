import 'package:cloud_firestore/cloud_firestore.dart';

class HomeModel {
  final String uid;
  final String city;
  final Timestamp lastUpdatedLocation;

  HomeModel({
    required this.uid,
    required this.city,
    required this.lastUpdatedLocation,
  });

  // Factory method to create a HomeModel from a Firestore document.
  factory HomeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeModel(
      uid: data['uid'] ?? '',
      city: data['city'] ?? 'Unknown',
      lastUpdatedLocation: data['lastUpdatedLocation'] ?? Timestamp.now(),
    );
  }

  // Converts the HomeModel into a Map for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'city': city,
      'lastUpdatedLocation': lastUpdatedLocation,
    };
  }
}
