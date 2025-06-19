import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_success_animation_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/core/navigation/enhanced_navigation_service.dart';

// Removed complex camera widget - now using simple upload fields like profile photo

// Modern Upload Field with Dark Theme
class ModernUploadField extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isActive;

  const ModernUploadField({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.file,
    required this.onTap,
    this.isLoading = false,
    this.isActive = true,
  });

  @override
  State<ModernUploadField> createState() => _ModernUploadFieldState();
}

class _ModernUploadFieldState extends State<ModernUploadField>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (isHovered && !widget.isLoading) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.file != null;
    final isDisabled = widget.isLoading || !widget.isActive;

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasFile
                    ? AppColors.tealColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              color: Colors.white.withOpacity(0.05),
              boxShadow: [
                if (hasFile)
                  BoxShadow(
                    color: AppColors.tealColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onTap,
                onHover: _handleHover,
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.tealColor.withOpacity(0.2),
                highlightColor: AppColors.tealColor.withOpacity(0.1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isDisabled ? 0.6 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: hasFile
                                  ? [
                                      AppColors.tealColor,
                                      AppColors.tealColor.withOpacity(0.8)
                                    ]
                                  : [
                                      AppColors.tealColor.withOpacity(0.8),
                                      AppColors.tealColor.withOpacity(0.6),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.tealColor.withOpacity(0.4),
                                blurRadius: hasFile ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              hasFile
                                  ? Icons.check_circle_rounded
                                  : widget.icon,
                              key: ValueKey(hasFile),
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Gap(16),

                        // Content Area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: getbodyStyle(
                                  color: hasFile
                                      ? AppColors.tealColor
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                widget.description,
                                style: getbodyStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (hasFile) ...[
                                const Gap(6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.tealColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "✓ Uploaded",
                                    style: getbodyStyle(
                                      color: AppColors.tealColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Image Preview
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          width: hasFile ? 60 : 48,
                          height: hasFile ? 60 : 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: widget.file != null
                                  ? Container(
                                      key: ValueKey(widget.file!.path),
                                      child: Image.file(
                                        widget.file!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  : Container(
                                      key: const ValueKey('placeholder'),
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
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 20,
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
            ),
          ),
        );
      },
    );
  }
}

// Modern Progress Stepper with Dark Theme
class ModernProgressStepper extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const ModernProgressStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  State<ModernProgressStepper> createState() => _ModernProgressStepperState();
}

class _ModernProgressStepperState extends State<ModernProgressStepper>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(ModernProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Complete Your Profile",
                style: getbodyStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealColor,
                      AppColors.tealColor.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tealColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "${((widget.currentStep + 1) / widget.totalSteps * 100).round()}%",
                  style: getbodyStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),

          // Step Indicators
          Row(
            children: List.generate(widget.totalSteps, (index) {
              final isCompleted = index < widget.currentStep;
              final isCurrent = index == widget.currentStep;
              final isActive = isCompleted || isCurrent;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          // Step Circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.tealColor,
                                        AppColors.tealColor.withOpacity(0.8)
                                      ],
                                    )
                                  : null,
                              color: isActive
                                  ? null
                                  : Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.tealColor
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : _getStepIcon(index),
                                key: ValueKey('$index-$isCompleted'),
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                size: 20,
                              ),
                            ),
                          ),
                          const Gap(8),

                          // Step Title
                          Text(
                            widget.stepTitles[index],
                            style: getbodyStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Connecting Line
                    if (index < widget.totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: index < widget.currentStep
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.tealColor,
                                        AppColors.tealColor.withOpacity(0.8)
                                      ],
                                    )
                                  : null,
                              color: index < widget.currentStep
                                  ? null
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person_outline_rounded;
      case 1:
        return Icons.badge_outlined;
      case 2:
        return Icons.verified_user_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

// Enhanced Bottom Sheet for Image Source Selection
class ModernImageSourceSheet extends StatelessWidget {
  const ModernImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.splashBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(20),

          // Title
          Text(
            "Choose Image Source",
            style: getbodyStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            "Select your preferred method to upload the image",
            style: getbodyStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),

          // Options
          Row(
            children: [
              Expanded(
                child: _buildSourceOption(
                  context,
                  icon: Icons.camera_alt_rounded,
                  title: "Camera",
                  subtitle: "Take a photo",
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildSourceOption(
                  context,
                  icon: Icons.photo_library_rounded,
                  title: "Gallery",
                  subtitle: "Choose from gallery",
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.tealColor.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.tealColor,
                        AppColors.tealColor.withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Gap(12),
                Text(
                  title,
                  style: getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern OneMoreStep Screen with Dark Theme
class OneMoreStepScreen extends StatefulWidget {
  const OneMoreStepScreen({super.key});

  @override
  State<OneMoreStepScreen> createState() => _OneMoreStepScreenState();
}

class _OneMoreStepScreenState extends State<OneMoreStepScreen>
    with TickerProviderStateMixin {
  // State variables
  File? _profilePic;
  File? _idFront;
  File? _idBack;
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _stepTitles = [
    "Profile Picture",
    "Egyptian ID Scan",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<ImageSource?> _showImageSourceSelector() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ModernImageSourceSheet(),
    );
  }

  Future<void> _pickProfilePicture() async {
    try {
      final source = await _showImageSourceSelector();
      if (source == null) return;

      final pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage != null && mounted) {
        setState(() {
          _profilePic = File(pickedImage.path);
        });
      }
    } catch (e) {
      if (mounted) {
        showGlobalSnackBar(
          context,
          "Error selecting image: ${e.toString()}",
          isError: true,
        );
      }
    }
  }

  Future<void> _pickIdImage(String side) async {
    try {
      final source = await _showImageSourceSelector();
      if (source == null) return;

      final pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage != null && mounted) {
        setState(() {
          if (side == 'front') {
            _idFront = File(pickedImage.path);
          } else {
            _idBack = File(pickedImage.path);
          }
        });

        showGlobalSnackBar(
          context,
          "✅ Egyptian ID ${side} uploaded successfully!",
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlobalSnackBar(
          context,
          "Error selecting image: ${e.toString()}",
          isError: true,
        );
      }
    }
  }

  void _uploadFiles() {
    if (_profilePic != null && _idFront != null && _idBack != null) {
      context.read<AuthBloc>().add(UploadIdEvent(
            profilePic: _profilePic!,
            idFront: _idFront!,
            idBack: _idBack!,
          ));
    }
  }

  void _continue(bool isLoading) {
    if (isLoading) return;

    switch (_currentStep) {
      case 0:
        if (_profilePic == null) {
          showGlobalSnackBar(context, "Please upload your profile picture.");
          return;
        }
        setState(() => _currentStep = 1);
        break;
      case 1:
        if (_idFront == null || _idBack == null) {
          showGlobalSnackBar(
              context, "Please scan both sides of your Egyptian ID.");
          return;
        }
        _uploadFiles();
        break;
    }
  }

  void _back(bool isLoading) {
    if (isLoading || _currentStep <= 0) return;
    setState(() => _currentStep--);
  }

  void _skip(bool isLoading) {
    if (isLoading) return;
    pushReplacement(context, const MainNavigationView());
  }

  Widget _buildEmailVerificationReminder() {
    // Check if current user email is verified
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink(); // Don't show if verified or no user
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade800.withOpacity(0.2),
            Colors.orange.shade700.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade600.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: Colors.orange.shade300,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📧 Email Verification Reminder",
                  style: getbodyStyle(
                    color: Colors.orange.shade200,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Please verify your email (${user.email}) for full account access.",
                  style: getbodyStyle(
                    color: Colors.orange.shade300,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _resendVerificationEmail(user),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              "Resend",
              style: getbodyStyle(
                color: Colors.orange.shade200,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      showGlobalSnackBar(
        context,
        "📧 Verification email sent to ${user.email}",
        isError: false,
      );
    } catch (e) {
      showGlobalSnackBar(
        context,
        "Failed to send verification email. Please try again.",
        isError: true,
      );
    }
  }

  Widget _buildCurrentStepContent(bool isLoading) {
    if (_currentStep == 0) {
      // Profile Picture Step
      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 400;

          return Column(
            children: [
              Gap(isSmallScreen ? 12.0 : 20.0),
              Text(
                "Upload Profile Picture",
                style: getbodyStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(isSmallScreen ? 4.0 : 8.0),
              Text(
                "Choose a clear photo of yourself for your profile",
                style: getbodyStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(isSmallScreen ? 16.0 : 24.0),
              ModernUploadField(
                title: "Profile Picture",
                description: "Tap to upload or take a photo",
                icon: Icons.person_outline_rounded,
                file: _profilePic,
                onTap: _pickProfilePicture,
                isLoading: isLoading,
              ),
            ],
          );
        },
      );
    } else {
      // Egyptian ID Scan Step
      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 500;
          final availableHeight = constraints.maxHeight;
          final headerHeight = isSmallScreen ? 80.0 : 100.0;
          final statusHeight = (_idFront != null && _idBack != null)
              ? (isSmallScreen ? 60.0 : 80.0)
              : 0.0;
          final cameraHeight =
              availableHeight - headerHeight - statusHeight - 32; // 32 for gaps

          return Column(
            children: [
              // Header Section
              Container(
                height: headerHeight,
                child: Column(
                  children: [
                    Gap(isSmallScreen ? 8.0 : 12.0),
                    Text(
                      "Scan Egyptian ID",
                      style: getbodyStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(isSmallScreen ? 4.0 : 8.0),
                    Text(
                      "Using main camera for best quality - position your Egyptian ID to capture both sides",
                      style: getbodyStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isSmallScreen ? 11 : 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Gap(isSmallScreen ? 12.0 : 16.0),

              // Egyptian ID Upload Fields - Simple like profile photo
              Column(
                children: [
                  ModernUploadField(
                    title: "Egyptian ID - Front Side",
                    description: "Upload a clear photo of the front side",
                    icon: Icons.badge_outlined,
                    file: _idFront,
                    onTap: () => _pickIdImage('front'),
                    isLoading: isLoading,
                  ),
                  const Gap(16),
                  ModernUploadField(
                    title: "Egyptian ID - Back Side",
                    description: "Upload a clear photo of the back side",
                    icon: Icons.flip_to_back_outlined,
                    file: _idBack,
                    onTap: () => _pickIdImage('back'),
                    isLoading: isLoading,
                  ),
                ],
              ),

              if (statusHeight > 0) Gap(isSmallScreen ? 8.0 : 12.0),

              // Status Display - Only show if both captured
              if (_idFront != null && _idBack != null)
                Container(
                  height: statusHeight,
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  decoration: BoxDecoration(
                    color: AppColors.tealColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.tealColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: AppColors.tealColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      Gap(isSmallScreen ? 8.0 : 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Egyptian ID Successfully Captured",
                              style: getbodyStyle(
                                color: AppColors.tealColor,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isSmallScreen) const Gap(4),
                            if (!isSmallScreen)
                              Text(
                                "Both front and back sides have been captured",
                                style: getbodyStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UploadIdSuccessState) {
          showGlobalSnackBar(context, "Documents uploaded successfully!");

          final userModel = state.user;
          String? firstName;
          if (userModel.name.isNotEmpty) {
            firstName = userModel.name.split(' ').firstWhere(
                  (s) => s.isNotEmpty,
                  orElse: () => '',
                );
          }
          String? profileUrl = userModel.profilePicUrl ?? userModel.image;

          pushReplacement(
              context,
              LoginSuccessAnimationView(
                profilePicUrl: profileUrl,
                firstName: firstName,
              ));
        } else if (state is AuthErrorState) {
          showGlobalSnackBar(context, state.message, isError: true);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Scaffold(
            backgroundColor: AppColors.splashBackground,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    AppColors.splashBackground,
                  ],
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenHeight = constraints.maxHeight;
                        final isSmallScreen = screenHeight < 700;

                        return Column(
                          children: [
                            // Premium App Bar - Responsive sizing
                            Container(
                              margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: isLoading
                                            ? null
                                            : () {
                                                context.toSignIn(
                                                    const LoginView());
                                              },
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "Complete Profile",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.tealColor,
                                          AppColors.tealColor.withOpacity(0.8)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Step ${_currentStep + 1}/2",
                                      style: getbodyStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Email Verification Reminder (if needed) - Responsive
                            _buildEmailVerificationReminder(),

                            // Progress Stepper - Responsive
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20),
                              child: ModernProgressStepper(
                                currentStep: _currentStep,
                                totalSteps: 2,
                                stepTitles: _stepTitles,
                              ),
                            ),

                            // Main Content - Scrollable to prevent overflow
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20),
                                child: _buildCurrentStepContent(isLoading),
                              ),
                            ),

                            // Action Buttons - Fixed at bottom
                            Container(
                              margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      if (_currentStep > 0) ...[
                                        Expanded(
                                          child: Container(
                                            height: isSmallScreen ? 48 : 52,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.tealColor
                                                    .withOpacity(0.5),
                                                width: 1.5,
                                              ),
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.tealColor
                                                      .withOpacity(0.1),
                                                  AppColors.tealColor
                                                      .withOpacity(0.05),
                                                ],
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: isLoading
                                                    ? null
                                                    : () => _back(isLoading),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_back,
                                                        color:
                                                            AppColors.tealColor,
                                                        size: 18,
                                                      ),
                                                      const Gap(8),
                                                      Text(
                                                        "Back",
                                                        style: getbodyStyle(
                                                          color: AppColors
                                                              .tealColor,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Gap(12),
                                      ],
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          height: isSmallScreen ? 48 : 52,
                                          decoration: BoxDecoration(
                                            gradient: isLoading
                                                ? LinearGradient(
                                                    colors: [
                                                      Colors.grey
                                                          .withOpacity(0.3),
                                                      Colors.grey
                                                          .withOpacity(0.2),
                                                    ],
                                                  )
                                                : LinearGradient(
                                                    colors: [
                                                      AppColors.tealColor,
                                                      AppColors.tealColor
                                                          .withOpacity(0.8)
                                                    ],
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: isLoading
                                                ? []
                                                : [
                                                    BoxShadow(
                                                      color: AppColors.tealColor
                                                          .withOpacity(0.4),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: isLoading
                                                  ? null
                                                  : () => _continue(isLoading),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Center(
                                                child: isLoading
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                          const Gap(12),
                                                          Text(
                                                            "Processing...",
                                                            style: getbodyStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            _currentStep == 1
                                                                ? "Complete Setup"
                                                                : "Continue",
                                                            style: getbodyStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const Gap(8),
                                                          Icon(
                                                            _currentStep == 1
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons
                                                                    .arrow_forward,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Gap(isSmallScreen ? 12.0 : 16.0),

                                  // Skip Button
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _skip(isLoading),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: isSmallScreen ? 8.0 : 12.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.skip_next,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 16,
                                        ),
                                        const Gap(6),
                                        Text(
                                          "Skip for now",
                                          style: getbodyStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
