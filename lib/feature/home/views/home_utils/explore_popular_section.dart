// lib/feature/home/views/home_utils/explore_popular_section.dart

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:gap/gap.dart';

// Import the display model and the reusable card widget
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
import 'package:shamil_mobile_app/core/navigation/service_provider_navigation.dart'; // Global navigation system
// Import navigation helper if needed for "See All"
// Import a potential screen for listing all popular items
// import 'package:shamil_mobile_app/feature/list_views/all_popular_screen.dart'; // Example

class ExplorePopularSection extends StatelessWidget {
  final List<ServiceProviderDisplayModel> popularProviders;
  // *** ADDED: Accept heroTagPrefix ***
  final String heroTagPrefix;

  const ExplorePopularSection({
    super.key,
    required this.popularProviders,
    required this.heroTagPrefix, // Make it required
  });

  /// Builds the section header (replicates logic from ExploreScreen helper).
  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    // ... (implementation remains the same)
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

  /// Builds a placeholder message for empty sections (replicates logic).
  Widget _buildEmptySectionPlaceholder(
      BuildContext context, String message, IconData icon) {
    // ... (implementation updated to accept icon)
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

    // Build the section header
    Widget header = _buildSectionHeader(
      context,
      "Popular Places", // Section title
      onSeeAll: () {
        print("See all Popular tapped");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Navigate to 'All Popular' (Not Implemented)"),
            duration: Duration(seconds: 2)));
      },
    );

    // Handle empty state
    if (popularProviders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: header,
          ),
          _buildEmptySectionPlaceholder(
              context,
              "No popular places to show yet.",
              Icons.local_fire_department_outlined),
        ],
      );
    }

    // Build the section with the horizontal list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: header,
        ),
        SizedBox(
          height: 260, // Adjusted height
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularProviders.length,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.none,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final provider = popularProviders[index];
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
