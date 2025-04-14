import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import extracted widgets and constants
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart'; // Assume this exists
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep for potential use
import 'package:shamil_mobile_app/core/constants/app_constants.dart'; // Import governorates
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // For user name/pic
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // For user name/pic
import 'dart:typed_data'; // For Uint8List (used in shimmer)

// Import the section widgets
import 'home_utils/explore_search_bar.dart';
import 'home_utils/explore_category_list.dart';
import 'home_utils/explore_popular_section.dart';
import 'home_utils/explore_recommended_section.dart';
import 'home_utils/explore_top_section.dart';
// Import extracted widgets
import 'package:shamil_mobile_app/feature/home/widgets/home_loading_shimmer.dart';
import 'package:shamil_mobile_app/feature/home/widgets/home_error_widget.dart';
// Import the access code content widget for the bottom sheet
import 'package:shamil_mobile_app/feature/access/widgets/access_code_content.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Use imported governorates list
  final List<String> _governorates = kGovernorates;

  final TextEditingController _searchController = TextEditingController();

   @override
  void initState() {
    super.initState();
    // Load data when the screen initializes, using the Bloc provided higher up
    WidgetsBinding.instance.addPostFrameCallback((_) {
       try {
         // Ensure HomeBloc is accessible via context (provided higher up)
         final homeState = context.read<HomeBloc>().state;
         if (homeState is HomeInitial) { context.read<HomeBloc>().add(LoadHomeData()); }
       } catch (e) { print("Error dispatching initial LoadHomeData: $e"); }
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
    // Get user data from AuthBloc state - Use context.read or BlocBuilder if needed dynamically
    final authState = context.read<AuthBloc>().state; // Read once for initial build
    String firstName = "User";
    String? profileImageUrl;
    String? currentUserId; // Needed for bottom sheet content if passed there

    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty) { firstName = nameParts.first; }
      profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;
      if (profileImageUrl != null && profileImageUrl.isEmpty) { profileImageUrl = null; }
      currentUserId = authState.user.uid; // Get user ID
    }

    // HomeBloc provided by MainNavigationView
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      body: SafeArea(
        // BlocBuilder now uses the HomeBloc provided by an ancestor
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // --- Loading State ---
            if (state is HomeLoading || state is HomeInitial) {
              // Use extracted shimmer widget
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                // Use ListView for shimmer, allowing scrolling
                child: ListView(
                  // *** REMOVED physics: const NeverScrollableScrollPhysics() to FIX OVERFLOW ***
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
              // Use extracted error widget
              return HomeErrorWidget(
                message: state.message,
                // Pass the callback to reload data
                onRetry: () { try { context.read<HomeBloc>().add(LoadHomeData()); } catch (e) { print("Error dispatching LoadHomeData on retry: $e"); } },
              );
            }
            // --- Loaded State ---
            else if (state is HomeLoaded) {
              final String currentCity = state.homeModel.city;
              final List<ServiceProviderDisplayModel> popular = state.popularProviders;
              final List<ServiceProviderDisplayModel> recommended = state.recommendedProviders;

              return RefreshIndicator(
                onRefresh: () async { try { context.read<HomeBloc>().add(LoadHomeData()); await Future.delayed(const Duration(milliseconds: 500)); } catch (e) { print("Error dispatching LoadHomeData on refresh: $e"); } },
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate( [
                            ExploreTopSection(
                              currentCity: currentCity,
                              userName: firstName,
                              profileImageUrl: profileImageUrl,
                              onCityTap: () => _openCityDropdown(context),
                              onProfileTap: () => _showAccessBottomSheet(context, currentUserId, firstName, profileImageUrl),
                              // Pass flag to start revolve animation
                            ),
                            const Gap(24),
                            const ExploreSearchBar(),
                            const Gap(24),
                            Text("Categories", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const Gap(12),
                            ExploreCategoryList( categories: const [ 'All', 'Sports', 'Gym', 'Entertainment', 'Outdoors', 'Dining', 'Cafe', 'Health' ], onCategorySelected: (category) { print("Category selected: $category"); }, ),
                            const Gap(32),
                            ExplorePopularSection( popularProviders: popular ),
                            const Gap(32),
                            ExploreRecommendedSection( recommendedProviders: recommended ),
                            const Gap(20),
                          ]
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text("Unknown state."));
          },
        ),
      ),
    );
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown(BuildContext context) async { // Now uses context directly
    String? currentBlocCity;
    try {
      final currentState = context.read<HomeBloc>().state;
      if(currentState is HomeLoaded) { currentBlocCity = currentState.homeModel.city; }
    } catch (e) { print("Error reading HomeBloc state for current city: $e"); }

    final newCity = await showGovernoratesBottomSheet( context: context, items: _governorates, title: 'Select Your Governorate', );

    if (newCity != null && newCity != currentBlocCity) {
       try { context.read<HomeBloc>().add(UpdateCityManually(newCity: newCity)); }
       catch (e) { print("Error dispatching UpdateCityManually event: $e"); if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Could not update city.")) ); } }
    }
  }

  /// Shows the Access Code content in a sliding bottom sheet.
  void _showAccessBottomSheet(BuildContext context, String? userId, String? userName, String? profileImageUrl) {
     if (userId == null) { showGlobalSnackBar(context, "User data not available.", isError: true); return; }
     showModalBottomSheet( context: context, isScrollControlled: true, backgroundColor: Theme.of(context).cardColor, shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20)), ),
        builder: (sheetContext) {
           return SingleChildScrollView(
             child: AccessCodeContent(
                userId: userId,
                userName: userName,
                profileImageUrl: profileImageUrl,
                isBottomSheet: true,
             ),
           );
        },
     );
  }

  // Removed _buildErrorWidget and _buildShimmerLoading methods

} // End of _ExploreScreenState

// Removed buildProfilePlaceholder function and constants - should be imported

