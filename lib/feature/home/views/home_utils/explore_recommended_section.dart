import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep if AppColors are used for specifics
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Keep if getSmallStyle is used, otherwise prefer theme
import 'package:gap/gap.dart'; // For spacing
// Removed Uint8List import

// *** Import the CORRECT display model ***
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// *** Import the new reusable card widget ***
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
// Removed unused image constants import

// --- REMOVED local constants ---

class ExploreRecommendedSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (passed from parent widget)
  final List<ServiceProviderDisplayModel> recommendedProviders;

  const ExploreRecommendedSection({
    super.key,
    required this.recommendedProviders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    // Section Header
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Add padding below header
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Recommended For You", // Title
            // Use consistent theme text style as Popular section
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            // Use TextButton
            onPressed: () {
              // TODO: Handle "See all" navigation for recommended items.
              print("See all Recommended tapped");
            },
            child: Text(
              'See all',
              // Use consistent theme text style as Popular section
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // Handle empty state
    if (recommendedProviders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header, // Show header even when empty
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
            alignment: Alignment.center,
            child: Text(
              "No recommendations found right now.", // User-friendly message
              // Use theme text style
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary), // Use theme color
              textAlign: TextAlign.center,
            ),
          ),
          // const SizedBox(height: 10), // Gap handles spacing
        ],
      );
    }

    // Build the section with the list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header, // Section header
        SizedBox(
          height: 220, // Match height of popular section for consistency
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recommendedProviders.length,
            // Padding handled by parent in home_view now
            padding: const EdgeInsets.symmetric(vertical: 4.0), // Padding for shadow
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = recommendedProviders[index];
              // *** Use the reusable ServiceProviderCard widget ***
              return ServiceProviderCard(provider: provider);
            },
          ),
        ),
      ],
    );
  }

  // *** REMOVED _buildCardItem method - logic moved to ServiceProviderCard ***
}
