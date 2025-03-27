import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/forgotPassword_view.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/oneMoreStep_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/register_view.dart';

/// SmoothTypingText widget animates the provided text by typing one letter at a time.
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
    return Text(_displayedText, style: widget.style);
  }
}

/// LoginView displays the login form along with an animated welcome text.
/// It is connected to AuthBloc for handling the login process.
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

  /// Initializes the slide animation for the login form.
  void _initSlideAnimation() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Starts off-screen below.
      end: Offset.zero, // Ends at its final position.
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 40 : 70;
    final double topPadding = isKeyboardOpen ? 40 : 120;
    // "Welcome Back" displayed in one or two lines based on keyboard visibility.
    final String welcomeText = isKeyboardOpen ? "Welcome Back" : "Welcome\nBack";
    final double fixedHeight = isKeyboardOpen ? welcomeFontSize * 1.5 : welcomeFontSize * 2.5;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Show loading dialog during login.
        if (state is LoginLoadingState) {
           showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const LoadingScreen();
                          },
                        );
        } else {
          // Dismiss any open loading dialog.
          Navigator.of(context, rootNavigator: true).pop();
          if (state is LoginSuccessState) {
            // Navigate based on whether the user has uploaded ID images.
            if (!state.user.uploadedId) {
              pushReplacement(context, const OneMoreStepScreen());
            } else {
              pushReplacement(context, const ExploreScreen());
            }
          } else if (state is AuthErrorState) {
            // Display error via global SnackBar.
            showGlobalSnackBar(context, state.message, isError: true);
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Container(
            color: AppColors.accentColor.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Welcome Text.
                _buildWelcomeText(
                  topPadding: topPadding,
                  fixedHeight: fixedHeight,
                  welcomeText: welcomeText,
                  welcomeFontSize: welcomeFontSize,
                  isKeyboardOpen: isKeyboardOpen,
                ),
                const SizedBox(height: 20),
                // Login form with slide animation.
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginForm(),
                  ),
                ),
              ],
            ),
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
          key: ValueKey(isKeyboardOpen), // Restart animation on state change.
          text: welcomeText,
          style: getbodyStyle(
            height: 1,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: welcomeFontSize,
          ),
        ),
      ),
    );
  }

  /// Builds the login form with email, password and action items.
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(10),
          // Email Field.
          EmailTextFormField(controller: _emailController),
          const SizedBox(height: 25),
          // Password Field.
          PasswordTextFormField(controller: _passwordController),
          // "Forgot Password?" text button.
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: Text(
                'Forgot Password?',
                style: getSmallStyle(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Gap(20),
          // Primary Login Button.
          CustomButton(
            onPressed: _handleLogin,
            text: "Login",
          ),
          // Clickable text to navigate to Register page.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: GestureDetector(
              onTap: _handleRegisterNavigation,
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: getbodyStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: getbodyStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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

  /// Handles the login action by dispatching a LoginEvent to AuthBloc.
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  /// Navigates to the RegisterView.
  Future<void> _handleRegisterNavigation() async {
    pushReplacement(context, const RegisterView());
  }

  /// Handles the "Forgot Password?" action.
  void _handleForgotPassword() {
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
