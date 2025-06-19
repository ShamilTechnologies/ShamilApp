import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Core imports
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

import 'package:shamil_mobile_app/core/widgets/enhanced_stroke_loader.dart';
import 'package:shamil_mobile_app/feature/auth/widgets/enhanced_auth_button.dart';

// Auth imports
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView>
    with TickerProviderStateMixin {
  // Form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form state
  bool _hasEmailError = false;
  String? _emailErrorText;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
  }

  void _initializeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            backgroundColor: AppColors.splashBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.splashBackground,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 48),
                          if (!_emailSent) ...[
                            _buildResetForm(isLoading),
                            const SizedBox(height: 32),
                            _buildBottomNavigation(isLoading),
                          ] else ...[
                            _buildSuccessMessage(),
                            const SizedBox(height: 32),
                            _buildReturnToLogin(isLoading),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero logo - matching sign-in design
          Align(
            alignment: Alignment.centerLeft,
            child: Hero(
              tag: 'app_logo_forgot',
              child: SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset(
                  AssetsIcons.logoSvg,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    AppColors.tealColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Main heading
          Text(
            _emailSent ? 'Check your email' : 'Reset password',
            style: getHeadlineTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ).copyWith(
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            _emailSent
                ? 'We\'ve sent reset instructions to your email'
                : 'Enter your email to receive reset instructions',
            style: getbodyStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form section with creative accent
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tealColor,
                        AppColors.tealColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Reset your password',
                  style: getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Email field
            _buildModernTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email',
              hintText: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hasError: _hasEmailError,
              errorText: _emailErrorText,
              isLoading: isLoading,
              onChanged: (value) {
                if (_hasEmailError) {
                  setState(() {
                    _hasEmailError = false;
                    _emailErrorText = null;
                  });
                }
              },
              onSubmitted: (_) => _handleSendReset(),
            ),

            const SizedBox(height: 32),

            // Send reset button
            _buildSendResetButton(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required String? errorText,
    required bool isLoading,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Text(
          label,
          style: getbodyStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),

        const SizedBox(height: 8),

        // Text field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            enabled: !isLoading,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: getbodyStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: getbodyStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Error message
        if (hasError && errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: getSmallStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.red.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSendResetButton(bool isLoading) {
    return EnhancedAuthButton(
      text: 'Send Reset Link',
      state: AuthButtonState.idle,
      onPressed: isLoading ? null : _handleSendReset,
      loadingText: 'Sending...',
      successText: 'Link sent!',
      errorText: 'Try again',
      enableHapticFeedback: true,
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
          color: Colors.green.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: Colors.green.withOpacity(0.8),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Reset link sent successfully!',
              style: getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your email (${_emailController.text.trim()}) and follow the instructions to reset your password.',
              style: getbodyStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Divider with text
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: getSmallStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Back to login button
          TextButton(
            onPressed: isLoading ? null : _navigateToLogin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: RichText(
              text: TextSpan(
                style: getbodyStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                ),
                text: "Remember your password? ",
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: getbodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnToLogin(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          EnhancedAuthButton(
            text: 'Return to Sign In',
            state: AuthButtonState.idle,
            onPressed: isLoading ? null : _navigateToLogin,
            loadingText: 'Loading...',
            successText: 'Returning...',
            errorText: 'Try again',
            enableHapticFeedback: true,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : _handleResendEmail,
            child: Text(
              'Didn\'t receive the email? Resend',
              style: getSmallStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.tealColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendReset() {
    FocusScope.of(context).unfocus();

    setState(() {
      _hasEmailError = false;
      _emailErrorText = null;
    });

    bool isValid = true;

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _hasEmailError = true;
        _emailErrorText = "Email is required";
      });
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _hasEmailError = true;
        _emailErrorText = "Please enter a valid email";
      });
      isValid = false;
    }

    if (!isValid) return;

    HapticFeedback.lightImpact();

    context.read<AuthBloc>().add(
          SendPasswordResetEmail(email: _emailController.text.trim()),
        );
  }

  void _handleResendEmail() {
    HapticFeedback.lightImpact();

    context.read<AuthBloc>().add(
          SendPasswordResetEmail(email: _emailController.text.trim()),
        );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthLoadingState) {
      // Show loading overlay
      LoadingOverlay.showLoading(
        context,
        message: state.message ?? 'Sending reset link...',
      );
    } else if (state is PasswordResetEmailSentState) {
      // Show success overlay with auto-dismiss
      LoadingOverlay.showSuccess(
        context,
        message: 'Reset link sent successfully!',
        autoDismissAfter: const Duration(seconds: 2),
        onComplete: () {
          setState(() {
            _emailSent = true;
          });
        },
      );
    } else if (state is AuthErrorState) {
      // Show error overlay with auto-dismiss
      LoadingOverlay.showError(
        context,
        message: state.message,
        autoDismissAfter: const Duration(seconds: 3),
        onComplete: () {
          // Update form field errors
          if (state.message.toLowerCase().contains("email") ||
              state.message.toLowerCase().contains("user")) {
            setState(() {
              _hasEmailError = true;
              _emailErrorText = "Email not recognized";
            });
          }
        },
      );
    }
  }

  void _navigateToLogin() {
    context.toSignIn(const LoginView());
  }
}
