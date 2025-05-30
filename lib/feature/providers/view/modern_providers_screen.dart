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

/// Modern Service Providers Screen
///
/// Features:
/// - Search functionality with real-time results
/// - Advanced filtering by category, city, and rating
/// - Modern card-based layout matching configuration screen
/// - Pull-to-refresh functionality
/// - Empty states and error handling
/// - Favorites integration
/// - Statistics display
/// - Clean structured code architecture
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
    with SingleTickerProviderStateMixin {
  // Data
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

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
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
    _initializeAnimation();
    _initializeFilters();
    _loadProviders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
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
    setState(() {
      _isRefreshing = true;
    });

    await _loadProviders();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    _applyFilters();

    // Reload if search query changed significantly
    if (query.length >= 3 || query.isEmpty) {
      _loadProviders();
    }
  }

  void _applyFilters() {
    List<ServiceProviderDisplayModel> filtered = List.from(_allProviders);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((provider) {
        return provider.businessName.toLowerCase().contains(queryLower) ||
            provider.businessCategory.toLowerCase().contains(queryLower) ||
            (provider.shortDescription?.toLowerCase().contains(queryLower) ??
                false);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((provider) => provider.businessCategory == _selectedCategory)
          .toList();
    }

    // City filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered =
          filtered.where((provider) => provider.city == _selectedCity).toList();
    }

    // Rating filter
    if (_minRating > 0) {
      filtered = filtered
          .where((provider) => provider.averageRating >= _minRating)
          .toList();
    }

    // Featured filter
    if (_showFeaturedOnly) {
      filtered = filtered.where((provider) => provider.isFeatured).toList();
    }

    // Sort by rating and then by name
    filtered.sort((a, b) {
      final ratingComparison = b.averageRating.compareTo(a.averageRating);
      if (ratingComparison != 0) return ratingComparison;
      return a.businessName.compareTo(b.businessName);
    });

    setState(() {
      _filteredProviders = filtered;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _updateCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
    _loadProviders();
  }

  void _updateCityFilter(String? city) {
    setState(() {
      _selectedCity = city;
    });
    _applyFilters();
    _loadProviders();
  }

  void _updateRatingFilter(double rating) {
    setState(() {
      _minRating = rating;
    });
    _applyFilters();
  }

  void _toggleFeaturedFilter() {
    setState(() {
      _showFeaturedOnly = !_showFeaturedOnly;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(),
            _buildSearchSection(),
            _buildFilterSection(),
            _buildStatisticsSection(),
            _buildProvidersGrid(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Service Providers',
          style: AppTextStyle.getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(40),
                  Text(
                    'Discover & Connect',
                    style: AppTextStyle.getSmallStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const Gap(4),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _refreshProviders,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(CupertinoIcons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: ModernSearchSection(
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        isSearching: _isSearching,
        onClearSearch: _clearSearch,
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: ModernFilterSection(
        selectedCategory: _selectedCategory,
        selectedCity: _selectedCity,
        minRating: _minRating,
        showFeaturedOnly: _showFeaturedOnly,
        onCategoryChanged: _updateCategoryFilter,
        onCityChanged: _updateCityFilter,
        onRatingChanged: _updateRatingFilter,
        onFeaturedToggled: _toggleFeaturedFilter,
        onClearFilters: _clearAllFilters,
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_isLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                _totalProviders.toString(),
                CupertinoIcons.building_2_fill,
                AppColors.primaryColor,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Showing',
                _filteredCount.toString(),
                CupertinoIcons.eye_fill,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Featured',
                _featuredCount.toString(),
                CupertinoIcons.star_fill,
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Avg Rating',
                _averageRating.toStringAsFixed(1),
                CupertinoIcons.heart_fill,
                Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const Gap(8),
        Text(
          value,
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        Text(
          label,
          style: AppTextStyle.getSmallStyle(
            fontSize: 11,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildProvidersGrid() {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLoadingCard(),
            childCount: 6,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: _buildErrorState(),
      );
    }

    if (_filteredProviders.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final provider = _filteredProviders[index];
            return ModernProviderCard(
              provider: provider,
              onTap: () => _navigateToProviderDetail(provider),
              animationDelay: Duration(milliseconds: index * 100),
            );
          },
          childCount: _filteredProviders.length,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
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
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
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
                    color: Colors.grey[300],
                  ),
                  const Gap(8),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                  const Gap(8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.red,
                size: 48,
              ),
            ),
            const Gap(20),
            Text(
              'Something went wrong',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const Gap(8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: _loadProviders,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters = _selectedCategory != null ||
        _selectedCity != null ||
        _minRating > 0 ||
        _showFeaturedOnly ||
        _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveFilters
                    ? CupertinoIcons.search
                    : CupertinoIcons.building_2_fill,
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            const Gap(20),
            Text(
              hasActiveFilters ? 'No matching providers' : 'No providers found',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const Gap(8),
            Text(
              hasActiveFilters
                  ? 'Try adjusting your search or filters'
                  : 'Check back later for new providers',
              textAlign: TextAlign.center,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
              ),
            ),
            if (hasActiveFilters) ...[
              const Gap(24),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(CupertinoIcons.clear),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToProviderDetail(ServiceProviderDisplayModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: BlocProvider.of<FavoritesBloc>(context),
          child: ServiceProviderDetailScreen(
            providerId: provider.id,
            heroTag: 'provider_${provider.id}',
            initialProviderData: provider,
          ),
        ),
      ),
    );
  }
}
