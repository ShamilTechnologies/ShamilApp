import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

class HeroSection extends StatelessWidget {
  final List<String> headerImages;
  final ServiceProviderDisplayModel displayData;
  final bool isFavorite;
  final String heroTag;
  final int carouselCurrentIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final VoidCallback onFavoriteToggle;

  const HeroSection({
    super.key,
    required this.headerImages,
    required this.displayData,
    required this.isFavorite,
    required this.heroTag,
    required this.carouselCurrentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 480,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(),
      actions: [],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: heroTag,
          child: _buildHeroContainer(context),
        ),
      ),
    );
  }

  Widget _buildHeroContainer(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.deepSpaceNavy),
      child: Stack(
        children: [
          _buildDynamicBackground(),
          Positioned.fill(
            child: _buildCarouselContainer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 8),
            tween: Tween(begin: 0.0, end: 1.0),
            onEnd: () {},
            builder: (context, value, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 60 + (30 * math.sin(value * 2 * math.pi)),
                    right: -100 + (20 * math.cos(value * math.pi)),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.3),
                            AppColors.tealColor.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 180 + (20 * math.cos(value * 1.5 * math.pi)),
                    left: -60 + (15 * math.sin(value * 1.2 * math.pi)),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.electricBlue.withOpacity(0.25),
                            AppColors.purpleColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 320 + (25 * math.sin(value * 0.8 * math.pi)),
                    right: 40 + (10 * math.cos(value * 1.8 * math.pi)),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.yellowColor.withOpacity(0.2),
                            AppColors.orangeColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselContainer(BuildContext context) {
    final bool noImagesAvailable = headerImages.isEmpty ||
        (headerImages.length == 1 && headerImages.first.isEmpty);

    return Container(
      margin: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            noImagesAvailable ? _buildFallbackState() : _buildImageCarousel(),
            _buildNavigation(context),
            if (headerImages.length > 1 && !noImagesAvailable)
              _buildIndicator(),
            _buildServiceProviderCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getCategoryGradient(displayData.businessCategory)
                .colors[0]
                .withOpacity(0.9),
            AppColors.getCategoryGradient(displayData.businessCategory)
                .colors[1]
                .withOpacity(0.7),
            AppColors.deepSpaceNavy.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Center(
                        child: Text(
                          displayData.businessName.isNotEmpty
                              ? displayData.businessName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.lightText,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return PageView.builder(
      controller: pageController,
      itemCount: headerImages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final imageUrl = headerImages[index];
        return _buildImagePage(imageUrl);
      },
    );
  }

  Widget _buildImagePage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFallbackState();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.3),
                  AppColors.tealColor.withOpacity(0.2),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.photo,
                  color: AppColors.lightText,
                  size: 24,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackState(),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => Navigator.of(context).pop(),
          ),
          Row(
            children: [
              _buildNavButton(
                icon: isFavorite
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                onTap: onFavoriteToggle,
                iconColor: isFavorite ? AppColors.dangerColor : null,
              ),
              const Gap(8),
              _buildNavButton(
                icon: CupertinoIcons.share,
                onTap: () => HapticFeedback.lightImpact(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.lightText,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    color: AppColors.lightText,
                    size: 10,
                  ),
                  const Gap(4),
                  Text(
                    "${carouselCurrentIndex + 1}/${headerImages.length}",
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.lightText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceProviderCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Row(
                      children: [
                        _buildLogoBadge(),
                        const Gap(12),
                        Expanded(child: _buildBusinessInfo()),
                        _buildActionButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.getCategoryGradient(displayData.businessCategory),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: displayData.businessLogoUrl != null &&
                displayData.businessLogoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: displayData.businessLogoUrl!,
                fit: BoxFit.cover,
                placeholder: (c, u) => _buildCompactLogoBadge(),
                errorWidget: (c, u, e) => _buildCompactLogoBadge(),
              )
            : _buildCompactLogoBadge(),
      ),
    );
  }

  Widget _buildCompactLogoBadge() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getCategoryGradient(displayData.businessCategory),
      ),
      child: Center(
        child: Text(
          displayData.businessName.isNotEmpty
              ? displayData.businessName[0].toUpperCase()
              : '?',
          style: AppTextStyle.getHeadlineTextStyle(
            color: AppColors.lightText,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayData.businessName,
          style: AppTextStyle.getHeadlineTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.tealColor, AppColors.electricBlue],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayData.businessCategory,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.lightText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.yellowColor, AppColors.orangeColor],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: AppColors.lightText,
                    size: 10,
                  ),
                  const Gap(2),
                  Text(
                    displayData.averageRating.toStringAsFixed(1),
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.lightText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.tealColor],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => HapticFeedback.lightImpact(),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              CupertinoIcons.arrow_right,
              color: AppColors.lightText,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
