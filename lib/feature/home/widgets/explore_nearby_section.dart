// lib/feature/home/widgets/explore_nearby_section.dart

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
// Import ServiceProviderModel if your cards expect the full model
// import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

class ExploreNearbySection extends StatelessWidget {
  // *** UPDATED: Changed parameter name to nearbyProviders ***
  final List<ServiceProviderDisplayModel> nearbyProviders;

  const ExploreNearbySection({
    super.key,
    required this.nearbyProviders, // Parameter is now nearbyProviders
  });

  @override
  Widget build(BuildContext context) {
    if (nearbyProviders.isEmpty) {
      // This case should ideally be handled by the parent (ExploreScreen)
      // showing a "No nearby places" message, but as a fallback:
      return const SizedBox.shrink();
    }

    return SizedBox(
      height:
          270, // Adjust height to fit your ServiceProviderCard appropriately
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nearbyProviders.length,
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 8.0), // Add some vertical padding too
        itemBuilder: (context, index) {
          final provider = nearbyProviders[index];
          return Padding(
            // Add padding around each card for better spacing
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ServiceProviderCard(
              provider: provider,
              heroTagPrefix: "nearby",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceProviderDetailScreen(
                      providerId: provider.id,
                      heroTag: 'nearby_${provider.id}',
                    ),
                  ),
                );
              },
              // If your ServiceProviderCard expects the full ServiceProviderModel,
              // you'll need to adjust the type of nearbyProviders and how it's passed.
            ),
          );
        },
      ),
    );
  }
}
