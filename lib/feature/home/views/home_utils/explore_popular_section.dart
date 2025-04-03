import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
import 'package:shamil_mobile_app/core/utils/text_style.dart';
// Import the display model
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// Import the transparent image constant if defined elsewhere, or define here
// import 'package:shamil_mobile_app/path/to/constants.dart' show kTransparentImage;


// Transparent placeholder image data (1x1 pixel PNG)
const List<int> kTransparentImage = <int>[ // Keep as List<int> here
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
];

// *** FIX: Define the Uint8List variable at the top level ***
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


class ExplorePopularSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel (connected via HomeBloc/HomeView)
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
            "Popular", // Keep title simple or use "Popular Near You"
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Bolder title
          ),
          TextButton(
            onPressed: () {
              // TODO: Handle "See all" navigation.
              print("See all Popular tapped");
            },
            child: Text(
              'See all',
              style: getSmallStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
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
             padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
             alignment: Alignment.center,
             child: Text(
                "No popular places found nearby yet.",
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryColor),
                textAlign: TextAlign.center,
             ),
          ),
           const SizedBox(height: 10),
        ],
      );
    }

    // Build the section with the list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(
          height: 220, // Increased height slightly for new design elements
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularProviders.length,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            clipBehavior: Clip.none,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final provider = popularProviders[index];
              // Build the new card item design
              return _buildNewCardItem(context, provider);
            },
          ),
        ),
      ],
    );
  }


  /// Builds a single card item with the new design inspired by the screenshot.
  Widget _buildNewCardItem(BuildContext context, ServiceProviderDisplayModel provider) {
    final theme = Theme.of(context);
    // More pronounced border radius like the screenshot
    final cardBorderRadius = BorderRadius.circular(16.0);
    // Use placeholder if imageUrl is null or empty
    final String imageUrl = (provider.imageUrl != null && provider.imageUrl!.isNotEmpty)
        ? provider.imageUrl!
        : 'https://placehold.co/340x400/e0e0e0/757575?text=No+Image'; // Placeholder

    final String ratingString = provider.rating.toStringAsFixed(1);
    // TODO: Add state management for isFavorite
    const bool isFavorite = false; // Placeholder favorite state

    return GestureDetector(
      onTap: () {
        // TODO: Handle item tap navigation.
        print("Item tapped: ${provider.businessName} (ID: ${provider.id})");
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(providerId: provider.id)));
      },
      child: SizedBox(
        width: 180, // Wider cards to accommodate content better
        child: Card(
          // Use Card for elevation/shape from theme, but override if needed
          shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
          elevation: 3.0, // Slightly more elevation
          shadowColor: Colors.black.withOpacity(0.1), // Softer shadow
          clipBehavior: Clip.antiAlias, // Clip child (Image) to card shape
          margin: const EdgeInsets.only(bottom: 2.0), // Margin for shadow visibility
          child: Stack(
            fit: StackFit.expand, // Make stack fill the card
            children: [
              // Background Image
              Positioned.fill(
                child: FadeInImage.memoryNetwork(
                   // *** FIX: Use the defined Uint8List variable ***
                   placeholder: _transparentImageData,
                   image: imageUrl,
                   fit: BoxFit.cover,
                   imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                        ),
                      );
                   },
                ),
              ),

              // Darker Gradient overlay from the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                // Adjust height based on content, approx 40-50%
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only( // Apply radius only to bottom corners if needed
                       bottomLeft: cardBorderRadius.bottomLeft,
                       bottomRight: cardBorderRadius.bottomRight,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.85), // Darker start
                        Colors.black.withOpacity(0.0) // Fade to transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
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
                  padding: const EdgeInsets.all(12.0), // Padding for text/icons
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end, // Align items to bottom
                    children: [
                      // Left side: Title and Rating
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                          children: [
                             // Title (Business Name)
                            Text(
                              provider.businessName,
                              style: theme.textTheme.titleMedium?.copyWith( // Slightly smaller title
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                                 shadows: [ // Add subtle shadow to text for readability
                                     Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0,1))
                                 ]
                              ),
                              maxLines: 1, // Keep single line
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5), // Space between title and rating
                            // Rating Row
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: AppColors.yellowColor), // Use specific yellow/gold
                                const SizedBox(width: 4),
                                Text(
                                  ratingString,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                     color: Colors.white,
                                     fontWeight: FontWeight.w600
                                  ),
                                ),
                                 // Optional: Review Count
                                 // if (provider.reviewCount > 0)
                                 //   Text(
                                 //     " (${provider.reviewCount})",
                                 //     style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                 //   ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Space between text and icon button

                      // Right side: Circular Action Button (Favorite/Logo Placeholder)
                      InkWell( // Use InkWell for tap effect if IconButton styling is tricky
                         onTap: () {
                            // TODO: Implement favorite toggle logic
                            // Need to manage state (e.g., in Bloc or locally if simple)
                            print('Favorite tapped for ${provider.businessName}');
                         },
                         borderRadius: BorderRadius.circular(15), // Tap radius
                         child: Container(
                           padding: const EdgeInsets.all(6), // Padding inside circle
                           decoration: BoxDecoration(
                             // Semi-transparent background like screenshot
                             color: Colors.white.withOpacity(0.2),
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5) // Subtle border
                           ),
                           child: const Icon(
                             // Show filled heart if favorite, outline otherwise
                             isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                             size: 18, // Icon size
                             color: isFavorite ? AppColors.redColor : Colors.white, // Red if favorite
                           ),
                         ),
                      ),
                    ],
                  )
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
