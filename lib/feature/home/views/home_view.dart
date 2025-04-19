import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
// Import necessary functions, models, widgets etc.
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/constants/app_constants.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'dart:typed_data'; // For Uint8List

// Import the section widgets
import 'home_utils/explore_search_bar.dart';
import 'home_utils/explore_category_list.dart';
import 'home_utils/explore_popular_section.dart';
import 'home_utils/explore_recommended_section.dart';
import 'home_utils/explore_top_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_banner_carousel.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_offers_section.dart';
import 'package:shamil_mobile_app/feature/home/widgets/explore_nearby_section.dart';
// Import extracted helper widgets
import 'package:shamil_mobile_app/feature/home/widgets/home_loading_shimmer.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_error_widget.dart';
// Import the AccessCodeView screen for navigation
import 'package:shamil_mobile_app/feature/access/views/access_code_view.dart';
// Import navigation helper
import 'package:shamil_mobile_app/core/functions/navigation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> _governorates = kGovernorates;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final homeState = context.read<HomeBloc>().state;
        if (homeState is HomeInitial) {
          context.read<HomeBloc>().add(LoadHomeData());
        }
      } catch (e) {
        print("Error dispatching initial LoadHomeData: $e");
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    String firstName = "User";
    String? profileImageUrl;
    String? currentUserId;

    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
      }
      profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;
      if (profileImageUrl != null && profileImageUrl.isEmpty) {
        profileImageUrl = null;
      }
      currentUserId = authState.user.uid;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // --- Loading State ---
            if (state is HomeLoading || state is HomeInitial) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  // Use ListView for shimmer
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
                onRetry: () {
                  context.read<HomeBloc>().add(LoadHomeData());
                },
              );
            }
            // --- Loaded State ---
            else if (state is HomeLoaded) {
              final String currentCity = state.homeModel.city;
              final List<ServiceProviderDisplayModel> popular =
                  state.popularProviders;
              final List<ServiceProviderDisplayModel> recommended =
                  state.recommendedProviders;
              // TODO: Get banner, offer, and NEARBY data from state when implemented
              final List<BannerModel> banners = []; // Placeholder
              final List<ServiceProviderDisplayModel> offers =
                  []; // Placeholder
              final List<ServiceProviderDisplayModel> nearby =
                  []; // Placeholder

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(LoadHomeData());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  // Use CustomScrollView for flexible layout
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- Top Section ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      sliver: SliverToBoxAdapter(
                        child: ExploreTopSection(
                          currentCity: currentCity,
                          userName: firstName,
                          profileImageUrl: profileImageUrl,
                          onCityTap: () => _openCityDropdown(context),
                          onProfileTap: () {
                            push(context, const AccessCodeView());
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(16)),

                    // --- Search Bar ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver:
                          const SliverToBoxAdapter(child: ExploreSearchBar()),
                    ),
                    const SliverToBoxAdapter(child: Gap(24)),

                    // --- Banner Carousel ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal:
                              10.0), // Less horizontal padding for full-width feel
                      sliver: SliverToBoxAdapter(
                        child: ExploreBannerCarousel(
                            banners: banners), // Placeholder data
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(24)),

                    // --- Categories ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Categories",
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const Gap(12),
                            ExploreCategoryList(
                              categories: const [
                                'All',
                                'Sports',
                                'Gym',
                                'Entertainment',
                                'Outdoors',
                                'Dining',
                                'Cafe',
                                'Health'
                              ],
                              onCategorySelected: (category) {
                                print("Category selected: $category");
                                context.read<HomeBloc>().add(FilterByCategory(
                                    category:
                                        category == 'All' ? '' : category));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: Gap(32)), // More space after categories

                    // --- Nearby Places Section ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        // TODO: Replace [] with state.nearbyProviders when implemented
                        child: ExploreNearbySection(nearbyProviders: nearby),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Popular Section ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: ExplorePopularSection(popularProviders: popular),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Offers Section ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        // TODO: Replace [] with state.offerProviders when implemented
                        child: ExploreOffersSection(offerProviders: offers),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(32)),

                    // --- Recommended Section ---
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: ExploreRecommendedSection(
                            recommendedProviders: recommended),
                      ),
                    ),
                    // Vertical Spacer (Bottom Padding)
                    const SliverToBoxAdapter(child: Gap(20)),
                  ],
                ),
              );
            }
            // Fallback / Unknown State
            return const Center(child: Text("Something went wrong."));
          },
        ),
      ),
    );
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown(BuildContext context) async {
    String? currentBlocCity;
    try {
      final currentState = context.read<HomeBloc>().state;
      if (currentState is HomeLoaded) {
        currentBlocCity = currentState.homeModel.city;
      }
    } catch (e) {
      print("Error reading HomeBloc state for current city: $e");
    }

    final newCity = await showGovernoratesBottomSheet(
      context: context,
      items: _governorates,
      title: 'Select Your Governorate',
    );

    if (newCity != null && newCity != currentBlocCity) {
      try {
        context.read<HomeBloc>().add(UpdateCityManually(newCity: newCity));
      } catch (e) {
        print("Error dispatching UpdateCityManually event: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not update city.")));
        }
      }
    }
  }
} // End of _ExploreScreenState
