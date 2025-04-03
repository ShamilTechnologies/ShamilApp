import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors if needed
import 'package:shamil_mobile_app/core/utils/text_style.dart';
// Import the display model
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// Import or define kTransparentImage and convert it

// Transparent placeholder image data (1x1 pixel PNG)
const List<int> kTransparentImage = <int>[ // Defined locally for self-containment
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
];

// *** FIX: Define the Uint8List variable at the top level ***
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


class ExploreRecommendedSection extends StatelessWidget {
  // Accept a list of ServiceProviderDisplayModel
  final List<ServiceProviderDisplayModel> recommendedProviders;

  const ExploreRecommendedSection({
    super.key,
    required this.recommendedProviders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme

     // Section Header
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // Add padding below header
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Recommended For You", // Title
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
          ),
          TextButton( // Use TextButton
            onPressed: () {
              // TODO: Handle "See all" navigation for recommended items.
              print("See all Recommended tapped");
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
    if (recommendedProviders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header, // Show header even when empty
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
             alignment: Alignment.center,
             child: Text(
                "No recommendations found nearby yet.", // User-friendly message
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
        header, // Section header
        SizedBox(
          height: 220, // Match height of popular section for consistency
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedProviders.length,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0), // Padding for list
            clipBehavior: Clip.none, // Allow shadows
            separatorBuilder: (context, index) => const SizedBox(width: 16), // Space between cards
            itemBuilder: (context, index) {
              final provider = recommendedProviders[index];
              // Reuse the same card building logic from ExplorePopularSection
              return _buildCardItem(context, provider);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single card item - REUSING THE EXACT SAME LOGIC/STYLE as Popular Section
  /// This promotes consistency. If variations are needed, duplicate and modify.
  Widget _buildCardItem(BuildContext context, ServiceProviderDisplayModel provider) {
     final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(16.0); // Match popular section radius
    final String imageUrl = (provider.imageUrl != null && provider.imageUrl!.isNotEmpty)
        ? provider.imageUrl!
        : 'https://placehold.co/340x400/e0e0e0/757575?text=No+Image'; // Placeholder

    final String ratingString = provider.rating.toStringAsFixed(1);
    // TODO: Add state management for isFavorite
    const bool isFavorite = false; // Placeholder favorite state (same as popular)


    return GestureDetector(
      onTap: () {
        // TODO: Handle item tap navigation.
        print("Recommended Item tapped: ${provider.businessName} (ID: ${provider.id})");
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(providerId: provider.id)));
      },
      child: SizedBox(
        width: 180, // Match width of popular cards
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
          elevation: 3.0,
          shadowColor: Colors.black.withOpacity(0.1),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 2.0), // Margin for shadow
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Positioned.fill(
                child: FadeInImage.memoryNetwork(
                   // *** FIX: Use the defined Uint8List variable ***
                   placeholder: _transparentImageData,
                   image: imageUrl,
                   fit: BoxFit.cover,
                   imageErrorBuilder: (context, error, stackTrace) {
                      return Container( // Placeholder on error
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                        ),
                      );
                   },
                ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0, left: 0, right: 0, height: 100, // Match popular
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only( bottomLeft: cardBorderRadius.bottomLeft, bottomRight: cardBorderRadius.bottomRight),
                    gradient: LinearGradient(
                      colors: [ Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.0)],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.9],
                    ),
                  ),
                ),
              ),
              // Content (Title, Rating, Action Button)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Match popular
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                          children: [
                            Text( // Title
                              provider.businessName,
                              style: theme.textTheme.titleMedium?.copyWith( color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0,1))]),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row( // Rating
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: AppColors.yellowColor),
                                const SizedBox(width: 4),
                                Text( ratingString, style: theme.textTheme.bodyMedium?.copyWith( color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action Button (Favorite)
                      InkWell(
                         onTap: () { /* TODO: Implement favorite */ },
                         borderRadius: BorderRadius.circular(15),
                         child: Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration( color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5)),
                           child: const Icon( isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: isFavorite ? AppColors.redColor : Colors.white),
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
