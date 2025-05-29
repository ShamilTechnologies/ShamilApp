import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Modern app theme with glassmorphism and advanced animations
class AppTheme {
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration extraSlowAnimation = Duration(milliseconds: 800);

  // Spacing system
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius system
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 50.0;

  // Elevation system
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Glassmorphism decorations
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get modernCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: [
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
        ],
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Gradient backgrounds
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.8),
        ],
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.95),
          AppColors.lightBackground,
        ],
        stops: const [0.0, 0.25, 0.5],
      );

  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentColor,
          AppColors.secondaryColor,
        ],
      );

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationM,
        shadowColor: AppColors.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        elevation: elevationS,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  static ButtonStyle get glassmorphismButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryText,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Input decoration
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isError = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : AppColors.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(
          color: AppColors.redColor,
          width: 2,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
    );
  }

  // Animation helpers
  static Widget createShimmer({
    required Widget child,
    bool isLoading = true,
  }) {
    if (!isLoading) return child;

    return AnimatedContainer(
      duration: normalAnimation,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }

  static Widget createPulse({
    required Widget child,
    bool animate = true,
  }) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'succeeded':
        return AppColors.greenColor;
      case 'pending':
      case 'processing':
        return AppColors.orangeColor;
      case 'failed':
      case 'error':
      case 'cancelled':
        return AppColors.redColor;
      case 'refunded':
        return AppColors.infoColor;
      default:
        return AppColors.secondaryText;
    }
  }
}
