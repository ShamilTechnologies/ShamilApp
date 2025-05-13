import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// For placeholder image data

// Placeholder for transparent image data (Consider moving to a constants file)
const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // State variables for dropdown and initial values
  String _selectedGender = 'Male'; // Default value
  String _selectedCountryCode = '+20'; // Default value

  // Store initial values to detect changes
  String _initialName = '';
  String _initialPhone = ''; // Stores full phone number including country code
  String _initialDob = '';
  String _initialGender = '';
  String? _profileImageUrl; // To display current image

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  void initState() {
    super.initState();
    // Initialize fields from AuthBloc state
    _initializeFields();
  }

  void _initializeFields() {
    final currentState = context.read<AuthBloc>().state;
    if (currentState is LoginSuccessState && !_isInitialized) {
      final user = currentState.user;

      // Initialize controllers
      _nameController.text = user.name;
      _dobController.text = user.dob ?? '';
      _selectedGender = user.gender ?? 'Male';

      // Handle phone number initialization (split country code)
      _initialPhone = user.phone ?? '';
      _phoneController.text = _extractPhoneNumber(_initialPhone);
      _selectedCountryCode = _extractCountryCode(_initialPhone) ?? '+20';

      // Store initial values for comparison
      _initialName = user.name;
      _initialDob = user.dob ?? '';
      _initialGender = user.gender ?? 'Male';

      // Store image URL for display
      _profileImageUrl = user.profilePicUrl ?? user.image;
      if (_profileImageUrl != null && _profileImageUrl!.isEmpty) {
        _profileImageUrl = null;
      }

      _isInitialized = true; // Mark as initialized
    } else if (currentState is! LoginSuccessState) {
      // Handle case where user data isn't available (e.g., navigated here improperly)
      // Maybe show an error or pop back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showGlobalSnackBar(context, "User data not available.",
              isError: true);
          Navigator.maybePop(context);
        }
      });
    }
  }

  // Helper to extract number part (basic implementation)
  String _extractPhoneNumber(String? fullPhone) {
    if (fullPhone == null) return '';
    // Find the likely start of the number after potential country code
    int startIndex =
        fullPhone.indexOf(RegExp(r'[1-9]')); // Find first non-zero digit
    if (startIndex != -1 && startIndex < 5) {
      // Assume code is short
      // More robust: Use a library or check against known codes
      if (fullPhone.startsWith('+')) {
        // Try removing common prefixes - needs improvement for global use
        if (fullPhone.startsWith('+20')) return fullPhone.substring(3).trim();
        if (fullPhone.startsWith('+966')) return fullPhone.substring(4).trim();
        // Add more codes or use a library
      }
      // Fallback if no known code found but looks like it has one
      if (fullPhone.length > 10 && !fullPhone.startsWith('0')) {
        // Heuristic: might be code + number, try removing first few chars
        // This is unreliable - better to store code separately if possible
      }
    }
    return fullPhone; // Return full number if unsure
  }

  // Helper to extract country code (basic implementation)
  String? _extractCountryCode(String? fullPhone) {
    if (fullPhone == null) return null;
    if (fullPhone.startsWith('+20')) return '+20';
    if (fullPhone.startsWith('+966')) return '+966';
    // Add more codes
    return null; // Return null if no known code found
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  /// Handles saving changes
  void _handleSaveChanges() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't proceed if form is invalid
    }

    final Map<String, dynamic> updatedData = {};
    final currentState = context.read<AuthBloc>().state;
    AuthModel? currentUser;
    if (currentState is LoginSuccessState) {
      currentUser = currentState.user;
    } else {
      showGlobalSnackBar(context, "Could not get current user data.",
          isError: true);
      return; // Cannot save without current user data for comparison
    }

    // Compare current values with initial values and add changed fields
    final currentName = _nameController.text.trim();
    if (currentName != _initialName) {
      updatedData['name'] = currentName;
    }

    final currentFullPhone =
        _selectedCountryCode + _phoneController.text.trim();
    if (currentFullPhone != _initialPhone) {
      updatedData['phone'] = currentFullPhone;
    }

    final currentDob = _dobController.text.trim();
    if (currentDob != _initialDob) {
      updatedData['dob'] = currentDob;
    }

    if (_selectedGender != _initialGender) {
      updatedData['gender'] = _selectedGender;
    }

    // Check if any data actually changed
    if (updatedData.isEmpty) {
      showGlobalSnackBar(context, "No changes made.");
      return;
    }

    // Dispatch update event
    print("Dispatching UpdateUserProfile with data: $updatedData");
    context.read<AuthBloc>().add(UpdateUserProfile(updatedData: updatedData));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initial = DateTime.tryParse(_dobController.text) ??
        DateTime.now().subtract(const Duration(days: 365 * 18));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-initialize fields if the widget rebuilds and hasn't been initialized yet
    if (!_isInitialized) {
      _initializeFields();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoginSuccessState &&
              state.user.updatedAt?.millisecondsSinceEpoch != null &&
              state.user.updatedAt!.millisecondsSinceEpoch >
                  DateTime.now().millisecondsSinceEpoch - 2000) {
            // Check if the state update is recent (indicating success from *this* update)
            showGlobalSnackBar(context, "Profile updated successfully!");
            // Pop back to profile screen after successful update
            Navigator.of(context).pop();
          } else if (state is AuthErrorState) {
            // Show error if update fails
            showGlobalSnackBar(
                context, "Failed to update profile: ${state.message}",
                isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;
          // Get current user data for read-only fields (handle null state gracefully)
          AuthModel? currentUser;
          if (state is LoginSuccessState) {
            currentUser = state.user;
          } else if (state is AuthLoadingState &&
              context.read<AuthBloc>().state is LoginSuccessState) {
            // If loading, try to show previous user data
            currentUser =
                (context.read<AuthBloc>().state as LoginSuccessState).user;
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(isLoading),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile pic and user info
                        _buildProfileInfo(currentUser, isLoading),
                        const Gap(20),

                        // Read-only section
                        _buildReadOnlyCard(currentUser),
                        const Gap(20),

                        // Editable section
                        _buildEditableForm(isLoading),
                        const Gap(32),

                        // Save button
                        CustomButton(
                          onPressed: isLoading ? null : _handleSaveChanges,
                          text: isLoading ? "Saving..." : "Save Changes",
                        ),
                        const Gap(30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(bool isLoading) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              CupertinoIcons.pencil,
                              color: AppColors.primaryColor,
                              size: 26,
                            ),
                          ),
                          const Gap(14),
                          Text(
                            'Edit Profile',
                            style: AppTextStyle.getHeadlineTextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : IconButton(
                                onPressed: _handleSaveChanges,
                                icon: const Icon(
                                  CupertinoIcons.check_mark,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Text(
                    isLoading
                        ? 'Saving your changes...'
                        : 'Update your personal information',
                    style: AppTextStyle.getbodyStyle(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(AuthModel? user, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        AppColors.primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (_profileImageUrl == null ||
                            _profileImageUrl!.isEmpty)
                        ? Icon(
                            CupertinoIcons.person_fill,
                            size: 60,
                            color: AppColors.primaryColor.withOpacity(0.5),
                          )
                        : FadeInImage.memoryNetwork(
                            placeholder: _transparentImageData,
                            image: _profileImageUrl!,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                Icon(
                              CupertinoIcons.person_fill,
                              size: 60,
                              color: AppColors.primaryColor.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),

                // Edit photo hint
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // User name
          if (user != null)
            Text(
              user.name,
              style: AppTextStyle.getTitleStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Gap(4),

          // User email
          if (user != null)
            Text(
              user.email,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
            ),

          // Phone display if available
          if (user != null && user.phone != null && user.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.phone_fill,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  const Gap(6),
                  Text(
                    user.phone!,
                    style: AppTextStyle.getbodyStyle(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyCard(AuthModel? user) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Information",
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),
          _buildInfoRow(
            CupertinoIcons.person,
            'Username',
            user.username ?? 'Not set',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            CupertinoIcons.mail,
            'Email',
            user.email,
          ),
          if (user.nationalId != null && user.nationalId!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              CupertinoIcons.creditcard,
              'National ID',
              user.nationalId!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                ),
              ),
              const Gap(2),
              Text(
                value,
                style: AppTextStyle.getbodyStyle(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableForm(bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),

          // Full Name
          GeneralTextFormField(
            labelText: 'Full Name',
            controller: _nameController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(CupertinoIcons.person, size: 20),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const Gap(16),

          // Phone Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: isLoading
                        ? Colors.grey.shade200
                        : Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                                .inputDecorationTheme
                                .enabledBorder
                                ?.borderSide
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
                  initialSelection: _selectedCountryCode.replaceAll(
                      '+', ''), // Initialize picker
                  favorite: const ['+20', 'EG'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  enabled: !isLoading,
                  textStyle: TextStyle(
                      color: isLoading
                          ? Colors.grey.shade500
                          : AppColors.primaryColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
              ),
              const Gap(10),
              Expanded(
                child: GeneralTextFormField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  prefixIcon: const Icon(CupertinoIcons.phone, size: 20),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Date of Birth & Gender
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GeneralTextFormField(
                  controller: _dobController,
                  labelText: 'Date of Birth',
                  readOnly: true,
                  enabled: !isLoading,
                  prefixIcon: const Icon(CupertinoIcons.calendar, size: 18),
                  onTap: isLoading ? null : () => _selectDate(context),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
              ),
              const Gap(10),
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
                  enabled: !isLoading,
                  onChanged: isLoading
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
        ],
      ),
    );
  }
}
