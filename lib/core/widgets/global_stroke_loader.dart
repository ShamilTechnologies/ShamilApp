import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Global stroke-to-fill logo loader for consistent loading states
class GlobalStrokeLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration? duration;
  final bool showBackground;
  final Color? backgroundColor;

  const GlobalStrokeLoader({
    super.key,
    this.size = 80.0,
    this.color,
    this.duration,
    this.showBackground = false,
    this.backgroundColor,
  });

  /// Creates a small loader for buttons and inline usage
  const GlobalStrokeLoader.small({
    super.key,
    this.size = 24.0,
    this.color,
    this.duration,
    this.showBackground = false,
    this.backgroundColor,
  });

  /// Creates a medium loader for cards and sections
  const GlobalStrokeLoader.medium({
    super.key,
    this.size = 48.0,
    this.color,
    this.duration,
    this.showBackground = false,
    this.backgroundColor,
  });

  /// Creates a large loader for full-screen loading
  const GlobalStrokeLoader.large({
    super.key,
    this.size = 120.0,
    this.color,
    this.duration,
    this.showBackground = true,
    this.backgroundColor,
  });

  /// Creates a full-screen overlay loader
  const GlobalStrokeLoader.overlay({
    super.key,
    this.size = 100.0,
    this.color,
    this.duration,
    this.showBackground = true,
    this.backgroundColor,
  });

  @override
  State<GlobalStrokeLoader> createState() => _GlobalStrokeLoaderState();
}

class _GlobalStrokeLoaderState extends State<GlobalStrokeLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fill animation with easing
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _startAnimation() {
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.tealColor;
    final effectiveBackgroundColor =
        widget.backgroundColor ?? AppColors.splashBackground.withOpacity(0.9);

    Widget loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return StrokeToFillLogo(
            logoPath: AssetsIcons.logoSvg,
            brandColor: effectiveColor,
            progress: _fillAnimation.value,
            size: widget.size,
          );
        },
      ),
    );

    if (widget.showBackground) {
      return Container(
        color: effectiveBackgroundColor,
        child: Center(child: loader),
      );
    }

    return loader;
  }
}

/// Optimized stroke-to-fill logo widget for loading states
class StrokeToFillLogo extends StatelessWidget {
  final String logoPath;
  final Color brandColor;
  final double progress;
  final double size;

  const StrokeToFillLogo({
    super.key,
    required this.logoPath,
    required this.brandColor,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Stroke Layer (always visible at 30% opacity)
            SvgPicture.asset(
              logoPath,
              width: size,
              height: size,
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
                width: size,
                height: size,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  brandColor,
                  BlendMode.srcIn,
                ),
              ),
            ),

            // Glow effect when filling (for larger sizes)
            if (progress > 0.1 && size > 40)
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      brandColor.withOpacity(0.4),
                      brandColor.withOpacity(0.4),
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
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    brandColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Utility class for showing global loaders
class LoaderHelper {
  /// Shows a full-screen overlay loader
  static void showOverlay(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GlobalStrokeLoader.overlay(),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hides the overlay loader
  static void hideOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Shows a bottom sheet loader
  static void showBottomSheet(BuildContext context, {String? message}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.splashBackground,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlobalStrokeLoader.large(),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
