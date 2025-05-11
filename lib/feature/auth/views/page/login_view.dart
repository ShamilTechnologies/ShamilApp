import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

/// Enhanced login view with modern design and improved maintainability
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Dismiss keyboard when state changes
        FocusScope.of(context).unfocus();

        // Handle login-related state changes
        _handleAuthStateChanges(state);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, current) =>
            (prev is AuthLoadingState) != (current is AuthLoadingState),
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.95),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 0.6],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with animated content
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildHeader(context),
                        ),

                        // Main content with form
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(24.0),
                                child: Form(
                                  key: _formKey,
                                  child: _buildLoginForm(context, isLoading),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
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

  /// Builds the animated header section
  Widget _buildHeader(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 28 : 36;
    final double headerHeight = isKeyboardOpen ? 100 : 160;
    final String welcomeText =
        isKeyboardOpen ? "Welcome Back" : "Welcome\nBack";

    return Container(
      height: headerHeight,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // App logo/icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Gap(12),

          // Welcome text with animation
          Flexible(
            child: SmoothTypingText(
              key: ValueKey(isKeyboardOpen),
              text: welcomeText,
              style: getHeadlineTextStyle(
                fontSize: welcomeFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          // Subtitle (hidden when keyboard is open)
          if (!isKeyboardOpen && headerHeight > 120)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Sign in to continue to your account",
                  style: getbodyStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the login form
  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form Title
        Text(
          "Login",
          style: getTitleStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Please sign in to continue",
          style: getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(30),

        // Email Field
        EmailTextFormField(
          controller: _emailController,
          focusNode: FocusNode(),
          onChanged: (value) {
            // Clear error when typing
            if (_hasEmailError) {
              setState(() {
                _hasEmailError = false;
                _emailErrorText = null;
              });
            }
          },
          onFieldSubmitted: (_) => _focusPassword(),
          enabled: !isLoading,
          hasError: _hasEmailError,
          errorText: _emailErrorText,
        ),
        const Gap(20),

        // Password Field
        PasswordTextFormField(
          controller: _passwordController,
          onChanged: (value) {
            // Clear error when typing
            if (_hasPasswordError) {
              setState(() {
                _hasPasswordError = false;
                _passwordErrorText = null;
              });
            }
          },
          onFieldSubmitted: (_) => _handleLogin(),
          enabled: !isLoading,
          hasError: _hasPasswordError,
          errorText: _passwordErrorText,
        ),

        // Forgot Password Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : _navigateToForgotPassword,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              foregroundColor: AppColors.primaryColor,
            ),
            child: Text(
              'Forgot Password?',
              style: getbodyStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Gap(30),

        // Login Button
        CustomButton(
          onPressed: isLoading ? null : _handleLogin,
          text: isLoading ? "Logging In..." : "Login",
          height: 54,
        ),
        const Gap(20),

        // Register Navigation Link
        Center(
          child: GestureDetector(
            onTap: isLoading ? null : _navigateToRegister,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: getbodyStyle(
                  color: isLoading ? Colors.grey : AppColors.secondaryText,
                ),
                text: "Don't have an account? ",
                children: [
                  TextSpan(
                    text: 'Register Now',
                    style: getbodyStyle(
                      color: isLoading ? Colors.grey : AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
