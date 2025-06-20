import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/on_boarding_view.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _appNameController;
  late AnimationController _logoController;
  late AnimationController _floatingElementsController;
  late AnimationController _backgroundController;

  // Animations
  late Animation<double> _appNameFadeAnimation;
  late Animation<double> _appNameScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _floatingElementsAnimation;
  late Animation<double> _backgroundAnimation;

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

    // Floating elements controller
    _floatingElementsController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 5000),
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

    // Floating elements animation
    _floatingElementsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingElementsController,
        curve: Curves.easeInOut,
      ),
    );

    // Background animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
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
    // Start floating elements immediately
    _floatingElementsController.repeat(reverse: true);

    // Start background animation
    _backgroundController.forward();

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
            s is AuthInitial || s is LoginSuccessState || s is AuthErrorState,
        orElse: () => const AuthInitial(),
      );

      if (!mounted) return;

      Widget targetScreen;
      final bool onboardingShown =
          AppLocalStorage.getData(key: AppLocalStorage.isOnboardingShown) ??
              false;

      if (!onboardingShown) {
        targetScreen = const OnBoardingView();
      } else if (state is LoginSuccessState) {
        targetScreen = const MainNavigationView();
      } else {
        targetScreen = const LoginView();
      }

      // Smooth transition with fade
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => targetScreen,
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      debugPrint("Error in splash navigation: $e");
      if (mounted) {
        pushReplacement(context, const LoginView());
      }
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _logoController.dispose();
    _floatingElementsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final logoSize = isTablet ? 320.0 : min(size.width * 0.7, 280.0);

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.splashBackground,
              AppColors.splashBackground.withOpacity(0.9),
              AppColors.deepSpaceNavy.withOpacity(0.8),
              AppColors.splashBackground,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            ..._buildFloatingOrbs(size),

            // Main content
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _showAppName
                    ? _buildAppNameSection()
                    : _buildLogoSection(logoSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs(Size size) {
    return [
      // Large teal orb
      AnimatedBuilder(
        animation: _floatingElementsAnimation,
        builder: (context, child) {
          return Positioned(
            top: 100 + (50 * sin(_floatingElementsAnimation.value * 2 * pi)),
            right: -80 + (30 * cos(_floatingElementsAnimation.value * 2 * pi)),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.3),
                    AppColors.tealColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // Medium premium blue orb
      AnimatedBuilder(
        animation: _floatingElementsAnimation,
        builder: (context, child) {
          return Positioned(
            bottom: 150 + (40 * cos(_floatingElementsAnimation.value * 3 * pi)),
            left: -60 + (25 * sin(_floatingElementsAnimation.value * 3 * pi)),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.premiumBlue.withOpacity(0.2),
                    AppColors.premiumBlue.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),

      // Small accent orb
      AnimatedBuilder(
        animation: _floatingElementsAnimation,
        builder: (context, child) {
          return Positioned(
            top: size.height * 0.3 +
                (20 * sin(_floatingElementsAnimation.value * 4 * pi)),
            left: 50 + (15 * cos(_floatingElementsAnimation.value * 4 * pi)),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildAppNameSection() {
    return AnimatedBuilder(
      animation: _appNameController,
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
                  style: TextStyle(
                    fontFamily: 'BaloooBhaijaan',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                    shadows: [
                      Shadow(
                        color: AppColors.tealColor.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 3,
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tealColor,
                        AppColors.premiumBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
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
                    brandColor: AppColors.tealColor,
                    progress: _logoProgress,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'shamil platform',
                  style: TextStyle(
                    fontFamily: 'BaloooBhaijaan',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.0,
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
    return Stack(
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
      ],
    );
  }
}
