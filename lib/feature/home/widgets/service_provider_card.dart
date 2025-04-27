import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart'; // Includes isFavorite
// import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // Not needed if transparentImageData is handled differently or not used
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';

class ServiceProviderCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;

  const ServiceProviderCard({
    super.key,
    required this.provider,
  });

  // Consistent styling
  static final BorderRadius _cardRadius = BorderRadius.circular(12.0);
  static final BorderRadius _squareRadius = BorderRadius.circular(8.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String imageUrl = provider.imageUrl ?? '';
    final String ratingString = provider.rating.toStringAsFixed(1);
    final bool isFavorite = provider.isFavorite;
    final String heroTag = 'providerImage_${provider.id}';
    const double favoriteButtonSize = 32.0;

    return SizedBox(
      width: 180, // Keep width or adjust as needed
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: _cardRadius),
        elevation: 4.0,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 4.0),
        child: InkWell(
          onTap: () {
            // *** MODIFICATION START ***
            // Navigate and pass the full 'provider' object as 'initialProviderData'
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ServiceProviderDetailScreen(
                providerId: provider.id,
                initialImageUrl: provider.imageUrl, // Keep for Hero transition continuity
                initialProviderData: provider,    // Pass the display model
              ),
            ));
            // *** MODIFICATION END ***
          },
          borderRadius: _cardRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image (Portrait Aspect Ratio)
              Positioned.fill(
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: _cardRadius,
                    child: AspectRatio(
                      aspectRatio: 2.0 / 3.0, // Portrait ratio
                      child: (imageUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildImagePlaceholder(context),
                              errorWidget: (context, url, error) =>
                                  _buildImageErrorWidget(context, "No Image"),
                            )
                          : _buildImageErrorWidget(context, "No Image"),
                    ),
                  ),
                ),
              ),

              // Darker Gradient overlay from the bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 90,
                child: Container(
                  /* ... gradient ... */
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(bottom: _cardRadius.bottomLeft),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.0)
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Content positioned at the bottom (Text and Favorite Button ONLY)
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 8.0),
                      child: Row(
                        // Row for Info - Fav Button
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Info Column (Expanded)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.businessName,
                                  /* ... styling ... */
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1))
                                      ]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(4),
                                Row(
                                  /* ... rating ... */
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 16, color: AppColors.yellowColor),
                                    const Gap(4),
                                    Text(
                                      ratingString,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w600),
                                    ),
                                    if (provider.reviewCount > 0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: Text(
                                          "(${provider.reviewCount})",
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: AppColors.white
                                                      .withOpacity(0.8)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Gap(8), // Space between info and button

                          // 2. Favorite Button (Square, 8px radius, Animated)
                          _buildFavoriteButton(context, theme, provider,
                              isFavorite, favoriteButtonSize),
                        ],
                      ))),
            ],
          ),
        ),
      ),
    );
  }

  // --- Placeholder and Error Widgets for CachedNetworkImage ---
  Widget _buildImagePlaceholder(BuildContext context) {
    // ... implementation remains the same ...
    final shimmerBaseColor = AppColors.accentColor.withOpacity(0.4);
    final shimmerHighlightColor = AppColors.accentColor.withOpacity(0.1);
    return Shimmer.fromColors(
      baseColor: shimmerBaseColor, highlightColor: shimmerHighlightColor,
      child: Container(color: AppColors.white), // Base color for shimmer
    );
  }

  Widget _buildImageErrorWidget(BuildContext context, String message) {
    // ... implementation remains the same ...
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withOpacity(0.1),
      ),
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              color: AppColors.secondaryColor.withOpacity(0.5), size: 40),
          const Gap(4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.secondaryColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          )
        ],
      )),
    );
  }

  // --- Helper for Animated Favorite Button ---
  Widget _buildFavoriteButton(
      BuildContext context,
      ThemeData theme,
      ServiceProviderDisplayModel provider,
      bool isFavorite,
      double buttonSize) {
    // ... implementation remains the same ...
    final Color backgroundColor =
        theme.colorScheme.background.withOpacity(0.5); // Darker shade
    final Color defaultIconColor = AppColors.white;
    final Color favoriteIconColor = AppColors.redColor;

    return Material(
      color: backgroundColor,
      borderRadius: _squareRadius, // Use 8px radius for square shape
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Dispatch event to HomeBloc
          context.read<HomeBloc>().add(ToggleFavoriteHome(
              providerId: provider.id, currentStatus: isFavorite));
        },
        borderRadius: _squareRadius,
        splashColor: AppColors.primaryColor.withOpacity(0.3),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                child: child,
              );
            },
            child: Icon(
              key: ValueKey<bool>(isFavorite), // Key for switcher
              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: 18,
              color: isFavorite ? favoriteIconColor : defaultIconColor,
            ),
          ),
        ),
      ),
    );
  }
}