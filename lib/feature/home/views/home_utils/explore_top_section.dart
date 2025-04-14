import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:gap/gap.dart';
import 'dart:typed_data'; // For Uint8List
import 'dart:math'; // For pi
// Import shared constants/helpers
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';


class ExploreTopSection extends StatefulWidget {
  final String currentCity;
  final String userName;
  final String? profileImageUrl;
  final VoidCallback onCityTap;
  final VoidCallback onProfileTap;

  const ExploreTopSection({
    super.key,
    required this.currentCity,
    required this.userName,
    required this.profileImageUrl,
    required this.onCityTap,
    required this.onProfileTap,
  });

  @override
  State<ExploreTopSection> createState() => _ExploreTopSectionState();
}

class _ExploreTopSectionState extends State<ExploreTopSection> with TickerProviderStateMixin {

  // Controller for continuous revolving border animation
  late AnimationController _revolveController;

  // Controller for tap animation
  late AnimationController _tapController;
  late Animation<double> _scaleTapAnimation;

  @override
  void initState() {
    super.initState();

    // --- Setup Revolving Border Animation ---
    _revolveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Speed of one full revolution
    )..repeat(); // Start repeating immediately

    // --- Setup Tap Scale Animation (Expand) ---
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleTapAnimation = Tween<double>(begin: 1.0, end: 1.1) // Expand slightly
        .animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _revolveController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  // --- Tap Handler ---
  void _handleProfileTap() {
    _tapController.forward().then((_) {
       Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) { _tapController.reverse(); }
       });
       widget.onProfileTap();
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(8.0);
    const double avatarSize = 44.0;
    const double borderStrokeWidth = 2.0; // Can adjust border thickness via padding

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Greeting and Location Selector
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text( "Hello, ${widget.userName} 👋", style: theme.textTheme.titleMedium?.copyWith( color: theme.colorScheme.secondary, fontWeight: FontWeight.w500, ), ),
              const Gap(4),
              Material( color: Colors.transparent, child: InkWell( onTap: widget.onCityTap, borderRadius: borderRadius, splashColor: theme.colorScheme.primary.withOpacity(0.1), highlightColor: theme.colorScheme.primary.withOpacity(0.05), child: Padding( padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), child: Row( mainAxisSize: MainAxisSize.min, children: [ Icon( Icons.location_on_outlined, color: theme.colorScheme.primary, size: 18, ), const Gap(4), Text( widget.currentCity, style: theme.textTheme.titleLarge?.copyWith( fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground, ), ), const Gap(4), Icon( Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary, size: 20, ), ], ), ), ), ),
            ],
        ),

        // Right side: Profile Picture with Hero, Revolve Border, and Tap Animations
        ScaleTransition( // Apply tap scale animation
           scale: _scaleTapAnimation,
           child: Hero(
             tag: 'userProfilePic_hero',
             child: SizedBox(
               width: avatarSize,
               height: avatarSize,
               child: AnimatedBuilder( // Use AnimatedBuilder to rebuild border container
                 animation: _revolveController,
                 builder: (context, child) {
                   // Container acting as the animated border
                   return Container(
                     padding: const EdgeInsets.all(borderStrokeWidth), // Padding creates border
                     decoration: BoxDecoration(
                       borderRadius: borderRadius,
                       shape: BoxShape.rectangle,
                       gradient: SweepGradient( // Apply the revolving gradient
                         colors: [
                            theme.colorScheme.primary.withOpacity(0.9), // Start color
                            theme.colorScheme.primary.withOpacity(0.9), // Hold color
                            Colors.transparent, // Fade to transparent
                            Colors.transparent, // Stay transparent
                         ],
                         stops: const [ 0.0, 0.25, 0.30, 1.0, ], // Adjust stops for segment size/fade
                         tileMode: TileMode.repeated, // Ensures smooth wrap-around
                         transform: GradientRotation( _revolveController.value * 2 * pi ),
                       ),
                     ),
                     child: child, // The actual image content goes here
                   );
                 },
                 // Child passed to AnimatedBuilder's builder: The actual image container
                 child: Material( // Use Material for clipping and InkWell ripple
                   shape: RoundedRectangleBorder(borderRadius: borderRadius),
                   clipBehavior: Clip.antiAlias,
                   elevation: 0.0, // No need for elevation on inner content
                   child: InkWell(
                     onTap: _handleProfileTap,
                     borderRadius: borderRadius, // Match shape for splash
                     child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
                         ? buildProfilePlaceholder(avatarSize, theme, borderRadius) // Placeholder fills Material
                         : FadeInImage.memoryNetwork(
                             placeholder: transparentImageData,
                             image: widget.profileImageUrl!,
                             fit: BoxFit.cover,
                             // Let image fill the space defined by SizedBox -> Material
                             width: double.infinity,
                             height: double.infinity,
                             imageErrorBuilder: (context, error, stackTrace) {
                               return buildProfilePlaceholder(avatarSize, theme, borderRadius);
                             },
                           ),
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

// Note: buildProfilePlaceholder should be imported from lib/core/widgets/placeholders.dart
// Note: transparentImageData should be imported from lib/core/constants/image_constants.dart
