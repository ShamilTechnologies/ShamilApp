import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart'; // For LoadingScreen
import 'package:gap/gap.dart';
import 'dart:typed_data'; // Import for Uint8List for placeholder

// Import Social Bloc & Event
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
// Import the content widget
import 'package:shamil_mobile_app/feature/profile/views/edit_profile_view.dart';
import 'package:shamil_mobile_app/feature/passes/view/passes_screen.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart';
import 'package:shamil_mobile_app/feature/social/views/family_view.dart';

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
    return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Photo',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: AppTextStyle.getbodyStyle(),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo_fill,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: AppTextStyle.getbodyStyle(),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _pickAndUpdateProfilePicture() async {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.red,
                size: 24,
              ),
            ),
            const Gap(16),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text("Logout"),
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
      backgroundColor: theme.scaffoldBackgroundColor,
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
              return SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            child: RefreshIndicator(
                              onRefresh: () async {
                                context
                                    .read<AuthBloc>()
                                    .add(const CheckEmailVerificationStatus());
                                context
                                    .read<SocialBloc>()
                                    .add(const LoadFamilyMembers());
                                context
                                    .read<SocialBloc>()
                                    .add(const LoadFriendsAndRequests());
                                await Future.delayed(
                                    const Duration(milliseconds: 500));
                              },
                              child: _buildProfileContent(context, userModel),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Fallback for any unexpected AuthBloc state
            return const Center(child: Text("An unexpected error occurred."));
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
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
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Gap(14),
                  Text(
                    'My Profile',
                    style: AppTextStyle.getHeadlineTextStyle(
                      color: AppColors.primaryText,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildRefreshButton(context),
            ],
          ),
          const Gap(12),
          Text(
            'Manage your account settings and preferences',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<AuthBloc>().add(const CheckEmailVerificationStatus());
        context.read<SocialBloc>().add(const LoadFamilyMembers());
        context.read<SocialBloc>().add(const LoadFriendsAndRequests());
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.arrow_clockwise,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, final userModel) {
    // Profile picture section
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    // Profile card
    final profileCard = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Profile image
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
                    child: (profilePicUrl == null)
                        ? Icon(
                            CupertinoIcons.person_fill,
                            size: 60,
                            color: AppColors.primaryColor.withOpacity(0.5),
                          )
                        : FadeInImage.memoryNetwork(
                            placeholder: transparentImageData,
                            image: profilePicUrl,
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
                // Edit button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUpdatingPicture
                        ? null
                        : _pickAndUpdateProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isUpdatingPicture
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.camera_fill,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          Text(
            userModel.name,
            style: AppTextStyle.getTitleStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            userModel.email,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
          ),
          const Gap(16),
          if (userModel.phone != null && userModel.phone!.isNotEmpty)
            _buildInfoItem(CupertinoIcons.phone_fill, userModel.phone!),
        ],
      ),
    );

    // Options section
    final optionsCard = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionItem(
            CupertinoIcons.person_crop_circle,
            'Edit Profile',
            'Update your personal information',
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileView()));
            },
          ),
          const Divider(height: 1),
          _buildOptionItem(
            CupertinoIcons.person_2_fill,
            'Family Members',
            'Manage your family connections',
            () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<SocialBloc>(context),
                      child: const FamilyView(),
                    ),
                  ),
                ).then((_) {
                  // Refresh profile data when returning from family view
                  context
                      .read<AuthBloc>()
                      .add(const CheckEmailVerificationStatus());
                });
              } catch (e) {
                print("Error navigating to FamilyView: $e");
                showGlobalSnackBar(
                    context, "Unable to access Family Members view",
                    isError: true);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.person_2_fill,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildOptionItem(
            CupertinoIcons.person_3_fill,
            'Friends',
            'Connect with other users',
            () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<SocialBloc>(context),
                      child: const FriendsView(),
                    ),
                  ),
                ).then((_) {
                  // Refresh profile data when returning
                  context
                      .read<AuthBloc>()
                      .add(const CheckEmailVerificationStatus());
                });
              } catch (e) {
                print("Error navigating to FriendsView: $e");
                showGlobalSnackBar(context, "Unable to access Friends view",
                    isError: true);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.person_3_fill,
                color: AppColors.accentColor,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildOptionItem(
            CupertinoIcons.ticket_fill,
            'My Passes',
            'View your reservations and subscriptions',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PassesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildOptionItem(
            CupertinoIcons.settings,
            'Settings',
            'App preferences and notifications',
            () {
              // Will be implemented later
              showGlobalSnackBar(context, "Settings coming soon!");
            },
          ),
          const Divider(height: 1),
          _buildOptionItem(
            CupertinoIcons.question_circle,
            'Help & Support',
            'Get assistance with the app',
            () {
              // Will be implemented later
              showGlobalSnackBar(context, "Help & Support coming soon!");
            },
          ),
        ],
      ),
    );

    // Logout section
    final logoutButton = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(CupertinoIcons.square_arrow_left, size: 20),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        profileCard,
        const Gap(16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Account Options',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(8),
        optionsCard,
        logoutButton,
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryColor,
        ),
        const Gap(8),
        Text(
          text,
          style: AppTextStyle.getbodyStyle(),
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    IconData defaultIcon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: icon ??
          Icon(
            defaultIcon,
            color: AppColors.primaryColor,
            size: 24,
          ),
      title: Text(
        title,
        style: AppTextStyle.getTitleStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyle.getSmallStyle(
          color: AppColors.secondaryText,
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: AppColors.primaryColor,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  /// Widget to display error message
  Widget _buildErrorDisplay(
      BuildContext context, ThemeData theme, String message,
      {bool showRetry = true}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.red,
                size: 48,
              ),
            ),
            const Gap(16),
            Text(
              'Error Loading Profile',
              style: AppTextStyle.getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              message,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetry) ...[
              const Gap(24),
              ElevatedButton.icon(
                onPressed: () {
                  try {
                    context
                        .read<AuthBloc>()
                        .add(const CheckEmailVerificationStatus());
                  } catch (e) {
                    print("Error dispatching retry event: $e");
                  }
                },
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} // End of _ProfileScreenState

/// Helper to build the placeholder image (can be moved to a shared file)
Widget buildProfilePlaceholder(
    {required double size, required BorderRadius borderRadius, String? name}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppColors.primaryColor.withOpacity(0.1),
        width: 1.0,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: AppColors.primaryColor.withOpacity(0.4),
      ),
    ),
  );
}
