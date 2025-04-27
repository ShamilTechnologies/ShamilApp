import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
// import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Prefer theme styles
import 'package:gap/gap.dart'; // For spacing

// Import the display model and the reusable card widget
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
// Import navigation helper if needed for "See All"
import 'package:shamil_mobile_app/core/functions/navigation.dart';
// Import a potential screen for listing all popular items
// import 'package:shamil_mobile_app/feature/list_views/all_popular_screen.dart'; // Example

class ExplorePopularSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (passed from parent widget)
  final List<ServiceProviderDisplayModel> popularProviders;

  const ExplorePopularSection({
    super.key,
    required this.popularProviders,
  });

  /// Builds the section header (replicates logic from ExploreScreen helper).
  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    final theme = Theme.of(context);
    return Padding(
      // No horizontal padding here, handled by parent SliverPadding
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor, // Use AppColor
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30), // Ensure minimum tap target
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.secondaryColor, // Use AppColor
              ),
              child: Text(
                'See All',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor, // Use AppColor
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a placeholder message for empty sections (replicates logic).
  Widget _buildEmptySectionPlaceholder(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      // Add horizontal padding matching the list's start padding
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      height: 150, // Give placeholder some height
      alignment: Alignment.center,
      child: Column(
        // Icon and Text
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_outlined, // Icon for "Popular"
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
        // TODO: Implement navigation to a dedicated screen showing all popular providers
        // Example: push(context, const AllPopularScreen());
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
          // Add horizontal padding for the header when the list is empty
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: header,
          ),
          _buildEmptySectionPlaceholder(
              context, "No popular places to show yet."),
        ],
      );
    }

    // Build the section with the horizontal list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add horizontal padding for the header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: header,
        ),
        SizedBox(
          // Define height for the horizontal list view
          // Adjust height based on the ServiceProviderCard's expected height + padding
          height: 260, // Increased height to accommodate taller cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularProviders.length,
            // Add horizontal padding for the list itself to space from screen edges
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            clipBehavior: Clip.none, // Allow card shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = popularProviders[index];
              // *** Use the reusable ServiceProviderCard widget ***
              // It handles its own styling, hero animation, and navigation logic
              return ServiceProviderCard(provider: provider);
            },
          ),
        ),
      ],
    );
  }
}
