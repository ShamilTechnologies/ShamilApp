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

// --- Extensions ---

// Extension for ReservationType
extension ReservationTypeExtension on ReservationType {
  /// Returns the string representation used in Firestore.
  String get typeString {
    switch (this) {
      case ReservationType.timeBased: return 'time-based';
      case ReservationType.serviceBased: return 'service-based';
      case ReservationType.seatBased: return 'seat-based';
      case ReservationType.recurring: return 'recurring';
      case ReservationType.group: return 'group';
      case ReservationType.accessBased: return 'access-based';
      case ReservationType.sequenceBased: return 'sequence-based';
      default: return 'unknown';
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
    case 'timebased': return ReservationType.timeBased;
    case 'servicebased': return ReservationType.serviceBased;
    case 'seatbased': return ReservationType.seatBased;
    case 'recurring': return ReservationType.recurring;
    case 'group': return ReservationType.group;
    case 'accessbased': return ReservationType.accessBased;
    case 'sequencebased': return ReservationType.sequenceBased;
    default:
      debugPrint("Warning: Unknown reservation type string '$typeString', defaulting to unknown.");
      return ReservationType.unknown;
  }
}

// Extension for PaymentStatus
extension PaymentStatusExtension on PaymentStatus {
  /// Parses a string into a PaymentStatus enum. Defaults to pending.
  static PaymentStatus fromString(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'pending': return PaymentStatus.pending;
      case 'partial': return PaymentStatus.partial;
      case 'complete': return PaymentStatus.complete;
      case 'hosted': return PaymentStatus.hosted;
      case 'waived': return PaymentStatus.waived;
      default:
        // Don't print warning for null, only for unrecognized strings
        if (statusString != null) {
            debugPrint("Warning: Unknown payment status string '$statusString', defaulting to pending.");
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
      case ReservationStatus.pending: return 'pending';
      case ReservationStatus.confirmed: return 'confirmed';
      case ReservationStatus.cancelledByUser: return 'cancelled_by_user';
      case ReservationStatus.cancelledByProvider: return 'cancelled_by_provider';
      case ReservationStatus.completed: return 'completed';
      case ReservationStatus.noShow: return 'no_show';
      default: return 'unknown';
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
    case 'pending': return ReservationStatus.pending;
    case 'confirmed': return ReservationStatus.confirmed;
    case 'cancelled': // Handle potential legacy 'cancelled'
    case 'cancelled_by_user': return ReservationStatus.cancelledByUser;
    case 'cancelled_by_provider': return ReservationStatus.cancelledByProvider;
    case 'completed': return ReservationStatus.completed;
    case 'no_show':
    case 'noshow': return ReservationStatus.noShow;
    default:
       // Don't print warning for null, only for unrecognized strings
       if (status != null) {
           debugPrint("Warning: Unknown reservation status string '$status', defaulting to unknown.");
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
  final String status; // 'going', 'invited', 'declined', 'confirmed' // Added confirmed?

  // New fields
  final PaymentStatus paymentStatus;
  final double? amountToPay; // Individual's portion of the payment
  final bool isHost; // Whether this attendee is hosting the reservation

  const AttendeeModel({
    required this.userId,
    required this.name,
    required this.type,
    required this.status,
    this.paymentStatus = PaymentStatus.pending, // Default to pending
    this.amountToPay, // Allow null amount
    this.isHost = false, // Default to not host
  });

  factory AttendeeModel.fromMap(Map<String, dynamic> map) {
    return AttendeeModel(
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Attendee',
      type: map['type'] as String? ?? 'unknown', // e.g. 'guest' if not specified
      status: map['status'] as String? ?? 'unknown', // e.g. 'invited' or 'unknown'
      // Parse new fields with defaults using the extension
      paymentStatus: PaymentStatusExtension.fromString(map['paymentStatus'] as String?),
      // Safely parse amountToPay
      amountToPay: (map['amountToPay'] as num?)?.toDouble(),
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
      // Only include amountToPay if it's not null
      if (amountToPay != null) 'amountToPay': amountToPay,
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
    bool? isHost,
    // Special flag to explicitly set amountToPay to null if needed
    bool clearAmountToPay = false,
  }) {
    return AttendeeModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      // Use clear flag or existing logic for amount
      amountToPay: clearAmountToPay ? null : (amountToPay ?? this.amountToPay),
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        type,
        status,
        paymentStatus, // Add new field to props
        amountToPay,   // Add new field to props
        isHost,        // Add new field to props
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
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

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
      type: reservationTypeFromString(data['reservationType'] as String? ?? data['type'] as String?),
      groupSize: effectiveGroupSize,
      serviceId: data['serviceId'] as String?,
      serviceName: data['serviceName'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      // Handle legacy 'dateTime' field if 'reservationStartTime' is missing
      reservationStartTime: data['reservationStartTime'] as Timestamp? ?? data['dateTime'] as Timestamp?,
      endTime: data['endTime'] as Timestamp?,
      status: reservationStatusFromString(data['status'] as String?),
      paymentStatus: data['paymentStatus'] as String?, // Kept based on snippet
      paymentDetails: data['paymentDetails'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      typeSpecificData: data['typeSpecificData'] as Map<String, dynamic>?,
      queuePosition: (data['queuePosition'] as num?)?.toInt(),
      estimatedEntryTime: data['estimatedEntryTime'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(), // Fallback needed?
      updatedAt: data['updatedAt'] as Timestamp?,
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
    );
  }

  /// Generates a map suitable for creating a new reservation document.
  /// Excludes fields automatically set by Firestore (like id, timestamps).
  Map<String, dynamic> toMapForCreate() {
    // Ensure attendees are converted using the updated toMap method
    final attendeesMapList = attendees.map((attendee) => attendee.toMap()).toList();

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
      if (reservationStartTime != null) 'reservationStartTime': reservationStartTime,
      if (endTime != null) 'endTime': endTime,
      'status': status.statusString, // Use string representation
      if (paymentStatus != null) 'paymentStatus': paymentStatus, // Kept based on snippet
      if (paymentDetails != null) 'paymentDetails': paymentDetails,
      if (notes != null) 'notes': notes,
      if (typeSpecificData != null) 'typeSpecificData': typeSpecificData,
      if (queuePosition != null) 'queuePosition': queuePosition,
      if (estimatedEntryTime != null) 'estimatedEntryTime': estimatedEntryTime,
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
    if (newCostSplitDetails != null) map['costSplitDetails'] = newCostSplitDetails;
    if (newCommunityVisibility != null) map['isCommunityVisible'] = newCommunityVisibility;
    // Handle category/description updates carefully based on visibility
    if (newHostingCategory != null) {
      map['hostingCategory'] = newHostingCategory;
    } else if (newCommunityVisibility == false) map['hostingCategory'] = FieldValue.delete(); // Remove if not visible
    if (newHostingDescription != null) {
      map['hostingDescription'] = newHostingDescription;
    } else if (newCommunityVisibility == false) map['hostingDescription'] = FieldValue.delete(); // Remove if not visible

     if (updatedAttendees != null) map['attendees'] = updatedAttendees.map((a) => a.toMap()).toList();
     if (newPaymentDetails != null) map['paymentDetails'] = newPaymentDetails;
     if (newNotes != null) map['notes'] = newNotes;
     if (newTypeSpecificData != null) map['typeSpecificData'] = newTypeSpecificData;
     if (updatedJoinRequests != null) map['joinRequests'] = updatedJoinRequests; // Update the requests list


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
      ];
}