import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import '../enhanced_booking_configuration_screen.dart';

/// Modern Progress Stepper Component
class ProgressStepper extends StatefulWidget {
  final List<ConfigurationStep> steps;
  final int currentStep;
  final OptionsConfigurationState state;

  const ProgressStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.state,
  });

  @override
  State<ProgressStepper> createState() => _ProgressStepperState();
}

class _ProgressStepperState extends State<ProgressStepper>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _bounceController;
  late Animation<double> _progressAnimation;
  late Animation<double> _bounceAnimation;

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
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(ProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Column(
            children: [
              _buildProgressLine(),
              const Gap(16),
              _buildStepIndicators(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressLine() {
    final progress = widget.currentStep / (widget.steps.length - 1);

    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          width: MediaQuery.of(context).size.width * progress,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.cyanColor,
                AppColors.tealColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return _buildStepIndicator(step, index);
      }).toList(),
    );
  }

  Widget _buildStepIndicator(ConfigurationStep step, int index) {
    final isActive = index == widget.currentStep;
    final isCompleted = index < widget.currentStep;
    final isUpcoming = index > widget.currentStep;
    final isValid = _isStepValid(index);

    return Expanded(
      child: AnimatedBuilder(
        animation: isActive ? _bounceAnimation : _progressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? (1.0 + _bounceAnimation.value * 0.1) : 1.0,
            child: Column(
              children: [
                _buildStepCircle(step, isActive, isCompleted, isUpcoming),
                const Gap(8),
                _buildStepLabel(step, isActive, isCompleted, isUpcoming),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepCircle(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getCircleGradient(step, isActive, isCompleted, isUpcoming),
        border: Border.all(
          color: _getCircleBorderColor(isActive, isCompleted, isUpcoming),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildStepIcon(step, isActive, isCompleted, isUpcoming),
        ),
      ),
    );
  }

  Widget _buildStepIcon(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    IconData iconData;
    Color iconColor;

    if (isCompleted) {
      iconData = CupertinoIcons.check_mark;
      iconColor = Colors.white;
    } else if (isActive) {
      iconData = step.icon;
      iconColor = Colors.white;
    } else {
      iconData = step.icon;
      iconColor = Colors.white.withValues(alpha: 0.6);
    }

    return Center(
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildStepLabel(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    return Text(
      step.title,
      style: app_text_style.getSmallStyle(
        color: isActive
            ? AppColors.lightText
            : AppColors.lightText.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Gradient _getCircleGradient(
    ConfigurationStep step,
    bool isActive,
    bool isCompleted,
    bool isUpcoming,
  ) {
    if (isCompleted) {
      return LinearGradient(
        colors: [AppColors.greenColor, AppColors.tealColor],
      );
    } else if (isActive) {
      return LinearGradient(
        colors: [step.color, step.color.withValues(alpha: 0.8)],
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ],
      );
    }
  }

  Color _getCircleBorderColor(
      bool isActive, bool isCompleted, bool isUpcoming) {
    if (isCompleted) {
      return AppColors.greenColor;
    } else if (isActive) {
      return AppColors.primaryColor;
    } else {
      return Colors.white.withValues(alpha: 0.2);
    }
  }

  bool _isStepValid(int stepIndex) {
    switch (stepIndex) {
      case 0: // Date & Time
        return widget.state.isDateTimeStepComplete;
      case 1: // Attendees
        return widget.state.isAttendeesStepComplete;
      case 2: // Preferences
        return true; // Always valid
      case 3: // Payment
        return widget.state.canProceedToPayment;
      default:
        return true;
    }
  }
}
