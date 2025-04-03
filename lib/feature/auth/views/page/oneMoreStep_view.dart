import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart'; // Use Gap
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/navigation/main_navigation_view.dart';
// Import LoginSuccessAnimationView
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
// Import AuthModel to access user data from state
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';


// --- ModernUploadField Widget (Updated) ---
// This widget provides a styled area for users to tap and upload an image,
// showing a preview or icon based on the state.
class ModernUploadField extends StatelessWidget {
  final String title;
  final String description;
  final File? file; // The selected image file (if any)
  final VoidCallback onTap; // Action to trigger when tapped
  final bool isLoading; // Flag to disable interaction during loading

  const ModernUploadField({
    super.key,
    required this.title,
    required this.description,
    required this.file,
    required this.onTap,
    this.isLoading = false, // Default to not loading
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasFile = file != null; // Check if a file has been selected

    return Material( // Use Material for InkWell splash effect
      color: Colors.transparent,
      child: InkWell( // Use InkWell for ripple effect on tap
        onTap: isLoading ? null : onTap, // Disable tap when loading
        borderRadius: BorderRadius.circular(12), // Match border radius for tap effect
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: AnimatedOpacity( // Fade the widget slightly if disabled
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.5 : 1.0,
          child: Container( // Removed AnimatedContainer, decoration changes instantly
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Adjust padding
            constraints: const BoxConstraints(minHeight: 120), // Set min height
            decoration: BoxDecoration(
              // Use theme's fill color or a fallback accent color
              color: theme.inputDecorationTheme.fillColor ?? AppColors.accentColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              // Change border based on whether a file is selected
              border: Border.all(
                color: hasFile
                    ? Colors.green.shade400 // Brighter green border if file selected
                    : (theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? AppColors.secondaryColor.withOpacity(0.3)),
                width: hasFile ? 1.5 : 1.0,
              ),
               // Add subtle shadow when file selected for emphasis
               boxShadow: hasFile ? [
                  BoxShadow( color: Colors.green.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)
               ] : [],
            ),
            child: Row(
              children: [
                // Animated Icon Container (changes background and icon)
                AnimatedContainer(
                   duration: const Duration(milliseconds: 300),
                   width: 50, height: 50,
                   decoration: BoxDecoration(
                     color: hasFile ? Colors.green.withOpacity(0.15) : AppColors.accentColor.withOpacity(0.2),
                     shape: BoxShape.circle, // Circular background for icon
                   ),
                   child: Icon(
                      // Show checkmark if file exists, upload icon otherwise
                      hasFile ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                      size: 28,
                      color: hasFile ? Colors.green.shade700 : AppColors.primaryColor.withOpacity(0.8),
                   ),
                 ),
                const Gap(16), // Use Gap
                // Text content (Title and Description)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text( title, style: theme.textTheme.titleMedium?.copyWith( color: AppColors.primaryColor, fontWeight: FontWeight.w600, ), ),
                      const Gap(6),
                      Text( description, style: theme.textTheme.bodyMedium?.copyWith( color: AppColors.secondaryColor, fontSize: 13, ), ),
                    ],
                  ),
                ),
                const Gap(10), // Spacing
                // Image Preview Area (animates presence)
                AnimatedSwitcher(
                   duration: const Duration(milliseconds: 400),
                   transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                   child: file != null
                    // Show image preview if file exists
                    ? ClipRRect( key: ValueKey(file!.path), borderRadius: BorderRadius.circular(8),
                        child: Image.file( file!, width: 70, height: 70, fit: BoxFit.cover, ),
                      )
                    // Otherwise, show a sized container as placeholder
                    : Container(key: const ValueKey('no_image'), width: 70, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- End ModernUploadField Widget ---


/// OneMoreStepScreen: Handles profile picture selection and ID scanning.
class OneMoreStepScreen extends StatefulWidget {
  const OneMoreStepScreen({super.key});
  @override State<OneMoreStepScreen> createState() => _OneMoreStepScreenState();
}

class _OneMoreStepScreenState extends State<OneMoreStepScreen> with TickerProviderStateMixin {
  // State variables to hold selected image files
  File? _profilePic;
  File? _idFront;
  File? _idBack;
  // Tracks the current step in the process (0: Pic, 1: ID Front, 2: ID Back)
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker(); // Instance of image picker

  // Animation controller for fade-in effect
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize and start fade-in animation
    _fadeController = AnimationController( vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose(); // Dispose animation controller
    super.dispose();
  }

  /// Shows a themed bottom sheet to select image source (Camera or Gallery).
  Future<ImageSource?> _showImageSourceSelector() async {
     return showModalBottomSheet<ImageSource>(
      context: context, backgroundColor: Colors.transparent, // Make sheet background transparent
      builder: (BuildContext context) {
        // Build the content of the bottom sheet
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.white, // White background
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
            boxShadow: const [ BoxShadow( color: Colors.black26, blurRadius: 10, offset: Offset(0, 5), ), ], // Subtle shadow
          ),
          child: Column( mainAxisSize: MainAxisSize.min, children: [
              Text( 'Choose Image Source', style: getbodyStyle( color: AppColors.primaryColor, fontSize: 18, fontWeight: FontWeight.bold, ), ),
              const Gap(15), // Spacing
              ListTile( leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryColor), title: Text('Camera', style: getbodyStyle(color: AppColors.primaryColor)), onTap: () => Navigator.of(context).pop(ImageSource.camera), ),
              const Divider(height: 1), // Separator
              ListTile( leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryColor), title: Text('Gallery', style: getbodyStyle(color: AppColors.primaryColor)), onTap: () => Navigator.of(context).pop(ImageSource.gallery), ),
            ],
          ),
        );
       }
    );
   }

  /// Picks an image using the selected source and updates the state.
  Future<void> _pickImage(int forStep) async {
    final source = await _showImageSourceSelector(); // Show source selector
    if (source == null) return; // Exit if user cancelled

    try {
       // Use image_picker to get the image
       final pickedImage = await _picker.pickImage( source: source, imageQuality: 80, maxWidth: 1024, );
       // If an image was picked and the widget is still mounted
       if (pickedImage != null && mounted) {
         setState(() {
           // Update the correct file variable based on the current step
           if (forStep == 0) {
             _profilePic = File(pickedImage.path);
           } else if (forStep == 1) _idFront = File(pickedImage.path);
           else if (forStep == 2) _idBack = File(pickedImage.path);
         });
       } else if (pickedImage == null) {
         // Show feedback if selection was cancelled
         showGlobalSnackBar(context, "Image selection cancelled.");
       }
    } catch (e) {
       // Handle potential errors during image picking
       print("Error picking image: $e");
       showGlobalSnackBar(context, "Error picking image: ${e.toString()}", isError: true);
    }
  }

  /// Dispatches the UploadIdEvent to AuthBloc with the selected files.
  void _uploadFiles() {
    // Ensure all files have been selected
    if (_profilePic != null && _idFront != null && _idBack != null) {
      try {
         // Dispatch the event using context.read (assumes AuthBloc provided above)
         context.read<AuthBloc>().add( UploadIdEvent( profilePic: _profilePic!, idFront: _idFront!, idBack: _idBack!, ), );
      } catch(e) {
         // Handle error if Bloc is not found (shouldn't happen if provided correctly)
         print("Error accessing AuthBloc: $e");
         showGlobalSnackBar(context, "An error occurred. Could not start upload.", isError: true);
      }
    } else {
       // This validation is mostly handled by the _continue button logic
       showGlobalSnackBar(context, "Please select all required images.", isError: true);
    }
  }

  /// Handles the 'Continue' or 'Finish' button press.
  void _continue(bool isLoading) {
    if (isLoading) return; // Prevent action if already loading

    // Check which step we are on and validate the required file
    if (_currentStep == 0) {
      if (_profilePic == null) { showGlobalSnackBar(context, "Please upload your profile picture."); return; }
      setState(() => _currentStep = 1); // Move to next step
    } else if (_currentStep == 1) {
      if (_idFront == null) { showGlobalSnackBar(context, "Please upload the front of your ID."); return; }
      setState(() => _currentStep = 2); // Move to next step
    } else if (_currentStep == 2) {
      if (_idBack == null) { showGlobalSnackBar(context, "Please upload the back of your ID."); return; }
      _uploadFiles(); // All files selected, trigger the upload event
    }
  }

  /// Handles the 'Back' button press.
  void _back(bool isLoading) {
     if (isLoading) return; // Prevent action if already loading
    if (_currentStep > 0) {
      setState(() { _currentStep -= 1; }); // Decrement step index
    }
  }

  /// Handles the 'Skip for now' button press.
  void _skip(bool isLoading) {
     if (isLoading) return; // Prevent action if already loading
    // Navigate to the main navigation view, replacing the current route
    pushReplacement(context, const MainNavigationView());
  }

  /// Builds the icon for a specific step in the stepper.
  Widget _buildStepIcon(int step, bool isActive, ThemeData theme) {
    IconData iconData;
    switch (step) { // Assign icons based on step index
      case 0: iconData = Icons.person_outline_rounded; break;
      case 1: iconData = Icons.badge_outlined; break;
      case 2: iconData = Icons.document_scanner_outlined; break;
      default: iconData = Icons.info_outline;
    }
    bool isCompleted = step < _currentStep; // Show checkmark for completed steps
    if (isCompleted) { iconData = Icons.check_circle_rounded; }
    return Icon( iconData, color: isActive ? Colors.white : theme.colorScheme.primary, size: 20);
  }

  /// Builds the horizontal stepper widget with animated transitions.
  Widget _buildCustomStepper(ThemeData theme) {
    List<Widget> indicators = [];
    for (int i = 0; i < 3; i++) { // Loop through the 3 steps
      bool isCompleted = i < _currentStep; bool isCurrent = i == _currentStep; bool isActive = isCompleted || isCurrent;
      Widget circle = AnimatedContainer( // Animated circle for the step indicator
        duration: const Duration(milliseconds: 300), width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? theme.colorScheme.primary : theme.scaffoldBackgroundColor, // Animate background color
          border: Border.all( color: isActive ? theme.colorScheme.primary : Colors.grey.shade400, width: 1.5 ), // Animate border color
          boxShadow: isActive ? [ BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 5, spreadRadius: 1) ] : [], // Add shadow to active step
        ),
        child: Center(child: _buildStepIcon(i, isActive, theme)), // Display the step icon
      );
      indicators.add(circle);
      if (i < 2) { // Add animated connecting line between steps
        indicators.add( Expanded( child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), height: 2, margin: const EdgeInsets.symmetric(horizontal: 4.0),
              color: i < _currentStep ? theme.colorScheme.primary : Colors.grey.shade300, // Animate line color
            ),
          ),
        );
      }
    }
    return Padding( padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Row(children: indicators), ); // Return the indicators in a Row
  }

  /// Builds the main content area (the upload field) for the current step.
  Widget _buildCurrentStepContent(bool isLoading, ThemeData theme) {
    // Use AnimatedSwitcher for smooth transition between step content
    return AnimatedSwitcher(
       duration: const Duration(milliseconds: 400),
       transitionBuilder: (child, animation) {
          // Define slide-in animation
          final offsetAnimation = Tween<Offset>( begin: const Offset(1.0, 0.0), end: Offset.zero ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition( opacity: animation, child: SlideTransition(position: offsetAnimation, child: child), ); // Combine Fade and Slide
       },
       child: Container( // Use Key based on the current step for AnimatedSwitcher
          key: ValueKey<int>(_currentStep),
          child: Column( children: [
              const Gap(10),
              Text( // Display title for the current step
                 _currentStep == 0 ? "Upload Profile Picture" : (_currentStep == 1 ? "Upload ID Front" : "Upload ID Back"),
                 style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(15),
              // Display the appropriate ModernUploadField based on the current step
              if (_currentStep == 0) ModernUploadField( title: "Profile Picture", description: "Tap to capture or select a headshot.", file: _profilePic, onTap: () => _pickImage(0), isLoading: isLoading, )
              else if (_currentStep == 1) ModernUploadField( title: "ID Front", description: "Tap to upload the front of your ID.", file: _idFront, onTap: () => _pickImage(1), isLoading: isLoading, )
              else ModernUploadField( title: "ID Back", description: "Tap to upload the back of your ID.", file: _idBack, onTap: () => _pickImage(2), isLoading: isLoading, ),
             ],
          ),
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
    // Listen for Bloc state changes for navigation and feedback
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation and snackbars based on Bloc state
        if (state is UploadIdSuccessState) {
          showGlobalSnackBar(context, "Documents uploaded successfully!");
          // Extract data needed for animation screen from the state
          final userModel = state.user;
          String? firstName;
          if (userModel.name.isNotEmpty) { firstName = userModel.name.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => ''); }
          String? profileUrl = userModel.profilePicUrl ?? userModel.image;
          // Navigate to LoginSuccessAnimationView
          pushReplacement(context, LoginSuccessAnimationView( profilePicUrl: profileUrl, firstName: firstName, ));
        } else if (state is AuthErrorState) {
          // Show error message if upload fails
          showGlobalSnackBar(context, state.message, isError: true);
        }
      },
      // Build UI based on Bloc state (primarily for loading state)
      child: BlocBuilder<AuthBloc, AuthState>(
         builder: (context, state) {
            // Determine if an upload operation is in progress
            final isLoading = state is AuthLoadingState;

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar( title: const Text("Complete Your Profile"), elevation: 0.5, backgroundColor: theme.appBarTheme.backgroundColor, foregroundColor: theme.appBarTheme.foregroundColor, ),
              body: SafeArea(
                child: FadeTransition( // Apply fade-in to the whole body
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      children: [
                        const Gap(20),
                        _buildCustomStepper(theme), // Display stepper
                        const Gap(30),
                        Expanded( child: _buildCurrentStepContent(isLoading, theme) ), // Display upload field
                        const Gap(20),
                        Row( children: [ // Action buttons
                            if (_currentStep > 0) Expanded( flex: 1, child: TextButton( onPressed: isLoading ? null : () => _back(isLoading), child: Text("Back", style: getbodyStyle(color: AppColors.secondaryColor)), ), ),
                            if (_currentStep > 0) const Gap(10),
                            Expanded( flex: 2, child: CustomButton( onPressed: isLoading ? null : () => _continue(isLoading), text: isLoading ? "Uploading..." : (_currentStep == 2 ? "Finish" : "Continue"), ), ),
                          ],
                        ),
                         const Gap(10), // Space below buttons
                      ],
                    ),
                  ),
                ),
              ),
              // Skip button at the bottom
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: TextButton(
                  onPressed: isLoading ? null : () => _skip(isLoading),
                  child: Text( "Skip for now", style: getbodyStyle( color: AppColors.secondaryColor, fontWeight: FontWeight.w600, fontSize: 15, ), ),
                ),
              ),
            );
         }
      ),
    );
  }
}
