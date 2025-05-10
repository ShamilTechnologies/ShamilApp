// lib/feature/options_configuration/view/options_configuration_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'
    show OpeningHoursDay;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart'
    show
        ReservationModel,
        AttendeeModel,
        ReservationStatus,
        ReservationStatusExtension;
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/repository/options_configuration_repository.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // For AuthModel if current user is an attendee
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // To get current user
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'dart:ui' as ui;

class OptionsConfigurationScreen extends StatelessWidget {
  final String providerId;
  final PlanModel? plan;
  final ServiceModel? service;

  const OptionsConfigurationScreen({
    super.key,
    required this.providerId,
    this.plan,
    this.service,
  }) : assert(plan != null || service != null,
            'Either plan or service must be provided');

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OptionsConfigurationBloc(
        repository: FirebaseOptionsConfigurationRepository(),
      )..add(InitializeOptionsConfiguration(
          providerId: providerId,
          plan: plan,
          service: service,
        )),
      child: _OptionsConfigurationView(
        providerId: providerId,
        isPlan: plan != null,
      ),
    );
  }
}

class _OptionsConfigurationView extends StatefulWidget {
  final String providerId;
  final bool isPlan;

  const _OptionsConfigurationView({
    required this.providerId,
    required this.isPlan,
  });

  @override
  State<_OptionsConfigurationView> createState() =>
      _OptionsConfigurationViewState();
}

class _OptionsConfigurationViewState extends State<_OptionsConfigurationView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Scroll controller to implement the collapsing app bar effect
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Setup scroll listener
    _scrollController.addListener(_scrollListener);

    // Connect notes controller to bloc state
    final optionsBloc = context.read<OptionsConfigurationBloc>();
    _notesController.text = optionsBloc.state.notes ?? '';

    // Listen to BLoC state for notes changes to prevent overwriting user input
    optionsBloc.stream.listen((state) {
      if (mounted && _notesController.text != (state.notes ?? '')) {
        final currentSelection = _notesController.selection;
        _notesController.text = state.notes ?? '';
        if (currentSelection.start <= _notesController.text.length &&
            currentSelection.end <= _notesController.text.length) {
          _notesController.selection = currentSelection;
        }
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 56 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 56 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<OptionsConfigurationBloc, OptionsConfigurationState>(
      listener: (context, state) {
        // Handle success and error states
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          showGlobalSnackBar(context, state.errorMessage!, isError: true);
          context
              .read<OptionsConfigurationBloc>()
              .add(const ClearErrorMessage());
        }

        // Handle confirmed state
        if (state is OptionsConfigurationConfirmed) {
          HapticFeedback.mediumImpact();

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.greenColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: AppColors.greenColor,
                      size: 48,
                    ),
                  ),
                  const Gap(16),
                  Text(
                    widget.isPlan
                        ? "Subscription Confirmed!"
                        : "Booking Confirmed!",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    "Confirmation ID: ${state.confirmationId}",
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    "Total: ${state.currencySymbol}${state.totalPrice.toStringAsFixed(2)}",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context,
                            state); // Return to previous screen with result
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Done"),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is OptionsConfigurationInitial) {
          return _buildLoadingScreen(theme);
        }

        if (state.itemId.isEmpty &&
            state.originalPlan == null &&
            state.originalService == null &&
            !state.isLoading) {
          return _buildErrorScreen(theme, "Configuration Error",
              "No item details found to configure. Please go back and try again.");
        }

        // Get operating hours and reservations from bloc
        final OptionsConfigurationBloc bloc =
            context.read<OptionsConfigurationBloc>();
        final Map<String, OpeningHoursDay> operatingHours =
            bloc.getOperatingHours();
        final List<ReservationModel> existingReservations =
            bloc.getExistingReservations();
        final bool isLoadingOperatingHours = bloc.isLoadingOperatingHours();
        final bool isLoadingReservations = bloc.isLoadingReservations();

        final options = state.optionsDefinition;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.9),
                      AppColors.lightBackground,
                    ],
                    stops: const [0.0, 0.15, 0.3],
                  ),
                ),
              ),

              // Main content with app bar
              SafeArea(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      _buildFlexibleAppBar(theme, state, innerBoxIsScrolled),
                    ];
                  },
                  body: FadeTransition(
                    opacity: _fadeAnimation,
                    child: options != null
                        ? _buildMainContent(
                            theme,
                            state,
                            options,
                            operatingHours,
                            existingReservations,
                            isLoadingOperatingHours,
                            isLoadingReservations,
                          )
                        : _buildNoOptionsMessage(theme),
                  ),
                ),
              ),

              // Bottom action bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomActionBar(theme, state),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildFlexibleAppBar(
    ThemeData theme,
    OptionsConfigurationState state,
    bool innerBoxIsScrolled,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor:
          _isScrolled ? AppColors.primaryColor : Colors.transparent,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: _isScrolled
          ? Text(
              state.itemName,
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isPlan ? "Configure Subscription" : "Configure Booking",
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(4),
              Text(
                state.itemName,
                style: AppTextStyle.getHeadlineTextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    ThemeData theme,
    OptionsConfigurationState state,
    Map<String, dynamic> options,
    Map<String, OpeningHoursDay> operatingHours,
    List<ReservationModel> existingReservations,
    bool isLoadingOperatingHours,
    bool isLoadingReservations,
  ) {
    final List<Widget> optionsWidgets = [];

    // Add curved container for the main content
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Item summary card
              _buildItemSummaryCard(theme, state),

              // Attendees summary if any
              if (state.selectedAttendees.isNotEmpty &&
                  options['allowAttendeeSelection'] == true)
                _buildAttendeesSummaryCard(theme, state),

              // Dynamic options
              ..._buildDynamicOptions(
                theme,
                state,
                options,
                operatingHours,
                existingReservations,
                isLoadingOperatingHours,
                isLoadingReservations,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemSummaryCard(
      ThemeData theme, OptionsConfigurationState state) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
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
                  child: Icon(
                    widget.isPlan
                        ? CupertinoIcons.creditcard_fill
                        : CupertinoIcons.calendar_badge_plus,
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
                        state.itemName,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.isPlan
                            ? state.originalPlan?.billingCycle ?? 'Subscription'
                            : state.originalService?.category ?? 'Service',
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${state.currencySymbol}${state.basePrice.toStringAsFixed(2)}",
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      widget.isPlan
                          ? "/${state.originalPlan?.billingCycle.split(' ').first.toLowerCase() ?? 'cycle'}"
                          : state.originalService?.priceType == "fixed"
                              ? ""
                              : "per ${state.originalService?.priceUnit ?? 'item'}",
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (state.originalService?.description != null &&
                    state.originalService!.description.isNotEmpty ||
                state.originalPlan?.description != null &&
                    state.originalPlan!.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                state.originalService?.description ??
                    state.originalPlan?.description ??
                    '',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeesSummaryCard(
      ThemeData theme, OptionsConfigurationState state) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
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
                    color: AppColors.greenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_2_fill,
                    color: AppColors.greenColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Selected Attendees (${state.selectedAttendees.length})",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.pencil_circle_fill,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () => _showAttendeeSelectionModal(theme, state),
                ),
              ],
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.selectedAttendees.map((attendee) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                    child: Text(
                      attendee.name.isNotEmpty
                          ? attendee.name.substring(0, 1).toUpperCase()
                          : "?",
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    attendee.name,
                    style: AppTextStyle.getSmallStyle(),
                  ),
                  deleteIcon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 18,
                  ),
                  onDeleted: () {
                    context.read<OptionsConfigurationBloc>().add(
                          RemoveOptionAttendee(attendeeUserId: attendee.userId),
                        );
                  },
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicOptions(
    ThemeData theme,
    OptionsConfigurationState state,
    Map<String, dynamic> options,
    Map<String, OpeningHoursDay> operatingHours,
    List<ReservationModel> existingReservations,
    bool isLoadingOperatingHours,
    bool isLoadingReservations,
  ) {
    final List<Widget> optionsWidgets = [];

    // Date selection
    if (options['allowDateSelection'] == true) {
      final List<DateTime> availableDates = _getAvailableDates(
        options,
        operatingHours,
      );

      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: "Date",
          icon: CupertinoIcons.calendar,
          content: isLoadingOperatingHours
              ? _buildLoadingIndicator("Loading available dates...")
              : availableDates.isEmpty
                  ? _buildNoOptionsAvailable(
                      "No dates available in the next 30 days")
                  : _buildDateSelector(theme, state, availableDates),
        ),
      );
    }

    // Time selection
    if (options['allowTimeSelection'] == true && state.selectedDate != null) {
      final List<Map<String, dynamic>> timeSlots = _generateTimeSlots(
        state.selectedDate!,
        options,
        state.originalService,
        operatingHours,
        existingReservations,
      );

      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: "Time",
          icon: CupertinoIcons.clock,
          content: isLoadingReservations || isLoadingOperatingHours
              ? _buildLoadingIndicator("Loading available times...")
              : timeSlots.isEmpty
                  ? _buildNoOptionsAvailable(
                      "No time slots available for the selected date")
                  : _buildTimeSelector(theme, state, timeSlots),
        ),
      );
    }

    // Quantity selection
    if (options['allowQuantitySelection'] == true) {
      final qtyDetails = options['quantityDetails'] as Map<String, dynamic>?;
      final String qtyLabel = qtyDetails?['label'] as String? ?? 'Quantity';
      final int minQty = (qtyDetails?['min'] as num?)?.toInt() ?? 1;
      final int maxQty = (qtyDetails?['max'] as num?)?.toInt() ?? 100;

      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: qtyLabel,
          icon: CupertinoIcons.number,
          content: _buildQuantitySelector(theme, state, minQty, maxQty),
        ),
      );
    }

    // Attendee selection
    if (options['allowAttendeeSelection'] == true) {
      final attendeeDetails =
          options['attendeeDetails'] as Map<String, dynamic>?;
      final int minAttendees = (attendeeDetails?['min'] as num?)?.toInt() ?? 0;
      final int? maxAttendees = (attendeeDetails?['max'] as num?)?.toInt();

      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: "Attendees",
          icon: CupertinoIcons.person_2,
          content:
              _buildAttendeeSelector(theme, state, minAttendees, maxAttendees),
        ),
      );
    }

    // Add-ons
    if (options['availableAddOns'] is List &&
        (options['availableAddOns'] as List).isNotEmpty) {
      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: "Add-ons",
          icon: CupertinoIcons.cart_badge_plus,
          content: _buildAddOnsSelector(
              theme, state, options['availableAddOns'] as List),
        ),
      );
    }

    // Notes
    final notesPrompt = options['customizableNotes'];
    if (notesPrompt != null &&
        (notesPrompt is bool && notesPrompt == true || notesPrompt is String)) {
      optionsWidgets.add(
        _buildOptionCard(
          theme,
          title: "Additional Notes",
          icon: CupertinoIcons.doc_text,
          content: _buildNotesField(
            theme,
            notesPrompt is String
                ? notesPrompt
                : "Any specific requests or instructions?",
          ),
        ),
      );
    }

    return optionsWidgets;
  }

  Widget _buildOptionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
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
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Text(
                  title,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const CupertinoActivityIndicator(),
            const Gap(8),
            Text(
              message,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOptionsAvailable(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          message,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    OptionsConfigurationState state,
    List<DateTime> availableDates,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = state.selectedDate?.year == date.year &&
              state.selectedDate?.month == date.month &&
              state.selectedDate?.day == date.day;

          final bool isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => context
                  .read<OptionsConfigurationBloc>()
                  .add(DateSelected(selectedDate: date)),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : isToday
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : isToday
                            ? AppColors.primaryColor.withOpacity(0.3)
                            : theme.dividerColor.withOpacity(0.5),
                    width: isSelected || isToday ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: AppTextStyle.getSmallStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        date.day.toString(),
                        style: AppTextStyle.getHeadlineTextStyle(
                          fontSize: 24,
                          color:
                              isSelected ? Colors.white : AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        DateFormat('MMM').format(date),
                        style: AppTextStyle.getSmallStyle(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector(
    ThemeData theme,
    OptionsConfigurationState state,
    List<Map<String, dynamic>> timeSlots,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: timeSlots.map((slot) {
        final bool isSelected = state.selectedTime == slot['time'];
        final bool isAvailable = slot['isAvailable'] as bool;

        return InkWell(
          onTap: isAvailable
              ? () => context
                  .read<OptionsConfigurationBloc>()
                  .add(TimeSelected(selectedTime: slot['time']))
              : null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : isAvailable
                      ? Colors.white
                      : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : isAvailable
                        ? theme.dividerColor.withOpacity(0.5)
                        : theme.dividerColor.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              slot['label'],
              style: AppTextStyle.getSmallStyle(
                color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? AppColors.primaryText
                        : AppColors.secondaryText.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector(
    ThemeData theme,
    OptionsConfigurationState state,
    int minQty,
    int maxQty,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: state.groupSize > minQty
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.minus,
                color: state.groupSize > minQty
                    ? AppColors.primaryColor
                    : AppColors.secondaryText.withOpacity(0.3),
                size: 16,
              ),
            ),
            onPressed: state.groupSize > minQty
                ? () => context
                    .read<OptionsConfigurationBloc>()
                    .add(QuantityChanged(quantity: state.groupSize - 1))
                : null,
          ),
          Text(
            state.groupSize.toString(),
            style: AppTextStyle.getHeadlineTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: state.groupSize < maxQty
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.plus,
                color: state.groupSize < maxQty
                    ? AppColors.primaryColor
                    : AppColors.secondaryText.withOpacity(0.3),
                size: 16,
              ),
            ),
            onPressed: state.groupSize < maxQty
                ? () => context
                    .read<OptionsConfigurationBloc>()
                    .add(QuantityChanged(quantity: state.groupSize + 1))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeSelector(
    ThemeData theme,
    OptionsConfigurationState state,
    int minAttendees,
    int? maxAttendees,
  ) {
    String attendeeHint = "Select attendees";
    if (minAttendees > 0) attendeeHint += " (min $minAttendees)";
    if (maxAttendees != null) attendeeHint += " (max $maxAttendees)";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          attendeeHint,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(12),
        if (state.selectedAttendees.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.selectedAttendees.map((att) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  child: Text(
                    att.name.isNotEmpty
                        ? att.name.substring(0, 1).toUpperCase()
                        : "?",
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  att.name,
                  style: AppTextStyle.getSmallStyle(),
                ),
                deleteIcon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 18,
                ),
                onDeleted: () {
                  context.read<OptionsConfigurationBloc>().add(
                        RemoveOptionAttendee(attendeeUserId: att.userId),
                      );
                },
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        const Gap(12),
        ElevatedButton.icon(
          icon: const Icon(CupertinoIcons.person_badge_plus_fill, size: 20),
          label: Text(
            state.selectedAttendees.isEmpty
                ? "Add Attendees"
                : "Manage Attendees",
          ),
          onPressed: (maxAttendees != null &&
                  state.selectedAttendees.length >= maxAttendees)
              ? null
              : () => _showAttendeeSelectionModal(theme, state),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        if (maxAttendees != null &&
            state.selectedAttendees.length >= maxAttendees)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Maximum $maxAttendees attendees reached",
              style: AppTextStyle.getSmallStyle(
                color: AppColors.redColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildAddOnsSelector(
    ThemeData theme,
    OptionsConfigurationState state,
    List<dynamic> addOns,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addOns.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final addOnData = addOns[index] as Map<String, dynamic>;
        final String id = addOnData['id'] as String? ?? UniqueKey().toString();
        final String name = addOnData['name'] as String? ?? 'Unnamed Add-on';
        final double price = (addOnData['price'] as num?)?.toDouble() ?? 0.0;
        final bool isSelected = state.selectedAddOns[id] ?? false;
        final String? description = addOnData['description'] as String?;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            name,
            style: AppTextStyle.getTitleStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null && description.isNotEmpty)
                Text(
                  description,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              Text(
                "+${state.currencySymbol}${price.toStringAsFixed(2)}",
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          trailing: Switch.adaptive(
            value: isSelected,
            onChanged: (value) =>
                context.read<OptionsConfigurationBloc>().add(AddOnToggled(
                      addOnId: id,
                      isSelected: value,
                      addOnPrice: price,
                    )),
            activeColor: AppColors.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildNotesField(ThemeData theme, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: 3,
        style: AppTextStyle.getbodyStyle(),
        onChanged: (value) => context
            .read<OptionsConfigurationBloc>()
            .add(NotesUpdated(notes: value)),
      ),
    );
  }

  Widget _buildNoOptionsMessage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_circle,
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            const Gap(16),
            Text(
              "No Configurable Options",
              style: AppTextStyle.getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              "This item doesn't have any configurable options.",
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
      ThemeData theme, OptionsConfigurationState state) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Price",
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      "${state.currencySymbol}${state.totalPrice.toStringAsFixed(2)}",
                      style: AppTextStyle.getHeadlineTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.canConfirm && !state.isLoading
                      ? () => context
                          .read<OptionsConfigurationBloc>()
                          .add(const ConfirmConfiguration())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    state.isLoading ? "Processing..." : "Confirm",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Text(
          "Loading Options",
          style: AppTextStyle.getTitleStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 20),
            const Gap(24),
            Text(
              "Loading configuration options...",
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme, String title, String message) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Text(
          "Error",
          style: AppTextStyle.getTitleStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.redColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_circle,
                  color: AppColors.redColor,
                  size: 48,
                ),
              ),
              const Gap(16),
              Text(
                title,
                style: AppTextStyle.getTitleStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                message,
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAttendeeSelectionModal(
    ThemeData theme,
    OptionsConfigurationState state,
  ) async {
    // This context has access to OptionsConfigurationBloc already
    final optionsBloc = context.read<OptionsConfigurationBloc>();
    // Get SocialBloc from the main context
    final socialBloc = BlocProvider.of<SocialBloc>(context, listen: false);
    final authBloc = BlocProvider.of<AuthBloc>(context, listen: false);
    final currentUser = (authBloc.state is LoginSuccessState)
        ? (authBloc.state as LoginSuccessState).user
        : null;

    if (socialBloc.state is! FamilyDataLoaded &&
        socialBloc.state is! SocialLoading) {
      // Avoid multiple loads
      socialBloc.add(const LoadFamilyMembers());
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: optionsBloc),
            BlocProvider.value(value: socialBloc),
            if (currentUser != null) BlocProvider.value(value: authBloc),
          ],
          child: BlocBuilder<SocialBloc, SocialState>(
            builder: (modalContentContext, socialState) {
              List<FamilyMember> potentialFamilyAttendees = [];
              bool isLoadingAttendees =
                  socialState is SocialLoading && socialState.isLoadingList;

              if (socialState is FamilyDataLoaded) {
                potentialFamilyAttendees = socialState.familyMembers
                    .where((fm) => fm.status == 'accepted')
                    .toList();
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.85,
                expand: false,
                builder: (draggableContext, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),

                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Select Attendees",
                                style: AppTextStyle.getTitleStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.xmark,
                                    size: 16,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.pop(draggableContext),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Content
                        Expanded(
                          child: isLoadingAttendees
                              ? const Center(
                                  child: CupertinoActivityIndicator())
                              : (potentialFamilyAttendees.isEmpty &&
                                      currentUser == null)
                                  ? Center(
                                      child: Text(
                                        "No family members found to add.",
                                        style: AppTextStyle.getbodyStyle(
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      controller: scrollController,
                                      padding: const EdgeInsets.only(
                                        bottom: 100,
                                      ),
                                      children: [
                                        if (currentUser != null) // Add self
                                          CheckboxListTile(
                                            title: Text(
                                              "${currentUser.name} (Myself)",
                                              style: AppTextStyle.getbodyStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            secondary: CircleAvatar(
                                              backgroundColor: AppColors
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                              backgroundImage:
                                                  currentUser.profilePicUrl !=
                                                              null &&
                                                          currentUser
                                                              .profilePicUrl!
                                                              .isNotEmpty
                                                      ? NetworkImage(currentUser
                                                          .profilePicUrl!)
                                                      : null,
                                              child:
                                                  (currentUser.profilePicUrl ==
                                                                  null ||
                                                              currentUser
                                                                  .profilePicUrl!
                                                                  .isEmpty) &&
                                                          currentUser
                                                              .name.isNotEmpty
                                                      ? Text(
                                                          currentUser.name
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                          style: AppTextStyle
                                                              .getbodyStyle(
                                                            color: AppColors
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                            ),
                                            activeColor: AppColors.primaryColor,
                                            checkColor: Colors.white,
                                            value: state.selectedAttendees.any(
                                                (att) =>
                                                    att.userId ==
                                                    currentUser.uid),
                                            onChanged: (selected) {
                                              final selfAttendee =
                                                  AttendeeModel(
                                                      userId: currentUser.uid,
                                                      name: currentUser.name,
                                                      type: 'self',
                                                      status: 'going');
                                              if (selected == true) {
                                                optionsBloc.add(
                                                    AddOptionAttendee(
                                                        attendee:
                                                            selfAttendee));
                                              } else {
                                                optionsBloc.add(
                                                    RemoveOptionAttendee(
                                                        attendeeUserId:
                                                            currentUser.uid));
                                              }
                                              HapticFeedback.lightImpact();
                                            },
                                          ),
                                        if (potentialFamilyAttendees.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 16, 16, 8),
                                            child: Text(
                                              "Family Members",
                                              style: AppTextStyle.getTitleStyle(
                                                fontSize: 16,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ),
                                        ...potentialFamilyAttendees
                                            .map((member) {
                                          final isSelected = state
                                              .selectedAttendees
                                              .any((att) =>
                                                  att.userId == member.userId);
                                          return CheckboxListTile(
                                            title: Text(
                                              member.name,
                                              style: AppTextStyle.getbodyStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Text(
                                              member.relationship,
                                              style: AppTextStyle.getSmallStyle(
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                            secondary: CircleAvatar(
                                              backgroundColor: AppColors
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                              backgroundImage:
                                                  member.profilePicUrl !=
                                                              null &&
                                                          member.profilePicUrl!
                                                              .isNotEmpty
                                                      ? NetworkImage(
                                                          member.profilePicUrl!)
                                                      : null,
                                              child: (member.profilePicUrl ==
                                                              null ||
                                                          member.profilePicUrl!
                                                              .isEmpty) &&
                                                      member.name.isNotEmpty
                                                  ? Text(
                                                      member.name
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: AppTextStyle
                                                          .getbodyStyle(
                                                        color: AppColors
                                                            .primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            activeColor: AppColors.primaryColor,
                                            checkColor: Colors.white,
                                            value: isSelected,
                                            onChanged: (selected) {
                                              final attendeeModel =
                                                  AttendeeModel(
                                                      userId: member.userId!,
                                                      name: member.name,
                                                      type: 'family',
                                                      status: 'going');
                                              if (selected == true) {
                                                optionsBloc.add(
                                                    AddOptionAttendee(
                                                        attendee:
                                                            attendeeModel));
                                              } else {
                                                optionsBloc.add(
                                                    RemoveOptionAttendee(
                                                        attendeeUserId:
                                                            member.userId!));
                                              }
                                              HapticFeedback.lightImpact();
                                            },
                                          );
                                        }),
                                      ],
                                    ),
                        ),

                        // Bottom action
                        Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 16 +
                                MediaQuery.of(draggableContext).padding.bottom,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(draggableContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text("Done"),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Helper methods for date and time logic
  List<DateTime> _getAvailableDates(
    Map<String, dynamic> options,
    Map<String, OpeningHoursDay> operatingHours,
  ) {
    if (operatingHours.isEmpty) return [];

    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final allowedDaysOfWeek = (options['availableDaysOfWeek'] as List<dynamic>?)
        ?.map((e) => e.toString().toLowerCase())
        .toList();

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(date).toLowerCase();
      final openingHoursDay = operatingHours[dayName];
      if (openingHoursDay != null && openingHoursDay.isOpen) {
        if (allowedDaysOfWeek == null || allowedDaysOfWeek.contains(dayName)) {
          dates.add(date);
        }
      }
    }
    return dates;
  }

  List<Map<String, dynamic>> _generateTimeSlots(
    DateTime selectedDate,
    Map<String, dynamic> options,
    ServiceModel? service,
    Map<String, OpeningHoursDay> operatingHours,
    List<ReservationModel> existingReservations,
  ) {
    if (operatingHours.isEmpty) return [];

    final dayName = DateFormat('EEEE').format(selectedDate).toLowerCase();
    final openingHoursDay = operatingHours[dayName];

    if (openingHoursDay == null ||
        !openingHoursDay.isOpen ||
        openingHoursDay.startTime == null ||
        openingHoursDay.endTime == null) {
      return [];
    }

    final List<Map<String, dynamic>> slots = [];
    final int serviceDuration = service?.estimatedDurationMinutes ??
        (options['defaultDurationMinutes'] as int?) ??
        60;
    final now = DateTime.now();
    final bool isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    TimeOfDay currentTime = openingHoursDay.startTime!;
    while (currentTime.hour < openingHoursDay.endTime!.hour ||
        (currentTime.hour == openingHoursDay.endTime!.hour &&
            currentTime.minute < openingHoursDay.endTime!.minute)) {
      final slotStartDateTime = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, currentTime.hour, currentTime.minute);
      if (isToday &&
          slotStartDateTime.isBefore(now.add(const Duration(minutes: 5)))) {
        int totalMinutes =
            currentTime.hour * 60 + currentTime.minute + serviceDuration;
        currentTime =
            TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
        if (currentTime.hour >= 24) break;
        continue;
      }
      final slotEndDateTime =
          slotStartDateTime.add(Duration(minutes: serviceDuration));
      if (slotEndDateTime.hour > openingHoursDay.endTime!.hour ||
          (slotEndDateTime.hour == openingHoursDay.endTime!.hour &&
              slotEndDateTime.minute > openingHoursDay.endTime!.minute)) {
        break;
      }

      // Check existing reservations
      bool isReserved = existingReservations.any((reservation) {
        if (reservation.reservationStartTime == null) return false;
        final resStart = reservation.reservationStartTime!.toDate();
        final resEnd = reservation.endTime?.toDate() ??
            resStart.add(Duration(
                minutes: reservation.durationMinutes ?? serviceDuration));

        return slotStartDateTime.isBefore(resEnd) &&
            slotEndDateTime.isAfter(resStart);
      });

      slots.add({
        'time':
            "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}",
        'label': MaterialLocalizations.of(context).formatTimeOfDay(currentTime,
            alwaysUse24HourFormat:
                MediaQuery.of(context).alwaysUse24HourFormat),
        'isAvailable': !isReserved,
      });

      int totalMinutes =
          currentTime.hour * 60 + currentTime.minute + serviceDuration;
      currentTime =
          TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
      if (currentTime.hour >= 24) break;
    }

    return slots;
  }
}

extension OptionsStateHelper on OptionsConfigurationState {
  String get currencySymbol {
    final currencyCode =
        originalPlan?.currency ?? originalService?.currency ?? 'EGP';
    if (currencyCode.toUpperCase() == 'EGP') return 'EGP ';
    if (currencyCode.toUpperCase() == 'USD') return '\$';
    return '$currencyCode ';
  }
}
