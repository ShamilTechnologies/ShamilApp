import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import the access content widget and bloc
import 'package:shamil_mobile_app/feature/access/bloc/access_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gap/gap.dart';

class AccessCodeView extends StatefulWidget {
  const AccessCodeView({super.key});

  @override
  State<AccessCodeView> createState() => _AccessCodeViewState();
}

class _AccessCodeViewState extends State<AccessCodeView>
    with TickerProviderStateMixin {
  late AccessBloc _accessBloc;
  late AnimationController _animationController;
  late AnimationController _orbAnimationController;
  late AnimationController _qrController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _qrScaleAnimation;
  late Animation<double> _pulseAnimation;

  String? _userId;
  String? _userName;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _hasError = false;
  bool _nfcAvailable = false;
  bool _nfcActive = false;

  @override
  void initState() {
    super.initState();
    _accessBloc = AccessBloc();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Floating orbs animation
    _orbAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // QR code scale animation
    _qrController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Pulse animation for NFC indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

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

    _qrScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qrController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;

    if (authState is LoginSuccessState) {
      _userId = authState.user.uid;
      _userName = authState.user.name;
      _profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;

      if (_profileImageUrl?.isEmpty ?? true) {
        _profileImageUrl = null;
      }

      setState(() {
        _isLoading = false;
      });

      // Start entry animations
      _animationController.forward();
      _qrController.forward();

      // Check NFC and activate
      _checkNFCAvailability();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showGlobalSnackBar(context, "User data not available.",
              isError: true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.maybePop(context);
          });
        }
      });
    }
  }

  void _checkNFCAvailability() {
    if (mounted) {
      _accessBloc.add(CheckNFCAvailabilityEvent());
    }
  }

  void _activateNFC() {
    if (mounted && _userId != null && _userId!.isNotEmpty) {
      _accessBloc.add(ActivateNFCEvent());
      setState(() {
        _nfcActive = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _orbAnimationController.dispose();
    _qrController.dispose();
    _pulseController.dispose();
    _accessBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPremiumLoadingScreen();
    }

    if (_hasError || _userId == null) {
      return _buildPremiumErrorScreen();
    }

    return BlocProvider.value(
      value: _accessBloc,
      child: BlocListener<AccessBloc, AccessState>(
        listener: (context, state) {
          if (state is NFCAvailableState) {
            setState(() {
              _nfcAvailable = true;
            });
            if (!_nfcActive) _activateNFC();
          } else if (state is NFCUnavailableState) {
            setState(() {
              _nfcAvailable = false;
              _nfcActive = false;
            });
          } else if (state is NFCSuccessState) {
            showGlobalSnackBar(
              context,
              state.isWriteSuccess
                  ? "ID shared successfully via NFC!"
                  : "NFC tag read successfully!",
            );
          } else if (state is NFCErrorState) {
            showGlobalSnackBar(
              context,
              state.message ?? "NFC operation failed",
              isError: true,
            );
          }
        },
        child: _buildPremiumMainScreen(),
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
                      'Loading access code...',
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

  Widget _buildPremiumErrorScreen() {
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
                      'Unable to load user data',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(24),
                    Material(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
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
                              const Icon(CupertinoIcons.back,
                                  color: Colors.white),
                              const Gap(8),
                              Text(
                                'Go Back',
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMainScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildPremiumAppBar(),
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
            SafeArea(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPremiumContent(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Color(0xFFB8BCC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          "Access Code",
          style: AppTextStyle.getTitleStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
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
            ),
          );
        },
      ),

      // Small orb bottom right
      AnimatedBuilder(
        animation: _orbAnimationController,
        builder: (context, child) {
          return Positioned(
            bottom: 150 + (25 * _orbAnimationController.value),
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
            ),
          );
        },
      ),
    ];
  }

  Widget _buildPremiumContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Gap(12),
          _buildPremiumProfileSection(),
          const Gap(28),
          _buildPremiumQRCodeSection(),
          const Gap(28),
          if (_nfcAvailable) _buildPremiumNFCSection(),
          if (_nfcAvailable) const Gap(28),
          _buildPremiumQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildPremiumProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Optimized avatar with multiple layers
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.8),
                        AppColors.accentColor.withOpacity(0.8),
                        AppColors.tealColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPremiumProfilePlaceholder(),
                            )
                          : _buildPremiumProfilePlaceholder(),
                    ),
                  ),
                ),
                const Gap(16),

                // Optimized name with shader effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    _userName ?? "User",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Gap(6),

                // Optimized User ID badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "ID: ${_userId?.substring(0, 8) ?? 'XXXXXXXX'}...",
                    style: AppTextStyle.getbodyStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                const Gap(14),

                // Optimized instruction badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.9),
                        AppColors.accentColor.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_shield_fill,
                        color: Colors.white,
                        size: 14,
                      ),
                      const Gap(6),
                      Text(
                        "Present for Access",
                        style: AppTextStyle.getbodyStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumProfilePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildPremiumQRCodeSection() {
    return ScaleTransition(
      scale: _qrScaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealColor.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Optimized QR Code header with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.tealColor.withOpacity(0.3),
                              AppColors.tealColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.qrcode,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const Gap(8),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          "Access QR Code",
                          style: AppTextStyle.getTitleStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Optimized QR Code container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.tealColor.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: QrImageView(
                        data: _userId ?? "error",
                        version: QrVersions.auto,
                        size: 180,
                        gapless: false,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.grey.shade900,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),

                  // Optimized instruction text
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.camera_viewfinder,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const Gap(6),
                            Text(
                              "Scan to Verify Identity",
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          "Hold device steady • Ensure good lighting",
                          style: AppTextStyle.getbodyStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumNFCSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_nfcActive ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Optimized NFC icon with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _nfcActive
                            ? [
                                Colors.green.withOpacity(0.9),
                                Colors.green.shade600.withOpacity(0.8),
                                Colors.green.shade700.withOpacity(0.7),
                              ]
                            : [
                                Colors.grey.withOpacity(0.8),
                                Colors.grey.shade600.withOpacity(0.7),
                                Colors.grey.shade700.withOpacity(0.6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_nfcActive ? Colors.green : Colors.grey)
                              .withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: (_nfcActive ? Colors.green : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.nfc_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const Gap(16),

                // Optimized text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status with icon
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _nfcActive ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_nfcActive ? Colors.green : Colors.grey)
                                          .withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Text(
                            _nfcActive ? "NFC Active" : "NFC Unavailable",
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),

                      // Description
                      Text(
                        _nfcActive
                            ? "Ready to share access code via NFC"
                            : "NFC feature is not available on this device",
                        style: AppTextStyle.getbodyStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),

                      // Action instruction
                      if (_nfcActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.antenna_radiowaves_left_right,
                                color: Colors.white.withOpacity(0.9),
                                size: 12,
                              ),
                              const Gap(4),
                              Text(
                                "Tap to another NFC device",
                                style: AppTextStyle.getbodyStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced section header
        Container(
          margin: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.3),
                      AppColors.accentColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const Gap(10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                child: Text(
                  'Quick Actions',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Enhanced action cards
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionCard(
                icon: CupertinoIcons.calendar,
                title: "My Events",
                subtitle: "View upcoming",
                gradient: [
                  AppColors.primaryColor.withOpacity(0.3),
                  AppColors.primaryColor.withOpacity(0.1),
                ],
                glowColor: AppColors.primaryColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to events
                },
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildPremiumActionCard(
                icon: CupertinoIcons.ticket,
                title: "My Passes",
                subtitle: "Digital tickets",
                gradient: [
                  AppColors.tealColor.withOpacity(0.3),
                  AppColors.tealColor.withOpacity(0.1),
                ],
                glowColor: AppColors.tealColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to passes
                },
              ),
            ),
          ],
        ),
        const Gap(12),

        // Additional action cards row
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionCard(
                icon: CupertinoIcons.heart_fill,
                title: "Favorites",
                subtitle: "Saved items",
                gradient: [
                  AppColors.accentColor.withOpacity(0.3),
                  AppColors.accentColor.withOpacity(0.1),
                ],
                glowColor: AppColors.accentColor,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to favorites
                },
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildPremiumActionCard(
                icon: CupertinoIcons.person_2_fill,
                title: "Community",
                subtitle: "Connect & share",
                gradient: [
                  Colors.purple.withOpacity(0.3),
                  Colors.purple.withOpacity(0.1),
                ],
                glowColor: Colors.purple,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to community
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ultra-compact icon container
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const Gap(3),

                    // Ultra-compact title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.9),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        title,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ).copyWith(height: 1.2),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Ultra-compact subtitle
                    Text(
                      subtitle,
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ).copyWith(height: 1.2),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
