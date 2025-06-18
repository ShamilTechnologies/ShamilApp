import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
// Removed: Premium card details sheet no longer used - using direct Stripe payment sheet
// import 'package:shamil_mobile_app/core/payment/ui/premium_card_details_sheet.dart';
import 'package:shamil_mobile_app/core/payment/gateways/stripe/stripe_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:shamil_mobile_app/core/utils/colors.dart';
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
                    onPaymentMethodChanged: (method) {
                      // Update payment method in bloc state
                      context.read<OptionsConfigurationBloc>().add(
                            UpdatePaymentMethod(paymentMethod: method),
                          );
                    },
                  ),
                ],
              ),
            ),

            // Bottom navigation - Complete booking handles payment + reservation
            BookingNavigation(
              currentStep: _currentStep,
              totalSteps: _steps.length,
              canProceed: _canProceedToNextStep(state),
              onPrevious: _previousStep,
              onNext: _nextStep,
              onComplete: _currentStep == 2
                  ? () => _completeBookingWithPayment(state)
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
    if (!mounted) return;
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

  Future<void> _completeBookingWithPayment(
      OptionsConfigurationState state) async {
    try {
      HapticFeedback.mediumImpact();

      // Show loading state
      if (!mounted) return;
      showGlobalSnackBar(
          context, 'Processing payment and creating reservation...');

      // Step 1: Process Payment
      final paymentSuccess = await _processPaymentFlow(state);

      if (!mounted) return;
      if (!paymentSuccess) {
        showGlobalSnackBar(context, 'Payment failed. Please try again.',
            isError: true);
        return;
      }

      // Step 2: Create Reservation
      if (!mounted) return;
      showGlobalSnackBar(context, 'Creating your reservation...');

      await _createReservation(state);

      // Step 3: Show Success and Navigate
      if (!mounted) return;
      showGlobalSnackBar(context, 'Reservation created successfully!');
      _handleBookingSuccess();
    } catch (e) {
      debugPrint('Error completing booking: $e');
      if (!mounted) return;
      _handlePaymentFailure('Failed to complete booking. Please try again.');
    }
  }

  Future<bool> _processPaymentFlow(OptionsConfigurationState state) async {
    try {
      // Get the selected payment method from the payment step
      final selectedPaymentMethod =
          state.paymentMethod.isNotEmpty ? state.paymentMethod : 'stripeSheet';

      if (selectedPaymentMethod == 'cash') {
        // Cash payment - no processing needed
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }

      // Process payment using PaymentOrchestrator for other methods
      final paymentRequest = PaymentRequest(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        amount: PaymentAmount(
          amount: state.totalPrice,
          currency: Currency.egp,
        ),
        customer: PaymentCustomer(
          id: _currentUserId ?? 'guest_user',
          name: _currentUserName ?? 'Guest User',
          email: _currentUserEmail ?? 'guest@shamil.app',
        ),
        method: _getPaymentMethodFromSelection(selectedPaymentMethod),
        description:
            'Booking payment for ${widget.service?.name ?? widget.plan?.name ?? 'service'}',
        gateway: PaymentGateway.stripe,
        createdAt: DateTime.now(),
        metadata: {
          'provider_id': widget.provider.id,
          'service_id': widget.service?.id ?? '',
          'plan_id': widget.plan?.id ?? '',
          'booking_date': state.selectedDate?.toIso8601String() ?? '',
          'booking_time': state.selectedTime ?? '',
          'attendees_count': state.selectedAttendees.length.toString(),
          'payment_method': selectedPaymentMethod,
        },
      );

      // Show payment sheet for card payments
      if (!mounted) return false;

      // Process payment directly through Stripe Payment Sheet with dark theme
      final response = await _processDirectStripePayment(paymentRequest);

      return response != null && response.isSuccessful;
    } catch (e) {
      debugPrint('Payment processing error: $e');
      return false;
    }
  }

  PaymentMethod _getPaymentMethodFromSelection(String selectedMethod) {
    switch (selectedMethod) {
      case 'stripeSheet':
        return PaymentMethod.creditCard;
      case 'applePay':
        return PaymentMethod.applePay;
      case 'googlePay':
        return PaymentMethod.googlePay;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.creditCard;
    }
  }

  /// Process payment directly through Stripe Payment Sheet with dark theme
  Future<PaymentResponse?> _processDirectStripePayment(
      PaymentRequest paymentRequest) async {
    try {
      debugPrint('🚀 Starting direct Stripe payment process...');

      // Initialize Stripe Service
      final stripeService = StripeService();
      await stripeService.initialize();

      // Create Payment Intent
      final paymentIntent = await stripeService.createPaymentIntent(
        amount: paymentRequest.amount.amount,
        currency: paymentRequest.amount.currency,
        customer: paymentRequest.customer,
        description: paymentRequest.description,
        metadata: paymentRequest.metadata,
      );

      if (!mounted) return null;
      debugPrint('✅ Payment Intent created: ${paymentIntent['id']}');

      // Initialize Stripe Payment Sheet with dark theme
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Shamil App',
          customerId: paymentRequest.customer.id,
          style: ThemeMode.dark,
          appearance: stripe.PaymentSheetAppearance(
            colors: stripe.PaymentSheetAppearanceColors(
              primary: AppColors.premiumBlue,
              background: const Color(0xFF0A0E1A),
              componentBackground: AppColors.premiumBlue.withOpacity(0.1),
              componentBorder: Colors.white.withOpacity(0.1),
              componentDivider: Colors.white.withOpacity(0.1),
              primaryText: Colors.white,
              secondaryText: Colors.white.withOpacity(0.7),
              componentText: Colors.white,
              placeholderText: Colors.white.withOpacity(0.5),
            ),
            shapes: stripe.PaymentSheetShape(
              borderRadius: 8,
              borderWidth: 1,
            ),
            primaryButton: stripe.PaymentSheetPrimaryButtonAppearance(
              colors: stripe.PaymentSheetPrimaryButtonTheme(
                light: stripe.PaymentSheetPrimaryButtonThemeColors(
                  background: AppColors.premiumBlue,
                  text: Colors.white,
                  border: AppColors.premiumBlue,
                ),
                dark: stripe.PaymentSheetPrimaryButtonThemeColors(
                  background: AppColors.premiumBlue,
                  text: Colors.white,
                  border: AppColors.premiumBlue,
                ),
              ),
            ),
          ),
        ),
      );

      if (!mounted) return null;
      debugPrint('💳 Presenting Stripe Payment Sheet...');

      // Present the Stripe Payment Sheet
      await stripe.Stripe.instance.presentPaymentSheet();

      if (!mounted) return null;
      debugPrint('✅ Payment Sheet completed successfully');

      // Small delay to allow Stripe to process the payment
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify payment completion
      final verificationResponse = await stripeService.verifyPayment(
        paymentIntentId: paymentIntent['id'],
      );

      if (!mounted) return null;

      if (verificationResponse.isConfirmedByGateway) {
        debugPrint('🎉 Payment verification successful!');
        debugPrint('💳 Payment Status: ${verificationResponse.status.name}');
        debugPrint('💰 Payment Amount: ${verificationResponse.amount}');
        debugPrint('🏦 Payment Gateway: ${verificationResponse.gateway.name}');

        // Create response
        final response = PaymentResponse(
          id: verificationResponse.id,
          status: verificationResponse.status,
          amount: verificationResponse.amount,
          currency: verificationResponse.currency,
          gateway: verificationResponse.gateway,
          gatewayResponse: verificationResponse.gatewayResponse,
          metadata: {
            ...?verificationResponse.metadata,
            'payment_intent_id': paymentIntent['id'],
            'payment_flow': 'direct_stripe_sheet_dark_theme',
            'checkout_completed': 'true',
          },
          timestamp: verificationResponse.timestamp,
        );

        return response;
      } else {
        debugPrint('❌ Payment verification failed');
        debugPrint('💳 Payment Status: ${verificationResponse.status.name}');
        debugPrint(
            '🔍 Gateway Response: ${verificationResponse.gatewayResponse}');
        throw Exception(
            'Payment verification failed: ${verificationResponse.status.name}');
      }
    } on stripe.StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.localizedMessage}');
      return null;
    } catch (e) {
      debugPrint('❌ Payment processing error: $e');
      return null;
    }
  }

  Future<void> _createReservation(OptionsConfigurationState state) async {
    StreamSubscription? subscription;

    try {
      // Create the reservation using the bloc with payment success flag
      if (!mounted) return;
      debugPrint('📝 Creating reservation after successful payment...');

      // Use a Completer to wait for the reservation to complete
      final completer = Completer<void>();

      // Listen to bloc state changes with proper error handling
      subscription = context.read<OptionsConfigurationBloc>().stream.listen(
        (newState) {
          // Always check mounted state first
          if (!mounted) {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                  'Widget unmounted during reservation creation');
            }
            return;
          }

          // Check if reservation was successfully created
          if (newState is OptionsConfigurationConfirmed) {
            debugPrint(
                '✅ Reservation confirmed with ID: ${newState.confirmationId}');
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }

          // Check for errors
          if (newState.errorMessage != null &&
              newState.errorMessage!.isNotEmpty) {
            debugPrint('❌ Reservation error: ${newState.errorMessage}');
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                  'Reservation failed: ${newState.errorMessage}');
            }
            return;
          }
        },
        onError: (error) {
          debugPrint('❌ Stream error during reservation: $error');
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError('Stream error: $error');
          }
        },
        onDone: () {
          debugPrint('📡 Reservation stream completed');
        },
      );

      // Trigger the reservation creation only if still mounted
      if (!mounted) {
        subscription?.cancel();
        return;
      }

      context
          .read<OptionsConfigurationBloc>()
          .add(const ConfirmConfiguration(paymentSuccessful: true));

      // Wait for completion with timeout
      try {
        await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            subscription?.cancel();
            throw Exception('Reservation creation timed out after 30 seconds');
          },
        );
      } catch (e) {
        subscription?.cancel();
        rethrow;
      }

      debugPrint('✅ Reservation creation completed successfully');
    } catch (e) {
      debugPrint('❌ Error creating reservation: $e');
      subscription?.cancel();
      throw Exception('Failed to create reservation: ${e.toString()}');
    } finally {
      // Ensure subscription is always cancelled
      subscription?.cancel();
    }
  }

  void _handleBookingSuccess() {
    if (!mounted) return;

    final currentState = context.read<OptionsConfigurationBloc>().state;
    String confirmationMessage =
        'Your reservation has been successfully created and payment processed.';

    // Add confirmation ID if available
    if (currentState is OptionsConfigurationConfirmed &&
        currentState.confirmationId != null &&
        currentState.confirmationId!.isNotEmpty) {
      confirmationMessage +=
          '\n\nConfirmation ID: ${currentState.confirmationId}';
    }

    // Use a post-frame callback to ensure the widget is still mounted when showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      PaymentSuccessDialog.show(
        context: context,
        title: 'Booking Confirmed!',
        message: confirmationMessage,
        onClose: () {
          // Double-check mounted state before navigation
          if (!mounted) return;

          // Navigate to home using multiple strategies for reliability
          _navigateToHome();
        },
      );
    });
  }

  void _navigateToHome() {
    if (!mounted) return;

    debugPrint('🏠 Attempting to navigate to home...');

    try {
      // Strategy 1: Use root navigator to pop until first route
      debugPrint('🏠 Strategy 1: Root navigator popUntil first route');
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      debugPrint('🏠 Strategy 1: Success!');
    } catch (e) {
      debugPrint('🏠 Strategy 1 failed: $e');

      try {
        // Strategy 2: Regular navigator popUntil first route
        debugPrint('🏠 Strategy 2: Regular navigator popUntil first route');
        Navigator.of(context).popUntil((route) => route.isFirst);
        debugPrint('🏠 Strategy 2: Success!');
      } catch (e2) {
        debugPrint('🏠 Strategy 2 failed: $e2');

        try {
          // Strategy 3: Pop to named route if available
          debugPrint('🏠 Strategy 3: popAndPushNamed');
          Navigator.of(context).popAndPushNamed('/');
          debugPrint('🏠 Strategy 3: Success!');
        } catch (e3) {
          debugPrint('🏠 Strategy 3 failed: $e3');

          try {
            // Strategy 4: Manual pop with safety check
            debugPrint('🏠 Strategy 4: Manual pop loop');
            while (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            debugPrint('🏠 Strategy 4: Success!');
          } catch (e4) {
            debugPrint('🏠 Strategy 4 failed: $e4');

            // Strategy 5: Force navigation to home (last resort)
            debugPrint('🏠 Strategy 5: pushNamedAndRemoveUntil');
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
            debugPrint('🏠 Strategy 5: Success!');
          }
        }
      }
    }
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;
    PaymentSuccessDialog.show(
      context: context,
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close dialog
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Go back
        }
      },
    );
  }

  void _handlePaymentFailure(String? errorMessage) {
    if (!mounted) return;
    PaymentSuccessDialog.show(
      context: context,
      isSuccess: false,
      title: 'Payment Failed',
      message: errorMessage ?? 'Something went wrong. Please try again.',
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
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
    if (!mounted) return;
    if (_currentStep < _steps.length - 1) {
      final currentState = context.read<OptionsConfigurationBloc>().state;

      if (!_canProceedToNextStep(currentState)) {
        _showValidationError(currentState);
        return;
      }

      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (!mounted) return;
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
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
      if (!mounted) return;
      context
          .read<OptionsConfigurationBloc>()
          .add(const ConfirmConfiguration(paymentSuccessful: true));
    } catch (e) {
      debugPrint('Error processing payment: $e');
      if (!mounted) return;
      _handlePaymentFailure('Failed to process payment. Please try again.');
    }
  }

  void _showValidationError(OptionsConfigurationState state) {
    if (!mounted) return;

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
