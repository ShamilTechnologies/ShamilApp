// lib/feature/home/widgets/service_provider_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons.heart/heart_fill
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
// Import placeholder image data and helper
import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // Contains transparentImageData
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'; // Use shared placeholder builder
// Import Detail Screen for Navigation
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:gap/gap.dart'; // Use Gap for spacing
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart'; // For dispatching favorite toggle

class ServiceProviderCard extends StatelessWidget {
  final ServiceProviderDisplayModel provider;
  final String heroTagPrefix;
  final VoidCallback? onTap;
  final double? cardWidth;

  const ServiceProviderCard({
    super.key,
    required this.provider,
    required this.heroTagPrefix,
    this.onTap,
    this.cardWidth = 200.0, // Slightly narrower for modern design
  });

  // Modernized styling constants
  static final BorderRadius _cardRadius = BorderRadius.circular(16.0);
  static final BorderRadius _logoRadius = BorderRadius.circular(12.0);
  static final BorderRadius _favoriteButtonRadius = BorderRadius.circular(12.0);
  static const double _favoriteButtonSize = 32.0;
  static const double _logoSize = 42.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String imageUrl = provider.imageUrl ?? '';
    final String logoUrl = provider.businessLogoUrl ?? '';
    final String ratingString = provider.averageRating.toStringAsFixed(1);
    final bool isFavorite = provider.isFavorite;
    final String uniqueHeroTag = '${heroTagPrefix}_${provider.id}';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: _cardRadius),
          elevation: 2.0, // Lower elevation for a flatter, modern look
          shadowColor: Colors.black.withOpacity(0.08),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 8.0, right: 4.0, left: 4.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Positioned.fill(
                child: Hero(
                  tag: uniqueHeroTag,
                  child: ClipRRect(
                    borderRadius: _cardRadius,
                    child: AspectRatio(
                      aspectRatio: 0.85,
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

              // Modern Gradient Overlay - More subtle
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _cardRadius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6, 0.9],
                    ),
                  ),
                ),
              ),

              // Modern favorite button
              Positioned(
                top: 8,
                right: 8,
                child:
                    _buildFavoriteButton(context, theme, provider, isFavorite),
              ),

              // Modern Content Layout
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rating chip - modern pill shape
                      if (provider.averageRating > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.yellowColor),
                              const Gap(4),
                              Text(
                                ratingString,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (provider.ratingCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Text(
                                    "(${provider.ratingCount})",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Business Name - Modern, clean typography
                      Text(
                        provider.businessName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),

                      // Category & City in single row with dot separator
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.businessCategory,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w300,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (provider.city != null &&
                              provider.city!.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text("•",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 8)),
                            ),
                            Flexible(
                              child: Text(
                                provider.city!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // If logo exists, show as a floating element
              if (logoUrl.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: _logoSize,
                    height: _logoSize,
                    decoration: BoxDecoration(
                      borderRadius: _logoRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: _logoRadius,
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CupertinoActivityIndicator(radius: 8),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.business_outlined,
                              color: Colors.grey[400], size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Modernized favorite button
  Widget _buildFavoriteButton(BuildContext context, ThemeData theme,
      ServiceProviderDisplayModel provider, bool isFavorite) {
    return Material(
      color: Colors.black.withOpacity(0.2),
      borderRadius: _favoriteButtonRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<HomeBloc>().add(ToggleFavoriteHome(
              providerId: provider.id, currentStatus: isFavorite));
        },
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          width: _favoriteButtonSize,
          height: _favoriteButtonSize,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              key: ValueKey<bool>(isFavorite),
              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: 18,
              color: isFavorite ? AppColors.redColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Simplified modern placeholder
  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      color: AppColors.secondaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.secondaryColor.withOpacity(0.3),
          size: 40,
        ),
      ),
    );
  }

  // Simplified error widget
  Widget _buildImageErrorWidget(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: _cardRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                color: Colors.grey.shade400, size: 32),
            const Gap(4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
