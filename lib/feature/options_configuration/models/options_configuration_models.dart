import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show PaymentStatus, AttendeeModel;
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// PaymentStatus is imported from reservation_model.dart

enum AttendeeType {
  currentUser,
  friend,
  familyMember,
  external, // For adding people not on the platform by name only
}

class AttendeeConfig extends Equatable {
  final String id;
  final String name;
  final AttendeeType type;
  final String? profilePictureUrl;
  final PaymentStatus paymentStatus;
  final double amountOwed;
  final bool isConfirmed; // Whether the attendee has confirmed their attendance
  final String? userId; // Firestore user ID for friends/family members
  final String? relationship; // For family members

  const AttendeeConfig({
    required this.id,
    required this.name,
    required this.type,
    this.profilePictureUrl,
    required this.paymentStatus,
    required this.amountOwed,
    this.isConfirmed = false,
    this.userId,
    this.relationship,
  });

  AttendeeConfig copyWith({
    String? id,
    String? name,
    AttendeeType? type,
    String? profilePictureUrl,
    PaymentStatus? paymentStatus,
    double? amountOwed,
    bool? isConfirmed,
    String? userId,
    String? relationship,
  }) {
    return AttendeeConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountOwed: amountOwed ?? this.amountOwed,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      userId: userId ?? this.userId,
      relationship: relationship ?? this.relationship,
    );
  }

  // Create from an AttendeeModel (from reservation)
  factory AttendeeConfig.fromAttendeeModel(AttendeeModel model) {
    AttendeeType type;
    switch (model.type.toLowerCase()) {
      case 'self':
        type = AttendeeType.currentUser;
        break;
      case 'friend':
        type = AttendeeType.friend;
        break;
      case 'family':
        type = AttendeeType.familyMember;
        break;
      default:
        type = AttendeeType.external;
    }

    return AttendeeConfig(
      id: model.userId,
      name: model.name,
      type: type,
      profilePictureUrl: null, // Not directly available in AttendeeModel
      paymentStatus: model.paymentStatus,
      amountOwed: model.amountToPay ?? 0.0,
      isConfirmed: model.status.toLowerCase() == 'confirmed',
      userId: model.userId,
    );
  }

  // Create from a FamilyMember
  factory AttendeeConfig.fromFamilyMember(FamilyMember member) {
    return AttendeeConfig(
      id: member.id,
      name: member.name,
      type: AttendeeType.familyMember,
      profilePictureUrl: member.profilePicUrl,
      paymentStatus: PaymentStatus.pending,
      amountOwed: 0.0, // Will be calculated later
      userId: member.userId,
      relationship: member.relationship,
    );
  }

  // Create from a Friend
  factory AttendeeConfig.fromFriend(dynamic friend) {
    // Handle both Map<String, dynamic> (from Firestore) and friend objects
    String userId = '';
    String name = 'Unknown';
    String? profilePictureUrl;

    if (friend is Map<String, dynamic>) {
      // Handle Map from Firestore
      userId = friend['userId'] as String? ??
          friend['id'] as String? ??
          friend['friendId'] as String? ??
          '';
      name = friend['name'] as String? ??
          friend['displayName'] as String? ??
          friend['userName'] as String? ??
          'Unknown';
      profilePictureUrl = friend['profilePicUrl'] as String? ??
          friend['profilePictureUrl'] as String? ??
          friend['avatar'] as String?;
    } else {
      // Handle friend object with properties
      try {
        userId = friend.userId?.toString() ?? friend.id?.toString() ?? '';
        name = friend.name?.toString() ??
            friend.displayName?.toString() ??
            'Unknown';
        profilePictureUrl = friend.profilePicUrl?.toString() ??
            friend.profilePictureUrl?.toString();
      } catch (e) {
        // Fallback if properties don't exist
        userId = '';
        name = friend?.toString() ?? 'Unknown Friend';
        profilePictureUrl = null;
      }
    }

    return AttendeeConfig(
      id: userId,
      name: name,
      type: AttendeeType.friend,
      profilePictureUrl: profilePictureUrl,
      paymentStatus: PaymentStatus.pending,
      amountOwed: 0.0,
    );
  }

  // Convert to AttendeeModel for reservations
  AttendeeModel toAttendeeModel() {
    String attendeeType;
    switch (type) {
      case AttendeeType.currentUser:
        attendeeType = 'self';
        break;
      case AttendeeType.friend:
        attendeeType = 'friend';
        break;
      case AttendeeType.familyMember:
        attendeeType = 'family';
        break;
      default:
        attendeeType = 'guest';
    }

    return AttendeeModel(
      userId: id,
      name: name,
      type: attendeeType,
      status: isConfirmed ? 'confirmed' : 'invited',
      paymentStatus: paymentStatus,
      amountToPay: amountOwed,
      isHost: type == AttendeeType.currentUser, // Current user is the host
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        profilePictureUrl,
        paymentStatus,
        amountOwed,
        isConfirmed,
        userId,
        relationship,
      ];
}

enum VenueBookingType {
  fullVenue,
  partialCapacity,
}

class VenueBookingConfig extends Equatable {
  final VenueBookingType type;
  final int? selectedCapacity;
  final List<AttendeeConfig> attendees;
  final int capacity;
  final double price;
  final int maxCapacity;
  final double? pricePerPerson; // For dynamic pricing based on attendees
  final double?
      minCapacityPrice; // Minimum booking price regardless of attendees
  final bool
      isPrivateEvent; // Whether the event is private or open to other users

  const VenueBookingConfig({
    required this.type,
    this.selectedCapacity,
    this.attendees = const [],
    required this.capacity,
    required this.price,
    required this.maxCapacity,
    this.pricePerPerson,
    this.minCapacityPrice,
    this.isPrivateEvent = true,
  });

  // Calculate total capacity used by confirmed attendees
  int get confirmedCapacityUsed => attendees.where((a) => a.isConfirmed).length;

  // Calculate remaining capacity
  int get remainingCapacity => type == VenueBookingType.fullVenue
      ? maxCapacity - confirmedCapacityUsed
      : (selectedCapacity ?? 0) - confirmedCapacityUsed;

  // Calculate dynamic price based on attendees
  double calculateDynamicPrice() {
    if (type == VenueBookingType.fullVenue) {
      return price;
    } else {
      // If per-person pricing is defined
      if (pricePerPerson != null) {
        final calculatedPrice =
            (confirmedCapacityUsed * (pricePerPerson ?? 0.0));
        // Apply minimum price if set
        return minCapacityPrice != null
            ? (calculatedPrice > minCapacityPrice!
                ? calculatedPrice
                : minCapacityPrice!)
            : calculatedPrice;
      } else {
        // If no per-person pricing, use the fixed price
        return price;
      }
    }
  }

  VenueBookingConfig copyWith({
    VenueBookingType? type,
    int? selectedCapacity,
    List<AttendeeConfig>? attendees,
    int? capacity,
    double? price,
    int? maxCapacity,
    double? pricePerPerson,
    double? minCapacityPrice,
    bool? isPrivateEvent,
  }) {
    return VenueBookingConfig(
      type: type ?? this.type,
      selectedCapacity: (type ?? this.type) == VenueBookingType.fullVenue
          ? null
          : selectedCapacity ?? this.selectedCapacity,
      attendees: attendees ?? this.attendees,
      capacity: capacity ?? this.capacity,
      price: price ?? this.price,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      minCapacityPrice: minCapacityPrice ?? this.minCapacityPrice,
      isPrivateEvent: isPrivateEvent ?? this.isPrivateEvent,
    );
  }

  // Add an attendee to the booking
  VenueBookingConfig addAttendee(AttendeeConfig attendee) {
    // Check if we have capacity
    if (type == VenueBookingType.partialCapacity &&
        selectedCapacity != null &&
        attendees.length >= selectedCapacity!) {
      throw Exception("Maximum capacity reached");
    }

    if (type == VenueBookingType.fullVenue && attendees.length >= maxCapacity) {
      throw Exception("Maximum venue capacity reached");
    }

    final newAttendees = List<AttendeeConfig>.from(attendees);
    newAttendees.add(attendee);

    return copyWith(attendees: newAttendees);
  }

  // Remove an attendee by id
  VenueBookingConfig removeAttendee(String attendeeId) {
    final newAttendees = attendees.where((a) => a.id != attendeeId).toList();
    return copyWith(attendees: newAttendees);
  }

  // Update an attendee
  VenueBookingConfig updateAttendee(AttendeeConfig updatedAttendee) {
    final index = attendees.indexWhere((a) => a.id == updatedAttendee.id);
    if (index == -1) {
      return this;
    }

    final newAttendees = List<AttendeeConfig>.from(attendees);
    newAttendees[index] = updatedAttendee;

    return copyWith(attendees: newAttendees);
  }

  @override
  List<Object?> get props => [
        type,
        selectedCapacity,
        attendees,
        capacity,
        price,
        maxCapacity,
        pricePerPerson,
        minCapacityPrice,
        isPrivateEvent,
      ];
}

enum CostSplitType {
  splitEqually,
  payAllMyself,
  splitCustom, // For custom splitting of costs
}

class CostSplitConfig extends Equatable {
  final CostSplitType type;
  final double totalAmount;
  final Map<String, double>? customSplits; // Map of attendee ID to amount
  final bool isHostPaying; // Whether the host is paying for all or not

  const CostSplitConfig({
    required this.type,
    required this.totalAmount,
    this.customSplits,
    this.isHostPaying = false,
  });

  CostSplitConfig copyWith({
    CostSplitType? type,
    double? totalAmount,
    Map<String, double>? customSplits,
    bool? isHostPaying,
  }) {
    return CostSplitConfig(
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      customSplits: customSplits ?? this.customSplits,
      isHostPaying: isHostPaying ?? this.isHostPaying,
    );
  }

  // Calculate individual cost shares based on the split type
  Map<String, double> calculateCostShares(List<AttendeeConfig> attendees) {
    Map<String, double> shares = {};

    switch (type) {
      case CostSplitType.splitEqually:
        if (isHostPaying) {
          // Host pays for all, others pay 0
          for (var attendee in attendees) {
            shares[attendee.id] =
                attendee.type == AttendeeType.currentUser ? totalAmount : 0.0;
          }
        } else {
          // Equal split among all attendees
          final perPersonCost = totalAmount / attendees.length;
          for (var attendee in attendees) {
            shares[attendee.id] = perPersonCost;
          }
        }
        break;

      case CostSplitType.payAllMyself:
        // Current user pays for all
        for (var attendee in attendees) {
          shares[attendee.id] =
              attendee.type == AttendeeType.currentUser ? totalAmount : 0.0;
        }
        break;

      case CostSplitType.splitCustom:
        if (customSplits != null) {
          shares = Map.from(customSplits!);

          // Ensure all attendees have an entry
          for (var attendee in attendees) {
            if (!shares.containsKey(attendee.id)) {
              shares[attendee.id] = 0.0;
            }
          }
        } else {
          // Default to equal split if custom is selected but no splits defined
          final perPersonCost = totalAmount / attendees.length;
          for (var attendee in attendees) {
            shares[attendee.id] = perPersonCost;
          }
        }
        break;
    }

    return shares;
  }

  // Apply calculated cost shares to a list of attendees
  List<AttendeeConfig> applyCostSharesToAttendees(
      List<AttendeeConfig> attendees) {
    final shares = calculateCostShares(attendees);
    return attendees.map((attendee) {
      return attendee.copyWith(
        amountOwed: shares[attendee.id] ?? 0.0,
      );
    }).toList();
  }

  @override
  List<Object?> get props => [type, totalAmount, customSplits, isHostPaying];
}

// This enum might be defined in your reservation_model.dart or globally
// enum PaymentStatus { pending, paid, failed, notApplicable }
// Re-declared or ensure it's imported if not directly available.
// Note: It was already declared at the top for AttendeeConfig.
// If it's in reservation_model.dart, use:
// import 'package:your_app_name/feature/reservation/data/models/reservation_model.dart' show PaymentStatus;
