// lib/feature/home/widgets/explore_categories_grid_section.dart
import 'dart:math'; // Add this import for Random
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // For Icons
import 'package:shamil_mobile_app/core/utils/colors.dart';
// --- NEW: Import business categories ---
import 'package:shamil_mobile_app/core/constants/business_categories.dart';
// --- NEW: Import category detail screen ---
import 'package:shamil_mobile_app/feature/category_detail/views/category_detail_screen.dart';
// Import HomeBloc only if dispatching FilterByCategory here (now handled by navigation)
// import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';

// Keep CategoryItemModel if still needed for color logic, or simplify
class CategoryItemModel {
  final String name;
  final IconData iconData;
  final Color backgroundColor;
  final Color iconAndTextColor;
  final String? filterKey;

  const CategoryItemModel({
    required this.name,
    required this.iconData,
    required this.backgroundColor,
    this.iconAndTextColor = Colors.white,
    this.filterKey,
  });
}

class ExploreCategoriesGridSection extends StatelessWidget {
  const ExploreCategoriesGridSection({super.key});

  static List<CategoryItemModel> _generateAppDefinedCategories() {
    final List<Color> availableColors = [
      AppColors.primaryColor,
      AppColors.orangeColor,
      AppColors.greenColor,
      AppColors.secondaryColor,
      AppColors.purpleColor,
      AppColors.yellowColor,
      AppColors.tealColor,
      AppColors.redColor,
      AppColors.pinkColor,
      AppColors.brownColor,
      AppColors.cyanColor,
      AppColors.darkBlue,
      AppColors.limeGreen,
    ];
    final List<Color> usableColors =
        availableColors.where((c) => c != AppColors.white).toList();
    if (usableColors.isEmpty) {
      usableColors.add(AppColors.primaryColor);
      usableColors.add(AppColors.secondaryColor);
    }

    int colorIndex = 0;
    final List<CategoryItemModel> categories = [];
    final List<String> categoryNames = getAllCategoryNames();

    for (var name in categoryNames) {
      final bgColor = usableColors[colorIndex % usableColors.length];
      final textColor = bgColor.computeLuminance() > 0.5
          ? (AppColors.primaryText ?? Colors.black87)
          : AppColors.white;
      final iconData =
          kBusinessCategoryIcons[name] ?? kBusinessCategoryIcons['_default']!;

      categories.add(
        CategoryItemModel(
          name: name,
          iconData: iconData,
          backgroundColor: bgColor,
          filterKey: name,
          iconAndTextColor: textColor,
        ),
      );
      colorIndex++;
    }
    return categories;
  }

  static final List<CategoryItemModel> _appDefinedCategories =
      _generateAppDefinedCategories();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const double itemSpacing = 12.0;
    const double horizontalPadding = 16.0;
    final int crossAxisCount = (screenWidth < 380) ? 2 : 2;
    final double itemWidth = (screenWidth -
            (horizontalPadding * 2) -
            (itemSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final double itemHeight = itemWidth; // Square ratio

    if (_appDefinedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categories",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText ?? theme.colorScheme.onSurface,
            ),
          ),
          const Gap(4),
          Text(
            "Discover amazing activities for every interest!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  AppColors.secondaryText ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appDefinedCategories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: itemSpacing,
              mainAxisSpacing: itemSpacing,
              childAspectRatio: 1.0, // Square ratio
            ),
            itemBuilder: (context, index) {
              final category = _appDefinedCategories[index];
              return _CategoryCard(category: category);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItemModel category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.0),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                categoryName: category.name,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: category.backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              // Decorative lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _DecorativeLinesPainter(
                    color: category.backgroundColor.withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: category.backgroundColor,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Faded icon in bottom-left
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Icon(
                        category.iconData,
                        size: 40.0,
                        color: category.backgroundColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeLinesPainter extends CustomPainter {
  final Color color;

  _DecorativeLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw random lines
    final random = Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 5; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 40;
      final endY = startY + random.nextDouble() * 40;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
