import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

class PremiumAuthBackground extends StatefulWidget {
  final Widget child;

  const PremiumAuthBackground({
    super.key,
    required this.child,
  });

  @override
  State<PremiumAuthBackground> createState() => _PremiumAuthBackgroundState();
}

class _PremiumAuthBackgroundState extends State<PremiumAuthBackground> {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  double _parallaxX = 0.0;
  double _parallaxY = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeGyroscope();
  }

  void _initializeGyroscope() {
    try {
      _gyroscopeSubscription = gyroscopeEvents.listen((event) {
        if (mounted) {
          setState(() {
            _parallaxX = (event.y * 5).clamp(-10.0, 10.0);
            _parallaxY = (-event.x * 5).clamp(-10.0, 10.0);
          });
        }
      });
    } catch (e) {
      debugPrint('Gyroscope unavailable: $e');
    }
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(
            (_parallaxX / 100).clamp(-0.2, 0.2),
            (_parallaxY / 100).clamp(-0.2, 0.2),
          ),
          radius: 1.2,
          colors: [
            AppColors.splashBackground,
            AppColors.tealColor.withOpacity(0.03),
            AppColors.splashBackground,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background particles
          _buildBackgroundParticles(size),

          // Main content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildBackgroundParticles(Size size) {
    return Transform.translate(
      offset: Offset(_parallaxX * 0.3, _parallaxY * 0.3),
      child: Stack(
        children: [
          Positioned(
            top: size.height * 0.2,
            right: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.08),
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
}
