import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Use text styles if needed, else rely on theme
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart'; // Import display model
import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // Import image constant
import 'package:shamil_mobile_app/core/functions/navigation.dart'; // Import navigation helper

class ServiceProviderCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;

  const ServiceProviderCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(16.0);
    // Use placeholder if imageUrl is null or empty
    final String imageUrl = (provider.imageUrl != null &&
            provider.imageUrl!.isNotEmpty)
        ? provider.imageUrl!
        : 'https://placehold.co/340x400/e0e0e0/757575?text=No+Image'; // Placeholder URL

    final String ratingString = provider.rating.toStringAsFixed(1);
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
            // Navigate to detail screen, passing the provider ID
            print("Card tapped: ${provider.businessName} (ID: ${provider.id})");
            //push(context, ServiceProviderDetailScreen(providerId: provider.id));
          },
          borderRadius: cardBorderRadius,
          child: Stack(
            fit: StackFit.expand, // Make stack fill the card
            children: [
              // Background Image
              Positioned.fill(
                child: FadeInImage.memoryNetwork(
                  // Use imported constant
                  placeholder: transparentImageData,
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
                        bottom: cardBorderRadius.bottomLeft // Apply radius only to bottom
                        ),
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
                                  provider.businessName, // Use directly
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
                                     if (provider.reviewCount > 0)
                                       Padding(
                                         padding: const EdgeInsets.only(left: 4.0),
                                         child: Text(
                                           "(${provider.reviewCount})",
                                           style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                          ),
                                       ),
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
