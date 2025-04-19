import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import package

// Placeholder Model - Replace with your actual Banner data model
class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? targetId; // e.g., providerId to navigate to
  final String? targetType; // e.g., 'provider', 'offer', 'external_link'

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.targetId,
    this.targetType,
  });
}


class ExploreBannerCarousel extends StatefulWidget {
  // TODO: Replace with actual BannerModel list fetched from Bloc/backend
  final List<BannerModel> banners;

  const ExploreBannerCarousel({super.key, required this.banners});

  @override
  State<ExploreBannerCarousel> createState() => _ExploreBannerCarouselState();
}

class _ExploreBannerCarouselState extends State<ExploreBannerCarousel> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use placeholder data if the passed list is empty
    final displayBanners = widget.banners.isEmpty
        ? _getPlaceholderBanners()
        : widget.banners;

    if (displayBanners.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no banners
    }

    return Column(
      children: [
        SizedBox(
          height: 150, // Adjust height as needed
          child: PageView.builder(
            controller: _pageController,
            itemCount: displayBanners.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final banner = displayBanners[index];
              return _buildBannerCard(context, banner);
            },
          ),
        ),
        const Gap(12), // Space between carousel and indicator
        // Page Indicator
        SmoothPageIndicator(
           controller: _pageController,
           count: displayBanners.length,
           effect: ExpandingDotsEffect( // Example effect
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.secondary.withOpacity(0.3),
              // paintStyle: PaintingStyle.stroke, // Optional outline style
           ),
        ),
      ],
    );
  }

  // Builds a single card within the carousel
  Widget _buildBannerCard(BuildContext context, BannerModel banner) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(16.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0), // Space between pages
      child: Card(
         shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
         clipBehavior: Clip.antiAlias,
         elevation: 3.0,
         shadowColor: Colors.black.withOpacity(0.1),
         child: InkWell(
           onTap: () {
             // TODO: Handle banner tap based on targetType and targetId
             print("Banner tapped: ${banner.title} (Target: ${banner.targetType}/${banner.targetId})");
             // Example: if (banner.targetType == 'provider' && banner.targetId != null) {
             //   push(context, ServiceProviderDetailScreen(providerId: banner.targetId!));
             // }
           },
           borderRadius: cardBorderRadius,
           child: Stack(
             fit: StackFit.expand,
             children: [
               // Background Image
               Positioned.fill(
                 child: FadeInImage.assetNetwork( // Or use memoryNetwork if needed
                   // Use a placeholder asset or transparent image constant
                   placeholder: 'assets/images/placeholder_banner.png', // ADD A PLACEHOLDER ASSET
                   image: banner.imageUrl,
                   fit: BoxFit.cover,
                   imageErrorBuilder: (context, error, stackTrace) {
                     return Container(
                       color: Colors.grey.shade300,
                       child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade600)),
                     );
                   },
                 ),
               ),
               // Optional: Gradient overlay for text legibility
               Positioned(
                 bottom: 0, left: 0, right: 0, height: 60,
                 child: Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.vertical(bottom: cardBorderRadius.bottomLeft),
                     gradient: LinearGradient(
                       colors: [ Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.0)],
                       begin: Alignment.bottomCenter, end: Alignment.topCenter,
                       stops: const [0.0, 0.9]
                     ),
                   ),
                 ),
               ),
               // Optional: Title Text
               Positioned(
                 bottom: 10, left: 12, right: 12,
                 child: Text(
                   banner.title,
                   style: theme.textTheme.titleMedium?.copyWith(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                       shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)]),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
         ),
      ),
    );
  }

  // Placeholder data generator
  List<BannerModel> _getPlaceholderBanners() {
    return [
      BannerModel(id: '1', imageUrl: 'https://placehold.co/600x300/019444/FFF?text=Offer+1', title: 'Special Discount This Week!'),
      BannerModel(id: '2', imageUrl: 'https://placehold.co/600x300/3498db/FFF?text=New+Venue', title: 'New Gym Opening Soon'),
      BannerModel(id: '3', imageUrl: 'https://placehold.co/600x300/e74c3c/FFF?text=Event', title: 'Upcoming Fitness Event'),
    ];
  }
}

