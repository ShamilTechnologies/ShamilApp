import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data'; // For Uint8List
// Import shared constants/helpers
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

class HomeLoadingShimmer extends StatelessWidget {
  final String? userName; // Use default if needed (though likely not displayed in shimmer)
  final String? profileImageUrl; // Needed for the static Hero target

  const HomeLoadingShimmer({
    super.key,
    this.userName, // Kept for consistency, but not used in shimmer display
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerBaseColor = Colors.grey.shade300;
    final shimmerHighlightColor = Colors.grey.shade100;
    final radius = BorderRadius.circular(8);
    final profileBorderRadius = BorderRadius.circular(8.0); // Match ExploreTopSection
    const double avatarSize = 44.0; // Match ExploreTopSection

    // Use a Column, place the real Hero widget at the top right, shimmer the rest
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Top Section Placeholder (with real Hero for profile pic) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shimmer for Greeting/Location
            Shimmer.fromColors( // Wrap shimmer elements individually if needed
              baseColor: shimmerBaseColor,
              highlightColor: shimmerHighlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                  const Gap(8),
                  Container(width: 160, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                ],
              ),
            ),
            // *** Static Hero Widget for Profile Picture ***
            // NO PULSE OR REVOLVE ANIMATION HERE - Just the target for Hero transition
            Hero(
              tag: 'userProfilePic_hero', // Must match exactly
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Material(
                  shape: RoundedRectangleBorder(borderRadius: profileBorderRadius),
                  clipBehavior: Clip.antiAlias,
                  elevation: 1.0, // Minimal elevation
                  color: Colors.transparent, // Ensure background doesn't obscure shimmer below
                  child: InkWell( // Can keep InkWell structure if needed, but no action
                    onTap: null, // No tap action in shimmer state
                    child: ClipRRect(
                      borderRadius: profileBorderRadius,
                      child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                          ? buildProfilePlaceholder(avatarSize, theme, profileBorderRadius)
                          : FadeInImage.memoryNetwork( // Still use FadeInImage for consistency
                              placeholder: transparentImageData,
                              image: profileImageUrl!,
                              fit: BoxFit.cover,
                              width: avatarSize,
                              height: avatarSize,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return buildProfilePlaceholder(avatarSize, theme, profileBorderRadius);
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(24),

        // --- Rest of the Shimmer Layout ---
        Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Column( // Wrap remaining shimmer elements
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer for Search Bar
              Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
              const Gap(24),
              // Shimmer for Category Title
              Container(width: 120, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
              const Gap(12),
              // Shimmer for Category List
              SizedBox( height: 40, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: 6,
                  itemBuilder: (_, __) => Container(width: 80, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), margin: const EdgeInsets.only(right: 12)),
                ),
              ),
              const Gap(24),
              // Shimmer for Section Header
               Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(width: 140, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                  Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                ],
              ),
               const Gap(16),
              // Shimmer for Horizontal Card List
              SizedBox( height: 220, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: 3, padding: const EdgeInsets.symmetric(vertical: 4.0), clipBehavior: Clip.none,
                  itemBuilder: (_, __) => Container( width: 180, height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(right: 16) ),
                ),
              ),
              const Gap(24),
               // Shimmer for another Section Header
               Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(width: 160, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                  Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                ],
              ),
               const Gap(16),
               // Shimmer for another Horizontal Card List
              SizedBox( height: 220, child: ListView.builder( scrollDirection: Axis.horizontal, itemCount: 2, padding: const EdgeInsets.symmetric(vertical: 4.0), clipBehavior: Clip.none,
                  itemBuilder: (_, __) => Container( width: 180, height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(right: 16) ),
                ),
              ),
               const Gap(20), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }
}
