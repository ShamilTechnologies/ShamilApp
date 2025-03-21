import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For BlocConsumer and context.read
import 'package:gap/gap.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // Global SnackBar function
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
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

/// RegisterView displays the registration form with an animated welcome text.
/// On success, a dialog notifies the user to verify their email before navigating to LoginView.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for registration fields.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Variables for country code and gender.
  String _selectedCountryCode = '+20';
  String _selectedGender = 'Male';

  // Controls the slide animation.
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
    final double topPadding = isKeyboardOpen ? 5 : 5;
    final String welcomeText =
        isKeyboardOpen ? "Create Account" : "Create\nAccount";
    final double fixedHeight =
        isKeyboardOpen ? welcomeFontSize * 1.5 : welcomeFontSize * 2.5;

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
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      // Dismiss keyboard whenever a new state is emitted.
                      FocusScope.of(context).unfocus();
                      if (state is RegisterLoadingState) {
                        // Show the loading dialog.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const LoadingScreen();
                          },
                        );
                      } else {
                        // If a dialog is open (from loading), pop it.
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        if (state is RegisterSuccessState) {
                          // Show success dialog.
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const SuccessScreen();
                            },
                          );
                          Future.delayed(const Duration(seconds: 4), () {
                            Navigator.of(context)
                                .pop(); // Dismiss success dialog.
                            pushReplacement(context, const LoginView());
                            showGlobalSnackBar(
                              context,
                              "Registration successful. Please verify your email.",
                            );
                          });
                        } else if (state is AuthErrorState) {
                          showGlobalSnackBar(context, state.message,
                              isError: true);
                        }
                      }
                    },
                    builder: (context, state) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildRegistrationForm(),
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

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(10),
          // Full Name split into three fields.
          Row(
            children: [
              Expanded(
                child: GlobalTextFormField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlobalTextFormField(
                  controller: _middleNameController,
                  labelText: 'Middle Name',
                  validator: (value) {
                    // Middle name is optional.
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlobalTextFormField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          EmailTextFormField(controller: _emailController),
          const SizedBox(height: 20),
          Row(
            children: [
              CountryCodePicker(
                onChanged: (countryCode) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode ?? '+20';
                  });
                },
                initialSelection: 'EG',
                favorite: const ['+20', 'EG'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlobalTextFormField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter phone number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlobalTextFormField(
            controller: _nationalIdController,
            labelText: 'National ID',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter national ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Row combining Date of Birth and Gender fields.
          Row(
            children: [
              Expanded(
                child: GlobalTextFormField(
                  controller: _dobController,
                  labelText: 'Date of Birth',
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 18)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _dobController.text =
                          pickedDate.toLocal().toString().split(' ')[0];
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select DOB';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlobalDropdownFormField<String>(
                  labelText: 'Gender',
                  items: ['Male', 'Female']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  value: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select gender';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PasswordTextFormField(controller: _passwordController),
          const SizedBox(height: 20),
          GlobalTextFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const Gap(20),
          CustomButton(
            onPressed: _handleRegister,
            text: "Register",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: GestureDetector(
              onTap: _handleLoginNavigation,
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: getbodyStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: 'Login',
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

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      // Combine first, middle, and last name into a full name.
      final fullName = '${_firstNameController.text.trim()} '
          '${_middleNameController.text.trim()} '
          '${_lastNameController.text.trim()}';
      context.read<AuthBloc>().add(
            RegisterEvent(
              name: fullName,
              email: _emailController.text.trim(),
              password: _passwordController.text,
              nationalId: _nationalIdController.text.trim(),
              phone: _selectedCountryCode + _phoneController.text.trim(),
              gender: _selectedGender,
              dob: _dobController.text.trim(),
            ),
          );
    }
  }

  Future<void> _handleLoginNavigation() async {
    pushReplacement(context, const LoginView());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
