import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_event.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_state.dart';
import 'package:shamil_mobile_app/feature/community/repository/community_repository.dart';
import 'package:shamil_mobile_app/feature/community/view/tabs/community_events_tab.dart';
import 'package:shamil_mobile_app/feature/community/view/tabs/group_hosts_tab.dart';
import 'package:shamil_mobile_app/feature/community/view/tabs/tournaments_tab.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final _pageController = PageController();

  // Remove scroll controller since we're using CupertinoSliverRefreshControl
  bool _isRefreshing = false;

  // Premium animation controllers
  late final AnimationController _animationController;
  late final AnimationController _orbAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Setup premium animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _orbAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

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

    _animationController.forward();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
      // Sync page controller with tab controller
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _selectedIndex,
          duration: _animationDuration,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    _orbAnimationController.dispose();
    super.dispose();
  }

  void _handlePageChange(int pageIndex) {
    setState(() {
      _selectedIndex = pageIndex;
      _tabController.animateTo(pageIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunityBloc(
        communityRepository: context.read<CommunityRepository>(),
      )..add(const LoadCommunityData()),
      child: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityLoaded) {
            if (state.successMessage != null) {
              showGlobalSnackBar(context, state.successMessage!);
            }
            if (state.errorMessage != null) {
              showGlobalSnackBar(context, state.errorMessage!, isError: true);
            }
            // End refresh indicator if active
            if (_isRefreshing) {
              setState(() {
                _isRefreshing = false;
              });
            }
          }
          if (state is CommunityError) {
            showGlobalSnackBar(context, state.message, isError: true);
            // End refresh indicator if active
            if (_isRefreshing) {
              setState(() {
                _isRefreshing = false;
              });
            }
          }
        },
        builder: (context, state) {
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
              child: Stack(
                children: [
                  // Animated floating orbs
                  ..._buildFloatingOrbs(),

                  // Main content
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Pull to refresh indicator
                      CupertinoSliverRefreshControl(
                        builder: (context,
                            refreshState,
                            pulledExtent,
                            refreshTriggerPullDistance,
                            refreshIndicatorExtent) {
                          return Container(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(
                    child: Container(
                                width: 40,
                                height: 40,
                      decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor.withOpacity(0.8),
                                      AppColors.tealColor.withOpacity(0.8),
                                    ],
                                  ),
                        shape: BoxShape.circle,
                                ),
                                child:
                                    refreshState == RefreshIndicatorMode.refresh
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                        : const Icon(
                                            Icons.arrow_downward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                              ),
                            ),
                          );
                        },
                            onRefresh: () async {
                          if (mounted) {
                              setState(() {
                                _isRefreshing = true;
                              });
                              context
                                  .read<CommunityBloc>()
                                  .add(const RefreshCommunityData());
                              // Will be completed by listener when state changes
                              return Future.delayed(const Duration(seconds: 3));
                          }
                          return Future.value();
                            },
                          ),

                      // Premium header
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                            pinned: true,
                        expandedHeight: 140,
                        automaticallyImplyLeading: false,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 80),
                            child: AnimatedBuilder(
                              animation: _slideAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Premium badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.accentColor
                                                    .withOpacity(0.8),
                                                AppColors.tealColor
                                                    .withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                                                color: AppColors.accentColor
                                                    .withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                ),
              ],
            ),
                                          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                                              const Icon(
                                                Icons.people_rounded,
                                                color: Colors.white,
                                                size: 12,
                ),
                                              const Gap(3),
                Text(
                                                'COMMUNITY HUB',
                                                style:
                                                    AppTextStyle.getbodyStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
                                        const Gap(8),

                                        // Title with gradient text
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                          colors: [
                                              Colors.white,
                                              Color(0xFFB8BCC8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            'Community',
                                            style: AppTextStyle.getTitleStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                          ),
                        ],
                      ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Premium tab bar section
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PremiumTabBarDelegate(
                          tabController: _tabController,
                          height: 70,
                          fadeAnimation: _fadeAnimation,
                          selectedIndex: _selectedIndex,
                          onTap: (index) {
                            HapticFeedback.mediumImpact();
                            context
                                .read<CommunityBloc>()
                                .add(ChangeTabEvent(index));
                            if (_pageController.hasClients) {
                              _pageController.animateToPage(
                                index,
                        duration: _animationDuration,
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                  ),
                      ),

                      // Tab content with premium styling
                      SliverFillRemaining(
                        child: Container(
                          decoration: const BoxDecoration(
              gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                colors: [
                                Colors.transparent,
                                Color(0xFF0A0A1A),
                ],
                            ),
              ),
                          child: _buildPremiumTabContent(context, state),
                        ),
              ),
                    ],
                  ),

                  // Loading overlay
                  if (state is CommunityLoading)
                    Positioned.fill(
                      child: _buildPremiumLoadingOverlay(),
                    ),
              ],
            ),
          ),
          );
        },
      ),
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
                    AppColors.accentColor.withOpacity(0.3),
                    AppColors.accentColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
        ),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
            ),
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: const BoxDecoration(
      color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
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
            bottom: 200 + (25 * _orbAnimationController.value),
            right: 80 + (10 * (_orbAnimationController.value * 2 - 1)),
        child: Container(
              width: 60,
          height: 60,
          decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.3),
                    AppColors.primaryColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
            ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
              );
            },
          ),
    ];
  }

  Widget _buildPremiumTabContent(BuildContext context, CommunityState state) {
    // Check if we should show content or empty/loading states
    bool hasContent = false;
    if (state is CommunityLoaded) {
      switch (_selectedIndex) {
        case 0:
          hasContent = state.events.isNotEmpty;
          break;
        case 1:
          hasContent = state.groupHosts.isNotEmpty;
          break;
        case 2:
          hasContent = state.tournaments.isNotEmpty;
          break;
      }
    }

    // Show loading or empty states directly without glassmorphism container
    if (state is CommunityLoading) {
      return _buildPremiumLoadingContent(_selectedIndex);
    } else if (state is CommunityLoaded && !hasContent) {
      return _buildPremiumEmptyState(_selectedIndex);
    }

    // Only show glassmorphism container when there's actual content
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Allow horizontal scroll gestures to pass through to PageView
                return false;
              },
        child: PageView(
          controller: _pageController,
          onPageChanged: _handlePageChange,
                physics: const BouncingScrollPhysics(),
          children: [
                  const CommunityEventsTab(),
                  const GroupHostsTab(),
                  const TournamentsTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContentWrapper(
      Widget tabContent, CommunityState state, int tabIndex) {
    // This method is no longer needed since we handle the logic in _buildPremiumTabContent
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: tabContent,
      );
  }

  Widget _buildPremiumLoadingContent(int tabIndex) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  double height = index == 0 ? 180 : 120;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
      height: height,
      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
                    ),
                  );
                },
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmptyState(int tabIndex) {
    List<IconData> emptyIcons = [
      CupertinoIcons.calendar_today,
      CupertinoIcons.person_3,
      CupertinoIcons.gamecontroller,
    ];

    List<String> emptyTitles = [
      'No Events Yet',
      'No Group Hosts Yet',
      'No Tournaments Yet',
    ];

    List<String> emptyMessages = [
      'Events will appear here once they are available',
      'Group hosts will appear here once they are available',
      'Tournaments will appear here once they are available',
    ];

    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.3),
                        AppColors.accentColor.withOpacity(0.3),
                      ],
                    ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcons[tabIndex],
                size: 50,
                    color: Colors.white,
              ),
            ),
            const Gap(24),
            Text(
              emptyTitles[tabIndex],
              style: AppTextStyle.getTitleStyle(
                    color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            Text(
              emptyMessages[tabIndex],
              textAlign: TextAlign.center,
              style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const Gap(30),
            Material(
              borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                      HapticFeedback.lightImpact();
                  context
                      .read<CommunityBloc>()
                      .add(const RefreshCommunityData());
                },
                    child: Container(
                  decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const Icon(
                          CupertinoIcons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                          const Gap(10),
                        Text(
                          'Refresh',
                            style: AppTextStyle.getbodyStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
    );
  }

  Widget _buildPremiumLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.4),
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
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
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
                  'Loading community...',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(8),
                Text(
                  'Getting the latest updates',
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Premium tab bar delegate with glassmorphism
class _PremiumTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final double height;
  final Animation<double> fadeAnimation;
  final int selectedIndex;
  final Function(int) onTap;

  _PremiumTabBarDelegate({
    required this.tabController,
    required this.height,
    required this.fadeAnimation,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final tabs = [
      _TabData(
        icon: CupertinoIcons.calendar,
        activeIcon: CupertinoIcons.calendar_badge_plus,
        label: 'Events',
      ),
      _TabData(
        icon: CupertinoIcons.person_3,
        activeIcon: CupertinoIcons.person_3_fill,
        label: 'Hosts',
      ),
      _TabData(
        icon: CupertinoIcons.gamecontroller,
        activeIcon: CupertinoIcons.gamecontroller_fill,
        label: 'Tournaments',
      ),
    ];

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: AnimatedBuilder(
        animation: fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: fadeAnimation,
            child: Container(
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
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(2),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      labelStyle: AppTextStyle.getbodyStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: AppTextStyle.getbodyStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: tabs
                          .map((tab) => _buildTab(tab, tabs.indexOf(tab)))
                          .toList(),
                      onTap: onTap,
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

  Widget _buildTab(_TabData tab, int index) {
    final isSelected = selectedIndex == index;
    const animationDuration = Duration(milliseconds: 300);

    return Tab(
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: animationDuration,
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                key: ValueKey<bool>(isSelected),
                size: 18,
              ),
            ),
            const Gap(6),
            Flexible(
              child: Text(
                tab.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _TabData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _TabData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
