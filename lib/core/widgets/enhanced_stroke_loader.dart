import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

/// Loading states for the enhanced stroke loader
enum LoaderState {
  loading,
  success,
  error,
}

/// Haptic feedback patterns for premium feel
class PremiumHaptics {
  /// Light tap for subtle interactions
  static void lightTap() {
    HapticFeedback.selectionClick();
  }

  /// Gentle pulse for loading states
  static void gentlePulse() {
    HapticFeedback.lightImpact();
  }

  /// Success burst - double tap pattern
  static void successBurst() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }

  /// Error buzz - sharp feedback pattern
  static void errorBuzz() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }

  /// Progress pulse - rhythmic loading feedback
  static void progressPulse() {
    HapticFeedback.selectionClick();
  }

  /// Completion celebration - layered success pattern
  static void celebrationBurst() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.selectionClick();
  }

  /// Start loading - gentle engagement
  static void startLoading() {
    HapticFeedback.lightImpact();
  }

  /// Overlay appear - subtle entrance
  static void overlayAppear() {
    HapticFeedback.selectionClick();
  }

  /// Overlay dismiss - gentle exit
  static void overlayDismiss() {
    HapticFeedback.selectionClick();
  }
}

/// Enhanced stroke loader with integrated overlay system
class EnhancedStrokeLoader extends StatefulWidget {
  final double size;
  final LoaderState state;
  final Color? color;
  final Duration? duration;
  final VoidCallback? onComplete;
  final bool enableHaptics;

  const EnhancedStrokeLoader({
    super.key,
    this.size = 80.0,
    this.state = LoaderState.loading,
    this.color,
    this.duration,
    this.onComplete,
    this.enableHaptics = true,
  });

  /// Creates a small loader for buttons and inline usage
  const EnhancedStrokeLoader.small({
    super.key,
    this.size = 24.0,
    this.state = LoaderState.loading,
    this.color,
    this.duration,
    this.onComplete,
    this.enableHaptics = true,
  });

  /// Creates an overlay-sized loader for full-screen overlays
  const EnhancedStrokeLoader.overlay({
    super.key,
    this.size = 100.0,
    this.state = LoaderState.loading,
    this.color,
    this.duration,
    this.onComplete,
    this.enableHaptics = true,
  });

  @override
  State<EnhancedStrokeLoader> createState() => _EnhancedStrokeLoaderState();
}

class _EnhancedStrokeLoaderState extends State<EnhancedStrokeLoader>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _beamController;
  late AnimationController _errorController;
  late AnimationController _pulseController;

  late Animation<double> _fillAnimation;
  late Animation<double> _beamAnimation;
  late Animation<double> _errorShakeAnimation;
  late Animation<double> _pulseAnimation;

  LoaderState _currentState = LoaderState.loading;
  bool _hasTriggeredStateHaptic = false;
  bool _hasTriggeredProgressHaptics = false;
  double _lastProgressCheckpoint = 0.0;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _initializeAnimations();
    _startAnimation();

    // Initial haptic for loading start
    if (widget.enableHaptics && _currentState == LoaderState.loading) {
      PremiumHaptics.startLoading();
    }
  }

  @override
  void didUpdateWidget(EnhancedStrokeLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateChange(widget.state);
    }
  }

  void _initializeAnimations() {
    _fillController = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1500),
      vsync: this,
    );

    _beamController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOutCubic,
    ));

    _beamAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _beamController,
      curve: Curves.elasticOut,
    ));

    _errorShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fillController.addStatusListener(_onFillAnimationStatus);
    _beamController.addStatusListener(_onBeamAnimationStatus);
    _fillController.addListener(_onFillProgressChanged);
    _pulseController.addStatusListener(_onPulseAnimationStatus);
  }

  void _startAnimation() {
    switch (_currentState) {
      case LoaderState.loading:
        _fillController.repeat();
        _pulseController.repeat(reverse: true);
        break;
      case LoaderState.success:
        _pulseController.stop();
        _fillController.forward();
        break;
      case LoaderState.error:
        _pulseController.stop();
        _triggerErrorAnimation();
        break;
    }
  }

  void _handleStateChange(LoaderState newState) {
    setState(() {
      _currentState = newState;
      _hasTriggeredStateHaptic = false;
      _hasTriggeredProgressHaptics = false;
      _lastProgressCheckpoint = 0.0;
    });

    switch (newState) {
      case LoaderState.loading:
        _fillController.reset();
        _beamController.reset();
        _errorController.reset();
        _pulseController.reset();
        _fillController.repeat();
        _pulseController.repeat(reverse: true);
        if (widget.enableHaptics) {
          PremiumHaptics.startLoading();
        }
        break;
      case LoaderState.success:
        _fillController.stop();
        _pulseController.stop();
        _fillController.forward();
        if (widget.enableHaptics) {
          PremiumHaptics.successBurst();
        }
        break;
      case LoaderState.error:
        _fillController.stop();
        _beamController.stop();
        _pulseController.stop();
        _triggerErrorAnimation();
        if (widget.enableHaptics) {
          PremiumHaptics.errorBuzz();
        }
        break;
    }
  }

  void _triggerErrorAnimation() {
    _errorController.reset();
    _errorController.forward();
  }

  void _onFillProgressChanged() {
    if (!widget.enableHaptics || _currentState != LoaderState.loading) return;

    final progress = _fillAnimation.value;

    // Progressive haptic feedback at 25%, 50%, 75%
    if (!_hasTriggeredProgressHaptics) {
      if (progress >= 0.25 && _lastProgressCheckpoint < 0.25) {
        _lastProgressCheckpoint = 0.25;
        PremiumHaptics.progressPulse();
      } else if (progress >= 0.50 && _lastProgressCheckpoint < 0.50) {
        _lastProgressCheckpoint = 0.50;
        PremiumHaptics.progressPulse();
      } else if (progress >= 0.75 && _lastProgressCheckpoint < 0.75) {
        _lastProgressCheckpoint = 0.75;
        PremiumHaptics.progressPulse();
      }
    }
  }

  void _onFillAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _currentState == LoaderState.success) {
      _beamController.forward();
      if (widget.enableHaptics) {
        PremiumHaptics.gentlePulse();
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (widget.enableHaptics) {
          PremiumHaptics.celebrationBurst();
        }
        widget.onComplete?.call();
      });
    }
  }

  void _onBeamAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _currentState == LoaderState.error) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onComplete?.call();
      });
    }
  }

  void _onPulseAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _currentState == LoaderState.loading &&
        widget.enableHaptics) {
      // Gentle pulse every cycle during loading
      if (_pulseController.status == AnimationStatus.dismissed) {
        PremiumHaptics.gentlePulse();
      }
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _beamController.dispose();
    _errorController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getEffectiveColor() {
    switch (_currentState) {
      case LoaderState.loading:
        return widget.color ?? AppColors.tealColor;
      case LoaderState.success:
        return widget.color ?? AppColors.tealColor;
      case LoaderState.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _getEffectiveColor();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _fillController,
          _beamController,
          _errorController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _currentState == LoaderState.loading
                ? _pulseAnimation.value
                : 1.0,
            child: Transform.translate(
              offset: _currentState == LoaderState.error
                  ? Offset(
                      sin(_errorShakeAnimation.value * pi * 8) * 3,
                      0,
                    )
                  : Offset.zero,
              child: EnhancedStrokeToFillLogo(
                logoPath: AssetsIcons.logoSvg,
                brandColor: effectiveColor,
                fillProgress: _fillAnimation.value,
                beamProgress: _beamAnimation.value,
                size: widget.size,
                state: _currentState,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced stroke-to-fill logo widget
class EnhancedStrokeToFillLogo extends StatelessWidget {
  final String logoPath;
  final Color brandColor;
  final double fillProgress;
  final double beamProgress;
  final double size;
  final LoaderState state;

  const EnhancedStrokeToFillLogo({
    super.key,
    required this.logoPath,
    required this.brandColor,
    required this.fillProgress,
    required this.beamProgress,
    required this.size,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Base stroke layer
            SvgPicture.asset(
              logoPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                brandColor.withOpacity(state == LoaderState.error ? 0.5 : 0.3),
                BlendMode.srcIn,
              ),
            ),

            // Fill layer
            if (fillProgress > 0)
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      brandColor,
                      brandColor,
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      fillProgress.clamp(0.0, 1.0),
                      fillProgress.clamp(0.0, 1.0),
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

            // Success scale effect
            if (state == LoaderState.success && beamProgress > 0)
              Transform.scale(
                scale: beamProgress,
                child: Opacity(
                  opacity: beamProgress * 0.6,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          brandColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Error overlay
            if (state == LoaderState.error)
              Opacity(
                opacity: 0.7,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen transparent overlay system
class LoadingOverlay {
  static OverlayEntry? _currentOverlay;

  /// Shows loading overlay with haptic feedback
  static void showLoading(
    BuildContext context, {
    String? message,
    bool enableHaptics = true,
  }) {
    if (enableHaptics) {
      PremiumHaptics.overlayAppear();
    }
    _show(
      context,
      state: LoaderState.loading,
      message: message ?? 'Loading...',
      enableHaptics: enableHaptics,
    );
  }

  /// Shows success overlay with auto-dismiss and haptic feedback
  static void showSuccess(
    BuildContext context, {
    String? message,
    VoidCallback? onComplete,
    Duration? autoDismissAfter,
    bool enableHaptics = true,
  }) {
    _show(
      context,
      state: LoaderState.success,
      message: message ?? 'Success!',
      onComplete: onComplete,
      autoDismissAfter: autoDismissAfter ?? const Duration(seconds: 2),
      enableHaptics: enableHaptics,
    );
  }

  /// Shows error overlay with auto-dismiss and haptic feedback
  static void showError(
    BuildContext context, {
    String? message,
    VoidCallback? onComplete,
    Duration? autoDismissAfter,
    bool enableHaptics = true,
  }) {
    _show(
      context,
      state: LoaderState.error,
      message: message ?? 'Something went wrong',
      onComplete: onComplete,
      autoDismissAfter: autoDismissAfter ?? const Duration(seconds: 3),
      enableHaptics: enableHaptics,
    );
  }

  /// Shows the overlay with specified parameters
  static void _show(
    BuildContext context, {
    required LoaderState state,
    required String message,
    VoidCallback? onComplete,
    Duration? autoDismissAfter,
    bool enableHaptics = true,
  }) {
    hide(); // Remove any existing overlay

    _currentOverlay = OverlayEntry(
      builder: (context) => _FullScreenOverlay(
        state: state,
        message: message,
        onComplete: onComplete,
        autoDismissAfter: autoDismissAfter,
        enableHaptics: enableHaptics,
      ),
    );

    Overlay.of(context)?.insert(_currentOverlay!);
  }

  /// Hides the current overlay with haptic feedback
  static void hide({bool enableHaptics = true}) {
    if (enableHaptics) {
      PremiumHaptics.overlayDismiss();
    }
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Checks if overlay is currently showing
  static bool get isShowing => _currentOverlay != null;
}

/// Full-screen transparent overlay widget
class _FullScreenOverlay extends StatefulWidget {
  final LoaderState state;
  final String message;
  final VoidCallback? onComplete;
  final Duration? autoDismissAfter;
  final bool enableHaptics;

  const _FullScreenOverlay({
    required this.state,
    required this.message,
    this.onComplete,
    this.autoDismissAfter,
    this.enableHaptics = true,
  });

  @override
  State<_FullScreenOverlay> createState() => _FullScreenOverlayState();
}

class _FullScreenOverlayState extends State<_FullScreenOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
    _setupAutoDismiss();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
  }

  void _setupAutoDismiss() {
    if (widget.autoDismissAfter != null) {
      Future.delayed(widget.autoDismissAfter!, () {
        if (mounted) {
          _dismissOverlay();
        }
      });
    }
  }

  void _dismissOverlay() {
    _scaleController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            widget.onComplete?.call();
            LoadingOverlay.hide(enableHaptics: widget.enableHaptics);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.4 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enhanced stroke loader with haptics
                      EnhancedStrokeLoader(
                        size: 80,
                        state: widget.state,
                        enableHaptics: widget.enableHaptics,
                        onComplete: () {
                          if (widget.state != LoaderState.loading) {
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              if (mounted) {
                                _dismissOverlay();
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Message text
                      Text(
                        widget.message,
                        style: getbodyStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
