import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep for specific colors if theme doesn't cover
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Can be removed if using theme exclusively
import 'package:gap/gap.dart'; // Use Gap for spacing

class ExploreTopSection extends StatelessWidget {
  final String currentCity;
  final String userName; // User's first name for greeting
  final VoidCallback onCityTap; // Callback when city selector is tapped

  const ExploreTopSection({
    super.key,
    required this.currentCity,
    required this.userName,
    required this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically center
      children: [
        // Left side: Greeting and Location Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center column content vertically
          children: [
            // Greeting Text
            Text(
              "Hello, $userName 👋",
              // Use theme text style for consistency
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary, // Use secondary color from theme
                fontWeight: FontWeight.w500, // Medium weight
              ),
            ),
            const Gap(4), // Small gap

            // City Selector - Wrap in Material/InkWell for tap feedback
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCityTap,
                borderRadius: BorderRadius.circular(8), // Add slight rounding for tap effect
                splashColor: theme.colorScheme.primary.withOpacity(0.1),
                highlightColor: theme.colorScheme.primary.withOpacity(0.05),
                child: Padding( // Add padding for better tap area
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Row takes minimum space
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.primary, // Use theme primary color
                        size: 18, // Slightly smaller icon
                      ),
                      const Gap(4),
                      Text(
                        currentCity,
                        // Use a prominent theme style for the city name
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground, // Use default text color
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded, // Rounded dropdown icon
                        color: theme.colorScheme.primary, // Use theme primary color
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Right side: Notification Icon Button
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded, // Rounded notification icon
            color: theme.colorScheme.onBackground.withOpacity(0.7), // Use themed icon color
            size: 28,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            // TODO: Navigate to notifications screen
            print("Notifications tapped");
          },
        ),
      ],
    );
  }
}
