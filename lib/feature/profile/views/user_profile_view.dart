import 'dart:ui';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/profile/bloc/profile_bloc.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_event.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_state.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';
import 'package:shamil_mobile_app/feature/profile/views/settings_view.dart';
import 'package:shamil_mobile_app/feature/social/views/enhanced_find_friends_view.dart';

/// Premium Professional Profile View - High-End Design
class UserProfileView extends StatefulWidget {
  final String userId;
  final ProfileViewContext context;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.context,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _headerController;
  late AnimationController _fabController;
  late AnimationController _backgroundController;

  late Animation<double> _headerOpacity;
  late Animation<double> _fabScale;
  late Animation<double> _backgroundScale;

  bool _isScrolledDown = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadProfile();
  }

  void _initializeAnimations() {
    _scrollController = ScrollController();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuart),
    );

    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _backgroundScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _fabController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final shouldShowHeader = offset > 200;

      if (shouldShowHeader != _isScrolledDown) {
        setState(() => _isScrolledDown = shouldShowHeader);

        if (shouldShowHeader) {
          _headerController.forward();
        } else {
          _headerController.reverse();
        }
      }
    });
  }

  void _loadProfile() {
    context.read<ProfileBloc>().add(LoadUserProfile(
          userId: widget.userId,
          context: widget.context,
        ));
    _isOwnProfile = widget.context == ProfileViewContext.ownProfile;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    _fabController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildMainContent(),
          _buildFloatingHeader(),
          if (_isOwnProfile) _buildFloatingActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Transform.scale(
          scale: _backgroundScale.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.deepSpaceNavy,
                  AppColors.deepSpaceNavy.withOpacity(0.9),
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.tealColor.withOpacity(0.05),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: FloatingOrbsPainter(
                animation: _backgroundController,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildLoadingState();
        } else if (state is ProfileError) {
          return _buildErrorState(state.message);
        } else if (state is ProfileLoaded) {
          return _buildProfileContent(state.profile);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildShimmerAvatar(),
          const Gap(20),
          _buildShimmerText(width: 200),
          const Gap(10),
          _buildShimmerText(width: 150),
          const Gap(30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShimmerStat(),
              _buildShimmerStat(),
              _buildShimmerStat(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerText({required double width}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStat() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
        ),
        const Gap(8),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.2),
                  Colors.red.withOpacity(0.1)
                ],
              ),
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.red,
              size: 40,
            ),
          ),
          const Gap(20),
          Text(
            'Profile Not Found',
            style: AppTextStyle.getTitleStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.getbodyStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Gap(30),
          _buildPremiumButton(
            'Go Back',
            CupertinoIcons.arrow_left,
            AppColors.primaryColor,
            () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeroBanner(profile),
        _buildProfileInfo(profile),
        _buildQuickActions(profile),
        _buildStatsSection(profile),
        _buildAboutSection(profile),
        _buildAchievementsSection(profile),
        _buildConnectionsPreview(profile),
        _buildActivityFeed(profile),
        const SliverToBoxAdapter(child: Gap(100)),
      ],
    );
  }

  Widget _buildHeroBanner(UserProfile profile) {
    return SliverToBoxAdapter(
      child: Container(
        height: 320,
        child: Stack(
          children: [
            // Dynamic gradient background
            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.tealColor.withOpacity(0.9),
                    const Color(0xFF8B5CF6),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Floating orbs
                  Positioned(
                    top: 50,
                    right: 50,
                    child: _buildFloatingOrb(60, Colors.white.withOpacity(0.1)),
                  ),
                  Positioned(
                    top: 120,
                    left: 30,
                    child:
                        _buildFloatingOrb(40, Colors.white.withOpacity(0.08)),
                  ),
                  Positioned(
                    bottom: 80,
                    right: 80,
                    child:
                        _buildFloatingOrb(35, Colors.white.withOpacity(0.06)),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile avatar with glass morphism
            Positioned(
              bottom: 0,
              left: 30,
              child: _buildProfileAvatar(profile),
            ),

            // Online status
            Positioned(
              bottom: 15,
              left: 155,
              child: _buildOnlineStatus(profile.isOnline),
            ),

            // Verification badge
            if (profile.isVerified)
              Positioned(
                bottom: 45,
                left: 155,
                child: _buildVerificationBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(double size, Color color) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10 * Math.sin(_backgroundController.value * 2 * Math.pi),
            5 * Math.cos(_backgroundController.value * 2 * Math.pi),
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(UserProfile profile) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatus(bool isOnline) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.greenColor : Colors.grey,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.greenColor : Colors.grey)
                .withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: isOnline
          ? const Icon(
              CupertinoIcons.circle_fill,
              color: Colors.white,
              size: 12,
            )
          : null,
    );
  }

  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.tealColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.checkmark_seal_fill,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  // Continue with more methods...
  Widget _buildFloatingHeader() {
    return AnimatedBuilder(
      animation: _headerOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _headerOpacity.value,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepSpaceNavy.withOpacity(0.95),
                  AppColors.deepSpaceNavy.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildHeaderButton(
                      CupertinoIcons.arrow_left,
                      () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      _isOwnProfile ? 'My Profile' : 'Profile',
                      style: AppTextStyle.getTitleStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _buildHeaderButton(
                      CupertinoIcons.share,
                      _shareProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return AnimatedBuilder(
      animation: _fabScale,
      builder: (context, child) {
        return Positioned(
          bottom: 30,
          right: 20,
          child: Transform.scale(
            scale: _fabScale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFAB(
                  CupertinoIcons.settings,
                  AppColors.primaryColor,
                  _openSettings,
                ),
                const Gap(16),
                _buildFAB(
                  CupertinoIcons.person_add,
                  AppColors.tealColor,
                  _openFindFriends,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAB(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Placeholder methods for remaining UI components
  Widget _buildProfileInfo(UserProfile profile) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
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
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
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
                      // Name with animated typing effect
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const Gap(8),

                      // Username with @
                      Text(
                        '@${profile.username}',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const Gap(6),

                      // Job title with icon
                      if (profile.jobTitle?.isNotEmpty == true)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.briefcase_fill,
                              color: AppColors.tealColor,
                              size: 16,
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                profile.jobTitle!,
                                style: TextStyle(
                                  color: AppColors.tealColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const Gap(12),

                      // Location with icon
                      if (profile.location?.isNotEmpty == true)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.location_solid,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                            const Gap(8),
                            Text(
                              profile.location!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Edit button for own profile
                if (_isOwnProfile)
                  _buildActionButton(
                    icon: CupertinoIcons.pencil,
                    label: 'Edit',
                    color: AppColors.primaryColor,
                    onTap: () => _editProfile(profile),
                  ),
              ],
            ),

            const Gap(24),

            // Bio with rich text
            if (profile.bio?.isNotEmpty == true) ...[
              Text(
                profile.bio!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Gap(24),
            ],

            // Quick info chips
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (profile.company?.isNotEmpty == true)
                  _buildInfoChip(
                    CupertinoIcons.building_2_fill,
                    profile.company!,
                    AppColors.primaryColor,
                  ),
                if (profile.languages.isNotEmpty)
                  _buildInfoChip(
                    CupertinoIcons.globe,
                    '${profile.languages.length} languages',
                    AppColors.tealColor,
                  ),
                _buildInfoChip(
                  CupertinoIcons.calendar,
                  'Joined ${_formatJoinDate(profile.createdAt)}',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(UserProfile profile) {
    if (_isOwnProfile)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: _getFriendshipIcon(profile.friendshipStatus),
                label: _getFriendshipLabel(profile.friendshipStatus),
                color: _getFriendshipColor(profile.friendshipStatus),
                onTap: () => _handleFriendshipAction(profile),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionButton(
                icon: CupertinoIcons.chat_bubble_fill,
                label: 'Message',
                color: AppColors.tealColor,
                onTap: () => _openChat(profile),
              ),
            ),
            const Gap(12),
            _buildIconButton(
              CupertinoIcons.ellipsis,
              Colors.white.withOpacity(0.3),
              () => _showMoreOptions(profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserProfile profile) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.person_2_fill,
                count: profile.stats.friendsCount,
                label: 'Friends',
                color: AppColors.primaryColor,
                onTap: () => _showFriends(profile),
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.star_fill,
                count: profile.stats.achievementsCount,
                label: 'Achievements',
                color: const Color(0xFF8B5CF6),
                onTap: () => _showAchievements(profile),
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.calendar,
                count: profile.stats.reservationsCount,
                label: 'Bookings',
                color: AppColors.tealColor,
                onTap: () => _showBookings(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(UserProfile profile) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(16),
            _buildAboutCard(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(UserProfile profile) {
    if (profile.achievements.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Achievements',
                  style: AppTextStyle.getTitleStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAllAchievements(profile),
                  child: Text(
                    'View All',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profile.achievements.take(5).length,
                itemBuilder: (context, index) {
                  final achievement = profile.achievements[index];
                  return _buildAchievementCard(achievement);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsPreview(UserProfile profile) {
    if (profile.mutualFriends.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mutual Friends',
                  style: AppTextStyle.getTitleStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showMutualFriends(profile),
                  child: Text(
                    'View All',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profile.mutualFriends.take(10).length,
                itemBuilder: (context, index) {
                  final friend = profile.mutualFriends[index];
                  return _buildMutualFriendAvatar(friend);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(UserProfile profile) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTextStyle.getTitleStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(16),
            _buildActivityPlaceholder(),
          ],
        ),
      ),
    );
  }

  // Helper methods for building components
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const Gap(8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const Gap(6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Gap(12),
              Text(
                count.toString(),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(UserProfile profile) {
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
          _buildInfoRow(
            CupertinoIcons.mail_solid,
            'Email',
            profile.email,
          ),
          if (profile.phone?.isNotEmpty == true)
            _buildInfoRow(
              CupertinoIcons.phone_fill,
              'Phone',
              profile.phone!,
            ),
          if (profile.website?.isNotEmpty == true)
            _buildInfoRow(
              CupertinoIcons.globe,
              'Website',
              profile.website!,
            ),
          _buildInfoRow(
            CupertinoIcons.calendar,
            'Joined',
            _formatJoinDate(profile.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const Gap(16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              value,
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

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.tealColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Gap(8),
          Text(
            achievement.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMutualFriendAvatar(MutualFriend friend) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: friend.profilePicUrl?.isNotEmpty == true
                  ? Image.network(
                      friend.profilePicUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryColor, AppColors.tealColor],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          friend.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const Gap(4),
          Text(
            friend.name.split(' ')[0],
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPlaceholder() {
    return Container(
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
              CupertinoIcons.chart_bar_fill,
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
    );
  }

  // Utility methods
  IconData _getFriendshipIcon(FriendshipStatus? status) {
    switch (status) {
      case FriendshipStatus.none:
        return CupertinoIcons.person_add_solid;
      case FriendshipStatus.requestSent:
        return CupertinoIcons.clock_solid;
      case FriendshipStatus.requestReceived:
        return CupertinoIcons.checkmark_circle_fill;
      case FriendshipStatus.friends:
        return CupertinoIcons.person_2_fill;
      default:
        return CupertinoIcons.person_add_solid;
    }
  }

  String _getFriendshipLabel(FriendshipStatus? status) {
    switch (status) {
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

  Color _getFriendshipColor(FriendshipStatus? status) {
    switch (status) {
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

  String _formatJoinDate(DateTime date) {
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

  Widget _buildPremiumButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const Gap(8),
              Text(
                text,
                style: AppTextStyle.getbodyStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _editProfile(UserProfile profile) {
    HapticFeedback.lightImpact();
    // TODO: Implement edit profile functionality
  }

  void _handleFriendshipAction(UserProfile profile) {
    HapticFeedback.lightImpact();
    switch (profile.friendshipStatus) {
      case FriendshipStatus.none:
        context.read<ProfileBloc>().add(SendFriendRequestFromProfile(
              targetUserId: profile.uid,
              targetUserName: profile.name,
              targetUserPicUrl: profile.profilePicUrl,
            ));
        break;
      case FriendshipStatus.requestReceived:
        context.read<ProfileBloc>().add(AcceptFriendRequestFromProfile(
              requesterUserId: profile.uid,
              requesterUserName: profile.name,
              requesterUserPicUrl: profile.profilePicUrl,
            ));
        break;
      default:
        break;
    }
  }

  void _openChat(UserProfile profile) {
    HapticFeedback.lightImpact();
    // TODO: Implement chat navigation
  }

  void _showMoreOptions(UserProfile profile) {
    HapticFeedback.lightImpact();
    // TODO: Implement more options
  }

  void _showFriends(UserProfile profile) {
    HapticFeedback.lightImpact();
  }

  void _showAchievements(UserProfile profile) {
    HapticFeedback.lightImpact();
  }

  void _showBookings(UserProfile profile) {
    HapticFeedback.lightImpact();
  }

  void _showAllAchievements(UserProfile profile) {
    HapticFeedback.lightImpact();
  }

  void _showMutualFriends(UserProfile profile) {
    HapticFeedback.lightImpact();
  }

  void _shareProfile() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsView()),
    );
  }

  void _openFindFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EnhancedFindFriendsView()),
    );
  }
}

/// Custom painter for floating orbs animation
class FloatingOrbsPainter extends CustomPainter {
  final Animation<double> animation;

  FloatingOrbsPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating orbs with animation
    for (int i = 0; i < 5; i++) {
      final progress = (animation.value + i * 0.2) % 1.0;
      final x = size.width * (0.1 + 0.8 * i / 4);
      final y = size.height * (0.1 + 0.3 * Math.sin(progress * 2 * Math.pi));
      final radius = 20 + 15 * Math.sin(progress * Math.pi);

      paint.color =
          Colors.white.withOpacity(0.03 + 0.02 * Math.sin(progress * Math.pi));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(FloatingOrbsPainter oldDelegate) => true;
}
