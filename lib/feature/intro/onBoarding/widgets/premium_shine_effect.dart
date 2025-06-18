import 'dart:math';
import 'package:flutter/material.dart';

/// Premium shine effect that responds to gyroscope movements
class PremiumShineEffect extends StatelessWidget {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final Color primaryColor;
  final Widget child;

  const PremiumShineEffect({
    super.key,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.primaryColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Animated shine overlay
        _buildShineOverlay(),
      ],
    );
  }

  Widget _buildShineOverlay() {
    // Calculate shine position based on gyroscope
    final shineX = (parallaxOffsetX / 30).clamp(-1.0, 1.0);
    final shineY = (parallaxOffsetY / 30).clamp(-1.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(shineX - 0.3, shineY - 0.3),
              end: Alignment(shineX + 0.3, shineY + 0.3),
              colors: [
                Colors.transparent,
                primaryColor.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                primaryColor.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium background gradient that responds to gyroscope
class GyroscopicBackground extends StatelessWidget {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final Color primaryColor;
  final Color baseColor;

  const GyroscopicBackground({
    super.key,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.primaryColor,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final gradientX = (parallaxOffsetX / 100).clamp(-0.3, 0.3);
    final gradientY = (parallaxOffsetY / 100).clamp(-0.3, 0.3);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(gradientX, gradientY),
          radius: 1.5,
          colors: [
            baseColor,
            primaryColor.withOpacity(0.05),
            baseColor,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}

/// Subtle moving highlight effect
class MovingHighlight extends StatelessWidget {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final Color highlightColor;
  final Widget child;

  const MovingHighlight({
    super.key,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.highlightColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(parallaxOffsetX * 0.1, parallaxOffsetY * 0.1),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-2.0, -2.0),
                  end: const Alignment(2.0, 2.0),
                  colors: [
                    Colors.transparent,
                    highlightColor.withOpacity(0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: GradientRotation(
                    (parallaxOffsetX + parallaxOffsetY) * 0.02,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
