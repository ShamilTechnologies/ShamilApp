// lib/feature/reservation/data/reservation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// --- Enums (ReservationType, ReservationStatus) ---
enum ReservationType {
  timeBased,
  serviceBased,
  seatBased,
  recurring,
  group,
  accessBased,
  sequenceBased,
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
        return 'recurring';
      case ReservationType.group:
        return 'group';
      case ReservationType.accessBased:
        return 'access-based';
      case ReservationType.sequenceBased:
        return 'sequence-based';
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
  // Normalize the input string slightly for matching
  final normalizedType = typeString?.toLowerCase().replaceAll('-', '');
  switch (normalizedType) {
    case 'timebased':
      return ReservationType.timeBased;
    case 'servicebased':
      return ReservationType.serviceBased;
    case 'seatbased':
      return ReservationType.seatBased;
    case 'recurring':
      return ReservationType.recurring;
    case 'group':
      return ReservationType.group;
    case 'accessbased':
      return ReservationType.accessBased;
    case 'sequencebased':
      return ReservationType.sequenceBased;
    default:
      print(
        "Warning: Unknown reservation type string '$typeString', defaulting to unknown.",
      );
      return ReservationType.unknown; // Default to unknown for safety
  }
}

// --- ReservationStatus Enum and Helpers (No changes needed here) ---
enum ReservationStatus {
  pending,
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
      return ReservationStatus.pending;
    case 'confirmed':
      return ReservationStatus.confirmed;
    case 'cancelled': // Handle potential legacy 'cancelled'
    case 'cancelled_by_user':
      return ReservationStatus.cancelledByUser;
    case 'cancelled_by_provider':
      return ReservationStatus.cancelledByProvider;
    case 'completed':
      return ReservationStatus.completed;
    case 'no_show':
    case 'noshow':
      return ReservationStatus.noShow;
    default:
      return ReservationStatus.unknown;
  }
}

extension ReservationStatusExtension on ReservationStatus {
  String get statusString {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending'; // Use lowercase for consistency?
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
      default:
        return 'unknown';
    }
  }

  // Optional: User-friendly display string
  String get displayString {
    String capitalize(String s) =>
        s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
    return statusString
        .replaceAll('_', ' ')
        .split(' ')
        .map(capitalize)
        .join(' ');
  }
}
// --- End Enums ---

/// Represents an attendee associated with a reservation. (No changes needed)
class AttendeeModel extends Equatable {
  final String userId;
  final String name;
  final String type; // 'self', 'family', 'friend'
  final String status; // 'going', 'invited', 'declined'

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
      status: map['status'] as String? ?? 'unknown',
    );
  }
  Map<String, dynamic> toMap() {
    return {'userId': userId, 'name': name, 'type': type, 'status': status};
  }

  @override
  List<Object?> get props => [userId, name, type, status];
}

/// Represents a reservation document stored in Firestore. (No changes needed)
class ReservationModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String providerId;
  final String governorateId;
  final ReservationType type;
  final int groupSize;
  final String? serviceId;
  final String? serviceName;
  final int? durationMinutes;
  final Timestamp? reservationStartTime;
  final Timestamp? endTime;
  final ReservationStatus status;
  final String? paymentStatus;
  final Map<String, dynamic>? paymentDetails;
  final String? notes;
  final Map<String, dynamic>? typeSpecificData;
  final int? queuePosition;
  final Timestamp? estimatedEntryTime;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<AttendeeModel> attendees;
  final String? reservationCode;
  final double? totalPrice;
  final List<String>? selectedAddOnsList;

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
    this.reservationCode,
    this.totalPrice,
    this.selectedAddOnsList,
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
      type: reservationTypeFromString(data['reservationType'] ??
          data['type'] as String?), // Check both 'type' and 'reservationType'
      groupSize: (data['groupSize'] as num?)?.toInt() ?? parsedAttendees.length,
      serviceId: data['serviceId'] as String?,
      serviceName: data['serviceName'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      reservationStartTime: data['reservationStartTime'] as Timestamp? ??
          data['dateTime'] as Timestamp?, // Check both keys
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
      reservationCode: data['reservationCode'] as String?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      selectedAddOnsList: data['selectedAddOnsList'] != null
          ? List<String>.from(data['selectedAddOnsList'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'governorateId': governorateId,
      'type': type.typeString,
      'groupSize': groupSize,
      if (serviceId != null) 'serviceId': serviceId,
      if (serviceName != null) 'serviceName': serviceName,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (reservationStartTime != null)
        'reservationStartTime': reservationStartTime,
      if (endTime != null) 'endTime': endTime,
      'status': status.statusString,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (notes != null) 'notes': notes,
      if (typeSpecificData != null) 'typeSpecificData': typeSpecificData,
      if (queuePosition != null) 'queuePosition': queuePosition,
      if (estimatedEntryTime != null) 'estimatedEntryTime': estimatedEntryTime,
      'attendees': attendees.map((attendee) => attendee.toMap()).toList(),
      if (reservationCode != null) 'reservationCode': reservationCode,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (selectedAddOnsList != null) 'selectedAddOnsList': selectedAddOnsList,
      // Server timestamps will be added in the repository
    };
  }

  Map<String, dynamic> toMapForUpdate({
    ReservationStatus? newStatus,
    String? newPaymentStatus,
    /* ... */
  }) {
    final map = <String, dynamic>{};
    if (newStatus != null) map['status'] = newStatus.statusString;
    if (newPaymentStatus != null) map['paymentStatus'] = newPaymentStatus;
    map['updatedAt'] = FieldValue.serverTimestamp();
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
        reservationCode,
        totalPrice,
        selectedAddOnsList
      ];
}
