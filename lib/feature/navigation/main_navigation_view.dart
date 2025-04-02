import 'package:flutter/material.dart';
// Import GNav and LineIcons
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep for potential future use
import 'package:cloud_firestore/cloud_firestore.dart'; // Keep for potential future use

// Import App Colors
import 'package:shamil_mobile_app/core/utils/colors.dart';

import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
// Import other screen widgets when they are created
// import 'package:shamil_mobile_app/feature/search/views/search_view.dart';
// import 'package:shamil_mobile_app/feature/bookings/views/bookings_view.dart';
// import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'; // Import Profile Screen

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _selectedIndex = 0; // Index for the selected tab (starts at 0 for Explore)
  // Profile Pic URL fetch is removed from here - should be handled by state management

  // List of the main screens corresponding to the navigation bar items
  // ExploreScreen is correctly placed at index 0
  // TODO: Replace placeholders with actual screen widgets
  static final List<Widget> _widgetOptions = <Widget>[
    const ExploreScreen(), // Index 0: Home/Explore screen
    const Center(child: Text('Likes Screen (Placeholder)')), // Index 1: Placeholder for Likes
    const Center(child: Text('Search Screen (Placeholder)')), // Index 2: Placeholder for Search
    const Center(child: Text('Profile Screen (Placeholder)')), // Index 3: Placeholder for Profile
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

    // Define GNav colors using AppColors for a themed, modern look
    final unselectedColor = AppColors.secondaryColor.withOpacity(0.8);
    final selectedColor = AppColors.primaryColor;
    // Subtle background for the active tab bubble
    final tabBackgroundColor = AppColors.primaryColor.withOpacity(0.08);
    // Colors for interaction feedback
    final rippleColor = AppColors.primaryColor.withOpacity(0.1);
    final hoverColor = AppColors.primaryColor.withOpacity(0.05);

    return Scaffold(
      body: Center(
        // Use IndexedStack to keep the state of the screens when switching tabs
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      // Implement GNav within a Container for background and shadow
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? colorScheme.surface, // Use theme background
          boxShadow: [
             BoxShadow(
                // Soft, diffused shadow
                color: Colors.black.withOpacity(0.06),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, -3),
             ),
          ],
        ),
        // Ensure safe area padding for the navigation bar
        child: SafeArea(
          child: Padding(
            // Padding around the GNav bar itself
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              // Apply styling using AppColors and refined values
              rippleColor: rippleColor,
              hoverColor: hoverColor,
              haptic: true, // Haptic feedback on tap
              // tabBorderRadius: 15, // Keep rounded tabs
              // Remove borders for a cleaner look
              // tabActiveBorder: Border.all(color: selectedColor.withOpacity(0.5), width: 1),
              // tabBorder: Border.all(color: Colors.transparent, width: 1),
              curve: Curves.easeInCubic, // Smoother animation curve
              duration: const Duration(milliseconds: 400), // Faster animation
              gap: 8, // Space between icon and text
              color: unselectedColor, // Inactive icon/text color
              activeColor: selectedColor, // Active icon/text color (App Primary)
              iconSize: 24, // Standard icon size
              tabBackgroundColor: tabBackgroundColor, // Subtle active tab background
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding inside each tab button

              // Define the tabs
              tabs: const [
                GButton(
                  icon: LineIcons.compass, // Alternative explore icon
                  // icon: LineIcons.home,
                  text: 'Explore',
                ),
                GButton(
                  icon: LineIcons.heart, // Use filled heart
                  // icon: LineIcons.heart_o,
                  text: 'Likes',
                ),
                GButton(
                  icon: LineIcons.search,
                  text: 'Search',
                ),
                // Profile Tab - Using standard icon
                GButton(
                  icon: LineIcons.user, // Standard user icon
                  text: 'Profile',
                  // Note: Display the actual user photo within the Profile screen, not here.
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped, // Handler for tab changes
            ),
          ),
        ),
      ),
    );
  }
}
