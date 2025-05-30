import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/constants/business_categories.dart';

/// Modern Filter Section Widget
class ModernFilterSection extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedCity;
  final double minRating;
  final bool showFeaturedOnly;
  final Function(String?) onCategoryChanged;
  final Function(String?) onCityChanged;
  final Function(double) onRatingChanged;
  final VoidCallback onFeaturedToggled;
  final VoidCallback onClearFilters;

  const ModernFilterSection({
    super.key,
    required this.selectedCategory,
    required this.selectedCity,
    required this.minRating,
    required this.showFeaturedOnly,
    required this.onCategoryChanged,
    required this.onCityChanged,
    required this.onRatingChanged,
    required this.onFeaturedToggled,
    required this.onClearFilters,
  });

  @override
  State<ModernFilterSection> createState() => _ModernFilterSectionState();
}

class _ModernFilterSectionState extends State<ModernFilterSection> {
  bool _isExpanded = false;

  final List<String> _sampleCities = [
    'Cairo',
    'Alexandria',
    'Giza',
    'Sharm El Sheikh',
    'Hurghada',
    'Luxor',
    'Aswan',
    'Mansoura',
    'Tanta',
    'Suez',
  ];

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = widget.selectedCategory != null ||
        widget.selectedCity != null ||
        widget.minRating > 0 ||
        widget.showFeaturedOnly;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          _buildFilterHeader(hasActiveFilters),
          if (_isExpanded) _buildExpandedFilters(),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(bool hasActiveFilters) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.slider_horizontal_3,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  if (hasActiveFilters)
                    Text(
                      _getActiveFiltersText(),
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (hasActiveFilters)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: widget.onClearFilters,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.redColor.withOpacity(0.1),
                    foregroundColor: AppColors.redColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: AppTextStyle.getSmallStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Icon(
              _isExpanded
                  ? CupertinoIcons.chevron_up
                  : CupertinoIcons.chevron_down,
              color: AppColors.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const Gap(20),
          _buildCategoryFilter(),
          const Gap(20),
          _buildCityFilter(),
          const Gap(20),
          _buildRatingFilter(),
          const Gap(20),
          _buildFeaturedFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyle.getTitleStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'All Categories',
              widget.selectedCategory == null,
              () => widget.onCategoryChanged(null),
            ),
            ...getAllCategoryNames().map((category) => _buildFilterChip(
                  category,
                  widget.selectedCategory == category,
                  () => widget.onCategoryChanged(category),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: AppTextStyle.getTitleStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'All Cities',
              widget.selectedCity == null,
              () => widget.onCityChanged(null),
            ),
            ..._sampleCities.map((city) => _buildFilterChip(
                  city,
                  widget.selectedCity == city,
                  () => widget.onCityChanged(city),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: AppTextStyle.getTitleStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: widget.minRating,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                activeColor: AppColors.primaryColor,
                inactiveColor: AppColors.primaryColor.withOpacity(0.2),
                onChanged: widget.onRatingChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: AppColors.primaryColor,
                    size: 14,
                  ),
                  const Gap(4),
                  Text(
                    widget.minRating.toStringAsFixed(1),
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturedFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.showFeaturedOnly
            ? AppColors.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.showFeaturedOnly
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.showFeaturedOnly
                  ? AppColors.primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.star_fill,
              color: widget.showFeaturedOnly
                  ? AppColors.primaryColor
                  : Colors.grey,
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Only',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  'Show only featured providers',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.showFeaturedOnly,
            onChanged: (_) => widget.onFeaturedToggled(),
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.getSmallStyle(
            color: isSelected ? Colors.white : AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getActiveFiltersText() {
    final List<String> activeFilters = [];

    if (widget.selectedCategory != null) {
      activeFilters.add(widget.selectedCategory!);
    }
    if (widget.selectedCity != null) {
      activeFilters.add(widget.selectedCity!);
    }
    if (widget.minRating > 0) {
      activeFilters.add('${widget.minRating.toStringAsFixed(1)}+ rating');
    }
    if (widget.showFeaturedOnly) {
      activeFilters.add('Featured');
    }

    return activeFilters.join(' • ');
  }
}
