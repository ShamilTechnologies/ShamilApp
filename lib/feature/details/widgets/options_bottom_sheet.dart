import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors
import 'package:shamil_mobile_app/core/widgets/custom_button.dart'; // For CustomButton
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
// *** Import the DETAILED ServiceProviderModel ***
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
// *** Import BookableService - Ensure this path is correct ***

/// A stateful widget that displays the content for the service provider options bottom sheet.
///
/// It dynamically shows subscription plans, reservation options, or both (in tabs)
/// based on the provider's `pricingModel`. Manages its own TabController if needed.
class OptionsBottomSheetContent extends StatefulWidget {
  // Use the detailed ServiceProviderModel
  final ServiceProviderModel provider;
  final ScrollController
      scrollController; // Controller from DraggableScrollableSheet

  const OptionsBottomSheetContent({
    super.key,
    required this.provider,
    required this.scrollController,
    // Removed tabController parameter
  });

  @override
  State<OptionsBottomSheetContent> createState() =>
      _OptionsBottomSheetContentState();
}

// Add SingleTickerProviderStateMixin for TabController
class _OptionsBottomSheetContentState extends State<OptionsBottomSheetContent>
    with SingleTickerProviderStateMixin {
  // --- State for Reservation Panel ---
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  BookableService? _selectedService;
  // --- End Reservation State ---

  // --- TabController for Hybrid Mode ---
  TabController? _tabController;
  // Determine if hybrid based on the widget's provider data
  bool get _isHybrid => widget.provider.pricingModel == PricingModel.hybrid;

  @override
  void initState() {
    super.initState();
    // Initialize TabController only if it's hybrid mode
    if (_isHybrid) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Dispose controller if created
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingModel = widget.provider.pricingModel;

    // Build the main content structure (Column containing panels)
    Widget buildPanelContent(PricingModel model) {
      if (model == PricingModel.subscription) {
        return _buildSubscriptionPanel(theme, widget.provider);
      } else if (model == PricingModel.reservation) {
        return _buildReservationPanel(theme, widget.provider);
      } else {
        // This case should ideally not be reached directly in this build logic
        // as hybrid is handled separately, but return empty for safety.
        return const SizedBox.shrink();
      }
    }

    // Determine overall structure based on pricing model
    if (_isHybrid) {
      // Use Column + TabBar + Expanded(TabBarView) for hybrid
      // The DraggableScrollableSheet's scrollController handles the outer scroll
      return Column(
        children: [
          TabBar(
            // TabBar needs the controller
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Subscriptions'),
              Tab(text: 'Reservations'),
            ],
          ),
          Expanded(
            // TabBarView needs to be Expanded within the Column
            child: TabBarView(
              controller: _tabController, // Use the state's controller
              children: [
                // Each tab's content needs its own scrolling mechanism
                // Use ListView and pass the DRAGGABLE SHEET's controller
                ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16.0).copyWith(top: 8),
                  children: [_buildSubscriptionPanel(theme, widget.provider)],
                ),
                ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16.0).copyWith(top: 8),
                  children: [_buildReservationPanel(theme, widget.provider)],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // For single mode, use ListView with the sheet's controller
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16.0).copyWith(top: 16),
        children: [buildPanelContent(pricingModel)], // Build the relevant panel
      );
    }
  } // End of build method

  // --- Panels for Bottom Sheet Content ---

  /// Builds the UI for displaying subscription plans.
  Widget _buildSubscriptionPanel(
      ThemeData theme, ServiceProviderModel provider) {
    final plans = provider.subscriptionPlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important for Column inside ListView
      children: [
        // No Title needed here as it's handled by Tab or single panel context

        if (plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
                child: Text("No subscription plans available.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey))),
          )
        else
          Column(
            children: plans.map((plan) {
              final intervalStr =
                  "${plan.intervalCount > 1 ? '${plan.intervalCount} ' : ''}${plan.interval.name}${plan.intervalCount > 1 ? 's' : ''}";
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: 1.5,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
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
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  print(
                                      "Selected Plan: ${plan.name} (ID: ${plan.id})");
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "EGP ${plan.price.toStringAsFixed(0)} / $intervalStr",
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                )),
                          ],
                        ),
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
              );
            }).toList(),
          ),
        const Gap(20),
      ],
    );
  }

  /// Builds the UI for making reservations.
  Widget _buildReservationPanel(
      ThemeData theme, ServiceProviderModel provider) {
    final services = provider.bookableServices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important for Column inside ListView
      children: [
        // No Title needed here as it's handled by Tab or single panel context

        if (services.isNotEmpty) ...[
          Text("Select Service/Class:", style: theme.textTheme.titleMedium),
          const Gap(8),
          DropdownButtonFormField<BookableService>(
            value: _selectedService,
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
                      child: Text(
                          "${service.name} (${service.durationMinutes} min) - EGP ${service.price.toStringAsFixed(0)}"),
                    ))
                .toList(),
            onChanged: (service) {
              setState(() {
                _selectedService = service;
                _selectedTime = null;
                print("Selected service: ${_selectedService?.name}");
              });
            },
            validator: (value) =>
                value == null ? 'Please select a service' : null,
          ),
          const Gap(20),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text("No bookable services available.",
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          ),
        ],

        if (services.isNotEmpty) ...[
          Text("Select Date:", style: theme.textTheme.titleMedium),
          const Gap(8),
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              enabled: _selectedService != null,
              leading: Icon(Icons.calendar_today,
                  color: _selectedService != null
                      ? AppColors.primaryColor
                      : Colors.grey),
              title: Text(DateFormat('EEE, MMM d, EEEE').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectedService == null
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        selectableDayPredicate: (DateTime day) => true,
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme
                                  .copyWith(primary: AppColors.primaryColor),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                          _selectedTime = null;
                        });
                        print(
                            "Date selected: $_selectedDate for service: ${_selectedService?.name}");
                      }
                    },
            ),
          ),
          Text("Available Time Slots:", style: theme.textTheme.titleMedium),
          const Gap(12),
          _buildTimeSlotSection(theme, _selectedService?.durationMinutes),
          const Gap(32),
          Center(
            child: CustomButton(
              text: "Confirm Reservation",
              onPressed: _selectedService == null || _selectedTime == null
                  ? null
                  : () {
                      print(
                          "Confirming reservation for service '${_selectedService?.name}' (ID: ${_selectedService?.id}) on $_selectedDate at $_selectedTime");
                      Navigator.pop(context);
                    },
            ),
          ),
          const Gap(20),
        ],
      ],
    );
  }

  /// Helper widget to build the time slot selection area.
  Widget _buildTimeSlotSection(ThemeData theme, int? serviceDurationMinutes) {
    bool enabled = _selectedService != null;
    List<TimeOfDay> exampleSlots = [];
    if (enabled && serviceDurationMinutes != null) {
      TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
      TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
      TimeOfDay currentTime = startTime;
      while (currentTime.hour < endTime.hour ||
          (currentTime.hour == endTime.hour &&
              currentTime.minute < endTime.minute)) {
        exampleSlots.add(currentTime);
        final totalMinutes =
            currentTime.hour * 60 + currentTime.minute + serviceDurationMinutes;
        currentTime =
            TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
        if (serviceDurationMinutes <= 0 || currentTime.hour > endTime.hour)
          break;
      }
    }
    if (!enabled) {
      return Text("Please select a service and date first.",
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey));
    }
    if (exampleSlots.isEmpty) {
      return Text("No available slots found for the selected date/service.",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange));
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: exampleSlots.map((time) {
        final isSelected = _selectedTime == time;
        return ChoiceChip(
          label: Text(time.format(context)),
          selected: isSelected,
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.primaryColor
                  : theme.textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: (bool selected) {
            setState(() {
              _selectedTime = selected ? time : null;
            });
            print("Time slot ${time.format(context)} selected: $selected");
          },
        );
      }).toList(),
    );
  }
} // End of _OptionsBottomSheetContentState
