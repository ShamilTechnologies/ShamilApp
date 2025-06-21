import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import 'package:shamil_mobile_app/feature/auth/views/page/forgotPassword_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/modern_register_view.dart';

class CreativeSignInView extends StatefulWidget {
  const CreativeSignInView({super.key});

  @override
  State<CreativeSignInView> createState() => _CreativeSignInViewState();
}

class _CreativeSignInViewState extends State<CreativeSignInView>
    with TickerProviderStateMixin {
  // Form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Animation controller
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form state
  bool _obscurePassword = true;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  String? _emailErrorText;
  String? _passwordErrorText;

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
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
              color: AppColors.splashBackground, // Pure dark background
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
                          _buildSignInForm(isLoading),
                          const SizedBox(height: 32),
                          _buildBottomNavigation(isLoading),
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
          // Hero logo - bigger and clean, left-aligned
          Align(
            alignment: Alignment.centerLeft,
            child: Hero(
              tag: 'app_logo',
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

          // Welcome message - left aligned under logo
          Text(
            'Welcome back',
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
            'Continue your premium experience',
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

  Widget _buildSignInForm(bool isLoading) {
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
                  'Sign in to your account',
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
              hintText: 'Enter your email',
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
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),

            const SizedBox(height: 20),

            // Password field
            _buildModernTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              hintText: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              hasError: _hasPasswordError,
              errorText: _passwordErrorText,
              isLoading: isLoading,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              onChanged: (value) {
                if (_hasPasswordError) {
                  setState(() {
                    _hasPasswordError = false;
                    _passwordErrorText = null;
                  });
                }
              },
              onSubmitted: (_) => _handleLogin(),
            ),

            const SizedBox(height: 16),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : _navigateToForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: getSmallStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.tealColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Sign in button
            _buildSignInButton(isLoading),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
            obscureText: obscureText,
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
              suffixIcon: suffixIcon,
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

  Widget _buildSignInButton(bool isLoading) {
    return EnhancedAuthButton(
      text: 'Sign In',
      state: AuthButtonState.idle,
      onPressed: isLoading ? null : _handleLogin,
      loadingText: 'Signing in...',
      successText: 'Welcome!',
      errorText: 'Try again',
      enableHapticFeedback: true,
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

          // Create account button
          TextButton(
            onPressed: isLoading ? null : _navigateToRegister,
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
                text: "Don't have an account? ",
                children: [
                  TextSpan(
                    text: 'Create account',
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

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    setState(() {
      _hasEmailError = false;
      _hasPasswordError = false;
      _emailErrorText = null;
      _passwordErrorText = null;
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

    if (_passwordController.text.isEmpty) {
      setState(() {
        _hasPasswordError = true;
        _passwordErrorText = "Password is required";
      });
      isValid = false;
    }

    if (!isValid) return;

    HapticFeedback.lightImpact();

    context.read<AuthBloc>().add(
          LoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthLoadingState) {
      // Show loading overlay
      LoadingOverlay.showLoading(
        context,
        message: state.message ?? 'Signing in...',
      );
    } else if (state is LoginSuccessState) {
      // Show success overlay with auto-dismiss - user has completed profile
      LoadingOverlay.showSuccess(
        context,
        message: 'Welcome back!',
        autoDismissAfter: const Duration(seconds: 2),
        onComplete: () {
          String? firstName;
          if (state.user.name.isNotEmpty) {
            firstName = state.user.name
                .split(' ')
                .firstWhere((s) => s.isNotEmpty, orElse: () => '');
          }

          String? profileUrl = state.user.profilePicUrl ?? state.user.image;
          if (profileUrl?.isEmpty ?? true) {
            profileUrl = null;
          }

          pushReplacement(
            context,
            LoginSuccessAnimationView(
              profilePicUrl: profileUrl,
              firstName: firstName,
            ),
          );

          // Show email verification reminder if email is not verified
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && !currentUser.emailVerified) {
            Future.delayed(const Duration(seconds: 1), () {
              showGlobalSnackBar(
                context,
                "📧 Reminder: Please verify your email (${currentUser.email}) for full account access.",
                isError: false,
              );
            });
          }
        },
      );
    } else if (state is IncompleteProfileState) {
      // User needs to complete profile setup - go to OneMoreStep
      LoadingOverlay.showSuccess(
        context,
        message: state.isEmailVerified
            ? 'Welcome! Please complete your profile setup.'
            : 'Welcome! Complete your profile and don\'t forget to verify your email.',
        autoDismissAfter: const Duration(seconds: 2),
        onComplete: () {
          pushReplacement(context, const OneMoreStepScreen());
          if (!state.isEmailVerified) {
            showGlobalSnackBar(
              context,
              "📧 Reminder: Please check your email to verify your account for full access.",
              isError: false,
            );
          }
        },
      );
    } else if (state is AwaitingVerificationState) {
      // User has completed profile but email not verified - show reminder and continue
      LoadingOverlay.showSuccess(
        context,
        message: 'Welcome back!',
        autoDismissAfter: const Duration(seconds: 2),
        onComplete: () {
          String? firstName;
          if (state.user?.name.isNotEmpty ?? false) {
            firstName = state.user!.name
                .split(' ')
                .firstWhere((s) => s.isNotEmpty, orElse: () => '');
          }

          String? profileUrl = state.user?.profilePicUrl ?? state.user?.image;
          if (profileUrl?.isEmpty ?? true) {
            profileUrl = null;
          }

          // Go to main app but show email verification reminder
          pushReplacement(
            context,
            LoginSuccessAnimationView(
              profilePicUrl: profileUrl,
              firstName: firstName,
            ),
          );

          // Show email verification reminder
          Future.delayed(const Duration(seconds: 1), () {
            showGlobalSnackBar(
              context,
              "📧 Reminder: Please verify your email (${state.email}) for full account access.",
              isError: false,
            );
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
          if (state.message.toLowerCase().contains("password")) {
            setState(() {
              _hasPasswordError = true;
              _passwordErrorText = "Incorrect password";
            });
          }
        },
      );
    }
  }

  void _navigateToForgotPassword() {
    context.toForgotPassword(const ForgotPasswordView());
  }

  void _navigateToRegister() {
    context.toRegister(const ModernRegisterView());
  }
}
