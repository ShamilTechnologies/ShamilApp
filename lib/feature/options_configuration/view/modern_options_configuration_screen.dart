import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/widgets/modern_configuration_sections.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/widgets/modern_payment_section.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/core/payment/models/payment_models.dart';
import 'package:shamil_mobile_app/core/payment/ui/widgets/enhanced_payment_widget.dart';
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

/// Modern Configuration Screen with Enhanced Full-Screen Design
class ModernOptionsConfigurationScreen extends StatelessWidget {
  final String providerId;
  final PlanModel? plan;
  final ServiceModel? service;

  const ModernOptionsConfigurationScreen({
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
        firebaseDataOrchestrator: FirebaseDataOrchestrator(),
      )..add(InitializeOptionsConfiguration(
          providerId: providerId,
          plan: plan,
          service: service,
        )),
      child: ModernConfigurationView(
        providerId: providerId,
        isPlan: plan != null,
      ),
    );
  }
}

class ModernConfigurationView extends StatefulWidget {
  final String providerId;
  final bool isPlan;

  const ModernConfigurationView({
    super.key,
    required this.providerId,
    required this.isPlan,
  });

  @override
  State<ModernConfigurationView> createState() =>
      _ModernConfigurationViewState();
}

class _ModernConfigurationViewState extends State<ModernConfigurationView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  final TextEditingController _notesController = TextEditingController();

  int _currentPage = 0;
  String _notes = '';
  final Map<String, bool> _preferences = {
    'notifications': true,
    'reminders': true,
    'calendar': false,
  };

  bool _payForEveryone = false;
  final List<String> _pages = ['Details', 'Configuration', 'Payment'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Set initial values to prevent negative values during animation start
    _progressAnimationController.value = 0.1;
    _animationController.forward();
    _progressAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    _slideAnimationController.dispose();
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OptionsConfigurationBloc, OptionsConfigurationState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        if (state is OptionsConfigurationInitial) {
          return _buildLoadingScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom Header
                  _buildCustomHeader(context, state),

                  // Modern Progress Indicator
                  _buildModernProgressIndicator(),

                  // Content Area
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                          _slideAnimationController.reset();
                          _slideAnimationController.forward();
                        },
                        children: [
                          _buildDetailsPage(state),
                          _buildConfigurationPage(state),
                          _buildPaymentPage(state),
                        ],
                      ),
                    ),
                  ),

                  // Modern Bottom Action Bar
                  _buildModernBottomActionBar(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomHeader(
      BuildContext context, OptionsConfigurationState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),

          const Gap(16),

          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.itemName,
                  style: AppTextStyle.getHeadlineTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.isPlan ? 'Subscription' : 'Booking',
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Icon(
                      CupertinoIcons.circle_fill,
                      size: 3,
                      color: Colors.grey.shade400,
                    ),
                    const Gap(6),
                    Flexible(
                      child: Text(
                        _pages[_currentPage],
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'EGP ${_getPaymentAmount(state).toStringAsFixed(0)}',
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProgressIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Column(
            children: [
              // Progress Steps
              Row(
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  final isCompleted = index < _currentPage;
                  final isLast = index == _pages.length - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        // Step Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuart,
                          width: isActive ? 32 : 24,
                          height: isActive ? 32 : 24,
                          decoration: BoxDecoration(
                            gradient: isCompleted || isActive
                                ? LinearGradient(
                                    colors: isCompleted
                                        ? [
                                            AppColors.successColor,
                                            AppColors.greenColor
                                          ]
                                        : [
                                            AppColors.primaryColor,
                                            AppColors.secondaryColor
                                          ],
                                  )
                                : null,
                            color: isCompleted || isActive
                                ? null
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: _progressAnimation.value.clamp(0.1, 1.0),
                            child: Center(
                              child: isCompleted
                                  ? Icon(
                                      CupertinoIcons.check_mark,
                                      color: Colors.white,
                                      size: isActive ? 16 : 12,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyle.getTitleStyle(
                                        color: isActive || isCompleted
                                            ? Colors.white
                                            : AppColors.secondaryText,
                                        fontSize: isActive ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const Gap(8),

                        // Step Label
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: AppTextStyle.getTitleStyle(
                              color: isActive
                                  ? AppColors.primaryColor
                                  : isCompleted
                                      ? AppColors.successColor
                                      : AppColors.secondaryText,
                              fontSize: isActive ? 14 : 12,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                            child: Text(
                              _pages[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // Progress Line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  gradient: isCompleted
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.successColor,
                                            AppColors.greenColor
                                          ],
                                        )
                                      : null,
                                  color:
                                      isCompleted ? null : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),

              const Gap(16),

              // Overall Progress Bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: (MediaQuery.of(context).size.width *
                          ((_currentPage + 1) / _pages.length) *
                          0.85)
                      .clamp(0.0, double.infinity),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.secondaryColor
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailsPage(OptionsConfigurationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        children: [
          // Hero Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Icon and Title
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondaryColor
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isPlan
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.calendar,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const Gap(20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: AppTextStyle.getHeadlineTextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                            child: Text(
                              state.itemName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.1),
                                  AppColors.secondaryColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              widget.isPlan
                                  ? "Subscription Plan"
                                  : "Service Booking",
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description Section
                if (state.originalService?.description != null ||
                    state.originalPlan?.description != null) ...[
                  const Gap(24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text,
                              color: AppColors.secondaryText,
                              size: 16,
                            ),
                            const Gap(8),
                            Text(
                              'Description',
                              style: AppTextStyle.getTitleStyle(
                                color: AppColors.secondaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          state.originalService?.description ??
                              state.originalPlan?.description ??
                              '',
                          style: AppTextStyle.getTitleStyle(
                            color: AppColors.primaryText,
                            fontSize: 15,
                          ).copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                const Gap(24),

                // Price Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.secondaryColor
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starting Price',
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'EGP ${state.basePrice.toStringAsFixed(0)}',
                              style: AppTextStyle.getHeadlineTextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'per person',
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isPlan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                              const Gap(6),
                              Text(
                                'monthly',
                                style: AppTextStyle.getSmallStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
          ),

          const Gap(20),

          // Additional Info Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.clock,
                  title: 'Duration',
                  value: widget.isPlan
                      ? 'Ongoing'
                      : '${state.originalService?.estimatedDurationMinutes ?? 60} min',
                  color: AppColors.orangeColor,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.person_2,
                  title: 'Capacity',
                  value: 'Up to 10',
                  color: AppColors.cyanColor,
                ),
              ),
            ],
          ),

          const Gap(12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.location,
                  title: 'Location',
                  value: 'On-site',
                  color: AppColors.greenColor,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.checkmark_seal,
                  title: 'Verified',
                  value: 'Provider',
                  color: AppColors.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const Gap(8),
          Text(
            title,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(2),
          Text(
            value,
            style: AppTextStyle.getTitleStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPage(OptionsConfigurationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        children: [
          // Page Header
          _buildPageHeader(
            title: 'Configure Your Booking',
            subtitle:
                'Set up date, time, and attendees for your ${widget.isPlan ? 'subscription' : 'booking'}',
            icon: CupertinoIcons.settings,
          ),
          const Gap(24),

          // Date & Time Selection
          ModernDateTimeSelection(state: state),
          const Gap(16),

          // Attendee Selection
          ModernAttendeeSelection(state: state),
          const Gap(16),

          // Preferences Section
          ModernPreferencesSection(state: state),
          const Gap(16),

          // Additional Notes
          _buildNotesSection(state),
        ],
      ),
    );
  }

  Widget _buildPaymentPage(OptionsConfigurationState state) {
    return BlocProvider(
      create: (context) => PaymentBloc(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // Page Header
            _buildPageHeader(
              title: 'Review & Payment',
              subtitle: 'Review your details and complete the payment',
              icon: CupertinoIcons.creditcard,
            ),
            const Gap(24),

            // Payment Summary
            ModernPaymentSummary(
              state: state,
              isPlan: widget.isPlan,
            ),
            const Gap(20),

            // Payment Methods
            ModernPaymentMethods(
              state: state,
              onPaymentMethodSelected: (method) {
                // Handle payment method selection
                context.read<OptionsConfigurationBloc>().add(
                      UpdatePaymentMethod(paymentMethod: method),
                    );
              },
            ),
            const Gap(20),

            // Payment Terms
            _buildPaymentTerms(),
            const Gap(20),

            // Booking Summary Card
            _buildBookingSummaryCard(state),
            const Gap(20),

            // Payment Button
            ModernPaymentButton(
              state: state,
              isPlan: widget.isPlan,
              onPaymentSuccess: () {
                // Payment success is handled by the payment widget itself
                // The ConfirmConfiguration event will create the reservation/subscription
                print(
                    'Payment completed, reservation/subscription will be created by ConfirmConfiguration event');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.getHeadlineTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: AppTextStyle.getTitleStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(OptionsConfigurationState state) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
                  color: AppColors.orangeColor,
                  size: 24,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Notes',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Add any special requests or notes',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          TextField(
            controller: _notesController,
            maxLines: 4,
            onChanged: (value) {
              setState(() => _notes = value);
              context.read<OptionsConfigurationBloc>().add(
                    NotesUpdated(notes: value),
                  );
            },
            decoration: InputDecoration(
              hintText: 'Enter any special requests, allergies, or notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.lightBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTerms() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.doc_checkmark,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const Gap(8),
              Text(
                'Terms & Conditions',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            'By proceeding with the payment, you agree to our terms of service and privacy policy. ${widget.isPlan ? 'This subscription will auto-renew unless cancelled.' : 'All bookings are subject to availability and confirmation.'}',
            style: AppTextStyle.getSmallStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'I agree to the terms and conditions',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard(OptionsConfigurationState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: AppTextStyle.getTitleStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),
          _buildSummaryItem(
            label: 'Service',
            value: state.itemName,
            icon: widget.isPlan
                ? CupertinoIcons.star_fill
                : CupertinoIcons.calendar,
          ),
          if (state.selectedDate != null) ...[
            const Gap(8),
            _buildSummaryItem(
              label: 'Date',
              value: 'Selected',
              icon: CupertinoIcons.calendar_today,
            ),
          ],
          if (state.selectedTime != null) ...[
            const Gap(8),
            _buildSummaryItem(
              label: 'Time',
              value: 'Selected',
              icon: CupertinoIcons.clock,
            ),
          ],
          const Gap(8),
          _buildSummaryItem(
            label: 'Attendees',
            value: '${state.selectedAttendees.length + 1} person(s)',
            icon: CupertinoIcons.person_2,
          ),
          if (_notes.isNotEmpty) ...[
            const Gap(8),
            _buildSummaryItem(
              label: 'Notes',
              value: 'Added',
              icon: CupertinoIcons.doc_text,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryColor,
        ),
        const Gap(8),
        Text(
          '$label:',
          style: AppTextStyle.getSmallStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const Gap(4),
        Expanded(
          child: Text(
            value,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomActionBar(OptionsConfigurationState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentPage > 0)
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_left,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                        const Gap(8),
                        Text(
                          'Back',
                          style: AppTextStyle.getTitleStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_currentPage > 0) const Gap(12),

          // Next/Continue Button
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: _isButtonEnabled(state)
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.secondaryColor
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isButtonEnabled(state)
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isButtonEnabled(state)
                      ? () => _handleNextButton(state)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _getButtonText(state),
                          key: ValueKey(_getButtonText(state)),
                          style: AppTextStyle.getTitleStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Gap(8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _currentPage == _pages.length - 1
                              ? CupertinoIcons.creditcard_fill
                              : CupertinoIcons.arrow_right,
                          key: ValueKey(_currentPage),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.secondaryColor
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const Gap(20),
                  Text(
                    'Loading Configuration...',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Setting up your booking experience',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  void _handleStateChanges(
      BuildContext context, OptionsConfigurationState state) {
    if (state.errorMessage?.isNotEmpty == true) {
      showGlobalSnackBar(context, state.errorMessage!, isError: true);
      context.read<OptionsConfigurationBloc>().add(const ClearErrorMessage());
    }
  }

  void _handleNextButton(OptionsConfigurationState state) {
    switch (_currentPage) {
      case 0:
        // Details page - validate date/time selection
        if (!state.isDateTimeStepComplete) {
          _showValidationError(
              context, 'Please complete date and time selection');
          return;
        }
        _goToNextPage();
        break;

      case 1:
        // Configuration page - validate attendees
        if (!state.isAttendeesStepComplete) {
          _showValidationError(
              context, 'Please ensure at least one person is attending');
          return;
        }
        _goToNextPage();
        break;

      case 2:
        // Payment page - validate and process payment
        if (!state.canProceedToPayment) {
          final validationErrors = _getValidationErrors(state);
          _showValidationError(context, validationErrors.first);
          return;
        }
        // Process payment
        _processPayment(state);
        break;
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
              size: 20,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyle.getTitleStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _processPayment(OptionsConfigurationState state) {
    // Show payment gateway directly
    ModernPaymentButton.showPaymentGateway(
      context,
      state,
      widget.isPlan,
      onPaymentSuccess: () {
        // Payment success is handled by the payment widget itself
        // The ConfirmConfiguration event will create the reservation/subscription
        print(
            'Payment completed, reservation/subscription will be created by ConfirmConfiguration event');
      },
    );
  }

  List<String> _getValidationErrors(OptionsConfigurationState state) {
    final errors = <String>[];

    if (!state.isDateTimeStepComplete) {
      if (state.optionsDefinition?['allowDateSelection'] == true &&
          state.selectedDate == null) {
        errors.add('Please select a booking date');
      }
      if (state.optionsDefinition?['allowTimeSelection'] == true &&
          (state.selectedTime == null || state.selectedTime!.isEmpty)) {
        errors.add('Please select a booking time');
      }
    }

    if (!state.isAttendeesStepComplete) {
      errors.add('At least one person must attend (you or invited attendees)');
    }

    if (!state.isPaymentDataValid) {
      if (state.totalPrice <= 0) {
        errors.add('Invalid payment amount');
      } else {
        errors.add('Payment configuration is incomplete');
      }
    }

    return errors.isEmpty ? ['Please complete all required fields'] : errors;
  }

  String _getButtonText(OptionsConfigurationState state) {
    switch (_currentPage) {
      case 0:
        return 'Continue to Configuration';
      case 1:
        return 'Continue to Payment';
      case 2:
        return state.canProceedToPayment
            ? 'Pay Now'
            : 'Complete Required Steps';
      default:
        return 'Continue';
    }
  }

  double _getPaymentAmount(OptionsConfigurationState state) {
    if (_payForEveryone) {
      int attendeeCount = state.selectedAttendees.length;
      if (attendeeCount == 0) attendeeCount = 1;
      return state.basePrice * attendeeCount;
    } else {
      return state.basePrice;
    }
  }

  bool _isButtonEnabled(OptionsConfigurationState state) {
    switch (_currentPage) {
      case 0:
        // Details page - check date/time requirements
        return state.isDateTimeStepComplete;
      case 1:
        // Configuration page - check attendee requirements
        return state.isAttendeesStepComplete;
      case 2:
        // Payment page - check all requirements
        return state.canProceedToPayment;
      default:
        return false;
    }
  }
}
