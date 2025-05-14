// lib/feature/home/views/home_utils/explore_top_section.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'
    as app_placeholders;
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
// Assuming your AuthBloc states are defined in auth_state.dart and AuthBloc in auth_bloc.dart
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_search_bar.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'
    hide buildProfilePlaceholder;

// Adjusted height for better integration with home screen
const double _kExpandedHeight = 180.0;
const double _kToolbarHeightStandard = kToolbarHeight;

class ExploreTopSectionDelegate extends SliverPersistentHeaderDelegate {
  final String currentCityDisplay;
  final VoidCallback onSearchTap;
  final Function(String) onCitySelected;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final double topSafeAreaPadding;

  ExploreTopSectionDelegate({
    required this.currentCityDisplay,
    required this.onSearchTap,
    required this.onCitySelected,
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.topSafeAreaPadding,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final topSafeArea = MediaQuery.of(context).padding.top;
    final double currentExtent =
        (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final double progress =
        ((maxExtent - currentExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);

    final double contentOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);

    // Transform values for animated elements
    final double greetingScale = (1.0 - 0.05 * progress).clamp(0.95, 1.0);
    final double searchBarScale = (1.0 - 0.05 * progress).clamp(0.95, 1.0);

    // Scroll indicator
    final double scrollIndicatorOpacity = progress * 0.8;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Container(
        // Fully transparent to let home background show through
        color: Colors.transparent,
        child: Stack(
          children: [
            // Optional subtle overlay for better text readability when scrolling
            Positioned.fill(
              child: Opacity(
                opacity: progress * 0.3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),

            // Main Content Container
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // User info section (greeting + location)
                    Positioned(
                      top: topSafeArea + 16,
                      left: 20,
                      right: 20,
                      child: Opacity(
                        opacity: contentOpacity,
                        child: Transform.scale(
                          scale: greetingScale,
                          alignment: Alignment.topLeft,
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              String greeting = "Good Morning!";
                              String userName = "Guest";
                              String? profilePicUrl;
                              String authUserNameForPlaceholder = "G";

                              if (authState is LoginSuccessState) {
                                final AuthModel? currentUser = authState.user;
                                if (currentUser != null) {
                                  authUserNameForPlaceholder = currentUser.name;
                                  userName = authUserNameForPlaceholder
                                      .split(' ')
                                      .first;

                                  // Dynamic greeting based on time of day
                                  final hour = DateTime.now().hour;
                                  if (hour < 12) {
                                    greeting = "Good Morning";
                                  } else if (hour < 17) {
                                    greeting = "Good Afternoon";
                                  } else {
                                    greeting = "Good Evening";
                                  }

                                  greeting = "$greeting, $userName!";
                                  profilePicUrl = currentUser.profilePicUrl ??
                                      currentUser.image;
                                }
                              } else if (authState is AuthLoadingState) {
                                greeting = "Loading...";
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left: greeting + city selector
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Greeting
                                        Text(
                                          greeting,
                                          style: app_text_style
                                              .getHeadlineTextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Gap(12),

                                        // Location pill
                                        _buildLocationPill(context),
                                      ],
                                    ),
                                  ),

                                  const Gap(12),

                                  // Right: action buttons
                                  Row(
                                    children: [
                                      // Notification button
                                      _buildActionButton(
                                        icon: CupertinoIcons.bell,
                                        onTap: onNotificationsTap,
                                      ),
                                      const Gap(12),

                                      // Profile avatar
                                      Hero(
                                        tag: 'userProfilePic_hero_main',
                                        child: GestureDetector(
                                          onTap: onProfileTap,
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: app_placeholders
                                                  .buildProfilePlaceholder(
                                                imageUrl: profilePicUrl,
                                                name:
                                                    authUserNameForPlaceholder,
                                                size: 40,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.15),
                                                textColor: Colors.white,
                                                defaultIcon:
                                                    Icons.person_rounded,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Search bar
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 16 + (progress * 8),
                      child: Opacity(
                        opacity: contentOpacity,
                        child: Transform.scale(
                          scale: searchBarScale,
                          child: _buildSearchBar(),
                        ),
                      ),
                    ),

                    // Modern scroll indicator (replaces app bar)
                    if (progress > 0.05)
                      Positioned(
                        top: topSafeArea + 6,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: scrollIndicatorOpacity,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.location_solid,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentCityDisplay.isNotEmpty
                                        ? currentCityDisplay
                                        : "Explore",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean, minimal location pill
  Widget _buildLocationPill(BuildContext context) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final selectedCity =
            await showGovernoratesBottomSheet(context, currentCityDisplay);
        if (selectedCity != null && selectedCity != currentCityDisplay) {
          onCitySelected(selectedCity);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.location_solid,
              color: Colors.white,
              size: 14,
            ),
            const Gap(6),
            Text(
              currentCityDisplay.isNotEmpty
                  ? currentCityDisplay
                  : "Select City",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
            const Gap(6),
            const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  // Simple, clean action button
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 40,
          width: 40,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced search bar with shadow
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExploreSearchBar(
        onSearch: (_) => onSearchTap(),
      ),
    );
  }

  @override
  double get maxExtent => _kExpandedHeight + topSafeAreaPadding;

  @override
  double get minExtent => _kToolbarHeightStandard + topSafeAreaPadding;

  @override
  bool shouldRebuild(covariant ExploreTopSectionDelegate oldDelegate) {
    return currentCityDisplay != oldDelegate.currentCityDisplay ||
        onSearchTap != oldDelegate.onSearchTap ||
        onCitySelected != oldDelegate.onCitySelected ||
        onProfileTap != oldDelegate.onProfileTap ||
        onNotificationsTap != oldDelegate.onNotificationsTap ||
        topSafeAreaPadding != oldDelegate.topSafeAreaPadding;
  }
}

// Beautiful wave pattern painter for background
class _WavePatternPainter extends CustomPainter {
  final Color color;

  _WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw flowing wave pattern
    final path = Path();

    // First wave
    path.moveTo(0, size.height * 0.3);
    for (int i = 0; i < 6; i++) {
      path.cubicTo(
        size.width * (0.1 + i * 0.15),
        size.height * 0.25,
        size.width * (0.15 + i * 0.15),
        size.height * 0.35,
        size.width * (0.2 + i * 0.15),
        size.height * 0.3,
      );
    }

    // Second wave
    path.moveTo(0, size.height * 0.6);
    for (int i = 0; i < 5; i++) {
      path.cubicTo(
        size.width * (0.15 + i * 0.2),
        size.height * 0.55,
        size.width * (0.25 + i * 0.2),
        size.height * 0.65,
        size.width * (0.35 + i * 0.2),
        size.height * 0.6,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
