import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/review_model.dart';

class ReviewForm extends StatefulWidget {
  final String reservationId;
  final String providerId;
  final String? serviceId;
  final Function(ReviewModel) onSubmit;
  final bool isAnonymous;
  final bool isVerified;

  const ReviewForm({
    Key? key,
    required this.reservationId,
    required this.providerId,
    this.serviceId,
    required this.onSubmit,
    this.isAnonymous = false,
    this.isVerified = false,
  }) : super(key: key);

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0.0;
  List<String> _photos = [];
  Map<String, double> _categoryRatings = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  // Define rating categories
  final List<String> _categories = [
    'Service',
    'Cleanliness',
    'Value',
    'Atmosphere',
    'Staff',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize category ratings
    for (var category in _categories) {
      _categoryRatings[category] = 0.0;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Upload image to storage and get URL
      setState(() {
        _photos.add(image.path);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0.0) {
      setState(() {
        _errorMessage = 'Please provide a rating';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final review = ReviewModel(
        id: '', // Will be set by Firestore
        reservationId: widget.reservationId,
        userId: '', // Will be set by backend
        userName: '', // Will be set by backend
        providerId: widget.providerId,
        serviceId: widget.serviceId,
        rating: _rating,
        comment: _commentController.text,
        photos: _photos,
        categoryRatings: _categoryRatings,
        createdAt: Timestamp.now(),
        isAnonymous: widget.isAnonymous,
        isVerified: widget.isVerified,
      );

      widget.onSubmit(review);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit review: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating
          Text(
            'Overall Rating',
            style: getTitleStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.yellowColor,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),

          // Category Ratings
          Text(
            'Category Ratings',
            style: getTitleStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._categories.map((category) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: getbodyStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < (_categoryRatings[category] ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.yellowColor,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _categoryRatings[category] = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Comment
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Your Review',
              hintText: 'Share your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.lightBackground,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your review';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Photos
          Text(
            'Add Photos (Optional)',
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
              ..._photos.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        entry.value,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.redColor,
                        ),
                        onPressed: () => _removePhoto(entry.key),
                      ),
                    ),
                  ],
                );
              }),
              if (_photos.length < 5)
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      border: Border.all(color: AppColors.primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.redColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: getbodyStyle(
                        color: AppColors.redColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: getbodyStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
