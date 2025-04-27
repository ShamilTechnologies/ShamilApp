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
import 'package:shamil_mobile_app/feature/home/data/banner_model.dart'; // Import the correct BannerModel

// Import home screen section widgets
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_top_section.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_search_bar.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_category_list.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_popular_section.dart'; // Popular section widget
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_recommended_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_banner_carousel.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_offers_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_nearby_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_loading_shimmer.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_error_widget.dart';
// Import destination screens for navigation examples
import 'package:shamil_mobile_app/feature/access/views/access_code_view.dart';
// import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'; // Or Profile screen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data if not already loaded or loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final homeState = context.read<HomeBloc>().state;
        if (homeState is HomeInitial) {
          context.read<HomeBloc>().add(const LoadHomeData());
        }
      } catch (e) {
        print(
            "Error accessing HomeBloc or dispatching initial LoadHomeData: $e");
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown(
      BuildContext context, String currentCity) async {
    final newCity = await showGovernoratesBottomSheet(
      context: context,
      items: kGovernorates, // Use constant list from app_constants.dart
      title: 'Select Your Governorate',
    );

    if (!mounted) return;

    if (newCity != null && newCity != currentCity) {
      try {
        context.read<HomeBloc>().add(UpdateCityManually(newCity: newCity));
      } catch (e) {
        print("Error dispatching UpdateCityManually event: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not update city.")),
          );
        }
      }
    }
  }

  /// Builds a styled section header with optional "See All" button.
  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    final theme = Theme.of(context);
    return Padding(
      // Apply horizontal padding here for the header itself
      padding:
          const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.secondaryColor,
              ),
              child: Text(
                'See All',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a placeholder message for empty horizontal list sections.
  Widget _buildEmptySectionPlaceholder(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      // Apply horizontal padding to match where the list content would start
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      height: 150, // Give placeholder some height
      alignment: Alignment.center,
      child: Column(
        // Icon and Text
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied_outlined, // General empty icon
            size: 40,
            color: AppColors.secondaryColor.withOpacity(0.6),
          ),
          const Gap(12),
          Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.secondaryColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    String firstName = "User";
    String? profileImageUrl;

    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
        firstName = nameParts.first;
      }
      profileImageUrl = authState.user.profilePicUrl?.isNotEmpty == true
          ? authState.user.profilePicUrl
          : (authState.user.image?.isNotEmpty == true
              ? authState.user.image
              : null);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {/* Optional listeners */},
          builder: (context, state) {
            // --- Loading State ---
            if (state is HomeLoading || state is HomeInitial) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    HomeLoadingShimmer(
                      userName: firstName,
                      profileImageUrl: profileImageUrl,
                    )
                  ],
                ),
              );
            }
            // --- Error State ---
            else if (state is HomeError) {
              return HomeErrorWidget(
                message: state.message,
                onRetry: () =>
                    context.read<HomeBloc>().add(const LoadHomeData()),
              );
            }
            // --- Loaded State ---
            else if (state is HomeLoaded) {
              final String currentCity = state.homeModel.city;
              final List<ServiceProviderDisplayModel> popular =
                  state.popularProviders;
              final List<ServiceProviderDisplayModel> recommended =
                  state.recommendedProviders;
              final List<BannerModel> banners = state.banners;
              final List<ServiceProviderDisplayModel> offers = state.offers;
              final List<ServiceProviderDisplayModel> nearby =
                  state.nearbyProviders;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(const LoadHomeData());
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                color: AppColors.primaryColor,
                backgroundColor: AppColors.white,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // --- Top Section ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      sliver: SliverToBoxAdapter(
                        child: ExploreTopSection(
                          currentCity: currentCity,
                          userName: firstName,
                          profileImageUrl: profileImageUrl,
                          onCityTap: () =>
                              _openCityDropdown(context, currentCity),
                          onProfileTap: () {
                            push(context, const AccessCodeView());
                            print(
                                "Profile Tapped - Navigating to Access Code Screen");
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
                              onSearch: (query) {
                                FocusScope.of(context).unfocus();
                                context
                                    .read<HomeBloc>()
                                    .add(SearchProviders(query: query));
                              })),
                    ),
                    const SliverToBoxAdapter(child: Gap(24)),

                    // --- Banner Carousel ---
                    if (banners.isNotEmpty)
                      SliverToBoxAdapter(
                          child: ExploreBannerCarousel(banners: banners)),
                    if (banners.isNotEmpty)
                      const SliverToBoxAdapter(child: Gap(24)),

                    // --- Categories ---
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(context, "Categories")),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0)
                          .copyWith(top: 4),
                      sliver: SliverToBoxAdapter(
                        child: ExploreCategoryList(
                          onCategorySelected: (category) {
                            final filterCategory =
                                category == 'All' ? '' : category;
                            context.read<HomeBloc>().add(
                                FilterByCategory(category: filterCategory));
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Nearby Places Section ---
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(context, "Nearby You",
                            onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: nearby.isNotEmpty
                          ? ExploreNearbySection(nearbyProviders: nearby)
                          : _buildEmptySectionPlaceholder(
                              context, "No nearby places found right now."),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    SliverToBoxAdapter(
                      child: popular.isNotEmpty
                          ? ExplorePopularSection(
                              popularProviders: popular) // Use the widget here
                          : _buildEmptySectionPlaceholder(
                              context, "No popular places to show yet."),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Offers Section ---
                    SliverToBoxAdapter(
                        child: _buildSectionHeader(context, "Special Offers",
                            onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: offers.isNotEmpty
                          ? ExploreOffersSection(offerProviders: offers)
                          : _buildEmptySectionPlaceholder(context,
                              "No special offers available currently."),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Recommended Section ---
                    SliverToBoxAdapter(
                        child:
                            _buildSectionHeader(context, "Recommended For You",
                                onSeeAll: () {/* TODO */})),
                    SliverToBoxAdapter(
                      child: recommended.isNotEmpty
                          ? ExploreRecommendedSection(
                              recommendedProviders: recommended)
                          : _buildEmptySectionPlaceholder(context,
                              "No specific recommendations for you yet."),
                    ),

                    // --- Empty State Message ---
                    if (banners.isEmpty &&
                        nearby.isEmpty &&
                        popular.isEmpty &&
                        offers.isEmpty &&
                        recommended.isEmpty)
                      SliverFillRemaining(
                        /* ... Empty state message ... */
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "Nothing to show in $currentCity yet.\nTry exploring other areas!",
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.secondaryColor),
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
            return const Center(child: Text("An unexpected error occurred."));
          },
        ),
      ),
    );
  }
}
