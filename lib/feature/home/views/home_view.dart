import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
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
  // List of Egyptian governorates.
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
  ];

  // Manually selected city; if null, the realtime city from HomeBloc is used.
  String? _manualCity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        body: Container(
                    color: AppColors.accentColor.withOpacity(0.6),

          child: SafeArea(
            
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return _buildShimmerLoading();
                  } else if (state is HomeLoaded) {
                    final String currentCity = _manualCity ?? state.homeModel.city;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        ExploreTopSection(
                          currentCity: currentCity,
                          onCityTap: _openCityDropdown,
                        ),
                        const SizedBox(height: 20),
                        const ExploreSearchBar(),
                        const SizedBox(height: 20),
                        const ExploreCategoryList(
                          categories: [
                            'All Categories',
                            'Sports & Fitness',
                            'Entertainment',
                            'Outdoors',
                            'Dining',
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Update popular items with network image URLs.
                        const ExplorePopularSection(
                          popularItems: [
                           {
            'title': 'Fury Arena',
            'rating': '4.7',
            'image': 'https://via.placeholder.com/160x200?text=Arena+1'
          }
          ,
                            {
                              'title': 'Luxury Arena',
                              'rating': '4.3',
                              'image': 'https://via.placeholder.com/160x200?text=Arena+2'
                            },
                            {
                              'title': 'Gold\'s GYM',
                              'rating': '4.5',
                              'image': 'https://via.placeholder.com/160x200?text=Gym'
                            },
                            {
                              'title': 'Gold\'s GYM',
                              'rating': '4.5',
                              'image': 'https://via.placeholder.com/160x200?text=Gym'
                            },
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Update recommended items with network image URLs.
                        const ExploreRecommendedSection(
                          recommendedItems: [
                            {
                              'title': 'Fury Arena',
                              'rating': '4.7',
                              'image': 'https://via.placeholder.com/160x200?text=Arena+1'
                            },
                            {
                              'title': 'Luxury Arena',
                              'rating': '4.3',
                              'image': 'https://via.placeholder.com/160x200?text=Arena+2'
                            },
                          ],
                        ),
                      ],
                    );
                  } else if (state is HomeError) {
                    return Center(child: Text("Error: ${state.message}"));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the global bottom sheet for governorate selection.
  Future<void> _openCityDropdown() async {
    final newCity = await showGovernoratesBottomSheet(
      context: context,
      items: _governorates,
      title: 'Select Your Governorate',
    );
    if (newCity != null) {
      setState(() {
        _manualCity = newCity;
      });
      await _updateCityInFirestore(newCity);
      context.read<HomeBloc>().add(LoadHomeData());
    }
  }

  /// Updates the city in Firestore for the current user.
  Future<void> _updateCityInFirestore(String newCity) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection("endUsers")
          .doc(currentUser.uid)
          .update({
        'city': newCity,
        'lastUpdatedLocation': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Shimmer effect widget for loading.
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(width: 80, height: 16, color: Colors.white),
          const SizedBox(height: 4),
          Container(width: 120, height: 24, color: Colors.white),
          const SizedBox(height: 20),
          Container(width: double.infinity, height: 50, color: Colors.white),
        ],
      ),
    );
  }
}
