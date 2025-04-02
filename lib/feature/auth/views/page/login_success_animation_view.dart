import 'dart:async';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart'; // Use navigation functions
import 'package:shamil_mobile_app/feature/navigation/main_navigation_view.dart'; // Import main navigation

// Placeholder for transparent image data (1x1 pixel PNG)
const List<int> kTransparentImage = const <int>[ // Keep as List<int> here
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
];


class LoginSuccessAnimationView extends StatefulWidget {
  final String? profilePicUrl; // Receive profile picture URL

  const LoginSuccessAnimationView({super.key, this.profilePicUrl});

  @override
  State<LoginSuccessAnimationView> createState() => _LoginSuccessAnimationViewState();
}

class _LoginSuccessAnimationViewState extends State<LoginSuccessAnimationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  // Pre-convert the list to Uint8List once
  final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Duration of the internal animation
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

     WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
           _colorAnimation = ColorTween(
             begin: Theme.of(context).colorScheme.primary.withOpacity(0.0),
             end: Theme.of(context).colorScheme.primary.withOpacity(0.8),
           ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
           _controller.forward(); // Start the internal animation
        }
     });

    // Listener to navigate AFTER the internal animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a bit longer after animation finishes before navigating
        Future.delayed(const Duration(milliseconds: 500), () { // Increased delay
           if (mounted) {
              // Use standard navigation - NO Hero animation between screens
              pushAndRemoveUntil(context, const MainNavigationView());
           }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 120.0;
    final borderRadius = BorderRadius.circular(12.0);

    // Build the image/placeholder widget (same as before)
    Widget imageWidget = (widget.profilePicUrl != null && widget.profilePicUrl!.isNotEmpty)
        ? ClipRRect(
            borderRadius: borderRadius,
            child: FadeInImage.memoryNetwork(
               // *** FIX: Use the converted Uint8List ***
               placeholder: _transparentImageData,
               image: widget.profilePicUrl!,
               width: size,
               height: size,
               fit: BoxFit.cover,
               imageErrorBuilder: (context, error, stackTrace) => _buildPlaceholder(size, theme, borderRadius),
            ),
          )
        : _buildPlaceholder(size, theme, borderRadius);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        // Build the animated container without Hero
        child: (_controller.isAnimating || _controller.isCompleted) && (_colorAnimation != null)
           ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final borderColor = _colorAnimation.value ?? Colors.transparent;
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  // *** Hero widget REMOVED ***
                  child: Container( // The container with the animated border
                    width: size + 8,
                    height: size + 8,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: borderColor, // Animated border color
                        width: 2.0,
                      ),
                    ),
                    child: imageWidget, // The image/placeholder inside
                  ),
                );
              },
            )
           : _buildPlaceholder(size + 8, theme, borderRadius), // Initial placeholder
      ),
    );
  }

  // Helper to build the placeholder widget (same as before)
  Widget _buildPlaceholder(double containerSize, ThemeData theme, BorderRadius borderRadius) {
     double iconSize = containerSize * 0.5;
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: borderRadius,
         border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1.0,
         ),
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
