import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:lottie/lottie.dart';
// Import AuthBloc and Event
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
// Import navigation targets
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/on_boarding_view.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart'; // Import local storage

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

    _lottieController = AnimationController(vsync: this);
    _squareController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _squareAnimation = CurvedAnimation(
      parent: _squareController,
      curve: Curves.easeInOut,
    );

    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start square reveal after Lottie finishes
        _squareController.forward();
      }
    });

    // Add listener for square animation completion to trigger navigation check
    _squareController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Check authentication status via Bloc AFTER animations
        _checkAuthAndNavigate();
      }
    });

    // Load Lottie composition and start animation
    _loadAndPlayLottie();
  }

  Future<void> _loadAndPlayLottie() async {
    try {
      // Load the Lottie file
      final composition = await AssetLottie(AssetsIcons.splashAnimation).load();
      if (mounted) {
        _lottieController.duration = composition.duration;
        // Start animation after a short delay for smoother entry
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _lottieController.forward();
          }
        });
      }
    } catch (e) {
      print("Error loading Lottie animation: $e");
      // If Lottie fails, proceed to auth check after a fallback delay
      Future.delayed(const Duration(seconds: 1), _checkAuthAndNavigate);
    }
  }

  /// Checks auth status via Bloc and navigates accordingly.
  Future<void> _checkAuthAndNavigate() async {
    // Ensure AuthBloc is available before reading/adding events
    // Assumes AuthBloc is provided higher up (e.g., in main.dart)
    try {
      final authBloc = context.read<AuthBloc>();
      // Dispatch event to check initial status
      authBloc.add(const CheckInitialAuthStatus());

      // Listen for the FIRST relevant state change after dispatching the check event
      // to determine where to navigate. Using await for clarity.
      final state = await authBloc.stream.firstWhere(
          (s) =>
              s is AuthInitial ||
              s is LoginSuccessState ||
              s is AwaitingVerificationState ||
              s is AuthErrorState,
          orElse: () =>
              const AuthInitial() // Default if stream closes unexpectedly
          );

      if (!mounted) return; // Check if widget is still mounted after await

      // Determine target screen based on the state emitted by the Bloc
      Widget targetScreen;
      // Check onboarding status AFTER checking auth state
      final bool onboardingShown =
          AppLocalStorage.getData(key: AppLocalStorage.isOnboardingShown) ??
              false;

      print(
          "SplashView Navigating: OnboardingShown=$onboardingShown, AuthState=${state.runtimeType}");

      if (!onboardingShown) {
        targetScreen = const OnBoardingView();
        // Set flag after showing onboarding for the first time (should happen in OnBoardingView)
        // AppLocalStorage.cacheData(key: AppLocalStorage.isOnboardingShown, value: true);
      } else if (state is LoginSuccessState) {
        targetScreen =
            const MainNavigationView(); // Already logged in and verified
      } else if (state is AwaitingVerificationState) {
        targetScreen =
            const LoginView(); // Go to login, show "verify email" message there
      } else {
        // AuthInitial or AuthError
        targetScreen = const LoginView();
      }

      // Perform navigation using pushReplacement
      pushReplacement(context, targetScreen);
    } catch (e) {
      // Handle error if AuthBloc is not found or stream error occurs
      print("Error checking auth/navigating in SplashView: $e");
      if (mounted) {
        // Default navigation on error (e.g., to Login)
        pushReplacement(context, const LoginView());
      }
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
    // Calculate max side based on diagonal for square reveal
    final maxSide = sqrt(pow(size.width, 2) + pow(size.height, 2));
    final theme = Theme.of(context); // Get theme

    return Scaffold(
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center, // Center stack children
        children: [
          // Animated square reveal background
          AnimatedBuilder(
            animation: _squareAnimation,
            builder: (context, child) {
              final currentSide = _squareAnimation.value * maxSide;
              return ClipPath(
                clipper: SquareClipper(currentSide),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  // Use primary color for the reveal background
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
          // Centered Lottie animation
          // Constrain Lottie size to prevent excessive scaling on large screens
          SizedBox(
            width: min(size.width * 0.8, 400), // Example constraint
            height: min(size.height * 0.8, 400),
            child: Lottie.asset(
              AssetsIcons.splashAnimation,
              controller: _lottieController,
              // onLoaded is handled in _loadAndPlayLottie
              // repeat: false, // Default
              // fit: BoxFit.contain, // Contain might be better than cover
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
    // Ensure side doesn't go negative
    final effectiveSide = max(0.0, side);
    return Path()
      ..addRect(Rect.fromCenter(
          center: center, width: effectiveSide, height: effectiveSide));
  }

  @override
  bool shouldReclip(SquareClipper oldClipper) => oldClipper.side != side;
}
