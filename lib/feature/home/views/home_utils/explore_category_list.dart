import 'package:flutter/material.dart';
// *** Import the centralized icon constants and helpers ***
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // Ensure this path is correct
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Import AppColors

// Callback type for when a category is selected
typedef CategorySelectedCallback = void Function(String category);

class ExploreCategoryList extends StatefulWidget {
  // *** REMOVED categories parameter ***
  // final List<String> categories;
  final CategorySelectedCallback onCategorySelected;
  // *** ADDED optional initialCategory parameter ***
  final String? initialCategory; // Optional: Specify which category is selected initially

  const ExploreCategoryList({
    super.key,
    // required this.categories, // REMOVED
    required this.onCategorySelected,
    this.initialCategory, // Optional initial selection
  });

  @override
  State<ExploreCategoryList> createState() => _ExploreCategoryListState();
}

class _ExploreCategoryListState extends State<ExploreCategoryList> {
  // Get the category list directly from the map keys, excluding '_default'
  // Add "All" category at the beginning for user convenience
  final List<String> _displayCategories = [
    'All', // Add the 'All' option
    ...kBusinessCategoryIcons.keys.where((key) => key != '_default').toList()
  ];

  int _selectedIndex = 0; // Initialize selected index

  @override
  void initState() {
    super.initState();
    // Set initial selection based on initialCategory parameter or default to 'All'
    int initialIndex = 0; // Default to 'All'
    if (widget.initialCategory != null) {
      initialIndex = _displayCategories.indexOf(widget.initialCategory!);
      // If initialCategory isn't found (or is '_default'), default to 'All' (index 0)
      if (initialIndex == -1) {
        initialIndex = 0;
      }
    }
     _selectedIndex = initialIndex;

     // Optionally call the callback initially if needed
     // widget.onCategorySelected(_displayCategories[_selectedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    // Handle empty categories list gracefully (shouldn't happen with 'All' added)
    if (_displayCategories.isEmpty) {
      return const SizedBox(height: 40);
    }

    return SizedBox(
      height: 40, // Consistent height for the list items
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _displayCategories.length, // Use the internal list length
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 10), // Spacing between items
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedIndex;
          final categoryName = _displayCategories[index]; // Use the internal list
          // Use Imported Helper Function to get icon (handles '_default' and 'All')
          final IconData icon = getIconForCategory(categoryName);

          // Define selected/unselected colors using AppColors or theme
          final selectedBgColor = AppColors.primaryColor;
          final selectedFgColor = AppColors.white;
          final unselectedBgColor = AppColors.primaryColor.withOpacity(0.1);
          final unselectedFgColor = AppColors.primaryColor.withOpacity(0.8);

          return GestureDetector(
            onTap: () {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
                // Pass the actual category name, or handle 'All' specifically if needed
                widget.onCategorySelected(categoryName);
                print("Category tapped: $categoryName");
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : unselectedBgColor,
                border: null,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedBgColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? selectedFgColor : unselectedFgColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    categoryName, // Display the category name
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected ? selectedFgColor : unselectedFgColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
