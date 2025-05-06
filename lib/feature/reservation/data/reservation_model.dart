// lib/feature/reservation/data/reservation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// --- Enums (ReservationType, ReservationStatus) ---
enum ReservationType {
  timeBased,
  serviceBased,
  seatBased,
  recurring, // Represents a reservation that is part of a recurring series
  group, // Indicates a reservation involving multiple attendees (often combined with another type)
  accessBased, // Based on purchasing access for a duration (e.g., day pass)
  unknown
}

// --- ADDED: Extension directly within the same file ---
extension ReservationTypeExtension on ReservationType {
  /// Returns the string representation used in Firestore.
  String get typeString {
    switch (this) {
      case ReservationType.timeBased:
        return 'time-based';
      case ReservationType.serviceBased:
        return 'service-based';
      case ReservationType.seatBased:
        return 'seat-based';
      case ReservationType.recurring:
        return 'recurring'; // Store 'recurring' if it's the primary aspect
      case ReservationType.group:
        return 'group'; // Store 'group' if it's the primary aspect
      case ReservationType.accessBased:
        return 'access-based';
      default:
        return 'unknown';
    }
  }

  /// Returns a user-friendly display string.
  String get displayString {
    String capitalize(String s) =>
        s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
    // Use the typeString getter defined above
    return typeString.replaceAll('-', ' ').split(' ').map(capitalize).join(' ');
  }
}

/// Parses a string into a ReservationType enum.
ReservationType reservationTypeFromString(String? typeString) {
  switch (typeString?.toLowerCase()) {
    case 'time-based':
      return ReservationType.timeBased;
    case 'service-based':
      return ReservationType.serviceBased;
    case 'seat-based':
      return ReservationType.seatBased;
    case 'recurring':
      return ReservationType.recurring;
    case 'group':
      return ReservationType.group;
    case 'access-based':
      return ReservationType.accessBased;
    default:
      return ReservationType.unknown;
  }
}

// --- ReservationStatus Enum and Helpers ---
// Aligned with the Implementation Guide
enum ReservationStatus {
  pending, // Default state, may require confirmation or payment
  confirmed,
  cancelledByUser,
  cancelledByProvider,
  completed,
  noShow,
  unknown
}

ReservationStatus reservationStatusFromString(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return ReservationStatus.pending; // Matches guide
    case 'confirmed':
      return ReservationStatus.confirmed;
    case 'cancelled': // Handle potential legacy 'cancelled' if needed, map to user cancelled?
    case 'cancelled_by_user':
      return ReservationStatus.cancelledByUser;
    case 'cancelled_by_provider':
      return ReservationStatus.cancelledByProvider;
    case 'completed':
      return ReservationStatus.completed;
    case 'no_show': // Matches guide
    case 'noshow':
      return ReservationStatus.noShow; // Handle variation
    default:
      return ReservationStatus.unknown;
  }
}

extension ReservationStatusExtension on ReservationStatus {
  String get statusString {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending'; // Use guide's values
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelledByUser:
        return 'Cancelled'; // Simplified for now, backend might use specific
      case ReservationStatus.cancelledByProvider:
        return 'Cancelled'; // Simplified for now
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.noShow:
        return 'NoShow'; // Matches guide
      default:
        return 'Unknown';
    }
  }
}
// --- End Enums ---

/// Represents an attendee associated with a reservation.
class AttendeeModel extends Equatable {
  final String userId; // User ID of the attendee
  final String name; // Denormalized name for display
  final String type; // 'self', 'family', 'friend'
  final String
      status; // 'going', 'invited', 'declined' (relevant for group/friend invites)

  const AttendeeModel({
    required this.userId,
    required this.name,
    required this.type,
    required this.status,
  });

  factory AttendeeModel.fromMap(Map<String, dynamic> map) {
    return AttendeeModel(
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Attendee',
      type: map['type'] as String? ?? 'unknown',
      status: map['status'] as String? ?? 'unknown', // e.g., 'going', 'invited'
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [userId, name, type, status];
}

/// Represents a reservation document stored in Firestore.
/// Updated to match the Implementation Guide V2.
class ReservationModel extends Equatable {
  final String id; // Document ID (reservationId)
  final String userId; // User who booked
  final String userName; // User's name for display
  final String providerId;
  // Removed providerName - fetch separately if needed
  final String governorateId; // Partition key
  final ReservationType type; // Parsed enum type
  final int groupSize; // Number of attendees
  final String? serviceId; // Optional ID of BookableService
  final String? serviceName; // Optional denormalized service name
  final int?
      durationMinutes; // Duration of the booking (may come from service or be specific)
  final Timestamp?
      reservationStartTime; // Primary start time/date (was 'dateTime')
  final Timestamp? endTime; // Calculated or stored end time
  final ReservationStatus status; // Parsed enum status
  final String? paymentStatus; // e.g., "Pending", "Paid", "Failed", "Refunded"
  final Map<String, dynamic>? paymentDetails; // Optional info about transaction
  final String? notes; // User notes for the booking
  final Map<String, dynamic>? typeSpecificData; // e.g., {"seatNumber": "A5"}
  final int? queuePosition; // For sequenceBased
  final Timestamp? estimatedEntryTime; // For sequenceBased
  final Timestamp createdAt; // When the document was created
  final Timestamp? updatedAt; // When the document was last modified
  final List<AttendeeModel> attendees; // List of attendees

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.providerId,
    required this.governorateId,
    required this.type,
    this.groupSize = 1,
    this.serviceId,
    this.serviceName,
    this.durationMinutes,
    this.reservationStartTime,
    this.endTime,
    required this.status,
    this.paymentStatus,
    this.paymentDetails,
    this.notes,
    this.typeSpecificData,
    this.queuePosition,
    this.estimatedEntryTime,
    required this.createdAt,
    this.updatedAt,
    this.attendees = const [],
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final List<AttendeeModel> parsedAttendees = (data['attendees'] as List?)
            ?.map((attendeeData) {
              if (attendeeData is Map<String, dynamic>) {
                try {
                  return AttendeeModel.fromMap(attendeeData);
                } catch (e) {
                  print("Error parsing attendee: $e");
                  return null;
                }
              }
              return null;
            })
            .whereType<AttendeeModel>()
            .toList() ??
        [];

    return ReservationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      governorateId: data['governorateId'] as String? ?? '',
      type: reservationTypeFromString(data['type'] as String?),
      groupSize: (data['groupSize'] as num?)?.toInt() ??
          parsedAttendees.length, // Default to attendee count
      serviceId: data['serviceId'] as String?,
      serviceName: data['serviceName'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      reservationStartTime:
          data['dateTime'] as Timestamp?, // Read from 'dateTime' field
      endTime: data['endTime'] as Timestamp?,
      status: reservationStatusFromString(data['status'] as String?),
      paymentStatus: data['paymentStatus'] as String?,
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      typeSpecificData: data['typeSpecificData'] as Map<String, dynamic>?,
      queuePosition: (data['queuePosition'] as num?)?.toInt(),
      estimatedEntryTime: data['estimatedEntryTime'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      attendees: parsedAttendees,
    );
  }

  /// Converts the model to a map suitable for Firestore writes.
  /// Uses FieldValue.serverTimestamp() for createdAt/updatedAt.
  Map<String, dynamic> toMapForCreate() {
    // Separate method for creation
    return {
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'governorateId': governorateId,
      'type': type.typeString, // Use extension getter
      'groupSize': groupSize,
      if (serviceId != null) 'serviceId': serviceId,
      if (serviceName != null) 'serviceName': serviceName,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (reservationStartTime != null)
        'dateTime': reservationStartTime, // Write to 'dateTime'
      if (endTime != null) 'endTime': endTime,
      'status': status.statusString, // Use extension getter
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (notes != null) 'notes': notes,
      if (typeSpecificData != null) 'typeSpecificData': typeSpecificData,
      if (queuePosition != null) 'queuePosition': queuePosition,
      if (estimatedEntryTime != null) 'estimatedEntryTime': estimatedEntryTime,
      'createdAt':
          FieldValue.serverTimestamp(), // Use server timestamp on create
      'updatedAt':
          FieldValue.serverTimestamp(), // Use server timestamp on create
      'attendees': attendees.map((attendee) => attendee.toMap()).toList(),
    };
  }

  /// Converts the model to a map suitable for Firestore updates.
  /// Only includes fields that might change and sets updatedAt.
  Map<String, dynamic> toMapForUpdate({
    ReservationStatus? newStatus,
    String? newPaymentStatus,
    // Add other updatable fields as needed
  }) {
    final map = <String, dynamic>{};
    if (newStatus != null) map['status'] = newStatus.statusString;
    if (newPaymentStatus != null) map['paymentStatus'] = newPaymentStatus;
    // Add other fields here if they are updatable
    map['updatedAt'] = FieldValue.serverTimestamp(); // Always update timestamp
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        providerId,
        governorateId,
        type,
        groupSize,
        serviceId,
        serviceName,
        durationMinutes,
        reservationStartTime,
        endTime,
        status,
        paymentStatus,
        paymentDetails,
        notes,
        typeSpecificData,
        queuePosition,
        estimatedEntryTime,
        createdAt,
        updatedAt,
        attendees,
      ];
}
