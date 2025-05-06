// lib/feature/details/widgets/options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors if needed
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';
// Import the panel widgets
import 'package:shamil_mobile_app/feature/details/widgets/reservation_panel.dart';
import 'package:shamil_mobile_app/feature/details/widgets/subscription_panel.dart';
// Import listener helper if needed for specific actions
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

/// Displays reservation/subscription options within a modal bottom sheet.
/// Handles multiple reservation types and pricing models with improved UI/UX.
class OptionsBottomSheetContent extends StatefulWidget {
  final ServiceProviderModel provider;
  final ScrollController
      scrollController; // Passed from DraggableScrollableSheet

  const OptionsBottomSheetContent({
    super.key,
    required this.provider,
    required this.scrollController,
  });

  @override
  State<OptionsBottomSheetContent> createState() =>
      _OptionsBottomSheetContentState();
}

class _OptionsBottomSheetContentState extends State<OptionsBottomSheetContent>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  // Determine if the provider supports both reservation and subscription
  bool get _isHybrid => widget.provider.pricingModel == PricingModel.hybrid;

  @override
  void initState() {
    super.initState();
    // Initialize TabController only if the provider is hybrid
    if (_isHybrid) {
      _tabController = TabController(length: 2, vsync: this);
    }
    // Initialize Blocs with provider context when the sheet opens
    // Assumes Blocs are provided *above* the bottom sheet
    _initializeBlocs();
  }

  /// Initializes Blocs and sets the initial reservation state.
  void _initializeBlocs() {
    // Use WidgetsBinding to ensure context is available after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Check if the widget is still in the tree
      try {
        // Reset flows for the current provider context
        // This ensures the Blocs start fresh for this specific provider
        context
            .read<ReservationBloc>()
            .add(ResetReservationFlow(provider: widget.provider));
        context.read<SubscriptionBloc>().add(ResetSubscriptionFlow());

        // ACTION: Load social data if attendee selection is needed immediately
        // If ReservationPanel triggers attendee loading, this might not be needed here.
        // Example:
        // context.read<SocialBloc>().add(const LoadFamilyMembers());
        // context.read<SocialBloc>().add(const LoadFriendsAndRequests());
      } catch (e) {
        // Log error and show feedback if Blocs aren't found
        print(
            "Error accessing/resetting Blocs in OptionsBottomSheet initState: $e.");
        // Use showGlobalSnackBar safely
        if (mounted) {
          showGlobalSnackBar(context, "Error preparing booking options.",
              isError: true);
        }
        // Optionally close the sheet if essential Blocs are missing
        // Navigator.maybePop(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Dispose TabController if it was created
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingModel = widget.provider.pricingModel;

    /// Builds the content panel (Reservation or Subscription) based on the pricing model.
    /// Reads the respective Bloc state to pass down to the panel widget.
    Widget buildPanelContent(PricingModel model) {
      if (model == PricingModel.subscription) {
        // Reads the current SubscriptionState and passes it to the SubscriptionPanel
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            // Determine loading state based on specific SubscriptionBloc states
            bool isLoading = state is SubscriptionPaymentProcessing ||
                state is SubscriptionConfirmationLoading;
            // The SubscriptionPanel widget handles displaying content based on the state
            return SubscriptionPanel(
              theme: theme,
              provider: widget.provider,
              state: state, // Pass the current SubscriptionState
              isLoading: isLoading,
              isHybrid: _isHybrid, // Pass flag for conditional title display
            );
          },
        );
      } else if (model == PricingModel.reservation) {
        // Reads the current ReservationState and passes it to the ReservationPanel
        return BlocBuilder<ReservationBloc, ReservationState>(
          builder: (context, state) {
            // Determine loading state based on specific ReservationBloc states
            bool isLoading = state is ReservationCreating ||
                (state is ReservationDateSelected && state.isLoadingSlots);
            // The ReservationPanel widget handles displaying content based on the state
            return ReservationPanel(
              theme: theme,
              provider: widget.provider,
              state: state, // Pass the current ReservationState
              isLoading: isLoading,
              isHybrid: _isHybrid, // Pass flag for conditional title display
            );
          },
        );
      }
      // Fallback for 'other' or unknown pricing models
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        child: Text(
          "Booking options for this provider are not available through the app.",
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    // Use MultiBlocListener for handling global feedback/navigation originating from Blocs
    return MultiBlocListener(
      listeners: [
        // Listener for Reservation Bloc actions (e.g., success/error after create attempt)
        BlocListener<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationSuccess) {
              showGlobalSnackBar(context, state.message);
              // Close the bottom sheet after a short delay on success
              Future.delayed(const Duration(milliseconds: 1500), () {
                // Check if the sheet is still visible before popping
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
            } else if (state is ReservationError) {
              // Avoid showing redundant errors if the panel already shows validation messages
              bool isValidationError =
                  state.message.contains("required fields") ||
                      state.message.contains("Maximum group size");
              if (!isValidationError) {
                showGlobalSnackBar(context, state.message, isError: true);
              }
            }
          },
        ),
        // Listener for Subscription Bloc actions
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
              // Show errors related to subscription process
              showGlobalSnackBar(context, state.message, isError: true);
            }
          },
        ),
      ],
      // Main layout structure of the bottom sheet content
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Stretch children horizontally
        children: [
          // --- Header Area ---
          // Draggable Handle visual cue
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
          // Provider Name Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16.0, 0, 16.0, 8.0), // Adjusted padding
            child: Text(
              widget.provider.businessName,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Subtitle
          Center(
            child: Text(
              "Booking Options",
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
          const Gap(12), // Spacing after subtitle
          const Divider(height: 1, thickness: 1), // Visual separator

          // --- TabBar for Hybrid Providers ---
          if (_isHybrid)
            Container(
              // Add background for visual grouping
              color: theme
                  .canvasColor, // Use theme canvas color or a subtle variant
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3.0, // Slightly thicker indicator
                labelStyle: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: const [
                  Tab(text: 'Subscriptions'),
                  Tab(text: 'Reservations'),
                ],
              ),
            ),
          // Separator below tabs only if hybrid
          if (_isHybrid) const Divider(height: 1, thickness: 1),

          // --- Content Area (Scrollable Panels) ---
          Expanded(
            child: _isHybrid
                // TabBarView for hybrid providers
                ? TabBarView(
                    controller: _tabController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable swiping between tabs
                    children: [
                        // Subscription Tab Content (uses ListView internally via panel)
                        SingleChildScrollView(
                          // Wrap panel in SingleChildScrollView
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16.0)
                              .copyWith(top: 20), // Consistent padding
                          child: buildPanelContent(PricingModel.subscription),
                        ),
                        // Reservation Tab Content (uses ListView internally via panel)
                        SingleChildScrollView(
                          // Wrap panel in SingleChildScrollView
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16.0)
                              .copyWith(top: 20), // Consistent padding
                          child: buildPanelContent(PricingModel.reservation),
                        ),
                      ])
                // Single Content Panel for non-hybrid providers
                : SingleChildScrollView(
                    // Wrap panel in SingleChildScrollView
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(16.0)
                        .copyWith(top: 20), // Consistent padding
                    child: buildPanelContent(
                        pricingModel), // Build content based on the single model
                  ),
          ),
        ],
      ),
    );
  }
}
