import 'package:flutter/material.dart';

/// Helper to build placeholder widget for profile pictures.
Widget buildProfilePlaceholder(double size, ThemeData theme, BorderRadius borderRadius) {
  return Container(
    width: size,
    height: size,
    // Decoration matches the Material shape/clip for consistency
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05), // Subtle background
      // borderRadius is applied by the parent ClipRRect/Material shape
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

// Add other placeholder widgets here if needed
