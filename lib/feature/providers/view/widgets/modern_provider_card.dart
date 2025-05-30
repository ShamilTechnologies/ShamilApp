import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

/// Modern Provider Card Widget
class ModernProviderCard extends StatefulWidget {
  final ServiceProviderDisplayModel provider;
  final VoidCallback onTap;
  final Duration animationDelay;

  const ModernProviderCard({
    super.key,
    required this.provider,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  State<ModernProviderCard> createState() => _ModernProviderCardState();
}

class _ModernProviderCardState extends State<ModernProviderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation with delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              Expanded(child: _buildInfoSection()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          // Main image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: widget.provider.imageUrl != null &&
                    widget.provider.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.provider.imageUrl!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Colors.grey[500],
                          size: 32,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          CupertinoIcons.building_2_fill,
                          color: Colors.grey[500],
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        CupertinoIcons.building_2_fill,
                        color: Colors.grey[500],
                        size: 32,
                      ),
                    ),
                  ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Featured badge
          if (widget.provider.isFeatured)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.star_fill,
                      color: Colors.white,
                      size: 12,
                    ),
                    const Gap(4),
                    Text(
                      'Featured',
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Category badge
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.provider.businessCategory,
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name
          Text(
            widget.provider.businessName,
            style: AppTextStyle.getTitleStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Gap(6),

          // Rating and reviews
          if (widget.provider.averageRating > 0)
            Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.orange,
                  size: 14,
                ),
                const Gap(4),
                Text(
                  widget.provider.averageRating.toStringAsFixed(1),
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Gap(4),
                Text(
                  '(${widget.provider.ratingCount})',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

          const Gap(6),

          // Location
          Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                color: AppColors.secondaryText,
                size: 12,
              ),
              const Gap(4),
              Expanded(
                child: Text(
                  widget.provider.city,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Gap(8),

          // Description
          if (widget.provider.shortDescription != null &&
              widget.provider.shortDescription!.isNotEmpty)
            Expanded(
              child: Text(
                widget.provider.shortDescription!,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const Gap(8),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                'View Details',
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
