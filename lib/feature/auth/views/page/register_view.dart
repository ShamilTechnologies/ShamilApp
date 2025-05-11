import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';

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

/// Enhanced RegisterView with modern design matching home screen.
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
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  int _currentFormPage = 0; // Track the current step/page of the form
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Add listener to FocusNode to trigger check when focus is lost
    _nationalIdFocusNode.addListener(_onNationalIdFocusChange);
  }

  void _initAnimations() {
    // Slide animation for form
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Start with a subtle offset
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

  // --- National ID Check Logic ---
  void _onNationalIdFocusChange() {
    // Trigger check only when focus is lost AND ID has correct length (14 digits)
    if (!_nationalIdFocusNode.hasFocus &&
        _nationalIdController.text.trim().length == 14) {
      _checkNationalId();
    }
  }

  /// Dispatches event to check National ID
  void _checkNationalId() {
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.length == 14) {
      // Reset pre-fill state before checking again
      // Keep National ID field populated
      setState(() {
        _isCheckingNatId = true;
        _clearPrefill(keepNatId: true);
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

  /// Pre-fills form fields based on data found
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
    _phoneController.text = _extractPhoneNumber(data.phone);
    _dobController.text = data.dob ?? '';
    _selectedGender = data.gender ?? 'Male';

    // Store IDs needed for registration linking
    _parentUserId = parentId;
    _familyMemberDocId = docId;
    _isPrefilled = true;

    showGlobalSnackBar(context,
        "Welcome! We found your details from a family member. Please complete your registration.");
  }

  /// Helper to extract number part from phone
  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null) return '';
    // Basic check: if starts with known prefix, remove it
    if (fullPhone.startsWith(_selectedCountryCode)) {
      return fullPhone.substring(_selectedCountryCode.length).trim();
    }
    return fullPhone.trim();
  }

  /// Clears pre-filled data and resets flags
  void _clearPrefill({bool keepNatId = false}) {
    if (!keepNatId) _nationalIdController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _dobController.clear();
    _selectedGender = 'Male';
    _parentUserId = null;
    _familyMemberDocId = null;
    _isPrefilled = false;
  }

  /// Shows the date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime.tryParse(_dobController.text) ??
        now.subtract(const Duration(days: 365 * 18));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // State variables for validations and errors
  List<bool> _pageValidationErrors = [false, false, false];
  bool _nationalIdError = false;
  String? _nationalIdErrorMessage;

  @override
  Widget build(BuildContext context) {
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
          child: LayoutBuilder(builder: (context, constraints) {
            return BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                FocusScope.of(context).unfocus();

                // Stop Nat ID check indicator after Bloc processing is done
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
                    builder: (BuildContext context) => const SuccessScreen(),
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
                // Handle General Auth Errors
                else if (state is AuthErrorState) {
                  showGlobalSnackBar(context, state.message, isError: true);
                }
                // Handle National ID Check results
                else if (state is ExistingFamilyMemberFound) {
                  if (mounted) {
                    setState(() {
                      _prefillForm(state.externalMemberData, state.parentUserId,
                          state.familyDocId);
                      _nationalIdError = false;
                      _nationalIdErrorMessage = null;
                      // Update validation for the page
                      _pageValidationErrors[1] = false;
                    });
                  }
                }
                // Handle National ID Check Failure
                else if (state is NationalIdCheckFailed) {
                  showGlobalSnackBar(context, state.message, isError: true);
                  if (mounted) {
                    setState(() {
                      if (_isPrefilled) _clearPrefill(keepNatId: true);
                      _nationalIdError = true;
                      _nationalIdErrorMessage = state.message;
                      // Update validation for the page
                      _pageValidationErrors[1] = true;
                    });
                  }
                }
                // Handle National ID Already Registered
                else if (state is NationalIdAlreadyRegistered) {
                  showGlobalSnackBar(context,
                      "This National ID is already registered to another user.",
                      isError: true);
                  if (mounted) {
                    setState(() {
                      if (_isPrefilled) _clearPrefill(keepNatId: true);
                      _nationalIdError = true;
                      _nationalIdErrorMessage =
                          "This National ID is already registered";
                      // Update validation for the page
                      _pageValidationErrors[1] = true;
                    });
                  }
                }
                // Handle National ID Available
                else if (state is NationalIdAvailable) {
                  if (mounted) {
                    setState(() {
                      if (_isPrefilled) _clearPrefill(keepNatId: true);
                      _nationalIdError = false;
                      _nationalIdErrorMessage = null;
                      // Update validation for the page
                      _validateCurrentPage(); // Recheck page validation
                    });
                  }
                }
              },
              buildWhen: (prev, current) =>
                  (prev is AuthLoadingState && current is! AuthLoadingState) ||
                  (prev is! AuthLoadingState && current is AuthLoadingState),
              builder: (context, state) {
                final isLoading = state is AuthLoadingState;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step indicator
                              _buildStepIndicator(),

                              // Form content
                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  physics: isLoading
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  onPageChanged: (page) {
                                    setState(() {
                                      _currentFormPage = page;
                                    });
                                  },
                                  children: [
                                    // Page 1: Basic Info
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(24.0),
                                      physics: const BouncingScrollPhysics(),
                                      child: _buildBasicInfoForm(isLoading),
                                    ),

                                    // Page 2: Contact & Personal Details
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(24.0),
                                      physics: const BouncingScrollPhysics(),
                                      child: _buildContactInfoForm(isLoading),
                                    ),

                                    // Page 3: Password & Completion
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(24.0),
                                      physics: const BouncingScrollPhysics(),
                                      child: _buildPasswordForm(isLoading),
                                    ),
                                  ],
                                ),
                              ),

                              // Navigation buttons
                              _buildFormNavigation(isLoading),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Builds the animated header section
  Widget _buildHeader(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final double welcomeFontSize = isKeyboardOpen ? 28 : 36;
    final double headerHeight = isKeyboardOpen ? 100 : 160;
    final String welcomeText =
        isKeyboardOpen ? "Create Account" : "Create\nAccount";

    return Container(
      height: headerHeight,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo or app brand icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.person_add_solid,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Gap(12),

          // Welcome text with typing animation
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
                  "Join us today and get started",
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

  /// Builds the step indicator at the top of the form
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentFormPage;
          bool hasError = _pageValidationErrors[index];

          // Color logic - error color takes precedence if there's an error
          Color indicatorColor = hasError
              ? Colors.red.shade600
              : (isActive ? AppColors.primaryColor : Colors.grey.shade300);

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              height: 5,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Builds the form navigation buttons at the bottom
  Widget _buildFormNavigation(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Back button (if not on first page)
          if (_currentFormPage > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Back",
                  style: AppTextStyle.getbodyStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_currentFormPage > 0) const Gap(16),

          // Continue/Register button
          Expanded(
            flex: 2,
            child: CustomButton(
              onPressed:
                  isLoading ? null : () => _handleContinueOrRegister(isLoading),
              text: isLoading
                  ? "Processing..."
                  : (_currentFormPage < 2 ? "Continue" : "Register"),
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  /// Handles the continue or register button press
  void _handleContinueOrRegister(bool isLoading) {
    if (isLoading) return;

    if (_currentFormPage < 2) {
      // Validate current page
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // On last page, validate and register
      if (_validateCurrentPage()) {
        _handleRegister();
      }
    }
  }

  /// Validates the current form page and returns whether validation passed
  bool _validateCurrentPage() {
    bool isValid = false;

    if (_currentFormPage == 0) {
      // Validate basic info
      isValid = _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().length >= 3 &&
          _emailController.text.trim().isNotEmpty &&
          _emailController.text.contains('@');

      setState(() {
        _pageValidationErrors[0] = !isValid;
      });

      if (!isValid) {
        showGlobalSnackBar(context, "Please complete all required fields",
            isError: true);
      }
    } else if (_currentFormPage == 1) {
      // Check if National ID has a validation error first
      if (_nationalIdError) {
        showGlobalSnackBar(
            context, _nationalIdErrorMessage ?? "National ID validation failed",
            isError: true);
        return false;
      }

      // If National ID is filled but not checked yet, perform the check
      if (_nationalIdController.text.trim().length == 14 &&
          !_isCheckingNatId &&
          !_isPrefilled) {
        _checkNationalId();
        showGlobalSnackBar(
            context, "Please wait while we validate your National ID");
        return false;
      }

      // Validate contact info
      isValid = _phoneController.text.trim().isNotEmpty &&
          _nationalIdController.text.trim().length == 14 &&
          _dobController.text.trim().isNotEmpty;

      setState(() {
        _pageValidationErrors[1] = !isValid;
      });

      if (!isValid) {
        showGlobalSnackBar(context, "Please complete all required fields",
            isError: true);
      }
    } else if (_currentFormPage == 2) {
      // Validate passwords
      if (_passwordController.text.trim().isEmpty) {
        showGlobalSnackBar(context, "Please enter a password", isError: true);
        setState(() {
          _pageValidationErrors[2] = true;
        });
        return false;
      }

      if (_passwordController.text.length < 6) {
        showGlobalSnackBar(context, "Password must be at least 6 characters",
            isError: true);
        setState(() {
          _pageValidationErrors[2] = true;
        });
        return false;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        showGlobalSnackBar(context, "Passwords do not match", isError: true);
        setState(() {
          _pageValidationErrors[2] = true;
        });
        return false;
      }

      isValid = true;
      setState(() {
        _pageValidationErrors[2] = false;
      });
    }

    return isValid;
  }

  /// Handles form validation and dispatches RegisterEvent
  void _handleRegister() {
    FocusScope.of(context).unfocus();

    // Check if any page has validation errors
    if (_pageValidationErrors.contains(true)) {
      showGlobalSnackBar(
          context, "Please fix all validation errors before registering",
          isError: true);

      // Navigate to the first page with an error
      int errorPage = _pageValidationErrors.indexOf(true);
      if (errorPage != _currentFormPage) {
        _pageController.animateToPage(
          errorPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    // Make sure we've validated National ID
    if (_nationalIdController.text.trim().length == 14) {
      if (_nationalIdError) {
        showGlobalSnackBar(
            context, _nationalIdErrorMessage ?? "National ID validation failed",
            isError: true);
        // Go to the page with National ID
        if (_currentFormPage != 1) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      // If National ID hasn't been validated yet, validate it now
      if (!_isPrefilled && !_isCheckingNatId) {
        _checkNationalId();
        showGlobalSnackBar(
            context, "Validating National ID before registration");
        return;
      }
    }

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
            parentUserId: _parentUserId,
            familyMemberDocId: _familyMemberDocId,
          ),
        );
  }

  /// Builds the first page of the form with basic information
  Widget _buildBasicInfoForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Basic Information",
          style: AppTextStyle.getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Let's start with your basic details",
          style: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // First Name
        _buildTextField(
          controller: _firstNameController,
          labelText: 'First Name',
          hintText: 'Your first name',
          prefixIcon: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
        ),
        const Gap(16),

        // Middle Name (Optional)
        _buildTextField(
          controller: _middleNameController,
          labelText: 'Middle Name (Optional)',
          hintText: 'Your middle name',
          prefixIcon: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
          isRequired: false,
        ),
        const Gap(16),

        // Last Name
        _buildTextField(
          controller: _lastNameController,
          labelText: 'Last Name',
          hintText: 'Your last name',
          prefixIcon: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
        ),
        const Gap(16),

        // Username
        _buildTextField(
          controller: _usernameController,
          labelText: 'Username',
          hintText: 'Choose a unique username',
          prefixIcon: CupertinoIcons.at,
          enabled: !isLoading,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
        ),
        const Gap(16),

        // Email
        _buildTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Your email address',
          prefixIcon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading && !_isPrefilled,
        ),
        const Gap(20),

        // Login link
        Center(
          child: GestureDetector(
            onTap: isLoading ? null : _handleLoginNavigation,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyle.getbodyStyle(
                  color: isLoading ? Colors.grey : AppColors.secondaryText,
                ),
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: 'Login',
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
    );
  }

  /// Builds the second page of the form with contact information
  Widget _buildContactInfoForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Information",
          style: AppTextStyle.getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Tell us how to reach you",
          style: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // Phone number with country code
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey.shade200 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CountryCodePicker(
                onChanged: (countryCode) {
                  if (!isLoading && !_isPrefilled) {
                    setState(() {
                      _selectedCountryCode = countryCode.dialCode ?? '+20';
                    });
                  }
                },
                initialSelection: 'EG',
                favorite: const ['+20', 'EG'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                enabled: !isLoading && !_isPrefilled,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
            const Gap(8),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Your phone number',
                prefixIcon: CupertinoIcons.phone,
                keyboardType: TextInputType.phone,
                enabled: !isLoading && !_isPrefilled,
              ),
            ),
          ],
        ),
        const Gap(16),

        // National ID
        _buildTextField(
          controller: _nationalIdController,
          labelText: 'National ID',
          hintText: '14-digit national ID',
          prefixIcon: CupertinoIcons.creditcard,
          keyboardType: TextInputType.number,
          enabled: !isLoading,
          focusNode: _nationalIdFocusNode,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
          suffix: _isCheckingNatId
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (_isPrefilled
                  ? Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 20)
                  : null),
        ),
        const Gap(16),

        // Date of Birth
        _buildTextField(
          controller: _dobController,
          labelText: 'Date of Birth',
          hintText: 'YYYY-MM-DD',
          prefixIcon: CupertinoIcons.calendar,
          enabled: !isLoading && !_isPrefilled,
          readOnly: true,
          onTap: isLoading || _isPrefilled ? null : () => _selectDate(context),
        ),
        const Gap(16),

        // Gender selection
        _buildDropdownField(
          labelText: 'Gender',
          value: _selectedGender,
          items: ['Male', 'Female']
              .map((gender) =>
                  DropdownMenuItem(value: gender, child: Text(gender)))
              .toList(),
          onChanged: isLoading || _isPrefilled
              ? null
              : (value) {
                  setState(() {
                    _selectedGender = value.toString();
                  });
                },
          prefixIcon: CupertinoIcons.person_2,
          enabled: !isLoading && !_isPrefilled,
        ),
      ],
    );
  }

  /// Builds the third page of the form with password fields
  Widget _buildPasswordForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create Password",
          style: AppTextStyle.getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Set a secure password for your account",
          style: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // Password
        _buildTextField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Min 6 characters',
          prefixIcon: CupertinoIcons.lock,
          obscureText: true,
          enabled: !isLoading,
        ),
        const Gap(16),

        // Confirm Password
        _buildTextField(
          controller: _confirmPasswordController,
          labelText: 'Confirm Password',
          hintText: 'Re-enter password',
          prefixIcon: CupertinoIcons.lock_shield,
          obscureText: true,
          enabled: !isLoading,
        ),
        const Gap(24),

        // Terms and conditions checkbox
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.checkmark_shield,
                color: AppColors.primaryColor,
                size: 22,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  "By creating an account, you agree to our Terms of Service and Privacy Policy.",
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Login link
        Center(
          child: GestureDetector(
            onTap: isLoading ? null : _handleLoginNavigation,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyle.getbodyStyle(
                  color: isLoading ? Colors.grey : AppColors.secondaryText,
                ),
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: 'Login',
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
    );
  }

  /// Builds a custom styled text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData prefixIcon = CupertinoIcons.pencil,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    bool isRequired = true,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    VoidCallback? onTap,
    Widget? suffix,
    bool hasError = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            border: hasError ? Border.all(color: Colors.red, width: 1.5) : null,
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            enabled: enabled,
            focusNode: focusNode,
            onTap: onTap,
            inputFormatters: inputFormatters,
            style: AppTextStyle.getbodyStyle(
              color: hasError ? Colors.red.shade800 : null,
            ),
            decoration: InputDecoration(
              labelText: isRequired ? '$labelText*' : labelText,
              hintText: hintText,
              labelStyle: AppTextStyle.getbodyStyle(
                color: hasError ? Colors.red.shade600 : AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: AppTextStyle.getbodyStyle(
                color: hasError
                    ? Colors.red.shade200
                    : AppColors.secondaryText.withOpacity(0.6),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasError
                        ? Colors.red.shade50
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prefixIcon,
                    color:
                        hasError ? Colors.red.shade600 : AppColors.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              suffixIcon: suffix,
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
                  color: hasError
                      ? Colors.red.shade400
                      : AppColors.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        // Error text display
        if (hasError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 16.0),
            child: Text(
              errorText,
              style: AppTextStyle.getSmallStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a custom dropdown field
  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(Object?)? onChanged,
    IconData prefixIcon = CupertinoIcons.pencil,
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
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        style: AppTextStyle.getbodyStyle(),
        decoration: InputDecoration(
          labelText: '$labelText*',
          labelStyle: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w500,
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
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.all(16),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Navigates to the Login screen
  void _handleLoginNavigation() {
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
    _nationalIdFocusNode.removeListener(_onNationalIdFocusChange);
    _nationalIdFocusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
