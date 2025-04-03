import 'dart:async';
// Removed math import - no longer needed for background animation
// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart'; // Using Gap for spacing
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart'; // For SuccessScreen
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:flutter/services.dart'; // For InputFormatters

// Removed Background Animation Classes: AnimatedLine, _BackgroundLinesPainter

/// SmoothTypingText widget animates text display.
class SmoothTypingText extends StatefulWidget {
  final String text; final TextStyle style; final Duration letterDelay;
  const SmoothTypingText({ super.key, required this.text, required this.style, this.letterDelay = const Duration(milliseconds: 130)});
  @override _SmoothTypingTextState createState() => _SmoothTypingTextState();
}
class _SmoothTypingTextState extends State<SmoothTypingText> {
  String _displayedText = ""; Timer? _timer; int _currentIndex = 0;
  @override void initState() { super.initState(); _startTyping(); }
  @override void didUpdateWidget(covariant SmoothTypingText oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.text != widget.text) { _resetTyping(); _startTyping(); } }
  void _resetTyping() { _timer?.cancel(); _currentIndex = 0; _displayedText = ""; }
  void _startTyping() { _timer = Timer.periodic(widget.letterDelay, (timer) { if (_currentIndex < widget.text.length) { setState(() { _displayedText = widget.text.substring(0, _currentIndex + 1); }); _currentIndex++; } else { _timer?.cancel(); } }); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  // Ensure maxLines allows for multiple lines
  @override Widget build(BuildContext context) { return Text(_displayedText, style: widget.style, maxLines: 2); }
}


/// RegisterView: Screen for user registration.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override State<RegisterView> createState() => _RegisterViewState();
}

// TickerProviderStateMixin is still needed for _slideController
class _RegisterViewState extends State<RegisterView> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Text Editing Controllers ---
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // --- Other State Variables ---
  String _selectedCountryCode = '+20';
  String _selectedGender = 'Male';

  // --- Animation Controllers ---
  late final AnimationController _slideController; // For form slide-in
  late final Animation<Offset> _slideAnimation;
  // Removed background animation controller and state


  @override
  void initState() {
    super.initState();
    _initSlideAnimation();
    // Removed background animation init
  }

  void _initSlideAnimation() {
    _slideController = AnimationController( vsync: this, duration: const Duration(milliseconds: 800), );
    _slideAnimation = Tween<Offset>( begin: const Offset(0, 0.5), end: Offset.zero, ) // Start closer
        .animate( CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart), ); // Use smoother curve
    Future.delayed(const Duration(milliseconds: 100), () { // Start sooner
       if (mounted) _slideController.forward();
    });
  }

  // Removed background animation methods

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 36 : 60; // Slightly smaller
    final double topPadding = isKeyboardOpen ? 20 : 50; // Adjust padding
    final String welcomeText = isKeyboardOpen ? "Create Account" : "Create\nAccount";
    // Increase height multiplier for two-line text
    final double fixedHeight = isKeyboardOpen ? welcomeFontSize * 1.4 : welcomeFontSize * 2.4;

    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      // Removed Stack, background animation is gone
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Welcome Text
              _buildWelcomeText( topPadding: topPadding, fixedHeight: fixedHeight, welcomeText: welcomeText, welcomeFontSize: welcomeFontSize, isKeyboardOpen: isKeyboardOpen, ),
              const Gap(20), // Use Gap for spacing
              // Form Area
              Expanded( child: SlideTransition( position: _slideAnimation,
                  child: BlocConsumer<AuthBloc, AuthState>( listener: (context, state) {
                      FocusScope.of(context).unfocus();
                      if (state is RegisterSuccessState) {
                         showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) => const SuccessScreen(), );
                         Future.delayed(const Duration(seconds: 3), () {
                            if (mounted && Navigator.of(context).canPop()) { Navigator.of(context).pop(); }
                            if (mounted) { pushReplacement(context, const LoginView()); showGlobalSnackBar( context, "Registration successful. Please verify your email.", ); }
                         });
                       } else if (state is AuthErrorState) { showGlobalSnackBar(context, state.message, isError: true); }
                    },
                    builder: (context, state) {
                      final isLoading = state is AuthLoadingState;
                      // Form with ListView for better scrolling
                      return Form(
                         key: _formKey,
                         child: ListView( // Use ListView for scrollable form content
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 20, top: 10), // Padding inside list
                            children: _buildRegistrationFormFields(isLoading, theme), // Build form fields dynamically
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
  Widget _buildWelcomeText({ required double topPadding, required double fixedHeight, required String welcomeText, required double welcomeFontSize, required bool isKeyboardOpen, }) {
    return Padding( padding: EdgeInsets.only(top: topPadding),
      // Ensure Container height is sufficient
      child: Container(
        height: fixedHeight, // Use calculated height
        alignment: Alignment.centerLeft,
        child: SmoothTypingText( key: ValueKey(isKeyboardOpen), text: welcomeText,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                 height: 1.1, // Line height affects total height needed
                 color: Theme.of(context).colorScheme.primary,
                 fontWeight: FontWeight.w800,
                 fontSize: welcomeFontSize,
              ),
        ),
      ),
    );
  }

  /// Builds the LIST of registration form field widgets with improved UX.
  List<Widget> _buildRegistrationFormFields(bool isLoading, ThemeData theme) {
    // Returns a list of widgets to be placed inside the ListView
    return [
          // --- Name Fields ---
          Text("Full Name", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(10),
          Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded( child: GeneralTextFormField( labelText: 'First Name*', controller: _firstNameController, enabled: !isLoading, textInputAction: TextInputAction.next, validator: (v) => v!.trim().isEmpty ? 'Required' : null, prefixIcon: const Icon(Icons.person_outline_rounded, size: 20), ), ),
              const Gap(8),
              Expanded( child: GeneralTextFormField( labelText: 'Middle Name', controller: _middleNameController, enabled: !isLoading, textInputAction: TextInputAction.next, validator: null, ), ),
              const Gap(8),
              Expanded( child: GeneralTextFormField( labelText: 'Last Name*', controller: _lastNameController, enabled: !isLoading, textInputAction: TextInputAction.next, validator: (v) => v!.trim().isEmpty ? 'Required' : null, ), ),
            ],
          ),
          const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

          // --- Account Info ---
           Text("Account Details", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
           const Gap(10),
           GeneralTextFormField( controller: _usernameController, labelText: 'Username*', hintText: 'Unique username (letters, numbers, _)', enabled: !isLoading, textInputAction: TextInputAction.next,
             prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
             inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')), LengthLimitingTextInputFormatter(20), ],
             validator: (value) { if (value == null || value.trim().isEmpty) return 'Username is required'; if (value.length < 3) return 'Min 3 characters'; if (value.contains(' ')) return 'No spaces allowed'; if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) { return 'Invalid characters'; } return null; },
          ),
          const Gap(16),
          EmailTextFormField(controller: _emailController, enabled: !isLoading),
           const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

          // --- Contact & Personal Info ---
           Text("Personal Information", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
           const Gap(10),
          Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container( decoration: BoxDecoration( color: isLoading ? Colors.grey.shade200 : theme.inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey) ),
                 child: CountryCodePicker( onChanged: (countryCode) { if (!isLoading) { setState(() { _selectedCountryCode = countryCode.dialCode ?? '+20'; }); } }, initialSelection: 'EG', favorite: const ['+20', 'EG'], showCountryOnly: false, showOnlyCountryWhenClosed: false, enabled: !isLoading, textStyle: getbodyStyle(color: isLoading ? Colors.grey.shade500 : AppColors.primaryColor), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), ),
              ),
              const Gap(10),
              Expanded( child: GeneralTextFormField( controller: _phoneController, labelText: 'Phone Number*', keyboardType: TextInputType.phone, enabled: !isLoading, textInputAction: TextInputAction.next, validator: (v) => v!.trim().isEmpty ? 'Required' : null, prefixIcon: const Icon(Icons.phone_outlined, size: 20),), ),
            ],
          ),
          const Gap(16),
          GeneralTextFormField( controller: _nationalIdController, labelText: 'National ID*', keyboardType: TextInputType.number, enabled: !isLoading, textInputAction: TextInputAction.next,
             prefixIcon: const Icon(Icons.badge_outlined, size: 20),
             inputFormatters: [ FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14) ], maxLength: 14,
             validator: (value) { if (value == null || value.trim().isEmpty) return 'Required'; if (value.length != 14) return 'Must be 14 digits'; return null; }
          ),
          const Gap(16),
          Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded( child: GeneralTextFormField( controller: _dobController, labelText: 'Date of Birth*', readOnly: true, enabled: !isLoading, prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: isLoading ? null : () async {
                     DateTime? pickedDate = await showDatePicker( context: context, initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (context, child) { return Theme( data: Theme.of(context).copyWith( colorScheme: Theme.of(context).colorScheme.copyWith( primary: AppColors.primaryColor, ), ), child: child!, ); }, );
                    if (pickedDate != null) { _dobController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}"; }
                  },
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ),
              const Gap(10),
              Expanded( child: GlobalDropdownFormField<String>( labelText: 'Gender*', items: ['Male', 'Female'].map((gender) => DropdownMenuItem( value: gender, child: Text(gender), )).toList(), value: _selectedGender, enabled: !isLoading, onChanged: isLoading ? null : (value) { setState(() { _selectedGender = value!; }); },
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

          // --- Password Fields ---
           Text("Set Your Password", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
           const Gap(10),
          PasswordTextFormField(controller: _passwordController, enabled: !isLoading, labelText: 'Password*'),
          const Gap(16),
          GeneralTextFormField( controller: _confirmPasswordController, labelText: 'Confirm Password*', enabled: !isLoading, obscureText: true, textInputAction: TextInputAction.done,
             prefixIcon: const Icon(Icons.lock_outline, size: 20),
             validator: (value) { if (value == null || value.isEmpty) return 'Required'; if (value != _passwordController.text) return 'Passwords do not match'; return null; },
          ),
          const Gap(30),

          // --- Actions ---
          CustomButton( onPressed: isLoading ? null : _handleRegister, text: isLoading ? "Registering..." : "Register", ),
          Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: GestureDetector( onTap: isLoading ? null : _handleLoginNavigation,
              child: RichText( textAlign: TextAlign.center, text: TextSpan( text: 'Already have an account? ', style: theme.textTheme.bodyMedium?.copyWith(color: isLoading ? Colors.grey : theme.colorScheme.secondary), children: [
                    TextSpan( text: 'Login', style: theme.textTheme.bodyMedium?.copyWith( color: isLoading ? Colors.grey : theme.colorScheme.primary, fontWeight: FontWeight.bold,), ),
                  ], ),
              ),
            ),
          ),
           const Gap(10),
        ];
  }

  /// Handles form validation and dispatches RegisterEvent.
  void _handleRegister() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = "$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName";
      // Dispatch RegisterEvent with username
      context.read<AuthBloc>().add( RegisterEvent(
          name: fullName.trim(),
          username: _usernameController.text.trim(), // Pass username
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

  /// Navigates back to the Login screen.
  Future<void> _handleLoginNavigation() async { pushReplacement(context, const LoginView()); }

  @override
  void dispose() {
    // Dispose all controllers
    _firstNameController.dispose(); _middleNameController.dispose(); _lastNameController.dispose();
    _usernameController.dispose(); _emailController.dispose(); _phoneController.dispose();
    _nationalIdController.dispose(); _dobController.dispose(); _passwordController.dispose();
    _confirmPasswordController.dispose();
    _slideController.dispose();
    // Removed background controller dispose
    super.dispose();
   }
}

