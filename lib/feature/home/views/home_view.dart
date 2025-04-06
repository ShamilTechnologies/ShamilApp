import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart'; // Use Gap for spacing
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart'; // Assume this exists
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // If needed by helpers
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // For user name

// Import the section widgets
import 'home_utils/explore_search_bar.dart';
import 'home_utils/explore_category_list.dart';
import 'home_utils/explore_popular_section.dart';
import 'home_utils/explore_recommended_section.dart';
import 'home_utils/explore_top_section.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Example list of governorates - replace with your actual data source if needed
  final List<String> _governorates = [
    'Cairo', 'Alexandria', 'Giza', 'Suez', 'Aswan', 'Luxor',
    'Port Said', 'Ismailia', 'Faiyum', 'Minya', // Add others...
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get user's first name from AuthBloc state for greeting
    // Use watch to rebuild if AuthBloc state changes (e.g., profile update)
    final authState = context.watch<AuthBloc>().state;
    String firstName = "User"; // Default name
    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
      }
    }

    // Provide the HomeBloc locally to this screen and its descendants
    return BlocProvider(
      create: (context) =>
          HomeBloc()..add(LoadHomeData()), // Load data on creation
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
        body: SafeArea(
          // BlocBuilder rebuilds based on HomeBloc state
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              // --- Loading State ---
              if (state is HomeLoading || state is HomeInitial) {
                // Show shimmer loading placeholders
                // Wrap shimmer content in Padding
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  // Use ListView for shimmer to prevent potential overflows if content is tall
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildShimmerLoading(context, theme)],
                  ),
                );
              }
              // --- Error State ---
              else if (state is HomeError) {
                return _buildErrorWidget(context, theme, state.message);
              }
              // --- Loaded State ---
              else if (state is HomeLoaded) {
                // Extract data for easier access
                final String currentCity = state.homeModel.city;
                final List<ServiceProviderDisplayModel> popular =
                    state.popularProviders;
                final List<ServiceProviderDisplayModel> recommended =
                    state.recommendedProviders;

                // Build the main content using RefreshIndicator and CustomScrollView
                return RefreshIndicator(
                  onRefresh: () async {
                    try {
                      context.read<HomeBloc>().add(LoadHomeData());
                      // Optional: Add a slight delay for visual feedback
                      await Future.delayed(const Duration(milliseconds: 500));
                    } catch (e) {
                      print("Error dispatching LoadHomeData on refresh: $e");
                    }
                  },
                  color: theme.colorScheme.primary,
                  child: CustomScrollView(
                    // Use CustomScrollView for sliver-based layout
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // SliverPadding adds padding around the list of content widgets
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                              // List of widgets to display vertically
                              [
                                ExploreTopSection(
                                  currentCity: currentCity,
                                  userName: firstName, // Pass user's first name
                                  // Pass the HomeBloc's context for dispatching update event
                                  onCityTap: () => _openCityDropdown(context),
                                ),
                                const Gap(24),
                                const ExploreSearchBar(),
                                const Gap(24),
                                Text("Categories",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold)),
                                const Gap(12),
                                ExploreCategoryList(
                                  // Use the category list widget
                                  categories: const [
                                    // Example categories
                                    'All', 'Sports', 'Gym', 'Entertainment',
                                    'Outdoors', 'Dining', 'Cafe', 'Health'
                                  ],
                                  onCategorySelected: (category) {
                                    print(
                                        "Category selected in View: $category");
                                    // TODO: Implement filtering logic
                                  },
                                ),
                                const Gap(32), // More space
                                // Pass the actual data list from the state
                                ExplorePopularSection(
                                    popularProviders: popular),
                                const Gap(32), // More space
                                // Pass the actual data list from the state
                                ExploreRecommendedSection(
                                    recommendedProviders: recommended),
                                const Gap(20), // Bottom padding within sliver
                              ]),
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Fallback case (shouldn't normally be reached)
              return const Center(child: Text("Unknown state."));
            },
          ),
        ),
      ),
    );
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown(BuildContext blocContext) async {
    String? currentBlocCity;
    try {
      // Read the current state safely
      final currentState = blocContext.read<HomeBloc>().state;
      if (currentState is HomeLoaded) {
        currentBlocCity = currentState.homeModel.city;
      }
    } catch (e) {
      print("Error reading HomeBloc state for current city: $e");
    }

    // Show the bottom sheet (assuming showGovernoratesBottomSheet exists)
    final newCity = await showGovernoratesBottomSheet(
      context: context, // Use the general context of the _ExploreScreenState
      items: _governorates,
      title: 'Select Your Governorate',
      // selectedItem: currentBlocCity, // Optionally pass current city to pre-select
    );

    // If a new city was selected and it's different
    if (newCity != null && newCity != currentBlocCity) {
      try {
        // Use the blocContext again to dispatch the event
        blocContext.read<HomeBloc>().add(UpdateCityManually(newCity: newCity));
      } catch (e) {
        print("Error dispatching UpdateCityManually event: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not update city.")));
        }
      }
    }
  }

  /// Builds the error widget with a retry button.
  Widget _buildErrorWidget(
      BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 50),
            const Gap(16),
            Text(
              "Oops! Something went wrong.",
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.secondaryColor),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
              onPressed: () {
                try {
                  context.read<HomeBloc>().add(LoadHomeData());
                } catch (e) {
                  print("Error dispatching LoadHomeData on retry: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Builds the shimmer loading effect widget.
  Widget _buildShimmerLoading(BuildContext context, ThemeData theme) {
    final shimmerBaseColor = Colors.grey.shade300;
    final shimmerHighlightColor = Colors.grey.shade100;
    final radius = BorderRadius.circular(8);

    // Return just the shimmer column content
    // Removed SingleChildScrollView wrapper
    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      child: Column(
        // Use Column for vertical arrangement of shimmer elements
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for Top Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
                  const Gap(8),
                  Container(
                      width: 160,
                      height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
                ],
              ),
              Container(
                  width: 110,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20))),
            ],
          ),
          const Gap(24),
          // Shimmer for Search Bar
          Container(
              width: double.infinity,
              height: 50,
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: radius)),
          const Gap(24),
          // Shimmer for Category Title
          Container(
              width: 120,
              height: 22,
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: radius)),
          const Gap(12),
          // Shimmer for Category List
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.only(right: 12)),
            ),
          ),
          const Gap(24),
          // Shimmer for Section Header (Popular/Recommended)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  width: 140,
                  height: 22,
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: radius)),
              Container(
                  width: 70,
                  height: 18,
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: radius)),
            ],
          ),
          const Gap(16),
          // Shimmer for Horizontal Card List
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              clipBehavior: Clip.none,
              itemBuilder: (_, __) => Container(
                  width: 180,
                  height: 220,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(right: 16)),
            ),
          ),
          const Gap(24),
          // Shimmer for another Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  width: 160,
                  height: 22,
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: radius)),
              Container(
                  width: 70,
                  height: 18,
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: radius)),
            ],
          ),
          const Gap(16),
          // Shimmer for another Horizontal Card List
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 2,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              clipBehavior: Clip.none,
              itemBuilder: (_, __) => Container(
                  width: 180,
                  height: 220,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(right: 16)),
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}
