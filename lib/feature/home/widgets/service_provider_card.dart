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
    this.cardWidth = 220.0, // Increased width for better layout
  });

  // Consistent styling constants
  static final BorderRadius _cardRadius = BorderRadius.circular(16.0);
  static final BorderRadius _logoRadius = BorderRadius.circular(12.0);
  static final BorderRadius _favoriteButtonRadius = BorderRadius.circular(10.0);
  static const double _favoriteButtonSize = 36.0;
  static const double _logoSize = 50.0;

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
          elevation: 4.0,
          shadowColor: Colors.black.withOpacity(0.1),
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

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _cardRadius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.0),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 0.8],
                    ),
                  ),
                ),
              ),

              // Favorite Button
              Positioned(
                top: 8,
                right: 8,
                child:
                    _buildFavoriteButton(context, theme, provider, isFavorite),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Business Name Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business Logo
                          if (logoUrl.isNotEmpty)
                            Container(
                              width: _logoSize,
                              height: _logoSize,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: _logoRadius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
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
                                      child: CupertinoActivityIndicator(
                                          radius: 10),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.business_outlined,
                                        color: Colors.grey[400], size: 24),
                                  ),
                                ),
                              ),
                            ),
                          // Business Name
                          Expanded(
                            child: Text(
                              provider.businessName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: _textShadow,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),

                      // Category & City
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.businessCategory,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                shadows: _textShadow,
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
                                      color: Colors.white.withOpacity(0.7))),
                            ),
                            Flexible(
                              child: Text(
                                provider.city!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: _textShadow,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        ],
                      ),
                      const Gap(6),

                      // Rating Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16, color: AppColors.yellowColor),
                            const Gap(4),
                            Text(
                              ratingString,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: _textShadow,
                              ),
                            ),
                            if (provider.ratingCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  "(${provider.ratingCount})",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    shadows: _textShadow,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shared text shadow for better readability
  static const List<Shadow> _textShadow = [
    Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1))
  ];

  Widget _buildImagePlaceholder(BuildContext context) {
    return buildProfilePlaceholder(
        double.infinity, Theme.of(context), _cardRadius);
  }

  Widget _buildImageErrorWidget(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: _cardRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_rounded, color: Colors.grey.shade400, size: 40),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, ThemeData theme,
      ServiceProviderDisplayModel provider, bool isFavorite) {
    final Color backgroundColor = Colors.black.withOpacity(0.4);
    final Color defaultIconColor = Colors.white.withOpacity(0.9);
    final Color favoriteIconColor = AppColors.redColor;

    return Material(
      color: backgroundColor,
      borderRadius: _favoriteButtonRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<HomeBloc>().add(ToggleFavoriteHome(
              providerId: provider.id, currentStatus: isFavorite));
        },
        borderRadius: _favoriteButtonRadius,
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          width: _favoriteButtonSize,
          height: _favoriteButtonSize,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                child: RotationTransition(
                  turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: Icon(
              key: ValueKey<bool>(isFavorite),
              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: 20,
              color: isFavorite ? favoriteIconColor : defaultIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
