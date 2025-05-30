import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;

/// Modern Search Section Widget
class ModernSearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearching;
  final VoidCallback onClearSearch;

  const ModernSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: searchFocusNode.hasFocus
                ? AppColors.primaryColor.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search providers...',
            hintStyle: AppTextStyle.getSmallStyle(
              color: AppColors.secondaryText,
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppColors.secondaryText,
              size: 20,
            ),
            suffixIcon: isSearching
                ? IconButton(
                    onPressed: onClearSearch,
                    icon: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: AppTextStyle.getbodyStyle(
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
