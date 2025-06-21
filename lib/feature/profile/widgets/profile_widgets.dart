import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

/// Premium profile header with glass morphism design
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onEditTap;
  final VoidCallback? onImageTap;
  final bool isImageUploading;
  final double uploadProgress;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = false,
    this.onEditTap,
    this.onImageTap,
    this.isImageUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F0F23).withOpacity(0.9),
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF16213E).withOpacity(0.7),
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor.withOpacity(0.3),
                                AppColors.tealColor.withOpacity(0.3),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: buildProfilePlaceholder(
                              imageUrl: profile.profilePicUrl,
                              name: profile.name,
                              size: 96,
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                        ),

                        // Online Status
                        if (profile.isOnline)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Gap(20),

                    // Profile Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (profile.isVerified)
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            '@${profile.username}',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const Gap(8),
                          // Account Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: profile.stats.accountType == 'premium'
                                    ? [Colors.amber, Colors.orange]
                                    : [
                                        AppColors.primaryColor,
                                        AppColors.tealColor
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile.stats.accountType.toUpperCase(),
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.bio?.isNotEmpty == true) ...[
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      profile.bio!,
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile statistics display
class ProfileStatsWidget extends StatelessWidget {
  final ProfileStats stats;
  final VoidCallback? onFriendsClick;
  final VoidCallback? onAchievementsClick;

  const ProfileStatsWidget({
    super.key,
    required this.stats,
    this.onFriendsClick,
    this.onAchievementsClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatItem(
                  label: 'Friends',
                  value: stats.friendsCount.toString(),
                  onTap: onFriendsClick,
                  icon: CupertinoIcons.person_2_fill,
                  color: AppColors.primaryColor,
                ),
                _buildStatItem(
                  label: 'Bookings',
                  value: stats.reservationsCount.toString(),
                  icon: CupertinoIcons.calendar,
                  color: AppColors.tealColor,
                ),
                _buildStatItem(
                  label: 'Achievements',
                  value: stats.achievementsCount.toString(),
                  onTap: onAchievementsClick,
                  icon: CupertinoIcons.star_fill,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: onTap != null
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Gap(8),
              Text(
                value,
                style: AppTextStyle.getTitleStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(4),
              Text(
                label,
                style: AppTextStyle.getSmallStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friend action buttons for profile
class ProfileActionButtons extends StatelessWidget {
  final FriendshipStatus? friendshipStatus;
  final bool isOwnProfile;
  final VoidCallback? onSendFriendRequest;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onUnsendRequest;
  final bool isProcessing;

  const ProfileActionButtons({
    super.key,
    this.friendshipStatus,
    this.isOwnProfile = false,
    this.onSendFriendRequest,
    this.onAcceptRequest,
    this.onUnsendRequest,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: _buildPrimaryActionButton(),
    );
  }

  Widget _buildPrimaryActionButton() {
    if (isProcessing) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.7),
              AppColors.tealColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
      );
    }

    String label;
    IconData icon;
    VoidCallback? onTap;
    List<Color> colors;

    switch (friendshipStatus) {
      case FriendshipStatus.none:
        label = 'Add Friend';
        icon = CupertinoIcons.person_add_solid;
        onTap = onSendFriendRequest;
        colors = [AppColors.primaryColor, AppColors.tealColor];
        break;

      case FriendshipStatus.requestSent:
        label = 'Request Sent';
        icon = CupertinoIcons.clock;
        onTap = onUnsendRequest;
        colors = [Colors.orange, Colors.orange.shade600];
        break;

      case FriendshipStatus.requestReceived:
        label = 'Accept Request';
        icon = CupertinoIcons.check_mark_circled_solid;
        onTap = onAcceptRequest;
        colors = [Colors.green, Colors.green.shade600];
        break;

      case FriendshipStatus.friends:
        label = 'Friends';
        icon = CupertinoIcons.check_mark;
        onTap = null;
        colors = [Colors.grey.shade600, Colors.grey.shade700];
        break;

      default:
        label = 'Add Friend';
        icon = CupertinoIcons.person_add_solid;
        onTap = onSendFriendRequest;
        colors = [AppColors.primaryColor, AppColors.tealColor];
    }

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const Gap(8),
            Text(
              label,
              style: AppTextStyle.getbodyStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
