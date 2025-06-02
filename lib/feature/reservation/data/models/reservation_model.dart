// lib/feature/reservation/data/models/reservation_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// --- Enums (ReservationType, PaymentStatus, ReservationStatus) ---
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

enum PaymentStatus { pending, partial, complete, hosted, waived }

enum ReservationStatus {
  pending,
  confirmed,
  cancelledByUser,
  cancelledByProvider,
  completed,
  noShow,
  unknown
}

// --- Queue Status Class ---
/// Represents the status of a queue-based reservation
class QueueStatus extends Equatable {
  final String id;
  final int position;
  final String
      status; // 'waiting', 'processing', 'completed', 'cancelled', 'no_show'
  final DateTime estimatedEntryTime;
  final int peopleAhead;

  const QueueStatus({
    required this.id,
    required this.position,
    required this.status,
    required this.estimatedEntryTime,
    this.peopleAhead = 0,
  });

  factory QueueStatus.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert timestamps
    DateTime safeDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return QueueStatus(
      id: map['id'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      status: map['status'] as String? ?? 'waiting',
      estimatedEntryTime: safeDateTime(map['estimatedEntryTime']),
      peopleAhead: map['peopleAhead'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position,
      'status': status,
      'estimatedEntryTime': estimatedEntryTime,
      'peopleAhead': peopleAhead,
    };
  }

  QueueStatus copyWith({
    String? id,
    int? position,
    String? status,
    DateTime? estimatedEntryTime,
    int? peopleAhead,
  }) {
    return QueueStatus(
      id: id ?? this.id,
      position: position ?? this.position,
      status: status ?? this.status,
      estimatedEntryTime: estimatedEntryTime ?? this.estimatedEntryTime,
      peopleAhead: peopleAhead ?? this.peopleAhead,
    );
  }

  @override
  List<Object?> get props =>
      [id, position, status, estimatedEntryTime, peopleAhead];
}

// --- Extensions ---

// Extension for ReservationType
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
      debugPrint(
          "Warning: Unknown reservation type string '$typeString', defaulting to unknown.");
      return ReservationType.unknown;
  }
}

// Extension for PaymentStatus
extension PaymentStatusExtension on PaymentStatus {
  /// Parses a string into a PaymentStatus enum. Defaults to pending.
  static PaymentStatus fromString(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'complete':
        return PaymentStatus.complete;
      case 'hosted':
        return PaymentStatus.hosted;
      case 'waived':
        return PaymentStatus.waived;
      default:
        // Don't print warning for null, only for unrecognized strings
        if (statusString != null) {
          debugPrint(
              "Warning: Unknown payment status string '$statusString', defaulting to pending.");
        }
        return PaymentStatus.pending;
    }
  }
  // name getter is implicitly provided by enum
}

// Extension for ReservationStatus
extension ReservationStatusExtension on ReservationStatus {
  String get statusString {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending';
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

  // User-friendly display string
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

/// Parses a string into a ReservationStatus enum.
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
      // Don't print warning for null, only for unrecognized strings
      if (status != null) {
        debugPrint(
            "Warning: Unknown reservation status string '$status', defaulting to unknown.");
      }
      return ReservationStatus.unknown;
  }
}

// --- End Enums and Extensions ---

/// Represents an attendee associated with a reservation.
class AttendeeModel extends Equatable {
  final String userId;
  final String name;
  final String type; // 'self', 'family', 'friend' // Added 'guest'?
  final String
      status; // 'going', 'invited', 'declined', 'confirmed' // Added confirmed?

  // New fields
  final PaymentStatus paymentStatus;
  final double? amountToPay; // Individual's portion of the payment
  final double? amountPaid; // Amount already paid by the attendee
  final bool isHost; // Whether this attendee is hosting the reservation

  const AttendeeModel({
    required this.userId,
    required this.name,
    required this.type,
    required this.status,
    this.paymentStatus = PaymentStatus.pending, // Default to pending
    this.amountToPay, // Allow null amount
    this.amountPaid, // Allow null amount
    this.isHost = false, // Default to not host
  });

  factory AttendeeModel.fromMap(Map<String, dynamic> map) {
    return AttendeeModel(
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Attendee',
      type:
          map['type'] as String? ?? 'unknown', // e.g. 'guest' if not specified
      status:
          map['status'] as String? ?? 'unknown', // e.g. 'invited' or 'unknown'
      // Parse new fields with defaults using the extension
      paymentStatus:
          PaymentStatusExtension.fromString(map['paymentStatus'] as String?),
      // Safely parse amounts
      amountToPay: (map['amountToPay'] as num?)?.toDouble(),
      amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      isHost: map['isHost'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'status': status,
      // Store enum name (string) in Firestore
      'paymentStatus': paymentStatus.name,
      // Only include amounts if they're not null
      if (amountToPay != null) 'amountToPay': amountToPay,
      if (amountPaid != null) 'amountPaid': amountPaid,
      'isHost': isHost,
    };
  }

  // Add copyWith method for immutable updates
  AttendeeModel copyWith({
    String? userId,
    String? name,
    String? type,
    String? status,
    PaymentStatus? paymentStatus,
    double? amountToPay,
    double? amountPaid,
    bool? isHost,
    // Special flags to explicitly set amounts to null if needed
    bool clearAmountToPay = false,
    bool clearAmountPaid = false,
  }) {
    return AttendeeModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      // Use clear flags or existing logic for amounts
      amountToPay: clearAmountToPay ? null : (amountToPay ?? this.amountToPay),
      amountPaid: clearAmountPaid ? null : (amountPaid ?? this.amountPaid),
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        type,
        status,
        paymentStatus,
        amountToPay,
        amountPaid,
        isHost,
      ];
}

/// Represents a reservation document stored in Firestore.
/// Updated ReservationModel class as provided in the prompt.
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
  final String? paymentStatus; // Kept based on snippet, maybe overall status?
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

  // New fields from snippet
  final bool isFullVenueReservation;
  final int? reservedCapacity; // Capacity reserved if not full venue
  final bool isCommunityVisible;
  final String? hostingCategory;
  final String? hostingDescription;
  final Map<String, dynamic>? costSplitDetails;
  // Field for pending join requests (list of maps containing userId, userName, timestamp?)
  final List<Map<String, dynamic>>? joinRequests;

  // Add queue status field for real-time queue updates
  final QueueStatus? queueStatus;

  // Add queueBased field to identify queue-based reservations
  final bool queueBased;

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.providerId,
    required this.governorateId,
    required this.type,
    this.groupSize = 1, // Default or derived from attendees.length
    this.serviceId,
    this.serviceName,
    this.durationMinutes,
    this.reservationStartTime,
    this.endTime,
    required this.status,
    this.paymentStatus, // Kept based on snippet
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
    // Initialize new fields
    this.isFullVenueReservation = false,
    this.reservedCapacity, // Nullable
    this.isCommunityVisible = false,
    this.hostingCategory,
    this.hostingDescription,
    this.costSplitDetails,
    this.joinRequests, // Nullable list of requests
    this.queueStatus, // Queue status for real-time updates
    this.queueBased = false, // Whether this reservation is queue-based
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to safely convert timestamps from Firestore data
    Timestamp? safeTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
      if (value is num) {
        return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
      }
      return null;
    }

    // Parse attendees using the updated AttendeeModel.fromMap
    final List<AttendeeModel> parsedAttendees = (data['attendees'] as List?)
            ?.map((attendeeData) {
              if (attendeeData is Map<String, dynamic>) {
                try {
                  return AttendeeModel.fromMap(attendeeData);
                } catch (e) {
                  print("Error parsing attendee: $e data: $attendeeData");
                  return null;
                }
              }
              return null;
            })
            .whereType<AttendeeModel>()
            .toList() ??
        [];

    // Parse join requests safely
    final List<Map<String, dynamic>> parsedJoinRequests = [];
    if (data['joinRequests'] is List) {
      for (var request in data['joinRequests']) {
        // Ensure each request is a map before adding
        if (request is Map<String, dynamic>) {
          // You might want more specific parsing/validation here if the request structure is fixed
          parsedJoinRequests.add(Map<String, dynamic>.from(request));
        }
      }
    }

    // Determine group size primarily from parsed attendees, fallback to stored value
    final int effectiveGroupSize = parsedAttendees.isNotEmpty
        ? parsedAttendees.length
        : (data['groupSize'] as num?)?.toInt() ?? 1;

    return ReservationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      providerId: data['providerId'] as String? ?? '',
      governorateId: data['governorateId'] as String? ?? '',
      // Handle legacy 'type' field name if 'reservationType' is missing
      type: reservationTypeFromString(
          data['reservationType'] as String? ?? data['type'] as String?),
      groupSize: effectiveGroupSize,
      serviceId: data['serviceId'] as String?,
      serviceName: data['serviceName'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      // Handle legacy 'dateTime' field if 'reservationStartTime' is missing - use safe timestamp conversion
      reservationStartTime: safeTimestamp(data['reservationStartTime']) ??
          safeTimestamp(data['dateTime']),
      endTime: safeTimestamp(data['endTime']),
      status: reservationStatusFromString(data['status'] as String?),
      paymentStatus: data['paymentStatus'] as String?, // Kept based on snippet
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      typeSpecificData: data['typeSpecificData'] as Map<String, dynamic>?,
      queuePosition: (data['queuePosition'] as num?)?.toInt(),
      estimatedEntryTime: safeTimestamp(data['estimatedEntryTime']),
      createdAt: safeTimestamp(data['createdAt']) ??
          Timestamp.now(), // Fallback needed?
      updatedAt: safeTimestamp(data['updatedAt']),
      attendees: parsedAttendees,
      reservationCode: data['reservationCode'] as String?,
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      selectedAddOnsList: data['selectedAddOnsList'] != null
          ? List<String>.from(data['selectedAddOnsList'] as List<dynamic>)
          : null,
      // Parse new fields
      isFullVenueReservation: data['isFullVenueReservation'] as bool? ?? false,
      reservedCapacity: (data['reservedCapacity'] as num?)?.toInt(),
      isCommunityVisible: data['isCommunityVisible'] as bool? ?? false,
      hostingCategory: data['hostingCategory'] as String?,
      hostingDescription: data['hostingDescription'] as String?,
      costSplitDetails: data['costSplitDetails'] as Map<String, dynamic>?,
      // Assign parsed requests, use null if list is empty after parsing
      joinRequests: parsedJoinRequests.isEmpty ? null : parsedJoinRequests,
      queueStatus: data['queueStatus'] != null
          ? QueueStatus.fromMap(data['queueStatus'] as Map<String, dynamic>)
          : null,
      queueBased: data['queueBased'] as bool? ?? false,
    );
  }

  /// Generates a map suitable for creating a new reservation document.
  /// Excludes fields automatically set by Firestore (like id, timestamps).
  Map<String, dynamic> toMapForCreate() {
    // Ensure attendees are converted using the updated toMap method
    final attendeesMapList =
        attendees.map((attendee) => attendee.toMap()).toList();

    return {
      'userId': userId,
      'userName': userName,
      'providerId': providerId,
      'governorateId': governorateId,
      'type': type.typeString, // Use string representation
      // Use actual attendees list length for groupSize at creation
      'groupSize': attendeesMapList.length,
      if (serviceId != null) 'serviceId': serviceId,
      if (serviceName != null) 'serviceName': serviceName,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (reservationStartTime != null)
        'reservationStartTime': reservationStartTime!.millisecondsSinceEpoch,
      if (endTime != null) 'endTime': endTime!.millisecondsSinceEpoch,
      'status': status.statusString, // Use string representation
      if (paymentStatus != null)
        'paymentStatus': paymentStatus, // Kept based on snippet
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (notes != null) 'notes': notes,
      if (typeSpecificData != null) 'typeSpecificData': typeSpecificData,
      if (queuePosition != null) 'queuePosition': queuePosition,
      if (estimatedEntryTime != null)
        'estimatedEntryTime': estimatedEntryTime!.millisecondsSinceEpoch,
      'attendees': attendeesMapList,
      if (reservationCode != null) 'reservationCode': reservationCode,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (selectedAddOnsList != null) 'selectedAddOnsList': selectedAddOnsList,
      // Include new fields in creation map
      'isFullVenueReservation': isFullVenueReservation,
      if (reservedCapacity != null) 'reservedCapacity': reservedCapacity,
      'isCommunityVisible': isCommunityVisible,
      if (hostingCategory != null) 'hostingCategory': hostingCategory,
      if (hostingDescription != null) 'hostingDescription': hostingDescription,
      if (costSplitDetails != null) 'costSplitDetails': costSplitDetails,
      // Include joinRequests only if not null (usually starts null/empty)
      if (joinRequests != null) 'joinRequests': joinRequests,
      if (queueStatus != null)
        'queueStatus': {
          'id': queueStatus!.id,
          'position': queueStatus!.position,
          'status': queueStatus!.status,
          'estimatedEntryTime':
              queueStatus!.estimatedEntryTime.millisecondsSinceEpoch,
          'peopleAhead': queueStatus!.peopleAhead,
        },
      'queueBased': queueBased,
      // Let repository/backend handle server timestamps
      // 'createdAt': FieldValue.serverTimestamp(),
      // 'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Generates a map suitable for updating specific fields of a reservation.
  /// Includes `updatedAt` timestamp automatically.
  /// Updated based on snippet.
  Map<String, dynamic> toMapForUpdate({
    ReservationStatus? newStatus,
    String? newPaymentStatus, // Kept based on snippet
    Map<String, dynamic>? newCostSplitDetails,
    bool? newCommunityVisibility,
    String? newHostingCategory,
    String? newHostingDescription,
    List<AttendeeModel>? updatedAttendees, // Allow updating the whole list
    Map<String, dynamic>? newPaymentDetails,
    String? newNotes,
    Map<String, dynamic>? newTypeSpecificData,
    List<Map<String, dynamic>>? updatedJoinRequests, // Allow updating requests
    // Add other updatable fields as needed
  }) {
    final map = <String, dynamic>{};
    if (newStatus != null) map['status'] = newStatus.statusString;
    if (newPaymentStatus != null) map['paymentStatus'] = newPaymentStatus;
    if (newCostSplitDetails != null) {
      map['costSplitDetails'] = newCostSplitDetails;
    }
    if (newCommunityVisibility != null) {
      map['isCommunityVisible'] = newCommunityVisibility;
    }
    // Handle category/description updates carefully based on visibility
    if (newHostingCategory != null) {
      map['hostingCategory'] = newHostingCategory;
    } else if (newCommunityVisibility == false)
      map['hostingCategory'] = FieldValue.delete(); // Remove if not visible
    if (newHostingDescription != null) {
      map['hostingDescription'] = newHostingDescription;
    } else if (newCommunityVisibility == false)
      map['hostingDescription'] = FieldValue.delete(); // Remove if not visible

    if (updatedAttendees != null) {
      map['attendees'] = updatedAttendees.map((a) => a.toMap()).toList();
    }
    if (newPaymentDetails != null) map['paymentDetails'] = newPaymentDetails;
    if (newNotes != null) map['notes'] = newNotes;
    if (newTypeSpecificData != null) {
      map['typeSpecificData'] = newTypeSpecificData;
    }
    if (updatedJoinRequests != null) {
      map['joinRequests'] = updatedJoinRequests; // Update the requests list
    }

    // Always include updatedAt on updates
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
        paymentStatus, // Kept based on snippet
        paymentDetails,
        notes,
        typeSpecificData,
        queuePosition,
        estimatedEntryTime,
        createdAt,
        updatedAt,
        attendees, // The list itself is part of props
        reservationCode,
        totalPrice,
        selectedAddOnsList,
        // Include new fields in props
        isFullVenueReservation,
        reservedCapacity,
        isCommunityVisible,
        hostingCategory,
        hostingDescription,
        costSplitDetails,
        joinRequests, // Add new field to props
        queueStatus,
        queueBased,
      ];

  /// Returns a copy of this reservation with the specified fields replaced.
  ReservationModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? providerId,
    String? governorateId,
    ReservationType? type,
    int? groupSize,
    String? serviceId,
    String? serviceName,
    int? durationMinutes,
    Timestamp? reservationStartTime,
    Timestamp? endTime,
    ReservationStatus? status,
    String? paymentStatus,
    Map<String, dynamic>? paymentDetails,
    String? notes,
    Map<String, dynamic>? typeSpecificData,
    int? queuePosition,
    Timestamp? estimatedEntryTime,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<AttendeeModel>? attendees,
    String? reservationCode,
    double? totalPrice,
    List<String>? selectedAddOnsList,
    bool? isFullVenueReservation,
    int? reservedCapacity,
    bool? isCommunityVisible,
    String? hostingCategory,
    String? hostingDescription,
    Map<String, dynamic>? costSplitDetails,
    List<Map<String, dynamic>>? joinRequests,
    QueueStatus? queueStatus,
    bool? queueBased,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      providerId: providerId ?? this.providerId,
      governorateId: governorateId ?? this.governorateId,
      type: type ?? this.type,
      groupSize: groupSize ?? this.groupSize,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reservationStartTime: reservationStartTime ?? this.reservationStartTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      notes: notes ?? this.notes,
      typeSpecificData: typeSpecificData ?? this.typeSpecificData,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedEntryTime: estimatedEntryTime ?? this.estimatedEntryTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendees: attendees ?? this.attendees,
      reservationCode: reservationCode ?? this.reservationCode,
      totalPrice: totalPrice ?? this.totalPrice,
      selectedAddOnsList: selectedAddOnsList ?? this.selectedAddOnsList,
      isFullVenueReservation:
          isFullVenueReservation ?? this.isFullVenueReservation,
      reservedCapacity: reservedCapacity ?? this.reservedCapacity,
      isCommunityVisible: isCommunityVisible ?? this.isCommunityVisible,
      hostingCategory: hostingCategory ?? this.hostingCategory,
      hostingDescription: hostingDescription ?? this.hostingDescription,
      costSplitDetails: costSplitDetails ?? this.costSplitDetails,
      joinRequests: joinRequests ?? this.joinRequests,
      queueStatus: queueStatus ?? this.queueStatus,
      queueBased: queueBased ?? this.queueBased,
    );
  }
}
