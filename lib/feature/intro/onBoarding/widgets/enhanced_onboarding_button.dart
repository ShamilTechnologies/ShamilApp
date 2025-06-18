import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

/// Enhanced button widget for onboarding navigation with premium animations
class EnhancedOnboardingButton extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Color primaryColor;
  final Color secondaryColor;

  const EnhancedOnboardingButton({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onPrevious,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<EnhancedOnboardingButton> createState() =>
      _EnhancedOnboardingButtonState();
}

class _EnhancedOnboardingButtonState extends State<EnhancedOnboardingButton>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late AnimationController _shimmerController;
  late Animation<double> _buttonAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start shimmer animation
    _shimmerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _isLastPage => widget.currentPage == widget.totalPages - 1;
  bool get _isFirstPage => widget.currentPage == 0;

  Future<void> _handleComplete() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Save onboarding completion flag
      await AppLocalStorage.cacheData(
        key: AppLocalStorage.isOnboardingShown,
        value: true,
      );

      // Navigate to login
      if (mounted) {
        pushReplacement(context, const LoginView());
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not proceed. Please try again.'),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Previous button (only show if not first page)
          if (!_isFirstPage) ...[
            _buildPreviousButton(),
            const SizedBox(width: 16),
          ],

          // Main action button
          Expanded(
            child: _isLastPage ? _buildCompleteButton() : _buildNextButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPrevious();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white.withOpacity(0.8),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _buttonController.forward(),
            onTapUp: (_) {
              _buttonController.reverse();
              HapticFeedback.mediumImpact();
              widget.onNext();
            },
            onTapCancel: () => _buttonController.reverse(),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withOpacity(0.8),
                    widget.secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: getButtonStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ).copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_buttonAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _buttonController.forward(),
            onTapUp: (_) {
              _buttonController.reverse();
              _handleComplete();
            },
            onTapCancel: () => _buttonController.reverse(),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor,
                    widget.primaryColor.withOpacity(0.9),
                    widget.secondaryColor,
                    widget.secondaryColor.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Transform.translate(
                        offset: Offset(
                          _shimmerAnimation.value * 200,
                          0,
                        ),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Button content
                  Center(
                    child: _isProcessing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Get Started',
                                style: getButtonStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ).copyWith(
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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

/// Alternative floating action button style
class FloatingOnboardingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isLoading;

  const FloatingOnboardingButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: FloatingActionButton.extended(
        onPressed: isLoading ? null : onPressed,
        backgroundColor: primaryColor,
        elevation: 8,
        highlightElevation: 12,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: getButtonStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
