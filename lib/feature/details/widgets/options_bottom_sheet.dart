// lib/feature/details/widgets/options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
// For AppColors if needed

// Import the UPDATED ServiceProviderModel
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Import Blocs needed within the sheet
import 'package:shamil_mobile_app/feature/reservation/presentation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
// Import the panel widgets
import 'package:shamil_mobile_app/feature/details/widgets/reservation_panel.dart';
import 'package:shamil_mobile_app/feature/details/widgets/subscription_panel.dart';
// Import listener helper if needed for specific actions
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import SocialBloc if needed for attendee dialogs
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';

/// Displays reservation/subscription options within a modal bottom sheet.
/// Handles multiple reservation types and pricing models with improved UI/UX.
class OptionsBottomSheetContent extends StatefulWidget {
  // Accept the FULL ServiceProviderModel
  final ServiceProviderModel provider;
  final ScrollController
      scrollController; // Passed from DraggableScrollableSheet

  const OptionsBottomSheetContent({
    super.key,
    required this.provider, // Now accepts the full model
    required this.scrollController,
  });

  @override
  State<OptionsBottomSheetContent> createState() =>
      _OptionsBottomSheetContentState();
}

class _OptionsBottomSheetContentState extends State<OptionsBottomSheetContent>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Read configuration directly from the passed provider model
  bool get _isHybrid => widget.provider.pricingModel == PricingModel.hybrid;

  // Check if specific reservation types are supported AND provider offers reservations
  bool get _supportsReservation =>
      (widget.provider.pricingModel == PricingModel.reservation || _isHybrid) &&
      widget.provider.supportedReservationTypes.isNotEmpty;

  // Check if subscription plans exist AND provider offers subscriptions
  bool get _supportsSubscription =>
      (widget.provider.pricingModel == PricingModel.subscription ||
          _isHybrid) &&
      widget.provider.subscriptionPlans.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Initialize TabController only if needed (hybrid and supports at least two distinct options)
    final List<Widget> tabsForController = [];
    if (_isHybrid) {
      if (_supportsSubscription) {
        tabsForController.add(const Tab(text: "Subscriptions"));
      }
      if (_supportsReservation) {
        tabsForController.add(const Tab(text: "Reservations"));
      }
    }

    if (tabsForController.length > 1) {
      // Only create TabController if there are multiple tabs
      _tabController =
          TabController(length: tabsForController.length, vsync: this);
    }

    // Initialize Blocs with provider context when the sheet opens
    _initializeBlocs();
  }

  /// Initializes Blocs and sets the initial reservation/subscription state.
  void _initializeBlocs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // Reset flows using the specific provider from the widget
        if (_supportsReservation) {
          context
              .read<ReservationBloc>()
              .add(ResetReservationFlow(provider: widget.provider));
        }
        if (_supportsSubscription) {
          context.read<SubscriptionBloc>().add(ResetSubscriptionFlow());
        }

        // Pre-load social data if needed for attendee selection
        if (_supportsReservation) {
          // Only load if reservations are supported
          final socialBloc = context.read<SocialBloc>();
          // Load only if not already loaded or loading to avoid redundant calls
          if (socialBloc.state is SocialInitial ||
              socialBloc.state is SocialError) {
            socialBloc.add(const LoadFamilyMembers());
            socialBloc.add(const LoadFriendsAndRequests());
          }
        }
      } catch (e) {
        print(
            "Error accessing/resetting Blocs in OptionsBottomSheet initState: $e.");
        if (mounted) {
          showGlobalSnackBar(context, "Error preparing booking options.",
              isError: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingModel = widget.provider.pricingModel;

    /// Builds the content panel (Reservation or Subscription) based on the pricing model.
    Widget buildPanelContent(PricingModel model) {
      if (model == PricingModel.subscription && _supportsSubscription) {
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            bool isLoading = state is SubscriptionPaymentProcessing ||
                state is SubscriptionConfirmationLoading;
            return SubscriptionPanel(
              theme: theme,
              provider: widget.provider,
              state: state,
              isLoading: isLoading,
              isHybrid: _isHybrid,
            );
          },
        );
      } else if (model == PricingModel.reservation && _supportsReservation) {
        return BlocBuilder<ReservationBloc, ReservationState>(
          builder: (context, state) {
            bool isLoadingReservation = state is ReservationCreating ||
                (state is ReservationDateSelected && state.isLoadingSlots) ||
                state is ReservationJoiningQueue;
            return ReservationPanel(
              theme: theme,
              state: state,
              isLoading: isLoadingReservation,
              isHybrid: _isHybrid,
            );
          },
        );
      }
      // Fallback for 'other' or if the requested model isn't supported
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        child: Text(
          model == PricingModel.subscription
              ? "Subscriptions not available for this provider."
              : model == PricingModel.reservation
                  ? "Reservations not available for this provider."
                  : "Booking options for this provider are not available through the app.",
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    // Determine which tabs to show and their corresponding views
    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    if (_isHybrid) {
      // Only consider tabs for hybrid model
      if (_supportsSubscription) {
        tabs.add(const Tab(text: 'Subscriptions'));
        tabViews.add(SingleChildScrollView(
          key: const PageStorageKey(
              'subscriptionTab'), // Preserve scroll position
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16.0).copyWith(top: 20),
          child: buildPanelContent(PricingModel.subscription),
        ));
      }
      if (_supportsReservation) {
        tabs.add(const Tab(text: 'Reservations'));
        tabViews.add(SingleChildScrollView(
          key: const PageStorageKey(
              'reservationTab'), // Preserve scroll position
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16.0).copyWith(top: 20),
          child: buildPanelContent(PricingModel.reservation),
        ));
      }
      // If only one option is actually supported in hybrid, don't show tabs
      if (tabs.length < 2) {
        _tabController?.dispose(); // Dispose if created but not needed
        _tabController = null; // Set to null
      }
    }

    // Use MultiBlocListener for handling global feedback/navigation
    return MultiBlocListener(
      listeners: [
        BlocListener<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationSuccess) {
              showGlobalSnackBar(context, state.message);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
            } else if (state is ReservationError &&
                state is! ReservationQueueError) {
              bool isValidationError =
                  state.message.contains("required fields") ||
                      state.message.contains("Maximum group size") ||
                      state.message.contains("Invalid time range");
              if (!isValidationError) {
                showGlobalSnackBar(context, state.message, isError: true);
              }
            }
          },
        ),
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listener: (context, state) {
            if (state is SubscriptionSuccess) {
              showGlobalSnackBar(context, state.message);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
            } else if (state is SubscriptionError) {
              showGlobalSnackBar(context, state.message, isError: true);
            }
          },
        ),
        BlocListener<SocialBloc, SocialState>(
          listener: (context, state) {
            if (state is SocialError) {
              showGlobalSnackBar(
                  context, "Social Action Failed: ${state.message}",
                  isError: true);
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header Area ---
          Center(
            child: Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Text(
              widget.provider.businessName,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Center(
            child: Text(
              "Booking Options",
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
          const Gap(12),
          const Divider(height: 1, thickness: 1),

          // --- TabBar for Hybrid Providers (if _tabController is not null) ---
          if (_tabController != null && tabs.isNotEmpty)
            Container(
              color: theme.canvasColor,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3.0,
                labelStyle: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: tabs,
              ),
            ),
          if (_tabController != null && tabs.isNotEmpty)
            const Divider(height: 1, thickness: 1),

          // --- Content Area (Scrollable Panels) ---
          Expanded(
            child: (_tabController != null && tabViews.isNotEmpty)
                // TabBarView for hybrid providers
                ? TabBarView(
                    controller: _tabController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable swiping between tabs
                    children: tabViews)
                // Single Content Panel for non-hybrid providers or hybrid with only one actual option
                : SingleChildScrollView(
                    key: const PageStorageKey(
                        'singleContentPanel'), // Key for scroll preservation
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(16.0).copyWith(top: 20),
                    // Determine which panel to show if not hybrid or only one option in hybrid
                    child: _isHybrid
                        ? (_supportsSubscription
                            ? buildPanelContent(PricingModel.subscription)
                            : (_supportsReservation
                                ? buildPanelContent(PricingModel.reservation)
                                : buildPanelContent(pricingModel)))
                        : buildPanelContent(pricingModel),
                  ),
          ),
        ],
      ),
    );
  }
}
