import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
// Import the display model and the reusable card
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart'; // Reusable card

class ExploreNearbySection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (passed from parent widget)
  // This list should be pre-sorted by distance in the Bloc
  final List<ServiceProviderDisplayModel> nearbyProviders;

  const ExploreNearbySection({
    super.key,
    required this.nearbyProviders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    // Section Header
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Nearby Places", // Title
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle "See all" navigation for nearby items.
              print("See all Nearby tapped");
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

    // Handle empty state (e.g., if location fails or no providers nearby)
    if (nearbyProviders.isEmpty) {
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
              "Could not find places near your current location.", // User-friendly message
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    // Build the section with the list using the standard card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header, // Section header
        SizedBox(
          height: 220, // Match height of other lists
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: nearbyProviders.length,
            padding: const EdgeInsets.symmetric(vertical: 4.0), // Padding for shadow
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = nearbyProviders[index];
              // Use the reusable ServiceProviderCard widget
              // TODO: Consider adding distance display to the card if needed
              return ServiceProviderCard(provider: provider);
            },
          ),
        ),
      ],
    );
  }
}
