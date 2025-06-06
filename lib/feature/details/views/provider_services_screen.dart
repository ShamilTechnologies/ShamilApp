import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/view/enhanced_booking_configuration_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  final ServiceProviderModel provider;

  const ProviderServicesScreen({
    super.key,
    required this.provider,
  });

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen>
    with TickerProviderStateMixin {
  // Enhanced animation controllers
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _itemsAnimationController;

  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _searchFadeAnimation;
  late Animation<double> _itemsFadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _hasServices = false;
  bool _hasPlans = false;
  String _searchQuery = '';
  List<BookableService> _filteredServices = [];
  List<SubscriptionPlan> _filteredPlans = [];
  String _selectedCategory = 'all'; // 'all', 'services', 'plans'
  bool _showSearchResults = false;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _hasServices = widget.provider.bookableServices.isNotEmpty;
    _hasPlans = widget.provider.subscriptionPlans.isNotEmpty;
    _filteredServices = widget.provider.bookableServices;
    _filteredPlans = widget.provider.subscriptionPlans;

    // Initialize enhanced animation controllers
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _itemsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Setup animations
    _heroAnimation = CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutCubic,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _searchFadeAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    );
    _itemsFadeAnimation = CurvedAnimation(
      parent: _itemsAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Start staggered animations
    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _searchAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _itemsAnimationController.forward();
    });

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _showSearchResults = _searchQuery.isNotEmpty;

      _filteredServices = widget.provider.bookableServices.where((service) {
        return service.name.toLowerCase().contains(_searchQuery) ||
            service.description.toLowerCase().contains(_searchQuery);
      }).toList();

      _filteredPlans = widget.provider.subscriptionPlans.where((plan) {
        return plan.name.toLowerCase().contains(_searchQuery) ||
            plan.description.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _searchAnimationController.dispose();
    _itemsAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.deepSpaceNavy,
        ),
        child: Stack(
          children: [
            // Professional ambient orbs
            ..._buildAmbientDesign(),

            // Main content
            FadeTransition(
              opacity: _heroAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Modern Hero Header
                    _buildModernHeroHeader(),

                    // Enhanced Search Section
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _searchFadeAnimation,
                        child: _buildEnhancedSearchSection(),
                      ),
                    ),

                    // Premium Content
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _itemsFadeAnimation,
                        child: _buildPremiumContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Professional Ambient Design Elements
  List<Widget> _buildAmbientDesign() {
    return [
      // Primary ambient orb
      Positioned(
        top: 80,
        right: -120,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                AppColors.tealColor.withOpacity(0.15),
                AppColors.tealColor.withOpacity(0.08),
                AppColors.tealColor.withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
      ),
      // Secondary ambient orb
      Positioned(
        top: 300,
        left: -80,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                AppColors.electricBlue.withOpacity(0.12),
                AppColors.electricBlue.withOpacity(0.06),
                AppColors.electricBlue.withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
      ),
    ];
  }

  // Modern Hero Header
  Widget _buildModernHeroHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(),
      actions: [],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroBackground(),
      ),
    );
  }

  // Hero Background
  Widget _buildHeroBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepSpaceNavy,
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Dynamic gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.tealColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation row
                  Row(
                    children: [
                      // Back button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.chevron_left,
                                    color: AppColors.lightText,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Stats badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Text(
                              '${widget.provider.bookableServices.length + widget.provider.subscriptionPlans.length} Items',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 12,
                                color: AppColors.lightText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(30),

                  // Provider info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.provider.businessName,
                        style: AppTextStyle.getHeadlineTextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.tealColor
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Services & Subscription Plans',
                          style: AppTextStyle.getSmallStyle(
                            fontSize: 12,
                            color: AppColors.lightText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Search Section
  Widget _buildEnhancedSearchSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Modern search bar
          _buildModernSearchBar(),
          const Gap(20),
          // Enhanced category tabs
          _buildEnhancedCategoryTabs(),
        ],
      ),
    );
  }

  // Modern Search Bar
  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSearchFocused
              ? AppColors.primaryColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? AppColors.primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: _isSearchFocused ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search services and plans...',
              hintStyle: AppTextStyle.getbodyStyle(
                color: AppColors.lightText.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.tealColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.lightText,
                  size: 18,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            color: AppColors.lightText,
                            size: 14,
                          ),
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Category Tabs
  Widget _buildEnhancedCategoryTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumCategoryTab(
            'All Items',
            'all',
            CupertinoIcons.square_stack_3d_up,
            _filteredServices.length + _filteredPlans.length,
          ),
        ),
        if (_hasServices) ...[
          const Gap(12),
          Expanded(
            child: _buildPremiumCategoryTab(
              'Services',
              'services',
              CupertinoIcons.wrench_fill,
              _filteredServices.length,
            ),
          ),
        ],
        if (_hasPlans) ...[
          const Gap(12),
          Expanded(
            child: _buildPremiumCategoryTab(
              'Plans',
              'plans',
              CupertinoIcons.doc_text_fill,
              _filteredPlans.length,
            ),
          ),
        ],
      ],
    );
  }

  // Premium Category Tab
  Widget _buildPremiumCategoryTab(
      String label, String category, IconData icon, int count) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.tealColor],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.lightText
                      : AppColors.lightText.withOpacity(0.7),
                ),
                const Gap(8),
                Text(
                  label,
                  style: AppTextStyle.getSmallStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppColors.lightText
                        : AppColors.lightText.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyle.getSmallStyle(
                      fontSize: 10,
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Content
  Widget _buildPremiumContent() {
    List<dynamic> items = [];

    if (_selectedCategory == 'all') {
      items.addAll(_filteredServices);
      items.addAll(_filteredPlans);
    } else if (_selectedCategory == 'services') {
      items.addAll(_filteredServices);
    } else if (_selectedCategory == 'plans') {
      items.addAll(_filteredPlans);
    }

    if (items.isEmpty) {
      return _buildPremiumEmptyState();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: item is BookableService
                          ? _buildPremiumServiceCard(item)
                          : _buildPremiumPlanCard(item as SubscriptionPlan),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          const Gap(100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Gap(16),
              // Provider Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.provider.businessName,
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Browse Services & Plans',
                      style: AppTextStyle.getSmallStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Stats Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${widget.provider.bookableServices.length + widget.provider.subscriptionPlans.length} Items',
                  style: AppTextStyle.getSmallStyle(
                    fontSize: 11,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search services and plans...',
          hintStyle: AppTextStyle.getbodyStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: AppColors.secondaryText,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppColors.secondaryText,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.secondaryText.withOpacity(0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.secondaryText.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHorizontalCategories() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip(
            'All Items',
            'all',
            CupertinoIcons.rectangle_stack,
            _filteredServices.length + _filteredPlans.length,
          ),
          if (_hasServices) ...[
            const Gap(12),
            _buildCategoryChip(
              'Services',
              'services',
              CupertinoIcons.wrench,
              _filteredServices.length,
            ),
          ],
          if (_hasPlans) ...[
            const Gap(12),
            _buildCategoryChip(
              'Plans',
              'plans',
              CupertinoIcons.doc_text,
              _filteredPlans.length,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      String label, String category, IconData icon, int count) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.secondaryText.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            const Gap(6),
            Text(
              label,
              style: AppTextStyle.getSmallStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.secondaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyle.getSmallStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    List<dynamic> items = [];

    if (_selectedCategory == 'all') {
      items.addAll(_filteredServices);
      items.addAll(_filteredPlans);
    } else if (_selectedCategory == 'services') {
      items.addAll(_filteredServices);
    } else if (_selectedCategory == 'plans') {
      items.addAll(_filteredPlans);
    }

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item is BookableService) {
              return _buildServiceListItem(item);
            } else if (item is SubscriptionPlan) {
              return _buildPlanListItem(item);
            }
            return const SizedBox.shrink();
          },
          childCount: items.length,
        ),
      ),
    );
  }

  // Premium Empty State
  Widget _buildPremiumEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Icon(
                      _searchQuery.isNotEmpty
                          ? CupertinoIcons.search
                          : CupertinoIcons.cube_box,
                      color: AppColors.lightText.withOpacity(0.6),
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No Results Found'
                  : 'No Items Available',
              style: AppTextStyle.getHeadlineTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
            ),
            const Gap(12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms or browse all categories'
                  : 'This provider hasn\'t added any services or plans yet',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.lightText.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Premium Service Card
  Widget _buildPremiumServiceCard(BookableService service) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _navigateToOptionsConfiguration(context,
                    service: service, provider: widget.provider);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Service Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryColor, AppColors.tealColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.wrench_fill,
                        color: AppColors.lightText,
                        size: 28,
                      ),
                    ),
                    const Gap(16),
                    // Service Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.lightText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.tealColor
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Service',
                                  style: AppTextStyle.getSmallStyle(
                                    fontSize: 10,
                                    color: AppColors.lightText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            service.description,
                            style: AppTextStyle.getbodyStyle(
                              fontSize: 14,
                              color: AppColors.lightText.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              if (service.price != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.money_dollar,
                                        size: 14,
                                        color: AppColors.lightText,
                                      ),
                                      const Gap(4),
                                      Text(
                                        '${service.price!.toStringAsFixed(0)} EGP',
                                        style: AppTextStyle.getSmallStyle(
                                          fontSize: 12,
                                          color: AppColors.lightText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (service.price != null &&
                                  service.durationMinutes != null)
                                const Gap(8),
                              if (service.durationMinutes != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.clock,
                                        size: 14,
                                        color: AppColors.lightText
                                            .withOpacity(0.8),
                                      ),
                                      const Gap(4),
                                      Text(
                                        '${service.durationMinutes} min',
                                        style: AppTextStyle.getSmallStyle(
                                          fontSize: 12,
                                          color: AppColors.lightText
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Arrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.lightText.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Premium Plan Card
  Widget _buildPremiumPlanCard(SubscriptionPlan plan) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _navigateToOptionsConfiguration(context,
                    planData: plan, provider: widget.provider);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Plan Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.electricBlue,
                            AppColors.purpleColor
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.electricBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.doc_text_fill,
                        color: AppColors.lightText,
                        size: 28,
                      ),
                    ),
                    const Gap(16),
                    // Plan Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.lightText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.electricBlue,
                                      AppColors.purpleColor
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Plan',
                                  style: AppTextStyle.getSmallStyle(
                                    fontSize: 10,
                                    color: AppColors.lightText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            plan.description,
                            style: AppTextStyle.getbodyStyle(
                              fontSize: 14,
                              color: AppColors.lightText.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.money_dollar,
                                      size: 14,
                                      color: AppColors.lightText,
                                    ),
                                    const Gap(4),
                                    Text(
                                      '${plan.price.toStringAsFixed(0)} EGP',
                                      style: AppTextStyle.getSmallStyle(
                                        fontSize: 12,
                                        color: AppColors.lightText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.repeat,
                                      size: 14,
                                      color:
                                          AppColors.lightText.withOpacity(0.8),
                                    ),
                                    const Gap(4),
                                    Text(
                                      _getBillingText(plan),
                                      style: AppTextStyle.getSmallStyle(
                                        fontSize: 12,
                                        color: AppColors.lightText
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Arrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.lightText.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceListItem(BookableService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _navigateToOptionsConfiguration(context,
                service: service, provider: widget.provider);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Service Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.wrench,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const Gap(16),
                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Service',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 10,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        service.description,
                        style: AppTextStyle.getSmallStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          if (service.price != null) ...[
                            Icon(
                              CupertinoIcons.money_dollar,
                              size: 14,
                              color: AppColors.primaryColor,
                            ),
                            const Gap(4),
                            Text(
                              '${service.price!.toStringAsFixed(0)} EGP',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (service.price != null &&
                              service.durationMinutes != null)
                            const Gap(16),
                          if (service.durationMinutes != null) ...[
                            Icon(
                              CupertinoIcons.clock,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const Gap(4),
                            Text(
                              '${service.durationMinutes} min',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                // Arrow
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanListItem(SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _navigateToOptionsConfiguration(context,
                planData: plan, provider: widget.provider);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Plan Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    color: AppColors.accentColor,
                    size: 24,
                  ),
                ),
                const Gap(16),
                // Plan Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Plan',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 10,
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        plan.description,
                        style: AppTextStyle.getSmallStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.money_dollar,
                            size: 14,
                            color: AppColors.accentColor,
                          ),
                          const Gap(4),
                          Text(
                            '${plan.price.toStringAsFixed(0)} EGP',
                            style: AppTextStyle.getSmallStyle(
                              fontSize: 12,
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(16),
                          Icon(
                            CupertinoIcons.repeat,
                            size: 14,
                            color: AppColors.secondaryText,
                          ),
                          const Gap(4),
                          Text(
                            _getBillingText(plan),
                            style: AppTextStyle.getSmallStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                // Arrow
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getBillingText(SubscriptionPlan plan) {
    switch (plan.interval) {
      case PricingInterval.day:
        return plan.intervalCount > 1 ? '${plan.intervalCount} days' : 'Daily';
      case PricingInterval.week:
        return plan.intervalCount > 1
            ? '${plan.intervalCount} weeks'
            : 'Weekly';
      case PricingInterval.month:
        return plan.intervalCount > 1
            ? '${plan.intervalCount} months'
            : 'Monthly';
      case PricingInterval.year:
        return plan.intervalCount > 1
            ? '${plan.intervalCount} years'
            : 'Yearly';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondaryText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? CupertinoIcons.search
                  : CupertinoIcons.square_stack_3d_up,
              color: AppColors.secondaryText,
              size: 40,
            ),
          ),
          const Gap(20),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No items available',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const Gap(8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'This provider has no services or plans yet',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBookButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            // Handle quick book action
          },
          borderRadius: BorderRadius.circular(16),
          child: const Icon(
            CupertinoIcons.calendar_badge_plus,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _navigateToOptionsConfiguration(BuildContext context,
      {BookableService? service,
      SubscriptionPlan? planData,
      required ServiceProviderModel provider}) {
    ServiceModel? serviceModelForConfig;
    PlanModel? planModelForConfig;

    if (service != null) {
      serviceModelForConfig =
          _convertBookableServiceToServiceModel(service, provider.id, provider);
    } else if (planData != null) {
      planModelForConfig =
          _convertSubscriptionPlanToPlanModel(planData, provider.id, provider);
    } else {
      showGlobalSnackBar(context, "No item selected for configuration.",
          isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedBookingConfigurationScreen(
          provider: provider,
          plan: planModelForConfig,
          service: serviceModelForConfig,
        ),
      ),
    );
  }

  ServiceModel _convertBookableServiceToServiceModel(
      BookableService bookableService,
      String providerId,
      ServiceProviderModel detailedProvider) {
    Map<String, dynamic> optionsDef =
        Map<String, dynamic>.from(bookableService.configData ?? {});
    final String serviceTypeKey = bookableService.type.typeString;
    final generalTypeConfig =
        detailedProvider.reservationTypeConfigs?[serviceTypeKey];

    if (generalTypeConfig is Map) {
      generalTypeConfig.forEach((key, value) {
        optionsDef.putIfAbsent(key, () => value);
      });
    }

    switch (bookableService.type) {
      case ReservationType.timeBased:
      case ReservationType.seatBased:
      case ReservationType.recurring:
      case ReservationType.group:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('allowTimeSelection', () => true);
        optionsDef.putIfAbsent('timeSelectionType',
            () => optionsDef['timeSelectionType'] ?? 'slots');
        break;
      case ReservationType.serviceBased:
        optionsDef.putIfAbsent('allowDateSelection',
            () => optionsDef['allowDateSelection'] ?? false);
        optionsDef.putIfAbsent('allowTimeSelection',
            () => optionsDef['allowTimeSelection'] ?? false);
        break;
      case ReservationType.accessBased:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('requiresAccessPassSelection', () => true);
        if (detailedProvider.accessOptions != null &&
            detailedProvider.accessOptions!.isNotEmpty) {
          optionsDef.putIfAbsent(
              'definedAccessPasses',
              () => detailedProvider.accessOptions!
                  .map((e) => e.toMap())
                  .toList());
        }
        break;
      case ReservationType.sequenceBased:
        optionsDef.putIfAbsent('allowDateSelection', () => true);
        optionsDef.putIfAbsent('allowTimeSelection', () => true);
        optionsDef.putIfAbsent('timeSelectionType', () => 'preference');
        break;
      default:
        break;
    }

    bool defaultAllowAttendeeSelection =
        bookableService.type == ReservationType.group ||
            (bookableService.capacity ?? 0) > 1;
    int defaultMaxAttendees = bookableService.capacity ??
        (bookableService.type == ReservationType.group ? 10 : 1);

    if (bookableService.capacity != null && bookableService.capacity! > 0) {
      optionsDef.putIfAbsent('allowQuantitySelection', () => true);
      optionsDef.putIfAbsent(
          'quantityDetails',
          () => {
                'min': 1,
                'max': bookableService.capacity,
                'label': bookableService.type == ReservationType.group
                    ? 'Number of People'
                    : 'Quantity'
              });
    } else if (bookableService.type != ReservationType.group) {
      optionsDef.putIfAbsent('allowQuantitySelection', () => false);
    } else if (bookableService.type == ReservationType.group &&
        bookableService.capacity == null) {
      optionsDef.putIfAbsent('allowQuantitySelection', () => true);
      optionsDef.putIfAbsent(
          'quantityDetails',
          () => {
                'min': 1,
                'max': optionsDef['quantityDetails']?['max'] ?? 10,
                'label': 'Number of People'
              });
    }

    optionsDef.putIfAbsent(
        'allowAttendeeSelection', () => defaultAllowAttendeeSelection);
    optionsDef.putIfAbsent(
        'attendeeDetails',
        () => {
              'max': defaultMaxAttendees,
              'min': 1,
            });

    return ServiceModel(
      id: bookableService.id,
      providerId: providerId,
      name: bookableService.name,
      description: bookableService.description,
      price: bookableService.price ?? 0.0,
      priceType: optionsDef['priceType'] as String? ?? 'fixed',
      currency: detailedProvider.address['country'] == 'EG' ? 'EGP' : 'USD',
      estimatedDurationMinutes: bookableService.durationMinutes,
      category: bookableService.type.displayString,
      isActive: true,
      optionsDefinition: optionsDef.isNotEmpty ? optionsDef : null,
    );
  }

  PlanModel _convertSubscriptionPlanToPlanModel(
      SubscriptionPlan subscriptionPlan,
      String providerId,
      ServiceProviderModel detailedProvider) {
    Map<String, dynamic> optionsDef = {};

    optionsDef.putIfAbsent('allowDateSelection', () => true);
    optionsDef.putIfAbsent('customizableNotes',
        () => "Any specific requests for your subscription?");

    String billingCycleDisplay;
    switch (subscriptionPlan.interval) {
      case PricingInterval.day:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} days'
            : 'Daily';
        break;
      case PricingInterval.week:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} weeks'
            : 'Weekly';
        break;
      case PricingInterval.month:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} months'
            : 'Monthly';
        break;
      case PricingInterval.year:
        billingCycleDisplay = subscriptionPlan.intervalCount > 1
            ? '${subscriptionPlan.intervalCount} years'
            : 'Yearly';
        break;
    }

    optionsDef.putIfAbsent('billingCycle', () => billingCycleDisplay);
    optionsDef.putIfAbsent('allowMultipleMonths', () => false);

    return PlanModel(
      id: subscriptionPlan.id,
      providerId: providerId,
      name: subscriptionPlan.name,
      description: subscriptionPlan.description,
      price: subscriptionPlan.price,
      currency: detailedProvider.address['country'] == 'EG' ? 'EGP' : 'USD',
      billingCycle: billingCycleDisplay,
      features: subscriptionPlan.features,
      isActive: true,
      optionsDefinition: optionsDef.isNotEmpty ? optionsDef : null,
    );
  }
}
