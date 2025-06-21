import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Modern app theme with glassmorphism and advanced animations
/// Updated to match auth screen colors and design
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

  // Glassmorphism decorations with auth screen styling
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get modernCardDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusXL),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealColor.withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Updated gradient backgrounds to match auth screens
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryColor,
          AppColors.tealColor,
        ],
      );

  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.darkNavy1,
          AppColors.darkNavy2,
          AppColors.darkNavy3,
          AppColors.deepSpaceNavy,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );

  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.tealColor,
          AppColors.electricBlue,
        ],
      );

  // Updated button styles to use tealColor
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.tealColor,
        foregroundColor: AppColors.primaryText,
        elevation: elevationM,
        shadowColor: AppColors.tealColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  static ButtonStyle get glassmorphismButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15),
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: spacingL, vertical: spacingM),
      );

  // Updated text styles for dark theme
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
    color: AppColors.primaryText,
  );

  // Updated input decoration to use tealColor
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
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: BorderSide(
          color: isError ? AppColors.redColor : AppColors.tealColor,
          width: 2.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusL),
        borderSide: const BorderSide(
          color: AppColors.redColor,
          width: 2,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
      labelStyle: TextStyle(
        color: AppColors.primaryText.withOpacity(0.8),
        fontSize: 16,
      ),
      hintStyle: TextStyle(
        color: AppColors.secondaryText.withOpacity(0.7),
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.tealColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Updated shimmer for dark theme
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
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.1),
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

  // Updated status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'succeeded':
        return AppColors.tealColor;
      case 'pending':
      case 'processing':
        return AppColors.orangeColor;
      case 'failed':
      case 'error':
      case 'cancelled':
        return AppColors.redColor;
      case 'refunded':
        return AppColors.electricBlue;
      default:
        return AppColors.secondaryText;
    }
  }

  // **NEW: Premium bottom sheet decoration**
  static BoxDecoration get premiumBottomSheetDecoration => BoxDecoration(
        color: AppColors.deepSpaceNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      );

  // **NEW: Premium floating action button decoration**
  static BoxDecoration get premiumFabDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tealColor,
            AppColors.electricBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // **NEW: Premium notification badge decoration**
  static BoxDecoration get premiumNotificationBadgeDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentColor, Colors.red],
        ),
        borderRadius: BorderRadius.circular(radiusS),
        border: Border.all(color: AppColors.primaryText, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // **NEW: Enhanced glassmorphism for navigation elements**
  static BoxDecoration get navigationGlassmorphism => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // **NEW: Premium text field decoration matching auth screens**
  static BoxDecoration get premiumTextFieldDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      );

  // **NEW: Premium focused text field decoration**
  static BoxDecoration get premiumFocusedTextFieldDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusL),
        border: Border.all(
          color: AppColors.tealColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
