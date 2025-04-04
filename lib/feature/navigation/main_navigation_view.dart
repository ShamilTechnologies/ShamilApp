import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
// Removed FirebaseAuth and Firestore imports as they are no longer used directly here

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart';
// Import the actual ProfileScreen

// Import other screen placeholders/widgets
// import 'package:shamil_mobile_app/feature/likes/views/likes_view.dart'; // Example
// import 'package:shamil_mobile_app/feature/search/views/search_view.dart'; // Example


class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _selectedIndex = 0;
  // Profile Pic URL fetch is removed from here - ProfileScreen handles its own data

  // List of the main screens. ProfileScreen is instantiated without arguments now.
  // TODO: Replace placeholders with actual screen widgets
  static final List<Widget> _widgetOptions = <Widget>[
    const ExploreScreen(), // Index 0
    const Center(child: Text('Likes Screen (Placeholder)')), // Index 1
    const Center(child: Text('Search Screen (Placeholder)')), // Index 2
    const ProfileScreen(), // Index 3 - Instantiated directly
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define GNav colors using AppColors
    final unselectedColor = AppColors.secondaryColor.withOpacity(0.8);
    const selectedColor = AppColors.primaryColor;
    final tabBackgroundColor = AppColors.primaryColor.withOpacity(0.08);
    final rippleColor = AppColors.primaryColor.withOpacity(0.1);
    final hoverColor = AppColors.primaryColor.withOpacity(0.05);

    return Scaffold(
       body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions, // Use the static list
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? colorScheme.surface,
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.06),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, -3),
             ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: rippleColor,
              hoverColor: hoverColor,
              haptic: true,
              curve: Curves.easeInCubic,
              duration: const Duration(milliseconds: 400),
              gap: 8,
              color: unselectedColor,
              activeColor: selectedColor,
              iconSize: 24,
              tabBackgroundColor: tabBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              tabs: const [
                GButton(
                  icon: LineIcons.compass,
                  text: 'Explore',
                ),
                GButton(
                  icon: LineIcons.heart,
                  text: 'Likes',
                ),
                GButton(
                  icon: LineIcons.search,
                  text: 'Search',
                ),
                // *** Using standard icon for Profile tab ***
                GButton(
                  icon: LineIcons.user, // Standard user icon for the tab
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
