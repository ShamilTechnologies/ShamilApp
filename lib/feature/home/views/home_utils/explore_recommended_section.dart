// lib/feature/home/views/home_utils/explore_recommended_section.dart

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep if AppColors are used for specifics
import 'package:gap/gap.dart'; // For spacing

// Import the display model
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// Import the reusable card widget
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
import 'package:shamil_mobile_app/core/navigation/service_provider_navigation.dart'; // Global navigation system
// Import navigation helper
// Import placeholder screen for "See All" (Create this screen later)
// import 'package:shamil_mobile_app/feature/home/views/all_recommended_screen.dart';

class ExploreRecommendedSection extends StatelessWidget {
  final List<ServiceProviderDisplayModel> recommendedProviders;
  // *** ADDED: Accept heroTagPrefix ***
  final String heroTagPrefix;

  const ExploreRecommendedSection({
    super.key,
    required this.recommendedProviders,
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
    final theme = Theme.of(context); // Get theme data

    // Section Header
    Widget header = _buildSectionHeader(context, "Recommended For You", // Title
        onSeeAll: () {
      // TODO: Implement navigation to a dedicated "All Recommended" screen
      print("See all Recommended tapped");
      // Example Navigation (create AllRecommendedScreen later):
      // push(context, const AllRecommendedScreen());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Navigate to 'All Recommended' (Not Implemented)"),
          duration: Duration(seconds: 2)));
    });

    // Handle empty state with an icon
    if (recommendedProviders.isEmpty) {
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
            "No recommendations found right now.", // User-friendly message
            Icons.thumb_up_alt_outlined, // Specific icon for recommended empty
          ),
        ],
      );
    }

    // Build the section with the list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add horizontal padding for header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: header,
        ),
        SizedBox(
          height: 260, // Match height of popular section for consistency
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recommendedProviders.length,
            // Add horizontal padding for the list itself
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = recommendedProviders[index];
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
