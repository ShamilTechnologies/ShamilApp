// lib/feature/details/widgets/dynamic_reservation_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors
import 'package:shamil_mobile_app/core/widgets/custom_button.dart'; // For CustomButton in queue section

// Import UPDATED Models
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // Includes AccessPassOption, OpeningHoursDay

// Import Reservation Bloc & State
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart'; // Imports State and Event too

// Import ReservationType enum and its extension
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';

// Import the swipe selector widget
import 'package:shamil_mobile_app/feature/details/widgets/time_slot_swipe_selector.dart';

/// Builds the specific form fields based on the selected reservation type.
/// Reads data from the passed [ReservationState] including the provider configuration.
class DynamicReservationForm extends StatelessWidget {
  final ThemeData theme;
  final ReservationState state; // Accept the full state object
  final bool isLoading; // General loading flag from parent (passed from ReservationPanel)
  final bool slotsCurrentlyLoading; // Specific flag for slot loading (time-based)
  final ReservationType type; // The currently selected reservation type
  final Function(TimeOfDay start, TimeOfDay end) onTimeRangeSelected; // Callback for swipe selector

  const DynamicReservationForm({
    super.key,
    required this.theme,
    required this.state,
    required this.isLoading,
    required this.slotsCurrentlyLoading,
    required this.type,
    required this.onTimeRangeSelected,
  });

  // Helper to get default duration for time-based, using provider config
  int _getTimeBasedDefaultDuration(ServiceProviderModel provider) {
    // 1. Check selected service first (if any)
    if (state.selectedService?.durationMinutes != null &&
        state.selectedService!.durationMinutes! > 0) {
      return state.selectedService!.durationMinutes!;
    }
    // 2. Check provider's specific config for timeBased
    final timeBasedConfig = provider.reservationTypeConfigs?['timeBased'];
    if (timeBasedConfig is Map &&
        timeBasedConfig['defaultDurationMinutes'] is int) {
      return timeBasedConfig['defaultDurationMinutes'];
    }
    // 3. Fallback: check first valid bookable service of type timeBased or group
    // Ensure there's a null check before accessing properties on the result of firstWhere
    final BookableService? firstTimeBasedService = provider.bookableServices
        .firstWhere(
            (s) =>
                (s.type == ReservationType.timeBased ||
                    s.type == ReservationType.group) &&
                s.durationMinutes != null &&
                s.durationMinutes! > 0,
            orElse: () => const BookableService( // This orElse provides a non-null default
                id: '_fallback_no_time_service',
                name: '',
                description: '',
                type: ReservationType.unknown,
                durationMinutes: 60)
            );

    // Since orElse guarantees a non-null BookableService, we can safely access durationMinutes.
    // However, the const BookableService in orElse has durationMinutes: 60.
    // If the intention is to return the found service's duration or 60 if nothing is found,
    // the logic can be simplified or made more explicit.
    if (firstTimeBasedService != null && firstTimeBasedService.id != '_fallback_no_time_service' && firstTimeBasedService.durationMinutes != null) {
         return firstTimeBasedService.durationMinutes!;
    }


    // 4. Absolute fallback if no other duration is found
    return 60;
  }

  // Helper to generate hourly slots based on opening hours for a given date
  List<TimeOfDay> _getHourlySlotsForDate(
      DateTime date, Map<String, OpeningHoursDay> openingHours) {
    final List<TimeOfDay> slots = [];
    final String dayOfWeek =
        DateFormat('EEEE').format(date).toLowerCase(); // e.g., 'monday'
    final OpeningHoursDay? hoursForDay = openingHours[dayOfWeek];

    if (hoursForDay != null &&
        hoursForDay.isOpen &&
        hoursForDay.startTime != null &&
        hoursForDay.endTime != null) {
      TimeOfDay currentTime = hoursForDay.startTime!;
      final TimeOfDay endTime = hoursForDay.endTime!;
      final DateTime now = DateTime.now();
      // Compare date part only for "isToday" check
      final DateTime selectedDateOnly =
          DateTime(date.year, date.month, date.day);
      final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);

      bool isToday = selectedDateOnly.isAtSameMomentAs(todayDateOnly);

      while (true) {
        final DateTime currentSlotStartDateTime = DateTime(date.year,
            date.month, date.day, currentTime.hour, currentTime.minute);
        final DateTime providerCloseDateTime = DateTime(
            date.year, date.month, date.day, endTime.hour, endTime.minute);

        // Break if current slot start time is at or after the provider's closing time
        if (currentSlotStartDateTime.isAtSameMomentAs(providerCloseDateTime) ||
            currentSlotStartDateTime.isAfter(providerCloseDateTime)) {
          break;
        }

        // If it's today, only add slots where the start time is in the future
        if (!isToday || currentSlotStartDateTime.isAfter(now)) {
          slots.add(currentTime);
        }

        // Move to the next hour
        int nextHour = currentTime.hour + 1;
        if (nextHour >= 24) break; // Stop if we go past midnight
        currentTime = TimeOfDay(hour: nextHour, minute: 0);
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    // Get provider configuration FROM THE STATE
    final currentProvider = state.provider;
    if (currentProvider == null) {
      // Handle case where provider is unexpectedly null in the state
      print("Error: Provider data missing in DynamicReservationForm state.");
      return _buildEmptyState("Error loading provider configuration.", theme);
    }

    // Get common data directly from the state object or derived from provider
    final allServices = currentProvider.bookableServices;
    final accessOptions = currentProvider.accessOptions ?? [];
    final bool dateSelected = state.selectedDate != null;
    final bool slotsLoading =
        slotsCurrentlyLoading; // Use flag passed from parent
    final List<TimeOfDay> availableSlots =
        state.availableSlots; // For time-based
    final TimeOfDay? preferredHour =
        state.selectedStartTime; // Used for sequence-based preferred hour
    final TimeOfDay? confirmedEndTime =
        state.selectedEndTime; // For time-based
    final bool isActionLoading =
        state is ReservationJoiningQueue || state is ReservationCreating;
    // Disable interactions if parent is loading OR a specific action is loading
    final bool disableInteractions = isLoading || isActionLoading;

    switch (type) {
      // --- Time-Based Reservation Form ---
      case ReservationType.timeBased:
        final timeBasedServices = allServices
            .where((s) =>
                s.type == ReservationType.timeBased || s.durationMinutes != null)
            .toList();
        final defaultDuration = _getTimeBasedDefaultDuration(currentProvider);
        final String dateStepNumber =
            timeBasedServices.isNotEmpty ? "3" : "2";
        final String timeStepNumber =
            timeBasedServices.isNotEmpty ? "4" : "3";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional Service Selection
            if (timeBasedServices.isNotEmpty) ...[
              Text("2. Select Service (Optional):",
                  style: _sectionTitleStyle(theme)),
              const Gap(8),
              DropdownButtonFormField<BookableService?>(
                value: state.selectedService,
                hint: Text("General Time Slot ($defaultDuration min)"),
                isExpanded: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme,
                    hint:
                        "Select a specific service or use general booking"),
                items: [
                  DropdownMenuItem<BookableService?>(
                      value: null,
                      child: Text("General Time Slot ($defaultDuration min)")),
                  ...timeBasedServices.map((s) =>
                      DropdownMenuItem<BookableService>(
                          value: s,
                          child: Text(
                              "${s.name} (${s.durationMinutes ?? 'N/A'} min)",
                              overflow: TextOverflow.ellipsis)))
                ],
                onChanged: disableInteractions
                    ? null
                    : (BookableService? selectedService) {
                        context.read<ReservationBloc>().add(
                            SelectReservationService(
                                selectedService: selectedService));
                      },
              ),
              const Gap(20),
            ],

            // Date Selection
            Text("$dateStepNumber. Select Date:",
                style: _sectionTitleStyle(theme)),
            const Gap(8),
            _buildDatePickerTile(
                context, theme, state, disableInteractions, slotsLoading),
            const Gap(20),

            // Time Slot Swipe Selection
            if (dateSelected) ...[
              Text("$timeStepNumber. Select Time Range (Swipe):",
                  style: _sectionTitleStyle(theme)),
              const Gap(12),
              if (slotsLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (availableSlots.isEmpty)
                _buildEmptyState(
                    "No available slots found for this date.", theme)
              else
                IgnorePointer(
                  ignoring: disableInteractions,
                  child: Opacity(
                    opacity: disableInteractions ? 0.5 : 1.0,
                    child: TimeSlotSwipeSelector(
                      availableSlots: availableSlots,
                      confirmedStartTime: state.selectedStartTime,
                      confirmedEndTime: confirmedEndTime,
                      serviceDurationMinutes:
                          state.selectedService?.durationMinutes ??
                              defaultDuration,
                      onRangeSelected: onTimeRangeSelected,
                    ),
                  ),
                ),
            ],
            const Gap(20),
          ],
        );

      // --- Service-Based Reservation Form ---
      case ReservationType.serviceBased:
        final serviceBasedServices = allServices
            .where((s) => s.type == ReservationType.serviceBased)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Service:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            if (serviceBasedServices.isEmpty)
              _buildEmptyState(
                  "No specific services available for booking.", theme)
            else
              DropdownButtonFormField<BookableService>(
                value: state.selectedService,
                hint: const Text("Choose a service..."),
                isExpanded: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme,
                    hint: "Select the service you want to book"),
                items: serviceBasedServices
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                            "${s.name} - EGP ${s.price?.toStringAsFixed(0) ?? 'N/A'}",
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: disableInteractions
                    ? null
                    : (s) {
                        if (s != null) {
                          context
                              .read<ReservationBloc>()
                              .add(SelectReservationService(selectedService: s));
                        }
                      },
                validator: (v) =>
                    v == null ? 'Please select a service' : null,
              ),
            const Gap(20),
          ],
        );

      // --- Seat-Based Reservation Form ---
      case ReservationType.seatBased:
        final seatBasedServices = allServices
            .where((s) => s.type == ReservationType.seatBased)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (seatBasedServices.isNotEmpty) ...[
              Text("2. Select Event/Showing:",
                  style: _sectionTitleStyle(theme)),
              const Gap(8),
              DropdownButtonFormField<BookableService>(
                value: state.selectedService,
                hint: const Text("Choose an event..."),
                isExpanded: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(overflow: TextOverflow.ellipsis),
                decoration:
                    _inputDecoration(theme, hint: "Select the event"),
                items: seatBasedServices
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child:
                            Text("${s.name} (${s.durationMinutes ?? 'N/A'} min)")))
                    .toList(),
                onChanged: disableInteractions
                    ? null
                    : (s) {
                        if (s != null) {
                          context
                              .read<ReservationBloc>()
                              .add(SelectReservationService(selectedService: s));
                        }
                      },
                validator: (v) =>
                    v == null ? 'Please select an event' : null,
              ),
              const Gap(20),
            ],
            Text("3. Select Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            _buildDatePickerTile(
                context, theme, state, disableInteractions, slotsLoading),
            const Gap(20),
            if (dateSelected && availableSlots.isNotEmpty) ...[
              Text("4. Select Time:", style: _sectionTitleStyle(theme)),
              const Gap(12),
              if (slotsLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))))
              else
                Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableSlots.map((time) {
                      final bool isSelected = state.selectedStartTime == time;
                      return ChoiceChip(
                        label: Text(time.format(context)),
                        selected: isSelected,
                        onSelected: disableInteractions
                            ? null
                            : (sel) {
                                if (sel) {
                                  int duration = state.selectedService
                                          ?.durationMinutes ??
                                      _getTimeBasedDefaultDuration(
                                          currentProvider);
                                  int startMinutes =
                                      time.hour * 60 + time.minute;
                                  int endMinutes = startMinutes + duration;
                                  TimeOfDay endTime = TimeOfDay(
                                      hour: (endMinutes ~/ 60) % 24,
                                      minute: endMinutes % 60);
                                  context.read<ReservationBloc>().add(
                                      UpdateSwipeSelection(
                                          startTime: time, endTime: endTime));
                                }
                              },
                        selectedColor: AppColors.primaryColor,
                        labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor),
                        backgroundColor:
                            AppColors.primaryColor.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade300)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList()),
              const Gap(20),
            ],
            Text("5. Select Seat:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            Container(
              height: 150,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat_outlined,
                      size: 40, color: Colors.grey.shade600),
                  const Gap(8),
                  Text(
                      "Seat Map UI Placeholder\n(URL: ${currentProvider.seatMapUrl ?? 'Not Set'})",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            const Gap(20),
          ],
        );

      // --- Access-Based Reservation Form ---
      case ReservationType.accessBased:
        AccessPassOption? selectedOption;
        if (state.typeSpecificData != null && state.typeSpecificData!['selectedAccessPassId'] != null) {
            selectedOption = accessOptions.firstWhere(
                (opt) => opt.id == state.typeSpecificData!['selectedAccessPassId'],
                orElse: () => AccessPassOption(
                    id: '_default',
                    label: 'Default Access Pass',
                    price: 0.0,
                    durationHours: 0),
            );
        }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Access Pass:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            if (accessOptions.isEmpty)
              _buildEmptyState("No access options defined by provider.", theme)
            else
              DropdownButtonFormField<AccessPassOption>(
                value: selectedOption,
                hint: const Text("Choose access duration..."),
                isExpanded: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme,
                    hint: "Select the desired access pass"),
                items: accessOptions
                    .map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(
                            "${opt.label} - EGP ${opt.price.toStringAsFixed(0)} (${opt.durationHours}h)",
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: disableInteractions
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<ReservationBloc>().add(
                              SelectAccessPassOption(option: value));
                        }
                      },
                validator: (v) =>
                    v == null ? 'Please select an access pass' : null,
              ),
            const Gap(20),
            Text("3. Select Start Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            _buildDatePickerTile(context, theme, state, disableInteractions,
                false), // slotsLoading false for access
            const Gap(20),
          ],
        );

      // --- Sequence-Based Reservation UI ---
      case ReservationType.sequenceBased:
        final sequenceServices = allServices
            .where((s) => s.type == ReservationType.sequenceBased)
            .toList();
        final List<TimeOfDay> hourlySlots = dateSelected
            ? _getHourlySlotsForDate(
                state.selectedDate!, currentProvider.openingHours)
            : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Service:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            if (sequenceServices.isEmpty)
              _buildEmptyState("No queue-based services available.", theme)
            else
              DropdownButtonFormField<BookableService>(
                value: state.selectedService,
                hint: const Text("Choose a service for the queue..."),
                isExpanded: true,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme,
                    hint: "Select the service to queue for"),
                items: sequenceServices
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name,
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: disableInteractions
                    ? null
                    : (s) {
                        if (s != null) {
                          context
                              .read<ReservationBloc>()
                              .add(SelectReservationService(selectedService: s));
                        }
                      },
                validator: (v) =>
                    v == null ? 'Please select a service' : null,
              ),
            const Gap(20),
            Text("3. Select Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            _buildDatePickerTile(context, theme, state, disableInteractions,
                false), // slotsLoading is false
            const Gap(20),
            if (dateSelected) ...[
              Text("4. Select Preferred Hour:",
                  style: _sectionTitleStyle(theme)),
              const Gap(12),
              if (hourlySlots.isEmpty)
                _buildEmptyState(
                    "No available hours found for this date.", theme)
              else
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: hourlySlots.map((time) {
                      final bool isSelected = preferredHour == time;
                      return ChoiceChip(
                        label: Text(DateFormat.jm().format(DateTime(
                            state.selectedDate!.year,
                            state.selectedDate!.month,
                            state.selectedDate!.day,
                            time.hour,
                            time.minute))),
                        selected: isSelected,
                        onSelected: disableInteractions
                            ? null
                            : (selected) {
                                if (selected) {
                                  context.read<ReservationBloc>().add(
                                      SelectSequenceTimeSlot(
                                          preferredHour: time));
                                }
                              },
                        selectedColor: AppColors.primaryColor,
                        labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade300)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        visualDensity: VisualDensity.comfortable,
                      );
                    }).toList(),
                  ),
                ),
              const Gap(24),
            ],
            _buildQueueStatusSection(context, theme, state, disableInteractions),
            const Gap(20),
          ],
        );

      // --- Fallback for Unhandled Types ---
      case ReservationType.recurring:
      case ReservationType.group: // Group might use time-based as a base
      case ReservationType.unknown:
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
              "Booking configuration for '${type.displayString}' is not yet supported in the app.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.orange.shade800)),
        );
    }
  }

  // --- Helper Widgets ---

  Widget _buildDatePickerTile(
      BuildContext context,
      ThemeData theme,
      ReservationState state,
      bool isDisabled,
      bool slotsCurrentlyLoading) {
    final bool dateSelected = state.selectedDate != null;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      color: isDisabled ? Colors.grey.shade200 : null,
      child: ListTile(
        enabled: !isDisabled,
        leading: Icon(Icons.calendar_today_outlined,
            color:
                isDisabled ? Colors.grey.shade500 : theme.colorScheme.secondary),
        title: Text(
          dateSelected
              ? DateFormat('EEE, MMM d, yyyy').format(state.selectedDate!) // Corrected DateFormat
              : "Select a date",
          style: dateSelected
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: isDisabled ? Colors.grey.shade600 : null)
              : theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
        ),
        trailing: (slotsCurrentlyLoading && type == ReservationType.timeBased)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.arrow_drop_down_rounded,
                color: isDisabled
                    ? Colors.grey.shade500
                    : theme.colorScheme.secondary),
        onTap: isDisabled
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: AppColors.primaryColor,
                          onPrimary: Colors.white,
                          onSurface: AppColors.primaryColor,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryColor),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  if (state.selectedReservationType ==
                          ReservationType.sequenceBased &&
                      state.selectedStartTime != null) {
                    context
                        .read<ReservationBloc>()
                        .add(const SelectSequenceTimeSlot(preferredHour: null));
                  }
                  context
                      .read<ReservationBloc>()
                      .add(SelectReservationDate(selectedDate: picked));
                }
              },
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.inputDecorationTheme.hintStyle,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary)),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ??
          AppColors.accentColor.withOpacity(0.5),
    );
  }

  TextStyle? _sectionTitleStyle(ThemeData theme) {
    return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.secondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildQueueStatusSection(BuildContext context, ThemeData theme,
      ReservationState state, bool disableActions) {
    if (state is ReservationJoiningQueue) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    Gap(12),
                    Text("Joining Queue...")
                  ])));
    } else if (state is ReservationInQueue) {
      String estimateText = "Estimating entry time...";
      if (state.estimatedEntryTime != null) {
        estimateText =
            "Estimated Entry: ~${DateFormat.jm().format(state.estimatedEntryTime!)}";
      }
      return Column(
        children: [
          Card(
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: AppColors.accentColor.withOpacity(0.8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.group_work_rounded,
                      color: AppColors.primaryColor, size: 30),
                  const Gap(12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("You're in the Queue!",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor)),
                          const Gap(6),
                          if (state.queuePosition > 0)
                            Text("Your Position: #${state.queuePosition}",
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.secondaryColor)),
                          Text(estimateText,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.secondaryColor)),
                        ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: "Refresh Status",
                    color: AppColors.secondaryColor,
                    onPressed: disableActions
                        ? null
                        : () => context
                            .read<ReservationBloc>()
                            .add(const CheckQueueStatus()),
                  )
                ],
              ),
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text("Leave Queue"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: disableActions
                  ? null
                  : () =>
                      context.read<ReservationBloc>().add(const LeaveQueue()),
            ),
          ),
        ],
      );
    } else if (state is ReservationQueueError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: theme.colorScheme.error.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error, size: 30),
            const Gap(8),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            CustomButton(
              text: "Retry Join",
              onPressed: disableActions
                  ? null
                  : () =>
                      context.read<ReservationBloc>().add(const JoinQueue()),
              color: theme.colorScheme.error,
              height: 44,
              textStyle:
                  theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    } else {
      // Default: Show "Join Queue" button
      final bool canJoin = state.selectedService != null &&
          state.selectedDate != null &&
          state.selectedStartTime !=
              null && // startTime holds preferred hour for sequence
          !disableActions;
      return Center(
        child: CustomButton(
          text: "Join Queue",
          onPressed: canJoin
              ? () => context.read<ReservationBloc>().add(const JoinQueue())
              : null,
          height: 50,
          width: double.infinity,
        ),
      );
    }
  }
}