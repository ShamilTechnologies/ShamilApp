import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReservationStatus {
  pending, // Optional: If confirmation is needed
  confirmed,
  cancelledByUser,
  cancelledByProvider,
  completed,
  noShow,
}

// Helper to convert string to enum and vice-versa
ReservationStatus reservationStatusFromString(String? status) {
  switch (status?.toLowerCase()) {
    case 'confirmed':
      return ReservationStatus.confirmed;
    case 'cancelled_by_user':
      return ReservationStatus.cancelledByUser;
    case 'cancelled_by_provider':
      return ReservationStatus.cancelledByProvider;
    case 'completed':
      return ReservationStatus.completed;
    case 'no_show':
      return ReservationStatus.noShow;
    case 'pending':
    default:
      return ReservationStatus.pending; // Default or initial status
  }
}

extension ReservationStatusExtension on ReservationStatus {
  String get statusString {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'confirmed';
      case ReservationStatus.cancelledByUser:
        return 'cancelled_by_user';
      case ReservationStatus.cancelledByProvider:
        return 'cancelled_by_provider';
      case ReservationStatus.completed:
        return 'completed';
      case ReservationStatus.noShow:
        return 'no_show';
      case ReservationStatus.pending:
      default:
        return 'pending';
    }
  }
}


class ReservationModel extends Equatable {
  final String id; // Firestore document ID
  final String userId; // ID of the user who booked
  final String providerId; // ID of the service provider
  final String providerName; // Denormalized provider name
  final String serviceId; // ID of the specific BookableService
  final String serviceName; // Denormalized service name
  final int serviceDurationMinutes; // Denormalized duration
  final double servicePrice; // Denormalized price (at time of booking)
  final Timestamp reservationStartTime; // Specific date and time (UTC)
  final Timestamp reservationEndTime; // Calculated end time (UTC)
  final ReservationStatus status; // Status of the booking
  final Timestamp createdAt; // When the booking was made
  final Timestamp? lastUpdatedAt; // Optional: When status last changed

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDurationMinutes,
    required this.servicePrice,
    required this.reservationStartTime,
    required this.reservationEndTime,
    required this.status,
    required this.createdAt,
    this.lastUpdatedAt,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReservationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? 'Unknown Provider',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? 'Unknown Service',
      serviceDurationMinutes: (data['serviceDurationMinutes'] as num?)?.toInt() ?? 0,
      servicePrice: (data['servicePrice'] as num?)?.toDouble() ?? 0.0,
      reservationStartTime: data['reservationStartTime'] as Timestamp? ?? Timestamp.now(),
      reservationEndTime: data['reservationEndTime'] as Timestamp? ?? Timestamp.now(),
      status: reservationStatusFromString(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastUpdatedAt: data['lastUpdatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'providerId': providerId,
      'providerName': providerName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceDurationMinutes': serviceDurationMinutes,
      'servicePrice': servicePrice,
      'reservationStartTime': reservationStartTime,
      'reservationEndTime': reservationEndTime,
      'status': status.statusString, // Store enum as string
      'createdAt': createdAt, // Should ideally use FieldValue.serverTimestamp() on write
      'lastUpdatedAt': lastUpdatedAt, // Should use FieldValue.serverTimestamp() on update
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        providerId,
        providerName,
        serviceId,
        serviceName,
        serviceDurationMinutes,
        servicePrice,
        reservationStartTime,
        reservationEndTime,
        status,
        createdAt,
        lastUpdatedAt,
      ];
}