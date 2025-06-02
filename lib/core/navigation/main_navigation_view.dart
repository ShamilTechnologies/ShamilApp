// lib/core/navigation/main_navigation_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'dart:ui' as ui;

// ... other imports (screens, etc.) ...

class MainNavigationView extends StatefulWidget {
  final int initialIndex;
  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late NavigationNotifier _navigationNotifier; // Store notifier instance
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late List<AnimationController> _iconControllers;

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

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.explore_rounded,
      activeIcon: Icons.explore,
      label: 'Explore',
      gradient: [AppColors.primaryColor, AppColors.tealColor],
    ),
    _NavItem(
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      label: 'Passes',
      gradient: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Community',
      gradient: [const Color(0xFF06B6D4), const Color(0xFF00D4FF)],
    ),
    _NavItem(
      icon: Icons.favorite_outline_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorites',
      gradient: [const Color(0xFFEC4899), const Color(0xFFF97316)],
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      gradient: [const Color(0xFF10B981), const Color(0xFF06B6D4)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconControllers = List.generate(
      _navItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // Start floating animation
    _floatingController.repeat(reverse: true);

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
    _animationController.dispose();
    _floatingController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Listener method to update local state when notifier changes
  void _handleTabChangeFromNotifier() {
    if (mounted && _navigationNotifier.selectedIndex != _selectedIndex) {
      _onItemTapped(_navigationNotifier.selectedIndex);
    }
  }

  // Called when the user taps a navigation item
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Animate the icon
      _iconControllers[index].forward().then((_) {
        _iconControllers[index].reverse();
      });

      setState(() {
        _selectedIndex = index;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Also update the notifier so the state is consistent
      _navigationNotifier.internalSetIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0A0E1A),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildPremiumBottomNavBar(),
    );
  }

  Widget _buildPremiumBottomNavBar() {
    return Container(
      height: 90 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0A0E1A).withOpacity(0.95),
            const Color(0xFF0A0E1A),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == _selectedIndex;

                    return _buildPremiumNavItem(
                      item: item,
                      index: index,
                      isSelected: isSelected,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumNavItem({
    required _NavItem item,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _iconControllers[index],
          _floatingController,
        ]),
        builder: (context, child) {
          final floatingOffset = isSelected
              ? Tween<double>(begin: 0, end: 2)
                  .animate(
                    CurvedAnimation(
                      parent: _floatingController,
                      curve: Curves.easeInOut,
                    ),
                  )
                  .value
              : 0.0;

          final scaleValue = 1.0 + (_iconControllers[index].value * 0.2);

          return Transform.translate(
            offset: Offset(0, -floatingOffset),
            child: Transform.scale(
              scale: scaleValue,
              child: SizedBox(
                width: 60,
                height: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container with premium styling
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item.gradient,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: item.gradient.first.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Label with optimized styling
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        letterSpacing: 0.3,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<Color> gradient;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}
