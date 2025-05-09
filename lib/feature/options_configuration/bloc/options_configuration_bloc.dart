// lib/feature/options_configuration/bloc/options_configuration_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/options_configuration_event.dart';
// Make sure these paths are correct for your project structure

// If you have a separate model for AddOns, import it here.
// For simplicity, we'll assume add-on details like price are passed with events or known.
// import 'package:shamil_mobile_app/feature/options_configuration/data/add_on_model.dart';

part 'options_configuration_state.dart';

class OptionsConfigurationBloc
    extends Bloc<OptionsConfigurationEvent, OptionsConfigurationState> {
  OptionsConfigurationBloc()
      // Start with the OptionsConfigurationInitial state.
      // The UI will dispatch InitializeOptionsConfiguration with the necessary data.
      : super(OptionsConfigurationInitial()) {
    on<InitializeOptionsConfiguration>(_onInitializeOptionsConfiguration);
    on<DateSelected>(_onDateSelected);
    on<TimeSelected>(_onTimeSelected);
    on<QuantityChanged>(_onQuantityChanged);
    on<AddOnToggled>(_onAddOnToggled);
    on<NotesUpdated>(_onNotesUpdated);
    on<ConfirmConfiguration>(_onConfirmConfiguration);
  }

  void _onInitializeOptionsConfiguration(
    InitializeOptionsConfiguration event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    // Determine the base price from the plan or service
    double initialBasePrice = event.plan?.price ?? event.service?.price ?? 0.0;
    int initialQuantity = 1; // Default quantity

    // Check optionsDefinition for a default quantity, if specified
    final options = event.optionsDefinition;
    if (options != null && options['quantityDetails'] is Map) {
        final qtyDetails = options['quantityDetails'] as Map;
        // Use 'default' or 'initial' key for default quantity from optionsDefinition
        initialQuantity = (qtyDetails['default'] as int?) ?? (qtyDetails['initial'] as int?) ?? initialQuantity;
    }

    // Initial total price calculation
    double initialTotalPrice = initialBasePrice * initialQuantity;

    emit(OptionsConfigurationState(
      providerId: event.providerId,
      originalPlan: event.plan,
      originalService: event.service,
      basePrice: initialBasePrice,
      quantity: initialQuantity,
      totalPrice: initialTotalPrice, // Set initial total price
      selectedAddOns: const {}, // Start with no add-ons selected
      isLoading: false, // Initialization is complete
      canConfirm: _checkCanConfirm( // Check if initial state is confirmable
        options: event.optionsDefinition,
        selectedDate: null, // No date selected initially
        selectedTime: null, // No time selected initially
        quantity: initialQuantity,
      ),
    ));
  }

  void _onDateSelected(
    DateSelected event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    // Ensure the BLoC is in a configurable state (not initial or error)
    if (state.originalPlan == null && state.originalService == null) return;

    emit(state.copyWith(
      selectedDate: event.selectedDate,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: event.selectedDate,
        selectedTime: state.selectedTime,
        quantity: state.quantity,
      ),
      clearErrorMessage: true, // Clear any previous error messages
    ));
  }

  void _onTimeSelected(
    TimeSelected event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state.originalPlan == null && state.originalService == null) return;

    emit(state.copyWith(
      selectedTime: event.selectedTime,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: event.selectedTime,
        quantity: state.quantity,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onQuantityChanged(
    QuantityChanged event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state.originalPlan == null && state.originalService == null) return;

    int newQuantity = event.quantity;
    // Apply min/max quantity constraints from optionsDefinition if they exist
    final qtyDetails = state.optionsDefinition?['quantityDetails'] as Map?;
    if (qtyDetails != null) {
        final minQty = qtyDetails['min'] as int?;
        final maxQty = qtyDetails['max'] as int?;
        if (minQty != null && newQuantity < minQty) newQuantity = minQty;
        if (maxQty != null && newQuantity > maxQty) newQuantity = maxQty;
    }
    if (newQuantity < 1) newQuantity = 1; // Absolute minimum


    final newTotalPrice = (state.basePrice * newQuantity) + state.addOnsPrice;
    emit(state.copyWith(
      quantity: newQuantity,
      totalPrice: newTotalPrice,
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        quantity: newQuantity,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onAddOnToggled(
    AddOnToggled event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state.originalPlan == null && state.originalService == null) return;

    final newSelectedAddOns = Map<String, bool>.from(state.selectedAddOns);
    newSelectedAddOns[event.addOnId] = event.isSelected;

    // Recalculate addOnsPrice based on all currently selected addOns.
    // This simplified version uses the price passed in the event.
    // A more robust solution would involve looking up add-on prices from a data source
    // (e.g., if add-ons are defined in optionsDefinition with their prices, or fetched separately).
    double currentAddOnsTotal = state.addOnsPrice;
    if (event.isSelected) {
      currentAddOnsTotal += event.addOnPrice;
    } else {
      // Ensure we don't subtract if the addOn wasn't actually adding to the price before
      // This logic might need refinement if addOnPrice in event is always positive.
      // A better way: recalculate from scratch based on newSelectedAddOns and their known prices.
      currentAddOnsTotal -= event.addOnPrice;
    }
    // Ensure addOnsPrice doesn't go negative
    final newAddOnsPrice = currentAddOnsTotal < 0 ? 0.0 : currentAddOnsTotal;

    final newTotalPrice = (state.basePrice * state.quantity) + newAddOnsPrice;

    emit(state.copyWith(
      selectedAddOns: newSelectedAddOns,
      addOnsPrice: newAddOnsPrice,
      totalPrice: newTotalPrice,
      // Confirmation status usually doesn't depend on optional add-ons,
      // but might if certain add-ons become mandatory based on other selections.
      canConfirm: _checkCanConfirm(
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        quantity: state.quantity,
      ),
      clearErrorMessage: true,
    ));
  }

  void _onNotesUpdated(
    NotesUpdated event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state.originalPlan == null && state.originalService == null) return;
    emit(state.copyWith(notes: event.notes));
  }

  void _onConfirmConfiguration(
    ConfirmConfiguration event,
    Emitter<OptionsConfigurationState> emit,
  ) {
    if (state.originalPlan == null && state.originalService == null) return;

    if (!_checkCanConfirm( // Re-validate before confirming
        options: state.optionsDefinition,
        selectedDate: state.selectedDate,
        selectedTime: state.selectedTime,
        quantity: state.quantity)) {
      emit(state.copyWith(errorMessage: "Please complete all required options."));
      return;
    }

    // All checks passed, emit confirmed state
    emit(OptionsConfigurationConfirmed(
      providerId: state.providerId,
      originalPlan: state.originalPlan,
      originalService: state.originalService,
      selectedDate: state.selectedDate,
      selectedTime: state.selectedTime,
      quantity: state.quantity,
      selectedAddOns: state.selectedAddOns,
      notes: state.notes,
      basePrice: state.basePrice,
      addOnsPrice: state.addOnsPrice,
      totalPrice: state.totalPrice,
    ));
  }

  /// Helper function to determine if the configuration is valid to proceed.
  /// This logic depends heavily on the `optionsDefinition` map.
  bool _checkCanConfirm({
    required Map<String, dynamic>? options,
    required DateTime? selectedDate,
    required String? selectedTime,
    required int quantity,
  }) {
    // If no options are defined, it's always confirmable (or based on other business rules)
    if (options == null) return true;

    bool dateRequirementMet = true;
    if (options['allowDateSelection'] == true) {
      dateRequirementMet = selectedDate != null;
    }

    bool timeRequirementMet = true;
    if (options['allowTimeSelection'] == true) {
      // Could also check if selectedTime is one of the 'availableTimeSlots' if defined
      timeRequirementMet = selectedTime != null && selectedTime.isNotEmpty;
    }

    bool quantityRequirementMet = true;
    if (options['allowQuantitySelection'] == true && options['quantityDetails'] is Map) {
        final qtyDetails = options['quantityDetails'] as Map;
        final minQty = qtyDetails['min'] as int?;
        final maxQty = qtyDetails['max'] as int?;
        if (minQty != null && quantity < minQty) quantityRequirementMet = false;
        if (maxQty != null && quantity > maxQty) quantityRequirementMet = false;
        if (quantity < 1) quantityRequirementMet = false; // Absolute minimum
    } else if (options['allowQuantitySelection'] == true) {
        // If allowQuantitySelection is true but no details, assume quantity must be >= 1
        if (quantity < 1) quantityRequirementMet = false;
    }


    // Placeholder for checking mandatory add-ons if such a concept exists
    // bool mandatoryAddOnsMet = true;
    // if (options['mandatoryAddOnIds'] is List) {
    //   List<String> mandatoryIds = List<String>.from(options['mandatoryAddOnIds']);
    //   for (String id in mandatoryIds) {
    //     if (!(state.selectedAddOns[id] ?? false)) { // Assuming state is accessible or passed
    //       mandatoryAddOnsMet = false;
    //       break;
    //     }
    //   }
    // }

    return dateRequirementMet && timeRequirementMet && quantityRequirementMet; // && mandatoryAddOnsMet;
  }
}
