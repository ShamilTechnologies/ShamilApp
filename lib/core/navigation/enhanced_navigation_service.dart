import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enum for slide directions
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Auth Navigation - Specialized for authentication flow
class AuthNavigation {
  // Enhanced animation durations for stability
  static const Duration _fastDuration = Duration(milliseconds: 350);
  static const Duration _normalDuration = Duration(milliseconds: 600);
  static const Duration _slowDuration = Duration(milliseconds: 900);

  /// Navigate to sign in with smooth slide transition
  static Future<T?> toSignIn<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumAuthSlideTransition(
              animation, secondaryAnimation, child, SlideDirection.left);
        },
      ),
    );
  }

  /// Navigate to register with smooth slide transition
  static Future<T?> toRegister<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumAuthSlideTransition(
              animation, secondaryAnimation, child, SlideDirection.right);
        },
      ),
    );
  }

  /// Navigate to forgot password with premium fade slide transition
  static Future<T?> toForgotPassword<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumFadeSlideTransition(
              animation, secondaryAnimation, child);
        },
      ),
    );
  }

  /// Back to previous auth screen with reverse animation
  static void back(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  /// Navigate after successful auth with celebration transition
  static Future<T?> toMainApp<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _slowDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _celebrationTransition(animation, child);
        },
      ),
      (route) => false,
    );
  }

  // Premium auth transition methods
  static Widget _premiumAuthSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    SlideDirection direction,
  ) {
    // High-end app curves for smooth motion
    const primaryCurve = Curves.easeOutCubic;
    const secondaryCurve = Curves.easeInCubic;

    final slideOffset = direction == SlideDirection.left
        ? const Offset(-1.0, 0.0)
        : const Offset(1.0, 0.0);

    // Primary slide animation with enhanced smoothness
    final slideAnimation = Tween<Offset>(
      begin: slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: primaryCurve,
    ));

    // Secondary animation for the previous screen
    final secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: direction == SlideDirection.left
          ? const Offset(0.25, 0.0)
          : const Offset(-0.25, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: secondaryCurve,
    ));

    // Enhanced fade animation with custom intervals
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    // Secondary fade for smoother transitions
    final secondaryFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInQuart),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: secondarySlideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _premiumFadeSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Gentle, premium motion
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
    ));

    // Scale for subtle depth
    final scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  static Widget _celebrationTransition(
      Animation<double> animation, Widget child) {
    // Enhanced success transition with premium feel
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    final scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));

    // Subtle slide for depth
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }
}

/// Global Navigation - For general app navigation
class GlobalNavigation {
  static const Duration _fastDuration = Duration(milliseconds: 350);
  static const Duration _normalDuration = Duration(milliseconds: 600);

  /// Push with premium fade transition
  static Future<T?> pushFade<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumFadeTransition(animation, secondaryAnimation, child);
        },
      ),
    );
  }

  /// Push with premium slide from right
  static Future<T?> pushSlideRight<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumSlideTransition(
              animation, secondaryAnimation, child, SlideDirection.right);
        },
      ),
    );
  }

  /// Push with premium slide from bottom
  static Future<T?> pushSlideUp<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumSlideTransition(
              animation, secondaryAnimation, child, SlideDirection.up);
        },
      ),
    );
  }

  /// Push with premium scale transition
  static Future<T?> pushScale<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumScaleTransition(animation, secondaryAnimation, child);
        },
      ),
    );
  }

  /// Replace with premium fade transition
  static Future<T?> replaceFade<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumFadeTransition(animation, secondaryAnimation, child);
        },
      ),
    );
  }

  /// Replace with premium slide transition
  static Future<T?> replaceSlide<T extends Object?>(
      BuildContext context, Widget screen,
      {SlideDirection direction = SlideDirection.right}) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        reverseTransitionDuration: _fastDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _premiumSlideTransition(
              animation, secondaryAnimation, child, direction);
        },
      ),
    );
  }

  /// Clear stack and navigate with premium transition
  static Future<T?> clearAndNavigate<T extends Object?>(
      BuildContext context, Widget screen) {
    HapticFeedback.mediumImpact();
    return Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, _) => screen,
        transitionDuration: _normalDuration,
        transitionsBuilder: (context, animation, _, child) {
          return _premiumFadeTransition(animation, null, child);
        },
      ),
      (route) => false,
    );
  }

  // Premium transition implementations
  static Widget _premiumFadeTransition(
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
    ));

    // Subtle scale for depth
    final scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    Widget result = ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );

    // Add secondary animation if provided
    if (secondaryAnimation != null) {
      final secondaryFadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.92,
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInQuart,
      ));

      final secondaryScaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.96,
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      ));

      result = ScaleTransition(
        scale: secondaryScaleAnimation,
        child: FadeTransition(
          opacity: secondaryFadeAnimation,
          child: result,
        ),
      );
    }

    return result;
  }

  static Widget _premiumSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    SlideDirection direction,
  ) {
    late Offset beginOffset;
    late Offset secondaryOffset;

    switch (direction) {
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        secondaryOffset = const Offset(0.3, 0.0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        secondaryOffset = const Offset(-0.3, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, 1.0);
        secondaryOffset = const Offset(0.0, -0.3);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, -1.0);
        secondaryOffset = const Offset(0.0, 0.3);
        break;
    }

    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: secondaryOffset,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    ));

    // Enhanced fade animations
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuart),
    ));

    final secondaryFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInQuart),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: secondarySlideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _premiumScaleTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    // Secondary scale for background
    final secondaryScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    ));

    final secondaryFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInQuart,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: secondaryScaleAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Modal Navigation - For bottom sheets, dialogs, etc.
class ModalNavigation {
  static const Duration _normalDuration = Duration(milliseconds: 500);

  /// Show bottom sheet with premium animation
  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    Widget sheet, {
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      transitionAnimationController: AnimationController(
        duration: _normalDuration,
        vsync: Navigator.of(context),
      ),
      builder: (context) => sheet,
    );
  }

  /// Show dialog with premium scale animation
  static Future<T?> showDialog<T>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
  }) {
    HapticFeedback.lightImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: _normalDuration,
      pageBuilder: (context, animation, _) => dialog,
      transitionBuilder: (context, animation, _, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Enhanced Navigation Service - Main service class
class EnhancedNavigationService {
  /// Access to auth navigation
  static AuthNavigation get auth => AuthNavigation();

  /// Access to global navigation
  static GlobalNavigation get global => GlobalNavigation();

  /// Access to modal navigation
  static ModalNavigation get modal => ModalNavigation();
}

/// Extension methods for convenient navigation
extension EnhancedNavigationExtension on BuildContext {
  /// Quick access to enhanced navigation
  EnhancedNavigationService get nav => EnhancedNavigationService();

  /// Auth navigation shortcuts
  Future<T?> toSignIn<T extends Object?>(Widget screen) =>
      AuthNavigation.toSignIn<T>(this, screen);

  Future<T?> toRegister<T extends Object?>(Widget screen) =>
      AuthNavigation.toRegister<T>(this, screen);

  Future<T?> toForgotPassword<T extends Object?>(Widget screen) =>
      AuthNavigation.toForgotPassword<T>(this, screen);

  /// Global navigation shortcuts
  Future<T?> pushFade<T extends Object?>(Widget screen) =>
      GlobalNavigation.pushFade<T>(this, screen);

  Future<T?> pushSlideRight<T extends Object?>(Widget screen) =>
      GlobalNavigation.pushSlideRight<T>(this, screen);

  Future<T?> pushSlideUp<T extends Object?>(Widget screen) =>
      GlobalNavigation.pushSlideUp<T>(this, screen);

  Future<T?> pushScale<T extends Object?>(Widget screen) =>
      GlobalNavigation.pushScale<T>(this, screen);
}
