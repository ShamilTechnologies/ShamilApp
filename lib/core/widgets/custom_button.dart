import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Use text style functions

class CustomButton extends StatelessWidget {
  final double? width; // Allow null for intrinsic width
  final double height;
  final String text;
  final VoidCallback? onPressed; // Allow null to disable button
  final TextStyle? textStyle;
  final Color color;
  final double radius;
  final bool isOutline;
  final double elevation; // Add elevation property
  final EdgeInsetsGeometry padding; // Add padding property

  const CustomButton({
    super.key,
    this.width, // Default to null
    this.height = 48, // Default height
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.color = AppColors.primaryColor,
    this.radius = 12, // Default radius from theme
    this.isOutline = false,
    this.elevation = 2.0, // Default elevation
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Default padding
  });

  @override
  Widget build(BuildContext context) {
    // Determine background and foreground colors based on outline state
    final bgColor = isOutline ? AppColors.white : color;
    final fgColor = isOutline ? color : AppColors.white;
    final effectiveTextStyle = textStyle ?? getButtonStyle(color: fgColor); // Use text style function

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor, // Text and icon color
            elevation: onPressed != null ? elevation : 0, // No elevation if disabled
            shadowColor: onPressed != null ? color.withOpacity(0.3) : Colors.transparent,
            padding: padding,
            shape: RoundedRectangleBorder(
              // Use BorderSide for outline effect
              side: isOutline
                  ? BorderSide(color: color, width: 1.5) // Outline border
                  : BorderSide.none,
              borderRadius: BorderRadius.circular(radius),
            ),
            // Handle disabled state explicitly
            disabledBackgroundColor: isOutline ? AppColors.white : Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
          ),
          onPressed: onPressed, // Pass onPressed directly (null disables)
          child: Text(
            text,
            style: effectiveTextStyle,
            textAlign: TextAlign.center,
          )),
    );
  }
}
