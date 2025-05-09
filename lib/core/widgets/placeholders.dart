import 'package:flutter/material.dart';

/// Helper to build placeholder widget for profile pictures.
Widget buildProfilePlaceholder(
    double size, ThemeData theme, BorderRadius borderRadius) {
  // Ensure size is finite and positive
  final safeSize = size.isFinite ? size : 48.0;
  final iconSize = (safeSize * 0.6).clamp(24.0, safeSize);

  return Container(
    width: safeSize,
    height: safeSize,
    // Decoration matches the Material shape/clip for consistency
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05), // Subtle background
      // borderRadius is applied by the parent ClipRRect/Material shape
    ),
    child: Center(
      child: Icon(
        Icons.person_rounded, // Placeholder icon
        size: iconSize,
        color: theme.colorScheme.primary.withOpacity(0.4), // Themed icon color
      ),
    ),
  );
}

// Add other placeholder widgets here if needed
