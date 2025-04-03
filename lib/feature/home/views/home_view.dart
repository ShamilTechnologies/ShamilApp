// Keep for potential future use if needed directly
// Keep for potential future use if needed directly
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors if needed for specific overrides
// Use text style functions
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
// Import the display model used in the state
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

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
  final List<String> _governorates = [
    'Cairo', 'Alexandria', 'Giza', 'Suez', 'Aswan', 'Luxor',
    'Port Said', 'Ismailia', 'Faiyum', 'Minya', 'Beheira', 'Sharqia',
    'Qalyubia', 'Monufia', 'Gharbia', 'Dakahlia', 'Kafr El Sheikh',
    'Damietta', 'Asyut', 'Sohag', 'Qena', 'Red Sea', 'New Valley',
    'Matruh', 'North Sinai', 'South Sinai', 'Beni Suef',
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

    // Provide the HomeBloc here
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        body: SafeArea(
          // BlocBuilder decides the overall content (Loading/Error/Loaded ScrollView)
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              // Loading State
              if (state is HomeLoading || state is HomeInitial) {
                // Wrap shimmer content in Padding AND SingleChildScrollView
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  // *** FIX: Added SingleChildScrollView ***
                  child: SingleChildScrollView(child: _buildShimmerLoading(context)),
                );
              }
              // Error State
              else if (state is HomeError) {
                return _buildErrorWidget(context, state.message);
              }
              // Loaded State - Build the ScrollView
              else if (state is HomeLoaded) {
                // Extract data from the state *once*
                final String currentCity = state.homeModel.city;
                final List<ServiceProviderDisplayModel> popular = state.popularProviders;
                final List<ServiceProviderDisplayModel> recommended = state.recommendedProviders;

                // Return the RefreshIndicator wrapping the CustomScrollView
                return RefreshIndicator(
                   onRefresh: () async {
                      try {
                         context.read<HomeBloc>().add(LoadHomeData());
                         await Future.delayed(const Duration(milliseconds: 500));
                      } catch (e) {
                         print("Error dispatching LoadHomeData on refresh: $e");
                      }
                   },
                   color: AppColors.primaryColor,
                  child: CustomScrollView(
                    slivers: [
                      // Use SliverPadding for overall padding around the content list
                      SliverPadding(
                         padding: const EdgeInsets.all(16.0),
                         // Use SliverList with a delegate that builds a list of widgets directly
                         sliver: SliverList(
                            delegate: SliverChildListDelegate(
                               // Build the list of widgets directly using loaded data
                               [
                                  ExploreTopSection(
                                    currentCity: currentCity,
                                    // Pass the BlocBuilder's context for Bloc access
                                    onCityTap: () => _openCityDropdown(context),
                                  ),
                                  const SizedBox(height: 24),
                                  const ExploreSearchBar(),
                                  const SizedBox(height: 24),
                                  Text("Categories", style: theme.textTheme.headlineSmall),
                                  const SizedBox(height: 12),
                                  ExploreCategoryList(
                                    categories: const [
                                      'All', 'Sports', 'Gym', 'Entertainment',
                                      'Outdoors', 'Dining', 'Cafe', 'Health'
                                    ],
                                    onCategorySelected: (category) {
                                      print("Category selected in View: $category");
                                      // TODO: Implement filtering
                                      // Example: context.read<HomeBloc>().add(FilterByCategory(category));
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  // Pass the actual data list from the state
                                  ExplorePopularSection(
                                    popularProviders: popular,
                                  ),
                                  const SizedBox(height: 24),
                                  // Pass the actual data list from the state
                                  ExploreRecommendedSection(
                                    recommendedProviders: recommended,
                                  ),
                                  const SizedBox(height: 20), // Bottom padding
                               ]
                            ),
                         ),
                      ),
                    ],
                  ),
                );
              }
              // Fallback case
              return const Center(child: Text("Unknown state."));
            },
          ),
        ),
      ),
    );
  }

   /// Builds the error widget with a retry button.
  Widget _buildErrorWidget(BuildContext context, String message) {
     final theme = Theme.of(context);
     return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
             const SizedBox(height: 16),
             Text(
                "Oops! Something went wrong.",
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
             ),
             const SizedBox(height: 8),
             Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.secondaryColor),
                textAlign: TextAlign.center,
             ),
             const SizedBox(height: 24),
             ElevatedButton.icon(
               icon: const Icon(Icons.refresh, size: 18),
               label: const Text("Retry"),
               onPressed: () {
                  try {
                    // Use the context passed to the method which has access to the Bloc
                    context.read<HomeBloc>().add(LoadHomeData());
                  } catch (e) {
                     print("Error dispatching LoadHomeData on retry: $e");
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not reload data."))
                     );
                  }
               },
               style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               ),
             )
           ],
         ),
       ));
  }


  /// Opens the global bottom sheet for governorate selection.
  /// Needs the correct context that has access to HomeBloc.
  Future<void> _openCityDropdown(BuildContext blocContext) async {
     String? currentBlocCity;
     try {
       final currentState = blocContext.read<HomeBloc>().state;
       if(currentState is HomeLoaded) {
          currentBlocCity = currentState.homeModel.city;
       }
     } catch (e) {
        print("Error reading HomeBloc state for current city: $e");
     }

    final newCity = await showGovernoratesBottomSheet(
      context: context, // Use the general context of the _ExploreScreenState
      items: _governorates,
      title: 'Select Your Governorate',
    );

    if (newCity != null && newCity != currentBlocCity) {
       try {
         // Use the blocContext again to dispatch the event
         blocContext.read<HomeBloc>().add(UpdateCityManually(newCity: newCity));
       } catch (e) {
          print("Error dispatching UpdateCityManually event: $e");
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Could not update city."))
          );
       }
    }
  }


  /// Builds the shimmer loading effect widget.
  Widget _buildShimmerLoading(BuildContext context) {
     final theme = Theme.of(context);
     final shimmerBaseColor = Colors.grey.shade300;
     final shimmerHighlightColor = Colors.grey.shade100;
     final radius = BorderRadius.circular(8);

    // Return only the shimmer content, padding is handled outside now
    // *** FIX: Wrap Column in SingleChildScrollView ***
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for shimmer itself
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: Column(
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
                      Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                      const SizedBox(height: 8),
                      Container(width: 160, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                    ],
                  ),
                   Container(width: 110, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                ],
              ),
              const SizedBox(height: 24),
              // Shimmer for Search Bar
              Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
              const SizedBox(height: 24),
               // Shimmer for Category Title
               Container(width: 120, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
               const SizedBox(height: 12),
              // Shimmer for Category List
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  itemBuilder: (_, __) => Container(width: 80, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), margin: const EdgeInsets.only(right: 12)),
                ),
              ),
              const SizedBox(height: 24),
              // Shimmer for Section Header (Popular/Recommended)
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(width: 140, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                   Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                ],
              ),
               const SizedBox(height: 16),
              // Shimmer for Horizontal Card List
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  clipBehavior: Clip.none,
                  itemBuilder: (_, __) => Container(
                     width: 180, height: 220,
                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                     margin: const EdgeInsets.only(right: 16)
                  ),
                ),
              ),
              const SizedBox(height: 24),
               // Shimmer for another Section Header
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(width: 160, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                   Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: radius)),
                ],
              ),
               const SizedBox(height: 16),
               // Shimmer for another Horizontal Card List
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                   padding: const EdgeInsets.symmetric(vertical: 4.0),
                   clipBehavior: Clip.none,
                  itemBuilder: (_, __) => Container(
                     width: 180, height: 220,
                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                     margin: const EdgeInsets.only(right: 16)
                  ),
                ),
              ),
               const SizedBox(height: 20),
            ],
          ),
      ),
    );
  }
}
