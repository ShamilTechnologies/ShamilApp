import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import '../data/models/nfc_models.dart';
import '../data/enhanced_nfc_service.dart';

class NFCResponseBottomSheet extends StatefulWidget {
  final NFCAccessResponse response;
  final VoidCallback? onClose;

  const NFCResponseBottomSheet({
    super.key,
    required this.response,
    this.onClose,
  });

  @override
  State<NFCResponseBottomSheet> createState() => _NFCResponseBottomSheetState();
}

class _NFCResponseBottomSheetState extends State<NFCResponseBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _statusController;
  late AnimationController _detailsController;
  late AnimationController _pulseController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _statusScaleAnimation;
  late Animation<double> _detailsFadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Status animation
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Details animation
    _detailsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _statusScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.elasticOut,
    ));

    _detailsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _detailsController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    // Start entry animations
    _slideController.forward();
    _fadeController.forward();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Delay and start status animation
    await Future.delayed(const Duration(milliseconds: 200));
    _statusController.forward();

    // Start pulse for success states
    if (widget.response.accessGranted) {
      _pulseController.repeat(reverse: true);
    }

    // Show details after status animation
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _showDetails = true;
    });
    _detailsController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _statusController.dispose();
    _detailsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isGranted = widget.response.accessGranted;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * screenHeight * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.75,
                minHeight: 300,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isGranted ? AppColors.tealColor : Colors.red)
                        .withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.bottomSheetBackground.withOpacity(0.95),
                          AppColors.bottomSheetBackground.withOpacity(0.9),
                          AppColors.bottomSheetBackground.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        _buildHandle(),

        // Header
        _buildHeader(),

        // Status Section
        _buildStatusSection(),

        // Details Section
        if (_showDetails) _buildDetailsSection(),

        // Action Buttons
        if (_showDetails) _buildActionButtons(),

        const Gap(20),
      ],
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.3),
                  AppColors.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NFC Access Response',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'From ${widget.response.serviceProvider}',
                  style: AppTextStyle.getbodyStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeBottomSheet,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.xmark,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isGranted = widget.response.accessGranted;

    return AnimatedBuilder(
      animation: _statusScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statusScaleAnimation.value,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isGranted ? _pulseAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isGranted
                          ? [
                              AppColors.tealColor.withOpacity(0.3),
                              AppColors.primaryColor.withOpacity(0.2),
                            ]
                          : [
                              Colors.red.withOpacity(0.3),
                              Colors.orange.withOpacity(0.2),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Status Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isGranted
                                ? [AppColors.tealColor, AppColors.primaryColor]
                                : [Colors.red, Colors.orange],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isGranted ? AppColors.tealColor : Colors.red)
                                      .withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isGranted
                              ? CupertinoIcons.checkmark_shield_fill
                              : CupertinoIcons.xmark_shield_fill,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const Gap(16),

                      // Status Text
                      Text(
                        isGranted ? 'Access Granted' : 'Access Denied',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(8),

                      // Reason
                      Text(
                        widget.response.reason,
                        style: AppTextStyle.getbodyStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Processing Time Badge
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Processed in ${widget.response.processingTime}ms',
                          style: AppTextStyle.getbodyStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _buildDetailsSection() {
    return FadeTransition(
      opacity: _detailsFadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access Details',
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Gap(16),

            // Details Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  if (widget.response.userName != null)
                    _buildDetailRow(
                      icon: CupertinoIcons.person_fill,
                      label: 'User',
                      value: widget.response.userName!,
                    ),
                  if (widget.response.accessType != null)
                    _buildDetailRow(
                      icon: CupertinoIcons.ticket_fill,
                      label: 'Access Type',
                      value: widget.response.accessType!.toUpperCase(),
                    ),
                  if (widget.response.validUntil != null)
                    _buildDetailRow(
                      icon: CupertinoIcons.time_solid,
                      label: 'Valid Until',
                      value: _formatDateTime(widget.response.validUntil!),
                    ),
                  if (widget.response.additionalData?.location != null)
                    _buildDetailRow(
                      icon: CupertinoIcons.location_solid,
                      label: 'Location',
                      value: widget.response.additionalData!.location!,
                    ),
                  if (widget.response.additionalData?.facility != null)
                    _buildDetailRow(
                      icon: CupertinoIcons.building_2_fill,
                      label: 'Facility',
                      value: widget.response.additionalData!.facility!,
                    ),
                  _buildDetailRow(
                    icon: CupertinoIcons.device_phone_portrait,
                    label: 'Device UID',
                    value: widget.response.mobileUid.length > 16
                        ? '${widget.response.mobileUid.substring(0, 16)}...'
                        : widget.response.mobileUid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ),
          const Gap(12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyle.getbodyStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyle.getbodyStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _detailsFadeAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Row(
          children: [
            // Share Button
            Expanded(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _shareResponse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.share,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const Gap(8),
                        Text(
                          'Share',
                          style: AppTextStyle.getbodyStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Gap(12),

            // Done Button
            Expanded(
              flex: 2,
              child: Material(
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _closeBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.response.accessGranted
                            ? [AppColors.tealColor, AppColors.primaryColor]
                            : [
                                Colors.red.withOpacity(0.8),
                                Colors.orange.withOpacity(0.8)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.response.accessGranted
                                  ? AppColors.primaryColor
                                  : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: Colors.white,
                          size: 18,
                        ),
                        const Gap(8),
                        Text(
                          'Done',
                          style: AppTextStyle.getbodyStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = dateTime.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours % 24}h';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Expired';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _shareResponse() {
    // TODO: Implement share functionality
    HapticFeedback.lightImpact();
    // You can use the share_plus package here
  }

  void _closeBottomSheet() {
    HapticFeedback.lightImpact();
    if (widget.onClose != null) {
      widget.onClose!();
    }
    Navigator.of(context).pop();
  }
}

// Helper function to show the NFC response bottom sheet
void showNFCResponseBottomSheet(
  BuildContext context,
  NFCAccessResponse response, {
  VoidCallback? onClose,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    enableDrag: true,
    isDismissible: true,
    builder: (context) => NFCResponseBottomSheet(
      response: response,
      onClose: onClose,
    ),
  );
}
