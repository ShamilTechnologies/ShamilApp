import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // Import global snack bar
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';

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
    return Text(_displayedText, style: widget.style);
  }
}

/// ForgotPasswordView displays a form for users to reset their password.
/// It follows the same design as the Login and Register screens.
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
      begin: const Offset(0, 1), // Starts off-screen.
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
    final String welcomeText =
        isKeyboardOpen ? "Reset Password" : "Reset\nPassword";
    final double fixedHeight =
        isKeyboardOpen ? welcomeFontSize * 1.5 : welcomeFontSize * 4.5;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          color: AppColors.accentColor.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeText(
                topPadding: topPadding,
                fixedHeight: fixedHeight,
                welcomeText: welcomeText,
                welcomeFontSize: welcomeFontSize,
                isKeyboardOpen: isKeyboardOpen,
              ),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildForgotPasswordForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText({
    required double topPadding,
    required double fixedHeight,
    required String welcomeText,
    required double welcomeFontSize,
    required bool isKeyboardOpen,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
      ),
      child: Container(
        height: fixedHeight,
        alignment: Alignment.centerLeft,
        child: SmoothTypingText(
          key: ValueKey(isKeyboardOpen),
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

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email Field.
          EmailTextFormField(controller: _emailController),
          const SizedBox(height: 25),
          // Reset Password Button.
          CustomButton(
            onPressed: _handleResetPassword,
            text: "Reset Password",
          ),
          // Clickable text to navigate back to Login.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: GestureDetector(
              onTap: _handleLoginNavigation,
              child: RichText(
                text: TextSpan(
                  text: "Remember your password? ",
                  style: getbodyStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: "Login",
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

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        // Use the global SnackBar function with vibration.
        showGlobalSnackBar(
            context, "Password reset email sent. Check your inbox.");
      } on FirebaseAuthException catch (e) {
        showGlobalSnackBar(context, e.message ?? "Reset password error.",
            isError: true);
      } catch (e) {
        showGlobalSnackBar(context, "Something went wrong.", isError: true);
      }
    }
  }

  Future<void> _handleLoginNavigation() async {
    pushReplacement(context, const LoginView());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
