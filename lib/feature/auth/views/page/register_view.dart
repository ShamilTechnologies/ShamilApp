import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/services.dart';

// Core utilities & widgets
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';

// Auth bloc
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';

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
  int _currentIndex = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.letterDelay, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(SmoothTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer.cancel();
      _currentIndex = 0;
      _displayedText = "";
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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

/// Main registration view with multi-step form
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Page controller for multi-step form
  final PageController _pageController = PageController();

  // Form controllers
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

  // Focus node for National ID validation
  final FocusNode _nationalIdFocusNode = FocusNode();

  // State variables
  String _selectedCountryCode = '+20'; // Default to Egypt
  String _selectedGender = 'Male'; // Default gender
  int _currentFormPage = 0; // Current form step

  // National ID validation state
  bool _nationalIdError = false;
  String? _nationalIdErrorMessage;
  bool _isCheckingNatId = false;

  // Pre-filled data state (from family member linkage)
  String? _parentUserId;
  String? _familyMemberDocId;
  bool _isPrefilled = false;

  // Step validation state
  List<bool> _pageValidationErrors = [false, false, false];

  // Animation controllers
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _nationalIdFocusNode.addListener(_onNationalIdFocusChange);
  }

  void _initAnimations() {
    // Slide animation for form content
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

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  // National ID validation logic
  void _onNationalIdFocusChange() {
    if (!_nationalIdFocusNode.hasFocus &&
        _nationalIdController.text.trim().length == 14) {
      _checkNationalId();
    }
  }

  void _checkNationalId() {
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.length == 14) {
      setState(() {
        _isCheckingNatId = true;
        _clearPrefill(keepNatId: true);
      });

      // Dispatch event to AuthBloc
      context
          .read<AuthBloc>()
          .add(CheckNationalIdAsFamilyMember(nationalId: nationalId));
    } else if (_isPrefilled || _parentUserId != null) {
      setState(() {
        _clearPrefill(keepNatId: true);
      });
    }
  }

  // Pre-fill form with family member data
  void _prefillForm(FamilyMember data, String parentId, String docId) {
    // Split name components
    final nameParts = data.name.split(' ');
    _firstNameController.text =
        nameParts.isNotEmpty ? nameParts.first : data.name;
    _middleNameController.text = nameParts.length > 2
        ? nameParts.sublist(1, nameParts.length - 1).join(' ')
        : '';
    _lastNameController.text = nameParts.length > 1 ? nameParts.last : '';

    // Pre-fill other fields
    _emailController.text = data.email ?? '';
    _phoneController.text = _extractPhoneNumber(data.phone);
    _dobController.text = data.dob ?? '';
    _selectedGender = data.gender ?? 'Male';

    // Store IDs for linking
    _parentUserId = parentId;
    _familyMemberDocId = docId;
    _isPrefilled = true;

    showGlobalSnackBar(context,
        "Welcome! We found your details from a family member. Please complete your registration.");
  }

  // Extract phone number without country code
  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null) return '';

    if (fullPhone.startsWith(_selectedCountryCode)) {
      return fullPhone.substring(_selectedCountryCode.length).trim();
    }
    return fullPhone.trim();
  }

  // Clear pre-filled data
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

  // Date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime.tryParse(_dobController.text) ??
        now.subtract(const Duration(days: 365 * 18)); // Default to 18 years ago

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
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              // Dismiss keyboard on state changes
              FocusScope.of(context).unfocus();

              // Handle National ID check completion
              if (_isCheckingNatId && state is! AuthLoadingState) {
                setState(() {
                  _isCheckingNatId = false;
                });
              }

              // Handle success state
              if (state is RegisterSuccessState) {
                _handleRegistrationSuccess();
              }
              // Handle error state
              else if (state is AuthErrorState) {
                showGlobalSnackBar(context, state.message, isError: true);
              }
              // Handle National ID check states
              else if (state is ExistingFamilyMemberFound) {
                _handleExistingFamilyMember(state);
              } else if (state is NationalIdCheckFailed) {
                _handleNationalIdCheckFailed(state);
              } else if (state is NationalIdAlreadyRegistered) {
                _handleNationalIdAlreadyRegistered();
              } else if (state is NationalIdAvailable) {
                _handleNationalIdAvailable();
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
                  // Header with welcome text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(context),
                  ),

                  // Form container
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
                          children: [
                            // Step indicator
                            _buildStepIndicator(),

                            // Form pages
                            Expanded(
                              child: Form(
                                key: _formKey,
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

                                    // Page 2: Contact Info
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
          ),
        ),
      ),
    );
  }

  // Handle registration success
  void _handleRegistrationSuccess() {
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

  // Handle existing family member found
  void _handleExistingFamilyMember(ExistingFamilyMemberFound state) {
    setState(() {
      _prefillForm(
          state.externalMemberData, state.parentUserId, state.familyDocId);
      _nationalIdError = false;
      _nationalIdErrorMessage = null;
      _pageValidationErrors[1] = false;
    });
  }

  // Handle National ID check failure
  void _handleNationalIdCheckFailed(NationalIdCheckFailed state) {
    showGlobalSnackBar(context, state.message, isError: true);
    setState(() {
      if (_isPrefilled) _clearPrefill(keepNatId: true);
      _nationalIdError = true;
      _nationalIdErrorMessage = state.message;
      _pageValidationErrors[1] = true;
    });
  }

  // Handle National ID already registered
  void _handleNationalIdAlreadyRegistered() {
    showGlobalSnackBar(
        context, "This National ID is already registered to another user.",
        isError: true);

    setState(() {
      if (_isPrefilled) _clearPrefill(keepNatId: true);
      _nationalIdError = true;
      _nationalIdErrorMessage = "This National ID is already registered";
      _pageValidationErrors[1] = true;
    });
  }

  // Handle National ID available
  void _handleNationalIdAvailable() {
    setState(() {
      if (_isPrefilled) _clearPrefill(keepNatId: true);
      _nationalIdError = false;
      _nationalIdErrorMessage = null;
      _validateCurrentPage(); // Recheck page validation
    });
  }

  // Build the animated header section
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
          // Logo icon
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
                  "Join us today and get started",
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

  // Build step indicator for multi-page form
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentFormPage;
          bool hasError = _pageValidationErrors[index];

          // Error color takes precedence
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

  // Build form navigation buttons
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
                  style: getbodyStyle(
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

  // Handle continue or register button press
  void _handleContinueOrRegister(bool isLoading) {
    if (isLoading) return;

    if (_currentFormPage < 2) {
      // Validate current page before proceeding
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

  // Validate current form page
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
      // Check National ID validation first
      if (_nationalIdError) {
        showGlobalSnackBar(
            context, _nationalIdErrorMessage ?? "National ID validation failed",
            isError: true);
        return false;
      }

      // Check if National ID needs validation
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

  // Handle registration submission
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

    // Final National ID validation check
    if (_nationalIdController.text.trim().length == 14) {
      if (_nationalIdError) {
        showGlobalSnackBar(
            context, _nationalIdErrorMessage ?? "National ID validation failed",
            isError: true);

        // Go to contact info page
        if (_currentFormPage != 1) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }

      // If National ID hasn't been validated yet
      if (!_isPrefilled && !_isCheckingNatId) {
        _checkNationalId();
        showGlobalSnackBar(
            context, "Validating National ID before registration");
        return;
      }
    }

    // Prepare full name
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName =
        "$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName"
            .trim();

    // Dispatch registration event
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

  // Build basic information form (first page)
  Widget _buildBasicInfoForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Basic Information",
          style: getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Let's start with your basic details",
          style: getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // First Name
        GeneralTextFormField(
          controller: _firstNameController,
          labelText: 'First Name',
          hintText: 'Your first name',
          iconData: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
        ),
        const Gap(16),

        // Middle Name (Optional)
        GeneralTextFormField(
          controller: _middleNameController,
          labelText: 'Middle Name',
          hintText: 'Your middle name (optional)',
          iconData: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
          isRequired: false,
        ),
        const Gap(16),

        // Last Name
        GeneralTextFormField(
          controller: _lastNameController,
          labelText: 'Last Name',
          hintText: 'Your last name',
          iconData: CupertinoIcons.person,
          enabled: !isLoading && !_isPrefilled,
        ),
        const Gap(16),

        // Username
        GeneralTextFormField(
          controller: _usernameController,
          labelText: 'Username',
          hintText: 'Choose a unique username',
          iconData: CupertinoIcons.at,
          enabled: !isLoading,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
        ),
        const Gap(16),

        // Email
        EmailTextFormField(
          controller: _emailController,
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
                style: getbodyStyle(
                  color: isLoading ? Colors.grey : AppColors.secondaryText,
                ),
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: 'Login',
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

  // Build contact information form (second page)
  Widget _buildContactInfoForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Information",
          style: getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Tell us how to reach you",
          style: getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // Phone number with country code picker
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
                initialSelection: 'EG', // Egypt
                favorite: const ['+20', 'EG'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                enabled: !isLoading && !_isPrefilled,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
            const Gap(8),
            Expanded(
              child: GeneralTextFormField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Your phone number',
                iconData: CupertinoIcons.phone,
                keyboardType: TextInputType.phone,
                enabled: !isLoading && !_isPrefilled,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ],
        ),
        const Gap(16),

        // National ID field with status indicator
        GeneralTextFormField(
          controller: _nationalIdController,
          labelText: 'National ID',
          hintText: '14-digit national ID',
          iconData: CupertinoIcons.creditcard,
          keyboardType: TextInputType.number,
          enabled: !isLoading,
          focusNode: _nationalIdFocusNode,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
          hasError: _nationalIdError,
          errorText: _nationalIdErrorMessage,
          suffixIcon: _buildNationalIdSuffix(),
        ),
        const Gap(16),

        // Date of Birth
        DatePickerField(
          controller: _dobController,
          labelText: 'Date of Birth',
          hintText: 'YYYY-MM-DD',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your date of birth';
            }
            return null;
          },
          enabled: !isLoading && !_isPrefilled,
          onTap: () => _selectDate(context),
        ),
        const Gap(16),

        // Gender selection
        GlobalDropdownFormField<String>(
          labelText: 'Gender',
          items: ['Male', 'Female']
              .map((gender) =>
                  DropdownMenuItem(value: gender, child: Text(gender)))
              .toList(),
          value: _selectedGender,
          onChanged: isLoading || _isPrefilled
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
          iconData: CupertinoIcons.person_2,
          enabled: !isLoading && !_isPrefilled,
        ),
      ],
    );
  }

  // Build the custom icon/loader for the National ID field
  Widget _buildNationalIdSuffix() {
    if (_isCheckingNatId) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    } else if (_isPrefilled) {
      return Icon(
        Icons.check_circle,
        color: Colors.green.shade600,
        size: 20,
      );
    }
    return const SizedBox.shrink();
  }

  // Build password form (third page)
  Widget _buildPasswordForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create Password",
          style: getTitleStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(8),
        Text(
          "Set a secure password for your account",
          style: getbodyStyle(
            color: AppColors.secondaryText,
          ),
        ),
        const Gap(24),

        // Password field
        PasswordTextFormField(
          controller: _passwordController,
          labelText: 'Password',
          enabled: !isLoading,
        ),
        const Gap(16),

        // Confirm Password field
        PasswordTextFormField(
          controller: _confirmPasswordController,
          labelText: 'Confirm Password',
          enabled: !isLoading,
        ),
        const Gap(24),

        // Terms and conditions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
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
                  style: getSmallStyle(
                    color: AppColors.primaryText,
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
                style: getbodyStyle(
                  color: isLoading ? Colors.grey : AppColors.secondaryText,
                ),
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: 'Login',
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

  // Login page navigation
  void _handleLoginNavigation() {
    pushReplacement(context, const LoginView());
  }

  @override
  void dispose() {
    // Dispose controllers
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

    // Dispose focus node
    _nationalIdFocusNode.removeListener(_onNationalIdFocusChange);
    _nationalIdFocusNode.dispose();

    // Dispose animation controllers
    _slideController.dispose();
    _fadeController.dispose();

    // Dispose page controller
    _pageController.dispose();

    super.dispose();
  }
}
