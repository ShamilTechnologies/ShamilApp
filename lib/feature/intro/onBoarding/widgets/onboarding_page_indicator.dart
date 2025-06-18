import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Widget that displays page indicators for the onboarding flow
class OnboardingPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color activeColor;

  const OnboardingPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentPage ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == currentPage
                ? activeColor
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// Enhanced page indicator with premium design and animations
class PremiumPageIndicator extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Color activeColor;
  final Color inactiveColor;
  final double indicatorHeight;
  final double indicatorSpacing;

  const PremiumPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
    this.inactiveColor = Colors.white,
    this.indicatorHeight = 8.0,
    this.indicatorSpacing = 8.0,
  });

  @override
  State<PremiumPageIndicator> createState() => _PremiumPageIndicatorState();
}

class _PremiumPageIndicatorState extends State<PremiumPageIndicator>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PremiumPageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.totalPages,
          (index) => AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final isActive = index == widget.currentPage;
              final scale = isActive ? _scaleAnimation.value : 1.0;

              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.symmetric(
                      horizontal: widget.indicatorSpacing / 2),
                  width: isActive ? 24 : widget.indicatorHeight,
                  height: widget.indicatorHeight,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              widget.activeColor,
                              widget.activeColor.withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: !isActive
                        ? widget.inactiveColor.withOpacity(0.3)
                        : null,
                    borderRadius:
                        BorderRadius.circular(widget.indicatorHeight / 2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: widget.activeColor.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Animated dots indicator with progress animation
class AnimatedDotsIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const AnimatedDotsIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
    this.inactiveColor = Colors.white,
    this.dotSize = 10.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: index == currentPage ? dotSize * 2.5 : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            gradient: index == currentPage
                ? LinearGradient(
                    colors: [
                      activeColor,
                      activeColor.withOpacity(0.6),
                    ],
                  )
                : null,
            color: index != currentPage ? inactiveColor.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(dotSize / 2),
            border: Border.all(
              color: index == currentPage
                  ? activeColor.withOpacity(0.3)
                  : inactiveColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: index == currentPage
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
