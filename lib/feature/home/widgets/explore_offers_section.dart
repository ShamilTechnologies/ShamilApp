import 'package:flutter/material.dart';
// Import the display model and the reusable card
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';

class ExploreOffersSection extends StatelessWidget {
  // TODO: Replace with actual OfferModel or use ServiceProviderDisplayModel if offers are tied to providers
  final List<ServiceProviderDisplayModel> offerProviders;

  const ExploreOffersSection({
    super.key,
    required this.offerProviders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Section Header
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Special Offers",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle "See all" navigation for offers.
              print("See all Offers tapped");
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

    // Handle empty state
    if (offerProviders.isEmpty) {
      // Optionally hide the section entirely or show an empty message
      // return const SizedBox.shrink();
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           header,
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
             alignment: Alignment.center,
             child: Text(
               "No special offers available right now.",
               style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
               textAlign: TextAlign.center,
             ),
           ),
         ],
       );
    }

    // Build the section with the horizontal list using the standard card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(
          height: 220, // Same height as other lists
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: offerProviders.length,
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            clipBehavior: Clip.none,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final provider = offerProviders[index];
              // Use the standard ServiceProviderCard
              return ServiceProviderCard(provider: provider);
            },
          ),
        ),
      ],
    );
  }
}
