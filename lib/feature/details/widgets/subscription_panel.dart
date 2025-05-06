// lib/feature/details/widgets/subscription_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // Includes SubscriptionPlan
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_bloc.dart';

/// Displays subscription plans and handles selection/payment initiation.
/// Reads data from the provided [SubscriptionState].
class SubscriptionPanel extends StatelessWidget {
  final ThemeData theme;
  final ServiceProviderModel provider; // Provider data is still needed for plan list
  final SubscriptionState state;      // Accepts the full Bloc state
  final bool isLoading;               // General loading flag from parent
  final bool isHybrid;                // To conditionally show title

  const SubscriptionPanel({
    super.key,
    required this.theme,
    required this.provider,
    required this.state, // Accept state object
    required this.isLoading,
    required this.isHybrid,
  });

  @override
  Widget build(BuildContext context) {
    final plans = provider.subscriptionPlans; // Get plans from provider data

    // Determine selected plan from the current state object
    SubscriptionPlan? selectedPlan = switch (state) {
      SubscriptionPlanSelected(plan: final p) => p,
      SubscriptionPaymentProcessing(plan: final p) => p,
      SubscriptionConfirmationLoading(plan: final p) => p,
      SubscriptionError(plan: final p) => p, // Extract plan even from error state
      _ => null, // No plan selected in other states (Initial, Success)
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title (only if not part of a tab view in hybrid mode)
        if (!isHybrid)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Subscription Plans",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),

        // Empty State: Show if the provider offers no subscription plans
        if (plans.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text("No subscription plans available.",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
            ),
          )
        // List of Plans: Show if plans exist
        else
          ListView.builder(
            shrinkWrap: true, // Important for nested ListView
            physics: const NeverScrollableScrollPhysics(), // Disable its scrolling
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              // Check if this plan is the one currently selected in the Bloc state
              final bool isSelected = selectedPlan?.id == plan.id;
              // Format the interval string (e.g., "month", "3 months")
              final intervalStr =
                  "${plan.intervalCount > 1 ? '${plan.intervalCount} ' : ''}${plan.interval.name}${plan.intervalCount > 1 ? 's' : ''}";

              // Build Card for each plan
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  elevation: isSelected ? 3.0 : 1.5, // Highlight selected card
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      // Add border to selected card
                      side: isSelected
                          ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                          : BorderSide.none),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // Disable tap during loading, dispatch SelectSubscriptionPlan event otherwise
                    onTap: isLoading ? null : () => context.read<SubscriptionBloc>().add(SelectSubscriptionPlan(selectedPlan: plan)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan Name, Price, Interval Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side: Name and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plan.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const Gap(6),
                                    Text(plan.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              const Gap(12), // Space between text and price
                              // Right side: Price and Interval
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end, // Align price/interval right
                                children: [
                                  Text("EGP ${plan.price.toStringAsFixed(0)}", // Format price
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                  Text("/ $intervalStr", // Display formatted interval
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                ],
                              ),
                            ],
                          ),
                          // Features Wrap (only if features exist)
                          if (plan.features.isNotEmpty) ...[
                            const Gap(10), // Space before features
                            Wrap(
                              spacing: 6.0, // Horizontal space between chips
                              runSpacing: 4.0, // Vertical space between chip lines
                              children: plan.features.map((feature) => Chip(
                                        label: Text(feature),
                                        labelStyle: theme.textTheme.labelSmall?.copyWith(color: AppColors.primaryColor),
                                        backgroundColor: AppColors.primaryColor.withOpacity(0.1), // Subtle background
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        visualDensity: VisualDensity.compact, // Make chip smaller
                                        side: BorderSide.none, // No border
                                      )).toList(),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Spacing before the button
        const Gap(24),

        // Purchase Button
        if (plans.isNotEmpty) // Only show button if there are plans
          Center(
            child: CustomButton(
              text: isLoading ? 'Processing...' : 'Proceed to Payment',
              // Disable button if no plan is selected in the state or if loading
              onPressed: (selectedPlan == null || isLoading)
                  ? null
                  : () => context.read<SubscriptionBloc>().add(const InitiateSubscriptionPayment()),
            ),
          ),

        // Error Message Display (if state is SubscriptionError)
        if (state is SubscriptionError)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
                child: Text(
                    (state as SubscriptionError).message, // Access message from state
                    style: TextStyle(color: theme.colorScheme.error), // Use theme error color
                    textAlign: TextAlign.center,
                )
            ),
          ),

        // Bottom padding
        const Gap(20),
      ],
    );
  }
}
