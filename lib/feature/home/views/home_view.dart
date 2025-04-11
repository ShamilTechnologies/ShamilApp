import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart'; // Assume this exists
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // If needed by helpers
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // For user name/pic
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // For user name/pic
import 'dart:typed_data'; // For Uint8List

// Import the section widgets
import 'home_utils/explore_search_bar.dart';
import 'home_utils/explore_category_list.dart';
import 'home_utils/explore_popular_section.dart';
import 'home_utils/explore_recommended_section.dart';
import 'home_utils/explore_top_section.dart';

// *** ADDED: Define constants locally ***
// Transparent placeholder image data (1x1 pixel PNG)
const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Example list of governorates - replace with your actual data source if needed
  final List<String> _governorates = [
    'Cairo',
    'Alexandria',
    'Giza',
    'Suez',
    'Aswan',
    'Luxor',
    'Port Said',
    'Ismailia',
    'Faiyum',
    'Minya',
    'Beheira',
    'Sharqia',
    'Qalyubia',
    'Monufia',
    'Gharbia',
    'Dakahlia',
    'Kafr El Sheikh',
    'Damietta',
    'Asyut',
    'Sohag',
    'Qena',
    'Red Sea',
    'New Valley',
    'Matruh',
    'North Sinai',
    'South Sinai',
    'Beni Suef',
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
    // Get user data from AuthBloc state - Use context.read or BlocBuilder if needed dynamically
    final authState =
        context.read<AuthBloc>().state; // Read once for initial build
    String firstName = "User";
    String? profileImageUrl;

    if (authState is LoginSuccessState) {
      final nameParts = authState.user.name.split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
      }
      profileImageUrl = authState.user.profilePicUrl ?? authState.user.image;
      if (profileImageUrl != null && profileImageUrl.isEmpty) {
        profileImageUrl = null;
      }
    }

    // Provide the HomeBloc locally to this screen and its descendants
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          // BlocBuilder rebuilds the UI based on HomeBloc state changes
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              // --- Loading State ---
              if (state is HomeLoading || state is HomeInitial) {
                // Pass necessary data from AuthBloc to shimmer builder
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  // Use ListView for shimmer to prevent potential overflows
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildShimmerLoading(
                          context, theme, firstName, profileImageUrl)
                    ], // Pass data
                  ),
                );
              }
              // --- Error State ---
              else if (state is HomeError) {
                return _buildErrorWidget(context, theme, state.message);
              }
              // --- Loaded State ---
              else if (state is HomeLoaded) {
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
                      await Future.delayed(const Duration(milliseconds: 500));
                    } catch (e) {
                      print("Error dispatching LoadHomeData on refresh: $e");
                    }
                  },
                  color: theme.colorScheme.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Build the actual top section when loaded
                            ExploreTopSection(
                              currentCity: currentCity,
                              userName: firstName,
                              profileImageUrl: profileImageUrl, // Pass the URL
                              onCityTap: () => _openCityDropdown(context),
                            ),
                            const Gap(24),
                            const ExploreSearchBar(),
                            const Gap(24),
                            Text("Categories",
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const Gap(12),
                            ExploreCategoryList(
                              categories: const [
                                // Example categories
                                'All', 'Sports', 'Gym', 'Entertainment',
                                'Outdoors', 'Dining', 'Cafe', 'Health'
                              ],
                              onCategorySelected: (category) {
                                print("Category selected in View: $category");
                                // TODO: Implement filtering logic
                              },
                            ),
                            const Gap(32),
                            ExplorePopularSection(popularProviders: popular),
                            const Gap(32),
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
              // Fallback case
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
      final currentState = blocContext.read<HomeBloc>().state;
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
      // Removed 'selectedItem' as it's not defined in the function signature
    );

    if (newCity != null && newCity != currentBlocCity) {
      try {
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

  /// Builds the error widget displayed when data loading fails.
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

  /// Builds the shimmer loading effect widget. Includes the actual Hero widget.
  Widget _buildShimmerLoading(BuildContext context, ThemeData theme,
      String userName, String? profileImageUrl) {
    final shimmerBaseColor = Colors.grey.shade300;
    final shimmerHighlightColor = Colors.grey.shade100;
    final radius = BorderRadius.circular(8);
    final profileBorderRadius =
        BorderRadius.circular(8.0); // Match ExploreTopSection
    const double avatarSize = 44.0; // Match ExploreTopSection

    // Use a Column, place the real Hero widget at the top right, shimmer the rest
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Top Section Placeholder (with real Hero) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shimmer for Greeting/Location
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
            // *** Real Hero Widget for Profile Picture ***
            Hero(
              tag: 'userProfilePic_hero', // Must match exactly
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Material(
                  color: Colors.transparent,
                  shape:
                      RoundedRectangleBorder(borderRadius: profileBorderRadius),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // Keep InkWell for consistency if needed
                    onTap: () {}, // No action needed here
                    child: (profileImageUrl == null || profileImageUrl.isEmpty)
                        // *** Use local buildProfilePlaceholder ***
                        ? buildProfilePlaceholder(
                            avatarSize, theme, profileBorderRadius)
                        : FadeInImage.memoryNetwork(
                            // *** Use local _transparentImageData ***
                            placeholder: _transparentImageData,
                            image: profileImageUrl,
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            imageErrorBuilder: (context, error, stackTrace) {
                              // *** Use local buildProfilePlaceholder ***
                              return buildProfilePlaceholder(
                                  avatarSize, theme, profileBorderRadius);
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(24),

        // --- Rest of the Shimmer Layout ---
        Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Column(
            // Wrap remaining shimmer elements
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              // Shimmer for Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      width: 140,
                      height: 22,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
                  Container(
                      width: 70,
                      height: 18,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
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
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
                  Container(
                      width: 70,
                      height: 18,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: radius)),
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
              const Gap(20), // Bottom padding
            ],
          ),
        ),
      ],
    );
  }
} // End of _ExploreScreenState

// *** ADDED: Helper function defined locally ***
/// Helper to build placeholder widget for the profile picture.
Widget buildProfilePlaceholder(
    double size, ThemeData theme, BorderRadius borderRadius) {
  return Container(
    width: size,
    height: size,
    // Decoration matches the Material shape/clip for consistency
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.05), // Subtle background
      // No need for border/radius here if parent Material/ClipRRect handles it
    ),
    child: Center(
      child: Icon(
        Icons.person_rounded, // Placeholder icon
        size: size * 0.6, // Icon size relative to container size
        color: theme.colorScheme.primary.withOpacity(0.4), // Themed icon color
      ),
    ),
  );
}
