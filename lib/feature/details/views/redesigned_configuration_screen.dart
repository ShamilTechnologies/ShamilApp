import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';

/// Modern full-screen configuration experience
class RedesignedConfigurationScreen extends StatefulWidget {
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;

  const RedesignedConfigurationScreen({
    super.key,
    required this.provider,
    this.service,
    this.plan,
  }) : assert(service != null || plan != null,
            'Either service or plan must be provided');

  @override
  State<RedesignedConfigurationScreen> createState() =>
      _RedesignedConfigurationScreenState();
}

class _RedesignedConfigurationScreenState
    extends State<RedesignedConfigurationScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Configuration data
  DateTime? _selectedDate;
  String? _selectedTime;
  int _quantity = 1;
  String _notes = '';
  Map<String, bool> _selectedAddOns = {};
  Map<String, bool> _preferences = {
    'notifications': true,
    'reminders': true,
    'calendar': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutQuart,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_contentAnimation);
  }

  void _startAnimations() {
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpaceNavy,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(color: AppColors.deepSpaceNavy),
        child: Stack(
          children: [
            _buildAmbientBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.2),
                    AppColors.primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.tealColor.withOpacity(0.15),
                    AppColors.tealColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _heroAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentStep = index),
                    children: [
                      _buildServiceDetailsStep(),
                      _buildDateTimeStep(),
                      _buildOptionsStep(),
                      _buildConfirmationStep(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          _buildBackButton(),
          const Gap(16),
          Expanded(child: _buildHeaderInfo()),
          _buildPriceDisplay(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildHeaderInfo() {
    final itemName = widget.service?.name ?? widget.plan?.name ?? 'Service';
    final itemType =
        widget.service != null ? 'Service Booking' : 'Subscription Plan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          itemName,
          style: AppTextStyle.getHeadlineTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(4),
        Text(
          itemType,
          style: AppTextStyle.getSmallStyle(
            color: AppColors.lightText.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    final price = widget.service?.price ?? widget.plan?.price ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.tealColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total',
            style: AppTextStyle.getSmallStyle(
              color: AppColors.lightText.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'EGP ${price.toStringAsFixed(0)}',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                gradient: isCompleted || isActive
                    ? LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.tealColor],
                      )
                    : null,
                color: isCompleted || isActive
                    ? null
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServiceDetailsStep() {
    return _buildStepContainer(
      title: 'Service Details',
      subtitle: 'Review what you\'re booking',
      child: Column(
        children: [
          _buildServiceCard(),
          const Gap(24),
          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return _buildStepContainer(
      title: 'Date & Time',
      subtitle: 'Choose your preferred schedule',
      child: Column(
        children: [
          _buildDateSelector(),
          const Gap(20),
          _buildTimeSelector(),
          const Gap(20),
          _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildOptionsStep() {
    return _buildStepContainer(
      title: 'Options & Preferences',
      subtitle: 'Customize your experience',
      child: Column(
        children: [
          _buildNotesSection(),
          const Gap(24),
          _buildAddOnsSection(),
          const Gap(24),
          _buildPreferencesSection(),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return _buildStepContainer(
      title: 'Confirmation',
      subtitle: 'Review and confirm your booking',
      child: Column(
        children: [
          _buildSummaryCard(),
          const Gap(24),
          _buildTermsSection(),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.getHeadlineTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.lightText,
            ),
          ),
          const Gap(8),
          Text(
            subtitle,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const Gap(32),
          Expanded(
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    final itemName = widget.service?.name ?? widget.plan?.name ?? 'Service';
    final itemDescription =
        widget.service?.description ?? widget.plan?.description ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.tealColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    widget.service != null
                        ? CupertinoIcons.calendar_badge_plus
                        : CupertinoIcons.creditcard_fill,
                    color: AppColors.lightText,
                    size: 24,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: AppTextStyle.getHeadlineTextStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      widget.service != null
                          ? 'One-time Service'
                          : 'Monthly Subscription',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.lightText.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (itemDescription.isNotEmpty) ...[
            const Gap(16),
            Text(
              itemDescription,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.lightText.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    // Mock features - in real app, get from service/plan
    final features = [
      'Professional service delivery',
      'Expert consultation included',
      'Flexible scheduling options',
      'Customer support',
      'Quality guarantee',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s Included',
          style: AppTextStyle.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(16),
        ...features.map((feature) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.greenColor, AppColors.tealColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.check_mark,
                        color: AppColors.lightText,
                        size: 12,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          InkWell(
            onTap: () => _selectDate(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    color: AppColors.lightText,
                    size: 20,
                  ),
                  const Gap(12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Choose a date',
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    final timeSlots = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((time) {
              final isSelected = _selectedTime == time;
              return InkWell(
                onTap: () => setState(() => _selectedTime = time),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.tealColor
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    time,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(
            'Quantity',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildQuantityButton(
                icon: CupertinoIcons.minus,
                onTap: () =>
                    setState(() => _quantity = (_quantity - 1).clamp(1, 10)),
              ),
              const Gap(16),
              Text(
                _quantity.toString(),
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(16),
              _buildQuantityButton(
                icon: CupertinoIcons.plus,
                onTap: () =>
                    setState(() => _quantity = (_quantity + 1).clamp(1, 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.tealColor],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(icon, color: AppColors.lightText, size: 18),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          TextField(
            maxLines: 3,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Any special requests or preferences...',
              hintStyle: AppTextStyle.getbodyStyle(
                color: AppColors.lightText.withOpacity(0.6),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsSection() {
    // Mock add-ons - in real app, get from service/plan
    final addOns = [
      {'id': 'premium', 'name': 'Premium Package', 'price': 50.0},
      {'id': 'express', 'name': 'Express Service', 'price': 25.0},
      {'id': 'warranty', 'name': 'Extended Warranty', 'price': 30.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add-ons',
          style: AppTextStyle.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        ...addOns.map((addOn) {
          final id = addOn['id'] as String;
          final isSelected = _selectedAddOns[id] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedAddOns[id] = !isSelected),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.tealColor
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                CupertinoIcons.check_mark,
                                color: AppColors.lightText,
                                size: 12,
                              ),
                            )
                          : null,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        addOn['name'] as String,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.lightText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '+EGP ${(addOn['price'] as double).toStringAsFixed(0)}',
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: AppTextStyle.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        ..._preferences.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;
          final titles = {
            'notifications': 'Notifications',
            'reminders': 'Reminders',
            'calendar': 'Calendar Sync',
          };

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titles[key] ?? key,
                    style: AppTextStyle.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                CupertinoSwitch(
                  value: value,
                  activeColor: AppColors.primaryColor,
                  onChanged: (newValue) {
                    setState(() => _preferences[key] = newValue);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final itemName = widget.service?.name ?? widget.plan?.name ?? 'Service';
    final basePrice = widget.service?.price ?? widget.plan?.price ?? 0.0;
    final addOnsPrice = _selectedAddOns.entries
        .where((entry) => entry.value)
        .fold(0.0, (sum, entry) => sum + 25.0); // Mock pricing
    final totalPrice = (basePrice + addOnsPrice) * _quantity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: AppTextStyle.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          _buildSummaryRow('Service', itemName),
          _buildSummaryRow(
              'Date',
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Not selected'),
          _buildSummaryRow('Time', _selectedTime ?? 'Not selected'),
          _buildSummaryRow('Quantity', _quantity.toString()),
          if (_notes.isNotEmpty) _buildSummaryRow('Notes', _notes),
          const Gap(12),
          Divider(color: Colors.white.withOpacity(0.2)),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'EGP ${totalPrice.toStringAsFixed(0)}',
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.lightText.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.lightText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text_fill,
                color: AppColors.lightText.withOpacity(0.8),
                size: 18,
              ),
              const Gap(8),
              Text(
                'Terms & Conditions',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'By proceeding, you agree to our terms of service and privacy policy. Cancellations must be made 24 hours in advance.',
            style: AppTextStyle.getSmallStyle(
              color: AppColors.lightText.withOpacity(0.7),
              fontSize: 12,
            ).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceedToNextStep();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.deepSpaceNavy.withOpacity(0.9),
            AppColors.deepSpaceNavy,
          ],
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: _buildNavButton(
                text: 'Back',
                isPrimary: false,
                onTap: () => _previousStep(),
              ),
            ),
          if (_currentStep > 0) const Gap(16),
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: _buildNavButton(
              text: isLastStep ? 'Confirm Booking' : 'Continue',
              isPrimary: true,
              enabled: canProceed,
              onTap: canProceed ? () => _nextStep() : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String text,
    required bool isPrimary,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary && enabled
            ? LinearGradient(
                colors: [AppColors.primaryColor, AppColors.tealColor],
              )
            : null,
        color: isPrimary && enabled
            ? null
            : enabled
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(enabled ? 0.2 : 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: AppTextStyle.getButtonStyle(
                color: enabled
                    ? AppColors.lightText
                    : AppColors.lightText.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: // Service details - always can proceed
        return true;
      case 1: // Date & Time
        return _selectedDate != null && _selectedTime != null;
      case 2: // Options - always can proceed
        return true;
      case 3: // Confirmation - always can proceed
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _confirmBooking() {
    HapticFeedback.mediumImpact();
    // TODO: Implement actual booking logic
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking confirmed successfully!'),
        backgroundColor: AppColors.greenColor,
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      HapticFeedback.lightImpact();
    }
  }
}
