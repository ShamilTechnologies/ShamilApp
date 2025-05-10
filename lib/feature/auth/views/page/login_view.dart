import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart'; // Use navigation functions
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // Import global snack bar
// Import AppColors if needed
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
// Import text styles
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // Imports AuthBloc, AuthState etc.
// Ensure AuthModel is imported if LoginSuccessState uses it directly (it does)
import 'package:shamil_mobile_app/feature/auth/views/page/forgotPassword_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/register_view.dart';

/// SmoothTypingText widget animates text display.
class SmoothTypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration letterDelay;
  const SmoothTypingText(
      {super.key,
      required this.text,
      required this.style,
      this.letterDelay = const Duration(milliseconds: 100)});
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
    // Allow multiple lines for text like "Welcome\nBack"
    return Text(_displayedText, style: widget.style, maxLines: 2);
  }
}

/// LoginView displays the login form along with an animated welcome text.
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

  @override
  void initState() {
    super.initState();
    _initSlideAnimation();
  }

  void _initSlideAnimation() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start below screen
      end: Offset.zero, // Animate to final position
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    // Start animation shortly after build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detect if keyboard is open to adjust layout
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 40 : 70;
    final double topPadding = isKeyboardOpen ? 40 : 120;
    final String welcomeText =
        isKeyboardOpen ? "Welcome Back" : "Welcome\nBack";
    // Adjust height based on single or double line text
    final double fixedHeight =
        isKeyboardOpen ? welcomeFontSize * 1.5 : welcomeFontSize * 2.5;
    final theme = Theme.of(context);

    // Use BlocListener for side effects (navigation, snackbars)
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Dismiss keyboard when state changes
        FocusScope.of(context).unfocus();

        // Handle Success State -> Navigation
        if (state is LoginSuccessState) {
          if (!state.user.uploadedId) {
            // Navigate to OneMoreStepScreen if ID not uploaded
            // Pass the destination WIDGET directly
            pushReplacement(context, const OneMoreStepScreen());
            showGlobalSnackBar(
                context, "Login successful! Please complete the next step.");
          } else {
            // Navigate to Success Animation View if ID is uploaded
            // Extract First Name safely
            String? firstName;
            if (state.user.name.isNotEmpty) {
              firstName = state.user.name
                  .split(' ')
                  .firstWhere((s) => s.isNotEmpty, orElse: () => '');
            }
            // Get profile URL (check both fields)
            String? profileUrl = state.user.profilePicUrl ?? state.user.image;
            // Ensure empty string is treated as null for image check
            if (profileUrl?.isEmpty ?? true) {
              profileUrl = null;
            }

            // *** FIX: Pass the destination WIDGET directly ***
            pushReplacement(
              context,
              // No MaterialPageRoute needed here
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
      // Use BlocBuilder to rebuild UI parts based on state (e.g., enable/disable buttons)
      child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
        // Determine if loading based on the generic AuthLoadingState
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          resizeToAvoidBottomInset:
              true, // Allow resizing when keyboard appears
          backgroundColor:
              theme.scaffoldBackgroundColor, // Use theme background
          body: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Welcome Text
                  _buildWelcomeText(
                    topPadding: topPadding,
                    fixedHeight: fixedHeight,
                    welcomeText: welcomeText,
                    welcomeFontSize: welcomeFontSize,
                    isKeyboardOpen: isKeyboardOpen,
                  ),
                  const SizedBox(height: 30), // Spacing
                  // Form Area with Slide Animation
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        // Make form scrollable
                        physics: const BouncingScrollPhysics(),
                        // Pass isLoading status to the form builder
                        child: _buildLoginForm(context, isLoading),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Builds the animated welcome text widget.
  Widget _buildWelcomeText({
    required double topPadding,
    required double fixedHeight,
    required String welcomeText,
    required double welcomeFontSize,
    required bool isKeyboardOpen,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
        height: fixedHeight, // Ensure enough height for text
        alignment: Alignment.centerLeft,
        child: SmoothTypingText(
          // Use ValueKey to force rebuild when keyboard state changes text
          key: ValueKey(isKeyboardOpen),
          text: welcomeText,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                height: 1.1, // Adjust line height
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: welcomeFontSize,
              ),
        ),
      ),
    );
  }

  /// Builds the login form widgets.
  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
        children: [
          // Email Field
          EmailTextFormField(controller: _emailController, enabled: !isLoading),
          const SizedBox(height: 20),
          // Password Field
          PasswordTextFormField(
              controller: _passwordController, enabled: !isLoading),
          // Forgot Password Button
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton(
              onPressed: isLoading ? null : _handleForgotPassword,
              child: Text(
                'Forgot Password?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Login Button
          CustomButton(
            onPressed: isLoading ? null : _handleLogin,
            text: isLoading ? "Logging In..." : "Login",
          ),
          const SizedBox(height: 20),
          // Register Navigation Link
          GestureDetector(
            onTap: isLoading ? null : _handleRegisterNavigation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: isLoading
                          ? Colors.grey
                          : theme.colorScheme.secondary),
                  text: "Don't have an account? ",
                  children: [
                    TextSpan(
                      text: 'Register Now',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isLoading ? Colors.grey : theme.colorScheme.primary,
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
    // Use pushReplacement from navigation helpers
    pushReplacement(context, const RegisterView());
  }

  /// Navigates to the Forgot Password screen.
  void _handleForgotPassword() {
    // Use push from navigation helpers
    push(context, const ForgotPasswordView());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
