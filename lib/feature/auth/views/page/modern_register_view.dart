import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Core imports
import 'package:shamil_mobile_app/core/constants/assets_icons.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/enhanced_stroke_loader.dart';

// Auth imports
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';

class ModernRegisterView extends StatefulWidget {
  const ModernRegisterView({super.key});

  @override
  State<ModernRegisterView> createState() => _ModernRegisterViewState();
}

class _ModernRegisterViewState extends State<ModernRegisterView>
    with TickerProviderStateMixin {
  // Form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _nationalIdFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Animation controller
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form state
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'Male';
  String _selectedCountryCode = '+20';

  // Validation errors
  Map<String, String?> _fieldErrors = {};

  // National ID state
  bool _isCheckingNationalId = false;
  String? _parentUserId;
  String? _familyMemberDocId;
  bool _isPrefilled = false;
  String? _lastCheckedNationalId;
  Timer? _nationalIdDebounceTimer;

  // Username validation state
  bool _isCheckingUsername = false;
  String? _lastCheckedUsername;
  Timer? _usernameDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startAnimation();
    _nationalIdFocusNode.addListener(_onNationalIdFocusChange);
    _usernameFocusNode.addListener(_onUsernameFocusChange);
  }

  void _initializeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  void _onNationalIdFocusChange() {
    if (!_nationalIdFocusNode.hasFocus &&
        _nationalIdController.text.trim().length == 14) {
      _debouncedCheckNationalId();
    }
  }

  void _onUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus &&
        _usernameController.text.trim().length >= 3) {
      _debouncedCheckUsername();
    }
  }

  void _debouncedCheckNationalId() {
    _nationalIdDebounceTimer?.cancel();
    _nationalIdDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkNationalId();
    });
  }

  void _checkNationalId() {
    final nationalId = _nationalIdController.text.trim();

    // Prevent duplicate checks and ensure widget is still mounted
    if (!mounted ||
        nationalId.length != 14 ||
        _isCheckingNationalId ||
        _lastCheckedNationalId == nationalId) {
      return;
    }

    setState(() {
      _isCheckingNationalId = true;
      _lastCheckedNationalId = nationalId;
      // Only reset prefill status without clearing user-entered data
      if (_isPrefilled) {
        _parentUserId = null;
        _familyMemberDocId = null;
        _isPrefilled = false;
      }
    });

    context
        .read<AuthBloc>()
        .add(CheckNationalIdAsFamilyMember(nationalId: nationalId));
  }

  void _debouncedCheckUsername() {
    _usernameDebounceTimer?.cancel();
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _checkUsername();
    });
  }

  void _checkUsername() {
    final username = _usernameController.text.trim();

    // Prevent duplicate checks and ensure widget is still mounted
    if (!mounted ||
        username.length < 3 ||
        _isCheckingUsername ||
        _lastCheckedUsername == username) {
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _lastCheckedUsername = username;
    });

    context.read<AuthBloc>().add(CheckUsernameAvailability(username: username));
  }

  void _prefillForm(FamilyMember data, String parentId, String docId) {
    final nameParts = data.name.split(' ');
    _firstNameController.text =
        nameParts.isNotEmpty ? nameParts.first : data.name;
    _lastNameController.text = nameParts.length > 1 ? nameParts.last : '';
    _emailController.text = data.email ?? '';
    _phoneController.text = _extractPhoneNumber(data.phone);
    _dobController.text = data.dob ?? '';
    _selectedGender = data.gender ?? 'Male';
    _parentUserId = parentId;
    _familyMemberDocId = docId;
    _isPrefilled = true;

    showGlobalSnackBar(context,
        "Welcome! We found your details from a family member. Please complete your registration.");
  }

  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null) return '';
    if (fullPhone.startsWith(_selectedCountryCode)) {
      return fullPhone.substring(_selectedCountryCode.length).trim();
    }
    return fullPhone.trim();
  }

  void _clearPrefill({bool keepNatId = false}) {
    if (!keepNatId) _nationalIdController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _dobController.clear();
    _selectedGender = 'Male';
    _parentUserId = null;
    _familyMemberDocId = null;
    _isPrefilled = false;
  }

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
            colorScheme: const ColorScheme.dark(
              primary: AppColors.tealColor,
              surface: AppColors.splashBackground,
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
  void dispose() {
    _nationalIdDebounceTimer?.cancel();
    _usernameDebounceTimer?.cancel();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _usernameFocusNode.removeListener(_onUsernameFocusChange);
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _nationalIdFocusNode.removeListener(_onNationalIdFocusChange);
    _nationalIdFocusNode.dispose();
    _dobFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            backgroundColor: AppColors.splashBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.splashBackground,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildRegisterForm(isLoading),
                          const SizedBox(height: 24),
                          _buildBottomNavigation(isLoading),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero logo - bigger and left-aligned like signin
          Align(
            alignment: Alignment.centerLeft,
            child: Hero(
              tag: 'app_logo',
              child: SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset(
                  AssetsIcons.logoSvg,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    AppColors.tealColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Main title - left aligned under logo
          Text(
            'Create Account',
            style: getHeadlineTextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ).copyWith(
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Join us and start your premium experience',
            style: getbodyStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Name fields row
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _firstNameController,
                    focusNode: _firstNameFocusNode,
                    label: 'First Name',
                    hintText: 'Enter first name',
                    icon: Icons.person_outline,
                    hasError: _fieldErrors['firstName'] != null,
                    errorText: _fieldErrors['firstName'],
                    isLoading: isLoading || _isPrefilled,
                    onChanged: (value) => _clearFieldError('firstName'),
                    onSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernTextField(
                    controller: _lastNameController,
                    focusNode: _lastNameFocusNode,
                    label: 'Last Name',
                    hintText: 'Enter last name',
                    icon: Icons.person_outline,
                    hasError: _fieldErrors['lastName'] != null,
                    errorText: _fieldErrors['lastName'],
                    isLoading: isLoading || _isPrefilled,
                    onChanged: (value) => _clearFieldError('lastName'),
                    onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Username - Standard field with validation
            _buildModernTextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              label: 'Username',
              hintText: 'Choose a unique username',
              icon: Icons.alternate_email_outlined,
              hasError: _fieldErrors['username'] != null,
              errorText: _fieldErrors['username'],
              isLoading: isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
              ],
              suffixIcon: _lastCheckedUsername != null &&
                      _lastCheckedUsername == _usernameController.text.trim() &&
                      _fieldErrors['username'] == null
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                  : null,
              onChanged: (value) {
                _clearFieldError('username');

                // Reset state if user clears or significantly modifies the username
                if (value.length < 3) {
                  // Cancel any pending validation
                  _usernameDebounceTimer?.cancel();
                  if (_lastCheckedUsername != null || _isCheckingUsername) {
                    setState(() {
                      _lastCheckedUsername = null;
                      _isCheckingUsername = false;
                    });
                  }
                } else if (value.length >= 3) {
                  _debouncedCheckUsername();
                }
              },
              onSubmitted: (_) => _emailFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Email
            _buildModernTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'Email',
              hintText: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hasError: _fieldErrors['email'] != null,
              errorText: _fieldErrors['email'],
              isLoading: isLoading || _isPrefilled,
              onChanged: (value) => _clearFieldError('email'),
              onSubmitted: (_) => _phoneFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Phone number
            _buildModernTextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              label: 'Phone Number',
              hintText: 'Enter phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hasError: _fieldErrors['phone'] != null,
              errorText: _fieldErrors['phone'],
              isLoading: isLoading || _isPrefilled,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Only numbers
              ],
              onChanged: (value) => _clearFieldError('phone'),
              onSubmitted: (_) => _nationalIdFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // National ID
            _buildModernTextField(
              controller: _nationalIdController,
              focusNode: _nationalIdFocusNode,
              label: 'National ID',
              hintText: '14-digit national ID',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
              maxLength: 14,
              hasError: _fieldErrors['nationalId'] != null,
              errorText: _fieldErrors['nationalId'],
              isLoading: isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Only numbers
                LengthLimitingTextInputFormatter(14), // Max 14 digits
              ],
              suffixIcon: _isPrefilled
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                  : null,
              onChanged: (value) {
                _clearFieldError('nationalId');

                // Reset state if user clears or modifies the national ID significantly
                if (value.length < 14) {
                  // Cancel any pending validation
                  _nationalIdDebounceTimer?.cancel();
                  if (_lastCheckedNationalId != null || _isCheckingNationalId) {
                    setState(() {
                      _lastCheckedNationalId = null;
                      _isCheckingNationalId = false;
                      // Only clear prefill status without clearing other fields
                      if (_isPrefilled) {
                        _parentUserId = null;
                        _familyMemberDocId = null;
                        _isPrefilled = false;
                      }
                    });
                  }
                } else if (value.length == 14) {
                  _debouncedCheckNationalId();
                }
              },
              onSubmitted: (_) => _dobFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Date of Birth and Gender row
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _dobController,
                    focusNode: _dobFocusNode,
                    label: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    icon: Icons.calendar_today_outlined,
                    hasError: _fieldErrors['dob'] != null,
                    errorText: _fieldErrors['dob'],
                    isLoading: isLoading || _isPrefilled,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    onChanged: (value) => _clearFieldError('dob'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGenderDropdown(isLoading),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Security',
              style: getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Password
            _buildModernTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Password',
              hintText: 'Create a secure password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              hasError: _fieldErrors['password'] != null,
              errorText: _fieldErrors['password'],
              isLoading: isLoading,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              onChanged: (value) => _clearFieldError('password'),
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            _buildModernTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              hasError: _fieldErrors['confirmPassword'] != null,
              errorText: _fieldErrors['confirmPassword'],
              isLoading: isLoading,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              onChanged: (value) => _clearFieldError('confirmPassword'),
              onSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: 24),

            // Terms notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.tealColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                      style: getSmallStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Register button
            _buildRegisterButton(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required String? errorText,
    required bool isLoading,
    required Function(String) onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLength,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getbodyStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: !isLoading,
            readOnly: readOnly,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            style: getbodyStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: getbodyStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: getSmallStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.red.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderDropdown(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: getbodyStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            items: ['Male', 'Female']
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(
                        gender,
                        style: getbodyStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: isLoading || _isPrefilled
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  },
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.person_2_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: AppColors.splashBackground,
            style: getbodyStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.tealColor.withOpacity(0.5),
        ),
        child: isLoading
            ? const EnhancedStrokeLoader.small(
                color: Colors.white,
              )
            : Text(
                'Create Account',
                style: getButtonStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isLoading) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: getSmallStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: isLoading ? null : _navigateToLogin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: RichText(
              text: TextSpan(
                style: getbodyStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                ),
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: getbodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFieldError(String field) {
    if (_fieldErrors[field] != null) {
      setState(() {
        _fieldErrors[field] = null;
      });
    }
  }

  bool _validateForm() {
    _fieldErrors.clear();
    bool isValid = true;

    // First Name validation
    if (_firstNameController.text.trim().isEmpty) {
      _fieldErrors['firstName'] = "First name is required";
      isValid = false;
    }

    // Last Name validation
    if (_lastNameController.text.trim().isEmpty) {
      _fieldErrors['lastName'] = "Last name is required";
      isValid = false;
    }

    // Username validation
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _fieldErrors['username'] = "Username is required";
      isValid = false;
    } else if (username.length < 3) {
      _fieldErrors['username'] = "Username must be at least 3 characters";
      isValid = false;
    } else if (username.contains(' ')) {
      _fieldErrors['username'] = "Username cannot contain spaces";
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      _fieldErrors['username'] =
          "Username can only contain letters, numbers, dots and underscores";
      isValid = false;
    }

    // Email validation
    if (_emailController.text.trim().isEmpty) {
      _fieldErrors['email'] = "Email is required";
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      _fieldErrors['email'] = "Please enter a valid email";
      isValid = false;
    }

    // Phone validation
    if (_phoneController.text.trim().isEmpty) {
      _fieldErrors['phone'] = "Phone number is required";
      isValid = false;
    }

    // National ID validation
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.isEmpty) {
      _fieldErrors['nationalId'] = "National ID is required";
      isValid = false;
    } else if (nationalId.length != 14) {
      _fieldErrors['nationalId'] = "National ID must be exactly 14 digits";
      isValid = false;
    } else if (!RegExp(r'^\d{14}$').hasMatch(nationalId)) {
      _fieldErrors['nationalId'] = "National ID can only contain numbers";
      isValid = false;
    }

    // Date of Birth validation
    if (_dobController.text.trim().isEmpty) {
      _fieldErrors['dob'] = "Date of birth is required";
      isValid = false;
    }

    // Password validation
    if (_passwordController.text.trim().isEmpty) {
      _fieldErrors['password'] = "Password is required";
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      _fieldErrors['password'] = "Password must be at least 6 characters";
      isValid = false;
    }

    // Confirm Password validation
    if (_confirmPasswordController.text.trim().isEmpty) {
      _fieldErrors['confirmPassword'] = "Please confirm your password";
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _fieldErrors['confirmPassword'] = "Passwords do not match";
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();

    if (!_validateForm()) {
      return;
    }

    HapticFeedback.lightImpact();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = "$firstName $lastName".trim();

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

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthLoadingState) {
      // Don't show overlay for National ID or Username checking
      if (!_isCheckingNationalId && !_isCheckingUsername) {
        LoadingOverlay.showLoading(
          context,
          message: state.message ?? 'Creating your account...',
        );
      }
    } else if (state is RegisterSuccessState) {
      LoadingOverlay.showSuccess(
        context,
        message: 'Account created successfully!',
        onComplete: () {
          context.toSignIn(const LoginView());
          showGlobalSnackBar(
            context,
            "Registration successful. Please verify your email.",
          );
        },
      );
    } else if (state is AuthErrorState) {
      LoadingOverlay.showError(
        context,
        message: state.message,
      );
    } else if (state is ExistingFamilyMemberFound) {
      setState(() {
        _isCheckingNationalId = false;
        _prefillForm(
            state.externalMemberData, state.parentUserId, state.familyDocId);
        _clearFieldError('nationalId');
      });
    } else if (state is NationalIdCheckFailed) {
      setState(() {
        _isCheckingNationalId = false;
        // Keep _lastCheckedNationalId to prevent re-checking the same failed ID
        _fieldErrors['nationalId'] = state.message;
      });
    } else if (state is NationalIdAlreadyRegistered) {
      setState(() {
        _isCheckingNationalId = false;
        // Keep _lastCheckedNationalId to prevent re-checking the same registered ID
        _fieldErrors['nationalId'] = "This National ID is already registered";
      });
    } else if (state is NationalIdAvailable) {
      setState(() {
        _isCheckingNationalId = false;
        // Keep _lastCheckedNationalId to prevent re-checking the same valid ID
        _clearFieldError('nationalId');
      });
    } else if (state is UsernameCheckFailed) {
      setState(() {
        _isCheckingUsername = false;
        // Keep _lastCheckedUsername to prevent re-checking the same failed username
        _fieldErrors['username'] = state.message;
      });
    } else if (state is UsernameAlreadyTaken) {
      setState(() {
        _isCheckingUsername = false;
        // Keep _lastCheckedUsername to prevent re-checking the same taken username
        _fieldErrors['username'] = "This username is already taken";
      });
    } else if (state is UsernameAvailable) {
      setState(() {
        _isCheckingUsername = false;
        // Keep _lastCheckedUsername to prevent re-checking the same valid username
        _clearFieldError('username');
      });
    } else {
      LoadingOverlay.hide();
    }
  }

  void _navigateToLogin() {
    context.toSignIn(const LoginView());
  }
}
