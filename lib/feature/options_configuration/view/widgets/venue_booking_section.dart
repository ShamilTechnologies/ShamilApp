import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:gap/gap.dart';

class VenueBookingSection extends StatefulWidget {
  final OptionsConfigurationState state;

  const VenueBookingSection({
    super.key,
    required this.state,
  });

  @override
  State<VenueBookingSection> createState() => _VenueBookingSectionState();
}

class _VenueBookingSectionState extends State<VenueBookingSection> {
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize capacity controller if venue booking configuration exists
    if (widget.state.venueBookingConfig != null &&
        widget.state.venueBookingConfig!.selectedCapacity != null) {
      _capacityController.text =
          widget.state.venueBookingConfig!.selectedCapacity.toString();
    }
  }

  @override
  void didUpdateWidget(VenueBookingSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update capacity controller if selectedCapacity changes
    if (widget.state.venueBookingConfig?.selectedCapacity != null &&
        _capacityController.text !=
            widget.state.venueBookingConfig!.selectedCapacity.toString()) {
      _capacityController.text =
          widget.state.venueBookingConfig!.selectedCapacity.toString();
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final venueConfig = widget.state.venueBookingConfig;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Venue Booking Options",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Booking type selection
            _buildBookingTypeSelection(venueConfig),
            const Gap(16),

            // Capacity selector (if partial capacity mode)
            if (venueConfig?.type == VenueBookingType.partialCapacity) ...[
              _buildCapacitySelector(venueConfig!),
              const Gap(16),
            ],

            // Booking privacy
            _buildBookingPrivacyToggle(venueConfig),

            // Capacity visualization
            if (venueConfig != null) ...[
              const Gap(16),
              _buildCapacityVisualization(venueConfig),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTypeSelection(VenueBookingConfig? venueConfig) {
    final currentType = venueConfig?.type ?? VenueBookingType.fullVenue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Booking Type",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        CupertinoSegmentedControl<VenueBookingType>(
          children: const {
            VenueBookingType.fullVenue: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Full Venue'),
            ),
            VenueBookingType.partialCapacity: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Partial Capacity'),
            ),
          },
          groupValue: currentType,
          onValueChanged: (value) {
            context.read<OptionsConfigurationBloc>().add(
                  ChangeVenueBookingType(bookingType: value),
                );

            // When changing to full venue, update groupSize to match maxCapacity
            if (value == VenueBookingType.fullVenue && venueConfig != null) {
              context.read<OptionsConfigurationBloc>().add(
                    QuantityChanged(quantity: venueConfig.maxCapacity),
                  );
            }
            // When changing to partial capacity, update groupSize to match selectedCapacity if available
            else if (value == VenueBookingType.partialCapacity &&
                venueConfig?.selectedCapacity != null) {
              context.read<OptionsConfigurationBloc>().add(
                    QuantityChanged(quantity: venueConfig!.selectedCapacity!),
                  );
            }
          },
          selectedColor: AppColors.primaryColor,
          unselectedColor: Colors.white,
          borderColor: AppColors.primaryColor,
        ),
        const Gap(8),
        // Description of booking type
        Text(
          currentType == VenueBookingType.fullVenue
              ? "Book the entire venue exclusively for your event."
              : "Book specific number of spots at the venue, sharing with others.",
          style: AppTextStyle.getSmallStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySelector(VenueBookingConfig venueConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Number of People",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Enter number of people',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'people',
                ),
                onChanged: (value) {
                  final capacity = int.tryParse(value);
                  if (capacity != null && capacity > 0) {
                    // Update capacity and sync with groupSize
                    context.read<OptionsConfigurationBloc>().add(
                          UpdateSelectedCapacity(capacity: capacity),
                        );
                    // Also update the groupSize to match the capacity
                    context.read<OptionsConfigurationBloc>().add(
                          QuantityChanged(quantity: capacity),
                        );
                  }
                },
              ),
            ),
            const Gap(12),
            Column(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.plus_circle_fill,
                      color: AppColors.primaryColor),
                  onPressed: () {
                    final current = int.tryParse(_capacityController.text) ?? 0;
                    final newValue = current + 1;
                    if (newValue <= venueConfig.maxCapacity) {
                      // Update capacity and sync with groupSize
                      context.read<OptionsConfigurationBloc>().add(
                            UpdateSelectedCapacity(capacity: newValue),
                          );
                      // Also update the groupSize to match the capacity
                      context.read<OptionsConfigurationBloc>().add(
                            QuantityChanged(quantity: newValue),
                          );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.minus_circle_fill,
                      color: AppColors.primaryColor),
                  onPressed: () {
                    final current = int.tryParse(_capacityController.text) ?? 0;
                    final newValue = current - 1;
                    if (newValue > 0) {
                      // Update capacity and sync with groupSize
                      context.read<OptionsConfigurationBloc>().add(
                            UpdateSelectedCapacity(capacity: newValue),
                          );
                      // Also update the groupSize to match the capacity
                      context.read<OptionsConfigurationBloc>().add(
                            QuantityChanged(quantity: newValue),
                          );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const Gap(8),
        Text(
          "Maximum capacity: ${venueConfig.maxCapacity} people",
          style: AppTextStyle.getSmallStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingPrivacyToggle(VenueBookingConfig? venueConfig) {
    final isPrivate = venueConfig?.isPrivateEvent ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Privacy Settings",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Private Event",
            style: AppTextStyle.getTitleStyle(fontSize: 14),
          ),
          subtitle: Text(
            isPrivate
                ? "Only invited attendees can join the event"
                : "Event is visible to the public and can be joined if space available",
            style: AppTextStyle.getSmallStyle(
              color: Colors.grey,
            ),
          ),
          value: isPrivate,
          activeColor: AppColors.primaryColor,
          onChanged: (value) {
            context.read<OptionsConfigurationBloc>().add(
                  UpdateVenueIsPrivate(isPrivate: value),
                );
          },
        ),
      ],
    );
  }

  Widget _buildCapacityVisualization(VenueBookingConfig venueConfig) {
    final int totalCapacity = venueConfig.type == VenueBookingType.fullVenue
        ? venueConfig.maxCapacity
        : venueConfig.selectedCapacity ?? 0;

    final int usedCapacity = venueConfig.confirmedCapacityUsed;
    final int remainingCapacity = venueConfig.remainingCapacity;

    // Calculate percentages for the bar
    final double usedPercentage =
        totalCapacity > 0 ? (usedCapacity / totalCapacity) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Capacity Summary",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),

        // Capacity progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: usedPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 20,
          ),
        ),
        const Gap(8),

        // Capacity details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Used: $usedCapacity people",
              style: AppTextStyle.getSmallStyle(),
            ),
            Text(
              "Available: $remainingCapacity people",
              style: AppTextStyle.getSmallStyle(),
            ),
          ],
        ),

        // Dynamic pricing if available
        if (venueConfig.pricePerPerson != null) ...[
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price per person:",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              Text(
                "\$${venueConfig.pricePerPerson!.toStringAsFixed(2)}",
                style: AppTextStyle.getTitleStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dynamic price ($usedCapacity people):",
                style: AppTextStyle.getTitleStyle(fontSize: 14),
              ),
              Text(
                "\$${venueConfig.calculateDynamicPrice().toStringAsFixed(2)}",
                style: AppTextStyle.getTitleStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
