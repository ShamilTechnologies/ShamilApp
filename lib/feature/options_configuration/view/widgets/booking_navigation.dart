import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Ultra-premium bottom navigation with magnetic interactions and fintech-grade UI
class BookingNavigation extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final bool canProceed;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;

  const BookingNavigation({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    this.onPrevious,
    this.onNext,
    this.onComplete,
  });

  @override
  State<BookingNavigation> createState() => _BookingNavigationState();
}

class _BookingNavigationState extends State<BookingNavigation>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _magnetController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _magnetAnimation;

  bool _isBackPressed = false;
  bool _isContinuePressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _magnetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _magnetAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _magnetController,
      curve: Curves.easeOutCubic,
    ));

    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _magnetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = widget.currentStep == 0;
    final isLastStep = widget.currentStep == widget.totalSteps - 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0A0E1A).withOpacity(0.8),
            const Color(0xFF0A0E1A).withOpacity(0.95),
            const Color(0xFF0A0E1A),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 50,
            offset: const Offset(0, -20),
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            // Subtle shimmer overlay
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          Alignment(-1.0 + 2 * _shimmerAnimation.value, -1.0),
                      end: Alignment(1.0 + 2 * _shimmerAnimation.value, 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            // Main content
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    if (!isFirstStep) ...[
                      _buildBackButton(),
                      const Gap(16),
                    ],
                    Expanded(
                      child: _buildContinueButton(
                        text: isLastStep ? 'Complete Booking' : 'Continue',
                        icon: isLastStep
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.arrow_right,
                        isEnabled: widget.canProceed,
                        onPressed: widget.canProceed
                            ? (isLastStep ? widget.onComplete : widget.onNext)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isBackPressed = true);
        _magnetController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isBackPressed = false);
        _magnetController.reverse();
      },
      onTapCancel: () {
        setState(() => _isBackPressed = false);
        _magnetController.reverse();
      },
      onTap: widget.onPrevious,
      child: AnimatedBuilder(
        animation: _magnetAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isBackPressed ? _magnetAnimation.value : 1.0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(_isBackPressed ? 0.3 : 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(_isBackPressed ? 0.3 : 0.15),
                    blurRadius: _isBackPressed ? 15 : 8,
                    offset: Offset(0, _isBackPressed ? 8 : 4),
                  ),
                  if (_isBackPressed)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white
                              .withOpacity(_isBackPressed ? 0.15 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.white.withOpacity(_isBackPressed ? 0.9 : 0.8),
                    size: 22,
                    weight: 600,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton({
    required String text,
    required IconData icon,
    required bool isEnabled,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              setState(() => _isContinuePressed = true);
              _magnetController.forward();
              HapticFeedback.mediumImpact();
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isContinuePressed = false);
              _magnetController.reverse();
            }
          : null,
      onTapCancel: isEnabled
          ? () {
              setState(() => _isContinuePressed = false);
              _magnetController.reverse();
            }
          : null,
      onTap: isEnabled ? onPressed : null,
      child: AnimatedBuilder(
        animation:
            isEnabled ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Transform.scale(
            scale: _isContinuePressed
                ? _magnetAnimation.value
                : (isEnabled ? _pulseAnimation.value : 1.0),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.tealColor,
                          AppColors.successColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEnabled
                      ? Colors.white
                          .withOpacity(_isContinuePressed ? 0.4 : 0.25)
                      : Colors.white.withOpacity(0.1),
                  width: isEnabled ? 2 : 1,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withOpacity(_isContinuePressed ? 0.6 : 0.4),
                          blurRadius: _isContinuePressed ? 25 : 15,
                          offset: Offset(0, _isContinuePressed ? 12 : 8),
                          spreadRadius: _isContinuePressed ? 2 : 0,
                        ),
                        BoxShadow(
                          color: AppColors.tealColor
                              .withOpacity(_isContinuePressed ? 0.4 : 0.2),
                          blurRadius: _isContinuePressed ? 40 : 25,
                          offset: Offset(0, _isContinuePressed ? 18 : 12),
                          spreadRadius: _isContinuePressed ? 8 : 4,
                        ),
                        if (_isContinuePressed)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect for enabled button
                  if (isEnabled)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(
                                    -1.0 + 2 * _shimmerAnimation.value, -1.0),
                                end: Alignment(
                                    1.0 + 2 * _shimmerAnimation.value, 1.0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Button content
                  Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isEnabled
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          size: 24,
                          weight: 600,
                        ),
                        const Gap(12),
                        Text(
                          text,
                          style: TextStyle(
                            color: isEnabled
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
