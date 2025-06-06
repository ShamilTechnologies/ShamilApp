import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';
import 'package:shamil_mobile_app/feature/details/views/service_provider_detail_screen.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/providers/view/widgets/modern_provider_card.dart';
import 'package:shamil_mobile_app/feature/providers/view/widgets/modern_filter_section.dart';
import 'package:shamil_mobile_app/feature/providers/view/widgets/modern_search_section.dart';

/// Modern Service Providers Screen - Redesigned with Dark-First UI/UX
///
/// Features new design system:
/// - Dark-first premium experience with gradient backgrounds
/// - Glassmorphism cards and elements
/// - Floating orbs for ambient depth
/// - White text on dark backgrounds
/// - Modern search and filter functionality
/// - Premium animations and interactions
/// - Clean, maintainable code architecture
class ModernProvidersScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCity;
  final String? initialSearchQuery;

  const ModernProvidersScreen({
    super.key,
    this.initialCategory,
    this.initialCity,
    this.initialSearchQuery,
  });

  @override
  State<ModernProvidersScreen> createState() => _ModernProvidersScreenState();
}

class _ModernProvidersScreenState extends State<ModernProvidersScreen>
    with TickerProviderStateMixin {
  // Data Management
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();
  List<ServiceProviderDisplayModel> _allProviders = [];
  List<ServiceProviderDisplayModel> _filteredProviders = [];

  // UI State
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  // Filters
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCity;
  double _minRating = 0.0;
  bool _showFeaturedOnly = false;

  // Controllers & Animations
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Statistics
  int get _totalProviders => _allProviders.length;
  int get _filteredCount => _filteredProviders.length;
  int get _featuredCount => _allProviders.where((p) => p.isFeatured).length;
  double get _averageRating => _allProviders.isEmpty
      ? 0.0
      : _allProviders.map((p) => p.averageRating).reduce((a, b) => a + b) /
          _allProviders.length;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFilters();
    _loadProviders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  void _initializeFilters() {
    _searchQuery = widget.initialSearchQuery ?? '';
    _selectedCategory = widget.initialCategory;
    _selectedCity = widget.initialCity;
    if (_searchQuery.isNotEmpty) {
      _searchController.text = _searchQuery;
      _isSearching = true;
    }
  }

  Future<void> _loadProviders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<ServiceProviderDisplayModel> providers;

      if (_searchQuery.isNotEmpty) {
        providers = await _dataOrchestrator.getServiceProvidersByQuery(
          query: _searchQuery,
          city: _selectedCity,
          category: _selectedCategory,
        );
      } else if (_selectedCategory != null) {
        providers = await _dataOrchestrator.getServiceProvidersByCategory(
          _selectedCategory!,
          _selectedCity,
          null,
        );
      } else {
        providers = await _dataOrchestrator.getServiceProviders(
          city: _selectedCity,
          category: _selectedCategory,
          limit: 100,
        );
      }

      _allProviders = providers;
      _applyFilters();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load providers: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProviders() async {
    setState(() => _isRefreshing = true);
    await _loadProviders();
    setState(() => _isRefreshing = false);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    _applyFilters();

    if (query.length >= 3 || query.isEmpty) {
      _loadProviders();
    }
  }

  void _applyFilters() {
    List<ServiceProviderDisplayModel> filtered = List.from(_allProviders);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((provider) {
        return provider.businessName.toLowerCase().contains(queryLower) ||
            provider.businessCategory.toLowerCase().contains(queryLower) ||
            (provider.shortDescription?.toLowerCase().contains(queryLower) ??
                false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((provider) => provider.businessCategory == _selectedCategory)
          .toList();
    }

    // Apply city filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered =
          filtered.where((provider) => provider.city == _selectedCity).toList();
    }

    // Apply rating filter
    if (_minRating > 0) {
      filtered = filtered
          .where((provider) => provider.averageRating >= _minRating)
          .toList();
    }

    // Apply featured filter
    if (_showFeaturedOnly) {
      filtered = filtered.where((provider) => provider.isFeatured).toList();
    }

    // Sort by rating and name
    filtered.sort((a, b) {
      final ratingComparison = b.averageRating.compareTo(a.averageRating);
      if (ratingComparison != 0) return ratingComparison;
      return a.businessName.compareTo(b.businessName);
    });

    setState(() {
      _filteredProviders = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: Stack(
          children: [
            // Floating orbs for ambient depth
            ..._buildFloatingOrbs(topPadding),

            // Main content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildPremiumSliverAppBar(topPadding, screenWidth),
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMainContent(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingOrbs(double topPadding) {
    return [
      // Large teal orb
      Positioned(
        top: topPadding + 60,
        right: -80,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.tealOrbGradient,
          ),
        ),
      ),
      // Medium light blue orb
      Positioned(
        top: topPadding + 140,
        left: -60,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.lightBlueOrbGradient,
          ),
        ),
      ),
      // Small accent orb
      Positioned(
        top: topPadding + 200,
        right: 40,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.electricBlue.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  SliverAppBar _buildPremiumSliverAppBar(
      double topPadding, double screenWidth) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.heroSectionGradient,
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(20),
                    _buildHeaderContent(),
                    const Spacer(),
                    _buildQuickStats(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            gradient: AppColors.glassmorphismCardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.glassmorphismBorder,
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _refreshProviders,
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.lightText,
                      ),
                    ),
                  )
                : Icon(
                    CupertinoIcons.refresh,
                    color: AppColors.lightText,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.glassmorphismCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.glassmorphismBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealColor, AppColors.electricBlue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.building_2_fill,
                  color: AppColors.lightText,
                  size: 12,
                ),
              ),
              const Gap(8),
              Text(
                'Service Providers',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.primaryTextEmphasis,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Main title with gradient text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.lightText,
              AppColors.tealColor,
              AppColors.electricBlue,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'Discover &\nConnect',
            style: TextStyle(
              color: AppColors.lightText,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.glassmorphismCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassmorphismBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildQuickStat('Total', _totalProviders.toString()),
          const Gap(16),
          _buildQuickStat('Showing', _filteredCount.toString()),
          const Gap(16),
          _buildQuickStat('Featured', _featuredCount.toString()),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyle.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.primaryTextSubtle,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: AppColors.deepSpaceNavy,
      child: Column(
        children: [
          const Gap(24),
          _buildModernSearchSection(),
          const Gap(20),
          _buildFilterSection(),
          const Gap(20),
          _buildProvidersContent(),
          const Gap(40),
        ],
      ),
    );
  }

  Widget _buildModernSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: AppColors.glassmorphismDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              hintText: 'Search providers...',
              hintStyle: AppTextStyle.getbodyStyle(
                color: AppColors.primaryTextSubtle,
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.tealColor, AppColors.electricBlue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.lightText,
                  size: 20,
                ),
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.primaryTextSubtle,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'All Categories',
              _selectedCategory == null,
              () => _updateCategoryFilter(null),
            ),
            const Gap(12),
            _buildFilterChip(
              'Healthcare',
              _selectedCategory == 'Healthcare',
              () => _updateCategoryFilter('Healthcare'),
            ),
            const Gap(12),
            _buildFilterChip(
              'Beauty',
              _selectedCategory == 'Beauty',
              () => _updateCategoryFilter('Beauty'),
            ),
            const Gap(12),
            _buildFilterChip(
              'Fitness',
              _selectedCategory == 'Fitness',
              () => _updateCategoryFilter('Fitness'),
            ),
            const Gap(12),
            _buildFilterChip(
              'Featured',
              _showFeaturedOnly,
              () => _toggleFeaturedFilter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.tealColor, AppColors.electricBlue],
                )
              : AppColors.glassmorphismCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : AppColors.glassmorphismBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.lightText,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProvidersContent() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredProviders.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _filteredProviders.length,
        itemBuilder: (context, index) {
          final provider = _filteredProviders[index];
          return _buildProviderCard(provider, index);
        },
      ),
    );
  }

  Widget _buildProviderCard(ServiceProviderDisplayModel provider, int index) {
    return GestureDetector(
      onTap: () => _navigateToProviderDetail(provider),
      child: Container(
        decoration: AppColors.glassmorphismDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.getCategoryGradient(
                      provider.businessCategory,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (provider.imageUrl != null &&
                          provider.imageUrl!.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            provider.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultImage(provider),
                          ),
                        )
                      else
                        _buildDefaultImage(provider),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Featured badge
                      if (provider.isFeatured)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.yellowColor,
                                  AppColors.orangeColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Featured',
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.lightText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.businessName,
                          style: AppTextStyle.getTitleStyle(
                            color: AppColors.lightText,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Text(
                          provider.businessCategory,
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.tealColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  color: AppColors.yellowColor,
                                  size: 14,
                                ),
                                const Gap(4),
                                Text(
                                  provider.averageRating.toStringAsFixed(1),
                                  style: AppTextStyle.getSmallStyle(
                                    color: AppColors.lightText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              CupertinoIcons.arrow_right_circle,
                              color: AppColors.primaryTextSubtle,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildDefaultImage(ServiceProviderDisplayModel provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getCategoryGradient(provider.businessCategory),
      ),
      child: Center(
        child: Text(
          provider.businessName.isNotEmpty
              ? provider.businessName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildLoadingCard(),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: AppColors.glassmorphismDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryTextSubtle,
                      AppColors.primaryTextHint,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTextHint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Gap(8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTextHint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: AppColors.glassmorphismDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.dangerColor.withOpacity(0.3),
                  AppColors.dangerColor.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.dangerColor,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'Something went wrong',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const Gap(8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.primaryTextSubtle,
            ),
          ),
          const Gap(24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealColor, AppColors.electricBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _loadProviders,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.lightText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: AppColors.glassmorphismDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.tealOrbGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.search,
              color: AppColors.lightText,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'No providers found',
            style: AppTextStyle.getTitleStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
          const Gap(8),
          Text(
            'Try adjusting your search criteria or filters',
            textAlign: TextAlign.center,
            style: AppTextStyle.getSmallStyle(
              color: AppColors.primaryTextSubtle,
            ),
          ),
          const Gap(24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealColor, AppColors.electricBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.lightText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  void _updateCategoryFilter(String? category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
    _loadProviders();
  }

  void _toggleFeaturedFilter() {
    setState(() => _showFeaturedOnly = !_showFeaturedOnly);
    _applyFilters();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCity = null;
      _minRating = 0.0;
      _showFeaturedOnly = false;
      _searchQuery = '';
    });
    _searchController.clear();
    _applyFilters();
    _loadProviders();
  }

  void _navigateToProviderDetail(ServiceProviderDisplayModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderDetailScreen(
          providerId: provider.id,
          heroTag: 'provider_card_${provider.id}',
          initialProviderData: provider,
        ),
      ),
    );
  }
}
