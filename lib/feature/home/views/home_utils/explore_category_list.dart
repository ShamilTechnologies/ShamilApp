// lib/feature/home/views/home_utils/explore_category_list.dart
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // For category icons
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors

// Callback type definition
typedef CategorySelectedCallback = void Function(String category);

/// A horizontal list widget to display selectable category or sub-category chips.
///
/// This widget takes a list of category names, highlights the selected one,
/// and calls a callback function when a different category is tapped.
/// It can optionally hide icons when displaying sub-categories.
class ExploreCategoryList extends StatefulWidget {
  /// The list of category or sub-category names to display.
  final List<String> categories;

  /// Callback function triggered when a category chip is tapped.
  final CategorySelectedCallback onCategorySelected;

  /// The initially selected category name. If null or not found, defaults to the first item.
  final String? initialCategory;

  /// Flag to indicate if this list represents sub-categories (affects icon display).
  final bool isSubCategoryList;

  const ExploreCategoryList({
    super.key,
    required this.categories,
    required this.onCategorySelected,
    this.initialCategory,
    this.isSubCategoryList = false, // Default to false (main categories show icons)
  });

  @override
  State<ExploreCategoryList> createState() => _ExploreCategoryListState();
}

class _ExploreCategoryListState extends State<ExploreCategoryList> {
  // Internal state to track the index of the currently selected chip.
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set the initial selection based on the provided initialCategory.
    _updateSelection();
  }

  @override
  void didUpdateWidget(covariant ExploreCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial category or the list itself changes, update the selection.
    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.categories != oldWidget.categories) {
      _updateSelection();
    }
  }

  /// Updates the internal `_selectedIndex` based on `widget.initialCategory`.
  void _updateSelection() {
    int newIndex = 0; // Default to the first item (usually "All")
    if (widget.initialCategory != null && widget.categories.isNotEmpty) {
      newIndex = widget.categories.indexOf(widget.initialCategory!);
      // If the initialCategory is not found in the list, default back to the first item.
      if (newIndex == -1) {
        newIndex = 0;
      }
    }
    // Only call setState if the widget is mounted and the index actually changed.
    if (mounted && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    } else if (!mounted) {
      // If called before mount (e.g., during initState indirectly), just set the value.
      _selectedIndex = newIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If no categories are provided, render an empty container with fixed height.
    if (widget.categories.isEmpty) {
      return const SizedBox(height: 40); // Maintain consistent height
    }

    // Build the horizontal list view for category chips.
    return SizedBox(
      height: 40, // Fixed height for the list container
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // iOS-like scroll physics
        itemCount: widget.categories.length,
        // Padding for the entire list (optional, adjust if needed)
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        clipBehavior: Clip.none, // Allow shadows/effects outside bounds
        separatorBuilder: (context, index) =>
            const SizedBox(width: 10), // Space between chips
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedIndex;
          final categoryName = widget.categories[index];

          // Determine if an icon should be shown for this chip.
          IconData? icon; // Make icon nullable
          // Show icon if it's the main category list OR if it's the "All" item in a sub-category list.
          bool showIcon = !widget.isSubCategoryList || categoryName.toLowerCase() == "all";
          if (showIcon) {
            // Fetch the icon using the helper function.
            icon = getIconForCategory(categoryName);
            // Optionally assign a specific icon for "All".
            if (categoryName.toLowerCase() == "all" && icon == kBusinessCategoryIcons['_default']) {
                icon = Icons.list_rounded; // Example specific icon for "All"
            }
          }

          // Define colors based on selection state.
          const selectedBgColor = AppColors.primaryColor;
          const selectedFgColor = AppColors.white;
          final unselectedBgColor = AppColors.primaryColor.withOpacity(0.1);
          final unselectedFgColor = AppColors.primaryColor.withOpacity(0.8);

          // Build the individual category chip.
          return GestureDetector(
            onTap: () {
              // Only trigger update if a different chip is tapped.
              if (_selectedIndex != index) {
                // Update internal state is handled by parent via initialCategory prop change
                // setState(() { _selectedIndex = index; });
                // Call the callback function provided by the parent widget.
                widget.onCategorySelected(categoryName);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), // Animation duration
              curve: Curves.easeInOut, // Animation curve
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Chip padding
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : unselectedBgColor,
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
                // Add shadow to selected chip for emphasis.
                boxShadow: isSelected
                    ? [ BoxShadow( color: selectedBgColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2), ) ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row takes minimum space
                children: [
                  // Conditionally display the icon.
                  if (showIcon && icon != null)
                    Icon(
                      icon,
                      size: 18, // Icon size
                      color: isSelected ? selectedFgColor : unselectedFgColor,
                    ),
                  // Add spacing only if icon is shown.
                  if (showIcon && icon != null)
                    const SizedBox(width: 6),
                  // Display the category name.
                  Text(
                    categoryName,
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
