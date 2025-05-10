// lib/feature/options_configuration/bloc/options_configuration_state.dart
part of 'options_configuration_bloc.dart'; // Ensures this is part of the BLoC file

class OptionsConfigurationState extends Equatable {
  final String providerId;
  final PlanModel? originalPlan;
  final ServiceModel? originalService;

  final DateTime? selectedDate;
  final String? selectedTime;
  final int groupSize;
  final Map<String, bool> selectedAddOns;
  final String? notes;
  final List<AttendeeModel> selectedAttendees;

  final double basePrice;
  final double addOnsPrice;
  final double totalPrice;

  final bool isLoading;
  final String? errorMessage;
  final bool canConfirm;

  const OptionsConfigurationState({
    required this.providerId,
    this.originalPlan,
    this.originalService,
    this.selectedDate,
    this.selectedTime,
    this.groupSize = 1,
    this.selectedAddOns = const {},
    this.notes,
    this.selectedAttendees = const [],
    this.basePrice = 0.0,
    this.addOnsPrice = 0.0,
    this.totalPrice = 0.0,
    this.isLoading = false,
    this.errorMessage,
    this.canConfirm = false,
  });

  Map<String, dynamic>? get optionsDefinition =>
      originalPlan?.optionsDefinition ?? originalService?.optionsDefinition;

  String get itemName => originalPlan?.name ?? originalService?.name ?? 'Item';
  String get itemId => originalPlan?.id ?? originalService?.id ?? '';

  OptionsConfigurationState copyWith({
    String? providerId,
    PlanModel? originalPlan,
    ServiceModel? originalService,
    DateTime? selectedDate,
    String? selectedTime,
    int? groupSize,
    Map<String, bool>? selectedAddOns,
    String? notes,
    List<AttendeeModel>? selectedAttendees,
    double? basePrice,
    double? addOnsPrice,
    double? totalPrice,
    bool? isLoading,
    String? errorMessage,
    bool? clearErrorMessage,
    bool? canConfirm,
  }) {
    return OptionsConfigurationState(
      providerId: providerId ?? this.providerId,
      originalPlan: originalPlan ?? this.originalPlan,
      originalService: originalService ?? this.originalService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      groupSize: groupSize ?? this.groupSize,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      notes: notes ?? this.notes,
      selectedAttendees: selectedAttendees ?? this.selectedAttendees,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: (clearErrorMessage == true)
          ? null
          : (errorMessage ?? this.errorMessage),
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
        groupSize,
        selectedAddOns,
        notes,
        selectedAttendees,
        basePrice,
        addOnsPrice,
        totalPrice,
        isLoading,
        errorMessage,
        canConfirm,
      ];
}

class OptionsConfigurationConfirmed extends OptionsConfigurationState {
  final String confirmationId;

  const OptionsConfigurationConfirmed({
    required super.providerId,
    super.originalPlan,
    super.originalService,
    super.selectedDate,
    super.selectedTime,
    required super.groupSize,
    required super.selectedAddOns,
    super.notes,
    required super.selectedAttendees,
    required super.basePrice,
    required super.addOnsPrice,
    required super.totalPrice,
    required this.confirmationId,
  }) : super(canConfirm: true, isLoading: false);

  @override
  List<Object?> get props => [...super.props, confirmationId];
}

class OptionsConfigurationInitial extends OptionsConfigurationState {
  OptionsConfigurationInitial()
      : super(
            providerId: '',
            isLoading: true,
            basePrice: 0.0,
            addOnsPrice: 0.0,
            totalPrice: 0.0);
}
