import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/enhanced_stroke_loader.dart';

/// Button states for enhanced auth button
enum AuthButtonState {
  idle,
  loading,
  success,
  error,
}

/// Enhanced authentication button with state management and haptic feedback
class EnhancedAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AuthButtonState state;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? loaderColor;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Duration? animationDuration;
  final bool enableHapticFeedback;
  final String? loadingText;
  final String? successText;
  final String? errorText;

  const EnhancedAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.state = AuthButtonState.idle,
    this.backgroundColor,
    this.textColor,
    this.loaderColor,
    this.height = 52.0,
    this.borderRadius = 12.0,
    this.padding,
    this.textStyle,
    this.animationDuration,
    this.enableHapticFeedback = true,
    this.loadingText,
    this.successText,
    this.errorText,
  });

  @override
  State<EnhancedAuthButton> createState() => _EnhancedAuthButtonState();
}

class _EnhancedAuthButtonState extends State<EnhancedAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  AuthButtonState? _previousState;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _previousState = widget.state;
  }

  @override
  void didUpdateWidget(EnhancedAuthButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateChange();
      _previousState = oldWidget.state;
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getButtonColor(AuthButtonState.idle),
      end: _getButtonColor(widget.state),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleStateChange() {
    if (widget.enableHapticFeedback) {
      switch (widget.state) {
        case AuthButtonState.loading:
          HapticFeedback.lightImpact();
          break;
        case AuthButtonState.success:
          HapticFeedback.mediumImpact();
          break;
        case AuthButtonState.error:
          HapticFeedback.heavyImpact();
          break;
        case AuthButtonState.idle:
          break;
      }
    }

    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  Color _getButtonColor(AuthButtonState state) {
    switch (state) {
      case AuthButtonState.idle:
        return widget.backgroundColor ?? AppColors.tealColor;
      case AuthButtonState.loading:
        return widget.backgroundColor ?? AppColors.tealColor;
      case AuthButtonState.success:
        return Colors.green;
      case AuthButtonState.error:
        return Colors.red;
    }
  }

  LoaderState _getLoaderState() {
    switch (widget.state) {
      case AuthButtonState.loading:
        return LoaderState.loading;
      case AuthButtonState.success:
        return LoaderState.success;
      case AuthButtonState.error:
        return LoaderState.error;
      case AuthButtonState.idle:
        return LoaderState.loading;
    }
  }

  String _getDisplayText() {
    switch (widget.state) {
      case AuthButtonState.idle:
        return widget.text;
      case AuthButtonState.loading:
        return widget.loadingText ?? widget.text;
      case AuthButtonState.success:
        return widget.successText ?? 'Success!';
      case AuthButtonState.error:
        return widget.errorText ?? 'Try Again';
    }
  }

  bool _shouldShowLoader() {
    return widget.state == AuthButtonState.loading ||
        widget.state == AuthButtonState.success ||
        widget.state == AuthButtonState.error;
  }

  bool _shouldShowText() {
    return widget.state == AuthButtonState.idle ||
        (widget.state == AuthButtonState.success &&
            _previousState == AuthButtonState.loading) ||
        widget.state == AuthButtonState.error;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: widget.height,
            child: ElevatedButton(
              onPressed: widget.state == AuthButtonState.idle
                  ? widget.onPressed
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _colorAnimation.value ?? _getButtonColor(widget.state),
                foregroundColor: widget.textColor ?? Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                padding: widget.padding ?? EdgeInsets.zero,
                disabledBackgroundColor:
                    _getButtonColor(widget.state).withOpacity(0.8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background overlay for enhanced visual effects
                  if (widget.state == AuthButtonState.success)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                  // Loader
                  if (_shouldShowLoader())
                    EnhancedStrokeLoader.small(
                      state: _getLoaderState(),
                      color: widget.loaderColor ?? Colors.white,
                      onComplete: () {
                        // Auto-reset to idle after success animation
                        if (widget.state == AuthButtonState.success) {
                          Future.delayed(const Duration(milliseconds: 1000),
                              () {
                            if (mounted) {
                              // This would typically be handled by parent widget
                              // For now, we just maintain the success state
                            }
                          });
                        }
                      },
                    ),

                  // Text
                  if (_shouldShowText())
                    AnimatedOpacity(
                      opacity: _shouldShowLoader() ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _getDisplayText(),
                        style: widget.textStyle ??
                            getButtonStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.textColor ?? Colors.white,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
