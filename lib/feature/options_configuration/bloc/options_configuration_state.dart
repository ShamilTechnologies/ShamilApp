// lib/feature/options_configuration/bloc/options_configuration_state.dart

part of 'options_configuration_bloc.dart'; // Ensures this is part of the BLoC file

/// Represents the state of the user's selections on the Options Configuration screen.
class OptionsConfigurationState extends Equatable {
  // Original item being configured
  final String providerId;
  final PlanModel? originalPlan; // The plan being configured, if applicable
  final ServiceModel? originalService; // The service being configured, if applicable

  // User's current selections based on optionsDefinition
  final DateTime? selectedDate;
  final String? selectedTime; // e.g., "09:00-10:00" or "Morning"
  final int quantity;
  final Map<String, bool> selectedAddOns; // Key: addOnId, Value: isSelected
  final String? notes;

  // Calculated values based on selections
  final double basePrice; // Base price of the plan/service
  final double addOnsPrice; // Total price of selected add-ons
  final double totalPrice; // Overall total price (base * quantity + addOns)

  // Status fields for the UI
  final bool isLoading; // For any async operations (e.g., validating time slots)
  final String? errorMessage; // For displaying errors related to configuration choices
  final bool canConfirm; // Whether the current configuration is valid and complete to proceed

  const OptionsConfigurationState({
    required this.providerId,
    this.originalPlan,
    this.originalService,
    this.selectedDate,
    this.selectedTime,
    this.quantity = 1, // Default quantity
    this.selectedAddOns = const {}, // Default to no add-ons selected
    this.notes,
    this.basePrice = 0.0,
    this.addOnsPrice = 0.0,
    this.totalPrice = 0.0,
    this.isLoading = false,
    this.errorMessage,
    this.canConfirm = false, // Initially, confirmation might be disabled
  });

  // Helper to get the options definition from the original plan or service
  // This is what drives the dynamic UI for configuration.
  Map<String, dynamic>? get optionsDefinition =>
      originalPlan?.optionsDefinition ?? originalService?.optionsDefinition;

  // Helper to get the name of the item being configured
  String get itemName => originalPlan?.name ?? originalService?.name ?? 'Item';

  // Helper to get the ID of the item being configured
  String get itemId => originalPlan?.id ?? originalService?.id ?? '';

  // Helper to determine if a plan or a service is being configured
  String get itemType => originalPlan != null ? 'plan' : 'service';


  OptionsConfigurationState copyWith({
    String? providerId,
    PlanModel? originalPlan,
    ServiceModel? originalService,
    DateTime? selectedDate,
    String? selectedTime,
    int? quantity,
    Map<String, bool>? selectedAddOns,
    String? notes,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    bool? isLoading,
    String? errorMessage,
    bool? clearErrorMessage, // Utility to clear the error message specifically
    bool? canConfirm,
  }) {
    return OptionsConfigurationState(
      providerId: providerId ?? this.providerId,
      originalPlan: originalPlan ?? this.originalPlan,
      originalService: originalService ?? this.originalService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      quantity: quantity ?? this.quantity,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      notes: notes ?? this.notes,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: (clearErrorMessage == true) ? null : (errorMessage ?? this.errorMessage),
      canConfirm: canConfirm ?? this.canConfirm,
    );
  }

  @override
  List<Object?> get props => [
        providerId,
        originalPlan,
        originalService,
        selectedDate,
        selectedTime,
        quantity,
        selectedAddOns,
        notes,
        basePrice,
        addOnsPrice,
        totalPrice,
        isLoading,
        errorMessage,
        canConfirm,
      ];
}

/// State indicating that the configuration is confirmed and ready to proceed
/// to the next step (e.g., booking summary, add to cart).
/// It carries all the final selected data.
class OptionsConfigurationConfirmed extends OptionsConfigurationState {
  const OptionsConfigurationConfirmed({
    required super.providerId,
    super.originalPlan,
    super.originalService,
    super.selectedDate,
    super.selectedTime,
    required super.quantity,
    required super.selectedAddOns,
    super.notes,
    required super.basePrice,
    required super.addOnsPrice,
    required super.totalPrice,
  }) : super(canConfirm: true, isLoading: false); // Confirmed state implies it was confirmable and not loading
}

/// Optional: An initial state before `InitializeOptionsConfiguration` is dispatched.
/// This can be useful if the BLoC needs a distinct starting point before it has
/// the plan/service details.
class OptionsConfigurationInitial extends OptionsConfigurationState {
  OptionsConfigurationInitial() : super(providerId: '', isLoading: true); // Default empty providerId, isLoading true
}
