// lib/feature/category_detail/views/category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/views/home_utils/explore_category_list.dart';
import 'package:shamil_mobile_app/feature/home/widgets/service_provider_card.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/constants/business_categories.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer for placeholder

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
          // Load ALL providers for the main category initially
          context.read<HomeBloc>().add(FilterByCategory(category: widget.categoryName));
          // Default to "All" sub-category selection
          setState(() { _selectedSubCategory = "All"; });
       }
    });
  }

  List<String> _getSubCategories() {
    final subs = getSubcategoriesFor(widget.categoryName);
    return ["All", ...subs];
  }

  void _onSubCategorySelected(String subCategory) {
     print("Sub-category selected: $subCategory");
     // Update local state FIRST to change the appearance of ExploreCategoryList
     setState(() {
       _selectedSubCategory = subCategory;
     });
     // Dispatch event to filter the list
     context.read<HomeBloc>().add(FilterBySubCategory(
        mainCategory: widget.categoryName,
        subCategory: subCategory
     ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> subCategoriesToShow = _getSubCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Sub-Category Filter List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))
            ),
            child: ExploreCategoryList(
               key: ValueKey(widget.categoryName + (_selectedSubCategory ?? 'All')), // Key helps update selection
               categories: subCategoriesToShow, // Correct parameter name
               onCategorySelected: _onSubCategorySelected,
               initialCategory: _selectedSubCategory, // Pass current selection state
               isSubCategoryList: true, // Indicate these are sub-categories
            ),
          ),

          // List of Service Providers
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                bool isLoading = state is HomeLoading;
                HomeDataLoaded? loadedState;
                List<ServiceProviderDisplayModel> providers = [];

                // Determine the source of truth for providers based on state
                if (state is HomeDataLoaded) {
                  loadedState = state;
                  // Use categoryFilteredResults if the filters match, otherwise show empty/loading
                  if (loadedState.filteredByCategory == widget.categoryName &&
                      (loadedState.selectedSubCategory ?? "All") == (_selectedSubCategory ?? "All")) {
                     providers = loadedState.homeData.categoryFilteredResults;
                  } else if (!isLoading) {
                    // If state doesn't match current filters but isn't loading, show empty/message
                    // This handles cases where the state is lagging the UI selection
                    print("State filters (${loadedState.filteredByCategory}/${loadedState.selectedSubCategory}) don't match UI (${widget.categoryName}/${_selectedSubCategory}). Showing potentially empty list.");
                  }

                } else if (state is HomeLoading && state.previousState != null) {
                    loadedState = state.previousState!;
                    // Show stale data while loading new filter results
                     if (loadedState.filteredByCategory == widget.categoryName) {
                          providers = loadedState.homeData.categoryFilteredResults;
                     }
                } else if (state is HomeError && state.previousState != null) {
                   // Show stale data on error
                   loadedState = state.previousState!;
                    if (loadedState.filteredByCategory == widget.categoryName) {
                          providers = loadedState.homeData.categoryFilteredResults;
                     }
                }

                // Show loading shimmer *only* if there's no stale data to display
                if (isLoading && providers.isEmpty) {
                  return GridView.builder(
                     padding: const EdgeInsets.all(16.0),
                     itemCount: 6,
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2, crossAxisSpacing: 12.0, mainAxisSpacing: 12.0, childAspectRatio: 0.75,
                     ),
                     itemBuilder: (ctx, index) => const ServiceProviderCardShimmer(),
                  );
                }
                 // Show error *only* if there's no stale data
                if (state is HomeError && providers.isEmpty) {
                   return Center(child: Text("Error: ${state.message}"));
                }

                // Show empty state if not loading and list is empty
                if (providers.isEmpty && !isLoading) {
                   return Center(child: Padding( padding: const EdgeInsets.all(32.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                           Icon(Icons.storefront_outlined, size: 60, color: Colors.grey.shade400), const Gap(16),
                           Text( "No providers found for '${_selectedSubCategory ?? widget.categoryName}'.", textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600), ),
                         ], ), ) );
                }

                // Display results Grid (potentially stale while loading)
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0, mainAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return ServiceProviderCard(
                       provider: provider,
                       heroTagPrefix: "category_${widget.categoryName}",
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Add a simple shimmer widget for the card
class ServiceProviderCardShimmer extends StatelessWidget {
  const ServiceProviderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
       elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
       clipBehavior: Clip.antiAlias,
       child: Shimmer.fromColors(
         baseColor: Colors.grey.shade300,
         highlightColor: Colors.grey.shade100,
         child: Container(color: Colors.white),
       ),
    );
  }
}