import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

// Callback type for when a category is selected
typedef CategorySelectedCallback = void Function(String category);

class ExploreCategoryList extends StatefulWidget {
  final List<String> categories;
  // *** Ensure this parameter is defined ***
  final CategorySelectedCallback onCategorySelected;

  const ExploreCategoryList({
    super.key,
    required this.categories,
    // *** Ensure it's required in the constructor ***
    required this.onCategorySelected,
  });

  @override
  State<ExploreCategoryList> createState() => _ExploreCategoryListState();
}

class _ExploreCategoryListState extends State<ExploreCategoryList> {
  int _selectedIndex = 0; // Track the selected category index ('All' initially)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return SizedBox(
      height: 40, // Consistent height for the list items
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        clipBehavior: Clip.none,
        separatorBuilder: (context, index) => const SizedBox(width: 10), // Spacing between items
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedIndex;
          final categoryName = widget.categories[index];

          // Use theme colors
          final selectedBgColor = theme.colorScheme.primary;
          final selectedFgColor = theme.colorScheme.onPrimary;
          final unselectedBgColor = theme.colorScheme.surface;
          final unselectedFgColor = theme.colorScheme.primary.withOpacity(0.8);
          final unselectedBorderColor = theme.colorScheme.primary.withOpacity(0.3);

          return GestureDetector(
            onTap: () {
              if (_selectedIndex != index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  // *** Call the callback function ***
                  widget.onCategorySelected(categoryName);
                  print("Category tapped: $categoryName");
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : unselectedBgColor,
                border: isSelected ? null : Border.all(color: unselectedBorderColor, width: 1.0),
                borderRadius: BorderRadius.circular(20),
                 boxShadow: isSelected ? [
                    BoxShadow(
                       color: selectedBgColor.withOpacity(0.3),
                       blurRadius: 5,
                       offset: const Offset(0, 2),
                    )
                 ] : [],
              ),
              child: Center(
                child: Text(
                  categoryName,
                  style: getbodyStyle(
                    color: isSelected ? selectedFgColor : unselectedFgColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
