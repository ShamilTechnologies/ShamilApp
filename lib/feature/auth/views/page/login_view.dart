import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

// Core utilities
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';

// Auth related imports
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/forgotPassword_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/register_view.dart';

/// Animated text typing widget for enhanced UX
class SmoothTypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration letterDelay;

  const SmoothTypingText({
    super.key,
    required this.text,
    required this.style,
    this.letterDelay = const Duration(milliseconds: 100),
  });

  @override
  State<SmoothTypingText> createState() => _SmoothTypingTextState();
}

class _SmoothTypingTextState extends State<SmoothTypingText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(SmoothTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetTyping();
      _startTyping();
    }
  }

  void _resetTyping() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = "";
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.letterDelay, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      maxLines: 2,
    );
  }
}

/// Enhanced login view with explore screen design architecture
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation controllers
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Error state
  bool _hasEmailError = false;
  bool _hasPasswordError = false;
  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Slide animation for form elements
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    // Fade animation for header
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        FocusScope.of(context).unfocus();
        _handleAuthStateChanges(state);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, current) =>
            (prev is AuthLoadingState) != (current is AuthLoadingState),
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            extendBodyBehindAppBar: true,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.95),
                    AppColors.primaryColor.withOpacity(0.9),
                    const Color(0xFF0A0E1A),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  // Premium Hero Header - Same as explore screen
                  SliverAppBar(
                    expandedHeight: screenHeight * 0.45,
                    floating: false,
                    pinned: true,
                    stretch: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    flexibleSpace:
                        _buildPremiumFlexibleSpace(topPadding, screenWidth),
                  ),

                  // Premium Content - Same dark background as explore screen
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFF0A0E1A),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildSignInContent(context, isLoading),
                      ),
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

  Widget _buildPremiumFlexibleSpace(double topPadding, double screenWidth) {
    return FlexibleSpaceBar(
      stretchModes: const [
        StretchMode.zoomBackground,
        StretchMode.blurBackground,
        StretchMode.fadeTitle,
      ],
      background: Stack(
        children: [
          // Animated background - Same as explore screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.9),
                  AppColors.tealColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Floating orbs - Same as explore screen
          Positioned(
            top: topPadding + 40,
            right: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: topPadding + 100,
            left: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero sign in section
                            Flexible(child: _buildHeroSignInSection()),
                            const SizedBox(height: 16),

                            // Premium sign in indicator
                            _buildPremiumSignInIndicator(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSignInSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome back text with gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ).createShader(bounds),
            child: SmoothTypingText(
              text: "Welcome\nBack",
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const Gap(12),

          // Subtitle with glassmorphism
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              "Sign in to continue your premium experience",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSignInIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tealColor.withOpacity(0.3),
                  AppColors.accentColor.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.arrow_down,
              color: Colors.white,
              size: 12,
            ),
          ),
          const Gap(8),
          Text(
            "Sign In Below",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInContent(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Gap(24),

          // Direct form fields without container
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Email Field
                _buildModernTextField(
                  controller: _emailController,
                  hintText: "Enter your email",
                  icon: CupertinoIcons.mail,
                  hasError: _hasEmailError,
                  errorText: _emailErrorText,
                  isPassword: false,
                  isLoading: isLoading,
                  onChanged: (value) {
                    if (_hasEmailError) {
                      setState(() {
                        _hasEmailError = false;
                        _emailErrorText = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _focusPassword(),
                ),
                const Gap(20),

                // Modern Password Field
                _buildModernTextField(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  icon: CupertinoIcons.lock,
                  hasError: _hasPasswordError,
                  errorText: _passwordErrorText,
                  isPassword: true,
                  isLoading: isLoading,
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

                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _navigateToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 8),
                      foregroundColor: AppColors.tealColor,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: getbodyStyle(
                        color: AppColors.tealColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const Gap(24),

                // Modern Glassy Sign In Button
                _buildGlassyButton(
                  text: isLoading ? "Signing In..." : "Sign In",
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleLogin,
                ),
              ],
            ),
          ),
          const Gap(32),

          // Modern Register Navigation Link
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: isLoading ? null : _navigateToRegister,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: getbodyStyle(
                      color: isLoading
                          ? Colors.grey
                          : Colors.white.withOpacity(0.8),
                      fontSize: 15,
                    ),
                    text: "Don't have an account? ",
                    children: [
                      TextSpan(
                        text: 'Create Account',
                        style: getbodyStyle(
                          color: isLoading ? Colors.grey : AppColors.tealColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Gap(40),
        ],
      ),
    );
  }

  Widget _buildGlassyButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isLoading && onPressed != null)
            BoxShadow(
              color: AppColors.tealColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: isLoading || onPressed == null
                      ? Colors.grey.withOpacity(0.2)
                      : AppColors.tealColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          text,
                          style: getTitleStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles auth state changes for navigation and feedback
  void _handleAuthStateChanges(AuthState state) {
    if (state is LoginSuccessState) {
      if (!state.user.uploadedId) {
        // Navigate to OneMoreStepScreen if ID not uploaded
        pushReplacement(context, const OneMoreStepScreen());
        showGlobalSnackBar(
            context, "Login successful! Please complete the next step.");
      } else {
        // Extract first name for personalized animation
        String? firstName;
        if (state.user.name.isNotEmpty) {
          firstName = state.user.name
              .split(' ')
              .firstWhere((s) => s.isNotEmpty, orElse: () => '');
        }

        // Get profile picture URL
        String? profileUrl = state.user.profilePicUrl ?? state.user.image;
        if (profileUrl?.isEmpty ?? true) {
          profileUrl = null;
        }

        // Navigate to success animation
        pushReplacement(
          context,
          LoginSuccessAnimationView(
            profilePicUrl: profileUrl,
            firstName: firstName,
          ),
        );
      }
    } else if (state is AuthErrorState) {
      showGlobalSnackBar(context, state.message, isError: true);

      // Set error state for relevant fields
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
    } else if (state is AwaitingVerificationState) {
      showGlobalSnackBar(context,
          "Please check your email (${state.email}) to verify your account.");
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required String? errorText,
    required bool isPassword,
    required bool isLoading,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: hasError
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            enabled: !isLoading,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: getbodyStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: getbodyStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealColor.withOpacity(0.3),
                      AppColors.accentColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const Gap(8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              errorText!,
              style: getbodyStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Focus the password field
  void _focusPassword() {
    FocusScope.of(context).nextFocus();
  }

  /// Validates form and dispatches login event
  void _handleLogin() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    // Reset error states
    setState(() {
      _hasEmailError = false;
      _hasPasswordError = false;
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    // Basic validation
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

    // Dispatch LoginEvent to AuthBloc
    context.read<AuthBloc>().add(
          LoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  /// Navigate to forgot password screen
  void _navigateToForgotPassword() {
    push(context, const ForgotPasswordView());
  }

  /// Navigate to registration screen
  void _navigateToRegister() {
    pushReplacement(context, const RegisterView());
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();

    // Dispose animation controllers
    _slideController.dispose();
    _fadeController.dispose();

    super.dispose();
  }
}
