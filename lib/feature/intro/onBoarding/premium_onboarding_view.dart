import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PremiumOnboardingView extends StatefulWidget {
  const PremiumOnboardingView({super.key});

  @override
  State<PremiumOnboardingView> createState() => _PremiumOnboardingViewState();
}

class _PremiumOnboardingViewState extends State<PremiumOnboardingView>
    with TickerProviderStateMixin {
  // Controllers
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  // State
  int _currentPage = 0;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _parallaxX = 0.0;
  double _parallaxY = 0.0;

  // Onboarding data
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Premium\nServices",
      subtitle: "Discover excellence",
      description: "Access premium services\nwith unprecedented ease",
      icon: Icons.diamond_rounded,
      color: AppColors.tealColor,
    ),
    OnboardingPage(
      title: "Smart\nBooking",
      subtitle: "Reserve instantly",
      description: "Book your experiences\nwith intelligent technology",
      icon: Icons.auto_awesome_rounded,
      color: AppColors.premiumBlue,
    ),
    OnboardingPage(
      title: "Seamless\nEntry",
      subtitle: "Touch to enter",
      description: "Enter venues effortlessly\nwith NFC technology",
      icon: Icons.contactless_rounded,
      color: AppColors.electricBlue,
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initializeGyroscope() {
    try {
      _gyroscopeSubscription = gyroscopeEvents.listen((event) {
        if (mounted) {
          setState(() {
            _parallaxX = (event.y * 8).clamp(-15.0, 15.0);
            _parallaxY = (-event.x * 8).clamp(-15.0, 15.0);
          });
        }
      });
    } catch (e) {
      debugPrint('Gyroscope unavailable: $e');
    }
  }

  void _startEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoController.forward();
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _completeOnboarding() async {
    try {
      HapticFeedback.mediumImpact();

      await AppLocalStorage.cacheData(
        key: AppLocalStorage.isOnboardingShown,
        value: true,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const LoginView(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentPage = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              (_parallaxX / 100).clamp(-0.3, 0.3),
              (_parallaxY / 100).clamp(-0.3, 0.3),
            ),
            radius: 1.5,
            colors: [
              AppColors.splashBackground,
              currentPage.color.withOpacity(0.05),
              AppColors.splashBackground,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildBackgroundParticles(size, currentPage.color),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top section with logo
                  _buildTopSection(),

                  // Main content area
                  Expanded(
                    child: _buildMainContent(),
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

  Widget _buildBackgroundParticles(Size size, Color color) {
    return Transform.translate(
      offset: Offset(_parallaxX * 0.3, _parallaxY * 0.3),
      child: Stack(
        children: [
          Positioned(
            top: size.height * 0.15,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Hero logo (smaller version)
            Hero(
              tag: 'app_logo',
              child: AnimatedBuilder(
                animation: _logoScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      child: SvgPicture.asset(
                        AssetsIcons.logoSvg,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          AppColors.tealColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // App name
            Text(
              'ShamilApp',
              style: getHeadlineTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

            const Spacer(),

            // Skip button
            GestureDetector(
              onTap: _completeOnboarding,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            final page = _pages[index];
            return Transform.translate(
              offset: Offset(_parallaxX * 0.1, _parallaxY * 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            page.color.withOpacity(0.8),
                            page.color.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: page.color.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Title
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: getHeadlineTextStyle(
                        fontSize: 38,
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
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: page.color.withOpacity(0.9),
                      ).copyWith(
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: getbodyStyle(
                        fontSize: 16,
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
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
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
                        ? _pages[_currentPage].color
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
                    ? _completeOnboarding
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages[_currentPage].color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Continue',
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
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
