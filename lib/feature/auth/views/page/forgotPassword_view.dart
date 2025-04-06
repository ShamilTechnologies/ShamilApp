import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart'; // Use Gap for spacing
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
// Removed actionScreens import as SuccessScreen isn't typically used here
// import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

/// SmoothTypingText widget animates text display.
class SmoothTypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration letterDelay;
  const SmoothTypingText({
    super.key,
    required this.text,
    required this.style,
    this.letterDelay = const Duration(milliseconds: 130),
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

/// ForgotPasswordView: Screen for resetting user password.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

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
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 36 : 60;
    final double topPadding = isKeyboardOpen ? 30 : 80; // Adjusted padding
    final String welcomeText =
        isKeyboardOpen ? "Reset Password" : "Reset\nPassword";
    // Adjust height based on one or two lines
    final double fixedHeight =
        isKeyboardOpen ? welcomeFontSize * 1.4 : welcomeFontSize * 2.4;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor,
      // Add AppBar for back navigation and consistency
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        iconTheme: IconThemeData(
            color: theme.colorScheme.primary), // Themed back arrow
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              _buildWelcomeText(
                topPadding: topPadding,
                fixedHeight: fixedHeight,
                welcomeText: welcomeText,
                welcomeFontSize: welcomeFontSize,
                isKeyboardOpen: isKeyboardOpen,
              ),
              const Gap(30), // Increased gap
              // Form Area
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  // Use BlocConsumer to handle state changes and build UI
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      FocusScope.of(context).unfocus(); // Dismiss keyboard
                      if (state is PasswordResetEmailSentState) {
                        // Show success message and potentially navigate back after delay
                        showGlobalSnackBar(context,
                            "Password reset email sent. Check your inbox.");
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            // Navigate back to login or previous screen
                            Navigator.maybePop(context);
                          }
                        });
                      } else if (state is AuthErrorState) {
                        // Show error message from Bloc
                        showGlobalSnackBar(context, state.message,
                            isError: true);
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is AuthLoadingState;
                      // Form with ListView
                      return Form(
                        key: _formKey,
                        child: ListView(
                          // Use ListView for potential future additions
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20, top: 10),
                          children:
                              _buildForgotPasswordFormFields(isLoading, theme),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        height: fixedHeight,
        alignment: Alignment.centerLeft,
        child: SmoothTypingText(
          key: ValueKey(isKeyboardOpen),
          text: welcomeText,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                height: 1.1,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: welcomeFontSize,
              ),
        ),
      ),
    );
  }

  /// Builds the LIST of form field widgets.
  List<Widget> _buildForgotPasswordFormFields(bool isLoading, ThemeData theme) {
    return [
      Text(
        // Add instructional text
        "Enter the email address associated with your account "
        "and we'll send you a link to reset your password.",
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.secondary),
      ),
      const Gap(24),
      // Email Field
      EmailTextFormField(
        controller: _emailController,
        enabled: !isLoading, // Disable when loading
      ),
      const Gap(30), // More space before button
      // Reset Password Button
      CustomButton(
        onPressed:
            isLoading ? null : _handleResetPassword, // Disable when loading
        text: isLoading ? "Sending..." : "Send Reset Link",
      ),
      const Gap(20), // Space before login link
      // Clickable text to navigate back to Login.
      Center(
        // Center the login link
        child: GestureDetector(
          onTap:
              isLoading ? null : _handleLoginNavigation, // Disable when loading
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "Remember your password? ",
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: isLoading ? Colors.grey : theme.colorScheme.secondary),
              children: [
                TextSpan(
                  text: "Login",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLoading ? Colors.grey : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const Gap(10),
    ];
  }

  /// Handles form validation and dispatches event to AuthBloc.
  void _handleResetPassword() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      // Dispatch event to Bloc instead of calling FirebaseAuth directly
      context.read<AuthBloc>().add(
            SendPasswordResetEmail(email: _emailController.text.trim()),
          );
    }
  }

  /// Navigates back to the Login screen.
  Future<void> _handleLoginNavigation() async {
    // Use pushReplacement to avoid stacking login/forgot password screens
    pushReplacement(context, const LoginView());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
