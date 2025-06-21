import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/enhanced_onboarding_view.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

class EnhancedSplashView extends StatefulWidget {
  const EnhancedSplashView({super.key});

  @override
  State<EnhancedSplashView> createState() => _EnhancedSplashViewState();
}

class _EnhancedSplashViewState extends State<EnhancedSplashView>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _appNameController;
  late AnimationController _logoController;

  // Animations
  late Animation<double> _appNameFadeAnimation;
  late Animation<double> _appNameScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  // Logo animation progress
  double _logoProgress = 0.0;
  bool _showAppName = true;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // App name animation controller
    _appNameController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // App name animations
    _appNameFadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_appNameController);

    _appNameScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInBack)),
        weight: 30,
      ),
    ]).animate(_appNameController);

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Listen for app name animation completion
    _appNameController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showAppName = false;
          _showLogo = true;
        });
        _logoController.forward();
      }
    });

    // Listen for logo progress updates
    _logoController.addListener(() {
      setState(() {
        _logoProgress = _logoController.value;
      });
    });

    // Listen for logo animation completion
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _performAuthCheckAndNavigate();
      }
    });
  }

  void _startAnimationSequence() {
    // Start app name animation after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _appNameController.forward();
      }
    });
  }

  Future<void> _performAuthCheckAndNavigate() async {
    try {
      final authBloc = context.read<AuthBloc>();
      authBloc.add(const CheckInitialAuthStatus());

      final state = await authBloc.stream.firstWhere(
        (s) =>
            s is AuthInitial ||
            s is LoginSuccessState ||
            s is IncompleteProfileState ||
            s is AuthErrorState,
        orElse: () => const AuthInitial(),
      );

      if (!mounted) return;

      Widget targetScreen;
      final bool onboardingShown =
          AppLocalStorage.getData(key: AppLocalStorage.isOnboardingShown) ??
              false;

      debugPrint(
          "EnhancedSplashView Navigating: OnboardingShown=$onboardingShown, AuthState=${state.runtimeType}");

      if (!onboardingShown) {
        targetScreen = const EnhancedOnboardingView();
      } else if (state is LoginSuccessState) {
        targetScreen = const MainNavigationView();
      } else if (state is IncompleteProfileState) {
        // User needs to complete profile setup - go to OneMoreStep
        targetScreen = const OneMoreStepScreen();
      } else {
        targetScreen = const LoginView();
      }

      // Use enhanced navigation for stable, premium transitions
      if (targetScreen.runtimeType.toString() == 'EnhancedOnboardingView') {
        // Special slide-up transition for onboarding continuity
        GlobalNavigation.replaceSlide(
          context,
          targetScreen,
          direction: SlideDirection.up,
        );
      } else if (targetScreen.runtimeType.toString() == 'LoginView') {
        // Smooth fade transition to auth
        GlobalNavigation.replaceFade(context, targetScreen);
      } else if (targetScreen.runtimeType.toString() == 'OneMoreStepScreen') {
        // Smooth transition to profile completion
        GlobalNavigation.replaceFade(context, targetScreen);
      } else {
        // Premium fade for main app
        AuthNavigation.toMainApp(context, targetScreen);
      }
    } catch (e) {
      debugPrint("Error in enhanced splash navigation: $e");
      if (mounted) {
        pushReplacement(context, const LoginView());
      }
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isTablet = size.shortestSide >= 600;

    // Responsive logo sizing based on screen dimensions
    double logoSize;
    if (isTablet) {
      logoSize = min(screenWidth * 0.5, screenHeight * 0.35);
    } else {
      // For phones: use 40-50% of screen width, capped at 45% of screen height
      logoSize = min(
        screenWidth * 0.45,
        screenHeight * 0.35,
      );
      // Minimum size to ensure visibility on smaller screens
      logoSize = max(logoSize, 120.0);
      // Maximum size to prevent oversizing on larger phones
      logoSize = min(logoSize, 280.0);
    }

    final appNameSize = isTablet ? 32.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.splashBackground, // Simple dark background only
        child: Stack(
          children: [
            // Main content
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _showAppName
                    ? _buildAppNameSection(appNameSize)
                    : _buildLogoSection(logoSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppNameSection(double fontSize) {
    return AnimatedBuilder(
      animation: _appNameController,
      key: const ValueKey('appName'),
      builder: (context, child) {
        return FadeTransition(
          opacity: _appNameFadeAnimation,
          child: ScaleTransition(
            scale: _appNameScaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ShamilApp',
                  style: getHeadlineTextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ).copyWith(
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(double logoSize) {
    return AnimatedBuilder(
      animation: _logoController,
      key: const ValueKey('logo'),
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: ScaleTransition(
            scale: _logoScaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: StrokeToFillLogo(
                    logoPath: AssetsIcons.logoSvg,
                    brandColor: const Color(0xFF20C997),
                    progress: _logoProgress,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stroke-to-Fill Logo Widget
/// Implementation based on the SVG Logo Animation Guide
class StrokeToFillLogo extends StatelessWidget {
  final String logoPath;
  final Color brandColor;
  final double progress;

  const StrokeToFillLogo({
    super.key,
    required this.logoPath,
    required this.brandColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Stroke Layer (always visible at 30% opacity)
          SvgPicture.asset(
            logoPath,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              brandColor.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),

          // Fill Layer (progressively revealed)
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  brandColor, // Visible area
                  brandColor, // Visible area
                  Colors.transparent, // Hidden area
                  Colors.transparent, // Hidden area
                ],
                stops: [
                  0.0,
                  progress, // Dynamic boundary
                  progress, // Sharp transition
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: SvgPicture.asset(
              logoPath,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                brandColor,
                BlendMode.srcIn,
              ),
            ),
          ),

          // Glow effect when filling
          if (progress > 0.1)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    brandColor.withOpacity(0.5),
                    brandColor.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    max(0.0, progress - 0.1),
                    progress,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              child: SvgPicture.asset(
                logoPath,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  brandColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
