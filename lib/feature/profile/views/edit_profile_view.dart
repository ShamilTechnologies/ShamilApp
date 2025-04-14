import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'dart:typed_data'; // For placeholder image data

// Placeholder for transparent image data (Consider moving to a constants file)
const List<int> kTransparentImage = <int>[ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, ];
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
          showGlobalSnackBar(context, "User data not available.", isError: true);
          Navigator.maybePop(context);
        }
      });
    }
  }

  // Helper to extract number part (basic implementation)
  String _extractPhoneNumber(String? fullPhone) {
     if (fullPhone == null) return '';
     // Find the likely start of the number after potential country code
     int startIndex = fullPhone.indexOf(RegExp(r'[1-9]')); // Find first non-zero digit
     if (startIndex != -1 && startIndex < 5) { // Assume code is short
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
      showGlobalSnackBar(context, "Could not get current user data.", isError: true);
      return; // Cannot save without current user data for comparison
    }

    // Compare current values with initial values and add changed fields
    final currentName = _nameController.text.trim();
    if (currentName != _initialName) {
      updatedData['name'] = currentName;
    }

    final currentFullPhone = _selectedCountryCode + _phoneController.text.trim();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Re-initialize fields if the widget rebuilds and hasn't been initialized yet
    // This handles cases where the screen might be pushed before AuthBloc is ready
    if (!_isInitialized) {
      _initializeFields();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 1, // Add slight elevation
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoginSuccessState && state.user.updatedAt.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch - 2000) {
            // Check if the state update is recent (indicating success from *this* update)
            showGlobalSnackBar(context, "Profile updated successfully!");
            // Pop back to profile screen after successful update
            Navigator.of(context).pop();
          } else if (state is AuthErrorState) {
            // Show error if update fails
            showGlobalSnackBar(context, "Failed to update profile: ${state.message}", isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;
          // Get current user data for read-only fields (handle null state gracefully)
          AuthModel? currentUser;
          if (state is LoginSuccessState) {
            currentUser = state.user;
          } else if (state is AuthLoadingState && context.read<AuthBloc>().state is LoginSuccessState) {
            // If loading, try to show previous user data
            currentUser = (context.read<AuthBloc>().state as LoginSuccessState).user;
          }


          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Picture Display (Non-editable here)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: (_profileImageUrl != null)
                        ? NetworkImage(_profileImageUrl!)
                        : null, // Use NetworkImage
                    child: (_profileImageUrl == null)
                        ? Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                const Gap(24),

                // --- Read-only Fields ---
                _buildReadOnlyField(theme, "Username", currentUser?.username),
                const Gap(16),
                _buildReadOnlyField(theme, "Email", currentUser?.email),
                const Gap(16),
                _buildReadOnlyField(theme, "National ID", currentUser?.nationalId),
                const Gap(24),
                const Divider(),
                const Gap(24),

                // --- Editable Fields ---
                Text("Editable Information", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Gap(16),

                // Full Name
                GeneralTextFormField(
                  labelText: 'Full Name*',
                  controller: _nameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(16),

                // Phone Number
                Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isLoading ? Colors.grey.shade200 : theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey)
                      ),
                      child: CountryCodePicker(
                        onChanged: (countryCode) { if (!isLoading) { setState(() { _selectedCountryCode = countryCode.dialCode ?? '+20'; }); } },
                        initialSelection: _selectedCountryCode.replaceAll('+', ''), // Initialize picker
                        favorite: const ['+20', 'EG'],
                        showCountryOnly: false, showOnlyCountryWhenClosed: false,
                        enabled: !isLoading,
                        textStyle: TextStyle(color: isLoading ? Colors.grey.shade500 : AppColors.primaryColor), // Use TextStyle directly
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                    ),
                    const Gap(10),
                    Expanded( child: GeneralTextFormField(
                      controller: _phoneController, labelText: 'Phone Number*',
                      keyboardType: TextInputType.phone, enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ), ),
                  ],
                ),
                const Gap(16),

                // Date of Birth & Gender
                Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded( child: GeneralTextFormField(
                      controller: _dobController, labelText: 'Date of Birth*',
                      readOnly: true, enabled: !isLoading,
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                      onTap: isLoading ? null : () async {
                         DateTime initial = DateTime.tryParse(_dobController.text) ?? DateTime.now().subtract(const Duration(days: 365 * 18));
                         DateTime? pickedDate = await showDatePicker( context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (context, child) { return Theme( data: Theme.of(context).copyWith( colorScheme: Theme.of(context).colorScheme.copyWith( primary: AppColors.primaryColor, ), ), child: child!, ); }, );
                         if (pickedDate != null) { _dobController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}"; }
                       },
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                     ),
                    ),
                    const Gap(10),
                    Expanded( child: GlobalDropdownFormField<String>(
                      labelText: 'Gender*',
                      items: ['Male', 'Female'].map((gender) => DropdownMenuItem( value: gender, child: Text(gender), )).toList(),
                      value: _selectedGender,
                      enabled: !isLoading,
                      onChanged: isLoading ? null : (value) { setState(() { _selectedGender = value!; }); },
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                     ),
                    ),
                  ],
                ),
                const Gap(32),

                // Save Button
                CustomButton(
                  onPressed: isLoading ? null : _handleSaveChanges,
                  text: isLoading ? "Saving..." : "Save Changes",
                ),
                const Gap(20),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Helper widget to display read-only fields consistently
  Widget _buildReadOnlyField(ThemeData theme, String label, String? value) {
    return TextFormField(
      initialValue: value ?? 'N/A', // Show N/A if value is null
      readOnly: true,
      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)), // Greyed out text
      decoration: InputDecoration(
        labelText: label,
        // Use theme decoration but maybe adjust fill color for read-only
        fillColor: theme.inputDecorationTheme.fillColor?.withOpacity(0.5) ?? Colors.grey.shade200,
        filled: true, // Ensure field is filled
        border: theme.inputDecorationTheme.border,
        enabledBorder: theme.inputDecorationTheme.enabledBorder,
        disabledBorder: theme.inputDecorationTheme.disabledBorder, // Use disabled border style
      ),
    );
  }
}

