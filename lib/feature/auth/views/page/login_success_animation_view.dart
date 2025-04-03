import 'dart:async';
import 'dart:math'; // Import for Random and pi
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart'; // Use navigation functions
import 'package:shamil_mobile_app/feature/navigation/main_navigation_view.dart'; // Import main navigation
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Import text styles
// Import AppColors

// Placeholder for transparent image data (1x1 pixel PNG)
const List<int> kTransparentImage = <int>[ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, ];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

// Simple class to hold data for an animated line
class AnimatedLine {
  Offset start; Offset end; final double maxOpacity;
  final Duration duration; final DateTime startTime; final double strokeWidth;
  AnimatedLine({required Size bounds}) :
    maxOpacity = Random().nextDouble() * 0.2 + 0.1, // Random opacity 0.1 - 0.3
    duration = Duration(milliseconds: 2000 + Random().nextInt(2000)),
    startTime = DateTime.now(),
    strokeWidth = 1.0 + Random().nextDouble() * 1.5,
    start = Offset(
      Random().nextDouble() * bounds.width,
      Random().nextDouble() * bounds.height,
    ),
    end = const Offset(
      0, // Temporary value, will be updated below
      0, // Temporary value, will be updated below
    ) {
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double length = (bounds.shortestSide * 0.1) + random.nextDouble() * (bounds.shortestSide * 0.2);
    end = Offset(start.dx + cos(angle) * length, start.dy + sin(angle) * length);
  }
  double get currentOpacity {
    final elapsed = DateTime.now().difference(startTime); if (elapsed >= duration) return 0.0;
    double progress = elapsed.inMilliseconds / duration.inMilliseconds;
    return maxOpacity * (1.0 - Curves.easeOutCubic.transform(progress));
  }
}


class LoginSuccessAnimationView extends StatefulWidget {
  final String? profilePicUrl;
  final String? firstName;
  const LoginSuccessAnimationView({ super.key, this.profilePicUrl, this.firstName, });

  @override
  State<LoginSuccessAnimationView> createState() => _LoginSuccessAnimationViewState();
}

class _LoginSuccessAnimationViewState extends State<LoginSuccessAnimationView>
    with TickerProviderStateMixin {
  late AnimationController _fgController;
  late Animation<double> _scaleAnimation;
  // *** FIX: Remove 'late' and make nullable ***
  Animation<Color?>? _colorAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _bgController;
  final List<AnimatedLine> _lines = [];
  final Random _random = Random();
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();

    // --- Foreground Animations Setup ---
    _fgController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Keep longer duration
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([ TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.20).chain(CurveTween(curve: Curves.easeOut)), weight: 40), TweenSequenceItem(tween: Tween<double>(begin: 1.20, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60), ]).animate(_fgController);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate( CurvedAnimation(parent: _fgController, curve: const Interval(0.0, 0.35, curve: Curves.easeIn)) );

     WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           // Initialize color animation here where context is safe
           _colorAnimation = ColorTween(
             begin: Theme.of(context).colorScheme.primary.withOpacity(0.0),
             end: Theme.of(context).colorScheme.primary.withOpacity(0.9),
           ).animate(CurvedAnimation(parent: _fgController, curve: const Interval(0.15, 0.85, curve: Curves.easeInOut)));
           // Trigger state update if needed, though AnimatedBuilder will pick it up
           // setState((){});
           _fgController.forward();
           _screenSize = MediaQuery.of(context).size;
        }
     });

    _fgController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 800), () { // Keep longer delay
           if (mounted) { pushAndRemoveUntil(context, const MainNavigationView()); }
        });
      }
    });

    // --- Background Animations Setup ---
    _bgController = AnimationController(
       duration: const Duration(seconds: 5), vsync: this,
    )..addListener(_updateBackgroundLines)..repeat();

  }

  void _updateBackgroundLines() {
     if (!mounted || _screenSize == Size.zero) return;
     _lines.removeWhere((line) => line.currentOpacity <= 0.0);
     const maxLines = 15;
     if (_lines.length < maxLines && _random.nextDouble() < 0.08) {
        _lines.add(AnimatedLine(bounds: _screenSize));
     }
     if (mounted) { // Check mounted before calling setState
       setState(() {});
     }
  }


  @override
  void dispose() {
    _fgController.dispose();
    _bgController.removeListener(_updateBackgroundLines);
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 120.0;
    final borderRadius = BorderRadius.circular(12.0);

    Widget imageWidget = (widget.profilePicUrl != null && widget.profilePicUrl!.isNotEmpty)
        ? ClipRRect(
            borderRadius: borderRadius,
            child: FadeInImage.memoryNetwork(
               placeholder: _transparentImageData, image: widget.profilePicUrl!,
               width: size, height: size, fit: BoxFit.cover,
               imageErrorBuilder: (context, error, stackTrace) => _buildPlaceholder(size, theme, borderRadius),
            ),
          )
        : _buildPlaceholder(size, theme, borderRadius);

    final String welcomeMessage = (widget.firstName != null && widget.firstName!.isNotEmpty)
       ? "Welcome, ${widget.firstName}!" : "Welcome!";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Animation Painter
          CustomPaint(
             painter: _BackgroundLinesPainter( lines: _lines, color: theme.colorScheme.primary, ),
             child: Container(),
          ),

          // Foreground Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _fgController,
                builder: (context, child) {
                  // *** FIX: Use null-aware access and default value ***
                  final borderColor = _colorAnimation?.value ?? Colors.transparent;
                  return Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        // Animated Container
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: size + 8, height: size + 8,
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              border: Border.all( color: borderColor, width: 2.0, ), // Uses borderColor safely
                            ),
                            child: imageWidget,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Animated Text
                        Text(
                           welcomeMessage,
                           textAlign: TextAlign.center,
                           style: getHeadlineTextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary
                           ),
                        ),
                     ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the placeholder widget
  Widget _buildPlaceholder(double containerSize, ThemeData theme, BorderRadius borderRadius) {
     double iconSize = containerSize * 0.5;
    return Container(
      width: containerSize, height: containerSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: borderRadius,
         border: Border.all( color: theme.colorScheme.primary.withOpacity(0.1), width: 1.0, ),
      ),
      child: Center( child: Icon( Icons.person_rounded, size: iconSize, color: theme.colorScheme.primary.withOpacity(0.4), ), ),
    );
   }
}


// Custom Painter for Background Lines
class _BackgroundLinesPainter extends CustomPainter {
   final List<AnimatedLine> lines; final Color color;
   _BackgroundLinesPainter({required this.lines, required this.color});
   @override void paint(Canvas canvas, Size size) {
      for (final line in lines) {
         final opacity = line.currentOpacity;
         if (opacity > 0) {
             final paint = Paint() ..color = color.withOpacity(opacity) ..strokeWidth = line.strokeWidth ..strokeCap = StrokeCap.round;
             canvas.drawLine(line.start, line.end, paint);
         } } }
   @override bool shouldRepaint(covariant _BackgroundLinesPainter oldDelegate) { return true; }
}
