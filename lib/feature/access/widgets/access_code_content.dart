// lib/feature/access/widgets/access_code_content.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:gap/gap.dart';
import 'dart:typed_data';
// Import shared constants/helpers
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

class AccessCodeContent extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? profileImageUrl;
  final bool isBottomSheet;

  const AccessCodeContent({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileImageUrl,
    this.isBottomSheet = false,
  });

  @override
  State<AccessCodeContent> createState() => _AccessCodeContentState();
}

class _AccessCodeContentState extends State<AccessCodeContent> with TickerProviderStateMixin {
  late AnimationController _entryAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entryAnimationController = AnimationController( vsync: this, duration: const Duration(milliseconds: 600), );
    _fadeAnimation = CurvedAnimation( parent: _entryAnimationController, curve: Curves.easeInOut, );
    _pulseAnimationController = AnimationController( vsync: this, duration: const Duration(milliseconds: 1200), );
    _scaleAnimation = TweenSequence<double>([ TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.03), weight: 50), TweenSequenceItem(tween: Tween<double>(begin: 1.03, end: 1.0), weight: 50), ]).animate(CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) { _entryAnimationController.forward(); _pulseAnimationController.repeat(reverse: true); } });
  }

   @override
  void dispose() {
    _entryAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = widget.userId ?? "error_user_id_not_found";
    final borderRadius = BorderRadius.circular(8.0);
    const double profilePicSize = 64.0;

    final padding = widget.isBottomSheet
      ? const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 40.0)
      : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0);

    // Ensure profileImageUrl handles empty string
    String? effectiveProfileImageUrl = widget.profileImageUrl;
    if (effectiveProfileImageUrl != null && effectiveProfileImageUrl.isEmpty) {
       effectiveProfileImageUrl = null;
    }


    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: widget.isBottomSheet ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             // --- Profile Picture with Hero ---
             Hero(
               // *** Use UNIQUE Hero Tag ***
               tag: 'userProfilePic_hero_access', // Unique tag for access screen
               child: SizedBox(
                 width: profilePicSize, height: profilePicSize,
                 child: Material(
                   shape: RoundedRectangleBorder(borderRadius: borderRadius),
                   clipBehavior: Clip.antiAlias, elevation: 2.0, shadowColor: Colors.black.withOpacity(0.2),
                   child: (effectiveProfileImageUrl == null)
                       ? buildProfilePlaceholder(profilePicSize, theme, borderRadius)
                       : FadeInImage.memoryNetwork( placeholder: transparentImageData, image: effectiveProfileImageUrl, fit: BoxFit.cover, width: profilePicSize, height: profilePicSize, imageErrorBuilder: (context, error, stackTrace) => buildProfilePlaceholder(profilePicSize, theme, borderRadius), ),
                 ),
               ),
             ),
             const Gap(16),

             // --- User Name ---
             Text( widget.userName ?? "User", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, ),
             const Gap(8),

             // --- Instructions ---
             Text( "Present this code to the scanner for entry.", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary), textAlign: TextAlign.center, ),
             const Gap(32),

             // --- Animated QR Code ---
             ScaleTransition(
               scale: _scaleAnimation,
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5), boxShadow: [ BoxShadow( color: theme.colorScheme.primary.withOpacity(0.15), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5), ), ], ),
                 child: QrImageView(
                   data: qrData, version: QrVersions.auto, size: 210.0, gapless: false,
                   eyeStyle: QrEyeStyle( eyeShape: QrEyeShape.square, color: theme.colorScheme.onSurface, ),
                   dataModuleStyle: QrDataModuleStyle( dataModuleShape: QrDataModuleShape.square, color: theme.colorScheme.onSurface, ),
                   errorStateBuilder: (cxt, err) => const Center( child: Text( "Error generating QR code.", textAlign: TextAlign.center, ), ),
                 ),
               ),
             ),
             const Gap(32),

             // --- NFC Placeholder ---
             Opacity( opacity: 0.6, child: Column( children: [
                 Row( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.nfc_rounded, color: theme.colorScheme.secondary, size: 20), const Gap(8), Text( "NFC Access Coming Soon", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary), ), ], ),
                 const Gap(8),
                 Text( "(Ensure NFC is enabled on your device)", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary), textAlign: TextAlign.center, ),
               ], ),
             ),
             if (!widget.isBottomSheet) ...[
                const Spacer(),
                TextButton.icon( icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.secondary), label: Text("Close", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)), onPressed: () => Navigator.maybePop(context), ),
             ]
             else ...[
                const Gap(20),
             ]
          ],
        ),
      ),
    );
  }
}