// lib/feature/home/views/home_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/notifications/notifications_view.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/queue_reservation_page.dart';

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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: BlocProvider.of<FavoritesBloc>(context),
                          child: ServiceProviderDetailScreen(
                            providerId: provider.id,
                            heroTag: '${heroTagPrefix}_${provider.id}',
                          ),
                        ),
                      ),
                    );
                  },
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
    final theme = Theme.of(context);

    return Scaffold(
      // Update background to a beautiful gradient
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildCustomFloatingButton(context),
      body: Container(
        decoration: BoxDecoration(
          // Subtle gradient background that complements the content
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.95),
              AppColors.lightBackground,
            ],
            stops: const [0.0, 0.25, 0.5],
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
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Couldn't refresh: ${state.message}"),
                        backgroundColor: Colors.orange[700]),
                  );
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
                return HomeLoadingShimmer(
                    userName: _userName, profileImageUrl: _userImageUrl);
              }
              if (isInitialError) {
                return HomeErrorWidget(
                  message: (state).message,
                  onRetry: () => context
                      .read<HomeBloc>()
                      .add(const LoadHomeData(isRefresh: true)),
                );
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

              // Determine if results are being shown (from search or filter)
              final bool isShowingResults =
                  _activeSearchQuery != null || _activeFilterCategory != null;
              List<ServiceProviderDisplayModel> mainProviderList = homeData
                      ?.nearbyPlaces ??
                  []; // Default to nearby, will be overwritten if searching/filtering
              String mainListTitle = "Nearby You"; // Default title

              if (isShowingResults) {
                if (_activeSearchQuery != null) {
                  mainListTitle = "Results for \"$_activeSearchQuery\"";
                  // Assuming searchResults are placed in nearbyPlaces by the Bloc for now
                  mainProviderList =
                      homeData?.searchResults ?? homeData?.nearbyPlaces ?? [];
                } else if (_activeFilterCategory != null) {
                  mainListTitle = "Results for \"$_activeFilterCategory\"";
                  // Assuming categoryFilteredResults are placed in nearbyPlaces by the Bloc for now
                  mainProviderList = homeData?.categoryFilteredResults ??
                      homeData?.nearbyPlaces ??
                      [];
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<HomeBloc>()
                      .add(const LoadHomeData(isRefresh: true));
                  await context
                      .read<HomeBloc>()
                      .stream
                      .firstWhere((s) => s is HomeDataLoaded || s is HomeError);
                },
                color: AppColors.primaryColor,
                backgroundColor: Colors.white,
                child: Stack(
                  children: [
                    // Main content
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: <Widget>[
                        SliverPersistentHeader(
                          delegate: ExploreTopSectionDelegate(
                            currentCityDisplay: _currentCity,
                            onSearchTap: () {
                              // Show search UI or navigate to search screen
                              // You can implement this based on your app's requirements
                              print("Search tapped");
                            },
                            onCitySelected: (city) {
                              if (city.isNotEmpty) {
                                _onCityChanged(city);
                              }
                            },
                            onProfileTap: () {
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AccessCodeView(),
                                  ),
                                );
                              } catch (e) {
                                print(
                                    "Error navigating to Access Code screen: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Could not navigate to Access Code screen."),
                                  ),
                                );
                              }
                            },
                            onNotificationsTap: () {
                              // Navigate to notifications screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsView(),
                                ),
                              );
                            },
                            topSafeAreaPadding:
                                MediaQuery.of(context).padding.top,
                          ),
                          pinned: true,
                          floating: false,
                        ),

                        // Main content sections with white background
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Drag handle for visual affordance
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    height: 5,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),
                                ),

                                // Content sections
                                if (isShowingResults)
                                  _buildSearchResultsContent(
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
                                  _buildNearbyContent(
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Nearby content section
  Widget _buildNearbyContent({
    required BuildContext context,
    required HomeData? homeData,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Nearby places section
        _buildSectionTitleWidget(context, "Nearby You",
            () => _navigateToSeeAll("Nearby You", homeData?.nearbyPlaces)),

        // Nearby places cards
        SizedBox(
          height: 270,
          child: (isLoading && homeData?.nearbyPlaces == null)
              ? _buildLoadingShimmer()
              : (homeData?.nearbyPlaces == null ||
                      homeData!.nearbyPlaces.isEmpty)
                  ? _buildEmptyState(
                      "No nearby places found for $_currentCity.",
                      Icons.location_off_outlined)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: homeData.nearbyPlaces.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      itemBuilder: (context, index) {
                        final provider = homeData.nearbyPlaces[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ServiceProviderCard(
                            provider: provider,
                            heroTagPrefix: "nearby",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value:
                                        BlocProvider.of<FavoritesBloc>(context),
                                    child: ServiceProviderDetailScreen(
                                      providerId: provider.id,
                                      heroTag: 'nearby_${provider.id}',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),

        // Categories section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ExploreCategoriesGridSection(),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Search results content
  Widget _buildSearchResultsContent({
    required BuildContext context,
    required String title,
    required List<ServiceProviderDisplayModel> results,
    required bool isLoading,
    required String query,
  }) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildLoadingShimmer(),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.secondaryText),
              const Gap(16),
              Text(
                'No results found for "$query"',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                "Try checking your spelling or use different keywords.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const Gap(24),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () {
                    // Clear search
                    FocusScope.of(context).unfocus();
                    _onSearchSubmitted('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear Search'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionTitleWidget(context, title, null),

        Padding(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, top: 8.0, bottom: 24.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final provider = results[index];
              return ServiceProviderCard(
                provider: provider,
                heroTagPrefix: "search_result",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: BlocProvider.of<FavoritesBloc>(context),
                        child: ServiceProviderDetailScreen(
                          providerId: provider.id,
                          heroTag: 'search_result_${provider.id}',
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Categories section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ExploreCategoriesGridSection(),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Loading shimmer
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                height: 250,
              ),
            ),
          ),
        );
      },
    );
  }

  // Empty state widget
  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    return Container(
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
    );
  }

  void _navigateToSeeAll(
      String title, List<ServiceProviderDisplayModel>? providers) {
    if (providers == null || providers.isEmpty) return;
    print("Navigate to See All: $title");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Navigate to 'See All: $title' (Not Implemented)"),
          duration: const Duration(seconds: 2)),
    );
    // TODO: Implement actual navigation to a generic list screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => AllProvidersScreen(title: title, providers: providers)));
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _showQueueServiceSelectionDialog(BuildContext context) {
    // Get current city from state
    final cityName = _currentCity;

    // Use the HomeBloc to get services
    final homeState = context.read<HomeBloc>().state;
    List<ServiceProviderDisplayModel> providers = [];

    if (homeState is HomeDataLoaded) {
      // Get nearby providers or popular ones
      providers = homeState.homeData?.nearbyPlaces ??
          homeState.homeData?.popularPlaces ??
          [];
    }

    if (providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No services available for queue reservation')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Service'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount:
                providers.length > 10 ? 10 : providers.length, // Limit to 10
            itemBuilder: (context, index) {
              final provider = providers[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.store_mall_directory,
                    color: AppColors.primaryColor,
                  ),
                ),
                title: Text(provider.businessName),
                subtitle: Text(provider.businessCategory),
                onTap: () {
                  Navigator.pop(context); // Close dialog

                  // Navigate to QueueReservationPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QueueReservationPage(
                        providerId: provider.id,
                        governorateId:
                            provider.city, // Use city as governorateId
                        serviceId: null, // Will be selected on the queue page
                        serviceName: provider.businessName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Builds a beautiful animated squared floating action button with dissolving colors
  Widget _buildCustomFloatingButton(BuildContext context) {
    return _AnimatedSquareButton(
      onTap: () {
        // Navigate to Access Code view (NFC/QR scanning page)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccessCodeView(),
          ),
        );
      },
    );
  }
}

/// Eye-catching animated floating action button with balanced complexity
class _AnimatedSquareButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedSquareButton({required this.onTap});

  @override
  State<_AnimatedSquareButton> createState() => _AnimatedSquareButtonState();
}

class _AnimatedSquareButtonState extends State<_AnimatedSquareButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late AnimationController _colorMixController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _colorMixAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for interaction
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    // Color cycling animation
    _colorController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse glow animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Gradient movement animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Color mix animation
    _colorMixController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.linear,
    ));

    _colorMixAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorMixController,
      curve: Curves.easeInOut,
    ));

    // Start continuous animations
    _colorController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _gradientController.repeat();
    _colorMixController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    _colorMixController.dispose();
    super.dispose();
  }

  Color _getAnimatedColor() {
    return Color.lerp(
          AppColors.primaryColor,
          AppColors.tealColor,
          _colorAnimation.value,
        ) ??
        AppColors.primaryColor;
  }

  Color _getSecondaryColor() {
    return Color.lerp(
          AppColors.secondaryColor,
          AppColors.purpleColor,
          _colorAnimation.value,
        ) ??
        AppColors.secondaryColor;
  }

  Color _getMixedColor() {
    // Create a complex color mix animation
    final mixProgress = _colorMixAnimation.value;
    final baseColor = Color.lerp(
          AppColors.primaryColor,
          AppColors.tealColor,
          mixProgress,
        ) ??
        AppColors.primaryColor;

    return Color.lerp(
          baseColor,
          AppColors.purpleColor,
          math.sin(mixProgress * math.pi * 2) * 0.3 + 0.5,
        ) ??
        baseColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _colorAnimation,
        _pulseAnimation,
        _gradientAnimation,
        _colorMixAnimation
      ]),
      builder: (context, child) {
        final primaryColor = _getAnimatedColor();
        final secondaryColor = _getSecondaryColor();
        final mixedColor = _getMixedColor();

        // Calculate moving gradient positions
        final gradientProgress = _gradientAnimation.value;
        final beginAlignment = Alignment.lerp(
              Alignment.topLeft,
              Alignment.bottomRight,
              gradientProgress,
            ) ??
            Alignment.topLeft;
        final endAlignment = Alignment.lerp(
              Alignment.bottomRight,
              Alignment.topLeft,
              gradientProgress,
            ) ??
            Alignment.bottomRight;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                // Animated pulsing glow with mixed color
                BoxShadow(
                  color: mixedColor.withOpacity(_pulseAnimation.value * 0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                // Secondary glow
                BoxShadow(
                  color:
                      secondaryColor.withOpacity(_pulseAnimation.value * 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                // Mixed color accent glow
                BoxShadow(
                  color: Color.lerp(primaryColor, mixedColor, 0.7)
                          ?.withOpacity(_pulseAnimation.value * 0.3) ??
                      primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                // Depth shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: beginAlignment,
                  end: endAlignment,
                  colors: [
                    primaryColor,
                    mixedColor,
                    secondaryColor,
                    Color.lerp(secondaryColor, mixedColor, 0.6) ??
                        secondaryColor,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                // Inner highlight
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Animated shine effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Button content
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          _scaleController.forward().then((_) {
                            _scaleController.reverse();
                          });
                          widget.onTap();
                        },
                        onTapDown: (_) => _scaleController.forward(),
                        onTapUp: (_) => _scaleController.reverse(),
                        onTapCancel: () => _scaleController.reverse(),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 26,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
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
        );
      },
    );
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
