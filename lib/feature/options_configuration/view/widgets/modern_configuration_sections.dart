import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/screens/attendee_selection_screen.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Enhanced time slot model with capacity information
class TimeSlotWithCapacity {
  final String time;
  final bool isAvailable;
  final TimeSlotCapacity? capacityInfo;

  TimeSlotWithCapacity({
    required this.time,
    required this.isAvailable,
    this.capacityInfo,
  });
}

/// Legacy time slot model for backward compatibility
class TimeSlot {
  final String time;
  final bool isAvailable;

  TimeSlot({required this.time, required this.isAvailable});
}

/// User profile picture widget
class UserProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final String? attendeeType; // friend, family, user

  const UserProfilePicture({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.attendeeType,
  });

  @override
  Widget build(BuildContext context) {
    Color defaultColor = _getDefaultColor();

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(size * 0.2), // 20% of size for better curves
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultColor,
          borderRadius: BorderRadius.circular(size * 0.2),
          border: attendeeType == 'user'
              ? Border.all(
                  color: AppColors.primaryColor,
                  width: 2,
                )
              : null,
          boxShadow: attendeeType == 'user'
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.2),
                child: Image.network(
                  imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultAvatar(),
                ),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35, // 35% of container size
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  String _getInitials() {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  Color _getDefaultColor() {
    switch (attendeeType) {
      case 'user':
        return AppColors.primaryColor;
      case 'friend':
        return AppColors.cyanColor;
      case 'family':
        return AppColors.greenColor;
      default:
        // Generate color based on name hash for consistency
        final int hash = name.hashCode;
        final List<Color> colors = [
          AppColors.primaryColor,
          AppColors.secondaryColor,
          AppColors.cyanColor,
          AppColors.greenColor,
          Colors.purple,
          Colors.orange,
          Colors.teal,
        ];
        return colors[hash.abs() % colors.length];
    }
  }
}

/// Modern Date and Time Selection Widget
class ModernDateTimeSelection extends StatefulWidget {
  final OptionsConfigurationState state;

  const ModernDateTimeSelection({super.key, required this.state});

  @override
  State<ModernDateTimeSelection> createState() =>
      _ModernDateTimeSelectionState();
}

class _ModernDateTimeSelectionState extends State<ModernDateTimeSelection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSectionHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const Gap(20),
                  _buildTimeSelector(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.calendar,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date & Time',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Select your preferred date and time',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (widget.state.selectedDate != null &&
              widget.state.selectedTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.check_mark,
                    color: AppColors.greenColor,
                    size: 14,
                  ),
                  const Gap(4),
                  Text(
                    'Selected',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.greenColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.state.selectedDate != null
                  ? AppColors.primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: widget.state.selectedDate != null ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showDatePicker(),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  color: widget.state.selectedDate != null
                      ? AppColors.primaryColor
                      : AppColors.secondaryText,
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    widget.state.selectedDate != null
                        ? DateFormat('EEE, MMM d, y')
                            .format(widget.state.selectedDate!)
                        : 'Tap to select date',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      color: widget.state.selectedDate != null
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                      fontWeight: widget.state.selectedDate != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        if (widget.state.selectedDate != null)
          _buildTimeSlotsWithCapacity()
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  color: Colors.grey,
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Select a date first',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotsWithCapacity() {
    return FutureBuilder<List<TimeSlotCapacity>>(
      future: _fetchTimeSlotsWithCapacity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSlots();
        }

        if (snapshot.hasError) {
          return _buildErrorSlots();
        }

        final slotsWithCapacity = snapshot.data ?? [];
        return _buildCapacityAwareTimeSlots(slotsWithCapacity);
      },
    );
  }

  Widget _buildLoadingSlots() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const Gap(8),
              Text(
                'Loading available slots...',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(6, (index) => _buildSkeletonSlot()),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSlots() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.red,
                size: 16,
              ),
              const Gap(8),
              Text(
                'Error loading slots',
                style: AppTextStyle.getSmallStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'Please try again or contact support',
            style: AppTextStyle.getSmallStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonSlot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '--:--',
        style: AppTextStyle.getSmallStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCapacityAwareTimeSlots(
      List<TimeSlotCapacity> slotsWithCapacity) {
    final attendeeCount = 1 + widget.state.selectedAttendees.length;
    final availableSlots = slotsWithCapacity
        .where((slot) =>
            slot.isAvailable && slot.availableCapacity >= attendeeCount)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with capacity info
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                color: AppColors.primaryColor,
                size: 16,
              ),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Time Slots',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$availableSlots slots available for $attendeeCount ${attendeeCount == 1 ? 'person' : 'people'}',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCapacityLegend(),
              // Debug button (only in debug mode)
              if (kDebugMode) ...[
                const Gap(8),
                GestureDetector(
                  onTap: () => _debugOperatingHours(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      CupertinoIcons.info,
                      size: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(12),

          // Show debug info if no slots available
          if (slotsWithCapacity.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const Gap(8),
                      Text(
                        'No time slots available',
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    'This could be because:\n• Provider is closed today\n• No operating hours configured\n• All slots are fully booked',
                    style: AppTextStyle.getSmallStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const Gap(8),
                    ElevatedButton(
                      onPressed: _debugOperatingHours,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'Debug Hours',
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(12),
          ],

          // Capacity explanation for first time users
          if (slotsWithCapacity.any((slot) => slot.bookedCapacity > 0)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: AppColors.primaryColor,
                    size: 14,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Multiple people can book the same time slot if capacity permits',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
          ],

          // Time slots grid
          if (slotsWithCapacity.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slotsWithCapacity.map((slot) {
                return _buildCapacityTimeSlot(slot);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCapacityLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(Colors.green, 'Available'),
        const Gap(8),
        _buildLegendItem(Colors.orange, 'Limited'),
        const Gap(8),
        _buildLegendItem(Colors.red, 'Full'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityTimeSlot(TimeSlotCapacity slot) {
    final isSelected = widget.state.selectedTime == slot.timeSlot;
    final isAvailable = slot.isAvailable;

    // Calculate attendee count from the current state
    int attendeeCount = 1; // Always include the user

    // Add selected attendees
    attendeeCount += widget.state.selectedAttendees.length;

    return GestureDetector(
      onTap: isAvailable && slot.availableCapacity >= attendeeCount
          ? () => _selectTimeSlot(slot.timeSlot)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : isAvailable
                  ? Colors.white
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : slot.status.color.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.timeSlot,
              style: AppTextStyle.getSmallStyle(
                color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? AppColors.primaryText
                        : Colors.grey,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isAvailable) ...[
              const Gap(4),
              // Capacity progress bar
              _buildCapacityProgressBar(slot, isSelected),
              const Gap(2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : slot.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '${slot.availableCapacity}/${slot.totalCapacity}',
                    style: AppTextStyle.getSmallStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : slot.status.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (slot.availableCapacity < attendeeCount) ...[
                const Gap(1),
                Text(
                  'Not enough spots',
                  style: AppTextStyle.getSmallStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityProgressBar(TimeSlotCapacity slot, bool isSelected) {
    final utilizationRate = slot.utilizationRate;

    return Container(
      width: 40,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: isSelected
            ? Colors.white.withOpacity(0.3)
            : Colors.grey.withOpacity(0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: utilizationRate,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isSelected ? Colors.white : slot.status.color,
          ),
        ),
      ),
    );
  }

  Future<List<TimeSlotCapacity>> _fetchTimeSlotsWithCapacity() async {
    try {
      final selectedDate = widget.state.selectedDate!;
      final providerId = widget.state.providerId;

      if (providerId == null) return [];

      // Fetch slots with capacity information
      final orchestrator = FirebaseDataOrchestrator();
      final slotsWithCapacity =
          await orchestrator.fetchAvailableSlotsWithCapacity(
        providerId: providerId,
        date: selectedDate,
        durationMinutes: 60, // Default duration
      );

      return slotsWithCapacity;
    } catch (e) {
      debugPrint('Error fetching time slots with capacity: $e');
      return [];
    }
  }

  void _selectTimeSlot(String timeSlot) {
    // Direct selection without validation for better performance
    // Validation will happen during reservation creation
    _selectTimeSlotDirectly(timeSlot);
  }

  void _selectTimeSlotDirectly(String timeSlot) {
    context.read<OptionsConfigurationBloc>().add(
          TimeSelected(selectedTime: timeSlot),
        );
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: widget.state.selectedDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        context.read<OptionsConfigurationBloc>().add(
              DateSelected(selectedDate: selectedDate),
            );
      }
    });
  }

  void _debugOperatingHours() async {
    final providerId = widget.state.providerId;
    if (providerId != null) {
      final orchestrator = FirebaseDataOrchestrator();
      await orchestrator.debugProviderOperatingHours(providerId);

      // Show a snackbar to indicate debug info was logged
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug info logged to console'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Modern Attendee Selection Widget - Redesigned for better UX
class ModernAttendeeSelection extends StatefulWidget {
  final OptionsConfigurationState state;

  const ModernAttendeeSelection({super.key, required this.state});

  @override
  State<ModernAttendeeSelection> createState() =>
      _ModernAttendeeSelectionState();
}

class _ModernAttendeeSelectionState extends State<ModernAttendeeSelection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Load friends and family members when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<OptionsConfigurationBloc>()
          .add(const LoadCurrentUserFriends());
      context
          .read<OptionsConfigurationBloc>()
          .add(const LoadCurrentUserFamilyMembers());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSectionHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHostCard(),
                  const Gap(20),
                  _buildPaymentOptionSelector(),
                  const Gap(20),
                  _buildAttendeeCounter(),
                  const Gap(20),
                  _buildSelectedAttendeesList(),
                  const Gap(20),
                  _buildAddAttendeesButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final totalAttendees = _getTotalAttendees();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.group,
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendees',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Who\'s joining your booking?',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$totalAttendees ${totalAttendees == 1 ? 'Person' : 'People'}',
              style: AppTextStyle.getTitleStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostCard() {
    final includeUser = widget.state.includeUserInBooking;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: includeUser
              ? [
                  AppColors.primaryColor.withOpacity(0.08),
                  AppColors.primaryColor.withOpacity(0.04),
                ]
              : [
                  Colors.grey.withOpacity(0.08),
                  Colors.grey.withOpacity(0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: includeUser
              ? AppColors.primaryColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          UserProfilePicture(
            imageUrl: null, // TODO: Get actual user profile picture
            name: 'You',
            size: 60,
            attendeeType: 'user',
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'You',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            includeUser ? AppColors.primaryText : Colors.grey,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: includeUser ? AppColors.greenColor : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        includeUser ? 'INCLUDED' : 'EXCLUDED',
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  includeUser
                      ? 'Booking organizer & payment handler'
                      : 'Not attending this booking',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
                const Gap(8),
                // Toggle button for including/excluding self
                GestureDetector(
                  onTap: () {
                    context.read<OptionsConfigurationBloc>().add(
                          ToggleUserSelfInclusion(includeUser: !includeUser),
                        );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: includeUser
                          ? AppColors.redColor.withOpacity(0.1)
                          : AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: includeUser
                            ? AppColors.redColor.withOpacity(0.3)
                            : AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          includeUser
                              ? CupertinoIcons.minus_circle
                              : CupertinoIcons.plus_circle,
                          color: includeUser
                              ? AppColors.redColor
                              : AppColors.primaryColor,
                          size: 16,
                        ),
                        const Gap(6),
                        Text(
                          includeUser ? 'Remove me' : 'Include me',
                          style: AppTextStyle.getSmallStyle(
                            color: includeUser
                                ? AppColors.redColor
                                : AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionSelector() {
    final payForAll = widget.state.payForAllAttendees;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentOptionItem(
              title: 'Individual Payment',
              subtitle: 'Everyone pays separately',
              icon: CupertinoIcons.person_circle,
              isSelected: !payForAll,
              onTap: () {
                context.read<OptionsConfigurationBloc>().add(
                      const UpdatePaymentMode(payForAll: false),
                    );
              },
            ),
          ),
          Expanded(
            child: _buildPaymentOptionItem(
              title: 'Pay for All',
              subtitle: 'You pay for everyone',
              icon: CupertinoIcons.creditcard_fill,
              isSelected: payForAll,
              onTap: () {
                context.read<OptionsConfigurationBloc>().add(
                      const UpdatePaymentMode(payForAll: true),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const Gap(8),
            Text(
              title,
              style: AppTextStyle.getTitleStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryText : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(4),
            Text(
              subtitle,
              style: AppTextStyle.getSmallStyle(
                fontSize: 11,
                color: isSelected ? AppColors.secondaryText : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeCounter() {
    final totalAttendees = _getTotalAttendees();
    final includeUser = widget.state.includeUserInBooking;
    final payForAll = widget.state.payForAllAttendees;
    final basePrice = widget.state.basePrice;
    final actualTotal = includeUser ? totalAttendees + 1 : totalAttendees;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Attendees',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    actualTotal == 0
                        ? 'No one attending'
                        : '$actualTotal ${actualTotal == 1 ? 'person' : 'people'} attending',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              Text(
                '$actualTotal',
                style: AppTextStyle.getHeadlineTextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: actualTotal > 0 ? AppColors.primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: payForAll
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : AppColors.greenColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: payForAll
                    ? AppColors.primaryColor.withOpacity(0.3)
                    : AppColors.greenColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  payForAll
                      ? CupertinoIcons.creditcard_fill
                      : CupertinoIcons.person_2_fill,
                  color:
                      payForAll ? AppColors.primaryColor : AppColors.greenColor,
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payForAll
                            ? 'You\'ll pay for everyone'
                            : 'Individual payments',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: payForAll
                              ? AppColors.primaryColor
                              : AppColors.greenColor,
                        ),
                      ),
                      Text(
                        'Total cost: EGP ${widget.state.totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalAttendees() {
    return widget.state.selectedAttendees.length;
  }

  Widget _buildSelectedAttendeesList() {
    if (widget.state.selectedAttendees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.person_add_solid,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const Gap(12),
            Text(
              'No additional attendees',
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const Gap(4),
            Text(
              'Add friends or family to join your booking',
              style: AppTextStyle.getSmallStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Additional Attendees',
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.state.selectedAttendees.length}',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        ...widget.state.selectedAttendees.asMap().entries.map((entry) {
          final index = entry.key;
          final attendee = entry.value;
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildAttendeeCard(attendee, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAttendeeCard(attendee, int index) {
    final payForAll = widget.state.payForAllAttendees;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserProfilePicture(
            imageUrl:
                null, // TODO: Get actual profile picture from attendee data
            name: attendee.name,
            size: 48,
            attendeeType: attendee.type,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attendee.name,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: attendee.type == 'friend'
                            ? AppColors.cyanColor.withOpacity(0.1)
                            : AppColors.greenColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        attendee.type.toUpperCase(),
                        style: AppTextStyle.getSmallStyle(
                          color: attendee.type == 'friend'
                              ? AppColors.cyanColor
                              : AppColors.greenColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    Icon(
                      payForAll
                          ? CupertinoIcons.creditcard
                          : CupertinoIcons.money_dollar_circle,
                      color: payForAll
                          ? AppColors.primaryColor
                          : AppColors.greenColor,
                      size: 14,
                    ),
                    const Gap(4),
                    Text(
                      payForAll ? 'Paid by organizer' : 'Individual payment',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.redColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                CupertinoIcons.minus_circle_fill,
                color: AppColors.redColor,
                size: 20,
              ),
              onPressed: () {
                context.read<OptionsConfigurationBloc>().add(
                      RemoveOptionAttendee(attendeeUserId: attendee.userId),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAttendeesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToAttendeeSelection(),
        icon: const Icon(CupertinoIcons.person_add),
        label: Text(
          widget.state.selectedAttendees.isEmpty
              ? 'Add Friends & Family'
              : 'Manage Attendees',
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryColor,
          side: BorderSide(
              color: AppColors.primaryColor.withOpacity(0.3), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _navigateToAttendeeSelection() async {
    final result = await Navigator.push<List<AttendeeConfig>>(
      context,
      MaterialPageRoute(
        builder: (context) => AttendeeSelectionScreen(
          initialSelectedAttendees: widget.state.selectedAttendees
              .map((attendee) => AttendeeConfig.fromAttendeeModel(attendee))
              .toList(),
          eventTitle: 'Your Booking',
        ),
      ),
    );

    if (result != null && mounted) {
      // Clear existing attendees first to avoid duplicates
      for (final existingAttendee in widget.state.selectedAttendees) {
        context.read<OptionsConfigurationBloc>().add(
              RemoveOptionAttendee(attendeeUserId: existingAttendee.userId),
            );
      }

      // Add new attendees
      for (final attendee in result) {
        if (attendee.type == AttendeeType.familyMember) {
          // Add family member
          final familyMember = FamilyMember(
            id: attendee.id,
            name: attendee.name ?? 'Unknown',
            userId: attendee.userId,
            relationship: attendee.relationship ?? 'Family Member',
            status: 'accepted', // Default status for selected family members
          );
          context.read<OptionsConfigurationBloc>().add(
                AddFamilyMemberAsAttendee(familyMember: familyMember),
              );
        } else if (attendee.type == AttendeeType.friend) {
          // Add friend - create a friend map
          final friendData = {
            'userId': attendee.userId ?? attendee.id,
            'name': attendee.name,
            'profilePicUrl': attendee.profilePictureUrl,
          };
          context.read<OptionsConfigurationBloc>().add(
                AddFriendAsAttendee(friend: friendData),
              );
        } else if (attendee.type == AttendeeType.external) {
          // Add external guest
          context.read<OptionsConfigurationBloc>().add(
                AddExternalAttendee(
                  name: attendee.name,
                  relationship: attendee.relationship ?? 'Guest',
                ),
              );
        }
      }
    }
  }
}

/// Modern Preferences Section Widget
class ModernPreferencesSection extends StatelessWidget {
  final OptionsConfigurationState state;

  const ModernPreferencesSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildNotificationSettings(),
                const Gap(16),
                _buildReminderSettings(),
                const Gap(16),
                _buildSharingSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.settings,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _buildPreferenceCard(
      icon: CupertinoIcons.bell,
      title: 'Notifications',
      subtitle: 'Get updates about your booking',
      value: true,
      onChanged: (value) {
        // Handle notification settings change
      },
    );
  }

  Widget _buildReminderSettings() {
    return _buildPreferenceCard(
      icon: CupertinoIcons.alarm,
      title: 'Reminders',
      subtitle: 'Set reminders before your appointment',
      value: true,
      onChanged: (value) {
        // Handle reminder settings change
      },
    );
  }

  Widget _buildSharingSettings() {
    return _buildPreferenceCard(
      icon: CupertinoIcons.share,
      title: 'Calendar Integration',
      subtitle: 'Add to your calendar automatically',
      value: false,
      onChanged: (value) {
        // Handle sharing settings change
      },
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

// Helper class to combine friends and family members
class CombinedContact {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String? relationship;
  final bool isFamilyMember;
  final bool isFriend;
  final FamilyMember? familyMember;
  final dynamic friendData;

  const CombinedContact({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.relationship,
    required this.isFamilyMember,
    required this.isFriend,
    this.familyMember,
    this.friendData,
  });

  CombinedContact copyWith({
    String? userId,
    String? name,
    String? profileImageUrl,
    String? relationship,
    bool? isFamilyMember,
    bool? isFriend,
    FamilyMember? familyMember,
    dynamic friendData,
  }) {
    return CombinedContact(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      relationship: relationship ?? this.relationship,
      isFamilyMember: isFamilyMember ?? this.isFamilyMember,
      isFriend: isFriend ?? this.isFriend,
      familyMember: familyMember ?? this.familyMember,
      friendData: friendData ?? this.friendData,
    );
  }
}
