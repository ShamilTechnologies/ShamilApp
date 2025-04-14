import 'package:flutter/material.dart';
// Keep for fallback/specific colors if needed
// Can likely remove if theme covers all styles

// Callback type for when a category is selected
typedef CategorySelectedCallback = void Function(String category);

class ExploreCategoryList extends StatefulWidget {
  final List<String> categories;
  final CategorySelectedCallback onCategorySelected;

  const ExploreCategoryList({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<ExploreCategoryList> createState() => _ExploreCategoryListState();
}

class _ExploreCategoryListState extends State<ExploreCategoryList> {
  // Initialize selected index based on 'All' or first item
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set initial selection to 'All' if present, otherwise first item
    int initialIndex = widget.categories.indexOf('All');
    if (initialIndex != -1) {
      _selectedIndex = initialIndex;
    } else if (widget.categories.isNotEmpty) {
      _selectedIndex = 0; // Default to first item if 'All' is not present
    }
  }

  // Example mapping - replace with your actual icons
  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer_rounded; // Example
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'padel':
        return Icons.sports_tennis_rounded;
      case 'pools':
        return Icons.pool_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'salons':
        return Icons.cut_rounded;
      case 'spas':
        return Icons.spa_rounded;
      case 'dining':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'outdoors':
        return Icons.hiking_rounded;
      default:
        return Icons.category_rounded; // Default icon for 'All' or others
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return SizedBox(
      height: 40, // Consistent height for the list items
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // Use bouncy scroll
        itemCount: widget.categories.length,
        // Padding handled by parent in home_view now
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none, // Allow shadows to be visible if added
        separatorBuilder: (context, index) =>
            const SizedBox(width: 10), // Spacing between items
        itemBuilder: (context, index) {
          final bool isSelected = index == _selectedIndex;
          final categoryName = widget.categories[index];
          final IconData icon = _getIconForCategory(categoryName); // Get icon

          // Define selected/unselected colors using the theme
          final selectedBgColor = theme.colorScheme.primary;
          final selectedFgColor = theme.colorScheme.onPrimary;
          // *** UPDATED: Unselected background uses primary color with low opacity ***
          final unselectedBgColor = theme.colorScheme.primary.withOpacity(0.1);
          // *** UPDATED: Unselected foreground uses primary color with medium opacity ***
          final unselectedFgColor = theme.colorScheme.primary.withOpacity(0.8);

          return GestureDetector(
            onTap: () {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onCategorySelected(categoryName);
                print("Category tapped: $categoryName");
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), // Animation duration
              curve: Curves.easeInOut, // Animation curve
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBgColor : unselectedBgColor,
                // *** UPDATED: Remove border for unselected state ***
                border: null, // No border for a cleaner look
                borderRadius:
                    BorderRadius.circular(8.0), // Rounded rectangle corners
                boxShadow: isSelected
                    ? [
                        // Shadow only for selected item
                        BoxShadow(
                          color: selectedBgColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                // Use Row to include icon and text
                mainAxisSize: MainAxisSize.min, // Row takes minimum width
                children: [
                  Icon(
                    // Display icon
                    icon,
                    size: 18,
                    color: isSelected
                        ? selectedFgColor
                        : unselectedFgColor, // Use defined colors
                  ),
                  const SizedBox(width: 6), // Space between icon and text
                  Text(
                    categoryName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      // Use theme text style
                      color: isSelected
                          ? selectedFgColor
                          : unselectedFgColor, // Use defined colors
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
