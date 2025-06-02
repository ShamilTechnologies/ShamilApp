import 'dart:io'; // For File type
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingPicture = false;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Premium animation controllers
  late final AnimationController _animationController;
  late final AnimationController _orbAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Setup premium animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _orbAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();

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
    _animationController.dispose();
    _orbAnimationController.dispose();
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
  Future<void> _pickAndUpdateProfilePicture() async {
    try {
      setState(() {
        _isUpdatingPicture = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        if (mounted) {
          context.read<AuthBloc>().add(UpdateProfilePicture(
                imageFile: imageFile,
              ));
        }
      }
    } catch (e) {
      if (mounted) {
        showGlobalSnackBar(context, "Failed to pick image: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPicture = false;
        });
      }
    }
  }

  void _handleLogout() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.square_arrow_left,
                        color: Colors.white,
                        size: 48,
                      ),
                      const Gap(16),
                      Text(
                        'Sign Out',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Are you sure you want to sign out?',
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(24),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: AppTextStyle.getbodyStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context
                                      .read<AuthBloc>()
                                      .add(const LogoutEvent());
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.8),
                                        Colors.red.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Sign Out',
                                    style: AppTextStyle.getbodyStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState &&
            state.message.contains('profile') &&
            _isUpdatingPicture) {
          setState(() {
            _isUpdatingPicture = false;
          });
          showGlobalSnackBar(context, "Failed to update profile picture",
              isError: true);
        } else if (state is LoginSuccessState && _isUpdatingPicture) {
          setState(() {
            _isUpdatingPicture = false;
          });
          showGlobalSnackBar(context, "Profile picture updated successfully!");
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthInitial || authState is AuthLoadingState) {
            return _buildPremiumLoadingScreen();
          }
          if (authState is AuthErrorState) {
            return _buildPremiumErrorScreen(authState.message);
          }
          if (authState is AwaitingVerificationState) {
            return _buildPremiumErrorScreen(
                "Please verify your email (${authState.email})",
                showRetry: false);
          }
          if (authState is LoginSuccessState) {
            final userModel = authState.user;
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F0F23),
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F0F23),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated floating orbs
                    ..._buildFloatingOrbs(),

                    // Main content
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Pull to refresh indicator
                        CupertinoSliverRefreshControl(
                          builder: (context,
                              refreshState,
                              pulledExtent,
                              refreshTriggerPullDistance,
                              refreshIndicatorExtent) {
                            return Container(
                              padding: const EdgeInsets.only(top: 16),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.8),
                                        AppColors.tealColor.withOpacity(0.8),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: refreshState ==
                                          RefreshIndicatorMode.refresh
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Icon(
                                          Icons.arrow_downward_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            );
                          },
                          onRefresh: () async {
                            context
                                .read<AuthBloc>()
                                .add(const CheckEmailVerificationStatus());
                            return Future.delayed(const Duration(seconds: 1));
                          },
                        ),

                        // Premium header
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          pinned: true,
                          expandedHeight: 140,
                          automaticallyImplyLeading: false,
                          flexibleSpace: FlexibleSpaceBar(
                            background: _buildPremiumHeader(userModel),
                          ),
                        ),

                        // Content with premium styling
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF0A0A1A),
                                ],
                              ),
                            ),
                            child: _buildPremiumProfileContent(userModel),
                          ),
                        ),
                      ],
                    ),

                    // Floating logout button
                    Positioned(
                      top: 50,
                      right: 16,
                      child: SafeArea(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _handleLogout,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red.withOpacity(0.3),
                                                Colors.red.withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.square_arrow_left,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const Gap(8),
                                        Text(
                                          'Logout',
                                          style: AppTextStyle.getbodyStyle(
                                            color: Colors.white,
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildPremiumErrorScreen("An unexpected error occurred.");
        },
      ),
    );
  }

  List<Widget> _buildFloatingOrbs() {
    return [
      // Large orb top right
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            top: 100 + (20 * (_orbAnimationController.value * 2 - 1).abs()),
            right: 50 + (15 * (_orbAnimationController.value * 2 - 1)),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.3),
                    AppColors.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Medium orb middle left
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            top: 300 + (30 * _orbAnimationController.value),
            left: 30 + (20 * (1 - _orbAnimationController.value)),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.4),
                    AppColors.tealColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Small orb bottom right
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            bottom: 200 + (25 * _orbAnimationController.value),
            right: 80 + (10 * (_orbAnimationController.value * 2 - 1)),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentColor.withOpacity(0.3),
                    AppColors.accentColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildPremiumHeader(final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 80),
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.8),
                          AppColors.accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const Gap(3),
                        Text(
                          'YOUR PROFILE',
                          style: AppTextStyle.getbodyStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),

                  // Title with gradient text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFB8BCC8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Profile',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumProfileContent(final userModel) {
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
      profilePicUrl = null;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Profile info section
                  _buildPremiumProfileInfo(userModel, profilePicUrl),
                  const Gap(24),

                  // Account section
                  _buildPremiumSection('Account', [
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.person_crop_circle,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      color: AppColors.primaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EditProfileView()));
                      },
                    ),
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.creditcard_fill,
                      title: 'Payments',
                      subtitle: 'Manage payments and transactions',
                      color: Colors.green,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.ticket_fill,
                      title: 'My Passes',
                      subtitle: 'View your reservations and subscriptions',
                      color: Colors.orange,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PassesScreen(),
                          ),
                        );
                      },
                    ),
                  ]),

                  const Gap(20),

                  // Social section
                  _buildPremiumSection('Social', [
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.person_2_fill,
                      title: 'Family Members',
                      subtitle: 'Manage your family connections',
                      color: AppColors.primaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
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
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.person_3_fill,
                      title: 'Friends',
                      subtitle: 'Connect with other users',
                      color: AppColors.accentColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
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
                          showGlobalSnackBar(
                              context, "Unable to access Friends view",
                              isError: true);
                        }
                      },
                    ),
                  ]),

                  const Gap(20),

                  // Services section
                  _buildPremiumSection('Services', [
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.list_number,
                      title: 'Queue Reservations',
                      subtitle: 'Join and manage virtual queues',
                      color: Colors.blue,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReminderSettingsPage(),
                          ),
                        );
                      },
                    ),
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.settings,
                      title: 'Settings',
                      subtitle: 'App preferences and notifications',
                      color: Colors.grey,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showGlobalSnackBar(context, "Settings coming soon!");
                      },
                    ),
                    _buildPremiumMenuItem(
                      icon: CupertinoIcons.question_circle,
                      title: 'Help & Support',
                      subtitle: 'Get assistance with the app',
                      color: Colors.purple,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showGlobalSnackBar(
                            context, "Help & Support coming soon!");
                      },
                    ),
                  ]),

                  const Gap(30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumProfileInfo(final userModel, String? profilePicUrl) {
    return Column(
      children: [
        // Profile Picture
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.3),
                    AppColors.accentColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildProfileImage(userModel, 60),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Material(
                borderRadius: BorderRadius.circular(50),
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap:
                      _isUpdatingPicture ? null : _pickAndUpdateProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor.withOpacity(0.9),
                          AppColors.accentColor.withOpacity(0.9),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
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
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(6),
        Text(
          userModel.email,
          style: AppTextStyle.getbodyStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (userModel.phone != null && userModel.phone!.isNotEmpty) ...[
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.phone_fill,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const Gap(6),
              Flexible(
                child: Text(
                  userModel.phone!,
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.getTitleStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Gap(12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(children: items),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const Gap(20),
                    Text(
                      'Loading profile...',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumErrorScreen(String message, {bool showRetry = true}) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withOpacity(0.15),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: Colors.white,
                      size: 48,
                    ),
                    const Gap(20),
                    Text(
                      'Error Loading Profile',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      message,
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showRetry) ...[
                      const Gap(24),
                      Material(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            try {
                              context
                                  .read<AuthBloc>()
                                  .add(const CheckEmailVerificationStatus());
                            } catch (e) {
                              print("Error dispatching retry event: $e");
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withOpacity(0.8),
                                  Colors.red.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.refresh,
                                    color: Colors.white),
                                const Gap(8),
                                Text(
                                  'Try Again',
                                  style: AppTextStyle.getbodyStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
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
            color: Colors.white.withOpacity(0.5),
          )
        : FadeInImage.memoryNetwork(
            placeholder: transparentImageData,
            image: profilePicUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) => Icon(
              CupertinoIcons.person_fill,
              size: size,
              color: Colors.white.withOpacity(0.5),
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
