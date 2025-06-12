import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shared_preferences/shared_preferences.dart';

class NFCSettingsSection extends StatefulWidget {
  const NFCSettingsSection({super.key});

  @override
  State<NFCSettingsSection> createState() => _NFCSettingsSectionState();
}

class _NFCSettingsSectionState extends State<NFCSettingsSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _nfcEnabled = true;
  bool _hapticFeedback = true;
  bool _soundEffects = true;
  bool _autoStart = true;
  bool _showNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (_nfcEnabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nfcEnabled = prefs.getBool('nfc_enabled') ?? true;
      _hapticFeedback = prefs.getBool('nfc_haptic_feedback') ?? true;
      _soundEffects = prefs.getBool('nfc_sound_effects') ?? true;
      _autoStart = prefs.getBool('nfc_auto_start') ?? true;
      _showNotifications = prefs.getBool('nfc_show_notifications') ?? true;
      _isLoading = false;
    });

    _animationController.forward();

    if (_nfcEnabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSettingsContent(),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: List.generate(
                5,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_nfcEnabled ? AppColors.tealColor : Colors.grey)
                .withOpacity(0.3),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(),
                const Gap(24),
                _buildSettingTile(
                  icon: CupertinoIcons.antenna_radiowaves_left_right,
                  title: 'Enable NFC Access',
                  subtitle: 'Allow automatic NFC access detection',
                  value: _nfcEnabled,
                  onChanged: (value) {
                    setState(() {
                      _nfcEnabled = value;
                    });
                    _updateSetting('nfc_enabled', value);

                    if (value) {
                      _pulseController.repeat(reverse: true);
                    } else {
                      _pulseController.stop();
                      _pulseController.reset();
                    }
                  },
                  isPrimary: true,
                ),
                const Gap(16),
                _buildSettingTile(
                  icon: CupertinoIcons.play_circle_fill,
                  title: 'Auto-Start Listening',
                  subtitle: 'Start NFC listening when opening access screen',
                  value: _autoStart,
                  onChanged: _nfcEnabled
                      ? (value) {
                          setState(() {
                            _autoStart = value;
                          });
                          _updateSetting('nfc_auto_start', value);
                        }
                      : null,
                ),
                const Gap(16),
                _buildSettingTile(
                  icon: CupertinoIcons.device_phone_portrait,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrate on NFC response',
                  value: _hapticFeedback,
                  onChanged: _nfcEnabled
                      ? (value) {
                          setState(() {
                            _hapticFeedback = value;
                          });
                          _updateSetting('nfc_haptic_feedback', value);
                        }
                      : null,
                ),
                const Gap(16),
                _buildSettingTile(
                  icon: CupertinoIcons.speaker_2_fill,
                  title: 'Sound Effects',
                  subtitle: 'Play sounds for NFC responses',
                  value: _soundEffects,
                  onChanged: _nfcEnabled
                      ? (value) {
                          setState(() {
                            _soundEffects = value;
                          });
                          _updateSetting('nfc_sound_effects', value);
                        }
                      : null,
                ),
                const Gap(16),
                _buildSettingTile(
                  icon: CupertinoIcons.bell_fill,
                  title: 'Show Notifications',
                  subtitle: 'Display notifications for NFC events',
                  value: _showNotifications,
                  onChanged: _nfcEnabled
                      ? (value) {
                          setState(() {
                            _showNotifications = value;
                          });
                          _updateSetting('nfc_show_notifications', value);
                        }
                      : null,
                ),
                const Gap(20),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _nfcEnabled ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _nfcEnabled
                        ? [
                            AppColors.tealColor.withOpacity(0.3),
                            AppColors.primaryColor.withOpacity(0.2),
                          ]
                        : [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: _nfcEnabled ? AppColors.tealColor : Colors.grey,
                  size: 24,
                ),
              ),
            );
          },
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                child: Text(
                  'NFC Settings',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(4),
              Text(
                'Configure your NFC access preferences',
                style: AppTextStyle.getbodyStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isPrimary = false,
  }) {
    final isEnabled = onChanged != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary && value
              ? [
                  AppColors.tealColor.withOpacity(0.15),
                  AppColors.primaryColor.withOpacity(0.1),
                ]
              : [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary && value
              ? AppColors.tealColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () {
                  onChanged!(!value);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isPrimary && value
                            ? AppColors.tealColor
                            : Colors.white)
                        .withOpacity(isEnabled ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled
                        ? (isPrimary && value
                            ? AppColors.tealColor
                            : Colors.white)
                        : Colors.white.withOpacity(0.5),
                    size: 20,
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
                          color: isEnabled
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        subtitle,
                        style: AppTextStyle.getbodyStyle(
                          fontSize: 12,
                          color: isEnabled
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Transform.scale(
                  scale: 0.9,
                  child: CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: isPrimary
                        ? AppColors.tealColor
                        : AppColors.primaryColor,
                    trackColor: Colors.white.withOpacity(0.2),
                    thumbColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.info_circle_fill,
              color: Colors.blue.shade300,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About NFC Access',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  'NFC access allows you to quickly authenticate by holding your device near compatible readers. Ensure NFC is enabled in your device settings.',
                  style: AppTextStyle.getbodyStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Static method to get current settings
  static Future<Map<String, bool>> getCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nfc_enabled': prefs.getBool('nfc_enabled') ?? true,
      'nfc_haptic_feedback': prefs.getBool('nfc_haptic_feedback') ?? true,
      'nfc_sound_effects': prefs.getBool('nfc_sound_effects') ?? true,
      'nfc_auto_start': prefs.getBool('nfc_auto_start') ?? true,
      'nfc_show_notifications': prefs.getBool('nfc_show_notifications') ?? true,
    };
  }
}
