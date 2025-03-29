import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/bottom_text.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/button_area.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.accentColor.withOpacity(0.6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Lottie animation
            Lottie.asset(
              frameRate: FrameRate.composition,
              AssetsIcons.onBoardingAnimation,
              fit: BoxFit.cover,
            ),
            // Text at the bottom of the screen
            const BottomText(),
            // button at the end of the screen
            const ButtonArea()
          ],
        ),
      ),
    );
  }
}
