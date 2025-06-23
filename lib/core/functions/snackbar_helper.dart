import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

void showGlobalSnackBar(BuildContext context, String message,
    {Duration duration = const Duration(seconds: 3), bool isError = false}) {
  // Trigger a bouncing-ball vibration effect.
  HapticFeedback.mediumImpact();
  Future.delayed(const Duration(milliseconds: 50), () {
    HapticFeedback.mediumImpact();
  });
  Future.delayed(const Duration(milliseconds: 100), () {
    HapticFeedback.mediumImpact();
  });

  // Clear existing snackbars to prevent stacking
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? AppColors.redColor : AppColors.primaryColor,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      duration: duration,
      behavior: SnackBarBehavior
          .fixed, // Fixed instead of floating to prevent layout issues
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

// Show success animation.

void showSuccessAnimation(
  BuildContext context,
) {}
