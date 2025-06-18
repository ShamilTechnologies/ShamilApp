import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/widgets/enhanced_onboarding_content.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/widgets/enhanced_onboarding_button.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/widgets/premium_shine_effect.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/widgets/onboarding_page_indicator.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/models/onboarding_page_model.dart';

class EnhancedOnboardingView extends StatefulWidget {
  const EnhancedOnboardingView({super.key});

  @override
  State<EnhancedOnboardingView> createState() => _EnhancedOnboardingViewState();
}

class _EnhancedOnboardingViewState extends State<EnhancedOnboardingView>
    with TickerProviderStateMixin {
  // Page control
  late PageController _pageController;
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _parallaxController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _parallaxAnimation;

  // Gyroscope data
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // Parallax offsets for gyroscope effect
  double _parallaxOffsetX = 0.0;
  double _parallaxOffsetY = 0.0;

  // Onboarding pages data - minimalist approach
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: "Welcome to\nShamilApp",
      subtitle: "Premium services made simple",
      description:
          "Access nearby services with just a tap. Clean, fast, and effortless.",
      iconData: Icons.stars_rounded,
      primaryColor: AppColors.tealColor,
      secondaryColor: AppColors.premiumBlue,
    ),
    OnboardingPageModel(
      title: "Smart\nReservations",
      subtitle: "Book instantly, enter seamlessly",
      description: "Reserve your spot and enter with advanced NFC technology.",
      iconData: Icons.event_available_rounded,
      primaryColor: AppColors.premiumBlue,
      secondaryColor: AppColors.electricBlue,
    ),
    OnboardingPageModel(
      title: "Premium\nExperience",
      subtitle: "Exclusive benefits await",
      description:
          "Priority access, special offers, and premium service quality.",
      iconData: Icons.diamond_rounded,
      primaryColor: AppColors.passesPurple,
      secondaryColor: AppColors.passesPink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _initializeGyroscope();
    _startEntryAnimation();
  }

  void _initializeControllers() {
    _pageController = PageController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeGyroscope() {
    try {
      _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        if (mounted) {
          setState(() {
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;

            // Calculate parallax offsets with damping
            const sensitivity = 5.0;
            const maxOffset = 30.0;

            _parallaxOffsetX =
                (_gyroY * sensitivity).clamp(-maxOffset, maxOffset);
            _parallaxOffsetY =
                (-_gyroX * sensitivity).clamp(-maxOffset, maxOffset);
          });
        }
      });
    } catch (e) {
      debugPrint('Gyroscope not available: $e');
      // Graceful fallback - app continues without gyroscope effects
    }
  }

  void _startEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _slideController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _scaleController.forward();
      }
    });

    _parallaxController.repeat(reverse: true);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Restart animations for new page
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _scaleController.forward();
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentPageData = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:
            const BoxDecoration(), // Remove color, use gyroscopic background
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top section with hero logo
                  _buildTopSection(),

                  // Page view content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildPageContent(_pages[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom navigation
                  _buildBottomNavigation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Hero logo (smaller version)
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 32,
              height: 32,
              child: SvgPicture.asset(
                AssetsIcons.logoSvg,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  AppColors.tealColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // App name
          Text(
            'ShamilApp',
            style: getHeadlineTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          const Spacer(),

          // Skip button
          GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                _pages.length - 1,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Skip',
                style: getSmallStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPageModel pageData) {
    return Transform.translate(
      offset: Offset(_parallaxOffsetX * 0.1, _parallaxOffsetY * 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    pageData.primaryColor.withOpacity(0.8),
                    pageData.primaryColor.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: pageData.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                pageData.iconData,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              pageData.title,
              textAlign: TextAlign.center,
              style: getHeadlineTextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ).copyWith(
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              pageData.subtitle,
              textAlign: TextAlign.center,
              style: getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: pageData.primaryColor.withOpacity(0.9),
              ).copyWith(
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              pageData.description,
              textAlign: TextAlign.center,
              style: getbodyStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
                height: 1.6,
              ).copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final currentPageData = _pages[_currentPage];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? currentPageData.primaryColor
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1
                  ? () async {
                      try {
                        await AppLocalStorage.cacheData(
                          key: AppLocalStorage.isOnboardingShown,
                          value: true,
                        );
                        if (mounted) {
                          pushReplacement(context, const LoginView());
                        }
                      } catch (e) {
                        debugPrint('Error completing onboarding: $e');
                      }
                    }
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPageData.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                style: getButtonStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
