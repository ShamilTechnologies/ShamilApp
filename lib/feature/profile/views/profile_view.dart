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
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/reminder_settings_page.dart';
import 'package:shamil_mobile_app/feature/payments/views/payments_screen.dart';

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
  bool _isUpdatingPicture = false;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final socialBloc = context.read<SocialBloc>();
          if (socialBloc.state is SocialInitial) {
            socialBloc.add(const LoadFamilyMembers());
            socialBloc.add(const LoadFriendsAndRequests());
          }
        } catch (e) {
          print("Error accessing SocialBloc in ProfileScreen initState: $e");
          showGlobalSnackBar(context, "Could not load social data.",
              isError: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final scrollOffset = _scrollController.offset;

    // Trigger collapse when user scrolls past the profile header
    // Adjust threshold based on header height (approximately 300px)
    final shouldCollapse = scrollOffset > 250;

    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
    }
  }

  // --- Image Picking Logic ---
  Future<ImageSource?> _showImageSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(20),
                Text(
                  'Update Profile Photo',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(24),
                _buildImageSourceOption(
                  icon: CupertinoIcons.camera_fill,
                  title: 'Take Photo',
                  subtitle: 'Use camera to take a new photo',
                  color: AppColors.primaryColor,
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const Gap(12),
                _buildImageSourceOption(
                  icon: CupertinoIcons.photo_fill,
                  title: 'Choose from Gallery',
                  subtitle: 'Select from your photo library',
                  color: Colors.purple,
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                const Gap(20),
              ],
            ),
          );
        });
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
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

  // --- Logout Logic ---
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.square_arrow_left,
                color: Colors.red,
                size: 24,
              ),
            ),
            const Gap(16),
            const Text('Sign Out'),
          ],
        ),
        content:
            const Text("Are you sure you want to sign out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        showGlobalSnackBar(context, "Signing out...");
        context.read<AuthBloc>().add(const LogoutEvent());
      } catch (e) {
        print("Error dispatching logout event: $e");
        if (mounted) {
          showGlobalSnackBar(context, "Logout failed: $e", isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is! AuthLoadingState && _isUpdatingPicture) {
              if (mounted) {
                setState(() {
                  _isUpdatingPicture = false;
                });
              }
            }
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
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthInitial || authState is AuthLoadingState) {
            return const LoadingScreen();
          }
          if (authState is AuthErrorState) {
            return _buildErrorDisplay(
                context, theme, "Could not load profile: ${authState.message}");
          }
          if (authState is AwaitingVerificationState) {
            return _buildErrorDisplay(
                context, theme, "Please verify your email (${authState.email})",
                showRetry: false);
          }
          if (authState is LoginSuccessState) {
            final userModel = authState.user;
            return Scaffold(
              backgroundColor: Colors.grey.shade50,
              body: Stack(
                children: [
                  // Main scrollable content
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Normal profile header
                      SliverToBoxAdapter(
                        child: _buildNormalProfileHeader(context, userModel),
                      ),
                      SliverToBoxAdapter(
                        child: _buildProfileContent(context, userModel),
                      ),
                    ],
                  ),
                  // Floating header (only visible when collapsed)
                  if (_isCollapsed)
                    _buildFloatingCollapsedHeader(context, userModel),
                ],
              ),
            );
          }
          return const Center(child: Text("An unexpected error occurred."));
        },
      ),
    );
  }

  // Helper method to build profile image
  Widget _buildProfileImage(final userModel, double size) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return (profilePicUrl == null)
        ? Icon(
            CupertinoIcons.person_fill,
            size: size,
            color: AppColors.primaryColor.withOpacity(0.5),
          )
        : FadeInImage.memoryNetwork(
            placeholder: transparentImageData,
            image: profilePicUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) => Icon(
              CupertinoIcons.person_fill,
              size: size,
              color: AppColors.primaryColor.withOpacity(0.5),
            ),
          );
  }

  // Helper method to build expanded header
  Widget _buildExpandedHeader(BuildContext context, final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Logout button positioned in top right
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: _handleLogout,
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.square_arrow_left,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Profile content centered
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Gap(20),
                  // Profile Picture
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
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
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProfileImage(userModel, 50),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _isUpdatingPicture
                              ? null
                              : _pickAndUpdateProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _isUpdatingPicture
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    CupertinoIcons.camera_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  // User Info
                  Text(
                    userModel.name,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    userModel.email,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userModel.phone != null &&
                      userModel.phone!.isNotEmpty) ...[
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.phone_fill,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            userModel.phone!,
                            style: AppTextStyle.getbodyStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Gap(20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Normal profile header (always visible in scroll)
  Widget _buildNormalProfileHeader(BuildContext context, final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logout button row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _handleLogout,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.square_arrow_left,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(20),
              // Profile Picture
              Stack(
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
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProfileImage(userModel, 60),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
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
                              blurRadius: 6,
                              offset: const Offset(0, 3),
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
              const Gap(20),
              // User Info
              Text(
                userModel.name,
                style: AppTextStyle.getTitleStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(6),
              Text(
                userModel.email,
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (userModel.phone != null && userModel.phone!.isNotEmpty) ...[
                const Gap(4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.phone_fill,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const Gap(4),
                    Flexible(
                      child: Text(
                        userModel.phone!,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // Floating collapsed header (only visible when scrolled)
  Widget _buildFloatingCollapsedHeader(BuildContext context, final userModel) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // App title or greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profile',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Welcome back, ${userModel.name.split(' ').first}',
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                // Logout button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.square_arrow_left,
                              color: Colors.red,
                              size: 18,
                            ),
                            const Gap(8),
                            Text(
                              'Logout',
                              style: AppTextStyle.getbodyStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFloatingHeader(BuildContext context, final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isCollapsed ? 70 : 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: _isCollapsed
            ? // Collapsed state - horizontal row
            Container(
                height: 70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Small profile picture
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.15),
                            AppColors.primaryColor.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProfileImage(userModel, 22),
                      ),
                    ),
                    const Gap(14),
                    // Name
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(
                          userModel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Spacer between name and logout button
                    const Gap(20),
                    // Logout button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: IconButton(
                        onPressed: _handleLogout,
                        icon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.square_arrow_left,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : // Expanded state - use existing expanded header
            _buildExpandedHeader(context, userModel),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isCollapsed ? 80 : 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: _isCollapsed
            ? // Collapsed state - everything in one row
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Small profile picture
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
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
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: (profilePicUrl == null)
                            ? Icon(
                                CupertinoIcons.person_fill,
                                size: 22,
                                color: AppColors.primaryColor.withOpacity(0.5),
                              )
                            : FadeInImage.memoryNetwork(
                                placeholder: transparentImageData,
                                image: profilePicUrl,
                                fit: BoxFit.cover,
                                imageErrorBuilder:
                                    (context, error, stackTrace) => Icon(
                                  CupertinoIcons.person_fill,
                                  size: 22,
                                  color:
                                      AppColors.primaryColor.withOpacity(0.5),
                                ),
                              ),
                      ),
                    ),
                    const Gap(12),
                    // Name
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(
                          userModel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Gap(12),
                    // Logout button
                    IconButton(
                      onPressed: _handleLogout,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.square_arrow_left,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : // Expanded state - vertical layout
            Stack(
                children: [
                  // Logout button - positioned in top right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: _handleLogout,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.square_arrow_left,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Profile content centered
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Gap(40),
                          // Profile Picture
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
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
                                    color:
                                        AppColors.primaryColor.withOpacity(0.2),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (profilePicUrl == null)
                                      ? Icon(
                                          CupertinoIcons.person_fill,
                                          size: 60,
                                          color: AppColors.primaryColor
                                              .withOpacity(0.5),
                                        )
                                      : FadeInImage.memoryNetwork(
                                          placeholder: transparentImageData,
                                          image: profilePicUrl,
                                          fit: BoxFit.cover,
                                          imageErrorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            CupertinoIcons.person_fill,
                                            size: 60,
                                            color: AppColors.primaryColor
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
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
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
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
                          const Gap(20),
                          // User Info
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            child: Text(
                              userModel.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            userModel.email,
                            style: AppTextStyle.getbodyStyle(
                              color: AppColors.secondaryText,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userModel.phone != null &&
                              userModel.phone!.isNotEmpty) ...[
                            const Gap(4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.phone_fill,
                                  size: 14,
                                  color: AppColors.primaryColor,
                                ),
                                const Gap(4),
                                Flexible(
                                  child: Text(
                                    userModel.phone!,
                                    style: AppTextStyle.getbodyStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Gap(20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, final userModel) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          const Gap(12),
          _buildModernOptionCard([
            _buildModernOptionItem(
              icon: CupertinoIcons.person_crop_circle,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              color: AppColors.primaryColor,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditProfileView()));
              },
            ),
            _buildModernOptionItem(
              icon: CupertinoIcons.creditcard_fill,
              title: 'Payments',
              subtitle: 'Manage payments and transactions',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentsScreen(),
                  ),
                );
              },
            ),
            _buildModernOptionItem(
              icon: CupertinoIcons.ticket_fill,
              title: 'My Passes',
              subtitle: 'View your reservations and subscriptions',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PassesScreen(),
                  ),
                );
              },
            ),
          ]),

          const Gap(24),

          // Social Section
          _buildSectionHeader('Social'),
          const Gap(12),
          _buildModernOptionCard([
            _buildModernOptionItem(
              icon: CupertinoIcons.person_2_fill,
              title: 'Family Members',
              subtitle: 'Manage your family connections',
              color: AppColors.primaryColor,
              onTap: () {
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
            ),
            _buildModernOptionItem(
              icon: CupertinoIcons.person_3_fill,
              title: 'Friends',
              subtitle: 'Connect with other users',
              color: AppColors.accentColor,
              onTap: () {
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
            ),
          ]),

          const Gap(24),

          // Services Section
          _buildSectionHeader('Services'),
          const Gap(12),
          _buildModernOptionCard([
            _buildModernOptionItem(
              icon: CupertinoIcons.list_number,
              title: 'Queue Reservations',
              subtitle: 'Join and manage virtual queues',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderSettingsPage(),
                  ),
                );
              },
            ),
            _buildModernOptionItem(
              icon: CupertinoIcons.settings,
              title: 'Settings',
              subtitle: 'App preferences and notifications',
              color: Colors.grey,
              onTap: () {
                showGlobalSnackBar(context, "Settings coming soon!");
              },
            ),
            _buildModernOptionItem(
              icon: CupertinoIcons.question_circle,
              title: 'Help & Support',
              subtitle: 'Get assistance with the app',
              color: Colors.purple,
              onTap: () {
                showGlobalSnackBar(context, "Help & Support coming soon!");
              },
            ),
          ]),

          const Gap(40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyle.getTitleStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildModernOptionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildModernOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

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
}

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
