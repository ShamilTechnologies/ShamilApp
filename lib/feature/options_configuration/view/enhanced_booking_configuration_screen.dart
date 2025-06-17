import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';

// Import partitioned components
import 'widgets/booking_header.dart';
import 'widgets/booking_step_content.dart';
import 'widgets/booking_navigation.dart';
import 'widgets/booking_background.dart';
import 'widgets/payment_success_dialog.dart';
import '../models/configuration_step.dart';

/// Enhanced Booking Configuration Screen - Main Entry Point
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

/// Main Booking Configuration View
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
  // Animation Controllers
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _progressAnimation;

  // Navigation
  late final PageController _pageController;
  int _currentStep = 0;

  // User Data
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserEmail;

  // Selection State
  ServiceModel? _selectedService;
  PlanModel? _selectedPlan;
  String _costSplitMethod = 'equal';

  // Configuration Steps
  late final List<ConfigurationStep> _steps;

  // Payment trigger callback
  VoidCallback? _paymentTrigger;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    _initializeUserData();
    _initializeSteps();
    _initializeAnimations();
    _initializePageController();
    _startAnimationSequence();
  }

  void _initializeUserData() {
    _getCurrentUserData().then((userData) {
      if (mounted) {
        setState(() {
          _currentUserId = userData['id'];
          _currentUserName = userData['name'];
          _currentUserEmail = userData['email'];
        });
      }
    });
  }

  void _initializeSteps() {
    _steps = ConfigurationStep.getDefaultSteps();
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
  }

  void _initializePageController() {
    final initialStep = (widget.service != null || widget.plan != null) ? 0 : 0;
    _currentStep = initialStep;
    _pageController = PageController(initialPage: initialStep);
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

  Future<Map<String, String?>> _getCurrentUserData() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      if (authState is LoginSuccessState) {
        final user = authState.user;
        return {
          'id': user.uid,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
        };
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }

    return {
      'id': 'guest_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Guest User',
      'email': 'guest@shamil.app',
    };
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
    return MultiBlocListener(
      listeners: [
        BlocListener<OptionsConfigurationBloc, OptionsConfigurationState>(
          listener: _handleStateChanges,
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: _handlePaymentStateChange,
        ),
      ],
      child: BlocConsumer<OptionsConfigurationBloc, OptionsConfigurationState>(
        listener: (context, state) {},
        builder: (context, state) => _buildMainContent(state),
      ),
    );
  }

  Widget _buildMainContent(OptionsConfigurationState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Container(
        decoration: BookingBackground.getMainGradient(),
        child: Column(
          children: [
            // Header with progress
            BookingHeader(
              provider: widget.provider,
              isPlan: widget.isPlan,
              currentStep: _currentStep,
              totalSteps: _steps.length,
              progressAnimation: _progressAnimation,
              steps: _steps,
              onClose: () => Navigator.of(context).pop(),
            ),

            // Main content area
            Expanded(
              child: Stack(
                children: [
                  BookingBackground.buildFloatingOrbs(),
                  BookingStepContent(
                    pageController: _pageController,
                    currentStep: _currentStep,
                    steps: _steps,
                    state: state,
                    provider: widget.provider,
                    service: widget.service,
                    plan: widget.plan,
                    contentAnimation: _contentAnimation,
                    costSplitMethod: _costSplitMethod,
                    userId: _currentUserId,
                    userName: _currentUserName,
                    userEmail: _currentUserEmail,
                    onStepChanged: (index) =>
                        setState(() => _currentStep = index),
                    onCostSplitChanged: (method) =>
                        setState(() => _costSplitMethod = method),
                    onPaymentSuccess: _handlePaymentSuccess,
                    onPaymentFailure: _handlePaymentFailure,
                    onPaymentTriggerReady: (trigger) =>
                        _paymentTrigger = trigger,
                  ),
                ],
              ),
            ),

            // Bottom navigation
            BookingNavigation(
              currentStep: _currentStep,
              totalSteps: _steps.length,
              canProceed: _canProceedToNextStep(state),
              onPrevious: _previousStep,
              onNext: _nextStep,
              onComplete: _currentStep == 2
                  ? _triggerPayment
                  : () => _processPayment(state),
            ),
          ],
        ),
      ),
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

  void _handlePaymentStateChange(BuildContext context, PaymentState state) {
    if (state is PaymentLoaded) {
      if (state.lastPaymentResponse?.isSuccessful == true) {
        _handlePaymentSuccess();
      } else if (state.lastPaymentResponse?.isFailed == true) {
        _handlePaymentFailure(state.lastPaymentResponse?.errorMessage);
      }
    } else if (state is PaymentError) {
      _handlePaymentFailure(state.message);
    }
  }

  void _handlePaymentSuccess() {
    PaymentSuccessDialog.show(
      context: context,
      onClose: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Go back
      },
    );
  }

  void _handlePaymentFailure(String? errorMessage) {
    PaymentSuccessDialog.show(
      context: context,
      isSuccess: false,
      title: 'Payment Failed',
      message: errorMessage ?? 'Something went wrong. Please try again.',
      onClose: () => Navigator.of(context).pop(),
    );
  }

  bool _canProceedToNextStep(OptionsConfigurationState state) {
    switch (_currentStep) {
      case 0: // Details Step
        return state.selectedDate != null &&
            state.selectedTime != null &&
            state.selectedTime!.isNotEmpty &&
            (state.includeUserInBooking || state.selectedAttendees.isNotEmpty);
      case 1: // Preferences Step
        return true; // Always allow proceeding
      case 2: // Payment Step
        return state.totalPrice > 0;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      final currentState = context.read<OptionsConfigurationBloc>().state;

      if (!_canProceedToNextStep(currentState)) {
        _showValidationError(currentState);
        return;
      }

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

  void _triggerPayment() {
    // Trigger the payment processing directly in the payment step
    HapticFeedback.mediumImpact();

    // Call the payment trigger if available
    if (_paymentTrigger != null) {
      _paymentTrigger!();
    } else {
      // Fallback to the old method if payment trigger is not set
      _processPayment(context.read<OptionsConfigurationBloc>().state);
    }
  }

  void _processPayment(OptionsConfigurationState state) {
    // Fallback method for booking confirmation without payment
    try {
      context
          .read<OptionsConfigurationBloc>()
          .add(const ConfirmConfiguration());
    } catch (e) {
      debugPrint('Error processing payment: $e');
      _handlePaymentFailure('Failed to process payment. Please try again.');
    }
  }

  void _showValidationError(OptionsConfigurationState state) {
    String message = 'Please complete all required fields';

    switch (_currentStep) {
      case 0:
        if (state.selectedDate == null) {
          message = 'Please select a booking date';
        } else if (state.selectedTime == null) {
          message = 'Please select a time slot';
        } else if (!state.includeUserInBooking &&
            state.selectedAttendees.isEmpty) {
          message = 'Please include yourself or add attendees';
        }
        break;
      case 2:
        if (state.totalPrice <= 0) {
          message = 'Invalid booking amount';
        }
        break;
    }

    HapticFeedback.lightImpact();
    showGlobalSnackBar(context, message, isError: true);
  }
}
