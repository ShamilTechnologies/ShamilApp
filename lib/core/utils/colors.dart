// lib/core/utils/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Existing Colors (as per your last definition)
  static const Color accentColor = Color(0xFFe2f0ff); // Light blue
  static const Color primaryColor = Color(0xFF2a548d); // Dark blue
  static const Color secondaryColor = Color(0xFF6385c3); // Medium blue
  static const Color yellowColor = Color(0xFFd8a31a); // Gold/Yellow
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color redColor = Color(0xFFFF0000); // Bright red

  // --- New Identity Colors Added ---
  static const Color greenColor =
      Color(0xFF28a745); // Green (e.g., for success, nature)
  static const Color orangeColor =
      Color(0xFFfd7e14); // Orange (e.g., for attention, energy)
  static const Color purpleColor =
      Color(0xFF6f42c1); // Purple (e.g., for creativity, immersive)
  static const Color tealColor =
      Color(0xFF20c997); // Teal (e.g., for aqua, wellness)
  static const Color pinkColor =
      Color(0xFFe83e8c); // Pink (e.g., for events, fun)
  static const Color brownColor =
      Color(0xFF795548); // Brown (e.g., for outdoors, rustic)
  static const Color cyanColor =
      Color(0xFF17a2b8); // Cyan (e.g., for tech, info)
  static const Color darkBlue =
      Color(0xFF003366); // A deeper, more corporate blue
  static const Color limeGreen =
      Color(0xFFAFCC4C); // A light, vibrant green for highlights
  static const Color indigoColor =
      Color(0xFF4B0082); // Indigo for a deep, rich feel
  static const Color goldColor =
      Color(0xFFFFD700); // A brighter gold for accents

  // Text Colors (Essential for good UI)
  static const Color primaryText =
      Color(0xFF212529); // Very dark grey, almost black
  static const Color secondaryText =
      Color(0xFF6A737D); // Medium grey for less emphasis
  static const Color lightText = Colors.white; // For text on dark backgrounds
  static const Color linkText = Color(0xFF007bff); // Standard link blue

  // Background & Surface Colors
  static const Color lightBackground =
      Color(0xFFF8F9FA); // Off-white, for main backgrounds
  static const Color darkBackground =
      Color(0xFF212529); // Dark theme background
  static const Color surfaceColor =
      Colors.white; // For cards, dialogs on light theme
  static const Color darkSurfaceColor =
      Color(0xFF2c3034); // For cards, dialogs on dark theme

  // Status & Semantic Colors
  static const Color successColor = Color(0xFF28a745);
  static const Color warningColor =
      Color(0xFFffc107); // A softer yellow for warnings
  static const Color dangerColor = Color(0xFFdc3545); // A standard danger red
  static const Color infoColor =
      Color(0xFF17a2b8); // Cyan for informational messages
}
