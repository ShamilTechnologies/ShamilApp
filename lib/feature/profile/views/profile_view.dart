import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Keep for placeholder helper
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart'; // For LoadingScreen
import 'dart:typed_data'; // Import for Uint8List for placeholder

// Import Social Bloc & Event
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
// Import the content widget
import 'package:shamil_mobile_app/feature/profile/widgets/profile_content.dart';

// Placeholder for transparent image data (can be moved to a constants file)
const kTransparentImage = <int>[
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
final Uint8List transparentImageData = Uint8List.fromList(kTransparentImage);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingPicture =
      false; // Local flag for picture update loading state
  // REMOVED: late final SocialBloc _socialBloc;

  @override
  void initState() {
    super.initState();
    // REMOVED: _socialBloc = SocialBloc(); // Don't create local instance

    // Load initial social data using the *globally provided* Bloc
    // Use WidgetsBinding to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if widget is still mounted
        try {
          // Read the globally provided SocialBloc
          final socialBloc = context.read<SocialBloc>();
          // Load initial data if needed (check state first to avoid redundant loads)
          if (socialBloc.state is SocialInitial) {
            socialBloc.add(const LoadFamilyMembers());
            socialBloc.add(const LoadFriendsAndRequests()); // Load friends too
          }
        } catch (e) {
          print("Error accessing SocialBloc in ProfileScreen initState: $e");
          // Show error if Bloc isn't provided correctly
          showGlobalSnackBar(context, "Could not load social data.",
              isError: true);
        }
      }
    });
  }

  @override
  void dispose() {
    // REMOVED: _socialBloc.close(); // No local Bloc to dispose
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<ImageSource?> _showImageSourceSelector() async {
    // (Implementation remains the same)
    return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors
                  .white, // Use AppColors if defined, else Colors.white
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Image Source',
                  style: getbodyStyle(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ), // Assuming getbodyStyle exists
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: AppColors.primaryColor),
                  title: Text('Camera',
                      style: getbodyStyle(color: AppColors.primaryColor)),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.photo, color: AppColors.primaryColor),
                  title: Text('Gallery',
                      style: getbodyStyle(color: AppColors.primaryColor)),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _pickAndUpdateProfilePicture() async {
    // (Implementation remains the same - dispatches to AuthBloc)
    if (_isUpdatingPicture) return;
    final source = await _showImageSourceSelector();
    if (source == null) return;
    try {
      final pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (pickedImage != null && mounted) {
        setState(() {
          _isUpdatingPicture = true;
        });
        context
            .read<AuthBloc>()
            .add(UpdateProfilePicture(imageFile: File(pickedImage.path)));
      } else if (pickedImage == null) {
        showGlobalSnackBar(context, "Image selection cancelled.");
      }
    } catch (e) {
      print("Error picking image: $e");
      showGlobalSnackBar(context, "Error picking image: $e", isError: true);
      if (mounted) {
        setState(() {
          _isUpdatingPicture = false;
        });
      }
    }
  }
  // --- End Image Picking Logic ---

  // --- Logout Logic ---
  Future<void> _handleLogout() async {
    // (Implementation remains the same - dispatches to AuthBloc)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout",
                style: TextStyle(color: AppColors.redColor)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        showGlobalSnackBar(context, "Logging out...");
        context.read<AuthBloc>().add(const LogoutEvent());
      } catch (e) {
        print("Error dispatching logout event: $e");
        if (mounted) {
          showGlobalSnackBar(context, "Logout failed: $e", isError: true);
        }
      }
    }
  }
  // --- End Logout Logic ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // REMOVED: BlocProvider.value wrapper
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0, // Keep AppBar clean
        foregroundColor: theme.colorScheme.primary,
      ),
      // Use MultiBlocListener to handle side effects from both Blocs
      body: MultiBlocListener(
        listeners: [
          // Listener for AuthBloc side effects
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // Reset local picture updating flag AFTER Bloc finishes
              if (state is! AuthLoadingState && _isUpdatingPicture) {
                if (mounted) {
                  // Check mounted before calling setState
                  setState(() {
                    _isUpdatingPicture = false;
                  });
                }
              }
              // Show feedback only if WE initiated the update
              if (state is LoginSuccessState && _isUpdatingPicture) {
                showGlobalSnackBar(context, "Profile picture updated!");
              } else if (state is AuthErrorState && _isUpdatingPicture) {
                showGlobalSnackBar(context, "Update failed: ${state.message}",
                    isError: true);
              } else if (state is PasswordResetEmailSentState) {
                showGlobalSnackBar(context, "Password reset email sent.");
              }
            },
          ),
          // Listener for SocialBloc side effects (e.g., success/error from family/friend actions)
          BlocListener<SocialBloc, SocialState>(
            listener: (context, state) {
              if (state is SocialSuccess) {
                showGlobalSnackBar(context, state.message);
              } else if (state is SocialError) {
                showGlobalSnackBar(context, state.message, isError: true);
              }
            },
          ),
        ],
        // Use BlocBuilder for AuthBloc to determine the main UI structure
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // Show LoadingScreen during initial load or general AuthBloc loading
            if (authState is AuthInitial || authState is AuthLoadingState) {
              return const LoadingScreen();
            }
            // Show error if AuthBloc failed to load profile
            if (authState is AuthErrorState) {
              return _buildErrorDisplay(context, theme,
                  "Could not load profile: ${authState.message}");
            }
            // Show message if email verification is pending
            if (authState is AwaitingVerificationState) {
              return _buildErrorDisplay(context, theme,
                  "Please verify your email (${authState.email})",
                  showRetry: false);
            }
            // Build the main profile content if AuthBloc has user data
            if (authState is LoginSuccessState) {
              final userModel = authState.user;
              // Pass data and callbacks down to the content widget
              // ProfileContent will access the globally provided SocialBloc via context
              return ProfileContent(
                userModel: userModel,
                isUpdatingPicture: _isUpdatingPicture, // Pass loading flag down
                onUpdatePicture:
                    _pickAndUpdateProfilePicture, // Pass callback down
                onLogout: _handleLogout, // Pass callback down
              );
            }
            // Fallback for any unexpected AuthBloc state
            return const Center(child: Text("An unexpected error occurred."));
          },
        ),
      ),
    );
  }

  /// Widget to display error message
  Widget _buildErrorDisplay(
      BuildContext context, ThemeData theme, String message,
      {bool showRetry = true}) {
    // (Implementation remains the same)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center),
            if (showRetry) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    try {
                      context
                          .read<AuthBloc>()
                          .add(const CheckEmailVerificationStatus());
                    } catch (e) {
                      print("Error dispatching retry event: $e");
                    }
                  },
                  child: const Text("Retry")),
            ]
          ],
        ),
      ),
    );
  }
} // End of _ProfileScreenState

/// Helper to build the placeholder image (can be moved to a shared file)
Widget buildProfilePlaceholder(
    double size, ThemeData theme, BorderRadius borderRadius) {
  // (Implementation remains the same)
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05),
      borderRadius: borderRadius,
      border: Border.all(
        color: theme.colorScheme.primary.withOpacity(0.1),
        width: 1.0,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: theme.colorScheme.primary.withOpacity(0.4),
      ),
    ),
  );
}
