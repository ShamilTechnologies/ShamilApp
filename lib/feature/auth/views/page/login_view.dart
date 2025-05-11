import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/forgotPassword_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/register_view.dart';

/// SmoothTypingText widget animates text display.
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
  _SmoothTypingTextState createState() => _SmoothTypingTextState();
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
  void didUpdateWidget(covariant SmoothTypingText oldWidget) {
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
        });
        _currentIndex++;
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
    return Text(_displayedText, style: widget.style, maxLines: 2);
  }
}

/// Enhanced LoginView with modern design matching home screen.
class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Slide animation for form
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Start with a more subtle offset
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
    // Use BlocListener for side effects (navigation, snackbars)
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Dismiss keyboard when state changes
        FocusScope.of(context).unfocus();

        // Handle Success State -> Navigation
        if (state is LoginSuccessState) {
          if (!state.user.uploadedId) {
            // Navigate to OneMoreStepScreen if ID not uploaded
            pushReplacement(context, const OneMoreStepScreen());
            showGlobalSnackBar(
                context, "Login successful! Please complete the next step.");
          } else {
            // Extract First Name safely
            String? firstName;
            if (state.user.name.isNotEmpty) {
              firstName = state.user.name
                  .split(' ')
                  .firstWhere((s) => s.isNotEmpty, orElse: () => '');
            }
            // Get profile URL
            String? profileUrl = state.user.profilePicUrl ?? state.user.image;
            // Ensure empty string is treated as null for image check
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
          }
        }
        // Handle Error State -> Show SnackBar
        else if (state is AuthErrorState) {
          showGlobalSnackBar(context, state.message, isError: true);
        }
        // Handle Awaiting Verification State -> Show SnackBar
        else if (state is AwaitingVerificationState) {
          showGlobalSnackBar(context,
              "Please check your email (${state.email}) to verify your account.");
        }
      },
      // Use BlocBuilder to rebuild UI parts based on state
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Determine if loading based on the generic AuthLoadingState
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            // Use a gradient background similar to home screen
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
                child: LayoutBuilder(builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with animated content
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildHeader(context, isLoading),
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
                              child: _buildLoginForm(context, isLoading),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the animated header section with welcome text and decorative elements.
  Widget _buildHeader(BuildContext context, bool isLoading) {
    // Get the keyboard status to adjust layout
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
        mainAxisSize: MainAxisSize.min, // Use minimum vertical space
        children: [
          // Logo or app brand icon in top corner
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

          // Welcome text with smooth typing animation
          Flexible(
            child: SmoothTypingText(
              key: ValueKey(isKeyboardOpen),
              text: welcomeText,
              style: AppTextStyle.getHeadlineTextStyle(
                fontSize: welcomeFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          if (!isKeyboardOpen && headerHeight > 120)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Sign in to continue to your account",
                  style: AppTextStyle.getbodyStyle(
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

  /// Builds the login form widgets with enhanced styling.
  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title
          Text(
            "Login",
            style: AppTextStyle.getTitleStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const Gap(8),
          Text(
            "Please sign in to continue",
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
          ),
          const Gap(30),

          // Email Field
          _buildTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            enabled: !isLoading,
          ),
          const Gap(20),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: CupertinoIcons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            enabled: !isLoading,
          ),

          // Forgot Password Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                foregroundColor: AppColors.primaryColor,
              ),
              child: Text(
                'Forgot Password?',
                style: AppTextStyle.getbodyStyle(
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
              onTap: isLoading ? null : _handleRegisterNavigation,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyle.getbodyStyle(
                    color: isLoading ? Colors.grey : AppColors.secondaryText,
                  ),
                  text: "Don't have an account? ",
                  children: [
                    TextSpan(
                      text: 'Register Now',
                      style: AppTextStyle.getbodyStyle(
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
      ),
    );
  }

  /// Builds a custom styled text field.
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData prefixIcon = CupertinoIcons.pencil,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        style: AppTextStyle.getbodyStyle(),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText.withOpacity(0.6),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                prefixIcon,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  /// Handles login button press: validates form and dispatches event.
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    if (_formKey.currentState?.validate() ?? false) {
      // Dispatch LoginEvent to AuthBloc
      context.read<AuthBloc>().add(
            LoginEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  /// Navigates to the Register screen.
  Future<void> _handleRegisterNavigation() async {
    pushReplacement(context, const RegisterView());
  }

  /// Navigates to the Forgot Password screen.
  void _handleForgotPassword() {
    push(context, const ForgotPasswordView());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
