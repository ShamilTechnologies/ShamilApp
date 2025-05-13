// lib/feature/social/views/add_family_member_view.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

class AddFamilyMemberView extends StatefulWidget {
  const AddFamilyMemberView({super.key});

  @override
  State<AddFamilyMemberView> createState() => _AddFamilyMemberViewState();
}

class _AddFamilyMemberViewState extends State<AddFamilyMemberView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _dobController = TextEditingController();
  final _searchNationalIdController = TextEditingController();

  String? _selectedRelationship;
  String? _selectedGender;
  DateTime? _selectedDob;

  AuthModel? _linkedUserModel;
  bool _isCheckingId = false;
  bool _isSubmitting = false;

  final List<String> _relationships = [
    'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister',
    'Grandfather', 'Grandmother', 'Grandson', 'Granddaughter',
    'Uncle', 'Aunt', 'Nephew', 'Niece', 'Cousin', 'Other'
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _dobController.dispose();
    _searchNationalIdController.dispose();
    super.dispose();
  }

  void _resetFormFields({bool clearLinkedUser = true, bool keepSearchId = false}) {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _nationalIdController.clear();
    _dobController.clear();
    _selectedDob = null;
    setStateIfMounted(() {
      _selectedRelationship = null;
      _selectedGender = null;
      if (clearLinkedUser) {
        _linkedUserModel = null;
        if (!keepSearchId) {
          _searchNationalIdController.clear();
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_linkedUserModel != null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.primaryText,
                ),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setStateIfMounted(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _performNationalIdCheck() {
    if (_searchNationalIdController.text.trim().isEmpty) {
      showGlobalSnackBar(context, "Please enter a National ID to check.", isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setStateIfMounted(() {
      _isCheckingId = true;
      _linkedUserModel = null;
      _resetFormFields(clearLinkedUser: false, keepSearchId: true);
    });
    context.read<SocialBloc>().add(SearchUserByNationalId(nationalId: _searchNationalIdController.text.trim()));
  }

  void _submitFamilyMemberData() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showGlobalSnackBar(context, "Please correct the errors in the form.", isError: true);
      return;
    }

    if (_selectedRelationship == null) {
      showGlobalSnackBar(context, "Please select the relationship.", isError: true);
      return;
    }

    setStateIfMounted(() => _isSubmitting = true);

    final memberData = {
      'name': _nameController.text.trim(),
      'relationship': _selectedRelationship!,
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      'gender': _selectedGender,
      'nationalId': _linkedUserModel != null
          ? _linkedUserModel!.nationalId
          : (_nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null),
      'dob': _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null,
    };

    context.read<SocialBloc>().add(AddFamilyMember(
          memberData: memberData,
          linkedUserModel: _linkedUserModel,
        ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: app_text_style.getbodyStyle(color: AppColors.secondaryText.withOpacity(0.8)),
          prefixIcon: Icon(icon, color: AppColors.primaryColor.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), // Use 8 radius
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)), // Use 8 radius
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)), // Use 8 radius
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.2)), // Use 8 radius
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)), // Use 8 radius
          filled: !enabled,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        style: app_text_style.getbodyStyle(color: enabled ? AppColors.primaryText : AppColors.secondaryText.withOpacity(0.7)),
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        onTap: onTap,
        readOnly: readOnly,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: app_text_style.getbodyStyle(color: AppColors.secondaryText.withOpacity(0.8)),
          prefixIcon: Icon(icon, color: AppColors.primaryColor.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), // Use 8 radius
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)), // Use 8 radius
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)), // Use 8 radius
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.2)), // Use 8 radius
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)), // Use 8 radius
          filled: !enabled,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        value: value,
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString(), style: app_text_style.getbodyStyle()))).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
        disabledHint: value != null ? Text(value.toString(), style: app_text_style.getbodyStyle(color: AppColors.secondaryText.withOpacity(0.7))) : null,
        style: app_text_style.getbodyStyle(color: AppColors.primaryText),
        icon: Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primaryColor.withOpacity(0.7)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Family Member', style: app_text_style.getTitleStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: BlocListener<SocialBloc, SocialState>(
        listener: (context, state) {
          setStateIfMounted(() {
            if (state is SocialLoading) {
              if (state.processingUserId == null && !state.isLoadingList && !_isCheckingId) {
                _isSubmitting = true;
              }
            } else {
              if (_isCheckingId && state is! UserNationalIdSearchResult) {
                 _isCheckingId = false;
              }
               if (_isSubmitting) {
                _isSubmitting = false;
              }
            }
          });

          if (state is UserNationalIdSearchResult) {
            setStateIfMounted(() => _isCheckingId = false);
            if (state.foundUser != null) {
              _linkedUserModel = state.foundUser;
              _nameController.text = _linkedUserModel!.name;
              _phoneController.text = _linkedUserModel!.phone ?? '';
              _emailController.text = _linkedUserModel!.email;
              _nationalIdController.text = _linkedUserModel!.nationalId ?? '';
              _selectedGender = _linkedUserModel!.gender;
              if (_linkedUserModel!.dob != null && _linkedUserModel!.dob!.isNotEmpty) {
                try {
                  _selectedDob = DateFormat('yyyy-MM-dd').parse(_linkedUserModel!.dob!);
                  _dobController.text = DateFormat('yyyy-MM-dd').format(_selectedDob!);
                } catch (e) { _selectedDob = null; _dobController.clear(); }
              } else { _selectedDob = null; _dobController.clear(); }
              showGlobalSnackBar(context, "User found: ${_linkedUserModel!.name}. Details pre-filled. Select relationship to proceed.", isError: false);
            } else if (state.searchedNationalId.isNotEmpty) {
              showGlobalSnackBar(context, "No app user found with this National ID. You can add their details manually below.", isError: false);
               _resetFormFields(clearLinkedUser: true, keepSearchId: true);
            }
          } else if (state is SocialSuccess) {
            showGlobalSnackBar(context, state.message, isError: false);
            _resetFormFields(clearLinkedUser: true, keepSearchId: false);
          } else if (state is SocialError) {
            showGlobalSnackBar(context, state.message, isError: true);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(theme, "Link Existing User (Optional)"),
                const Gap(4),
                Text(
                  "If your family member already uses the app, enter their National ID to link them quickly. Otherwise, skip this and add their details manually below.",
                  style: app_text_style.getSmallStyle(color: AppColors.secondaryText.withOpacity(0.9)),
                ),
                const Gap(12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _searchNationalIdController,
                        label: "Member's National ID",
                        icon: Icons.search_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Gap(10),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        height: 52,
                        child: CustomButton(
                          text: _isCheckingId ? "..." : "Check",
                          onPressed: _isCheckingId ? null : _performNationalIdCheck,
                          color: AppColors.secondaryColor,
                          radius: 8, // Use 8 radius
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: app_text_style.getButtonStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_isCheckingId)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(child: CupertinoActivityIndicator(radius: 12)),
                  ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child));
                  },
                  child: _linkedUserModel != null
                      ? Card(
                          key: ValueKey(_linkedUserModel!.uid),
                          elevation: 2,
                          margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Use 8 radius
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                buildProfilePlaceholder( // Corrected call
                                  imageUrl: _linkedUserModel!.profilePicUrl ?? _linkedUserModel!.image,
                                  name: _linkedUserModel!.name,
                                  size: 50.0,
                                  borderRadius: BorderRadius.circular(8.0), // Use 8 radius
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_linkedUserModel!.name, style: app_text_style.getTitleStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                      Text("@${_linkedUserModel!.username}", style: app_text_style.getSmallStyle(color: AppColors.secondaryText)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700, size: 28),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const Gap(12),
                const Divider(thickness: 0.8, height: 30),
                _buildSectionTitle(theme, _linkedUserModel == null ? "Add Member Details Manually" : "Confirm Relationship & Details"),
                const Gap(10),

                _buildTextField(
                  controller: _nameController,
                  label: "Full Name*",
                  icon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                  enabled: _linkedUserModel == null,
                ),
                _buildDropdownField<String>(
                  label: "Relationship to You*",
                  icon: Icons.family_restroom_outlined,
                  value: _selectedRelationship,
                  items: _relationships,
                  onChanged: (value) => setStateIfMounted(() => _selectedRelationship = value),
                  validator: (value) => value == null ? 'Please select a relationship' : null,
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: _linkedUserModel == null,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _linkedUserModel == null,
                   validator: (value) {
                    if (value != null && value.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                 _buildTextField(
                  controller: _dobController,
                  label: "Date of Birth",
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  enabled: _linkedUserModel == null,
                ),
                _buildDropdownField<String>(
                  label: "Gender",
                  icon: Icons.wc_outlined,
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (value) => setStateIfMounted(() => _selectedGender = value),
                  enabled: _linkedUserModel == null,
                ),
                _buildTextField(
                  controller: _nationalIdController,
                  label: "National ID",
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  enabled: _linkedUserModel == null,
                ),

                const Gap(30),
                CustomButton(
                  text: _isSubmitting
                      ? "Saving..."
                      : (_linkedUserModel != null ? "Send Link Request" : "Add Family Member"),
                  onPressed: _isSubmitting ? null : _submitFamilyMemberData,
                  height: 52,
                  radius: 8, // Use 8 radius
                ),
                if (_linkedUserModel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () {
                        setStateIfMounted(() {
                           _resetFormFields(clearLinkedUser: true, keepSearchId: false);
                        });
                      },
                      child: Text("Clear and Add Manually Instead", style: app_text_style.getbodyStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
      child: Text(
        title,
        style: app_text_style.getTitleStyle(color: AppColors.primaryColor, fontSize: 19, fontWeight: FontWeight.w600),
      ),
    );
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
