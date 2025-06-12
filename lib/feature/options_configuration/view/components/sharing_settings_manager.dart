import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';

class SharingSettingsManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(bool, bool, List<String>?) onSharingSettingsChanged;

  const SharingSettingsManager({
    super.key,
    required this.state,
    required this.onSharingSettingsChanged,
  });

  @override
  State<SharingSettingsManager> createState() => _SharingSettingsManagerState();
}

class _SharingSettingsManagerState extends State<SharingSettingsManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _slideAnimation;

  bool _enableSocialSharing = false;
  List<String> _selectedPlatforms = [];

  final List<SharingPlatform> _sharingPlatforms = [
    SharingPlatform(
      id: 'facebook',
      name: 'Facebook',
      icon: CupertinoIcons.person_2_square_stack,
      color: const Color(0xFF4267B2),
    ),
    SharingPlatform(
      id: 'twitter',
      name: 'Twitter',
      icon: CupertinoIcons.chat_bubble_2,
      color: const Color(0xFF1DA1F2),
    ),
    SharingPlatform(
      id: 'instagram',
      name: 'Instagram',
      icon: CupertinoIcons.camera,
      color: const Color(0xFFE4405F),
    ),
    SharingPlatform(
      id: 'whatsapp',
      name: 'WhatsApp',
      icon: CupertinoIcons.phone,
      color: const Color(0xFF25D366),
    ),
    SharingPlatform(
      id: 'telegram',
      name: 'Telegram',
      icon: CupertinoIcons.paperplane,
      color: const Color(0xFF0088CC),
    ),
    SharingPlatform(
      id: 'linkedin',
      name: 'LinkedIn',
      icon: CupertinoIcons.briefcase,
      color: const Color(0xFF0E76A8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialState();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_cardAnimation);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
  }

  void _setupInitialState() {
    // Initialize with default values since these properties may not exist in state
    // Will be populated from user preferences or default settings
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _updateSharingSettings() {
    widget.onSharingSettingsChanged(
      _enableSocialSharing,
      true, // Privacy setting - always enabled
      _selectedPlatforms.isNotEmpty ? _selectedPlatforms : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSocialSharingToggle(),
            if (_enableSocialSharing) ...[
              const Gap(20),
              _buildPlatformSelector(),
            ],
            const Gap(20),
            _buildPrivacyInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSharingToggle() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.tealColor],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.share,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social Sharing',
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _enableSocialSharing
                        ? 'Share your booking on social media'
                        : 'Keep your booking private',
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            CupertinoSwitch(
              value: _enableSocialSharing,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _enableSocialSharing = value;
                  if (!value) {
                    _selectedPlatforms.clear();
                  }
                });
                _updateSharingSettings();
              },
              activeColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cyanColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.device_phone_portrait,
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
                        'Sharing Platforms',
                        style: AppTextStyle.getTitleStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Select platforms to share on',
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.lightText.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _sharingPlatforms.map((platform) {
                return _buildPlatformCard(platform);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(SharingPlatform platform) {
    final isSelected = _selectedPlatforms.contains(platform.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isSelected) {
            _selectedPlatforms.remove(platform.id);
          } else {
            _selectedPlatforms.add(platform.id);
          }
        });
        _updateSharingSettings();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    platform.color.withOpacity(0.3),
                    platform.color.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? platform.color.withOpacity(0.8)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isSelected ? platform.color : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                platform.icon,
                color: isSelected
                    ? Colors.white
                    : AppColors.lightText.withOpacity(0.7),
                size: 18,
              ),
            ),
            const Gap(4),
            Text(
              platform.name,
              style: AppTextStyle.getbodyStyle(
                color: isSelected
                    ? AppColors.lightText
                    : AppColors.lightText.withOpacity(0.7),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.greenColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.lock_shield,
                color: AppColors.greenColor,
                size: 16,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Protected',
                    style: AppTextStyle.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Your personal information is never shared without permission. Only selected details will be shared based on your preferences.',
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharingPlatform {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const SharingPlatform({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
