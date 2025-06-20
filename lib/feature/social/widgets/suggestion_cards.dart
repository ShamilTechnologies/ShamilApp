import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/social/data/suggestion_models.dart';

/// High-end suggestion card for home screen quick access
class CompactSuggestionCard extends StatefulWidget {
  final UserSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onDismiss;
  final double width;
  final bool showActions;

  const CompactSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.onConnect,
    this.onDismiss,
    this.width = 160,
    this.showActions = true,
  });

  @override
  State<CompactSuggestionCard> createState() => _CompactSuggestionCardState();
}

class _CompactSuggestionCardState extends State<CompactSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.suggestion.suggestedUser;

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealColor
                      .withOpacity(0.1 + 0.1 * _glowAnimation.value),
                  blurRadius: 20 + 10 * _glowAnimation.value,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTap();
                      },
                      onHover: _handleHover,
                      borderRadius: BorderRadius.circular(20),
                      splashColor: AppColors.tealColor.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile Picture with Status Indicator
                            Stack(
                              children: [
                                _buildProfilePicture(user),
                                if (widget.suggestion.isPromoted)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.tealColor,
                                            AppColors.accentColor,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const Gap(12),

                            // User Name
                            Text(
                              user.name,
                              style: getbodyStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const Gap(6),

                            // Suggestion Reason
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getSuggestionTypeColor(
                                        widget.suggestion.type)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getSuggestionTypeColor(
                                          widget.suggestion.type)
                                      .withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.suggestion.primaryReasonText,
                                style: getSmallStyle(
                                  color: _getSuggestionTypeColor(
                                      widget.suggestion.type),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            if (widget.showActions) ...[
                              const Gap(12),
                              _buildQuickActions(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(dynamic user) {
    final imageUrl = user.profilePicUrl ?? user.image ?? '';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.tealColor.withOpacity(0.3),
            AppColors.primaryColor.withOpacity(0.3),
          ],
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildAvatarPlaceholder(),
                errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final initials = widget.suggestion.suggestedUser.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.tealColor,
            AppColors.primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: getbodyStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.person_add_rounded,
            onTap: widget.onConnect ?? () {},
            color: AppColors.tealColor,
          ),
        ),
        const Gap(8),
        _buildActionButton(
          icon: Icons.close_rounded,
          onTap: widget.onDismiss ?? () {},
          color: Colors.grey,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double size = 36,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  Color _getSuggestionTypeColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.nearby:
        return AppColors.tealColor;
      case SuggestionType.governorate:
        return AppColors.primaryColor;
      case SuggestionType.mutualFriends:
        return AppColors.accentColor;
      case SuggestionType.trending:
        return Colors.orange;
      case SuggestionType.newToApp:
        return Colors.green;
      default:
        return AppColors.tealColor;
    }
  }
}

/// Expanded suggestion card for social hub
class ExpandedSuggestionCard extends StatefulWidget {
  final UserSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onDismiss;
  final bool showDetailedInfo;

  const ExpandedSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.onConnect,
    this.onDismiss,
    this.showDetailedInfo = true,
  });

  @override
  State<ExpandedSuggestionCard> createState() => _ExpandedSuggestionCardState();
}

class _ExpandedSuggestionCardState extends State<ExpandedSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.1,
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
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.suggestion.suggestedUser;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(
                0, MediaQuery.of(context).size.height * _slideAnimation.value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tealColor.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onTap();
                        },
                        borderRadius: BorderRadius.circular(24),
                        splashColor: AppColors.tealColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Profile Section
                              _buildProfileSection(user),

                              const Gap(16),

                              // Info Section
                              Expanded(
                                child: _buildInfoSection(user),
                              ),

                              const Gap(16),

                              // Actions Section
                              _buildActionsSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(dynamic user) {
    final imageUrl = user.profilePicUrl ?? user.image ?? '';

    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.tealColor.withOpacity(0.3),
                AppColors.primaryColor.withOpacity(0.3),
              ],
            ),
          ),
          child: ClipOval(
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildAvatarPlaceholder(user),
                    errorWidget: (context, url, error) =>
                        _buildAvatarPlaceholder(user),
                  )
                : _buildAvatarPlaceholder(user),
          ),
        ),

        // Status indicators
        if (widget.suggestion.isPromoted)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.tealColor,
                    AppColors.accentColor,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),

        // Confidence score indicator
        Positioned(
          bottom: -2,
          left: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getConfidenceColor(widget.suggestion.confidenceScore),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Text(
              '${(widget.suggestion.confidenceScore * 100).round()}%',
              style: getSmallStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Type Badge
        Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: getbodyStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSuggestionTypeColor(widget.suggestion.type)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSuggestionTypeColor(widget.suggestion.type)
                      .withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                _getSuggestionTypeLabel(widget.suggestion.type),
                style: getSmallStyle(
                  color: _getSuggestionTypeColor(widget.suggestion.type),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const Gap(6),

        // Primary Reason
        Text(
          widget.suggestion.primaryReasonText,
          style: getbodyStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        if (widget.showDetailedInfo) ...[
          const Gap(8),
          _buildDetailedInfo(user),
        ],
      ],
    );
  }

  Widget _buildDetailedInfo(dynamic user) {
    final details = <String>[];

    if (user.city?.isNotEmpty == true) {
      details.add(user.city!);
    }

    if (user.gender?.isNotEmpty == true) {
      details.add(user.gender!);
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.white.withOpacity(0.6),
          size: 12,
        ),
        const Gap(4),
        Expanded(
          child: Text(
            details.join(' • '),
            style: getSmallStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.person_add_rounded,
          onTap: widget.onConnect ?? () {},
          color: AppColors.tealColor,
          label: 'Connect',
        ),
        const Gap(8),
        _buildActionButton(
          icon: Icons.close_rounded,
          onTap: widget.onDismiss ?? () {},
          color: Colors.grey,
          label: 'Pass',
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required String label,
    bool isSecondary = false,
  }) {
    return Container(
      width: 80,
      height: 36,
      decoration: BoxDecoration(
        color: isSecondary ? Colors.transparent : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const Gap(4),
              Text(
                label,
                style: getSmallStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(dynamic user) {
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.tealColor,
            AppColors.primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: getbodyStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getSuggestionTypeColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.nearby:
        return AppColors.tealColor;
      case SuggestionType.governorate:
        return AppColors.primaryColor;
      case SuggestionType.mutualFriends:
        return AppColors.accentColor;
      case SuggestionType.trending:
        return Colors.orange;
      case SuggestionType.newToApp:
        return Colors.green;
      default:
        return AppColors.tealColor;
    }
  }

  String _getSuggestionTypeLabel(SuggestionType type) {
    switch (type) {
      case SuggestionType.nearby:
        return 'NEARBY';
      case SuggestionType.governorate:
        return 'LOCAL';
      case SuggestionType.mutualFriends:
        return 'MUTUAL';
      case SuggestionType.trending:
        return 'TRENDING';
      case SuggestionType.newToApp:
        return 'NEW';
      default:
        return 'SUGGESTED';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Horizontal suggestion carousel for home screen
class SuggestionCarousel extends StatelessWidget {
  final List<UserSuggestion> suggestions;
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final Function(UserSuggestion) onSuggestionTap;
  final Function(UserSuggestion)? onConnect;
  final Function(UserSuggestion)? onDismiss;

  const SuggestionCarousel({
    super.key,
    required this.suggestions,
    required this.title,
    this.subtitle,
    this.onSeeAll,
    required this.onSuggestionTap,
    this.onConnect,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealColor,
                      AppColors.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'See All',
                    style: getSmallStyle(
                      color: AppColors.tealColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Gap(16),

        // Carousel
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return CompactSuggestionCard(
                suggestion: suggestion,
                onTap: () => onSuggestionTap(suggestion),
                onConnect:
                    onConnect != null ? () => onConnect!(suggestion) : null,
                onDismiss:
                    onDismiss != null ? () => onDismiss!(suggestion) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
