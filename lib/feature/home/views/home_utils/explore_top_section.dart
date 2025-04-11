import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep if AppColors are used for specifics
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Keep if getbodyStyle is used (though theme preferred)
import 'package:gap/gap.dart'; // For spacing
import 'dart:typed_data'; // For Uint8List

// Placeholder for transparent image data (Consider moving to a constants file)
const List<int> kTransparentImage = <int>[ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, ];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


class ExploreTopSection extends StatelessWidget {
  final String currentCity;
  final String userName;
  // Parameter for profile image URL
  final String? profileImageUrl;
  final VoidCallback onCityTap; // Callback for city selection tap

  const ExploreTopSection({
    super.key,
    required this.currentCity,
    required this.userName,
    required this.profileImageUrl, // URL passed from parent
    required this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(8.0); // Consistent radius
    const double avatarSize = 44.0; // Consistent avatar size

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items
      children: [
        // Left side: Greeting and Location Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Greeting Text
            Text(
              "Hello, $userName 👋", // Personalized greeting
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary, // Use theme colors
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(4), // Consistent spacing

            // City Selector (Tappable)
            Material(
              color: Colors.transparent, // Makes InkWell background transparent
              child: InkWell(
                onTap: onCityTap, // Trigger callback
                borderRadius: borderRadius, // Ripple effect matches shape
                splashColor: theme.colorScheme.primary.withOpacity(0.1),
                highlightColor: theme.colorScheme.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Tap area padding
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Prevent row from expanding
                    children: [
                      Icon( Icons.location_on_outlined, color: theme.colorScheme.primary, size: 18, ),
                      const Gap(4),
                      Text(
                        currentCity,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const Gap(4),
                      Icon( Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary, size: 20, ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Right side: Profile Picture with Hero Animation
        Hero(
          // Unique tag for the Hero animation. Must match the source widget's tag.
          tag: 'userProfilePic_hero',
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Material( // Provides shape and clipping for InkWell
              color: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell( // Make picture tappable
                onTap: () {
                  // Optional: Navigate to profile or handle tap
                  print("Profile picture tapped");
                  // Example: Navigate to Profile Tab (index 3) if using Bloc for navigation
                  // context.read<MainNavigationBloc>().add(ChangeTab(3));
                },
                child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                    ? buildProfilePlaceholder(avatarSize, theme, borderRadius) // Placeholder if no image URL
                    : FadeInImage.memoryNetwork( // Display image with fade-in
                        placeholder: _transparentImageData, // Transparent placeholder
                        image: profileImageUrl!, // Actual image URL
                        fit: BoxFit.cover, // Cover the container
                        width: avatarSize,
                        height: avatarSize,
                        imageErrorBuilder: (context, error, stackTrace) {
                          print("Error loading profile image: $error"); // Log error
                          return buildProfilePlaceholder(avatarSize, theme, borderRadius); // Placeholder on error
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// Helper to build placeholder widget for the profile picture.
/// Accepts size and borderRadius to match the actual image container.
Widget buildProfilePlaceholder(double size, ThemeData theme, BorderRadius borderRadius) {
  return Container(
    width: size,
    height: size,
    // Decoration matches the Material shape/clip for consistency
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05), // Subtle background
      // No need for border/radius here if parent Material/ClipRRect handles it
    ),
    child: Center(
      child: Icon(
        Icons.person_rounded, // Placeholder icon
        size: size * 0.6, // Icon size relative to container size
        color: theme.colorScheme.primary.withOpacity(0.4), // Themed icon color
      ),
    ),
  );
}
