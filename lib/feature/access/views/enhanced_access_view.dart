import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/shamil_nfc_service.dart';
import '../../../services/models/global_access_models.dart';
import '../widgets/nfc_response_bottom_sheet.dart';
import '../widgets/nfc_settings_section.dart';
import '../data/nfc_sound_service.dart';

class EnhancedAccessView extends StatefulWidget {
  const EnhancedAccessView({super.key});

  @override
  State<EnhancedAccessView> createState() => _EnhancedAccessViewState();
}

class _EnhancedAccessViewState extends State<EnhancedAccessView>
    with TickerProviderStateMixin {
  late ShamIlNFCService _globalNFCService;
  late AnimationController _animationController;
  late AnimationController _nfcPulseController;
  late AnimationController _qrController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _qrScaleAnimation;
  late Animation<double> _nfcPulseAnimation;

  String? _userId;
  String? _userName;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _hasError = false;
  bool _nfcEnabled = true;
  String _nfcStatus = 'Initializing...';
  bool _isNFCListening = false;
  AccessResponseModel? _lastResponse;

  final NFCSoundService _soundService = NFCSoundService();

  @override
  void initState() {
    super.initState();
    _globalNFCService = ShamIlNFCService();
    _initializeAnimations();
    _setupNFCListeners();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _nfcPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _qrController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    _nfcPulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _nfcPulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupNFCListeners() {
    _globalNFCService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _nfcStatus = status;
          _isNFCListening =
              status.contains('listening') || status.contains('Active');
        });

        if (_isNFCListening) {
          _nfcPulseController.repeat(reverse: true);
        } else {
          _nfcPulseController.stop();
          _nfcPulseController.reset();
        }
      }
    });

    _globalNFCService.responseStream.listen((response) {
      if (mounted) {
        setState(() {
          _lastResponse = response;
        });

        _playHapticFeedback(response);

        _showInScreenResponse(response);
      }
    });
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

      _startInitializationSequence();
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

  void _startInitializationSequence() async {
    await _soundService.initialize();

    await _loadNFCSettings();

    _animationController.forward();
    _qrController.forward();

    await _globalNFCService.updateUserData();

    if (_nfcEnabled && _globalNFCService.isAvailable) {
      setState(() {
        _nfcStatus = 'Ready for NFC access';
      });
    }
  }

  Future<void> _loadNFCSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nfcEnabled = prefs.getBool('nfc_enabled') ?? true;
      });
    } catch (e) {
      debugPrint('Error loading NFC settings: $e');
    }
  }

  /// Check and update NFC service status
  void _updateNFCStatus() {
    setState(() {
      _nfcStatus = _globalNFCService.isAvailable
          ? 'Global NFC Service Ready'
          : 'NFC Not Available';
    });
  }

  void _playHapticFeedback(AccessResponseModel response) {
    final soundService = NFCSoundService();
    if (response.success) {
      soundService.playAccessGrantedSequence();
    } else {
      soundService.playAccessDeniedSequence();
    }
  }

  void _showInScreenResponse(AccessResponseModel response) {
    showGlobalSnackBar(
      context,
      response.success
          ? '✅ Access Granted: ${response.userName ?? "User"}'
          : '❌ Access Denied: ${response.reason ?? "Unknown error"}',
      isError: !response.success,
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _lastResponse = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nfcPulseController.dispose();
    _qrController.dispose();
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

    return _buildMainScreen();
  }

  Widget _buildLoadingScreen() {
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
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                      'Initializing Global NFC Service...',
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

  Widget _buildErrorScreen() {
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
              border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            child: Text(
                              'Go Back',
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
  }

  Widget _buildMainScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
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
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
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
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
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
          "Global NFC Access",
          style: AppTextStyle.getTitleStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        // NFC Status Indicator with StreamBuilder
        StreamBuilder<String>(
          stream: _globalNFCService.statusStream,
          initialData: _nfcStatus,
          builder: (context, snapshot) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedBuilder(
                      animation: _nfcPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              _isNFCListening ? _nfcPulseAnimation.value : 1.0,
                          child: Icon(
                            CupertinoIcons.antenna_radiowaves_left_right,
                            color: _getNFCStatusColor(),
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Gap(12),
          _buildProfileSection(),
          const Gap(28),
          _buildQRCodeSection(),
          const Gap(28),
          _buildNFCStatusSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
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
                                  _buildProfilePlaceholder(),
                            )
                          : _buildProfilePlaceholder(),
                    ),
                  ),
                ),
                const Gap(16),
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
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
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
              ],
            ),
          ),
        ),
      ),
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
        CupertinoIcons.person_fill,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildQRCodeSection() {
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
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNFCStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
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
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _nfcPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              _isNFCListening ? _nfcPulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.antenna_radiowaves_left_right,
                              color: _getNFCStatusColor(),
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNFCStatusTitle(),
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            _getNFCStatusMessage(),
                            style: AppTextStyle.getbodyStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNFCStatusColor() {
    if (_isNFCListening) {
      return AppColors.tealColor;
    } else if (_nfcEnabled) {
      return Colors.white;
    } else {
      return Colors.white.withOpacity(0.5);
    }
  }

  String _getNFCStatusTitle() {
    if (_isNFCListening) {
      return 'NFC Active';
    } else if (_nfcEnabled) {
      return 'NFC Ready';
    } else {
      return 'NFC Status';
    }
  }

  String _getNFCStatusMessage() {
    if (_isNFCListening) {
      return 'Listening for access requests. Hold your device near an NFC reader.';
    } else if (_nfcEnabled) {
      return 'Ready to start listening for NFC access.';
    } else {
      return 'NFC is not available on this device or disabled.';
    }
  }
}
