import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/bottom_text.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/button_area.dart';

class OnBoardingView extends StatefulWidget { // Changed to StatefulWidget for potential future animations/state
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme

    return Scaffold(
      // Use theme background instead of hardcoded color? Or keep specific color?
      // backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        // Consider using theme color or a gradient if preferred
        color: AppColors.accentColor.withOpacity(0.6), // Current background
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center, // Align stack children center
          children: [
            // Background Lottie animation
            Positioned.fill( // Ensure Lottie fills the space if needed
              child: Lottie.asset(
                // frameRate: FrameRate.composition, // Usually not needed unless optimizing
                AssetsIcons.onBoardingAnimation,
                fit: BoxFit.cover, // Cover ensures it fills, might crop
                // Consider BoxFit.contain if the whole animation should be visible
              ),
            ),

            // Positioned Widgets for Text and Button Area
            // Use Align or Positioned to place them correctly

            // Text at the bottom
            const Positioned(
              bottom: 150, // Adjust position as needed
              left: 20,
              right: 20,
              child: BottomText(),
            ),

            // Button area at the very bottom
            const Positioned(
              bottom: 40, // Adjust position as needed
              left: 20,
              right: 20,
              child: ButtonArea(), // This widget handles the action
            )
          ],
        ),
      ),
    );
  }
}
