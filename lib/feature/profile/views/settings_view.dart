import 'dart:io';
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
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart';
import 'package:shamil_mobile_app/feature/profile/views/edit_profile_view.dart';
import 'package:shamil_mobile_app/feature/passes/view/passes_screen.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart';
import 'package:shamil_mobile_app/feature/social/views/family_view.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/reminder_settings_page.dart';
import 'package:shamil_mobile_app/feature/payments/views/payments_screen.dart';
import 'package:gap/gap.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingPicture = false;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  late final AnimationController _animationController;
  late final AnimationController _orbAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _setupAnimations();
  }

  void _setupAnimations() {
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
    final shouldCollapse = scrollOffset > 250;

    if (shouldCollapse != _isCollapsed) {
      setState(() {
        _isCollapsed = shouldCollapse;
      });
    }
  }

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
      child: Scaffold(
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
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is AuthInitial ||
                      authState is AuthLoadingState) {
                    return _buildLoadingScreen();
                  }
                  if (authState is AuthErrorState) {
                    return _buildErrorScreen(authState.message);
                  }
                  if (authState is AwaitingVerificationState) {
                    return _buildErrorScreen(
                        "Please verify your email (${authState.email})",
                        showRetry: false);
                  }
                  if (authState is LoginSuccessState) {
                    final userModel = authState.user;
                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // App Bar
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          pinned: true,
                          expandedHeight: 140,
                          automaticallyImplyLeading: false,
                          flexibleSpace: FlexibleSpaceBar(
                            background: _buildHeader(userModel),
                            title: _isCollapsed
                                ? Text(
                                    'Settings',
                                    style: AppTextStyle.getTitleStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // Content
                        SliverToBoxAdapter(
                          child: AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: _buildSettingsContent(userModel),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return _buildLoadingScreen();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(userModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              Text(
                'Manage your account and preferences',
                style: AppTextStyle.getbodyStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(userModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Management Section
          _buildSection(
            title: 'Profile',
            icon: CupertinoIcons.person,
            children: [
              _buildSettingItem(
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                icon: CupertinoIcons.pencil,
                onTap: () => _navigateToEditProfile(),
              ),
              _buildSettingItem(
                title: 'Profile Picture',
                subtitle: 'Change your profile photo',
                icon: CupertinoIcons.camera,
                onTap: _pickAndUpdateProfilePicture,
                trailing: _isUpdatingPicture
                    ? const CupertinoActivityIndicator(
                        color: AppColors.primaryColor)
                    : null,
              ),
            ],
          ),

          const Gap(24),

          // Social Section
          _buildSection(
            title: 'Social',
            icon: CupertinoIcons.person_2,
            children: [
              _buildSettingItem(
                title: 'Friends',
                subtitle: 'Manage your connections',
                icon: CupertinoIcons.person_2,
                onTap: () => _navigateToFriends(),
              ),
              _buildSettingItem(
                title: 'Family',
                subtitle: 'Family member management',
                icon: CupertinoIcons.house,
                onTap: () => _navigateToFamily(),
              ),
            ],
          ),

          const Gap(24),

          // App Features Section
          _buildSection(
            title: 'Features',
            icon: CupertinoIcons.square_grid_2x2,
            children: [
              _buildSettingItem(
                title: 'My Passes',
                subtitle: 'View your passes',
                icon: CupertinoIcons.ticket,
                onTap: () => _navigateToPasses(),
              ),
              _buildSettingItem(
                title: 'Payments',
                subtitle: 'Payment methods',
                icon: CupertinoIcons.creditcard,
                onTap: () => _navigateToPayments(),
              ),
              _buildSettingItem(
                title: 'Reminders',
                subtitle: 'Configure reminder settings',
                icon: CupertinoIcons.bell,
                onTap: () => _navigateToReminders(),
              ),
            ],
          ),

          const Gap(24),

          // Account Section
          _buildSection(
            title: 'Account',
            icon: CupertinoIcons.settings,
            children: [
              _buildSettingItem(
                title: 'My Passes',
                subtitle: 'View your passes',
                icon: CupertinoIcons.ticket,
                onTap: () => _navigateToPasses(),
              ),
              _buildSettingItem(
                title: 'Payments',
                subtitle: 'Payment methods',
                icon: CupertinoIcons.creditcard,
                onTap: () => _navigateToPayments(),
              ),
              _buildSettingItem(
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                icon: CupertinoIcons.square_arrow_left,
                onTap: _handleLogout,
                textColor: Colors.red,
              ),
            ],
          ),

          const Gap(100), // Bottom spacing
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryColor, size: 20),
                const Gap(8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: textColor ?? Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.getbodyStyle(
                          color: textColor ?? Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        subtitle,
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs() {
    return [
      Positioned(
        top: 100,
        right: -50,
        child: AnimatedBuilder(
          animation: _orbAnimationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _orbAnimationController.value * 2 * 3.14159,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 200,
        left: -75,
        child: AnimatedBuilder(
          animation: _orbAnimationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: -_orbAnimationController.value * 2 * 3.14159,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.tealColor.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildLoadingScreen() {
    return const Center(child: LoadingScreen());
  }

  Widget _buildErrorScreen(String message, {bool showRetry = true}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.red,
              size: 48,
            ),
            const Gap(16),
            Text(
              'Error',
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              message,
              style: AppTextStyle.getbodyStyle(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetry) ...[
              const Gap(20),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<AuthBloc>()
                      .add(const CheckEmailVerificationStatus());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileView(),
      ),
    );
  }

  void _navigateToFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FriendsView(),
      ),
    );
  }

  void _navigateToFamily() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FamilyView(),
      ),
    );
  }

  void _navigateToPasses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PassesScreen(),
      ),
    );
  }

  void _navigateToPayments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentsScreen(),
      ),
    );
  }

  void _navigateToReminders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReminderSettingsPage(),
      ),
    );
  }
}
