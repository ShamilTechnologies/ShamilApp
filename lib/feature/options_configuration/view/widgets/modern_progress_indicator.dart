import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;

/// Configuration Step Model
class ConfigurationStep {
  final IconData icon;
  final String title;
  final String description;

  const ConfigurationStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Modern Progress Indicator with Step Animation
class ModernProgressIndicator extends StatefulWidget {
  final List<ConfigurationStep> steps;
  final int currentStep;
  final double progress;

  const ModernProgressIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.progress,
  });

  @override
  State<ModernProgressIndicator> createState() =>
      _ModernProgressIndicatorState();
}

class _ModernProgressIndicatorState extends State<ModernProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ModernProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProgressHeader(),
          const Gap(20),
          _buildProgressBar(),
          const Gap(24),
          _buildStepIndicators(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Progress',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            Text(
              widget.steps[widget.currentStep].description,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.chart_pie,
                color: Colors.white,
                size: 16,
              ),
              const Gap(6),
              Text(
                '${(widget.progress * 100).toInt()}%',
                style: AppTextStyle.getTitleStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${widget.currentStep + 1} of ${widget.steps.length}',
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              widget.steps[widget.currentStep].title,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Gap(12),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: widget.progress * _progressAnimation.value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.steps.length, (index) {
        return _buildStepIndicator(index);
      }),
    );
  }

  Widget _buildStepIndicator(int index) {
    final step = widget.steps[index];
    final isCompleted = index < widget.currentStep;
    final isCurrent = index == widget.currentStep;
    final isUpcoming = index > widget.currentStep;

    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation:
                isCurrent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: isCurrent ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStepColor(isCompleted, isCurrent),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStepBorderColor(isCompleted, isCurrent),
                      width: isCurrent ? 3 : 2,
                    ),
                    boxShadow: isCurrent || isCompleted
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: _buildStepIcon(
                        step, isCompleted, isCurrent, isUpcoming),
                  ),
                ),
              );
            },
          ),
          const Gap(12),
          Text(
            step.title,
            style: AppTextStyle.getSmallStyle(
              color: _getStepTextColor(isCompleted, isCurrent),
              fontWeight:
                  isCurrent || isCompleted ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(ConfigurationStep step, bool isCompleted,
      bool isCurrent, bool isUpcoming) {
    if (isCompleted) {
      return const Icon(
        CupertinoIcons.check_mark,
        color: Colors.white,
        size: 20,
      );
    }

    if (isCurrent) {
      return Icon(
        step.icon,
        color: Colors.white,
        size: 20,
      );
    }

    return Icon(
      step.icon,
      color: AppColors.secondaryText,
      size: 18,
    );
  }

  Color _getStepColor(bool isCompleted, bool isCurrent) {
    if (isCompleted || isCurrent) {
      return AppColors.primaryColor;
    }
    return Colors.white;
  }

  Color _getStepBorderColor(bool isCompleted, bool isCurrent) {
    if (isCompleted || isCurrent) {
      return AppColors.primaryColor;
    }
    return AppColors.primaryColor.withOpacity(0.3);
  }

  Color _getStepTextColor(bool isCompleted, bool isCurrent) {
    if (isCompleted || isCurrent) {
      return AppColors.primaryText;
    }
    return AppColors.secondaryText;
  }
}
