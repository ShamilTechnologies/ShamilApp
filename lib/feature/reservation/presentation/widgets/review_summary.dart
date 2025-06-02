import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/review_model.dart';

class ReviewSummary extends StatelessWidget {
  final List<ReviewModel> reviews;
  final VoidCallback? onViewAll;
  final VoidCallback? onAddReview;

  const ReviewSummary({
    super.key,
    required this.reviews,
    this.onViewAll,
    this.onAddReview,
  });

  double get _averageRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<double>(
      0,
      (sum, review) => sum + review.rating,
    );
    return sum / reviews.length;
  }

  Map<String, double> get _categoryAverages {
    final Map<String, List<double>> categoryScores = {};
    final Map<String, double> averages = {};

    for (final review in reviews) {
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

  Map<double, int> get _ratingDistribution {
    final distribution = <double, int>{};
    for (var i = 1.0; i <= 5.0; i++) {
      distribution[i] = 0;
    }

    for (final review in reviews) {
      final rating = review.rating;
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with average rating and total reviews
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Rating',
                      style: getTitleStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < _averageRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.yellowColor,
                            size: 24,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: getTitleStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${reviews.length} reviews',
                      style: getbodyStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    if (onViewAll != null)
                      TextButton(
                        onPressed: onViewAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View All',
                          style: getbodyStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating distribution
            Text(
              'Rating Distribution',
              style: getTitleStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._ratingDistribution.entries.map((entry) {
              final percentage =
                  reviews.isEmpty ? 0.0 : (entry.value / reviews.length) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${entry.key.toInt()}★',
                      style: getbodyStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.lightBackground,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.yellowColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: getbodyStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Category ratings
            if (_categoryAverages.isNotEmpty) ...[
              Text(
                'Category Ratings',
                style: getTitleStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: _categoryAverages.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: getbodyStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < entry.value
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.yellowColor,
                                size: 14,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              entry.value.toStringAsFixed(1),
                              style: getbodyStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Add review button
            if (onAddReview != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAddReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Write a Review',
                    style: getbodyStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
