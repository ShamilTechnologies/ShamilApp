// lib/feature/home/views/home_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
// REMOVED: explore_category_list import is no longer needed here
// import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_category_list.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_top_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_categories_grid_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_error_widget.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_loading_shimmer.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/core/constants/app_constants.dart'; // For kGovernorates
import 'package:shimmer/shimmer.dart'; // Needed for helper shimmer widgets
import 'package:provider/provider.dart'; // Import Provider
import 'package:shamil_mobile_app/core/navigation/navigation_notifier.dart'; // Import Notifier
import 'package:shamil_mobile_app/feature/access/views/access_code_view.dart';
// REMOVED: import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/notifications/notifications_view.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/queue_reservation_page.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:shamil_mobile_app/feature/providers/view/modern_providers_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  String _currentCity = "Loading...";
  String? _userName;
  String? _userImageUrl;
  String? _activeFilterCategory; // Keep track if filter is active
  String? _activeSearchQuery; // Keep track if search is active

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateUserDataFromAuthBloc(context.read<AuthBloc>().state);
        final homeBloc = context.read<HomeBloc>();
        // Load initial data or update city from existing state
        if (homeBloc.state is HomeInitial) {
          homeBloc.add(const LoadHomeData());
        } else if (homeBloc.state is HomeDataLoaded) {
          setStateIfMounted(() {
            _currentCity =
                (homeBloc.state as HomeDataLoaded).selectedCity ?? "Unknown";
            _activeFilterCategory =
                (homeBloc.state as HomeDataLoaded).filteredByCategory;
            _activeSearchQuery = (homeBloc.state as HomeDataLoaded).searchQuery;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to create navigation callback
  VoidCallback _createNavigationCallback(
      ServiceProviderDisplayModel provider, String heroTagPrefix) {
    return () async {
      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<FavoritesBloc>(context),
              child: ServiceProviderDetailScreen(
                providerId: provider.id,
                heroTag: '${heroTagPrefix}_${provider.id}',
                initialProviderData: provider,
              ),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Navigation error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening provider details: $e')),
          );
        }
      }
    };
  }

  void _updateUserDataFromAuthBloc(AuthState authState) {
    if (!mounted) return;
    if (authState is LoginSuccessState) {
      setState(() {
        _userName = authState.user.name;
        _userImageUrl = authState.user.profilePicUrl ?? authState.user.image;
        if (_userImageUrl != null && _userImageUrl!.isEmpty) {
          _userImageUrl = null;
        }
      });
    } else {
      setState(() {
        _userName = "Guest";
        _userImageUrl = null;
      });
    }
  }

  void _onCityChanged(String newCity) {
    if (!mounted) return;
    setState(() {
      _currentCity = newCity;
      _activeFilterCategory = null; // Reset filter on city change
      _activeSearchQuery = null; // Reset search on city change
    });
    context.read<HomeBloc>().add(UpdateCityManually(selectedCity: newCity));
  }

  // REMOVED: _onCategorySelected method as the filter list is removed

  void _onSearchSubmitted(String query) {
    if (!mounted) return;
    final String? newQuery = query.trim().isEmpty ? null : query.trim();
    // Only dispatch if the query changed OR if a filter was previously active
    if (newQuery != _activeSearchQuery || _activeFilterCategory != null) {
      setState(() {
        _activeSearchQuery = newQuery;
        _activeFilterCategory = null; // Clear filter when searching
      });
      // Dispatch SearchProviders even if query is empty to potentially revert to default list
      context.read<HomeBloc>().add(SearchProviders(query: query.trim()));
    }
  }

  // Helper to build section titles consistently
  Widget _buildSectionTitleWidget(
      BuildContext context, String title, VoidCallback? onSeeAllTapped) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0)
          .copyWith(top: 24.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              letterSpacing: -0.5,
            ),
          ),
          if (onSeeAllTapped != null)
            TextButton(
              onPressed: onSeeAllTapped,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primaryColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "See All",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const Gap(4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Sliver Builder Helper ---
  List<Widget> _buildProviderSliverSection({
    required BuildContext context,
    required String title,
    required List<ServiceProviderDisplayModel>? providers,
    required String emptyMessage,
    required IconData emptyIcon,
    required String heroTagPrefix,
    required VoidCallback? onSeeAll,
    required bool isLoading,
  }) {
    final titleSliver = SliverToBoxAdapter(
      child: _buildSectionTitleWidget(context, title, onSeeAll),
    );

    if (isLoading && providers == null) {
      return [titleSliver, _SectionLoadingShimmer(title: title)];
    }
    if (!isLoading && (providers == null || providers.isEmpty)) {
      return [
        titleSliver,
        _SectionEmptyState(title: title, message: emptyMessage, icon: emptyIcon)
      ];
    }
    if (providers == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    return [
      titleSliver,
      SliverToBoxAdapter(
        child: SizedBox(
          height: 270,
          child: ListView.builder(
            key: PageStorageKey(heroTagPrefix),
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ServiceProviderCard(
                  provider: provider,
                  heroTagPrefix: heroTagPrefix,
                  onTap: _createNavigationCallback(provider, heroTagPrefix),
                ),
              );
            },
          ),
        ),
      ),
      const SliverGap(16),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildPremiumFloatingButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.95),
              AppColors.primaryColor.withOpacity(0.9),
              const Color(0xFF0A0E1A),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: MultiBlocListener(
          listeners: [
            BlocListener<HomeBloc, HomeState>(
              listener: (context, state) {
                if (!mounted) return;
                if (state is HomeDataLoaded) {
                  setStateIfMounted(() {
                    _currentCity = state.selectedCity ?? "Unknown City";
                    _activeFilterCategory = state.filteredByCategory;
                    _activeSearchQuery = state.searchQuery;
                  });
                } else if (state is HomeError && !state.isInitialError) {
                  _showPremiumSnackBar(
                      context, "Couldn't refresh: ${state.message}");
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (!mounted) return;
                _updateUserDataFromAuthBloc(authState);
              },
            ),
          ],
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              final bool isInitialLoading = state is HomeLoading &&
                  state.isInitialLoading &&
                  state.previousState == null;
              final bool isInitialError = state is HomeError &&
                  state.isInitialError &&
                  state.previousState == null;

              if (isInitialLoading) {
                return _buildPremiumLoadingShimmer();
              }
              if (isInitialError) {
                return _buildPremiumErrorWidget(state.message);
              }

              HomeData? homeData;
              bool isEffectivelyLoading = state is HomeLoading;

              if (state is HomeDataLoaded) {
                homeData = state.homeData;
              } else if (state is HomeLoading && state.previousState != null) {
                homeData = state.previousState!.homeData;
              } else if (state is HomeError && state.previousState != null) {
                homeData = state.previousState!.homeData;
              }

              final bool isShowingResults =
                  _activeSearchQuery != null || _activeFilterCategory != null;
              List<ServiceProviderDisplayModel> mainProviderList =
                  homeData?.nearbyPlaces ?? [];
              String mainListTitle = "Discover Nearby";

              if (isShowingResults) {
                if (_activeSearchQuery != null) {
                  mainListTitle = "Search Results";
                  mainProviderList =
                      homeData?.searchResults ?? homeData?.nearbyPlaces ?? [];
                } else if (_activeFilterCategory != null) {
                  mainListTitle = _activeFilterCategory!;
                  mainProviderList = homeData?.categoryFilteredResults ??
                      homeData?.nearbyPlaces ??
                      [];
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  context
                      .read<HomeBloc>()
                      .add(const LoadHomeData(isRefresh: true));
                  await context
                      .read<HomeBloc>()
                      .stream
                      .firstWhere((s) => s is HomeDataLoaded || s is HomeError);
                },
                color: AppColors.tealColor,
                backgroundColor: Colors.white,
                strokeWidth: 3,
                displacement: 80,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    // Premium Hero Header
                    SliverAppBar(
                      expandedHeight: screenHeight * 0.45,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace:
                          _buildPremiumFlexibleSpace(topPadding, screenWidth),
                    ),

                    // Premium Content
                    SliverToBoxAdapter(
                      child: Container(
                        color: const Color(0xFF0A0E1A),
                        child: Column(
                          children: [
                            if (isShowingResults)
                              _buildPremiumSearchResults(
                                context: context,
                                title: mainListTitle,
                                results: mainProviderList,
                                isLoading: isEffectivelyLoading &&
                                    mainProviderList.isEmpty,
                                query: _activeSearchQuery ??
                                    _activeFilterCategory ??
                                    "",
                              )
                            else
                              _buildPremiumHomeContent(
                                context: context,
                                homeData: homeData,
                                isLoading: isEffectivelyLoading,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFlexibleSpace(double topPadding, double screenWidth) {
    return FlexibleSpaceBar(
      stretchModes: const [
        StretchMode.zoomBackground,
        StretchMode.blurBackground,
        StretchMode.fadeTitle,
      ],
      background: Stack(
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.9),
                  AppColors.tealColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Floating orbs
          Positioned(
            top: topPadding + 40,
            right: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: topPadding + 100,
            left: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Premium top header
                            _buildPremiumTopHeader(),
                            const SizedBox(height: 20),

                            // Hero welcome section
                            Flexible(child: _buildHeroWelcomeSection()),
                            const SizedBox(height: 16),

                            // Premium search bar
                            _buildPremiumSearchBar(),
                            const SizedBox(height: 12),

                            // Premium location selector
                            _buildPremiumLocationSelector(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Premium profile section
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessCodeView()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tealColor.withOpacity(0.3),
                  AppColors.accentColor.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: _userImageUrl != null
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.tealColor,
                                AppColors.accentColor,
                              ],
                            ),
                      image: _userImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_userImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userImageUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName ?? "Guest",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "Premium",
                        style: TextStyle(
                          color: AppColors.tealColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Premium notifications and menu
        Row(
          children: [
            // Notifications
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Menu
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.apps_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    String emoji = "🌅";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
      emoji = "☀️";
    } else if (hour >= 17) {
      greeting = "Good Evening";
      emoji = "🌙";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              AppColors.tealColor,
              AppColors.accentColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            "Discover Amazing\nServices Near You",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Premium experiences curated just for you",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSearchBar() {
    return TextField(
      onSubmitted: _onSearchSubmitted,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryText,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: "Search premium services...",
        hintStyle: TextStyle(
          color: AppColors.secondaryText.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.tealColor,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        suffixIcon: _activeSearchQuery?.isNotEmpty == true
            ? IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _onSearchSubmitted('');
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              )
            : Icon(
                Icons.tune_rounded,
                color: AppColors.tealColor,
                size: 20,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildPremiumLocationSelector() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCitySelectionBottomSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              _currentCity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Select Your City",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Cities list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: [
                  'Cairo',
                  'Alexandria',
                  'Giza',
                  'Sharm El Sheikh',
                  'Luxor'
                ].length,
                itemBuilder: (context, index) {
                  final cities = [
                    'Cairo',
                    'Alexandria',
                    'Giza',
                    'Sharm El Sheikh',
                    'Luxor'
                  ];
                  final city = cities[index];
                  final isSelected = city == _currentCity;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primaryColor,
                              width: 2,
                            )
                          : null,
                    ),
                    child: ListTile(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        _onCityChanged(city);
                      },
                      leading: Icon(
                        isSelected
                            ? Icons.location_on_rounded
                            : Icons.location_city_rounded,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.secondaryText,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.primaryText,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryColor,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHomeContent({
    required BuildContext context,
    required HomeData? homeData,
    required bool isLoading,
  }) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Premium quick access section
        _buildPremiumQuickAccess(),
        const SizedBox(height: 24),

        // Premium categories showcase
        _buildPremiumCategoriesShowcase(),
        const SizedBox(height: 32),

        // Premium nearby section
        _buildPremiumNearbySection(
          context: context,
          providers: homeData?.nearbyPlaces,
          isLoading: isLoading,
        ),
        const SizedBox(height: 32),

        // Premium popular section
        if (homeData?.popularPlaces?.isNotEmpty == true)
          _buildPremiumPopularSection(
            context: context,
            providers: homeData?.popularPlaces,
            isLoading: isLoading,
          ),

        const SizedBox(height: 120), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildPremiumQuickAccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealColor,
                      AppColors.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Quick Access",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick access cards
          Row(
            children: [
              _buildQuickAccessCard(
                "Scan QR",
                Icons.qr_code_scanner_rounded,
                AppColors.tealColor,
                () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccessCodeView()),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildQuickAccessCard(
                "Nearby",
                Icons.near_me_rounded,
                AppColors.primaryColor,
                () => _navigateToSeeAll("Nearby You", []),
              ),
              const SizedBox(width: 12),
              _buildQuickAccessCard(
                "Popular",
                Icons.trending_up_rounded,
                AppColors.accentColor,
                () => _navigateToSeeAll("Popular Places", []),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCategoriesShowcase() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5CF6),
                          const Color(0xFF06B6D4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Categories",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Premium categories grid
          const ExploreCategoriesGridSection(),
        ],
      ),
    );
  }

  Widget _buildPremiumNearbySection({
    required BuildContext context,
    required List<ServiceProviderDisplayModel>? providers,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF06B6D4),
                          const Color(0xFF00D4FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nearby You",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Premium services in $_currentCity",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (providers?.isNotEmpty == true)
                GestureDetector(
                  onTap: () => _navigateToSeeAll("Nearby You", providers),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: isLoading && providers == null
              ? _buildPremiumProviderShimmer()
              : providers == null || providers.isEmpty
                  ? _buildPremiumEmptyState(
                      "No nearby places found", Icons.location_off_rounded)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPremiumProviderCard(
                              providers[index], "nearby_$index"),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPremiumPopularSection({
    required BuildContext context,
    required List<ServiceProviderDisplayModel>? providers,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5CF6),
                          const Color(0xFFEC4899),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trending Now",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Most popular premium services",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (providers?.isNotEmpty == true)
                GestureDetector(
                  onTap: () => _navigateToSeeAll("Popular Places", providers),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: isLoading && providers == null
              ? _buildPremiumProviderShimmer()
              : providers == null || providers.isEmpty
                  ? _buildPremiumEmptyState(
                      "No popular places found", Icons.trending_down_rounded)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPremiumProviderCard(
                              providers[index], "popular_$index"),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPremiumProviderShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 220,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 48, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Widget _buildPremiumFloatingButton(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.tealColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessCodeView()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoadingShimmer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.95),
            const Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.35, 0.6],
        ),
      ),
      child: HomeLoadingShimmer(
        userName: _userName,
        profileImageUrl: _userImageUrl,
      ),
    );
  }

  Widget _buildPremiumErrorWidget(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.95),
            const Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.35, 0.6],
        ),
      ),
      child: HomeErrorWidget(
        message: message,
        onRetry: () =>
            context.read<HomeBloc>().add(const LoadHomeData(isRefresh: true)),
      ),
    );
  }

  Widget _buildPremiumSearchResults({
    required BuildContext context,
    required String title,
    required List<ServiceProviderDisplayModel> results,
    required bool isLoading,
    required String query,
  }) {
    if (isLoading) {
      return Container(
        height: 400,
        padding: const EdgeInsets.all(24),
        child: _buildPremiumProviderShimmer(),
      );
    }

    if (results.isEmpty) {
      return _buildPremiumEmptySearchState(query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        // Premium search results header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D4FF),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "${results.length} premium result${results.length != 1 ? 's' : ''} found",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

        const SizedBox(height: 32),

        // Premium results grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final provider = results[index];
              return _buildPremiumProviderCard(provider, "search_$index");
            },
          ),
        ),

        const SizedBox(height: 120), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildPremiumEmptySearchState(String query) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00D4FF).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Premium Results',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We couldn\'t find any premium services for "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Try different keywords or explore our categories below.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4FF),
                  const Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _onSearchSubmitted('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                'Clear Search',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumProviderCard(
      ServiceProviderDisplayModel provider, String heroTag) {
    return Container(
      width: 220,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _createNavigationCallback(provider, heroTag),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium image section
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00D4FF).withOpacity(0.8),
                        const Color(0xFF8B5CF6).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (provider.imageUrl?.isNotEmpty == true)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.network(
                              provider.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPremiumPlaceholderImage(),
                            ),
                          ),
                        )
                      else
                        _buildPremiumPlaceholderImage(),

                      // Premium overlay gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),

                      // Premium category badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            provider.businessCategory,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D29),
                            ),
                          ),
                        ),
                      ),

                      // Premium status indicator
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00D4FF),
                                const Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "PREMIUM",
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Premium content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.businessName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (provider.averageRating > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.2),
                                  Colors.orange.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  provider.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber[400],
                                  ),
                                ),
                                Text(
                                  " (${provider.ratingCount})",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00D4FF).withOpacity(0.2),
                                  const Color(0xFF8B5CF6).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00D4FF).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "New Business",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00D4FF),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildPremiumPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.8),
            const Color(0xFF8B5CF6).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.store_rounded,
        size: 48,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  void _showPremiumSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToSeeAll(
      String title, List<ServiceProviderDisplayModel>? providers) {
    if (providers == null || providers.isEmpty) return;

    // Direct navigation to modern providers screen
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: BlocProvider.of<FavoritesBloc>(context),
            child: ModernProvidersScreen(
              initialCategory: _mapSectionTitleToCategory(title),
              initialCity: (_currentCity != "All Cities") ? _currentCity : null,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('See All navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening providers list: $e')),
        );
      }
    }
  }

  // Helper method to map section titles to categories
  String? _mapSectionTitleToCategory(String title) {
    switch (title.toLowerCase()) {
      case 'fitness & gym':
      case 'fitness':
        return 'Fitness';
      case 'sports':
        return 'Sports';
      case 'entertainment':
        return 'Entertainment';
      case 'health & wellness':
      case 'health':
        return 'Health';
      case 'events':
        return 'Events';
      default:
        return null; // Show all categories
    }
  }
}

// REMOVED: _CategoryFilterHeaderDelegate class as it's no longer used

// --- Helper Shimmer/Empty State Widgets (adapted for Slivers) ---
class _SectionLoadingShimmer extends StatelessWidget {
  final String title;
  const _SectionLoadingShimmer({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          // Shimmer for Horizontal Card List
          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      child: const SizedBox(
                        width: 180,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const _SectionEmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Container(
            height: 180,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 56, color: AppColors.secondaryText),
                const Gap(16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}
