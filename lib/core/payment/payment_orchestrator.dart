import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/text_style.dart' as app_text_style;
import 'models/payment_models.dart';
import 'widgets/stripe_payment_widget.dart';
import 'ui/stripe_payment_widget.dart';
import 'gateways/stripe/stripe_service.dart';

/// Modern payment orchestrator that provides a unified payment experience
/// across the entire app with consistent UI/UX and smooth animations
class PaymentOrchestrator {
  static final PaymentOrchestrator _instance = PaymentOrchestrator._internal();
  factory PaymentOrchestrator() => _instance;
  PaymentOrchestrator._internal();

  final StripeService _stripeService = StripeService();

  /// Show premium payment screen with high-end fintech UI/UX
  static Future<PaymentResponse?> showPaymentScreen({
    required BuildContext context,
    required PaymentRequest paymentRequest,
    String? title,
    Widget? headerIcon,
    bool showSavedMethods = true,
    String? customerId,
    List<PaymentSummaryItem>? additionalItems,
  }) async {
    HapticFeedback.mediumImpact();

    return await Navigator.of(context).push<PaymentResponse>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E1A),
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.tealColor.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Premium Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title ?? 'Complete Payment',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Secure payment powered by Stripe',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.tealColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Premium Payment Widget
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: StripePaymentWidget(
            paymentRequest: paymentRequest,
                          onPaymentComplete: (response) {
                            Navigator.of(context).pop(response);
                          },
                          onError: (error) {
                            debugPrint('Payment error: $error');
                          },
            showSavedMethods: showSavedMethods,
            customerId: customerId,
                          onCancel: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutExpo;

          var slideAnimation = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          var scaleAnimation = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));

          return SlideTransition(
            position: animation.drive(slideAnimation),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
              child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show payment bottom sheet for quick payments
  static Future<PaymentResponse?> showPaymentBottomSheet({
    required BuildContext context,
    required PaymentRequest paymentRequest,
    bool showSavedMethods = true,
    String? customerId,
  }) async {
    HapticFeedback.lightImpact();

    return await showModalBottomSheet<PaymentResponse>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppColors.mainBackgroundGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: ModernPaymentWidget(
              paymentRequest: paymentRequest,
              onPaymentComplete: (response) {
                Navigator.of(context).pop(response);
              },
              onError: (error) {
                // Handle error
                debugPrint('Payment error: $error');
              },
              showSavedMethods: showSavedMethods,
              customerId: customerId,
              onCancel: () => Navigator.of(context).pop(),
            ),
          );
        },
      ),
    );
  }

  /// Show payment success screen with celebration animation
  static Future<void> showPaymentSuccess({
    required BuildContext context,
    required PaymentResponse paymentResponse,
    String? successMessage,
    Widget? customIcon,
    VoidCallback? onContinue,
  }) async {
    HapticFeedback.heavyImpact();

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return PaymentSuccessWidget(
            paymentResponse: paymentResponse,
            successMessage: successMessage,
            customIcon: customIcon,
            onContinue: onContinue ?? () => Navigator.of(context).pop(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ));

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
        fullscreenDialog: true,
      ),
    );
  }

  /// Create a payment request for reservations
  static PaymentRequest createReservationPayment({
    required String reservationId,
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    String? description,
    Map<String, String>? metadata,
    double? taxAmount,
    double? discountAmount,
  }) {
    return PaymentRequest(
      id: reservationId,
      amount: PaymentAmount(
        amount: amount,
        currency: currency,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
      ),
      customer: customer,
      method: PaymentMethod.creditCard,
      gateway: PaymentGateway.stripe,
      description: description ?? 'Reservation Payment',
      createdAt: DateTime.now(),
      metadata: {
        'type': 'reservation',
        'reservation_id': reservationId,
        ...?metadata,
      },
    );
  }

  /// Create a payment request for service bookings
  static PaymentRequest createServicePayment({
    required String serviceId,
    required String providerId,
    required double amount,
    required Currency currency,
    required PaymentCustomer customer,
    String? serviceName,
    Map<String, String>? metadata,
    double? taxAmount,
    double? discountAmount,
  }) {
    return PaymentRequest(
      id: '${serviceId}_${DateTime.now().millisecondsSinceEpoch}',
      amount: PaymentAmount(
        amount: amount,
        currency: currency,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
      ),
      customer: customer,
      method: PaymentMethod.creditCard,
      gateway: PaymentGateway.stripe,
      description:
          serviceName != null ? '$serviceName Payment' : 'Service Payment',
      createdAt: DateTime.now(),
      metadata: {
        'type': 'service',
        'service_id': serviceId,
        'provider_id': providerId,
        ...?metadata,
      },
    );
  }

  /// Process payment with error handling and retry logic
  static Future<PaymentResponse> processPayment({
    required PaymentRequest paymentRequest,
    int maxRetries = 3,
  }) async {
    final orchestrator = PaymentOrchestrator();

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response =
            await orchestrator._stripeService.createReservationPayment(
          reservationId: paymentRequest.id,
          amount: paymentRequest.amount.amount,
          currency: paymentRequest.amount.currency,
          customer: paymentRequest.customer,
          description: paymentRequest.description,
          metadata: paymentRequest.metadata,
        );

        return response;
      } catch (e) {
        debugPrint('Payment attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          rethrow;
        }

        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw Exception('Payment failed after $maxRetries attempts');
  }

  /// Initialize payment orchestrator
  Future<void> initialize() async {
    await _stripeService.initialize();
  }

  /// Verify payment status
  Future<PaymentResponse> verifyPayment(String paymentId) async {
    return await _stripeService.verifyPayment(paymentIntentId: paymentId);
  }

  /// Get payment history for a customer
  Future<List<PaymentResponse>> getPaymentHistory({
    required String customerId,
    int limit = 50,
  }) async {
    // For now, return empty list - implement based on your backend
    return [];
  }

  /// Get payment statistics for a customer
  Future<Map<String, dynamic>> getPaymentStatistics({
    required String customerId,
  }) async {
    // For now, return empty map - implement based on your backend
    return {};
  }
}

/// Modern payment screen with full-screen experience
class ModernPaymentScreen extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final String? title;
  final Widget? headerIcon;
  final bool showSavedMethods;
  final String? customerId;
  final List<PaymentSummaryItem>? additionalItems;

  const ModernPaymentScreen({
    super.key,
    required this.paymentRequest,
    this.title,
    this.headerIcon,
    this.showSavedMethods = true,
    this.customerId,
    this.additionalItems,
  });

  @override
  State<ModernPaymentScreen> createState() => _ModernPaymentScreenState();
}

class _ModernPaymentScreenState extends State<ModernPaymentScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    ));

    _backgroundController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppColors.mainBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom header
                  _buildHeader(),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Payment summary (collapsible)
                          if (_showSummary) ...[
                            PaymentSummaryCard(
                              paymentRequest: widget.paymentRequest,
                              additionalItems: widget.additionalItems,
                              footer: _buildSummaryToggle(),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            _buildCollapsedSummary(),
                            const SizedBox(height: 16),
                          ],

                          // Payment widget
                          ModernPaymentWidget(
                            paymentRequest: widget.paymentRequest,
                            onPaymentComplete: _handlePaymentComplete,
                            onError: _handlePaymentError,
                            showSavedMethods: widget.showSavedMethods,
                            customerId: widget.customerId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.chevron_back,
                size: 20,
                color: AppColors.lightText.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (widget.headerIcon != null) ...[
            widget.headerIcon!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.title ?? 'Payment',
              style: app_text_style.getHeadlineTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showSummary = !_showSummary),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hide Details',
              style: app_text_style.getSmallStyle(
                fontSize: 12,
                color: AppColors.lightText.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_up,
              size: 12,
              color: AppColors.lightText.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSummary() {
    return GestureDetector(
      onTap: () => setState(() => _showSummary = true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total: ${widget.paymentRequest.amount.currency.symbol}${widget.paymentRequest.amount.totalAmount.toStringAsFixed(2)}',
                style: app_text_style.getTitleStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppColors.lightText.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentComplete(PaymentResponse response) {
    Navigator.of(context).pop(response);

    // Show success screen
    PaymentOrchestrator.showPaymentSuccess(
      context: context,
      paymentResponse: response,
      onContinue: () => Navigator.of(context).pop(),
    );
  }

  void _handlePaymentError(String error) {
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Payment configuration for different app contexts
class PaymentConfig {
  static const String reservationTitle = 'Complete Reservation';
  static const String serviceTitle = 'Pay for Service';
  static const String subscriptionTitle = 'Subscribe';

  static Widget get reservationIcon => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.calendar,
          color: Colors.white,
          size: 18,
        ),
      );

  static Widget get serviceIcon => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.tealColor,
              AppColors.tealColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.star_fill,
          color: Colors.white,
          size: 18,
        ),
      );

  static Widget get subscriptionIcon => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purpleColor,
              AppColors.purpleColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.star_circle_fill,
          color: Colors.white,
          size: 18,
        ),
      );
}
