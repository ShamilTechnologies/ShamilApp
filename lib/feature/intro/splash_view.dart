import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/on_boarding_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _squareController;
  late final Animation<double> _squareAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers.
    _lottieController = AnimationController(vsync: this);
    _squareController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _squareAnimation = CurvedAnimation(
      parent: _squareController,
      curve: Curves.easeInOut,
    );

    // Trigger square reveal when Lottie animation completes.
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _squareController.forward();
      }
    });

    // Delay navigation to allow animations to play.
    Future.delayed(const Duration(seconds: 5), _navigateNext);
  }

  /// Checks login state from SharedPreferences and navigates accordingly.
  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      pushReplacement(context, const ExploreScreen());
    } else {
      pushReplacement(context, const OnBoardingView());
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _squareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxSide = sqrt(pow(size.width, 2) + pow(size.height, 2));

    return Scaffold(
      body: Stack(
        children: [
          // Animated square reveal.
          AnimatedBuilder(
            animation: _squareAnimation,
            builder: (context, child) {
              final currentSide = _squareAnimation.value * maxSide;
              return ClipPath(
                clipper: SquareClipper(currentSide),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF2A548D),
                ),
              );
            },
          ),
          // Centered Lottie animation.
          Center(
            child: Lottie.asset(
              AssetsIcons.splashAnimation,
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..forward();
              },
              repeat: false,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for the square reveal animation.
class SquareClipper extends CustomClipper<Path> {
  final double side;

  SquareClipper(this.side);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final halfSide = side / 2;
    return Path()..addRect(Rect.fromLTWH(center.dx - halfSide, center.dy - halfSide, side, side));
  }

  @override
  bool shouldReclip(SquareClipper oldClipper) => oldClipper.side != side;
}
