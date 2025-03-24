import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/bottom_sheets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

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

  // Holds the manually selected city; if null, realtime location is used.
  String? _manualCity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadHomeData()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
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
                      const SizedBox(height: 20),
                      _buildTopSection(currentCity),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildCategoryList(),
                      const SizedBox(height: 20),
                      _buildPopularSection(),
                      const SizedBox(height: 20),
                      _buildRecommendedSection(),
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
    );
  }

  /// Top section: Left side displays "Explore" and the large city name;
  /// right side displays a location icon with a dropdown arrow.
  Widget _buildTopSection(String currentCity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore',
              style: getbodyStyle(
                color: AppColors.yellowColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentCity,
              style: getbodyStyle(
                color: AppColors.primaryColor,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        // Right side: when tapped, opens the global bottom sheet.
        GestureDetector(
          onTap: _openCityDropdown,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              Text(
                '$currentCity, Egp',
                style: getbodyStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
            ],
          ),
        ),
      ],
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

  /// Search bar widget.
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Find things to do',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Horizontal list of categories.
  Widget _buildCategoryList() {
    final List<String> categories = [
      'All Categories',
      'Sports & Fitness',
      'Entertainment',
      'Outdoors',
      'Dining',
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Handle category tap.
            },
            child: Text(
              categories[index],
              style: getbodyStyle(
                color: index == 0 ? AppColors.primaryColor : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Popular section widget.
  Widget _buildPopularSection() {
    final List<Map<String, String>> popularItems = [
      {'title': 'PRO PADEL', 'rating': '4.1', 'image': 'assets/padel.png'},
      {'title': 'Gold\'s GYM', 'rating': '4.5', 'image': 'assets/gym.png'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Popular'),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = popularItems[index];
              return _buildCardItem(item['title']!, item['rating']!, item['image']!);
            },
          ),
        ),
      ],
    );
  }

  /// Recommended section widget.
  Widget _buildRecommendedSection() {
    final List<Map<String, String>> recommendedItems = [
      {'title': 'Fury Arena', 'rating': '4.7', 'image': 'assets/arena.png'},
      {'title': 'Luxury Arena', 'rating': '4.3', 'image': 'assets/arena2.png'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recommended'),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = recommendedItems[index];
              return _buildCardItem(item['title']!, item['rating']!, item['image']!);
            },
          ),
        ),
      ],
    );
  }

  /// Section header with "See all".
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: getbodyStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            // Handle "See all"
          },
          child: const Text(
            'See all',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Builds a card item for "Popular" or "Recommended".
  Widget _buildCardItem(String title, String rating, String imagePath) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.yellow.shade600),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
