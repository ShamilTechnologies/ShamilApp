import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc package
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

import 'package:shamil_mobile_app/core/utils/colors.dart'; // For custom colors
import 'package:shamil_mobile_app/feature/home/views/home_view.dart'; // ExploreScreen
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'; // Actual ProfileScreen
import 'package:shamil_mobile_app/feature/access/views/access_code_view.dart'; // Import AccessCodeView
// Import HomeBloc to provide it
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';

// Import other screen placeholders/widgets when created
// import 'package:shamil_mobile_app/feature/likes/views/likes_view.dart'; // Example
// import 'package:shamil_mobile_app/feature/search/views/search_view.dart'; // Example

class MainNavigationView extends StatefulWidget {
  final int initialIndex; // Optional initial index
  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _selectedIndex; // Use late initialization

  // *** UPDATED: Corrected widget list to match tabs ***
  static final List<Widget> _widgetOptions = <Widget>[
    const ExploreScreen(), // Index 0
    const Center(child: Text('Likes Screen (Placeholder)')), // Index 1
    const Center(child: Text('Likes Screen (Placeholder)')), // Index 1

    const ProfileScreen(), // Index 3
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        widget.initialIndex; // Set initial index from widget property
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define GNav colors using AppColors or Theme for consistency
    final unselectedColor = AppColors.secondaryColor.withOpacity(0.8);
    const selectedColor = AppColors.primaryColor;
    final tabBackgroundColor = AppColors.primaryColor.withOpacity(0.08);
    final rippleColor = AppColors.primaryColor.withOpacity(0.1);
    final hoverColor = AppColors.primaryColor.withOpacity(0.05);

    return Scaffold(
      // *** ADDED BlocProvider<HomeBloc> back around the body ***
      body: BlocProvider<HomeBloc>(
        // Create HomeBloc here - it will persist as long as MainNavigationView is alive
        create: (context) => HomeBloc(),
        // The IndexedStack now has access to the HomeBloc provided above
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions, // Use the corrected list
        ),
      ),
      // Configure the Bottom Navigation Bar using GNav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Use theme color for background, fallback to surface
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              colorScheme.surface,
          // Add subtle shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, -3), // Shadow position (top)
            ),
          ],
        ),
        // Ensure content is within safe area (respects notches, etc.)
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: rippleColor,
              hoverColor: hoverColor,
              haptic: true, // Enable haptic feedback on tap
              curve: Curves.easeInCubic, // Tab animation curve
              duration:
                  const Duration(milliseconds: 400), // Tab animation duration
              gap: 8, // Space between icon and text
              color: unselectedColor, // Icon and text color of unselected tab
              activeColor: selectedColor, // Icon and text color of selected tab
              iconSize: 24,
              tabBackgroundColor:
                  tabBackgroundColor, // Background color of active tab
              tabBorderRadius:
                  8.0, // Use 8px radius for the active tab background
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // Adjusted padding
              // Tabs list reflects the desired items
              tabs: const [
                GButton(
                  icon: LineIcons.compass, // Using LineIcons
                  text: 'Explore',
                ),
                GButton(
                  icon: LineIcons.heart, // Or LineIcons.heart_o for outline
                  text: 'Likes',
                ),
                GButton(
                  icon: LineIcons.key, // User's preferred icon
                  text: 'Access', // New label
                ),
                GButton(
                  icon: LineIcons.user,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex, // Current selected index
              onTabChange: _onItemTapped, // Callback function when tab changes
            ),
          ),
        ),
      ),
    );
  }
}
