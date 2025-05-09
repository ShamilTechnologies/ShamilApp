// lib/feature/home/views/home_utils/explore_top_section.dart
// UPDATED to use the new ExploreTopSection content and manage search bar visibility
// ADDED rounding for status bar padding to mitigate SliverGeometry error

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Your AppColors
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_search_bar.dart';
import 'package:gap/gap.dart';
import 'dart:typed_data'; // For Uint8List
import 'dart:math'; // For pi and ceil
import 'package:shamil_mobile_app/core/constants/image_constants.dart'; // For transparentImageData
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'; // For buildProfilePlaceholder
// Import HomeBloc if search dispatches event directly from here
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';

// This is the ExploreTopSection widget content you provided earlier.
// In your project, this would likely be in its own file (e.g., new_explore_top_section_content.dart) and imported.
class NewExploreTopSectionContent extends StatefulWidget {
  final String currentCity;
  final String userName;
  final String? profileImageUrl;
  final VoidCallback onCityTap;
  final VoidCallback onProfileTap;
  final ThemeData theme; // Theme passed from delegate

  const NewExploreTopSectionContent({
    super.key,
    required this.currentCity,
    required this.userName,
    required this.profileImageUrl,
    required this.onCityTap,
    required this.onProfileTap,
    required this.theme, // Expect theme
  });

  @override
  State<NewExploreTopSectionContent> createState() =>
      _NewExploreTopSectionContentState();
}

class _NewExploreTopSectionContentState
    extends State<NewExploreTopSectionContent> with TickerProviderStateMixin {
  late AnimationController _revolveController;
  late AnimationController _tapController;
  late Animation<double> _scaleTapAnimation;

  @override
  void initState() {
    super.initState();
    _revolveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Speed of one full revolution
    )..repeat(); // Start repeating immediately

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleTapAnimation = Tween<double>(begin: 1.0, end: 1.08) // Expand slightly
        .animate(CurvedAnimation(
            parent: _tapController, curve: Curves.easeInOut)); // Smoother curve
  }

  @override
  void dispose() {
    _revolveController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleProfileTap() {
    _tapController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // Slightly longer delay for visual effect
        if (mounted) {
          _tapController.reverse();
        }
      });
      widget.onProfileTap(); // Call the passed callback
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme; // Use the theme passed from the delegate
    final borderRadius =
        BorderRadius.circular(12.0); // Consistent border radius
    const double avatarSize =
        48.0; // Slightly larger avatar for better presence
    const double borderStrokeWidth = 2.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Greeting and Location Selector
        Expanded(
          // Allow text to take available space and wrap if needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment
                .center, // Center content vertically in its allocated space
            children: [
              Text(
                "Hello, ${widget.userName} 👋",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryText ??
                      theme.colorScheme.onSurfaceVariant, // Use AppColors
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(4),
              Material(
                // Wrap InkWell with Material for splash effect to be visible if parent has color
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onCityTap,
                  borderRadius:
                      borderRadius, // Apply borderRadius for tap effect
                  splashColor: AppColors.primaryColor.withOpacity(0.1),
                  highlightColor: AppColors.primaryColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical:
                            2.0), // Minimal padding to not affect layout much
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Important for Column wrapping
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: AppColors.primaryColor, size: 20),
                        const Gap(6),
                        Flexible(
                          // Allow city name to take space but not overflow
                          child: Text(
                            widget.currentCity,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText ??
                                  theme.colorScheme.onSurface, // Use AppColors
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryColor, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(12), // Add some space before the profile picture

        // Right side: Profile Picture
        ScaleTransition(
          scale: _scaleTapAnimation,
          child: Hero(
            tag: 'userProfilePic_hero_main_explore', // Ensure unique Hero tag
            child: SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: AnimatedBuilder(
                animation: _revolveController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(borderStrokeWidth),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      shape: BoxShape.rectangle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.9),
                          AppColors.primaryColor.withOpacity(0.9),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [
                          0.0,
                          0.25,
                          0.30,
                          1.0
                        ], // Adjust for desired border segment
                        tileMode: TileMode.repeated,
                        transform:
                            GradientRotation(_revolveController.value * 2 * pi),
                      ),
                    ),
                    child: child, // The Material widget with InkWell and Image
                  );
                },
                child: Material(
                  // Inner content with clipping and tap effect
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  clipBehavior: Clip.antiAlias,
                  elevation: 0.0, // No elevation needed for the image itself
                  child: InkWell(
                    onTap: _handleProfileTap,
                    borderRadius: borderRadius,
                    child: (widget.profileImageUrl == null ||
                            widget.profileImageUrl!.isEmpty)
                        ? buildProfilePlaceholder(
                            avatarSize - (borderStrokeWidth * 2),
                            theme,
                            borderRadius) // Adjust size for padding
                        : FadeInImage.memoryNetwork(
                            placeholder:
                                transparentImageData, // from image_constants.dart
                            image: widget.profileImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity, // Fill the Material widget
                            height: double.infinity, // Fill the Material widget
                            imageErrorBuilder: (context, error, stackTrace) {
                              return buildProfilePlaceholder(
                                  avatarSize - (borderStrokeWidth * 2),
                                  theme,
                                  borderRadius);
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// This is the SliverPersistentHeaderDelegate
class ExploreTopSectionDelegate extends SliverPersistentHeaderDelegate {
  final ThemeData theme;
  final String currentCity;
  final VoidCallback onCityChangeRequest;
  final String userName;
  final String? userImageUrl;
  final Function(String) onSearchChanged; // Callback for search query changes
  final VoidCallback onProfileTap; // *** ADDED: Callback for profile tap ***

  // Define heights for the header components
  final double _userInfoSectionHeight =
      70.0; // Height for the user info/location row
  final double _searchBarSectionHeight =
      50.0; // Height for the search bar itself
  final double _paddingBetweenSections =
      12.0; // Vertical padding between user info and search bar
  final double _bottomPadding =
      8.0; // Bottom padding for the entire delegate content
  final double _topInternalPadding =
      12.0; // Top padding inside the delegate, below status bar

  ExploreTopSectionDelegate({
    required this.theme,
    required this.currentCity,
    required this.onCityChangeRequest,
    required this.userName,
    required this.userImageUrl,
    required this.onSearchChanged,
    required this.onProfileTap, // *** ADDED ***
  });

  // *** UPDATED EXTENT CALCULATIONS ***
  // Use ceil() on status bar padding to avoid potential floating point issues
  double _getStatusBarPadding(BuildContext context) =>
      MediaQuery.of(context).padding.top.ceilToDouble();

  @override
  double get maxExtent {
    // Use a local BuildContext (though less ideal in delegate getters)
    // or assume a standard context exists when called. For safety,
    // might be better to pass context or calculate elsewhere if possible.
    // Here, we risk accessing context incorrectly if called outside build.
    // A safer approach might be to require the height to be passed in.
    // For this fix, let's assume context is available when Flutter calls this.
    final statusBarPadding = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.single)
        .padding
        .top
        .ceilToDouble();
    return _userInfoSectionHeight +
        _searchBarSectionHeight +
        _paddingBetweenSections +
        _bottomPadding +
        _topInternalPadding +
        statusBarPadding;
  }

  @override
  double get minExtent {
    final statusBarPadding = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.single)
        .padding
        .top
        .ceilToDouble();
    return _userInfoSectionHeight + _topInternalPadding + statusBarPadding;
  }
  // *** END UPDATED EXTENT CALCULATIONS ***

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final topStatusBarPadding = _getStatusBarPadding(context); // Use helper
    final double currentExtent = maxExtent - shrinkOffset;

    // Calculate opacity and vertical offset for the search bar for a smooth collapse animation
    // Use calculated min/max extent values directly here
    final double calculatedMaxExtent = maxExtent;
    final double calculatedMinExtent = minExtent;

    final double animationRange = calculatedMaxExtent -
        calculatedMinExtent -
        _bottomPadding -
        _paddingBetweenSections; // Range over which search bar animates
    double searchBarOpacity = 1.0;
    double searchBarVerticalPositionFactor =
        0.0; // 0.0 = fully visible, 1.0 = fully hidden/offset

    if (animationRange > 0) {
      // Calculate how much of the "collapsible" part (search bar area) has been scrolled
      double collapsiblePartHeight = calculatedMaxExtent -
          calculatedMinExtent -
          _bottomPadding; // Total height that collapses
      double scrolledDistance = calculatedMaxExtent -
          currentExtent; // How much has been scrolled off the top
      double scrolledRatioInAnimationRange =
          (scrolledDistance / animationRange).clamp(0.0, 1.0);

      searchBarOpacity = (1.0 - scrolledRatioInAnimationRange * 1.5)
          .clamp(0.0, 1.0); // Fade out faster
      searchBarVerticalPositionFactor = scrolledRatioInAnimationRange;
    } else {
      // If no range (e.g. minExtent is too close to maxExtent)
      searchBarOpacity = currentExtent > calculatedMinExtent ? 1.0 : 0.0;
    }

    return Container(
      color: AppColors.lightBackground, // Match ExploreScreen background
      padding: EdgeInsets.only(
        top: topStatusBarPadding + _topInternalPadding,
        left: 16.0,
        right: 16.0,
        bottom: _bottomPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // --- Top Row: User Info, Location, Profile Pic ---
          SizedBox(
            // Ensure height calculation doesn't introduce float errors
            height: _userInfoSectionHeight, // Use the defined height directly
            child: NewExploreTopSectionContent(
              currentCity: currentCity,
              userName: userName,
              profileImageUrl: userImageUrl,
              onCityTap: onCityChangeRequest,
              onProfileTap: onProfileTap, // *** Pass the callback ***
              theme: theme,
            ),
          ),
          // --- Search Bar (conditionally visible/animated) ---
          SizedBox(
            // Use SizedBox to control the space for the search bar and its animation
            height: _searchBarSectionHeight + _paddingBetweenSections,
            child: Opacity(
              opacity: searchBarOpacity,
              child: Transform.translate(
                // Slide up as it fades
                offset: Offset(
                    0,
                    -searchBarVerticalPositionFactor *
                        (_searchBarSectionHeight *
                            0.5)), // Slide up half its height
                child: Padding(
                  padding: EdgeInsets.only(
                      top:
                          _paddingBetweenSections), // Space between user info and search
                  child: ExploreSearchBar(
                    onSearch: onSearchChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ExploreTopSectionDelegate oldDelegate) {
    return theme != oldDelegate.theme ||
        currentCity != oldDelegate.currentCity ||
        userName != oldDelegate.userName ||
        userImageUrl != oldDelegate.userImageUrl ||
        onCityChangeRequest != oldDelegate.onCityChangeRequest ||
        onSearchChanged != oldDelegate.onSearchChanged ||
        onProfileTap != oldDelegate.onProfileTap; // *** ADDED ***
  }
}
