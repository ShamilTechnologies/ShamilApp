import 'dart:async'; // For Timer if using debounced onChanged
import 'dart:io'; // For File type (needed by UploadIdEvent, though not used directly here)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart'; // Use Gap for spacing
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
import 'package:intl/intl.dart'; // For DateFormat
// *** CORRECTED IMPORT: Import FamilyMember model for pre-filling ***
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';

// Assuming SmoothTypingText is defined elsewhere or replace with standard Text
// If SmoothTypingText is local, keep its definition here.
// For brevity, assuming it exists or replacing with Text for now.
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

/// RegisterView: Screen for user registration.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  // FocusNode for National ID field to trigger check on unfocus
  final FocusNode _nationalIdFocusNode = FocusNode();

  // --- Other State Variables ---
  String _selectedCountryCode = '+20'; // Default to Egypt
  String _selectedGender = 'Male'; // Default Gender
  // State variables for pre-fill logic
  String? _parentUserId;
  String? _familyMemberDocId;
  bool _isCheckingNatId = false; // Loading indicator for Nat ID check
  bool _isPrefilled = false; // Flag to indicate if form was pre-filled

  // --- Animation Controllers ---
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initSlideAnimation();
    // Add listener to FocusNode to trigger check when focus is lost
    _nationalIdFocusNode.addListener(_onNationalIdFocusChange);
  }

  void _initSlideAnimation() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start slightly below center
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );
    // Start animation shortly after build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
  }

  // --- National ID Check Logic ---
  void _onNationalIdFocusChange() {
    // Trigger check only when focus is lost AND ID has correct length (14 digits)
    if (!_nationalIdFocusNode.hasFocus &&
        _nationalIdController.text.trim().length == 14) {
      _checkNationalId();
    }
  }

  /// Dispatches event to check National ID against registered users and external family members.
  void _checkNationalId() {
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.length == 14) {
      print("Checking National ID: $nationalId");
      // Reset pre-fill state before checking again
      // Keep National ID field populated
      setState(() {
        _isCheckingNatId = true; // Show loading indicator
        _clearPrefill(
            keepNatId: true); // Clear previous prefill data but keep Nat ID
      });
      // Dispatch event to AuthBloc
      context
          .read<AuthBloc>()
          .add(CheckNationalIdAsFamilyMember(nationalId: nationalId));
    } else {
      // Clear pre-fill state if ID becomes invalid length after being valid
      if (_isPrefilled || _parentUserId != null) {
        setState(() {
          _clearPrefill(keepNatId: true);
        });
      }
    }
  }

  /// Pre-fills form fields based on data found from an external family member record.
  void _prefillForm(FamilyMember data, String parentId, String docId) {
    // Split name (simple split, assumes "First Last" or "First Middle Last")
    final nameParts = data.name.split(' ');
    _firstNameController.text =
        nameParts.isNotEmpty ? nameParts.first : data.name;
    _middleNameController.text = nameParts.length > 2
        ? nameParts.sublist(1, nameParts.length - 1).join(' ')
        : '';
    _lastNameController.text = nameParts.length > 1 ? nameParts.last : '';

    // Pre-fill other fields if available
    _emailController.text = data.email ?? '';
    _phoneController.text =
        _extractPhoneNumber(data.phone); // Helper to extract number part
    _dobController.text = data.dob ?? ''; // Use DOB if available
    _selectedGender = data.gender ?? 'Male'; // Default if null

    // Store IDs needed for registration linking
    _parentUserId = parentId;
    _familyMemberDocId = docId;
    _isPrefilled = true; // Set flag

    showGlobalSnackBar(context,
        "Welcome! We found your details from a family member. Please complete your registration.");
  }

  /// Helper to attempt extracting number part from phone (e.g., remove +20)
  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null) return '';
    // Basic check: if starts with known prefix, remove it
    if (fullPhone.startsWith(_selectedCountryCode)) {
      return fullPhone.substring(_selectedCountryCode.length).trim();
    }
    // Add more sophisticated checks if needed (regex for country codes)
    return fullPhone
        .trim(); // Return trimmed full if prefix not matched or complex
  }

  /// Clears pre-filled data and resets flags.
  void _clearPrefill({bool keepNatId = false}) {
    print("Clearing pre-filled data.");
    if (!keepNatId) _nationalIdController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _dobController.clear();
    _selectedGender = 'Male'; // Reset gender
    _parentUserId = null;
    _familyMemberDocId = null;
    _isPrefilled = false;
  }

  /// Shows the date picker dialog.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1920), // Reasonable earliest date
      lastDate: DateTime.now(), // Cannot select future date
    );
    if (picked != null) {
      setState(() {
        // Format the date as yyyy-MM-dd (or your preferred format)
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 36 : 60;
    final double topPadding = isKeyboardOpen ? 20 : 50;
    final String welcomeText =
        isKeyboardOpen ? "Create Account" : "Create\nAccount";
    final double fixedHeight =
        isKeyboardOpen ? welcomeFontSize * 1.4 : welcomeFontSize * 2.4;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const Gap(20),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  // Use BlocConsumer to handle state changes and build UI
                  child: BlocConsumer<AuthBloc, AuthState>(
                    // Listen only to relevant states for this screen
                    listenWhen: (prev, current) =>
                        current is RegisterSuccessState ||
                        current is AuthErrorState || // General auth errors
                        current
                            is ExistingFamilyMemberFound || // Nat ID check results
                        current is NationalIdCheckFailed || // Renamed state
                        current is NationalIdAlreadyRegistered || // Added state
                        current is NationalIdAvailable, // Renamed state
                    listener: (context, state) {
                      FocusScope.of(context).unfocus(); // Dismiss keyboard

                      // Stop Nat ID check indicator AFTER Bloc processing is done
                      bool wasChecking = _isCheckingNatId;
                      if (wasChecking && state is! AuthLoadingState) {
                        if (mounted) {
                          setState(() {
                            _isCheckingNatId = false;
                          });
                        }
                      }

                      // Handle Registration Success
                      if (state is RegisterSuccessState) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) =>
                              const SuccessScreen(),
                        );
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                          if (mounted) {
                            pushReplacement(context, const LoginView());
                            showGlobalSnackBar(
                              context,
                              "Registration successful. Please verify your email.",
                            );
                          }
                        });
                      }
                      // Handle General Auth Errors (e.g., from registration attempt)
                      else if (state is AuthErrorState) {
                        showGlobalSnackBar(context, state.message,
                            isError: true);
                      }
                      // Handle National ID Check results
                      else if (state is ExistingFamilyMemberFound) {
                        if (mounted) {
                          setState(() {
                            _prefillForm(state.externalMemberData,
                                state.parentUserId, state.familyDocId);
                          });
                        }
                      }
                      // Handle National ID Check Failure (Index error, network error, etc.)
                      else if (state is NationalIdCheckFailed) {
                        showGlobalSnackBar(context, state.message,
                            isError: true);
                        if (_isPrefilled && mounted) {
                          setState(() => _clearPrefill(keepNatId: true));
                        }
                      }
                      // Handle National ID Already Registered by another user
                      else if (state is NationalIdAlreadyRegistered) {
                        // *** ADDED HANDLER ***
                        showGlobalSnackBar(context,
                            "This National ID is already registered to another user.",
                            isError: true);
                        if (_isPrefilled && mounted) {
                          setState(() => _clearPrefill(keepNatId: true));
                        }
                      }
                      // Handle National ID Available (Not found anywhere)
                      else if (state is NationalIdAvailable) {
                        print("National ID is available.");
                        // Clear pre-fill state if user previously had data loaded then entered a different, available ID
                        if (_isPrefilled && mounted) {
                          setState(() => _clearPrefill(keepNatId: true));
                        }
                        // Optionally show a subtle success indicator or just allow proceeding
                        // showGlobalSnackBar(context, "National ID is available.", isError: false);
                      }
                    },
                    // Build UI based on general loading state (for registration attempt)
                    buildWhen: (prev, current) =>
                        (prev is AuthLoadingState &&
                            current is! AuthLoadingState) ||
                        (prev is! AuthLoadingState &&
                            current is AuthLoadingState),
                    builder: (context, state) {
                      // General loading state affects button/field enabled status
                      // _isCheckingNatId handles the specific indicator for the ID field check
                      final isLoading = state is AuthLoadingState &&
                          state.message ==
                              null; // Use general loading state, ignore Nat ID check loading state here
                      return Form(
                        key: _formKey,
                        // *** ADDED Autovalidate Mode ***
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: ListView(
                          // Use ListView for scrollability
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20, top: 10),
                          children:
                              _buildRegistrationFormFields(isLoading, theme),
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

  /// Builds the LIST of registration form field widgets.
  List<Widget> _buildRegistrationFormFields(bool isLoading, ThemeData theme) {
    // Suffix widget for the National ID field
    Widget nationalIdSuffix = _isCheckingNatId
        ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)))
        : (_isPrefilled
            ? Tooltip(
                message: "Details pre-filled",
                child: Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20))
            : const SizedBox.shrink());

    return [
      // --- Name Fields ---
      Text("Full Name",
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      const Gap(10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GeneralTextFormField(
              labelText: 'First Name*',
              controller: _firstNameController,
              enabled: !isLoading && !_isPrefilled,
              textInputAction: TextInputAction.next,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const Gap(8),
          Expanded(
            child: GeneralTextFormField(
              labelText: 'Middle Name',
              controller: _middleNameController,
              enabled: !isLoading && !_isPrefilled,
              textInputAction: TextInputAction.next,
              validator: null,
            ),
          ),
          const Gap(8),
          Expanded(
            child: GeneralTextFormField(
              labelText: 'Last Name*',
              controller: _lastNameController,
              enabled: !isLoading && !_isPrefilled,
              textInputAction: TextInputAction.next,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
          ),
        ],
      ),
      if (_isPrefilled)
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text("Name pre-filled from family record. Please verify.",
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orange.shade800)),
        ),
      const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

      // --- Account Info ---
      Text("Account Details",
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      const Gap(10),
      GeneralTextFormField(
        controller: _usernameController,
        labelText: 'Username*',
        hintText: 'Unique username (letters, numbers, _)',
        enabled: !isLoading,
        textInputAction: TextInputAction.next,
        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          LengthLimitingTextInputFormatter(20),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          if (value.length < 3) return 'Min 3 characters';
          if (value.contains(' ')) return 'No spaces allowed';
          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value))
            return 'Invalid characters';
          return null;
        },
      ),
      const Gap(16),
      EmailTextFormField(
          controller: _emailController,
          enabled: !isLoading && !_isPrefilled), // Disable if prefilled
      const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

      // --- Contact & Personal Info ---
      Text("Personal Information",
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      const Gap(10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* ... Country Code Picker ... */ Container(
            decoration: BoxDecoration(
                color: isLoading
                    ? Colors.grey.shade200
                    : theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.inputDecorationTheme.enabledBorder?.borderSide
                            .color ??
                        Colors.grey)),
            child: CountryCodePicker(
              onChanged: (countryCode) {
                if (!isLoading) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode ?? '+20';
                  });
                }
              },
              initialSelection: 'EG',
              favorite: const ['+20', 'EG'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              enabled: !isLoading,
              textStyle: getbodyStyle(
                  color: isLoading
                      ? Colors.grey.shade500
                      : AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          ),
          const Gap(10),
          Expanded(
            child: GeneralTextFormField(
              controller: _phoneController,
              labelText: 'Phone Number*',
              keyboardType: TextInputType.phone,
              enabled: !isLoading && !_isPrefilled,
              textInputAction: TextInputAction.next,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            ),
          ),
        ],
      ),
      const Gap(16),
      GeneralTextFormField(
        controller: _nationalIdController,
        focusNode: _nationalIdFocusNode,
        labelText: 'National ID*',
        keyboardType: TextInputType.number,
        enabled: !isLoading,
        readOnly: _isCheckingNatId,
        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
        suffixIcon: nationalIdSuffix,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(14)
        ],
        maxLength: 14,
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          if (value.length != 14) return 'Must be 14 digits';
          return null;
        },
      ),
      const Gap(16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GeneralTextFormField(
              controller: _dobController,
              labelText: 'Date of Birth*',
              readOnly: true,
              enabled: !isLoading && !_isPrefilled,
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              // *** IMPLEMENTED Date Picker onTap ***
              onTap:
                  isLoading || _isPrefilled ? null : () => _selectDate(context),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
          ),
          const Gap(10),
          Expanded(
            child: GlobalDropdownFormField<String>(
              labelText: 'Gender*',
              items: ['Male', 'Female']
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              value: _selectedGender,
              enabled: !isLoading && !_isPrefilled,
              onChanged: isLoading || _isPrefilled
                  ? null
                  : (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
          ),
        ],
      ),
      const Gap(24), const Divider(thickness: 0.5, height: 1), const Gap(24),

      // --- Password Fields ---
      Text("Set Your Password",
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      const Gap(10),
      PasswordTextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          labelText: 'Password*'),
      const Gap(16),
      GeneralTextFormField(
        controller: _confirmPasswordController,
        labelText: 'Confirm Password*',
        enabled: !isLoading,
        obscureText: true,
        textInputAction: TextInputAction.done,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          if (value != _passwordController.text)
            return 'Passwords do not match';
          return null;
        },
      ),
      const Gap(30),

      // --- Actions ---
      CustomButton(
        onPressed: isLoading ? null : _handleRegister,
        text: isLoading ? "Registering..." : "Register",
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: GestureDetector(
          onTap: isLoading ? null : _handleLoginNavigation,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'Already have an account? ',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: isLoading ? Colors.grey : theme.colorScheme.secondary),
              children: [
                TextSpan(
                  text: 'Login',
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

  /// Handles form validation and dispatches RegisterEvent.
  void _handleRegister() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName =
          "$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName"
              .trim();

      context.read<AuthBloc>().add(
            RegisterEvent(
              name: fullName,
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              nationalId: _nationalIdController.text.trim(),
              phone: _selectedCountryCode + _phoneController.text.trim(),
              gender: _selectedGender,
              dob: _dobController.text.trim(),
              parentUserId: _parentUserId, // Pass linking info if available
              familyMemberDocId: _familyMemberDocId,
            ),
          );
    }
  }

  /// Navigates back to the Login screen.
  Future<void> _handleLoginNavigation() async {
    pushReplacement(context, const LoginView());
  }

  @override
  void dispose() {
    // Dispose all controllers AND FocusNode
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nationalIdFocusNode
        .removeListener(_onNationalIdFocusChange); // Remove listener
    _nationalIdFocusNode.dispose(); // Dispose focus node
    _slideController.dispose();
    super.dispose();
  }
}
