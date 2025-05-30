// lib/feature/options_configuration/options_configuration_event.dart
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
// Ensure AttendeeModel is correctly imported. Assuming it's in reservation_model.dart
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show AttendeeModel;
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';

abstract class OptionsConfigurationEvent extends Equatable {
  const OptionsConfigurationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeOptionsConfiguration extends OptionsConfigurationEvent {
  final String providerId;
  final PlanModel? plan;
  final ServiceModel? service;

  const InitializeOptionsConfiguration({
    required this.providerId,
    this.plan,
    this.service,
  }) : assert(plan != null || service != null,
            'Either a plan or a service must be provided.');

  @override
  List<Object?> get props => [providerId, plan, service];

  Map<String, dynamic>? get optionsDefinition =>
      plan?.optionsDefinition ?? service?.optionsDefinition;
  String get itemName => plan?.name ?? service?.name ?? 'Item';
  String get itemId => plan?.id ?? service?.id ?? '';
}

class LoadProviderOperatingHours extends OptionsConfigurationEvent {
  final String providerId;

  const LoadProviderOperatingHours({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

class LoadProviderReservations extends OptionsConfigurationEvent {
  final String providerId;

  const LoadProviderReservations({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

class DateSelected extends OptionsConfigurationEvent {
  final DateTime selectedDate;
  const DateSelected({required this.selectedDate});
  @override
  List<Object?> get props => [selectedDate];
}

class TimeSelected extends OptionsConfigurationEvent {
  final String selectedTime;
  const TimeSelected({required this.selectedTime});
  @override
  List<Object?> get props => [selectedTime];
}

class QuantityChanged extends OptionsConfigurationEvent {
  final int quantity;
  const QuantityChanged({required this.quantity});
  @override
  List<Object?> get props => [quantity];
}

class AddOnToggled extends OptionsConfigurationEvent {
  final String addOnId;
  final bool isSelected;
  final double addOnPrice;

  const AddOnToggled(
      {required this.addOnId,
      required this.isSelected,
      required this.addOnPrice});
  @override
  List<Object?> get props => [addOnId, isSelected, addOnPrice];
}

class NotesUpdated extends OptionsConfigurationEvent {
  final String notes;
  const NotesUpdated({required this.notes});
  @override
  List<Object?> get props => [notes];
}

class AddOptionAttendee extends OptionsConfigurationEvent {
  final AttendeeModel attendee; // Using AttendeeModel from reservation feature
  const AddOptionAttendee({required this.attendee});
  @override
  List<Object?> get props => [attendee];
}

class RemoveOptionAttendee extends OptionsConfigurationEvent {
  final String attendeeUserId;
  const RemoveOptionAttendee({required this.attendeeUserId});
  @override
  List<Object?> get props => [attendeeUserId];
}

// New events for handling friends and family members

class LoadCurrentUserFriends extends OptionsConfigurationEvent {
  const LoadCurrentUserFriends();
}

class LoadCurrentUserFamilyMembers extends OptionsConfigurationEvent {
  const LoadCurrentUserFamilyMembers();
}

class AddFriendAsAttendee extends OptionsConfigurationEvent {
  final dynamic friend; // Friend type from social module
  const AddFriendAsAttendee({required this.friend});
  @override
  List<Object?> get props => [friend];
}

class AddFamilyMemberAsAttendee extends OptionsConfigurationEvent {
  final FamilyMember familyMember;
  const AddFamilyMemberAsAttendee({required this.familyMember});
  @override
  List<Object?> get props => [familyMember];
}

class AddExternalAttendee extends OptionsConfigurationEvent {
  final String name;
  final String? email;
  final String? phone;
  final String? relationship;

  const AddExternalAttendee({
    required this.name,
    this.email,
    this.phone,
    this.relationship,
  });

  @override
  List<Object?> get props => [name, email, phone, relationship];
}

// Venue booking events
class ChangeVenueBookingType extends OptionsConfigurationEvent {
  final VenueBookingType bookingType;
  const ChangeVenueBookingType({required this.bookingType});
  @override
  List<Object?> get props => [bookingType];
}

class UpdateSelectedCapacity extends OptionsConfigurationEvent {
  final int capacity;
  const UpdateSelectedCapacity({required this.capacity});
  @override
  List<Object?> get props => [capacity];
}

class UpdateVenueIsPrivate extends OptionsConfigurationEvent {
  final bool isPrivate;
  const UpdateVenueIsPrivate({required this.isPrivate});
  @override
  List<Object?> get props => [isPrivate];
}

// Cost splitting events
class ChangeCostSplitType extends OptionsConfigurationEvent {
  final CostSplitType splitType;
  const ChangeCostSplitType({required this.splitType});
  @override
  List<Object?> get props => [splitType];
}

class UpdateHostPaying extends OptionsConfigurationEvent {
  final bool isHostPaying;
  const UpdateHostPaying({required this.isHostPaying});
  @override
  List<Object?> get props => [isHostPaying];
}

class UpdateCustomCostSplit extends OptionsConfigurationEvent {
  final String attendeeId;
  final double amount;

  const UpdateCustomCostSplit({
    required this.attendeeId,
    required this.amount,
  });

  @override
  List<Object?> get props => [attendeeId, amount];
}

// New event for calendar integration
class ToggleAddToCalendar extends OptionsConfigurationEvent {
  final bool addToCalendar;

  const ToggleAddToCalendar({required this.addToCalendar});

  @override
  List<Object?> get props => [addToCalendar];
}

// New event for payment method selection
class UpdatePaymentMethod extends OptionsConfigurationEvent {
  final String paymentMethod;

  const UpdatePaymentMethod({required this.paymentMethod});

  @override
  List<Object?> get props => [paymentMethod];
}

// New event for reminder settings
class UpdateReminderSettings extends OptionsConfigurationEvent {
  final bool enableReminders;
  final List<int>
      reminderTimes; // Minutes before the event [60, 1440] = 1h, 24h

  const UpdateReminderSettings({
    required this.enableReminders,
    required this.reminderTimes,
  });

  @override
  List<Object?> get props => [enableReminders, reminderTimes];
}

// New event for sharing settings
class UpdateSharingSettings extends OptionsConfigurationEvent {
  final bool enableSharing;
  final bool shareWithAttendees;
  final List<String>? additionalEmails;

  const UpdateSharingSettings({
    required this.enableSharing,
    this.shareWithAttendees = true,
    this.additionalEmails,
  });

  @override
  List<Object?> get props =>
      [enableSharing, shareWithAttendees, additionalEmails];
}

class ConfirmConfiguration extends OptionsConfigurationEvent {
  final bool? paymentSuccessful;

  const ConfirmConfiguration({this.paymentSuccessful});

  @override
  List<Object?> get props => [paymentSuccessful];
}

// New event for updating total price when attendee count changes
class UpdateTotalPrice extends OptionsConfigurationEvent {
  final double totalPrice;

  const UpdateTotalPrice({required this.totalPrice});

  @override
  List<Object?> get props => [totalPrice];
}

// New events for managing user self-inclusion
class ToggleUserSelfInclusion extends OptionsConfigurationEvent {
  final bool includeUser;

  const ToggleUserSelfInclusion({required this.includeUser});

  @override
  List<Object?> get props => [includeUser];
}

// Event to update payment mode (individual vs pay for all)
class UpdatePaymentMode extends OptionsConfigurationEvent {
  final bool payForAll;

  const UpdatePaymentMode({required this.payForAll});

  @override
  List<Object?> get props => [payForAll];
}

class ClearErrorMessage extends OptionsConfigurationEvent {
  const ClearErrorMessage();
}
