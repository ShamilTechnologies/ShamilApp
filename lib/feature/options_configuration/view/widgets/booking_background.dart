import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Background decorations and gradients for the booking screen
class BookingBackground {
  /// Main gradient for the booking screen
  static BoxDecoration getMainGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.95),
          AppColors.primaryColor.withOpacity(0.9),
          const Color(0xFF0A0E1A),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  /// Build floating orbs for visual depth
  static Widget buildFloatingOrbs() {
    return Stack(
      children: [
        // Large orb - top right
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Medium orb - middle left
        Positioned(
          top: 200,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cyanColor.withOpacity(0.08),
                  AppColors.cyanColor.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Small orb - bottom right
        Positioned(
          bottom: 100,
          right: 50,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.tealColor.withOpacity(0.06),
                  AppColors.tealColor.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
