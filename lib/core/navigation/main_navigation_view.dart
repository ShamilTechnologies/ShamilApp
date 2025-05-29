// lib/core/navigation/main_navigation_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shamil_mobile_app/core/navigation/navigation_notifier.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_event.dart';
import 'package:shamil_mobile_app/feature/community/repository/community_repository.dart';
import 'package:shamil_mobile_app/feature/community/view/community_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/views/favorites_screen.dart';
import 'package:shamil_mobile_app/feature/home/views/home_view.dart';
import 'package:shamil_mobile_app/feature/passes/bloc/my_passes_bloc.dart';
import 'package:shamil_mobile_app/feature/passes/view/passes_screen.dart';

import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart'; // Import Notifier
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';

// ... other imports (screens, etc.) ...

class MainNavigationView extends StatefulWidget {
  final int initialIndex;
  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _selectedIndex;
  late NavigationNotifier _navigationNotifier; // Store notifier instance

  // Keep your widget options list
  static final List<Widget> _widgetOptions = <Widget>[
    // --- Explore Screen (Index 0) ---
    const ExploreScreen(),
    // --- My Passes Screen (Index 1) ---
    BlocProvider<MyPassesBloc>(
      create: (context) =>
          MyPassesBloc(userRepository: context.read<UserRepository>())
            ..add(const LoadMyPasses()),
      child: const PassesScreen(),
    ),
    // --- Community Screen (Index 2) ---
    BlocProvider<CommunityBloc>(
      create: (context) => CommunityBloc(
        communityRepository: context.read<CommunityRepository>(),
      )..add(const LoadCommunityData()),
      child: const CommunityScreen(),
    ),
    // --- Favorites Screen (Index 3) ---
    const FavoritesScreen(),
    // --- Profile Screen (Index 4) ---
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Get the notifier instance and add a listener
    _navigationNotifier =
        Provider.of<NavigationNotifier>(context, listen: false);
    _navigationNotifier.addListener(_handleTabChangeFromNotifier);
    // Ensure the notifier's initial state matches the widget's initial state
    _navigationNotifier.internalSetIndex(_selectedIndex);
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    _navigationNotifier.removeListener(_handleTabChangeFromNotifier);
    super.dispose();
  }

  // Listener method to update local state when notifier changes
  void _handleTabChangeFromNotifier() {
    if (mounted && _navigationNotifier.selectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = _navigationNotifier.selectedIndex;
      });
    }
  }

  // Called when the user taps a GNav button
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Also update the notifier so the state is consistent
      _navigationNotifier.internalSetIndex(index);
    }
  }

  // Public method to navigate (can be called from other parts if needed, but notifier is preferred)
  // void navigateToTab(int index) {
  //   _onItemTapped(index);
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unselectedColor = AppColors.secondaryColor.withOpacity(0.8);
    const selectedColor = AppColors.primaryColor;
    final tabBackgroundColor = AppColors.primaryColor.withOpacity(0.08);
    final rippleColor = AppColors.primaryColor.withOpacity(0.1);
    final hoverColor = AppColors.primaryColor.withOpacity(0.05);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        // ... (rest of your GNav styling) ...
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: rippleColor, hoverColor: hoverColor, haptic: true,
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 500),
              gap: 8,
              color: unselectedColor, activeColor: selectedColor, iconSize: 24,
              tabBackgroundColor: tabBackgroundColor,
              tabBorderRadius: 12.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tabs: const [
                GButton(
                  icon: LineIcons.compass,
                  text: 'Explore',
                ),
                GButton(
                  icon: LineIcons.alternateTicket,
                  text: 'My Passes',
                ),
                GButton(
                  icon: LineIcons.users,
                  text: 'Community',
                ),
                GButton(
                  icon: LineIcons.heart,
                  text: 'Favorites',
                ),
                GButton(
                  icon: LineIcons.user,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped, // Use the internal handler
            ),
          ),
        ),
      ),
    );
  }
}
