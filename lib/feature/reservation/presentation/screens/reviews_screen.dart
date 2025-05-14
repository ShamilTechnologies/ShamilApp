import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/review_model.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/widgets/review_card.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/widgets/review_summary.dart';

class ReviewsScreen extends StatefulWidget {
  final String providerId;
  final String? serviceId;
  final List<ReviewModel> reviews;
  final Function(ReviewModel)? onEdit;
  final Function(ReviewModel)? onDelete;
  final VoidCallback? onAddReview;

  const ReviewsScreen({
    Key? key,
    required this.providerId,
    this.serviceId,
    required this.reviews,
    this.onEdit,
    this.onDelete,
    this.onAddReview,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _sortBy = 'newest';
  double? _minRating;
  bool _showVerifiedOnly = false;
  bool _showWithPhotosOnly = false;

  List<ReviewModel> get _filteredReviews {
    var filtered = List<ReviewModel>.from(widget.reviews);

    // Apply filters
    if (_minRating != null) {
      filtered = filtered.where((r) => r.rating >= _minRating!).toList();
    }
    if (_showVerifiedOnly) {
      filtered = filtered.where((r) => r.isVerified).toList();
    }
    if (_showWithPhotosOnly) {
      filtered = filtered.where((r) => r.photos?.isNotEmpty ?? false).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest_rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest_rating':
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return filtered;
  }

  double get _averageRating {
    if (widget.reviews.isEmpty) return 0;
    final sum = widget.reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    return sum / widget.reviews.length;
  }

  Map<String, double> get _categoryAverages {
    final Map<String, List<double>> categoryScores = {};
    final Map<String, double> averages = {};

    for (final review in widget.reviews) {
      final ratings = review.categoryRatings;
      if (ratings != null) {
        for (final entry in ratings.entries) {
          categoryScores.putIfAbsent(entry.key, () => []).add(entry.value);
        }
      }
    }

    for (final entry in categoryScores.entries) {
      final sum = entry.value.fold<double>(0, (sum, score) => sum + score);
      averages[entry.key] = sum / entry.value.length;
    }

    return averages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews',
          style: getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.onAddReview != null)
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: AppColors.primaryColor,
              ),
              onPressed: widget.onAddReview,
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary section
          ReviewSummary(
            reviews: widget.reviews,
            onViewAll: null,
            onAddReview: widget.onAddReview,
          ),

          // Filters section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text('Verified Only'),
                      selected: _showVerifiedOnly,
                      onSelected: (value) {
                        setState(() {
                          _showVerifiedOnly = value;
                        });
                      },
                      backgroundColor: AppColors.lightBackground,
                      selectedColor: AppColors.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryColor,
                      labelStyle: getbodyStyle(
                        color: _showVerifiedOnly
                            ? AppColors.primaryColor
                            : AppColors.secondaryText,
                        fontWeight: _showVerifiedOnly
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    FilterChip(
                      label: Text('With Photos'),
                      selected: _showWithPhotosOnly,
                      onSelected: (value) {
                        setState(() {
                          _showWithPhotosOnly = value;
                        });
                      },
                      backgroundColor: AppColors.lightBackground,
                      selectedColor: AppColors.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppColors.primaryColor,
                      labelStyle: getbodyStyle(
                        color: _showWithPhotosOnly
                            ? AppColors.primaryColor
                            : AppColors.secondaryText,
                        fontWeight: _showWithPhotosOnly
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    ...List.generate(5, (index) {
                      final rating = index + 1.0;
                      final isSelected = _minRating == rating;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.yellowColor,
                            ),
                            const SizedBox(width: 4),
                            Text('$rating+'),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            _minRating = value ? rating : null;
                          });
                        },
                        backgroundColor: AppColors.lightBackground,
                        selectedColor: AppColors.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryColor,
                        labelStyle: getbodyStyle(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryText,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: InputBorder.none,
                      labelStyle: getbodyStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Newest First'),
                      ),
                      DropdownMenuItem(
                        value: 'oldest',
                        child: Text('Oldest First'),
                      ),
                      DropdownMenuItem(
                        value: 'highest_rating',
                        child: Text('Highest Rating'),
                      ),
                      DropdownMenuItem(
                        value: 'lowest_rating',
                        child: Text('Lowest Rating'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                    style: getbodyStyle(),
                    dropdownColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reviews list
          Expanded(
            child: _filteredReviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews found',
                          style: getbodyStyle(
                            color: AppColors.secondaryText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];
                      return ReviewCard(
                        review: review,
                        onEdit: widget.onEdit != null
                            ? () => widget.onEdit!(review)
                            : null,
                        onDelete: widget.onDelete != null
                            ? () => widget.onDelete!(review)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
