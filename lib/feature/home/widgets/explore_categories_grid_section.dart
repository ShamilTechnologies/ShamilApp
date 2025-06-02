// lib/feature/home/widgets/explore_categories_grid_section.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/constants/icon_constants.dart'; // For Icons
import 'package:shamil_mobile_app/core/utils/colors.dart';
// --- NEW: Import business categories ---
import 'package:shamil_mobile_app/core/constants/business_categories.dart';
// --- NEW: Import category detail screen ---
import 'package:shamil_mobile_app/feature/category_detail/views/category_detail_screen.dart';
// Import HomeBloc only if dispatching FilterByCategory here (now handled by navigation)
// import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;

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

class ExploreCategoriesGridSection extends StatefulWidget {
  const ExploreCategoriesGridSection({super.key});

  @override
  State<ExploreCategoriesGridSection> createState() =>
      _ExploreCategoriesGridSectionState();
}

class _ExploreCategoriesGridSectionState
    extends State<ExploreCategoriesGridSection> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _orbAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

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
  void initState() {
    super.initState();

    // Setup premium animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _orbAnimationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _orbAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double itemSpacing = 16.0;
    const double horizontalPadding = 20.0;
    final int crossAxisCount = (screenWidth < 380) ? 2 : 2;

    if (_appDefinedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildPremiumCategoriesGrid(
                crossAxisCount: crossAxisCount,
                itemSpacing: itemSpacing,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumCategoriesGrid({
    required int crossAxisCount,
    required double itemSpacing,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _appDefinedCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: itemSpacing,
        mainAxisSpacing: itemSpacing,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final category = _appDefinedCategories[index];
        return _PremiumCategoryCard(
          category: category,
          animationDelay: index * 100,
        );
      },
    );
  }
}

class _PremiumCategoryCard extends StatefulWidget {
  final CategoryItemModel category;
  final int animationDelay;

  const _PremiumCategoryCard({
    required this.category,
    required this.animationDelay,
  });

  @override
  State<_PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<_PremiumCategoryCard>
    with TickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(
                    categoryName: widget.category.name,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.category.backgroundColor
                        .withOpacity(_glowAnimation.value),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Floating particles background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FloatingParticlesPainter(
                          color:
                              widget.category.backgroundColor.withOpacity(0.1),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with premium styling
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.category.backgroundColor
                                      .withOpacity(0.8),
                                  widget.category.backgroundColor
                                      .withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.category.backgroundColor
                                      .withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.category.iconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const Spacer(),

                          // Category name
                          Text(
                            widget.category.name,
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(2),

                          // Subtitle with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.5),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Explore now',
                              style: AppTextStyle.getSmallStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hover indicator
                    if (_isHovered)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.category.backgroundColor
                                    .withOpacity(0.8),
                                widget.category.backgroundColor
                                    .withOpacity(0.6),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingParticlesPainter extends CustomPainter {
  final Color color;

  _FloatingParticlesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = Random(42);

    // Draw floating particles
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }

    // Draw subtle geometric lines
    final linePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 30;
      final endY = startY + random.nextDouble() * 30;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
