import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_bloc.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_event.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_state.dart';

/// Professional cover section with glass morphism design
class ProfileCoverSection extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onEditCover;

  const ProfileCoverSection({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.onEditCover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      child: Stack(
        children: [
          // Cover photo
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                  AppColors.tealColor,
                  const Color(0xFF8B5CF6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Cover photo functionality will be added later
                // No cover photo support in current UserProfile model

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Edit cover button
                if (isOwnProfile && onEditCover != null)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: onEditCover,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
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
                            child: const Icon(
                              CupertinoIcons.camera,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Profile picture
          Positioned(
            bottom: 0,
            left: 30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white,
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: profile.profilePicUrl?.isNotEmpty == true
                    ? Image.network(
                        profile.profilePicUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(profile.name),
                      )
                    : _buildDefaultAvatar(profile.name),
              ),
            ),
          ),

          // Online status indicator
          Positioned(
            bottom: 15,
            left: 150,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: profile.isOnline ? AppColors.greenColor : Colors.grey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    final initials = name.isNotEmpty
        ? (name.split(' ').length > 1
            ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}'
            : name[0])
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.tealColor],
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Professional profile info section
class ProfileInfoSection extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onSendFriendRequest;
  final VoidCallback? onViewSettings;

  const ProfileInfoSection({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.onEdit,
    this.onSendFriendRequest,
    this.onViewSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(4),

                    // Title/Profession
                    if (profile.jobTitle?.isNotEmpty == true)
                      Text(
                        profile.jobTitle!,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const Gap(8),

                    // Location
                    if (profile.location?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          const Gap(6),
                          Text(
                            profile.location!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Edit/Action buttons
              if (isOwnProfile && onEdit != null)
                _buildActionButton(
                  icon: CupertinoIcons.pencil,
                  label: 'Edit',
                  color: AppColors.primaryColor,
                  onTap: onEdit!,
                ),
            ],
          ),

          const Gap(20),

          // Bio
          if (profile.bio?.isNotEmpty == true) ...[
            Text(
              profile.bio!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Gap(20),
          ],

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: profile.stats.friendsCount.toString(),
                  label: 'Friends',
                  color: AppColors.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: profile.stats.friendsCount.toString(),
                  label: 'Connections',
                  color: AppColors.tealColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: profile.stats.achievementsCount.toString(),
                  label: 'Achievements',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),

          // Action buttons for non-own profiles
          if (!isOwnProfile) ...[
            const Gap(20),
            _buildFriendshipActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const Gap(6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendshipActions() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final isProcessing = state is ProfileActionProcessing;

        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: _getFriendshipIcon(),
                label: _getFriendshipLabel(),
                color: _getFriendshipColor(),
                onTap: isProcessing ? () {} : onSendFriendRequest ?? () {},
              ),
            ),
            const Gap(12),
            _buildActionButton(
              icon: CupertinoIcons.chat_bubble,
              label: 'Message',
              color: AppColors.tealColor,
              onTap: () {
                // Navigate to chat
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getFriendshipIcon() {
    switch (profile.friendshipStatus) {
      case FriendshipStatus.none:
        return CupertinoIcons.person_add;
      case FriendshipStatus.requestSent:
        return CupertinoIcons.clock;
      case FriendshipStatus.requestReceived:
        return CupertinoIcons.check_mark;
      case FriendshipStatus.friends:
        return CupertinoIcons.person_2;
      default:
        return CupertinoIcons.person_add;
    }
  }

  String _getFriendshipLabel() {
    switch (profile.friendshipStatus) {
      case FriendshipStatus.none:
        return 'Add Friend';
      case FriendshipStatus.requestSent:
        return 'Pending';
      case FriendshipStatus.requestReceived:
        return 'Accept';
      case FriendshipStatus.friends:
        return 'Friends';
      default:
        return 'Add Friend';
    }
  }

  Color _getFriendshipColor() {
    switch (profile.friendshipStatus) {
      case FriendshipStatus.none:
        return AppColors.primaryColor;
      case FriendshipStatus.requestSent:
        return Colors.orange;
      case FriendshipStatus.requestReceived:
        return AppColors.greenColor;
      case FriendshipStatus.friends:
        return AppColors.tealColor;
      default:
        return AppColors.primaryColor;
    }
  }
}

/// Custom tab bar delegate for profile tabs
class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isOwnProfile;

  TabBarDelegate({
    required this.tabController,
    required this.isOwnProfile,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Activity'),
              Tab(text: 'Connections'),
              Tab(text: 'Achievements'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.tealColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

/// Overview tab content
class ProfileOverviewTab extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileOverviewTab({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          _buildSection(
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.bio?.isNotEmpty == true)
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                const Gap(16),
                _buildInfoRow(
                  icon: CupertinoIcons.mail,
                  label: 'Email',
                  value: profile.email,
                ),
                _buildInfoRow(
                  icon: CupertinoIcons.phone,
                  label: 'Phone',
                  value: profile.phone,
                ),
                _buildInfoRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Joined',
                  value: _formatDate(profile.createdAt),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Professional info
          if (profile.jobTitle?.isNotEmpty == true ||
              profile.company?.isNotEmpty == true ||
              profile.education?.isNotEmpty == true)
            _buildSection(
              title: 'Professional',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: CupertinoIcons.briefcase,
                    label: 'Company',
                    value: profile.company,
                  ),
                  _buildInfoRow(
                    icon: CupertinoIcons.person_badge_plus,
                    label: 'Position',
                    value: profile.jobTitle,
                  ),
                  _buildInfoRow(
                    icon: CupertinoIcons.building_2_fill,
                    label: 'Education',
                    value: profile.education,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
  }) {
    if (value?.isEmpty != false) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 18,
          ),
          const Gap(12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(8),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Activity tab content
class ProfileActivityTab extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileActivityTab({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Recent activity placeholder
          Container(
            height: 200,
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
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chart_bar,
                    color: Colors.white,
                    size: 48,
                  ),
                  Gap(16),
                  Text(
                    'Activity Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8),
                  Text(
                    'Coming soon...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connections tab content
class ProfileConnectionsTab extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileConnectionsTab({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Connections placeholder
          Container(
            height: 200,
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
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    color: Colors.white,
                    size: 48,
                  ),
                  Gap(16),
                  Text(
                    'Connections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8),
                  Text(
                    'Friends and connections will appear here',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievements tab content
class ProfileAchievementsTab extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileAchievementsTab({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Achievements placeholder
          Container(
            height: 200,
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
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.star,
                    color: Colors.white,
                    size: 48,
                  ),
                  Gap(16),
                  Text(
                    'Achievements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(8),
                  Text(
                    'Badges and achievements will be displayed here',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
