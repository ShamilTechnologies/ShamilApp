import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/feature/passes/bloc/my_passes_bloc.dart';
import 'package:shamil_mobile_app/feature/passes/data/models/pass_type.dart';
import 'package:shamil_mobile_app/feature/passes/view/components/passes_content.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

class PassesScreen extends StatefulWidget {
  const PassesScreen({super.key});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final _pageController = PageController();

  // Scroll controller for pull-to-refresh
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  // Animation controllers
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    _fadeController.forward();
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
    _scrollController.dispose();
    _fadeController.dispose();
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
      create: (context) => MyPassesBloc(
        userRepository: context.read<UserRepository>(),
      )..add(const LoadMyPasses()),
      child: BlocConsumer<MyPassesBloc, MyPassesState>(
        listener: (context, state) {
          if (state is MyPassesLoaded) {
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
          if (state is MyPassesError) {
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
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative background elements
                  Positioned(
                    top: -100,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withOpacity(0.07),
                      ),
                    ),
                  ),

                  // Main content
                  SafeArea(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification &&
                            notification.metrics.pixels == 0 &&
                            notification.metrics.axisDirection ==
                                AxisDirection.down) {
                          if (!_isRefreshing) {
                            setState(() {
                              _isRefreshing = true;
                            });
                            context
                                .read<MyPassesBloc>()
                                .add(const RefreshMyPasses());
                          }
                          return true;
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Pull to refresh indicator
                          CupertinoSliverRefreshControl(
                            onRefresh: () async {
                              setState(() {
                                _isRefreshing = true;
                              });
                              context.read<MyPassesBloc>().add(
                                  const RefreshMyPasses(
                                      showSuccessMessage: true));
                              // Will be completed by listener when state changes
                              return Future.delayed(const Duration(seconds: 3));
                            },
                          ),

                          // Header
                          SliverToBoxAdapter(
                            child: _buildHeader(context, state),
                          ),

                          // Tab bar
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SliverTabBarDelegate(
                              child: _buildTabBar(context),
                            ),
                          ),

                          // Content
                          SliverFillRemaining(
                            child: _buildTabContent(context, state),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading overlay
                  if (state is MyPassesLoading)
                    Positioned.fill(
                      child: _buildLoadingOverlay(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: Colors.black.withOpacity(0.1),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    strokeWidth: 3,
                  ),
                ),
                const Gap(16),
                Text(
                  'Loading passes...',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MyPassesState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.tickets_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Gap(14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Passes',
                        style: AppTextStyle.getHeadlineTextStyle(
                          color: AppColors.primaryText,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      AnimatedSwitcher(
                        duration: _animationDuration,
                        child: Text(
                          _getTabLabel(),
                          key: ValueKey<String>(_getTabLabel()),
                          style: AppTextStyle.getTitleStyle(
                            color: AppColors.primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(context, state),
            ],
          ),
          const Gap(24),
          AnimatedContainer(
            duration: _animationDuration,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTabIcon(),
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const Gap(12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: _animationDuration,
                    child: Text(
                      _getSubtitle(),
                      key: ValueKey<String>(_getSubtitle()),
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                _buildRefreshButton(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, MyPassesState state) {
    if (state is MyPassesLoading) {
      return _buildShimmerBadge();
    } else if (state is MyPassesLoaded) {
      final count = _selectedIndex == 0
          ? state.filteredReservations.length
          : state.filteredSubscriptions.length;
      return _buildItemCountBadge(count);
    } else if (state is MyPassesError) {
      return _buildErrorBadge();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildShimmerBadge() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 70,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildItemCountBadge(int itemCount) {
    return AnimatedContainer(
      duration: _animationDuration,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.7),
            AppColors.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$itemCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Gap(5),
          Text(
            _getItemCountLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            color: Colors.red.shade700,
            size: 16,
          ),
          const Gap(5),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getTabLabel() {
    return _selectedIndex == 0 ? 'Reservations' : 'Subscriptions';
  }

  String _getSubtitle() {
    return _selectedIndex == 0
        ? 'View and manage your service reservations'
        : 'Manage your active and past subscriptions';
  }

  IconData _getTabIcon() {
    return _selectedIndex == 0
        ? CupertinoIcons.calendar_badge_plus
        : CupertinoIcons.creditcard_fill;
  }

  String _getItemCountLabel() {
    return _selectedIndex == 0 ? 'reservations' : 'plans';
  }

  Widget _buildRefreshButton(BuildContext context, MyPassesState state) {
    final isLoading = state is MyPassesLoaded && _isRefreshing;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context
              .read<MyPassesBloc>()
              .add(const RefreshMyPasses(showSuccessMessage: true));
        },
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedSwitcher(
            duration: _animationDuration,
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : const Icon(
                    key: ValueKey('refresh'),
                    CupertinoIcons.arrow_2_circlepath,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = [
      _TabData(
        icon: CupertinoIcons.calendar,
        activeIcon: CupertinoIcons.calendar_badge_plus,
        label: 'Reservations',
      ),
      _TabData(
        icon: CupertinoIcons.creditcard,
        activeIcon: CupertinoIcons.creditcard_fill,
        label: 'Subscriptions',
      ),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            labelStyle: AppTextStyle.getTitleStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyle.getTitleStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            labelPadding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: tabs.map((tab) => _buildTab(tab, tabs.indexOf(tab))).toList(),
            onTap: (index) {
              _pageController.animateToPage(
                index,
                duration: _animationDuration,
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab(_TabData tab, int index) {
    final isSelected = _selectedIndex == index;

    return Tab(
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: _animationDuration,
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                key: ValueKey<bool>(isSelected),
                size: 18,
              ),
            ),
            const Gap(6),
            Text(tab.label),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, MyPassesState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PageView(
          controller: _pageController,
          onPageChanged: _handlePageChange,
          children: [
            PassesContent(passType: PassType.reservation),
            PassesContent(passType: PassType.subscription),
          ],
        ),
      ),
    );
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
