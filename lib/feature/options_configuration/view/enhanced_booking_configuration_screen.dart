import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';

// Import individual feature components
import 'components/provider_services_selector.dart';
import 'components/date_time_selector.dart';
import 'components/attendee_manager.dart';
import 'components/cost_split_manager.dart';
import 'components/venue_booking_manager.dart';
import 'components/payment_method_selector.dart';
import 'components/reminder_settings_manager.dart';
import 'components/sharing_settings_manager.dart';
import 'components/calendar_integration_manager.dart';
import 'components/notes_preferences_manager.dart';
import 'components/booking_summary_card.dart';
import 'components/progress_stepper.dart';

/// Enhanced Booking Configuration Screen with Complete Feature Set
class EnhancedBookingConfigurationScreen extends StatelessWidget {
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;

  const EnhancedBookingConfigurationScreen({
    super.key,
    required this.provider,
    this.service,
    this.plan,
  }) : assert(service != null || plan != null,
            'Either service or plan must be provided');

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OptionsConfigurationBloc(
        firebaseDataOrchestrator: FirebaseDataOrchestrator(),
      )..add(InitializeOptionsConfiguration(
          providerId: provider.id,
          plan: plan,
          service: service,
        )),
      child: EnhancedBookingConfigurationView(
        provider: provider,
        isPlan: plan != null,
        plan: plan,
        service: service,
      ),
    );
  }
}

class EnhancedBookingConfigurationView extends StatefulWidget {
  final ServiceProviderModel provider;
  final bool isPlan;
  final PlanModel? plan;
  final ServiceModel? service;

  const EnhancedBookingConfigurationView({
    super.key,
    required this.provider,
    required this.isPlan,
    this.plan,
    this.service,
  });

  @override
  State<EnhancedBookingConfigurationView> createState() =>
      _EnhancedBookingConfigurationViewState();
}

class _EnhancedBookingConfigurationViewState
    extends State<EnhancedBookingConfigurationView>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _progressController;

  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  late final PageController _pageController;
  int _currentStep = 0;

  // Service/Plan selection state
  ServiceModel? _selectedService;
  PlanModel? _selectedPlan;

  final List<ConfigurationStep> _steps = [
    ConfigurationStep(
      id: 'service',
      title: 'Select Service',
      subtitle: 'Choose what you want to book',
      icon: CupertinoIcons.bag_fill,
      color: AppColors.primaryColor,
    ),
    ConfigurationStep(
      id: 'datetime',
      title: 'Date & Time',
      subtitle: 'When would you like to book?',
      icon: CupertinoIcons.calendar,
      color: AppColors.cyanColor,
    ),
    ConfigurationStep(
      id: 'attendees',
      title: 'Attendees',
      subtitle: 'Who will be joining?',
      icon: CupertinoIcons.person_2_fill,
      color: AppColors.tealColor,
    ),
    ConfigurationStep(
      id: 'preferences',
      title: 'Preferences',
      subtitle: 'Customize your experience',
      icon: CupertinoIcons.slider_horizontal_3,
      color: AppColors.cyanColor,
    ),
    ConfigurationStep(
      id: 'payment',
      title: 'Payment',
      subtitle: 'Review and pay',
      icon: CupertinoIcons.creditcard_fill,
      color: AppColors.greenColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();

    // Initialize with provided service/plan
    if (widget.service != null) {
      _selectedService = widget.service;
      _currentStep = 1; // Skip service selection step
    } else if (widget.plan != null) {
      _selectedPlan = widget.plan;
      _currentStep = 1; // Skip service selection step
    }

    // Initialize PageController with correct initial page
    _pageController = PageController(initialPage: _currentStep);
  }

  void _initializeAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutQuart,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_contentAnimation);
  }

  void _startAnimationSequence() {
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OptionsConfigurationBloc, OptionsConfigurationState>(
      listener: _handleStateChanges,
      builder: (context, state) => _buildMainContent(context, state),
    );
  }

  void _handleStateChanges(
      BuildContext context, OptionsConfigurationState state) {
    if (state.errorMessage != null) {
      showGlobalSnackBar(context, state.errorMessage!, isError: true);
    } else if (state is OptionsConfigurationConfirmed) {
      showGlobalSnackBar(context, "Booking confirmed successfully!");
      Navigator.of(context).pop();
    }
  }

  Widget _buildMainContent(
      BuildContext context, OptionsConfigurationState state) {
    if (state is OptionsConfigurationInitial) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepSpaceNavy,
              AppColors.deepSpaceNavy.withValues(alpha: 0.8),
              AppColors.primaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(state),
              _buildProgressIndicator(state),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _contentAnimation,
                    child: _buildStepContent(state),
                  ),
                ),
              ),
              _buildBottomNavigation(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(OptionsConfigurationState state) {
    return FadeTransition(
      opacity: _heroAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: AppColors.lightText,
                  size: 20,
                ),
              ),
            ),
            const Gap(16),
            Expanded(child: _buildHeaderInfo(state)),
            const Gap(16),
            _buildPriceDisplay(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(OptionsConfigurationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.itemName,
          style: app_text_style.getHeadlineTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.tealColor],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isPlan ? 'Plan' : 'Service',
                style: app_text_style.getSmallStyle(
                  color: AppColors.lightText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(8),
            Text(
              'Step ${_currentStep + 1} of ${_steps.length}',
              style: app_text_style.getSmallStyle(
                color: AppColors.lightText.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceDisplay(OptionsConfigurationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenColor, AppColors.tealColor],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'EGP ${state.totalPrice.toStringAsFixed(0)}',
        style: app_text_style.getTitleStyle(
          color: AppColors.lightText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(OptionsConfigurationState state) {
    return FadeTransition(
      opacity: _progressAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ProgressStepper(
          steps: _steps,
          currentStep: _currentStep,
          state: state,
        ),
      ),
    );
  }

  Widget _buildStepContent(OptionsConfigurationState state) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentStep = index),
      itemCount: _steps.length,
      itemBuilder: (context, index) => _buildStep(index, state),
    );
  }

  Widget _buildStep(int index, OptionsConfigurationState state) {
    switch (index) {
      case 0:
        return _buildServiceSelectionStep(state);
      case 1:
        return _buildDateTimeStep(state);
      case 2:
        return _buildAttendeesStep(state);
      case 3:
        return _buildPreferencesStep(state);
      case 4:
        return _buildPaymentStep(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildServiceSelectionStep(OptionsConfigurationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Choose Your Service',
            'Select from ${widget.provider.businessName}\'s available services and plans',
          ),
          const Gap(24),
          ProviderServicesSelector(
            provider: widget.provider,
            selectedService: _selectedService,
            selectedPlan: _selectedPlan,
            onServiceSelected: (service) {
              setState(() {
                _selectedService = service;
                _selectedPlan = null; // Clear plan when service is selected
              });

              // Update the BLoC with the selected service
              if (service != null) {
                context.read<OptionsConfigurationBloc>().add(
                      InitializeOptionsConfiguration(
                        providerId: widget.provider.id,
                        service: service,
                        plan: null,
                      ),
                    );
              }
            },
            onPlanSelected: (plan) {
              setState(() {
                _selectedPlan = plan;
                _selectedService = null; // Clear service when plan is selected
              });

              // Update the BLoC with the selected plan
              if (plan != null) {
                context.read<OptionsConfigurationBloc>().add(
                      InitializeOptionsConfiguration(
                        providerId: widget.provider.id,
                        service: null,
                        plan: plan,
                      ),
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep(OptionsConfigurationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Select Date & Time',
            'Choose when you\'d like to book this ${widget.isPlan ? 'plan' : 'service'}',
          ),
          const Gap(24),
          DateTimeSelector(
            state: state,
            provider: widget.provider,
            service: widget.service,
            plan: widget.plan,
            onDateChanged: (date) => context
                .read<OptionsConfigurationBloc>()
                .add(DateSelected(selectedDate: date)),
            onTimeChanged: (time) => context
                .read<OptionsConfigurationBloc>()
                .add(TimeSelected(selectedTime: time)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesStep(OptionsConfigurationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Manage Attendees',
            'Add friends, family members, or other attendees',
          ),
          const Gap(24),
          AttendeeManager(
            state: state,
            onAttendeeAdded: (attendee) => context
                .read<OptionsConfigurationBloc>()
                .add(AddOptionAttendee(attendee: attendee)),
            onAttendeeRemoved: (attendeeId) => context
                .read<OptionsConfigurationBloc>()
                .add(RemoveOptionAttendee(attendeeUserId: attendeeId)),
            onAttendeeUpdated: (attendee) => context
                .read<OptionsConfigurationBloc>()
                .add(AddOptionAttendee(attendee: attendee)),
          ),
          const Gap(24),
          CostSplitManager(
            state: state,
            onCostSplitChanged: (config) => context
                .read<OptionsConfigurationBloc>()
                .add(ChangeCostSplitType(splitType: config.type)),
          ),
          if (_shouldShowVenueBooking(state)) ...[
            const Gap(24),
            VenueBookingManager(
              state: state,
              onVenueConfigChanged: (config) => context
                  .read<OptionsConfigurationBloc>()
                  .add(ChangeVenueBookingType(bookingType: config.type)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(OptionsConfigurationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Customize Experience',
            'Set your sharing preferences and add to calendar',
          ),
          const Gap(24),
          NotesPreferencesManager(
            state: state,
            onNotesChanged: (notes) => context
                .read<OptionsConfigurationBloc>()
                .add(NotesUpdated(notes: notes)),
          ),
          const Gap(24),
          SharingSettingsManager(
            state: state,
            onSharingSettingsChanged: (enabled, shareWithAttendees, emails) =>
                context.read<OptionsConfigurationBloc>().add(
                      UpdateSharingSettings(
                          enableSharing: enabled,
                          shareWithAttendees: shareWithAttendees,
                          additionalEmails: emails),
                    ),
          ),
          const Gap(24),
          CalendarIntegrationManager(
            state: state,
            provider: widget.provider,
            service: widget.service,
            plan: widget.plan,
            onCalendarIntegrationChanged: (addToCalendar) => context
                .read<OptionsConfigurationBloc>()
                .add(ToggleAddToCalendar(addToCalendar: addToCalendar)),
            userId: 'guest_user', // Would come from user session
            userName: 'Guest User', // Would come from user session
            userEmail: 'guest@shamil.app', // Would come from user session
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(OptionsConfigurationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Review & Pay',
            'Confirm your booking details and complete payment',
          ),
          const Gap(24),
          BookingSummaryCard(
            state: state,
            provider: widget.provider,
            service: widget.service,
            plan: widget.plan,
            onEditBooking: () => setState(() => _currentStep = 0),
          ),
          const Gap(24),
          PaymentMethodSelector(
            state: state,
            provider: widget.provider,
            service: widget.service,
            plan: widget.plan,
            onPaymentMethodChanged: (method) => context
                .read<OptionsConfigurationBloc>()
                .add(UpdatePaymentMethod(paymentMethod: method)),
            onPaymentCompleted: (response) {
              if (response.status == PaymentStatus.completed ||
                  response.status == PaymentStatus.pending) {
                _completeBookingWithPayment(context, state, response);
              } else {
                _showPaymentErrorDialog(context, response.errorMessage);
              }
            },
            userId: 'guest_user', // Would come from user session
            userName: 'Guest User', // Would come from user session
            userEmail: 'guest@shamil.app', // Would come from user session
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: app_text_style.getHeadlineTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
        ),
        const Gap(8),
        Text(
          subtitle,
          style: app_text_style.getbodyStyle(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(OptionsConfigurationState state) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _steps.length - 1;
    final canProceed = _canProceedToNextStep(state);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.deepSpaceNavy.withValues(alpha: 0.9),
            AppColors.deepSpaceNavy,
          ],
        ),
      ),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: _buildNavigationButton(
                'Previous',
                CupertinoIcons.chevron_back,
                false,
                () => _previousStep(),
              ),
            ),
          if (!isFirstStep) const Gap(16),
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: _buildNavigationButton(
              isLastStep ? 'Complete Booking' : 'Next',
              isLastStep
                  ? CupertinoIcons.check_mark
                  : CupertinoIcons.chevron_forward,
              true,
              canProceed
                  ? (isLastStep
                      ? () => _completeBooking(state)
                      : () => _nextStep())
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    String text,
    IconData icon,
    bool isPrimary,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? (onPressed != null
                  ? AppColors.primaryColor
                  : Colors.grey.shade600)
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor: AppColors.lightText,
          elevation: isPrimary ? 8 : 0,
          shadowColor:
              isPrimary ? AppColors.primaryColor.withValues(alpha: 0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: !isPrimary
                ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (text == 'Previous') ...[
              Icon(icon, size: 18),
              const Gap(8),
            ],
            Text(
              text,
              style: app_text_style.getTitleStyle(
                color: AppColors.lightText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (text != 'Previous') ...[
              const Gap(8),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const Gap(24),
            Text(
              'Loading configuration...',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep(OptionsConfigurationState state) {
    switch (_currentStep) {
      case 0: // Service Selection
        return _selectedService != null || _selectedPlan != null;
      case 1: // Date & Time
        return state.selectedDate != null && state.selectedTime != null;
      case 2: // Attendees
        return true; // Can always proceed from attendees
      case 3: // Preferences
        return true; // Always can proceed from preferences
      case 4: // Payment
        return state.paymentMethod.isNotEmpty;
      default:
        return false;
    }
  }

  bool _shouldShowVenueBooking(OptionsConfigurationState state) {
    return state.optionsDefinition?['venueBooking'] == true ||
        state.optionsDefinition?['allowVenueBooking'] == true;
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeBooking(OptionsConfigurationState state) {
    HapticFeedback.mediumImpact();
    context.read<OptionsConfigurationBloc>().add(const ConfirmConfiguration());
  }

  void _completeBookingWithPayment(
    BuildContext context,
    OptionsConfigurationState state,
    PaymentResponse paymentResponse,
  ) {
    HapticFeedback.mediumImpact();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment ${paymentResponse.status == PaymentStatus.completed ? 'completed' : 'initiated'} successfully!',
        ),
        backgroundColor: AppColors.greenColor,
      ),
    );

    // Complete the booking
    context.read<OptionsConfigurationBloc>().add(const ConfirmConfiguration());
  }

  void _showPaymentErrorDialog(BuildContext context, String? errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: Text(
          'Payment Error',
          style: app_text_style.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          errorMessage ?? 'Payment failed. Please try again.',
          style: app_text_style.getbodyStyle(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: app_text_style.getbodyStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfigurationStep {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ConfigurationStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
