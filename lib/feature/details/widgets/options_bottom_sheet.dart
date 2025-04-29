import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:collection/collection.dart'; // For firstWhereOrNull and other list utils

// Core Utilities
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // For potential feedback

// Data Models
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Blocs, States, and Events
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';

/// Displays subscription plans and/or reservation options in a modal bottom sheet.
/// Interacts with SubscriptionBloc and ReservationBloc.
class OptionsBottomSheetContent extends StatefulWidget {
  final ServiceProviderModel provider;
  final ScrollController
      scrollController; // Passed from DraggableScrollableSheet

  const OptionsBottomSheetContent({
    super.key,
    required this.provider,
    required this.scrollController,
  });

  @override
  State<OptionsBottomSheetContent> createState() =>
      _OptionsBottomSheetContentState();
}

class _OptionsBottomSheetContentState extends State<OptionsBottomSheetContent>
    with SingleTickerProviderStateMixin {
  // TabController only needed for hybrid mode
  TabController? _tabController;
  bool get _isHybrid => widget.provider.pricingModel == PricingModel.hybrid;

  @override
  void initState() {
    super.initState();
    if (_isHybrid) {
      _tabController = TabController(length: 2, vsync: this);
    }
    // Reset Blocs to initial state when the sheet opens
    // Assumes Blocs are provided just above this widget (in _showOptionsBottomSheet)
    try {
      context.read<SubscriptionBloc>().add(ResetSubscriptionFlow());
      context.read<ReservationBloc>().add(ResetReservationFlow());
    } catch (e) {
      print(
          "Error accessing Blocs during initState in OptionsBottomSheetContent: $e");
      // This might happen if the sheet is somehow built without the BlocProviders
      // Consider showing an error or handling gracefully.
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Helper function to convert TimeOfDay to minutes since midnight for sorting/comparison.
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingModel = widget.provider.pricingModel;

    /// Builder function for panel content (Subscription or Reservation).
    Widget buildPanelContent(PricingModel model) {
      if (model == PricingModel.subscription) {
        // Use BlocBuilder to react to SubscriptionBloc state changes
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            // Determine loading state for UI elements
            bool isLoading = state is SubscriptionPaymentProcessing ||
                state is SubscriptionConfirmationLoading;
            return _buildSubscriptionPanel(
                theme, widget.provider, state, isLoading);
          },
        );
      } else if (model == PricingModel.reservation) {
        // Use BlocBuilder to react to ReservationBloc state changes
        return BlocBuilder<ReservationBloc, ReservationState>(
          builder: (context, state) {
            // Determine loading state for UI elements
            bool isLoading = state is ReservationCreating ||
                (state is ReservationDateSelected && state.isLoadingSlots);
            return _buildReservationPanel(
                theme, widget.provider, state, isLoading);
          },
        );
      }
      // Return empty if model is not subscription or reservation
      return const SizedBox.shrink();
    }

    // Main sheet layout structure
    // Use BlocListener to handle side-effects like showing snackbars or closing the sheet
    return BlocListener<ReservationBloc, ReservationState>(
        listener: (context, state) {
          if (state is ReservationSuccess) {
            // Show success message
            showGlobalSnackBar(context, state.message);
            // Close the bottom sheet after a short delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
          }
          // Keep existing error handling if needed, or rely on the panel's error display
          // else if (state is ReservationError) {
          //   showGlobalSnackBar(context, state.message, isError: true);
          // }
        },
        child: Column(
          children: [
            // Drag handle indicator
            Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
            // Provider Name Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                widget.provider.businessName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),

            // Conditional TabBar for Hybrid mode
            if (_isHybrid)
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Subscriptions'),
                  Tab(text: 'Reservations'),
                ],
              ),

            // Content Area (either TabBarView or direct ListView)
            Expanded(
              child: _isHybrid
                  ? TabBarView(
                      controller: _tabController,
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevent swiping between tabs if desired
                      children: [
                        // Subscription Panel in Tab 1
                        // Use a separate ListView for each tab content
                        ListView(
                          // *** Pass the scrollController here for the DraggableScrollableSheet ***
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16.0)
                              .copyWith(top: 20), // Add top padding
                          children: [
                            buildPanelContent(PricingModel.subscription)
                          ],
                        ),
                        // Reservation Panel in Tab 2
                        ListView(
                          // *** Pass the scrollController here for the DraggableScrollableSheet ***
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16.0)
                              .copyWith(top: 20), // Add top padding
                          children: [
                            buildPanelContent(PricingModel.reservation)
                          ],
                        ),
                      ],
                    )
                  : ListView(
                      // Single Mode: Use the scrollController from DraggableScrollableSheet
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(16.0)
                          .copyWith(top: 20), // Add top padding
                      children: [
                        buildPanelContent(pricingModel)
                      ], // Build the relevant panel directly
                    ),
            ),
          ],
        )); // Closing parenthesis and semicolon for the BlocListener
  }

  // --- Subscription Panel Widget ---
  Widget _buildSubscriptionPanel(ThemeData theme, ServiceProviderModel provider,
      SubscriptionState state, bool isLoading) {
    final plans = provider.subscriptionPlans;
    // Determine the currently selected plan from the Bloc state
    SubscriptionPlan? selectedPlan = switch (state) {
      SubscriptionPlanSelected(plan: final p) => p,
      SubscriptionPaymentProcessing(plan: final p) => p,
      SubscriptionConfirmationLoading(plan: final p) => p,
      SubscriptionError(plan: final p) => p, // Keep plan context on error
      _ => null, // No plan selected in other states
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title only needed if not in hybrid mode
        if (!_isHybrid)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Subscription Plans",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),

        // Handle empty plans list
        if (plans.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text("No subscription plans available."),
          ))
        else
          // Build list of plan cards
          ListView.builder(
            shrinkWrap: true, // Important inside Column/ListView
            physics:
                const NeverScrollableScrollPhysics(), // Disable nested scrolling
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final isSelected = selectedPlan?.id == plan.id;
              final intervalStr =
                  "${plan.intervalCount > 1 ? '${plan.intervalCount} ' : ''}${plan.interval.name}${plan.intervalCount > 1 ? 's' : ''}";

              // Card for each subscription plan
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: isSelected ? 3.0 : 1.5,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      // Highlight border if selected
                      side: isSelected
                          ? BorderSide(
                              color: theme.colorScheme.primary, width: 1.5)
                          : BorderSide.none),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // Make card tappable to select plan
                    onTap: isLoading
                        ? null
                        : () {
                            // Dispatch event to select this plan
                            context.read<SubscriptionBloc>().add(
                                SelectSubscriptionPlan(selectedPlan: plan));
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan Name and Price/Interval
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    const Gap(6),
                                    Text(plan.description,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              const Gap(12),
                              Column(
                                children: [
                                  Text("EGP ${plan.price.toStringAsFixed(0)}",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.primary)),
                                  Text("/ $intervalStr",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: Colors.grey.shade600)),
                                ],
                              ),
                            ],
                          ),
                          // Display features if any
                          if (plan.features.isNotEmpty) ...[
                            const Gap(10),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: plan.features
                                  .map((feature) => Chip(
                                        label: Text(feature),
                                        labelStyle: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: AppColors.primaryColor),
                                        backgroundColor: AppColors.primaryColor
                                            .withOpacity(0.1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        visualDensity: VisualDensity.compact,
                                        side: BorderSide.none,
                                      ))
                                  .toList(),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        const Gap(24),
        // Purchase Button
        Center(
          child: CustomButton(
            text: isLoading ? 'Processing...' : 'Proceed to Payment',
            // Enable button only if a plan is selected and not currently loading
            onPressed: (selectedPlan == null || isLoading)
                ? null
                : () {
                    // Dispatch event to start payment flow
                    context
                        .read<SubscriptionBloc>()
                        .add(const InitiateSubscriptionPayment());
                  },
          ),
        ),
        // Display error messages from the Bloc state
        if (state is SubscriptionError)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red))),
          ),
        const Gap(20), // Bottom padding
      ],
    );
  }

  // --- Reservation Panel Widget ---
  Widget _buildReservationPanel(ThemeData theme, ServiceProviderModel provider,
      ReservationState state, bool isLoading) {
    final services = provider.bookableServices;
    // Determine state flags for enabling/disabling UI elements
    final bool serviceSelected = state.selectedService != null;
    final bool dateSelected = state.selectedDate != null;

    // *** FIX START: Safely access availableSlots only when state allows ***
    List<TimeOfDay> availableSlots = [];
    bool slotsLoading = false;
    if (state is ReservationDateSelected) {
      availableSlots = state.availableSlots;
      slotsLoading = state.isLoadingSlots;
    } else if (state is ReservationSlotsSelected) {
      availableSlots = state.availableSlots;
      slotsLoading = false; // Slots are loaded if we are in this state
    }
    // *** FIX END ***

    final List<TimeOfDay> currentSelection = state.selectedSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title only needed if not in hybrid mode
        if (!_isHybrid)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Book a Slot",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),

        // 1. Service Selection Dropdown
        if (services.isNotEmpty) ...[
          Text("1. Select Service:", style: theme.textTheme.titleMedium),
          const Gap(8),
          DropdownButtonFormField<BookableService>(
            value: state.selectedService, // Controlled by Bloc state
            hint: const Text("Choose a service..."),
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor ??
                  AppColors.accentColor.withOpacity(0.5),
            ),
            items: services
                .map((service) => DropdownMenuItem(
                      value: service,
                      // Display service name, duration, and price
                      child: Text(
                          "${service.name} (${service.durationMinutes} min) - EGP ${service.price.toStringAsFixed(0)}"),
                    ))
                .toList(),
            onChanged: isLoading // Disable if overall reservation is loading
                ? null
                : (service) {
                    // Dispatch event on change
                    if (service != null) {
                      context.read<ReservationBloc>().add(
                          SelectReservationService(selectedService: service));
                    }
                  },
            validator: (value) =>
                value == null ? 'Please select a service' : null,
          ),
          const Gap(20),
        ] else ...[
          // Show message if no bookable services exist
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text("No bookable services available."),
          ))
        ],

        // 2. Date Selection Tile
        Text("2. Select Date:", style: theme.textTheme.titleMedium),
        const Gap(8),
        Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            enabled: serviceSelected &&
                !isLoading, // Enable only if service selected & not loading
            leading: Icon(Icons.calendar_today,
                color: serviceSelected ? AppColors.primaryColor : Colors.grey),
            title: Text(dateSelected
                ? DateFormat('EEE, MMM d, yyyy').format(state.selectedDate!)
                : "Select a date"),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: (serviceSelected && !isLoading)
                ? () async {
                    final initial = state.selectedDate ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context, initialDate: initial,
                      firstDate:
                          DateTime.now(), // Allow booking from today onwards
                      lastDate: DateTime.now()
                          .add(const Duration(days: 60)), // Limit booking range
                      builder: (context, child) => Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme
                              .copyWith(primary: AppColors.primaryColor),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      // Dispatch event with selected date
                      context
                          .read<ReservationBloc>()
                          .add(SelectReservationDate(selectedDate: picked));
                    }
                  }
                : null,
          ),
        ),

        // 3. Time Slot Selection Section (Conditional)
        // Only show if date is selected AND we are not in the final creating state
        if (dateSelected && state is! ReservationCreating) ...[
          Text("3. Select Time Slot(s):", style: theme.textTheme.titleMedium),
          const Gap(12),
          // Use the time slot builder widget, passing the safely accessed slots/loading state
          _buildTimeSlotSection(theme, state, availableSlots, slotsLoading),
          const Gap(32),
        ],

        // Display Reservation Errors
        if (state is ReservationError)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
            child: Center(
                child: Text(state.message,
                    style: const TextStyle(color: Colors.red))),
          ),

        // 4. Confirmation Button
        Center(
          child: CustomButton(
            text: state is ReservationCreating
                ? 'Booking...'
                : 'Confirm Reservation',
            // Enable only when slots are selected and not loading/creating
            onPressed: (currentSelection.isEmpty || isLoading)
                ? null
                : () {
                    final providerId = widget.provider.id;
                    // Ensure all required data is present in the state before dispatching
                    if (state.selectedService != null &&
                        state.selectedDate != null) {
                      context.read<ReservationBloc>().add(CreateReservation(
                            providerId: providerId,
                            service: state.selectedService!,
                            date: state.selectedDate!,
                            // Bloc reads selectedSlots from its state
                          ));
                    } else {
                      showGlobalSnackBar(
                          context, "Error: Missing service or date.",
                          isError: true);
                    }
                  },
          ),
        ),
        const Gap(20), // Bottom padding
      ],
    );
  }

  /// Builds the time slot selection area using FilterChips for multi-select.
  Widget _buildTimeSlotSection(ThemeData theme, ReservationState state,
      List<TimeOfDay> availableSlots, bool isLoading) {
    // Show loading indicator while fetching slots
    if (isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    // Show message if date is selected but no slots were found
    if (!isLoading && availableSlots.isEmpty && state.selectedDate != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text("No available slots found for this date.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.orange.shade800))));
    }
    // Don't show anything if date isn't selected yet or slots haven't loaded
    if (availableSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the currently selected slots from the Bloc state
    final List<TimeOfDay> selectedSlots = state.selectedSlots;

    // --- TODO: Implement Swipe-to-Select Gesture Logic Here ---
    // Wrap the 'Wrap' widget below with GestureDetector and implement handlers.
    // Update the appearance of FilterChips based on temporary swipe state.
    // Dispatch UpdateSlotSelection from onPanEnd.
    // --- End TODO ---

    // --- Current FilterChip Implementation (Tap Multi-Select) ---
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.start, // Align chips to the start
      children: availableSlots.map((time) {
        // Determine if this specific time slot is currently selected
        final isSelected = selectedSlots.contains(time);

        // Create a FilterChip for each available time slot
        return FilterChip(
          label: Text(time.format(context)), // Format TimeOfDay to string
          selected: isSelected,
          showCheckmark: false, // Don't show the default checkmark
          labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.white
                  : theme.textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          selectedColor: AppColors.primaryColor, // Background when selected
          backgroundColor: AppColors.primaryColor
              .withOpacity(0.1), // Background when not selected
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade300,
                  width: 1)),
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
          onSelected: (bool _) {
            // The boolean parameter indicates the NEW state if toggled
            // Create a mutable copy of the current selection
            final newSelection = List<TimeOfDay>.from(selectedSlots);
            if (isSelected) {
              // If it was already selected, remove it
              newSelection.remove(time);
            } else {
              // If it was not selected, add it
              newSelection.add(time);
            }
            // Dispatch event to the Bloc to update the selection
            // The Bloc will handle validation (like consecutiveness)
            context
                .read<ReservationBloc>()
                .add(UpdateSlotSelection(newlySelectedSlots: newSelection));
          },
        );
      }).toList(),
    );
    // --- End FilterChip Implementation ---
  }
}
