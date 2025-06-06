import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/bookable_service.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';

/// Provider Services Selector for Enhanced Booking Flow
class ProviderServicesSelector extends StatefulWidget {
  final ServiceProviderModel provider;
  final ServiceModel? selectedService;
  final PlanModel? selectedPlan;
  final Function(ServiceModel?) onServiceSelected;
  final Function(PlanModel?) onPlanSelected;

  const ProviderServicesSelector({
    super.key,
    required this.provider,
    this.selectedService,
    this.selectedPlan,
    required this.onServiceSelected,
    required this.onPlanSelected,
  });

  @override
  State<ProviderServicesSelector> createState() =>
      _ProviderServicesSelectorState();
}

class _ProviderServicesSelectorState extends State<ProviderServicesSelector>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedTab = 'services'; // 'services' or 'plans'
  final TextEditingController _searchController = TextEditingController();
  List<BookableService> _filteredServices = [];
  List<SubscriptionPlan> _filteredPlans = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  void _setupInitialData() {
    _filteredServices = widget.provider.bookableServices;
    _filteredPlans = widget.provider.subscriptionPlans;

    // Auto-select services tab if provider has services, otherwise plans
    _selectedTab =
        widget.provider.bookableServices.isNotEmpty ? 'services' : 'plans';
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredServices = widget.provider.bookableServices.where((service) {
        return service.name.toLowerCase().contains(query) ||
            service.description.toLowerCase().contains(query);
      }).toList();

      _filteredPlans = widget.provider.subscriptionPlans.where((plan) {
        return plan.name.toLowerCase().contains(query) ||
            plan.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTabSelector(),
              _buildSelectedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.tealColor],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.bag_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Service',
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Choose from ${widget.provider.businessName}\'s offerings',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: app_text_style.getbodyStyle(
            color: AppColors.lightText,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search services and plans...',
            hintStyle: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppColors.lightText.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabButton(
              'services',
              'Services',
              widget.provider.bookableServices.length,
              CupertinoIcons.wrench,
            ),
            _buildTabButton(
              'plans',
              'Plans',
              widget.provider.subscriptionPlans.length,
              CupertinoIcons.calendar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tab, String title, int count, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTab = tab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.tealColor],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : AppColors.lightText.withValues(alpha: 0.7),
                size: 16,
              ),
              const Gap(6),
              Text(
                title,
                style: app_text_style.getbodyStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (count > 0) ...[
                const Gap(4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.lightText.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: app_text_style.getbodyStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.lightText.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child:
          _selectedTab == 'services' ? _buildServicesList() : _buildPlansList(),
    );
  }

  Widget _buildServicesList() {
    if (_filteredServices.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.wrench,
        title: 'No Services Found',
        subtitle: _searchController.text.isEmpty
            ? 'This provider hasn\'t added any services yet'
            : 'No services match your search',
      );
    }

    return Column(
      children: _filteredServices.map((service) {
        return _buildServiceCard(service);
      }).toList(),
    );
  }

  Widget _buildPlansList() {
    if (_filteredPlans.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.calendar,
        title: 'No Plans Found',
        subtitle: _searchController.text.isEmpty
            ? 'This provider hasn\'t added any subscription plans yet'
            : 'No plans match your search',
      );
    }

    return Column(
      children: _filteredPlans.map((plan) {
        return _buildPlanCard(plan);
      }).toList(),
    );
  }

  Widget _buildServiceCard(BookableService service) {
    // Convert BookableService to ServiceModel for selection
    final serviceModel = ServiceModel(
      id: service.id,
      name: service.name,
      description: service.description,
      price: service.price ?? 0.0,
      priceType: 'fixed',
      providerId: widget.provider.id,
      category: 'General',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final isSelected = widget.selectedService?.id == serviceModel.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onServiceSelected(isSelected ? null : serviceModel);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.2),
                    AppColors.tealColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.wrench,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: app_text_style.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      service.description,
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    if (service.price != null) ...[
                      const Gap(6),
                      Text(
                        '\$${service.price!.toStringAsFixed(0)}',
                        style: app_text_style.getTitleStyle(
                          color: AppColors.greenColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    // Convert SubscriptionPlan to PlanModel for selection
    final planModel = PlanModel(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      price: plan.price,
      billingCycle: plan.interval.name,
      providerId: widget.provider.id,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final isSelected = widget.selectedPlan?.id == planModel.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPlanSelected(isSelected ? null : planModel);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.tealColor.withValues(alpha: 0.2),
                    AppColors.cyanColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.tealColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.tealColor
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: isSelected
                      ? Colors.white
                      : AppColors.lightText.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: app_text_style.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      plan.description,
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(0)}',
                          style: app_text_style.getTitleStyle(
                            color: AppColors.greenColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/${plan.interval.name}',
                          style: app_text_style.getbodyStyle(
                            color: AppColors.lightText.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.tealColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.lightText.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const Gap(16),
          Text(
            title,
            style: app_text_style.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
