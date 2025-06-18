import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Premium payment result bottom sheet with auto-dismiss and navigation
class PaymentSuccessDialog {
  static void show({
    required BuildContext context,
    bool isSuccess = true,
    String? title,
    String? message,
    required VoidCallback onClose,
    Duration autoDismissDelay = const Duration(seconds: 3),
  }) {
    HapticFeedback.heavyImpact();

    // Store the navigator context before showing the bottom sheet
    final navigatorContext = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _PremiumConfirmationBottomSheet(
        isSuccess: isSuccess,
        title: title,
        message: message,
        onClose: () {
          // First dismiss the bottom sheet
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Small delay to ensure bottom sheet is closed
          Future.delayed(const Duration(milliseconds: 150), () {
            onClose();
          });
        },
        autoDismissDelay: autoDismissDelay,
      ),
    );
  }
}

class _PremiumConfirmationBottomSheet extends StatefulWidget {
  final bool isSuccess;
  final String? title;
  final String? message;
  final VoidCallback onClose;
  final Duration autoDismissDelay;

  const _PremiumConfirmationBottomSheet({
    required this.isSuccess,
    this.title,
    this.message,
    required this.onClose,
    required this.autoDismissDelay,
  });

  @override
  State<_PremiumConfirmationBottomSheet> createState() =>
      _PremiumConfirmationBottomSheetState();
}

class _PremiumConfirmationBottomSheetState
    extends State<_PremiumConfirmationBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _iconController;
  late AnimationController _progressController;

  late Animation<double> _slideAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scheduleAutoDismiss();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.autoDismissDelay,
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    );

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _iconController.forward();
    });
  }

  void _scheduleAutoDismiss() {
    _progressController.forward();

    Future.delayed(widget.autoDismissDelay, () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() async {
    if (mounted) {
      // Start the slide animation
      await _slideController.reverse();

      // Call the onClose callback which handles both dismissal and navigation
      widget.onClose();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _iconController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 300),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E1A),
                  widget.isSuccess
                      ? AppColors.successColor.withOpacity(0.15)
                      : AppColors.orangeColor.withOpacity(0.15),
                  widget.isSuccess
                      ? AppColors.tealColor.withOpacity(0.1)
                      : AppColors.orangeColor.withOpacity(0.1),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  offset: const Offset(0, -20),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                _buildContent(),
                _buildProgressBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const Gap(24),
          _buildTitle(),
          const Gap(16),
          _buildMessage(),
          const Gap(32),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _iconAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconAnimation.value,
          child: Transform.rotate(
            angle: _iconAnimation.value * 0.1,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isSuccess
                      ? [AppColors.successColor, AppColors.tealColor]
                      : [
                          AppColors.orangeColor,
                          AppColors.orangeColor.withOpacity(0.7)
                        ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess
                            ? AppColors.successColor
                            : AppColors.orangeColor)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.isSuccess
                    ? CupertinoIcons.checkmark_alt
                    : CupertinoIcons.xmark,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.title ?? (widget.isSuccess ? 'Success!' : 'Error'),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Text(
      widget.message ??
          (widget.isSuccess
              ? 'Your action was completed successfully!'
              : 'Something went wrong. Please try again.'),
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _dismissWithAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progressAnimation.value,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isSuccess ? AppColors.successColor : AppColors.orangeColor,
            ),
          );
        },
      ),
    );
  }
}
