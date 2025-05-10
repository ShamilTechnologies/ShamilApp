// lib/feature/options_configuration/options_configuration_event.dart
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
// Ensure AttendeeModel is correctly imported. Assuming it's in reservation_model.dart
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart'
    show AttendeeModel;

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

class ConfirmConfiguration extends OptionsConfigurationEvent {
  const ConfirmConfiguration();
}

class ClearErrorMessage extends OptionsConfigurationEvent {
  const ClearErrorMessage();
}
