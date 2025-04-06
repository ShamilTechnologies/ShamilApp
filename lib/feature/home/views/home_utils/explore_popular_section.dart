import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Keep if getSmallStyle is used, otherwise prefer theme
// Import the display model
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

// --- Constants moved to top level ---
// Transparent placeholder image data (1x1 pixel PNG)
const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
// Define the Uint8List variable at the top level
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

class ExplorePopularSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (passed from parent widget)
  final List<ServiceProviderDisplayModel> popularProviders;

  const ExplorePopularSection({
    super.key,
    required this.popularProviders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Section Header (using theme)
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Popular", // Or "Popular Near You"
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold), // Use titleLarge
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle "See all" navigation.
              print("See all Popular tapped");
            },
            child: Text(
              'See all',
              // Use theme text style for consistency
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // Handle empty state
    if (popularProviders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
            alignment: Alignment.center,
            child: Text(
              "No popular places found nearby yet.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10), // Keep consistent spacing
        ],
      );
    }

    // Build the section with the horizontal list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(
          height: 220, // Height for the horizontal list container
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), // Use bouncy scroll
            itemCount: popularProviders.length,
            // Padding handled by parent in home_view now
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            clipBehavior: Clip.none, // Allow shadows to be visible
            separatorBuilder: (context, index) =>
                const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = popularProviders[index];
              // Build the card item using the provided design
              return _buildNewCardItem(context, provider);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single card item with the new design.
  Widget _buildNewCardItem(
      BuildContext context, ServiceProviderDisplayModel provider) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(16.0);
    // Use placeholder if imageUrl is null or empty
    final String imageUrl = (provider.imageUrl != null &&
            provider.imageUrl!.isNotEmpty)
        ? provider.imageUrl!
        : 'https://placehold.co/340x400/e0e0e0/757575?text=No+Image'; // Placeholder URL

    final String ratingString =
        provider.rating?.toStringAsFixed(1) ?? 'N/A'; // Handle null rating
    // TODO: Add state management for isFavorite
    const bool isFavorite = false; // Placeholder favorite state

    return SizedBox(
      // Constrain card width
      width: 180,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
        elevation: 3.0,
        shadowColor: Colors.black.withOpacity(0.1),
        clipBehavior: Clip.antiAlias, // Clip child (Stack) to card shape
        margin:
            const EdgeInsets.only(bottom: 2.0), // Margin for shadow visibility
        child: InkWell(
          // Make card tappable with ripple
          onTap: () {
            // TODO: Handle item tap navigation.
            print("Item tapped: ${provider.businessName} (ID: ${provider.id})");
            // Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(providerId: provider.id)));
          },
          borderRadius: cardBorderRadius,
          child: Stack(
            fit: StackFit.expand, // Make stack fill the card
            children: [
              // Background Image
              Positioned.fill(
                child: FadeInImage.memoryNetwork(
                  // Use the defined Uint8List variable
                  placeholder: _transparentImageData,
                  image: imageUrl,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    // Error placeholder
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 40),
                      ),
                    );
                  },
                ),
              ),

              // Darker Gradient overlay from the bottom
              Positioned(
                bottom: 0, left: 0, right: 0, height: 100, // Gradient height
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        bottom: cardBorderRadius
                            .bottomLeft), // Apply radius only to bottom
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.0)
                      ],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      stops: const [0.0, 0.9], // Control gradient spread
                    ),
                  ),
                ),
              ),

              // Content positioned within the gradient area
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                      padding:
                          const EdgeInsets.all(12.0), // Padding for text/icons
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end, // Align items to bottom
                        children: [
                          // Left side: Title and Rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize
                                  .min, // Take minimum vertical space
                              children: [
                                // Title (Business Name)
                                Text(
                                  provider.businessName ??
                                      'Unknown Venue', // Handle null name
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1))
                                      ] // Text shadow
                                      ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                // Rating Row
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 18, color: AppColors.yellowColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      ratingString,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
                                    ),
                                    // Optional: Review Count
                                    // if (provider.reviewCount > 0) Text(" (${provider.reviewCount})", style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12),),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                              width: 8), // Space between text and icon button

                          // Right side: Circular Action Button (Favorite)
                          Material(
                            // Use material for ink response on Container
                            color: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {
                                // TODO: Implement favorite toggle logic
                                print(
                                    'Favorite tapped for ${provider.businessName}');
                              },
                              customBorder: const CircleBorder(),
                              splashColor: Colors.white.withOpacity(0.4),
                              child: Container(
                                padding: const EdgeInsets.all(
                                    6), // Padding inside circle
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 0.5) // Subtle border
                                    ),
                                child: Icon(
                                  // Show filled heart if favorite, outline otherwise
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18, // Icon size
                                  color: isFavorite
                                      ? AppColors.redColor
                                      : Colors.white, // Red if favorite
                                ),
                              ),
                            ),
                          ),
                        ],
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
