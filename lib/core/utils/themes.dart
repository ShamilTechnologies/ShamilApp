import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Import text styles

class AppThemes {
  static ThemeData lightTheme = ThemeData(
      fontFamily:
          'BalooBhaijaan2', // Consistent font family using Baloo Bhaijaan

      // Set scaffoldBackgroundColor - Use accent color lightly or pure white
      scaffoldBackgroundColor:
          AppColors.white, // Or AppColors.accentColor.withOpacity(0.2),

      appBarTheme: AppBarTheme(
        // Use white or a very light color for AppBar background for a cleaner look
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryColor, // Icons/text on AppBar
        elevation: 0.5, // Subtle elevation
        surfaceTintColor: Colors.transparent, // Prevent tinting on scroll
        titleTextStyle: getTitleStyle(
          // Use text style function
          color: AppColors.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600, // Slightly less bold
        ),
        iconTheme: const IconThemeData(
            color: AppColors.primaryColor, size: 24), // Consistent icon theme
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white, // White background
        elevation: 2.0, // Add slight elevation
        showSelectedLabels: true, // Show labels for clarity
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor, // Primary color for selected
        unselectedItemColor:
            AppColors.secondaryColor, // Secondary for unselected
        selectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600), // Style for selected label
        unselectedLabelStyle:
            TextStyle(fontSize: 10), // Style for unselected label
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor, // Use primary as seed
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.white, // Surface color
        background: AppColors.white, // Background color
        error: AppColors.redColor,
        onPrimary: AppColors.white, // Text/icons on primary color
        onSecondary: AppColors.white, // Text/icons on secondary color
        onSurface: AppColors.primaryColor, // Text/icons on surface
        onBackground: AppColors.primaryColor, // Text/icons on background
        onError: AppColors.white,
        brightness: Brightness.light,
      ),

      // Updated Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.accentColor.withOpacity(0.5), // Lighter fill
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0, horizontal: 16.0), // Adjusted padding
        suffixIconColor: AppColors.secondaryColor,
        prefixIconColor: AppColors.secondaryColor,
        hintStyle: getSmallStyle(
          // Use text style function
          color: AppColors.secondaryColor.withOpacity(0.8),
          fontSize: 14,
        ),
        labelStyle: getbodyStyle(
          // Style for floating label
          color: AppColors.primaryColor.withOpacity(0.9),
          fontSize: 16, // Label size when floating
        ),
        floatingLabelStyle: getbodyStyle(
          // Style for floating label when focused
          color: AppColors.primaryColor,
          fontSize: 12, // Smaller size when floating up
        ),
        // Define borders more explicitly
        border: OutlineInputBorder(
          // Default border
          borderRadius:
              const BorderRadius.all(Radius.circular(12)), // More rounded
          borderSide: BorderSide(
              color: AppColors.secondaryColor.withOpacity(0.5),
              width: 1.0), // Subtle border
        ),
        enabledBorder: OutlineInputBorder(
          // Border when enabled but not focused
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
              color: AppColors.secondaryColor.withOpacity(0.5), width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          // Border when focused
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 1.5), // Primary color, slightly thicker
        ),
        errorBorder: OutlineInputBorder(
          // Border when error
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
              color: AppColors.redColor.withOpacity(0.8), width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          // Border when error and focused
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.redColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          // Border when disabled
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        errorStyle: getSmallStyle(
            color: AppColors.redColor,
            fontSize: 12), // Consistent error text style
      ),

      // Define default text themes
      textTheme: TextTheme(
        displayLarge:
            getHeadlineTextStyle(fontSize: 34, fontWeight: FontWeight.bold),
        displayMedium:
            getHeadlineTextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall:
            getHeadlineTextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        headlineMedium:
            getTitleStyle(fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: getTitleStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: getTitleStyle(
            fontSize: 16, fontWeight: FontWeight.w600), // For list tiles etc.
        bodyLarge: getbodyStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: getbodyStyle(
            fontSize: 14, fontWeight: FontWeight.normal), // Default body text
        labelLarge: getbodyStyle(
            fontSize: 16, fontWeight: FontWeight.w600), // For buttons
        bodySmall: getSmallStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal), // Captions, small text
        labelSmall: getSmallStyle(
            fontSize: 10, fontWeight: FontWeight.normal), // Very small labels
      ).apply(
        // Apply base color to text themes
        bodyColor: AppColors.primaryColor,
        displayColor: AppColors.primaryColor,
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 1.0, // Subtle elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Consistent rounding
          side: BorderSide(
              color: Colors.grey.shade200, width: 0.5), // Subtle border
        ),
        color: AppColors.white,
        surfaceTintColor: Colors.transparent, // Prevent tinting
        margin: const EdgeInsets.symmetric(
            vertical: 4.0, horizontal: 0), // Default margins
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 2.0, // Subtle elevation
        shadowColor: AppColors.primaryColor.withOpacity(0.3),
        textStyle: getbodyStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Consistent rounding
        ),
        minimumSize: const Size(double.infinity, 48), // Ensure decent height
      )),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              textStyle:
                  getbodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ))));
}
