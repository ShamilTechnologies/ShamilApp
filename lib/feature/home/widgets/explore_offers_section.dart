// lib/feature/home/widgets/explore_offers_section.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart'; // Import Gap
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Import AppColors
// Import the display model and the reusable card
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart'; // Reusable card
import 'package:shamil_mobile_app/core/navigation/service_provider_navigation.dart'; // Global navigation system

class ExploreOffersSection extends StatelessWidget {
  // Assuming offers are represented by ServiceProviderDisplayModel for now
  // TODO: Replace with a specific OfferModel if needed later
  final List<ServiceProviderDisplayModel> offerProviders;
  // *** ADDED: Accept heroTagPrefix ***
  final String heroTagPrefix;

  const ExploreOffersSection({
    super.key,
    required this.offerProviders,
    required this.heroTagPrefix, // Make it required
  });

  /// Builds the section header.
  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.secondaryColor,
              ),
              child: Text(
                'See All',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a placeholder message for empty sections.
  Widget _buildEmptySectionPlaceholder(
      BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.secondaryColor.withOpacity(0.6),
          ),
          const Gap(12),
          Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.secondaryColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Section Header
    Widget header = _buildSectionHeader(context, "Special Offers", // Title
        onSeeAll: () {
      // TODO: Handle "See all" navigation for offers.
      print("See all Offers tapped");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Navigate to 'All Offers' (Not Implemented)"),
          duration: Duration(seconds: 2)));
    });

    // Handle empty state
    if (offerProviders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add horizontal padding for header when list is empty
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: header,
          ),
          _buildEmptySectionPlaceholder(
            context,
            "No special offers available currently.", // User-friendly message
            Icons.sell_outlined, // Specific icon for offers empty
          ),
        ],
      );
    }

    // Build the section with the horizontal list using the standard card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add horizontal padding for header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: header,
        ),
        SizedBox(
          height: 260, // Match height of other sections
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: offerProviders.length,
            // Add horizontal padding for the list itself
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = offerProviders[index];
              // *** Pass the unique heroTagPrefix to the card ***
              return ServiceProviderCard(
                provider: provider,
                heroTagPrefix: heroTagPrefix, // Pass the prefix
                onTap: ServiceProviderNavigation.createProviderCardNavigation(
                  context,
                  provider: provider,
                  heroTagPrefix: heroTagPrefix,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
