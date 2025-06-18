import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/models/onboarding_page_model.dart';
import 'package:shamil_mobile_app/feature/intro/onBoarding/widgets/premium_shine_effect.dart';

/// Widget that displays the main content for each onboarding page
class EnhancedOnboardingContent extends StatelessWidget {
  final OnboardingPageModel pageData;
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final int pageIndex;
  final bool isCurrentPage;

  const EnhancedOnboardingContent({
    super.key,
    required this.pageData,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.pageIndex,
    required this.isCurrentPage,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 24,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon with gyroscope effect
          _buildAnimatedIcon(),

          SizedBox(height: isTablet ? 48 : 32),

          // Title with parallax effect
          _buildTitle(),

          SizedBox(height: isTablet ? 16 : 12),

          // Subtitle
          _buildSubtitle(),

          SizedBox(height: isTablet ? 24 : 20),

          // Description
          _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.3,
        parallaxOffsetY * 0.3,
      ),
      child: PremiumShineEffect(
        parallaxOffsetX: parallaxOffsetX,
        parallaxOffsetY: parallaxOffsetY,
        primaryColor: pageData.primaryColor,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pageData.primaryColor.withOpacity(0.7),
                pageData.primaryColor.withOpacity(0.5),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            pageData.iconData,
            size: 40,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.05,
        parallaxOffsetY * 0.05,
      ),
      child: PremiumShineEffect(
        parallaxOffsetX: parallaxOffsetX,
        parallaxOffsetY: parallaxOffsetY,
        primaryColor: pageData.primaryColor,
        child: Text(
          pageData.title,
          textAlign: TextAlign.center,
          style: getHeadlineTextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ).copyWith(
            letterSpacing: -0.3,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.02,
        parallaxOffsetY * 0.02,
      ),
      child: Text(
        pageData.subtitle,
        textAlign: TextAlign.center,
        style: getTitleStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: pageData.primaryColor.withOpacity(0.8),
        ).copyWith(
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.01,
        parallaxOffsetY * 0.01,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          pageData.description,
          textAlign: TextAlign.center,
          style: getbodyStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.6),
            height: 1.7,
          ).copyWith(
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

/// Alternative content layout with different visual hierarchy
class OnboardingContentCard extends StatelessWidget {
  final OnboardingPageModel pageData;
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final bool isActive;

  const OnboardingContentCard({
    super.key,
    required this.pageData,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.1,
        parallaxOffsetY * 0.1,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pageData.primaryColor.withOpacity(0.2),
              pageData.primaryColor.withOpacity(0.1),
              pageData.secondaryColor.withOpacity(0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: pageData.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: pageData.primaryColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 50,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    pageData.primaryColor,
                    pageData.secondaryColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pageData.primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                pageData.iconData,
                size: 40,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              pageData.title,
              textAlign: TextAlign.center,
              style: getHeadlineTextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ).copyWith(
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              pageData.subtitle,
              textAlign: TextAlign.center,
              style: getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: pageData.primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              pageData.description,
              textAlign: TextAlign.center,
              style: getbodyStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
