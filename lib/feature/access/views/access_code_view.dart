import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import the access content widget and bloc
import 'package:shamil_mobile_app/feature/access/widgets/access_code_content.dart';
import 'package:shamil_mobile_app/feature/access/bloc/access_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
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
  late AnimationController _backgroundController;
  late AnimationController _qrController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _qrScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

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
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    // QR code scale animation
    _qrController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse animation for NFC indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _qrScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qrController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _backgroundController.repeat();
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
      _slideController.forward();
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
    _backgroundController.dispose();
    _qrController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _accessBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError || _userId == null) {
      return _buildErrorScreen();
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
        child: _buildMainScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: _buildGradientDecoration(),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: _buildGradientDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.white,
              ),
              const Gap(16),
              const Text(
                "Unable to load user data",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: _buildAnimatedGradientDecoration(),
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _slideController,
                  child: _buildContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: const Text(
        "Access Code",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Gap(20),
          _buildProfileSection(),
          const Gap(40),
          _buildQRCodeSection(),
          const Gap(40),
          _buildNFCSection(),
          const Gap(40),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: _profileImageUrl != null
                ? Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildProfilePlaceholder(),
                  )
                : _buildProfilePlaceholder(),
          ),
        ),
        const Gap(16),
        Text(
          _userName ?? "User",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            "Present this code for access",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
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
        Icons.person_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return ScaleTransition(
      scale: _qrScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _userId ?? "error",
                version: QrVersions.auto,
                size: 200,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const Gap(16),
            Text(
              "Scan QR Code",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              "Hold your device steady for scanning",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFCSection() {
    if (!_nfcAvailable) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _nfcActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_nfcActive ? Colors.green : Colors.grey)
                        .withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.nfc_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nfcActive ? "NFC Ready" : "NFC Inactive",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  _nfcActive
                      ? "Tap your device to another NFC device"
                      : "NFC is not available",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_rounded,
                title: "My Events",
                subtitle: "View upcoming",
                onTap: () {
                  // Navigate to events
                },
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.confirmation_number_rounded,
                title: "My Passes",
                subtitle: "Digital tickets",
                onTap: () {
                  // Navigate to passes
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const Gap(8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryColor,
          AppColors.secondaryColor,
          AppColors.tealColor,
        ],
      ),
    );
  }

  BoxDecoration _buildAnimatedGradientDecoration() {
    final progress = _backgroundAnimation.value;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.lerp(
              Alignment.topLeft,
              Alignment.topRight,
              progress,
            ) ??
            Alignment.topLeft,
        end: Alignment.lerp(
              Alignment.bottomRight,
              Alignment.bottomLeft,
              progress,
            ) ??
            Alignment.bottomRight,
        colors: [
          Color.lerp(AppColors.primaryColor, AppColors.tealColor,
                  progress * 0.5) ??
              AppColors.primaryColor,
          AppColors.secondaryColor,
          Color.lerp(
                  AppColors.tealColor, AppColors.purpleColor, progress * 0.3) ??
              AppColors.tealColor,
        ],
      ),
    );
  }
}
