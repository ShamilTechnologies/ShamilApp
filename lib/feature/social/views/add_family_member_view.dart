import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for InputFormatters
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // Import SocialBloc
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // For feedback
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // Import AuthModel
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Import AppColors

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
  final _dobController = TextEditingController(); // Add controller for DOB

  String? _selectedRelationship;
  String? _selectedGender;

  bool _isCheckingId = false;
  AuthModel? _linkedUserModel;
  String? _idCheckMessage;

  final List<String> _relationshipOptions = [ 'Mother', 'Father', 'Sibling', 'Spouse', 'Child', 'Grandparent', 'Other' ];
  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _dobController.dispose(); // Dispose DOB controller
    super.dispose();
  }

  Future<void> _checkNationalId() async {
    if (_nationalIdController.text.trim().length != 14) {
       setState(() { _idCheckMessage = "Please enter a valid 14-digit ID."; });
       return;
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isCheckingId = true;
      _linkedUserModel = null;
      // Clear fields before check
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _dobController.clear();
      _selectedGender = null;
      _idCheckMessage = null;
    });
    context.read<SocialBloc>().add(SearchUserByNationalId(nationalId: _nationalIdController.text.trim()));
  }

  void _addMember(bool isBlocLoading) {
    if (isBlocLoading || _isCheckingId) return;
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final memberData = {
        'name': _nameController.text.trim(),
        'relationship': _selectedRelationship,
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'gender': _selectedGender,
        'nationalId': _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        'dob': _dobController.text.trim().isEmpty ? null : _dobController.text.trim(), // Add DOB
      };
      context.read<SocialBloc>().add(AddFamilyMember(memberData: memberData, linkedUserModel: _linkedUserModel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine if fields should be enabled based on linking status
    final bool canEditDetails = _linkedUserModel == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Family Member')),
      body: MultiBlocListener(
        listeners: [
           BlocListener<SocialBloc, SocialState>(
             listenWhen: (prev, current) => current is SocialSuccess || current is SocialError,
             listener: (context, state) { /* ... Listener logic for Success/Error ... */
                if (state is SocialSuccess) {
                  showGlobalSnackBar(context, state.message);
                  Navigator.of(context).pop();
               } else if (state is SocialError) {
                  // Stop loading indicator if error occurs during ID check
                  if (_isCheckingId) setState(() { _isCheckingId = false; });

                  if (state.message.contains("index missing for user search")) {
                     _idCheckMessage = "Error: ${state.message}";
                     setState(() {}); // Update UI to show message
                  } else if (state.message.contains("add yourself")) {
                     _idCheckMessage = state.message;
                     setState(() {}); // Update UI to show message
                  } else { showGlobalSnackBar(context, state.message, isError: true); }
               }
              },
           ),
           BlocListener<SocialBloc, SocialState>(
              listenWhen: (prev, current) => current is UserSearchResult,
              listener: (context, state) {
                  setState(() { _isCheckingId = false; }); // Stop ID check loading indicator
                  if (state is UserSearchResult) {
                     if (state.foundUser != null) {
                        // User found - prefill and disable fields
                        setState(() {
                           _linkedUserModel = state.foundUser;
                           _nameController.text = state.foundUser!.name;
                           // *** Prefill phone, email, dob ***
                           _phoneController.text = state.foundUser!.phone;
                           _emailController.text = state.foundUser!.email;
                           _dobController.text = state.foundUser!.dob; // Assuming dob is String YYYY-MM-DD

                           if (_genderOptions.contains(state.foundUser!.gender)) {
                              _selectedGender = state.foundUser!.gender;
                           } else { _selectedGender = null; }
                           _idCheckMessage = "App user found: ${state.foundUser!.name}";
                        });
                        showGlobalSnackBar(context, "App user found and linked!");
                     } else {
                         // User not found or user tried linking self
                         setState(() {
                           _linkedUserModel = null;
                           // Show message only if ID was actually searched and not found
                           if (state is! SocialError) { _idCheckMessage = "No app user found with this ID."; }
                           // Clear potentially prefilled fields
                           _nameController.clear();
                           _phoneController.clear(); // Clear phone
                           _emailController.clear(); // Clear email
                           _dobController.clear(); // Clear dob
                           _selectedGender = null;
                         });
                     }
                  }
              },
           ),
        ],
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling
            padding: const EdgeInsets.all(20.0),
            children: [
              // National ID Field + Check Button
              Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Expanded(
                       child: GeneralTextFormField(
                         controller: _nationalIdController, labelText: 'National ID (Optional)',
                         hintText: 'Enter 14-digit ID to link app user', keyboardType: TextInputType.number,
                         inputFormatters: [ FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14) ],
                         enabled: !_isCheckingId,
                         validator: (value) { if (value != null && value.isNotEmpty && value.length != 14) { return 'Must be 14 digits if entered'; } return null; },
                         textInputAction: TextInputAction.next,
                       ),
                    ),
                    const SizedBox(width: 8),
                    // *** FIX: Use TextButton instead of ElevatedButton ***
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0), // Adjust padding if needed
                        child: TextButton( // Changed to TextButton
                           onPressed: _isCheckingId ? null : _checkNationalId,
                           style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), // Match height roughly
                           ),
                           child: _isCheckingId
                             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                             : Text('Check ID', style: TextStyle(color: theme.colorScheme.primary)), // Style as needed
                        ),
                      ),
                    )
                 ],
              ),
              // Display ID check message/result
              if (_idCheckMessage != null)
                 Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text( _idCheckMessage!, style: TextStyle(color: _linkedUserModel != null ? Colors.green.shade700 : Colors.orange.shade900, fontSize: 12), ),
                 ),
              const SizedBox(height: 16),

              // Name Field
              GeneralTextFormField(
                controller: _nameController, labelText: 'Full Name*',
                enabled: canEditDetails && !_isCheckingId, // *** Disable if linked ***
                validator: (value) => (canEditDetails && (value == null || value.trim().isEmpty)) ? 'Name is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Relationship Dropdown
              GlobalDropdownFormField<String>(
                 labelText: 'Relationship*', hintText: 'Select Relationship',
                 items: _relationshipOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                 value: _selectedRelationship, enabled: !_isCheckingId, // Always enabled unless checking ID
                 onChanged: (value) { setState(() { _selectedRelationship = value; }); },
                 validator: (value) => (value == null) ? 'Relationship is required' : null,
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
               GlobalDropdownFormField<String>(
                 labelText: 'Gender*', hintText: 'Select Gender',
                 items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                 value: _selectedGender,
                 enabled: canEditDetails && !_isCheckingId, // *** Disable if linked ***
                 onChanged: (value) { setState(() { _selectedGender = value; }); },
                 validator: (value) => (canEditDetails && value == null) ? 'Gender is required' : null,
               ),
              const SizedBox(height: 16),

              // DOB Field
              GeneralTextFormField(
                controller: _dobController, labelText: 'Date of Birth',
                readOnly: true, // Always readOnly, use onTap
                enabled: canEditDetails && !_isCheckingId, // *** Disable if linked ***
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: (canEditDetails && !_isCheckingId) ? () async { // Disable tap if linked or checking
                  DateTime? pickedDate = await showDatePicker( context: context, initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (context, child) { return Theme( data: Theme.of(context).copyWith( colorScheme: Theme.of(context).colorScheme.copyWith( primary: AppColors.primaryColor, ), ), child: child!, ); }, );
                  if (pickedDate != null) { _dobController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}"; }
                } : null, // Disable onTap
                validator: (value) => (canEditDetails && (value == null || value.isEmpty)) ? 'DOB Required' : null, // Validate only if not linked
              ),
              const SizedBox(height: 16),

              // Phone Field
               GeneralTextFormField(
                 controller: _phoneController, labelText: 'Phone Number (Optional)',
                 keyboardType: TextInputType.phone, validator: null,
                 enabled: canEditDetails && !_isCheckingId, // *** Disable if linked ***
                 textInputAction: TextInputAction.next,
               ),
              const SizedBox(height: 16),

              // Email Field
               GeneralTextFormField(
                 controller: _emailController, labelText: 'Email (Optional)',
                 keyboardType: TextInputType.emailAddress, validator: null,
                 enabled: canEditDetails && !_isCheckingId, // *** Disable if linked ***
                 textInputAction: TextInputAction.done,
               ),
              const SizedBox(height: 30),

              // Add Member Button
              BlocBuilder<SocialBloc, SocialState>(
                 builder: (context, state) {
                    final isAdding = state is SocialLoading && !state.isLoadingList;
                    return CustomButton(
                       onPressed: isAdding || _isCheckingId ? null : () => _addMember(isAdding),
                       text: isAdding ? 'Adding...' : 'Add Member',
                    );
                 },
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
