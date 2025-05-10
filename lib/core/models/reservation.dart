import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String providerId;
  final String userId;
  final DateTime dateTime;
  final String status;
  final String? notes;
  final double totalPrice;
  final List<String> selectedAddOns;
  final int quantity;

  Reservation({
    required this.id,
    required this.providerId,
    required this.userId,
    required this.dateTime,
    required this.status,
    this.notes,
    required this.totalPrice,
    required this.selectedAddOns,
    required this.quantity,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String,
      providerId: map['providerId'] as String,
      userId: map['userId'] as String,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      selectedAddOns: List<String>.from(map['selectedAddOns'] as List),
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'userId': userId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'notes': notes,
      'totalPrice': totalPrice,
      'selectedAddOns': selectedAddOns,
      'quantity': quantity,
    };
  }
}
