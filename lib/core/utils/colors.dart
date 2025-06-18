// lib/core/utils/colors.dart

import 'package:flutter/material.dart';

/// ShamilApp Color Palette
///
/// A comprehensive color system based on the explore screen design patterns.
/// Primary philosophy: Dark-first premium experience with gradient-heavy modern approach.
class AppColors {
  // ==================== PRIMARY BRAND COLORS ====================

  /// Primary Dark Blue - Main brand color
  /// Usage: Primary backgrounds, headers, navigation, brand elements
  static const Color primaryColor = Color(0xFF2A548D);

  /// Deep Space Navy - Premium dark foundation
  /// Usage: Deep dark backgrounds, modern dark theme base
  static const Color deepSpaceNavy = Color(0xFF0A0E1A);

  /// Medium Blue - Secondary brand complement
  /// Usage: Secondary accents, complementary elements
  static const Color secondaryColor = Color(0xFF6385C3);

  /// Light Ice Blue - Ethereal accent
  /// Usage: Light accents, subtle highlights, floating orbs
  static const Color accentColor = Color(0xFFE2F0FF);

  // ==================== ACCENT COLORS ====================

  /// Vibrant Teal - Primary accent color
  /// Usage: Call-to-action elements, success states, interactive highlights
  static const Color tealColor = Color(0xFF20C997);

  /// Electric Cyan - Information accent
  /// Usage: Information states, tech-focused elements
  static const Color cyanColor = Color(0xFF17A2B8);

  /// Electric Blue - Navigation accent
  /// Usage: Community navigation, electric highlights
  static const Color electricBlue = Color(0xFF00D4FF);

  /// Premium Blue - Signature premium color from configuration screen
  /// Usage: Premium buttons, premium containers, premium highlights
  static const Color premiumBlue = Color(0xFF3B82F6);

  /// Bottom Sheet Background - Deep dark blue for bottom sheets and feedback dialogs
  /// Usage: Bottom sheets, feedback dialogs, modal backgrounds
  static const Color bottomSheetBackground = Color(0xFF080F21);

  // ==================== BACKGROUND SYSTEM ====================

  /// Light Background - Off-white for light themes
  static const Color lightBackground = Color(0xFFF8F9FA);

  /// Dark Background - Standard dark theme
  static const Color darkBackground = Color(0xFF212529);

  /// Surface Colors
  static const Color surfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF2C3034);

  // ==================== DARK GRADIENT VARIANTS ====================

  /// Alternative dark navy variations for complex gradients
  static const Color darkNavy1 = Color(0xFF0F0F23);
  static const Color darkNavy2 = Color(0xFF1A1A2E);
  static const Color darkNavy3 = Color(0xFF16213E);

  // ==================== TEXT COLORS ====================

  /// Primary Text - White for dark theme (main content)
  /// Usage: Primary headings, main text content on dark backgrounds
  static const Color primaryText = Colors.white;

  /// Secondary Text - Light gray for less emphasis
  /// Usage: Subtitles, descriptions, less important text
  static const Color secondaryText = Color(0xFFB0B0B0);

  /// Muted Text - Medium opacity white for hints
  /// Usage: Placeholder text, disabled text, very subtle content
  static const Color mutedText = Color(0xFF6A737D);

  /// Light Text - White for dark backgrounds (alias for consistency)
  /// Usage: Any text that needs to be white on dark backgrounds
  static const Color lightText = Colors.white;

  /// Dark Text - Dark gray for light backgrounds (when needed)
  /// Usage: Only for light theme contexts or light backgrounds
  static const Color darkText = Color(0xFF212529);

  /// Link Text - Teal accent for links
  /// Usage: Clickable links, action text
  static const Color linkText = tealColor;

  // ==================== TEXT OPACITY VARIANTS ====================

  /// Primary text with high emphasis (90% opacity)
  static Color get primaryTextEmphasis => Colors.white.withOpacity(0.9);

  /// Primary text with medium emphasis (80% opacity)
  static Color get primaryTextMedium => Colors.white.withOpacity(0.8);

  /// Primary text with low emphasis (60% opacity)
  static Color get primaryTextSubtle => Colors.white.withOpacity(0.6);

  /// Primary text with very low emphasis (50% opacity)
  static Color get primaryTextHint => Colors.white.withOpacity(0.5);

  // ==================== STATUS & SEMANTIC COLORS ====================

  /// Success - Green for positive actions
  static const Color successColor = Color(0xFF28A745);
  static const Color greenColor = Color(0xFF28A745);

  /// Warning - Amber for caution
  static const Color warningColor = Color(0xFFFFC107);
  static const Color yellowColor = Color(0xFFD8A31A); // Gold variant

  /// Danger - Red for errors and critical actions
  static const Color dangerColor = Color(0xFFDC3545);
  static const Color redColor = Color(0xFFFF0000);

  /// Info - Cyan for informational content
  static const Color infoColor = Color(0xFF17A2B8);

  // ==================== NAVIGATION GRADIENT COLORS ====================

  /// Navigation: Passes
  static const Color passesPurple = Color(0xFF8B5CF6);
  static const Color passesPink = Color(0xFFEC4899);

  /// Navigation: Community
  static const Color communityTeal = Color(0xFF06B6D4);

  /// Navigation: Favorites
  static const Color favoritesOrange = Color(0xFFF97316);

  /// Navigation: Profile
  static const Color profileGreen = Color(0xFF10B981);

  // ==================== EXTENDED COLOR PALETTE ====================

  /// Extended colors for various UI elements
  static const Color orangeColor = Color(0xFFFD7E14);
  static const Color purpleColor = Color(0xFF6F42C1);
  static const Color pinkColor = Color(0xFFE83E8C);
  static const Color brownColor = Color(0xFF795548);
  static const Color darkBlue = Color(0xFF003366);
  static const Color limeGreen = Color(0xFFAFCC4C);
  static const Color indigoColor = Color(0xFF4B0082);
  static const Color goldColor = Color(0xFFFFD700);

  /// Standard white
  static const Color white = Color(0xFFFFFFFF);

  // ==================== GRADIENT DEFINITIONS ====================

  /// Main App Background Gradient
  /// Usage: Primary screen backgrounds, hero sections
  static LinearGradient get mainBackgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor, // #2A548D at 100%
          Color(0xF22A548D), // #2A548D at 95%
          Color(0xE62A548D), // #2A548D at 90%
          deepSpaceNavy, // #0A0E1A at 100%
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );

  /// Hero Section Gradient
  /// Usage: Hero headers, premium sections
  static LinearGradient get heroSectionGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor, // #2A548D
          Color(0xE62A548D), // #2A548D at 90%
          tealColor, // #20C997
          Color(0xCC2A548D), // #2A548D at 80%
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );

  /// Alternative Dark Gradient
  /// Usage: Secondary screens, modal backgrounds
  static LinearGradient get alternativeDarkGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkNavy1, // #0F0F23
          darkNavy2, // #1A1A2E
          darkNavy3, // #16213E
          darkNavy1, // #0F0F23
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );

  /// Primary Element Gradient
  /// Usage: Buttons, cards, interactive elements
  static LinearGradient get primaryElementGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor,
          Color(0xCC2A548D), // primaryColor at 80%
        ],
      );

  /// Teal Accent Gradient
  /// Usage: Call-to-action buttons, highlights
  static LinearGradient get tealAccentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tealColor,
          Color(0xCC20C997), // tealColor at 80%
        ],
      );

  /// Premium Configuration Gradient
  /// Usage: Premium buttons, cards, and containers to match configuration screen
  static LinearGradient get premiumConfigGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          premiumBlue,
          tealColor,
        ],
      );

  // ==================== NAVIGATION GRADIENTS ====================

  /// Explore Navigation Gradient
  static LinearGradient get exploreGradient => const LinearGradient(
        colors: [primaryColor, tealColor],
      );

  /// Passes Navigation Gradient
  static LinearGradient get passesGradient => const LinearGradient(
        colors: [passesPurple, passesPink],
      );

  /// Community Navigation Gradient
  static LinearGradient get communityGradient => const LinearGradient(
        colors: [communityTeal, electricBlue],
      );

  /// Favorites Navigation Gradient
  static LinearGradient get favoritesGradient => const LinearGradient(
        colors: [passesPink, favoritesOrange],
      );

  /// Profile Navigation Gradient
  static LinearGradient get profileGradient => const LinearGradient(
        colors: [profileGreen, communityTeal],
      );

  // ==================== GLASSMORPHISM COLORS ====================

  /// Glassmorphism Card Background
  /// Usage: Semi-transparent floating cards
  static LinearGradient get glassmorphismCardGradient => LinearGradient(
        colors: [
          white.withOpacity(0.15),
          white.withOpacity(0.05),
        ],
      );

  /// Glassmorphism Border Color
  /// Usage: Borders for glass cards
  static Color get glassmorphismBorder => white.withOpacity(0.2);

  /// Strong Glassmorphism Border
  /// Usage: Emphasized glass elements
  static Color get glassmorphismBorderStrong => white.withOpacity(0.3);

  // ==================== FLOATING ORB COLORS ====================

  /// Teal Orb Gradient
  /// Usage: Floating background orbs
  static RadialGradient get tealOrbGradient => RadialGradient(
        colors: [
          tealColor.withOpacity(0.3),
          Colors.transparent,
        ],
      );

  /// Light Blue Orb Gradient
  /// Usage: Secondary floating orbs
  static RadialGradient get lightBlueOrbGradient => RadialGradient(
        colors: [
          accentColor.withOpacity(0.2),
          Colors.transparent,
        ],
      );

  // ==================== SHADOW COLORS ====================

  /// Premium Shadow
  /// Usage: Elevated cards, floating elements
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ];

  /// Subtle Shadow
  /// Usage: Subtle elevation, light cards
  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  // ==================== UTILITY METHODS ====================

  /// Get status color based on string status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'succeeded':
        return successColor;
      case 'pending':
      case 'processing':
        return warningColor;
      case 'failed':
      case 'error':
      case 'cancelled':
        return dangerColor;
      case 'refunded':
        return infoColor;
      default:
        return secondaryText;
    }
  }

  /// Get category-specific gradient colors
  static LinearGradient getCategoryGradient(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'healthcare':
      case 'medical':
        return const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF00D4FF)]);
      case 'fitness':
      case 'sports':
        return const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)]);
      case 'beauty':
      case 'wellness':
        return const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF97316)]);
      case 'education':
      case 'learning':
        return const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]);
      case 'technology':
      case 'tech':
        return const LinearGradient(colors: [primaryColor, tealColor]);
      default:
        return primaryElementGradient;
    }
  }

  /// Create glassmorphism decoration
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
        gradient: glassmorphismCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glassmorphismBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
