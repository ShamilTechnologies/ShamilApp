import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors

/// A widget displayed at the bottom of the screen, hinting users to swipe up
/// or tap to view options, often triggering a modal bottom sheet.
class AnimatedSwipeUpBar extends StatefulWidget {
  final VoidCallback onTap; // Callback when tapped or swiped
  final String title;      // Text to display on the bar

  const AnimatedSwipeUpBar({
    super.key,
    required this.onTap,
    this.title = "View Options",
  });

  @override
  State<AnimatedSwipeUpBar> createState() => _AnimatedSwipeUpBarState();
}

class _AnimatedSwipeUpBarState extends State<AnimatedSwipeUpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Duration of one bounce cycle
    );

    // Create a bouncing animation for the arrow icon
    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 40), // Move up
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 0), weight: 40), // Move down
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 0), weight: 20), // Pause
    ]).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutSine));

    // Start the animation loop after a short delay
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
     _timer?.cancel(); // Cancel any existing timer
     _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
           _animationController.forward(from: 0.0); // Start animation cycle
        } else {
           timer.cancel(); // Stop timer if widget is disposed
        }
     });
     // Initial animation start
     if (mounted) {
        _animationController.forward();
     }
  }


  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel(); // Important to cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = Radius.circular(16.0);

    return GestureDetector(
      onTap: widget.onTap,
      // Detect vertical drag to trigger the action as well
      onVerticalDragUpdate: (details) {
        // Trigger if swipe is upwards (negative delta) and significant enough
        if (details.primaryDelta != null && details.primaryDelta! < -5) {
          widget.onTap();
        }
      },
      child: Container(
        // Styling for the bar container
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppColors.primaryColor, // Use primary color
          borderRadius: BorderRadius.only( // Rounded top corners
            topLeft: borderRadius,
            topRight: borderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, -2), // Shadow upwards
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated arrow icon
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                );
              },
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            // Text label
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
             // Second animated arrow icon for symmetry
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                );
              },
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}