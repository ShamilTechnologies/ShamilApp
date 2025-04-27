import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep if AppColors are used for specifics
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Keep if getSmallStyle is used, otherwise prefer theme
import 'package:gap/gap.dart'; // For spacing

// Import the display model
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// Import the reusable card widget
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
// Import navigation helper
import 'package:shamil_mobile_app/core/functions/navigation.dart';
// Import placeholder screen for "See All" (Create this screen later)
// import 'package:shamil_mobile_app/feature/home/views/all_recommended_screen.dart';

class ExploreRecommendedSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (passed from parent widget)
  // This list should be populated and sorted by the HomeBloc
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Recommended For You", // Title
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement navigation to a dedicated "All Recommended" screen
              print("See all Recommended tapped");
              // Example Navigation (create AllRecommendedScreen later):
              // push(context, const AllRecommendedScreen());
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text("Navigate to 'All Recommended' (Not Implemented)"),
                  duration: Duration(seconds: 2)));
            },
            child: Text(
              'See all',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // Handle empty state with an icon
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
            child: Column(
              // Wrap icon and text
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sentiment_dissatisfied_outlined, // Example icon
                  size: 40,
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                ),
                const Gap(12),
                Text(
                  "No recommendations found right now.", // User-friendly message
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
            padding:
                const EdgeInsets.symmetric(vertical: 4.0), // Padding for shadow
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = recommendedProviders[index];
              // Use the reusable ServiceProviderCard widget
              return ServiceProviderCard(provider: provider);
            },
          ),
        ),
      ],
    );
  }
}
