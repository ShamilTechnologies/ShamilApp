// lib/feature/home/widgets/explore_banner_carousel.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening external URLs

// Models
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';

// Import the shared image constants file where transparentImageData is defined
// Assuming the path is something like this:
// import 'package:shamil_mobile_app/core/constants/image_constants.dart';

// Optional: Define AppColors or use Theme.of(context)


class ExploreBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;
  final bool isLoading; // Flag to indicate if banners are still loading

  const ExploreBannerCarousel({
    super.key,
    required this.banners,
    this.isLoading = false, // Default to not loading
  });

  @override
  State<ExploreBannerCarousel> createState() => _ExploreBannerCarouselState();
}

class _ExploreBannerCarouselState extends State<ExploreBannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9); // Show parts of adjacent banners
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      // Use floor() or round() depending on desired sensitivity
      final currentPageCandidate = _pageController.page?.round() ?? 0;
      if (currentPageCandidate != _currentPage) {
        // Use mounted check before calling setState
        if (mounted) {
          setState(() {
            _currentPage = currentPageCandidate;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Banner Tap Handler ---
  void _handleBannerTap(BuildContext context, BannerModel banner) async {
    print("Banner Tapped: ${banner.id}, Type: ${banner.targetType}, Target: ${banner.targetId ?? banner.targetUrl}");

    // Example navigation logic - adapt based on your app's routing and target types
    final targetType = banner.targetType?.toLowerCase();
    final targetId = banner.targetId;
    final targetUrl = banner.targetUrl;

    if (targetType == 'serviceprovider' && targetId != null) {
      // Navigate to ServiceDetailsScreen
      // Replace with your actual navigation call
      print("Navigate to Service Provider Details: $targetId");
      if (mounted) { // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigate to Provider: $targetId")));
      }

    } else if (targetType == 'category' && targetId != null) {
      // Navigate to a category screen or trigger a filter event
      // Replace with your actual event dispatch or navigation
      print("Navigate/Filter by Category: $targetId");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Filter by Category: $targetId")));
      }

    } else if (targetType == 'externalurl' && targetUrl != null) {
      // Open external URL
      final Uri? uri = Uri.tryParse(targetUrl);
      if (uri != null) {
        try {
           bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
           if (!launched && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open link: $targetUrl")));
           }
        } catch (e) {
           print("Error launching URL: $e");
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error opening link: $targetUrl")));
           }
        }
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid link format: $targetUrl")));
      }
    } else if (targetUrl != null) {
       // Fallback: Try opening targetUrl if type is unknown or ID is missing
       final Uri? uri = Uri.tryParse(targetUrl);
        if (uri != null) {
          try {
             bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
             if (!launched && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not open link: $targetUrl")));
             }
          } catch (e) {
             print("Error launching URL: $e");
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error opening link: $targetUrl")));
             }
          }
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid link format: $targetUrl")));
        }
    } else {
      // No action defined
      print("Banner has no defined action.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate height dynamically based on screen width, capped at a max height
    final double screenWidth = MediaQuery.of(context).size.width;
    final double calculatedHeight = screenWidth * 0.4;
    final double carouselHeight = calculatedHeight.clamp(150.0, 250.0); // Example min/max heights

    // --- Loading State ---
    if (widget.isLoading) {
      return _buildLoadingShimmer(carouselHeight);
    }

    // --- Empty State ---
    if (widget.banners.isEmpty) {
      return SizedBox(
        height: carouselHeight, // Use consistent height
        child: const Center(
          child: Text(
            'No banners available right now.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // --- Loaded State ---
    return Column(
      mainAxisSize: MainAxisSize.min, // Take only needed vertical space
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              // Add padding between pages
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0), // Space between banners
                child: _buildBannerItem(context, banner),
              );
            },
            // Optional: Add accessibility semantics
            // physics: const PageScrollPhysics(),
            // allowImplicitScrolling: true,
          ),
        ),
        // Conditionally show dots only if more than one banner
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8), // Space between carousel and dots
          // --- Dot Indicators ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0, // Active dot is wider
                decoration: BoxDecoration(
                  // Use Theme colors for better adaptability
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ] else
          const SizedBox(height: 16), // Maintain some space even without dots
      ],
    );
  }

  // --- Build Banner Item ---
  Widget _buildBannerItem(BuildContext context, BannerModel banner) {
    final borderRadius = BorderRadius.circular(12.0);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.2),
      clipBehavior: Clip.antiAlias, // Important for borderRadius on image
      child: InkWell( // Use InkWell for tap feedback
        borderRadius: borderRadius,
        onTap: () => _handleBannerTap(context, banner),
        child: CachedNetworkImage(
          imageUrl: banner.imageUrl ?? '', // Provide a default empty string if null
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(),
          errorWidget: (context, url, error) => _buildImageErrorWidget("Cannot load banner"),
          // If you prefer FadeInImage with the constant:
          // placeholder: MemoryImage(transparentImageData), // Use the imported constant
          // fadeInDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  // --- Build Loading Shimmer ---
  Widget _buildLoadingShimmer(double height) {
    final shimmerBaseColor = Colors.grey.shade300;
    final shimmerHighlightColor = Colors.grey.shade100;
    final shimmerContentColor = Colors.white;
    final borderRadius = BorderRadius.circular(12.0);

    // Calculate item width based on viewport fraction and padding
    final double itemWidth = MediaQuery.of(context).size.width * 0.9 - 12.0; // viewportFraction 0.9, padding 6.0 * 2

    return SizedBox(
      height: height + 16, // Account for potential padding/dots space
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: ListView.builder( // Use ListView for horizontal shimmer effect
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Disable scroll for shimmer
          itemCount: 3, // Show a few shimmer items
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding if needed
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0), // Match PageView padding
            child: Container(
              width: itemWidth, // Use calculated width
              decoration: BoxDecoration(
                color: shimmerContentColor,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Build Image Placeholder ---
  Widget _buildImagePlaceholder() {
    // Consistent placeholder
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_outlined, // Use outlined version
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }

  // --- Build Image Error Widget ---
  Widget _buildImageErrorWidget(String message) {
    // Consistent error display
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, // Use outlined version
                color: Colors.grey.shade500, size: 40),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall // Use bodySmall for consistency
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
