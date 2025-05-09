// lib/feature/options_configuration/bloc/options_configuration_event.dart
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart'; // Ensure Equatable is imported directly for this file's scope



abstract class OptionsConfigurationEvent extends Equatable {
  const OptionsConfigurationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the configuration screen with a specific plan or service.
/// This event will carry the necessary `optionsDefinition` to build the UI.
class InitializeOptionsConfiguration extends OptionsConfigurationEvent {
  final String providerId;
  final PlanModel? plan; // The selected plan, if configuring a plan
  final ServiceModel? service; // The selected service, if configuring a service
  // Potentially pass existing selections if editing a configuration
  // final Map<String, dynamic>? existingSelections;

  const InitializeOptionsConfiguration({
    required this.providerId,
    this.plan,
    this.service,
    // this.existingSelections,
  }) : assert(plan != null || service != null, 'Either a plan or a service must be provided.');

  @override
  List<Object?> get props => [providerId, plan, service];

  // Helper to get the options definition
  Map<String, dynamic>? get optionsDefinition => plan?.optionsDefinition ?? service?.optionsDefinition;
  String get itemName => plan?.name ?? service?.name ?? 'Item';
  String get itemId => plan?.id ?? service?.id ?? '';
  String get itemType => plan != null ? 'plan' : 'service';
}

/// Event triggered when the user selects a date.
class DateSelected extends OptionsConfigurationEvent {
  final DateTime selectedDate;

  const DateSelected({required this.selectedDate});

  @override
  List<Object?> get props => [selectedDate];
}

/// Event triggered when the user selects a time slot or time preference.
class TimeSelected extends OptionsConfigurationEvent {
  final String selectedTime; // Could be a specific slot "09:00-10:00" or a preference "Morning"

  const TimeSelected({required this.selectedTime});

  @override
  List<Object?> get props => [selectedTime];
}

/// Event triggered when the user changes the quantity of a service/item.
class QuantityChanged extends OptionsConfigurationEvent {
  final int quantity;

  const QuantityChanged({required this.quantity});

  @override
  List<Object?> get props => [quantity];
}

/// Event triggered when the user selects or deselects an add-on.
class AddOnToggled extends OptionsConfigurationEvent {
  final String addOnId;
  final bool isSelected;
  final double addOnPrice; // Price of the add-on, needed for total calculation

  const AddOnToggled({required this.addOnId, required this.isSelected, required this.addOnPrice});

  @override
  List<Object?> get props => [addOnId, isSelected, addOnPrice];
}

/// Event for updating custom notes.
class NotesUpdated extends OptionsConfigurationEvent {
  final String notes;

  const NotesUpdated({required this.notes});

  @override
  List<Object?> get props => [notes];
}

/// Event to finalize the configuration and proceed (e.g., to booking summary or cart).
class ConfirmConfiguration extends OptionsConfigurationEvent {
  // May not need parameters if all data is in the state,
  // or could carry final validated selections.
  const ConfirmConfiguration();
}
