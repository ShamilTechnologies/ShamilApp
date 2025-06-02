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
import 'package:shamil_mobile_app/feature/options_configuration/view/modern_options_configuration_screen.dart';

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
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasServices = false;
  bool _hasPlans = false;
  String _searchQuery = '';
  List<BookableService> _filteredServices = [];
  List<SubscriptionPlan> _filteredPlans = [];
  String _selectedCategory = 'all'; // 'all', 'services', 'plans'
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _hasServices = widget.provider.bookableServices.isNotEmpty;
    _hasPlans = widget.provider.subscriptionPlans.isNotEmpty;
    _filteredServices = widget.provider.bookableServices;
    _filteredPlans = widget.provider.subscriptionPlans;

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _contentFadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeAnimationController.forward();
    });

    _searchController.addListener(_onSearchChanged);
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
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Compact Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: _buildCompactHeader(),
          ),
          // Main Content
          Expanded(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  // Horizontal Categories
                  SliverToBoxAdapter(child: _buildHorizontalCategories()),
                  // Services and Plans List
                  _buildMainContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildQuickBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<SocialBloc>(context)),
            BlocProvider.value(value: BlocProvider.of<AuthBloc>(context)),
          ],
          child: ModernOptionsConfigurationScreen(
            providerId: provider.id,
            plan: planModelForConfig,
            service: serviceModelForConfig,
          ),
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
