import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
// *** Import the consolidated BannerModel ***
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart'; // Adjust path if needed

// *** REMOVED BannerModel class definition from here ***
// class BannerModel { ... }


class ExploreBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const ExploreBannerCarousel({super.key, required this.banners});

  @override
  State<ExploreBannerCarousel> createState() => _ExploreBannerCarouselState();
}

class _ExploreBannerCarouselState extends State<ExploreBannerCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9, // Show parts of adjacent banners
  );
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) { timer.cancel(); return; }
      int nextPage = _pageController.page!.round() + 1;
      if (nextPage >= widget.banners.length) { nextPage = 0; }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // Placeholder data generator (kept for fallback/testing)
  List<BannerModel> _getPlaceholderBanners() {
    // Use the imported BannerModel definition
    return [
      BannerModel(id: 'p1', imageUrl: 'https://placehold.co/600x300/019444/FFF?text=Offer+1', title: 'Special Discount This Week!'),
      BannerModel(id: 'p2', imageUrl: 'https://placehold.co/600x300/3498db/FFF?text=New+Venue', title: 'New Gym Opening Soon'),
      BannerModel(id: 'p3', imageUrl: 'https://placehold.co/600x300/e74c3c/FFF?text=Event', title: 'Upcoming Fitness Event'),
    ];
  }

  // Builds a single card within the carousel
  Widget _buildBannerCard(BuildContext context, BannerModel banner) {
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(16.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Card(
          shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
          child: InkWell(
            onTap: () {
              // Handle Banner Tap
              print("Banner tapped: ${banner.title} (Target: ${banner.targetType}/${banner.targetId})");
              if (banner.targetType == 'provider' && banner.targetId != null) {
                push(context, ServiceProviderDetailScreen(providerId: banner.targetId!, initialImageUrl: banner.imageUrl));
              } else if (banner.targetType == 'offer') {
                print("Navigate to Offer: ${banner.targetId}");
              } else if (banner.targetType == 'external_link' && banner.targetId != null) {
                print("Open External Link: ${banner.targetId}");
                // Example: launchUrl(Uri.parse(banner.targetId!)); // Requires url_launcher package
              }
            },
            borderRadius: cardBorderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image using CachedNetworkImage
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(context),
                    errorWidget: (context, url, error) => _buildImageErrorWidget(context),
                  ),
                ),
                // Gradient Overlay
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: cardBorderRadius.bottomLeft),
                      gradient: LinearGradient(
                        colors: [ Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.0)],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        stops: const [0.0, 1.0]
                      ),
                    ),
                  ),
                ),
                // Title Text
                Positioned(
                  bottom: 12, left: 14, right: 14,
                  child: Text(
                    banner.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 3, offset: const Offset(0,1))]),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  // Placeholder and Error Widgets
  Widget _buildImagePlaceholder(BuildContext context) {
     final shimmerBaseColor = AppColors.accentColor.withOpacity(0.4);
     final shimmerHighlightColor = AppColors.accentColor.withOpacity(0.1);
     return Shimmer.fromColors(
        baseColor: shimmerBaseColor, highlightColor: shimmerHighlightColor,
        child: Container(color: AppColors.white),
     );
  }

   Widget _buildImageErrorWidget(BuildContext context) {
      return Container(
        decoration: BoxDecoration( color: AppColors.secondaryColor.withOpacity(0.1) ),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AppColors.secondaryColor.withOpacity(0.5), size: 40),
        ),
      );
   }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayBanners = widget.banners.isEmpty ? _getPlaceholderBanners() : widget.banners;

    if (displayBanners.isEmpty) { return const SizedBox.shrink(); }

    return Column(
      children: [
        SizedBox(
          height: 160,
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
        const Gap(12),
        SmoothPageIndicator(
            controller: _pageController,
            count: displayBanners.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8, dotWidth: 8,
              activeDotColor: AppColors.primaryColor,
              dotColor: AppColors.secondaryColor.withOpacity(0.3),
            ),
        ),
      ],
    );
  }
}
