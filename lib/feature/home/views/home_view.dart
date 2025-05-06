// lib/feature/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
// Import core utilities and constants
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/constants/app_constants.dart'; // For kGovernorates
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart'; // For push navigation

// Import Blocs and Models
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart';

// Import home screen section widgets
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_top_section.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_search_bar.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_category_list.dart';
// *** Import the SECTION widgets, not the card directly ***
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_popular_section.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_recommended_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_banner_carousel.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_offers_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_nearby_section.dart';
// Import Loading/Error Widgets
import 'package:shamil_mobile_app/feature/home/widgets/home_loading_shimmer.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_error_widget.dart';
// Import destination screens for navigation examples
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'; // Navigate to actual profile screen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All'; // Track selected category

  @override
  void initState() {
    super.initState();
    _loadInitialDataIfNeeded();
  }

  void _loadInitialDataIfNeeded() {
    // Load initial data if not already loaded or loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final homeState = context.read<HomeBloc>().state;
        // Load only if in initial state
        if (homeState is HomeInitial) {
          print("ExploreScreen: Dispatching initial LoadHomeData.");
          context.read<HomeBloc>().add(const LoadHomeData());
        }
      } catch (e) {
        print("Error accessing HomeBloc or dispatching initial LoadHomeData: $e");
      }
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown(BuildContext context, String currentCity) async {
    final newCity = await showGovernoratesBottomSheet(
      context: context,
      items: kGovernorates, // Use constant list
      title: 'Select Your Governorate',
    );

    if (!mounted || newCity == null || newCity == currentCity) return;

    try {
      print("ExploreScreen: Updating city manually to $newCity");
      context.read<HomeBloc>().add(UpdateCityManually(newCity: newCity));
      _searchController.clear(); // Clear search on city change
      setState(() { _selectedCategory = 'All'; }); // Reset category on city change
    } catch (e) {
      print("Error dispatching UpdateCityManually event: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not update city.")),
        );
      }
    }
  }

  /// Handles category selection.
  void _onCategorySelected(String category) {
     print("ExploreScreen: Category selected: $category");
     // Update local state for category list UI
     setState(() { _selectedCategory = category; });
     // Dispatch event to filter providers
     final filterCategory = category == 'All' ? '' : category;
     context.read<HomeBloc>().add(FilterByCategory(category: filterCategory));
     _searchController.clear(); // Clear search on category change
  }

  /// Handles search submission.
  void _onSearchSubmitted(String query) {
     print("ExploreScreen: Search submitted: $query");
     FocusScope.of(context).unfocus();
     // Dispatch search event (Bloc handles empty query logic if needed)
     context.read<HomeBloc>().add(SearchProviders(query: query));
     // Reset category visually when searching
     setState(() { _selectedCategory = 'All'; });
  }

  /// Builds a styled section header with optional "See All" button.
  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text( title, style: theme.textTheme.titleLarge?.copyWith( fontWeight: FontWeight.bold, color: AppColors.primaryColor, ), ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom( padding: EdgeInsets.zero, minimumSize: const Size(50, 30), visualDensity: VisualDensity.compact, foregroundColor: AppColors.secondaryColor, ),
              child: Text( 'See All', style: theme.textTheme.bodyMedium?.copyWith( fontWeight: FontWeight.w600, color: AppColors.primaryColor, ), ),
            ),
        ],
      ),
    );
  }

  /// Builds a placeholder message for empty horizontal list sections.
  Widget _buildEmptySectionPlaceholder(BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      height: 150, // Give placeholder some height
      alignment: Alignment.center,
      child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon( icon, size: 40, color: AppColors.secondaryColor.withOpacity(0.6), ),
          const Gap(12),
          Text( message, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryColor.withOpacity(0.7)), textAlign: TextAlign.center, ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch AuthBloc to get user info for the header
    final authState = context.watch<AuthBloc>().state;
    String firstName = "User";
    String? profileImageUrl;

    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
        firstName = nameParts.first;
      }
      // Prioritize profilePicUrl, fallback to image
      profileImageUrl = authState.user.profilePicUrl?.isNotEmpty == true
          ? authState.user.profilePicUrl
          : (authState.user.image?.isNotEmpty == true ? authState.user.image : null);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // Listen to HomeBloc for state changes
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            // Optional: Show snackbar on error, etc.
            if (state is HomeError) {
              // Avoid showing error snackbar if the error widget is already displayed
            }
          },
          builder: (context, state) {
            // --- Loading State ---
            if (state is HomeLoading || state is HomeInitial) {
              // Show shimmer, passing necessary info for the static parts
              return HomeLoadingShimmer(
                  userName: firstName,
                  profileImageUrl: profileImageUrl,
              );
            }
            // --- Error State ---
            else if (state is HomeError) {
              return HomeErrorWidget(
                message: state.message,
                onRetry: () => context.read<HomeBloc>().add(const LoadHomeData()),
              );
            }
            // --- Loaded State ---
            else if (state is HomeLoaded) {
              final String currentCity = state.homeModel.city;
              final List<ServiceProviderDisplayModel> popular = state.popularProviders;
              final List<ServiceProviderDisplayModel> recommended = state.recommendedProviders;
              final List<BannerModel> banners = state.banners;
              final List<ServiceProviderDisplayModel> offers = state.offers;
              final List<ServiceProviderDisplayModel> nearby = state.nearbyProviders;
              final bool hasContent = banners.isNotEmpty || nearby.isNotEmpty || popular.isNotEmpty || offers.isNotEmpty || recommended.isNotEmpty;

              // Build the main scrollable view
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(const LoadHomeData());
                  // Allow time for the Bloc to process and emit loading state
                  await context.read<HomeBloc>().stream.firstWhere((s) => s is HomeLoading || s is HomeLoaded || s is HomeError);
                },
                color: AppColors.primaryColor,
                backgroundColor: AppColors.white,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // --- Top Section ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      sliver: SliverToBoxAdapter(
                        child: ExploreTopSection(
                          currentCity: currentCity,
                          userName: firstName,
                          profileImageUrl: profileImageUrl,
                          onCityTap: () => _openCityDropdown(context, currentCity),
                          onProfileTap: () {
                            // Navigate to the actual profile screen
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(16)),

                    // --- Search Bar ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                          child: ExploreSearchBar(
                            controller: _searchController,
                            onSearch: _onSearchSubmitted // Pass the handler
                          )
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(24)),

                    // --- Banner Carousel ---
                    if (banners.isNotEmpty)
                      SliverToBoxAdapter(child: ExploreBannerCarousel(banners: banners)),
                    if (banners.isNotEmpty) const SliverToBoxAdapter(child: Gap(24)),

                    // --- Categories ---
                    SliverToBoxAdapter(child: _buildSectionHeader(context, "Categories")),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 4),
                      sliver: SliverToBoxAdapter(
                        child: ExploreCategoryList(
                          initialCategory: _selectedCategory, // Pass current selection
                          onCategorySelected: _onCategorySelected, // Pass the handler
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Nearby Places Section ---
                    SliverToBoxAdapter(child: _buildSectionHeader(context, "Nearby You", onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: nearby.isNotEmpty
                          // *** Pass unique prefix for Hero tags ***
                          ? ExploreNearbySection(nearbyProviders: nearby, heroTagPrefix: 'nearby')
                          : _buildEmptySectionPlaceholder(context, "No nearby places found right now.", Icons.near_me_outlined),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Popular Places Section ---
                    SliverToBoxAdapter(
                      child: popular.isNotEmpty
                          // *** Pass unique prefix for Hero tags ***
                          ? ExplorePopularSection(popularProviders: popular, heroTagPrefix: 'popular')
                          : _buildEmptySectionPlaceholder(context, "No popular places to show yet.", Icons.local_fire_department_outlined),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Offers Section ---
                    SliverToBoxAdapter(child: _buildSectionHeader(context, "Special Offers", onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: offers.isNotEmpty
                          // *** Pass unique prefix for Hero tags ***
                          ? ExploreOffersSection(offerProviders: offers, heroTagPrefix: 'offer')
                          : _buildEmptySectionPlaceholder(context, "No special offers available currently.", Icons.sell_outlined),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Recommended Section ---
                    SliverToBoxAdapter(child: _buildSectionHeader(context, "Recommended For You", onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: recommended.isNotEmpty
                          // *** Pass unique prefix for Hero tags ***
                          ? ExploreRecommendedSection(recommendedProviders: recommended, heroTagPrefix: 'recommended')
                          : _buildEmptySectionPlaceholder(context, "No specific recommendations for you yet.", Icons.thumb_up_alt_outlined),
                    ),

                    // --- Empty State Message (if ALL lists are empty) ---
                    if (!hasContent)
                      SliverFillRemaining(
                        hasScrollBody: false, // Important for SliverFillRemaining
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "Nothing to show in $currentCity yet.\nTry exploring other areas!",
                              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.secondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),

                    // Bottom Padding
                    const SliverToBoxAdapter(child: Gap(24)),
                  ],
                ),
              );
            }
            // Fallback / Unknown State
            return const Center(child: Text("An unexpected error occurred. Please restart the app."));
          },
        ),
      ),
    );
  }
}
