import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

// Using GoogleFonts can provide more flexibility, but sticking to 'Cairo' from theme for now.
// import 'package:google_fonts/google_fonts.dart';

// Base text style function to reduce repetition
TextStyle _baseTextStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  double? height,
  String fontFamily = 'Cairo', // Default to theme font
}) {
  // Use GoogleFonts if needed: return GoogleFonts.cairo(...)
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.primaryColor.withOpacity(0.85), // Default text color slightly muted
    height: height, // Line height
  );
}


// Headline Styles (Large text, typically for page titles)
TextStyle getHeadlineTextStyle({
    double fontSize = 28, // Adjusted default size
    FontWeight fontWeight = FontWeight.bold,
    Color? color}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.primaryColor, // Headlines often use primary color directly
  );
}

// Title Styles (Section headers, list tile titles)
TextStyle getTitleStyle({
    double fontSize = 18, // Adjusted default size
    FontWeight fontWeight = FontWeight.w600, // Semi-bold is often good for titles
    Color? color}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.primaryColor,
  );
}

// Body Styles (Regular text content)
TextStyle getbodyStyle({
    double fontSize = 15, // Adjusted default size
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color, // Use default from _baseTextStyle if null
    height: height,
  );
}

// Small Styles (Captions, helper text, metadata)
TextStyle getSmallStyle({
    double fontSize = 12, // Adjusted default size
    FontWeight fontWeight = FontWeight.normal,
    Color? color}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.secondaryColor, // Secondary color often suitable for small text
  );
}

// Specific style for buttons (can be customized further)
TextStyle getButtonStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.white, // Default button text color
  );
}


// Example of a specific style if needed (e.g., for home screen heading)
// Kept for reference, but prefer using the main styles above for consistency
TextStyle getHomeHeadingStyle({
    double fontSize = 18,
    fontWeight = FontWeight.normal,
    Color? color,
    FontStyle? fontStyle, // Changed from fontFamily
    double? height}) {
  return _baseTextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.primaryColor,
    // fontStyle: fontStyle, // Apply fontStyle if needed
    height: height,
  );
}
