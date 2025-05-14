import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:gap/gap.dart';

class CostSplitSection extends StatefulWidget {
  final OptionsConfigurationState state;

  const CostSplitSection({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  State<CostSplitSection> createState() => _CostSplitSectionState();
}

class _CostSplitSectionState extends State<CostSplitSection> {
  // Map of attendee IDs to custom amount controllers
  final Map<String, TextEditingController> _customAmountControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(CostSplitSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If attendees changed, update controllers
    if (oldWidget.state.venueBookingConfig?.attendees !=
        widget.state.venueBookingConfig?.attendees) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Clear old controllers that are no longer needed
    final currentAttendees = widget.state.venueBookingConfig?.attendees ?? [];
    final Set<String> currentIds = currentAttendees.map((a) => a.id).toSet();

    // Remove controllers for attendees that are no longer present
    _customAmountControllers.removeWhere((id, _) => !currentIds.contains(id));

    // Add controllers for new attendees
    for (var attendee in currentAttendees) {
      if (!_customAmountControllers.containsKey(attendee.id)) {
        _customAmountControllers[attendee.id] = TextEditingController(
          text: attendee.amountOwed.toStringAsFixed(2),
        );
      } else {
        // Update existing controller value if needed
        if (_customAmountControllers[attendee.id]!.text !=
            attendee.amountOwed.toStringAsFixed(2)) {
          _customAmountControllers[attendee.id]!.text =
              attendee.amountOwed.toStringAsFixed(2);
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Early return if no cost split configuration
    if (widget.state.costSplitConfig == null &&
        (widget.state.venueBookingConfig == null ||
            widget.state.venueBookingConfig!.attendees.isEmpty)) {
      return const SizedBox.shrink();
    }

    final costSplitConfig = widget.state.costSplitConfig;
    final hasAttendees =
        (widget.state.venueBookingConfig?.attendees.isNotEmpty ?? false) ||
            widget.state.selectedAttendees.isNotEmpty;

    if (!hasAttendees) {
      return const SizedBox.shrink();
    }

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
                    CupertinoIcons.money_dollar_circle_fill,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Cost Splitting",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Split type selection
            _buildSplitTypeSelector(costSplitConfig),
            const Gap(16),

            // Host paying toggle
            if (costSplitConfig != null &&
                costSplitConfig.type == CostSplitType.splitEqually) ...[
              _buildHostPayingToggle(costSplitConfig),
              const Gap(16),
            ],

            // Individual cost splitting form
            if (costSplitConfig != null &&
                costSplitConfig.type == CostSplitType.splitCustom) ...[
              _buildCustomCostSplitForm(),
              const Gap(16),
            ],

            // Cost visualization
            _buildCostVisualization(),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitTypeSelector(CostSplitConfig? costSplitConfig) {
    final currentType = costSplitConfig?.type ?? CostSplitType.splitEqually;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How would you like to split the cost?",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        SegmentedButton<CostSplitType>(
          segments: const [
            ButtonSegment(
              value: CostSplitType.splitEqually,
              label: Text('Split Equally'),
              icon: Icon(CupertinoIcons.equal_circle_fill),
            ),
            ButtonSegment(
              value: CostSplitType.payAllMyself,
              label: Text('Pay All Myself'),
              icon: Icon(CupertinoIcons.person_circle_fill),
            ),
            ButtonSegment(
              value: CostSplitType.splitCustom,
              label: Text('Custom Split'),
              icon: Icon(CupertinoIcons.slider_horizontal_3),
            ),
          ],
          selected: {currentType},
          onSelectionChanged: (value) {
            if (value.isNotEmpty) {
              context.read<OptionsConfigurationBloc>().add(
                    ChangeCostSplitType(splitType: value.first),
                  );
            }
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(MaterialState.selected)) {
                  return AppColors.primaryColor;
                }
                return null;
              },
            ),
            foregroundColor: MaterialStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return AppColors.primaryColor;
              },
            ),
          ),
        ),
        const Gap(8),
        // Description
        Text(
          _getSplitTypeDescription(currentType),
          style: AppTextStyle.getSmallStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getSplitTypeDescription(CostSplitType type) {
    switch (type) {
      case CostSplitType.splitEqually:
        return "The total cost will be divided equally among all attendees.";
      case CostSplitType.payAllMyself:
        return "You'll cover the entire cost for all attendees.";
      case CostSplitType.splitCustom:
        return "Specify custom amounts for each attendee.";
    }
  }

  Widget _buildHostPayingToggle(CostSplitConfig costSplitConfig) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        "I'll pay for everyone",
        style: AppTextStyle.getTitleStyle(fontSize: 14),
      ),
      subtitle: Text(
        costSplitConfig.isHostPaying
            ? "You'll cover the cost for all attendees"
            : "Cost will be split equally among all attendees",
        style: AppTextStyle.getSmallStyle(
          color: Colors.grey,
        ),
      ),
      value: costSplitConfig.isHostPaying,
      activeColor: AppColors.primaryColor,
      onChanged: (value) {
        context.read<OptionsConfigurationBloc>().add(
              UpdateHostPaying(isHostPaying: value),
            );
      },
    );
  }

  Widget _buildCustomCostSplitForm() {
    final attendees = widget.state.venueBookingConfig?.attendees ?? [];
    final totalAmount =
        widget.state.costSplitConfig?.totalAmount ?? widget.state.totalPrice;

    if (attendees.isEmpty) {
      return Text(
        "Add attendees to split costs",
        style: AppTextStyle.getSmallStyle(
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify amount for each person",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        ...attendees.map(
            (attendee) => _buildAttendeeAmountField(attendee, totalAmount)),

        // Total summary
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total:",
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "\$${totalAmount.toStringAsFixed(2)}",
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),

        // Calculate remaining amount
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Currently allocated:",
              style: AppTextStyle.getSmallStyle(),
            ),
            Text(
              "\$${_calculateTotalAllocated().toStringAsFixed(2)}",
              style: AppTextStyle.getSmallStyle(
                color: _isTotalAllocatedMatching() ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Warning if total doesn't match
        if (!_isTotalAllocatedMatching()) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red, size: 16),
                const Gap(8),
                Expanded(
                  child: Text(
                    "The allocated amounts don't match the total cost. Adjust the amounts to continue.",
                    style: AppTextStyle.getSmallStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttendeeAmountField(
      AttendeeConfig attendee, double totalAmount) {
    // Get or create controller for this attendee
    final controller = _customAmountControllers[attendee.id]!;

    // Determine if this is the current user
    final isCurrentUser = attendee.type == AttendeeType.currentUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Attendee avatar and name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _getAttendeeAvatar(attendee),
                const Gap(8),
                Expanded(
                  child: Text(
                    attendee.name + (isCurrentUser ? " (You)" : ""),
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      fontWeight:
                          isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Amount field
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textAlign: TextAlign.right,
              onChanged: (value) {
                try {
                  final amount = double.parse(value);
                  context.read<OptionsConfigurationBloc>().add(
                        UpdateCustomCostSplit(
                          attendeeId: attendee.id,
                          amount: amount,
                        ),
                      );
                } catch (_) {
                  // Invalid number, ignore
                }
              },
            ),
          ),

          // Quick options
          IconButton(
            icon: const Icon(CupertinoIcons.equal_circle_fill, size: 20),
            tooltip: 'Equal split',
            onPressed: () {
              final equalAmount = totalAmount /
                  (widget.state.venueBookingConfig?.attendees.length ?? 1);
              controller.text = equalAmount.toStringAsFixed(2);
              context.read<OptionsConfigurationBloc>().add(
                    UpdateCustomCostSplit(
                      attendeeId: attendee.id,
                      amount: equalAmount,
                    ),
                  );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
            tooltip: 'Zero',
            onPressed: () {
              controller.text = '0.00';
              context.read<OptionsConfigurationBloc>().add(
                    UpdateCustomCostSplit(
                      attendeeId: attendee.id,
                      amount: 0,
                    ),
                  );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.money_dollar_circle_fill, size: 20),
            tooltip: 'Full amount',
            onPressed: () {
              controller.text = totalAmount.toStringAsFixed(2);
              context.read<OptionsConfigurationBloc>().add(
                    UpdateCustomCostSplit(
                      attendeeId: attendee.id,
                      amount: totalAmount,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }

  double _calculateTotalAllocated() {
    if (widget.state.venueBookingConfig == null) return 0;

    double total = 0;
    for (var attendee in widget.state.venueBookingConfig!.attendees) {
      total += attendee.amountOwed;
    }
    return total;
  }

  bool _isTotalAllocatedMatching() {
    if (widget.state.costSplitConfig == null) return true;

    final totalAllocated = _calculateTotalAllocated();
    final totalAmount = widget.state.costSplitConfig!.totalAmount;

    // Allow small floating point differences
    return (totalAllocated - totalAmount).abs() < 0.01;
  }

  Widget _buildCostVisualization() {
    final attendees = widget.state.venueBookingConfig?.attendees ?? [];
    if (attendees.isEmpty) return const SizedBox.shrink();

    final totalAmount =
        widget.state.costSplitConfig?.totalAmount ?? widget.state.totalPrice;

    // Sort attendees by amount (highest first)
    final sortedAttendees = List.of(attendees)
      ..sort((a, b) => b.amountOwed.compareTo(a.amountOwed));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cost Breakdown",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),

        // Pie chart visualization or bar chart could go here
        // For now, we'll use a simpler list view
        ...sortedAttendees.map((attendee) {
          // Calculate percentage of total
          final percentage =
              totalAmount > 0 ? (attendee.amountOwed / totalAmount * 100) : 0;

          final isCurrentUser = attendee.type == AttendeeType.currentUser;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getAttendeeAvatar(attendee),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        attendee.name + (isCurrentUser ? " (You)" : ""),
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 14,
                          fontWeight: isCurrentUser
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      "\$${attendee.amountOwed.toStringAsFixed(2)}",
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? AppColors.primaryColor : null,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      "(${percentage.toStringAsFixed(0)}%)",
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                // Progress bar showing percentage
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCurrentUser
                          ? AppColors.primaryColor
                          : AppColors.primaryColor.withOpacity(0.5),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // Payment status summary
        const Gap(16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment Status",
                style: AppTextStyle.getTitleStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              _buildPaymentStatusRow(
                  "Paid",
                  _countAttendeesWithStatus(PaymentStatus.complete),
                  Colors.green),
              _buildPaymentStatusRow(
                  "Pending",
                  _countAttendeesWithStatus(PaymentStatus.pending),
                  Colors.orange),
              _buildPaymentStatusRow("Failed",
                  _countAttendeesWithStatus(PaymentStatus.partial), Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: AppTextStyle.getSmallStyle(),
          ),
          const Spacer(),
          Text(
            "$count",
            style: AppTextStyle.getSmallStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _countAttendeesWithStatus(PaymentStatus status) {
    if (widget.state.venueBookingConfig == null) return 0;

    return widget.state.venueBookingConfig!.attendees
        .where((a) => a.paymentStatus == status)
        .length;
  }

  Widget _getAttendeeAvatar(AttendeeConfig attendee) {
    Color avatarColor;
    IconData iconData;

    // Determine avatar appearance based on attendee type
    switch (attendee.type) {
      case AttendeeType.currentUser:
        avatarColor = AppColors.primaryColor;
        iconData = CupertinoIcons.person_fill;
        break;
      case AttendeeType.friend:
        avatarColor = Colors.blue;
        iconData = CupertinoIcons.person_2_fill;
        break;
      case AttendeeType.familyMember:
        avatarColor = Colors.green;
        iconData = CupertinoIcons.house_fill;
        break;
      default: // external
        avatarColor = Colors.orange;
        iconData = CupertinoIcons.person_badge_plus_fill;
    }

    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: 12,
      child: Icon(
        iconData,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}
