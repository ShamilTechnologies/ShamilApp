// lib/feature/details/widgets/dynamic_reservation_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
// Import the swipe selector widget
import 'package:shamil_mobile_app/feature/details/widgets/time_slot_swipe_selector.dart';

/// Builds the specific form fields based on the selected reservation type.
/// Reads data from the passed [ReservationState].
class DynamicReservationForm extends StatelessWidget {
  final ThemeData theme;
  final ServiceProviderModel provider;
  final ReservationState state; // Accept the full state object
  final bool isLoading; // General loading state for the whole panel
  // *** CORRECTED: Accept the boolean passed from parent ***
  final bool slotsCurrentlyLoading;
  final ReservationType type; // The currently selected reservation type
  // Callback function invoked when a time range is selected via the swipe selector.
  final Function(TimeOfDay start, TimeOfDay end) onTimeRangeSelected;

  const DynamicReservationForm({
    super.key,
    required this.theme,
    required this.provider,
    required this.state, // Accept state
    required this.isLoading,
    required this.slotsCurrentlyLoading, // Accept the boolean
    required this.type,
    required this.onTimeRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get common data directly from the state object or provider
    final allServices = provider.bookableServices;
    final bool dateSelected = state.selectedDate != null;
    // Use the passed boolean directly
    final bool slotsLoading = slotsCurrentlyLoading;
    final List<TimeOfDay> availableSlots = state.availableSlots;
    final TimeOfDay? confirmedStartTime = state.selectedStartTime;
    final TimeOfDay? confirmedEndTime = state.selectedEndTime;

    // Determine default duration for time-based
    final int timeBasedDefaultDuration = state.selectedService?.durationMinutes ??
        provider.bookableServices
            .firstWhere((s) => s.type == ReservationType.timeBased && s.durationMinutes != null && s.durationMinutes! > 0,
                orElse: () => provider.bookableServices.firstWhere((s) => s.durationMinutes != null && s.durationMinutes! > 0,
                    orElse: () => const BookableService(id: '_default', name: '', description: '', type: ReservationType.unknown, durationMinutes: 60)
                )
            )
            .durationMinutes ??
        60;

    // Use a switch to render the correct UI elements based on the selected reservation type
    switch (type) {
      // --- Time-Based Reservation Form ---
      case ReservationType.timeBased:
        final timeBasedServices = allServices.where((s) => s.type == ReservationType.timeBased || s.durationMinutes != null).toList();
        final String dateStepNumber = timeBasedServices.isNotEmpty ? "3" : "2";
        final String timeStepNumber = timeBasedServices.isNotEmpty ? "4" : "3";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional Service Selection
            if (timeBasedServices.isNotEmpty) ...[
              Text("2. Select Service (Optional):", style: _sectionTitleStyle(theme)),
              const Gap(8),
              DropdownButtonFormField<BookableService?>(
                value: state.selectedService,
                hint: Text("General Time Slot ($timeBasedDefaultDuration min)"),
                isExpanded: true,
                style: theme.textTheme.bodyLarge?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme, hint: "Select a specific service or use general booking"),
                items: [
                  DropdownMenuItem<BookableService?>( value: null, child: Text("General Time Slot ($timeBasedDefaultDuration min)") ),
                  ...timeBasedServices.map((s) => DropdownMenuItem<BookableService>( value: s, child: Text("${s.name} (${s.durationMinutes ?? 'N/A'} min)", overflow: TextOverflow.ellipsis) ))
                ],
                onChanged: isLoading ? null : (BookableService? selectedService) {
                    context.read<ReservationBloc>().add(SelectReservationService(selectedService: selectedService));
                },
              ),
              const Gap(20),
            ],

            // Date Selection
            Text("$dateStepNumber. Select Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            // Pass the boolean down
            _buildDatePickerTile(context, theme, state, isLoading, slotsLoading),
            const Gap(20),

            // Time Slot Swipe Selection
            if (dateSelected) ...[
              Text("$timeStepNumber. Select Time Range (Swipe):", style: _sectionTitleStyle(theme)),
              const Gap(12),
              // Use the boolean here
              if (slotsLoading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30.0), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (availableSlots.isEmpty)
                _buildEmptyState("No available slots found for this date.", theme)
              else
                TimeSlotSwipeSelector(
                  availableSlots: availableSlots,
                  confirmedStartTime: confirmedStartTime,
                  confirmedEndTime: confirmedEndTime,
                  serviceDurationMinutes: state.selectedService?.durationMinutes ?? timeBasedDefaultDuration,
                  onRangeSelected: onTimeRangeSelected,
                ),
            ],
          ],
        );

      // --- Service-Based Reservation Form ---
      case ReservationType.serviceBased:
        final serviceBasedServices = allServices.where((s) => s.type == ReservationType.serviceBased).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Service:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            if (serviceBasedServices.isEmpty)
              _buildEmptyState("No specific services available for booking.", theme)
            else
              DropdownButtonFormField<BookableService>(
                value: state.selectedService,
                hint: const Text("Choose a service..."),
                isExpanded: true,
                style: theme.textTheme.bodyLarge?.copyWith(overflow: TextOverflow.ellipsis),
                decoration: _inputDecoration(theme, hint: "Select the service you want to book"),
                items: serviceBasedServices.map((s) => DropdownMenuItem( value: s, child: Text("${s.name} - EGP ${s.price?.toStringAsFixed(0) ?? 'N/A'}", overflow: TextOverflow.ellipsis,) )).toList(),
                onChanged: isLoading ? null : (s) {
                    if (s != null) context.read<ReservationBloc>().add(SelectReservationService(selectedService: s));
                  },
                validator: (v) => v == null ? 'Please select a service' : null,
              ),
          ],
        );

      // --- Seat-Based Reservation Form (Placeholder UI) ---
      case ReservationType.seatBased:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            // Pass the boolean down
            _buildDatePickerTile(context, theme, state, isLoading, slotsLoading),
            const Gap(20),
            Text("3. Select Seat:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            Container( height: 150, width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration( color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.event_seat_outlined, size: 40, color: Colors.grey.shade600), const Gap(8), Text("Seat Map / Selection UI\n(Requires Integration)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)), ], ),
            ),
          ],
        );

      // --- Access-Based Reservation Form ---
      case ReservationType.accessBased:
        final accessOptions = provider.accessOptions ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. Select Access Pass:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            if (accessOptions.isEmpty)
              _buildEmptyState("No access options defined by provider.", theme)
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                 hint: const Text("Choose access duration..."), isExpanded: true,
                 style: theme.textTheme.bodyLarge?.copyWith(overflow: TextOverflow.ellipsis),
                 decoration: _inputDecoration(theme, hint: "Select the desired access pass"),
                 items: accessOptions.map((opt) => DropdownMenuItem( value: opt, child: Text("${opt['label']} - EGP ${opt['price']?.toStringAsFixed(0) ?? 'N/A'}", overflow: TextOverflow.ellipsis,), )).toList(),
                 onChanged: isLoading ? null : (value) { /* TODO: Dispatch event */ },
                 validator: (v) => v == null ? 'Please select an access pass' : null,
              ),
            const Gap(20),
            Text("3. Select Start Date:", style: _sectionTitleStyle(theme)),
            const Gap(8),
            // Pass the boolean down
            _buildDatePickerTile(context, theme, state, isLoading, slotsLoading),
          ],
        );

      // --- Fallback for Unhandled Types ---
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text( "Configuration for '${type.displayString}' reservations is not yet available.", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800)),
        );
    }
  }

  /// Helper widget to build the Date Picker ListTile consistently.
  // *** Accepts the specific boolean ***
  Widget _buildDatePickerTile(BuildContext context, ThemeData theme, ReservationState state, bool isLoading, bool slotsCurrentlyLoading) {
     final bool dateSelected = state.selectedDate != null;

     return Card(
       elevation: 1, margin: EdgeInsets.zero,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       clipBehavior: Clip.antiAlias,
       child: ListTile(
         enabled: !isLoading,
         leading: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.secondary),
         title: Text( dateSelected ? DateFormat('EEE, MMM d, yyyy').format(state.selectedDate!) : "Select a date", style: dateSelected ? theme.textTheme.bodyLarge : theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor), ),
         // *** Uses the passed boolean ***
         trailing: slotsCurrentlyLoading
             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
             : Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.secondary),
         onTap: !isLoading ? () async {
               final picked = await showDatePicker(
                 context: context, initialDate: state.selectedDate ?? DateTime.now(),
                 firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
                 builder: (context, child) { return Theme( data: theme.copyWith( colorScheme: theme.colorScheme.copyWith( primary: AppColors.primaryColor, onPrimary: Colors.white, ), textButtonTheme: TextButtonThemeData( style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor), ), ), child: child!, ); },
               );
               if (picked != null) { context.read<ReservationBloc>().add(SelectReservationDate(selectedDate: picked)); }
             } : null,
       ),
     );
   }

   /// Helper to create consistent InputDecoration for dropdowns.
   InputDecoration _inputDecoration(ThemeData theme, {String? hint}) {
      return InputDecoration(
          hintText: hint, hintStyle: theme.inputDecorationTheme.hintStyle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.colorScheme.primary)),
          filled: true, fillColor: theme.inputDecorationTheme.fillColor ?? AppColors.accentColor.withOpacity(0.5),
      );
   }

   /// Helper for consistent section title style.
   TextStyle? _sectionTitleStyle(ThemeData theme) {
      return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
   }

   /// Helper widget for empty states within the form.
   Widget _buildEmptyState(String message, ThemeData theme) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 24.0),
         child: Text( message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary), textAlign: TextAlign.center, ),
       ),
     );
   }
}
