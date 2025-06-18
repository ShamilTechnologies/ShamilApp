import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import '../../models/configuration_step.dart';

/// Ultra-premium progress indicator with advanced animations and fintech-grade UI
class BookingProgressIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<ConfigurationStep> steps;
  final Animation<double> progressAnimation;

  const BookingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    required this.progressAnimation,
  });

  @override
  State<BookingProgressIndicator> createState() =>
      _BookingProgressIndicatorState();
}

class _BookingProgressIndicatorState extends State<BookingProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProgressBar(),
        const Gap(24),
        _buildStepIndicators(),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Base progress
            AnimatedBuilder(
              animation: widget.progressAnimation,
              builder: (context, child) {
                final progress = (widget.currentStep + 1) /
                    widget.totalSteps *
                    widget.progressAnimation.value;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.tealColor,
                        AppColors.successColor,
                      ],
                      stops: [0.0, progress.clamp(0.0, 0.5), 1.0],
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                );
              },
            ),
            // Animated glow overlay
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + 2 * _glowAnimation.value, 0.0),
                      end: Alignment(1.0 + 2 * _glowAnimation.value, 0.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: widget.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index == widget.currentStep;
          final isCompleted = index < widget.currentStep;
          final isUpcoming = index > widget.currentStep;

          return Expanded(
            child: _buildPremiumStepItem(
                step, index, isActive, isCompleted, isUpcoming),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPremiumStepItem(
    ConfigurationStep step,
    int index,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    return Column(
      children: [
        // Step number/icon with premium styling
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isActive ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.successColor,
                            AppColors.tealColor,
                          ],
                        )
                      : isActive
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor.withOpacity(0.8),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.successColor.withOpacity(0.5)
                        : isActive
                            ? AppColors.primaryColor.withOpacity(0.6)
                            : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: isActive || isCompleted
                      ? [
                          BoxShadow(
                            color: (isCompleted
                                    ? AppColors.successColor
                                    : AppColors.primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Shimmer effect for active step
                    if (isActive)
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment(
                                    -1.0 + 2 * _glowAnimation.value, 0.0),
                                end: Alignment(
                                    1.0 + 2 * _glowAnimation.value, 0.0),
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

                    // Step content
                    Center(
                      child: isCompleted
                          ? Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 24,
                            )
                          : isActive
                              ? Icon(
                                  step.icon,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const Gap(12),

        // Step title with premium typography
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCompleted || isActive
                ? Colors.white
                : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight:
                isCompleted || isActive ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: isActive ? 0.5 : 0,
          ),
        ),

        const Gap(6),

        // Step subtitle with elegant styling
        Text(
          step.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCompleted || isActive
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(
    ConfigurationStep step,
    int index,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect for active step
            if (isActive)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 60 * (1 + 0.3 * _rippleAnimation.value),
                    height: 60 * (1 + 0.3 * _rippleAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tealColor
                            .withOpacity(0.3 * (1 - _rippleAnimation.value)),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
            // Main step icon
            _buildStepIcon(step, isActive, isCompleted, isUpcoming),
          ],
        ),
        const Gap(12),
        _buildStepTitle(step, isActive, isCompleted, isUpcoming),
        const Gap(4),
        _buildStepSubtitle(step, isActive, isCompleted, isUpcoming),
      ],
    );
  }

  Widget _buildStepIcon(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    Widget iconChild;

    if (isCompleted) {
      iconChild = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.successColor,
              AppColors.tealColor,
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.successColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.checkmark,
          size: 20,
          color: Colors.white,
          weight: 700,
        ),
      );
    } else if (isActive) {
      iconChild = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.tealColor,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: AppColors.tealColor.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                step.icon,
                size: 20,
                color: Colors.white,
                weight: 600,
              ),
            ),
          );
        },
      );
    } else {
      iconChild = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.04),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          step.icon,
          size: 18,
          color: Colors.white.withOpacity(0.4),
          weight: 500,
        ),
      );
    }

    return iconChild;
  }

  Widget _buildStepTitle(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    Color textColor;
    FontWeight fontWeight;

    if (isCompleted) {
      textColor = AppColors.successColor;
      fontWeight = FontWeight.w700;
    } else if (isActive) {
      textColor = Colors.white;
      fontWeight = FontWeight.w800;
    } else {
      textColor = Colors.white.withOpacity(0.5);
      fontWeight = FontWeight.w600;
    }

    return Text(
      step.title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: textColor,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStepSubtitle(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    Color textColor;

    if (isCompleted) {
      textColor = AppColors.successColor.withOpacity(0.7);
    } else if (isActive) {
      textColor = Colors.white.withOpacity(0.7);
    } else {
      textColor = Colors.white.withOpacity(0.3);
    }

    return Text(
      step.subtitle,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.2,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
 