import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Import text styles

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'BalooBhaijaan2', // Consistent font family using Baloo Bhaijaan

    // Updated scaffold background to match auth screens
    scaffoldBackgroundColor: AppColors.deepSpaceNavy,

    appBarTheme: AppBarTheme(
      // Use deep space navy for consistency with auth screens
      backgroundColor: AppColors.deepSpaceNavy,
      foregroundColor: AppColors.primaryText, // White text/icons on AppBar
      elevation: 0, // No elevation for modern look
      surfaceTintColor: Colors.transparent, // Prevent tinting on scroll
      titleTextStyle: getTitleStyle(
        color: AppColors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
          color: AppColors.primaryText, size: 24), // White icons
      centerTitle: true,
    ),

    // Updated bottom navigation to use tealColor
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.deepSpaceNavy, // Dark background
      elevation: 8.0, // Increased elevation for modern look
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.tealColor, // Teal for selected items
      unselectedItemColor: AppColors.secondaryText, // Gray for unselected
      selectedLabelStyle: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700), // Bold selected labels
      unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500), // Regular unselected labels
    ),

    // Updated bottom sheet theme to use deepSpaceNavy
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.deepSpaceNavy,
      modalBackgroundColor: AppColors.deepSpaceNavy,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ),
    ),

    // Updated color scheme to match auth screens
    colorScheme: ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.tealColor, // Use teal as primary
      secondary: AppColors.primaryColor,
      surface: AppColors.deepSpaceNavy,
      background: AppColors.deepSpaceNavy,
      error: AppColors.redColor,
      onPrimary: AppColors.primaryText,
      onSecondary: AppColors.primaryText,
      onSurface: AppColors.primaryText,
      onBackground: AppColors.primaryText,
      onError: AppColors.primaryText,
      inversePrimary: AppColors.primaryColor,
      surfaceTint: Colors.transparent,
    ),

    // Updated Input Decoration Theme with tealColor focus
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white.withOpacity(0.1), // Subtle transparent fill
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0, horizontal: 20.0), // Increased padding
      suffixIconColor: AppColors.secondaryText,
      prefixIconColor: AppColors.secondaryText,
      hintStyle: getSmallStyle(
        color: AppColors.secondaryText.withOpacity(0.7),
        fontSize: 14,
      ),
      labelStyle: getbodyStyle(
        color: AppColors.primaryText.withOpacity(0.8),
        fontSize: 16,
      ),
      floatingLabelStyle: getbodyStyle(
        color: AppColors.tealColor, // Teal for floating labels
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      // Updated borders to use tealColor when focused
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(
            color: AppColors.tealColor, // Teal focus border
            width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide:
            BorderSide(color: AppColors.redColor.withOpacity(0.8), width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.redColor, width: 2.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1.5),
      ),
      errorStyle: getSmallStyle(color: AppColors.redColor, fontSize: 12),
    ),

    // Updated snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.deepSpaceNavy,
      contentTextStyle: getbodyStyle(
        color: AppColors.primaryText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),

    // Updated dialog theme
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.deepSpaceNavy,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: getTitleStyle(
        color: AppColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: getbodyStyle(
        color: AppColors.primaryText,
        fontSize: 14,
      ),
    ),

    // Define default text themes with white text
    textTheme: TextTheme(
      displayLarge: getHeadlineTextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText),
      displayMedium: getHeadlineTextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText),
      displaySmall: getHeadlineTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText),
      headlineMedium: getTitleStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText),
      headlineSmall: getTitleStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText),
      titleLarge: getTitleStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText),
      bodyLarge: getbodyStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.primaryText),
      bodyMedium: getbodyStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.primaryText),
      labelLarge: getbodyStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText),
      bodySmall: getSmallStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.secondaryText),
      labelSmall: getSmallStyle(
          fontSize: 10,
          fontWeight: FontWeight.normal,
          color: AppColors.secondaryText),
    ),

    // Updated Card Theme
    cardTheme: CardTheme(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.white.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
    ),

    // Updated Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.tealColor, // Use teal for buttons
      foregroundColor: AppColors.primaryText,
      elevation: 4.0,
      shadowColor: AppColors.tealColor.withOpacity(0.4),
      textStyle: getbodyStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      minimumSize: const Size(double.infinity, 56),
    )),

    // Updated Text Button Theme
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: AppColors.tealColor, // Use teal for text buttons
            textStyle: getbodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ))),

    // Updated Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.tealColor,
      foregroundColor: AppColors.primaryText,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Updated Tab Bar Theme
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.tealColor,
      unselectedLabelColor: AppColors.secondaryText,
      indicatorColor: AppColors.tealColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: getbodyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: getbodyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Updated Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.tealColor;
          }
          return AppColors.secondaryText;
        },
      ),
      trackColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.tealColor.withOpacity(0.3);
          }
          return AppColors.secondaryText.withOpacity(0.3);
        },
      ),
    ),

    // Updated Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.tealColor;
          }
          return Colors.transparent;
        },
      ),
      checkColor: MaterialStateProperty.all(AppColors.primaryText),
      side: BorderSide(
        color: AppColors.tealColor,
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Updated Radio Theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.tealColor;
          }
          return AppColors.secondaryText;
        },
      ),
    ),

    // Updated Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.tealColor,
      inactiveTrackColor: AppColors.tealColor.withOpacity(0.3),
      thumbColor: AppColors.tealColor,
      overlayColor: AppColors.tealColor.withOpacity(0.2),
      valueIndicatorColor: AppColors.tealColor,
      valueIndicatorTextStyle: getbodyStyle(
        color: AppColors.primaryText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Updated Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.tealColor,
      linearTrackColor: AppColors.tealColor.withOpacity(0.3),
      circularTrackColor: AppColors.tealColor.withOpacity(0.3),
    ),

    // Updated Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
      space: 1,
    ),

    // Updated List Tile Theme
    listTileTheme: ListTileThemeData(
      textColor: AppColors.primaryText,
      iconColor: AppColors.secondaryText,
      tileColor: Colors.transparent,
      selectedTileColor: AppColors.tealColor.withOpacity(0.1),
      selectedColor: AppColors.tealColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  // **NEW: Create dark theme that matches the enhanced dark design**
  static ThemeData get darkTheme => lightTheme.copyWith(
        brightness: Brightness.dark,
        // All other properties are already dark-themed in lightTheme
      );

  // **NEW: Create a method to get theme based on system settings**
  static ThemeData getTheme(BuildContext context) {
    // For now, always return the dark theme since the app is designed dark-first
    return lightTheme;
  }
}
