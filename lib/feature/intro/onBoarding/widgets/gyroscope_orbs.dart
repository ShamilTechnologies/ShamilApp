import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Widget that creates subtle shine effects responding to gyroscope movements
class GyroscopeShineEffect extends StatelessWidget {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final Color currentPageColor;
  final Size screenSize;

  const GyroscopeShineEffect({
    super.key,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.currentPageColor,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Primary shine effect - diagonal gradient that responds to tilt
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(parallaxOffsetX * 0.5, parallaxOffsetY * 0.5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + (parallaxOffsetX / 50),
                      -1.0 + (parallaxOffsetY / 50)),
                  end: Alignment(1.0 + (parallaxOffsetX / 50),
                      1.0 + (parallaxOffsetY / 50)),
                  colors: [
                    Colors.transparent,
                    currentPageColor.withOpacity(0.03),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Secondary shine layer - creates depth
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(-parallaxOffsetX * 0.3, -parallaxOffsetY * 0.3),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    (parallaxOffsetX / 100).clamp(-1.0, 1.0),
                    (parallaxOffsetY / 100).clamp(-1.0, 1.0),
                  ),
                  radius: 0.8,
                  colors: [
                    currentPageColor.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget that creates gyroscope-responsive background elements
class GyroscopeBackground extends StatelessWidget {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final Color primaryColor;
  final Color secondaryColor;

  const GyroscopeBackground({
    super.key,
    required this.parallaxOffsetX,
    required this.parallaxOffsetY,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        parallaxOffsetX * 0.1,
        parallaxOffsetY * 0.1,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.03),
              secondaryColor.withOpacity(0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
