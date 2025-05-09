import 'dart:math'; // Import for Random and pi
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
// Keep for other potential uses
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart'; // Import main navigation
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Import text styles
// Import AppColors if needed by placeholder

// Placeholder for transparent image data (1x1 pixel PNG)
// Consider moving this to a shared constants file (e.g., lib/core/constants/image_constants.dart)
const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

// Simple class to hold data for an animated line used in the background
class AnimatedLine {
  Offset start;
  Offset end;
  final double maxOpacity;
  final Duration duration;
  final DateTime startTime;
  final double strokeWidth;

  AnimatedLine({required Size bounds})
      : maxOpacity =
            Random().nextDouble() * 0.2 + 0.1, // Random opacity 0.1 - 0.3
        duration = Duration(
            milliseconds:
                2000 + Random().nextInt(2000)), // Random duration 2-4s
        startTime = DateTime.now(),
        strokeWidth = 1.0 + Random().nextDouble() * 1.5, // Random stroke width
        start = Offset(
          Random().nextDouble() * bounds.width,
          Random().nextDouble() * bounds.height,
        ),
        // Calculate end point based on random angle and length
        end = Offset.zero {
    // Initialize with a default value
    // Calculate the actual end point after 'start' is initialized
    end = _calculateEndPoint(start, bounds);
  }

  // Helper to calculate end point within bounds
  static Offset _calculateEndPoint(Offset start, Size bounds) {
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    // Ensure line length is reasonable relative to screen size
    double length = (bounds.shortestSide * 0.1) +
        random.nextDouble() * (bounds.shortestSide * 0.2);
    return Offset(
        start.dx + cos(angle) * length, start.dy + sin(angle) * length);
  }

  // Calculate current opacity based on elapsed time and duration
  double get currentOpacity {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed >= duration) return 0.0; // Fully faded out
    double progress = elapsed.inMilliseconds / duration.inMilliseconds;
    // Use a curve to make fading smoother
    return maxOpacity * (1.0 - Curves.easeOutCubic.transform(progress));
  }
}

/// A screen displayed after successful login or ID upload, showing an animation
/// before navigating to the main application screen. Includes Hero animation for profile pic.
class LoginSuccessAnimationView extends StatefulWidget {
  // Accept profile picture URL and user's first name to display
  final String? profilePicUrl;
  final String? firstName;

  const LoginSuccessAnimationView({
    super.key,
    this.profilePicUrl, // Optional: Can be null if not available
    this.firstName, // Optional: Can be null
  });

  @override
  State<LoginSuccessAnimationView> createState() =>
      _LoginSuccessAnimationViewState();
}

class _LoginSuccessAnimationViewState extends State<LoginSuccessAnimationView>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController
      _fgController; // Controls foreground elements (scale, fade, border)
  late AnimationController
      _bgController; // Controls background line animation redraw

  // Foreground Animations
  late Animation<double>
      _scaleAnimation; // For scaling the profile picture container
  Animation<Color?>?
      _colorAnimation; // For animating the border color (nullable)
  late Animation<double> _fadeAnimation; // For fading in the content

  // Background Animation State
  final List<AnimatedLine> _lines = []; // List of lines for background effect
  final Random _random = Random(); // Random generator for lines
  Size _screenSize = Size.zero; // Screen size needed for line generation

  @override
  void initState() {
    super.initState();

    // --- Foreground Animations Setup ---
    _fgController = AnimationController(
      // Duration for the entire foreground sequence (scale, border, fade)
      duration: const Duration(milliseconds: 2500), // Adjust as needed
      vsync: this,
    );

    // Scale animation: zoom in slightly then back to normal size
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.8, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 55),
    ]).animate(_fgController);

    // Fade animation for the content (image + text)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fgController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // Initialize color animation after the first frame build (needs context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure widget is still in the tree
        _colorAnimation = ColorTween(
          begin: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.0), // Start transparent
          end: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.8), // End slightly transparent primary
        ).animate(CurvedAnimation(
            parent: _fgController,
            curve: const Interval(0.1, 0.9, curve: Curves.easeInOut)));
        // Start the foreground animation sequence
        _fgController.forward();
        // Get screen size for background lines after layout
        _screenSize = MediaQuery.of(context).size;
      }
    });

    // Listener to navigate when foreground animation completes
    _fgController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Use standard Navigator with PageRouteBuilder for custom transition duration
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigationView(),
            // Set transition duration to control Hero animation speed
            transitionDuration: const Duration(
                milliseconds: 800), // Increased duration (slower)
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Use a simple fade for the page transition itself
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    });

    // --- Background Animations Setup ---
    _bgController = AnimationController(
      duration: const Duration(
          seconds: 5), // Duration for one cycle of background changes
      vsync: this,
    )
      ..addListener(_updateBackgroundLines)
      ..repeat(); // Repeat indefinitely
  }

  /// Updates the list of animated lines for the background effect
  void _updateBackgroundLines() {
    // Only update if widget is mounted and screen size is known
    if (!mounted || _screenSize == Size.zero) return;
    // Remove lines that have fully faded out
    _lines.removeWhere((line) => line.currentOpacity <= 0.0);
    // Add new lines occasionally, up to a maximum limit
    const maxLines = 15;
    if (_lines.length < maxLines && _random.nextDouble() < 0.08) {
      // Adjust probability for new lines
      _lines.add(AnimatedLine(bounds: _screenSize));
    }
    // Trigger a repaint of the CustomPaint using this State's context
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Dispose all animation controllers to free resources
    _fgController.dispose();
    _bgController.removeListener(
        _updateBackgroundLines); // Remove listener before disposing
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 120.0; // Size of the image container
    final borderRadius = BorderRadius.circular(8.0); // Use 8px radius

    // Build the image/placeholder widget conditionally
    Widget imageWidget = (widget.profilePicUrl != null &&
            widget.profilePicUrl!.isNotEmpty)
        ? ClipRRect(
            // Clip the image to the border radius
            borderRadius: borderRadius,
            child: FadeInImage.memoryNetwork(
              placeholder: _transparentImageData, // Use transparent placeholder
              image: widget.profilePicUrl!,
              width: size, height: size, fit: BoxFit.cover,
              // Display placeholder on image load error
              imageErrorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(size, theme, borderRadius),
            ),
          )
        : _buildPlaceholder(
            size, theme, borderRadius); // Use placeholder if no URL

    // Construct welcome message, handling null/empty first name
    final String welcomeMessage =
        (widget.firstName != null && widget.firstName!.isNotEmpty)
            ? "Welcome, ${widget.firstName}!"
            : "Welcome!";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        // Use Stack for background animation and centered content
        alignment: Alignment.center,
        children: [
          // Background Animation Painter
          CustomPaint(
            painter: _BackgroundLinesPainter(
              lines: _lines,
              color: theme.colorScheme.primary,
            ),
            child: Container(), // CustomPaint needs a child
          ),

          // Foreground Content (Icon/Image and Text)
          Center(
            child: FadeTransition(
              // Fade in the entire foreground content
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                // Rebuilds when foreground controller ticks
                animation: _fgController,
                builder: (context, child) {
                  // Get animated border color, default to transparent if animation not ready
                  final borderColor =
                      _colorAnimation?.value ?? Colors.transparent;
                  return Column(
                    mainAxisSize: MainAxisSize.min, // Center vertically
                    children: [
                      // Hero Widget for the profile picture transition
                      Hero(
                                               tag: 'userProfilePic_hero_main_explore',

                        child: Transform.scale(
                          // Apply scale animation
                          scale: _scaleAnimation.value,
                          child: Container(
                            // Container for border and padding
                            width: size + 8,
                            height:
                                size + 8, // Slightly larger for padding/border
                            padding: const EdgeInsets.all(
                                4.0), // Padding around image
                            decoration: BoxDecoration(
                              borderRadius:
                                  borderRadius, // Apply radius to border container
                              border: Border.all(
                                color: borderColor,
                                width: 2.0,
                              ), // Animated border
                            ),
                            child: imageWidget, // Display image or placeholder
                          ),
                        ),
                      ),
                      const SizedBox(
                          height: 24), // Space between image and text
                      // Welcome Text
                      Text(
                        welcomeMessage,
                        textAlign: TextAlign.center,
                        // Use custom text style function or theme
                        style: getHeadlineTextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary // Use theme color
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

  /// Helper function to build the placeholder widget for the profile picture.
  Widget _buildPlaceholder(
      double containerSize, ThemeData theme, BorderRadius borderRadius) {
    double iconSize = containerSize * 0.5; // Relative icon size
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05), // Subtle background
        borderRadius:
            borderRadius, // Apply border radius here too for consistency
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1.0,
        ), // Subtle border
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: iconSize,
          color: theme.colorScheme.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}

// Custom Painter for the animated background lines effect.
class _BackgroundLinesPainter extends CustomPainter {
  final List<AnimatedLine> lines;
  final Color color;
  _BackgroundLinesPainter({required this.lines, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Iterate through lines and draw them with current opacity
    for (final line in lines) {
      final opacity = line.currentOpacity;
      if (opacity > 0) {
        // Only draw if visible
        final paint = Paint()
          ..color = color.withOpacity(opacity) // Apply calculated opacity
          ..strokeWidth = line.strokeWidth
          ..strokeCap = StrokeCap.round; // Rounded line ends
        canvas.drawLine(line.start, line.end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundLinesPainter oldDelegate) {
    // Repaint whenever the lines list changes (driven by AnimationController)
    return true;
  }
}
