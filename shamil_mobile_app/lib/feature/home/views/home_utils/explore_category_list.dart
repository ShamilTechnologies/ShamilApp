import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

class ExploreCategoryList extends StatelessWidget {
  final List<String> categories;
  
  const ExploreCategoryList({
    super.key,
    required this.categories,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Handle category tap.
            },
            child: Text(
              categories[index],
              style: getbodyStyle(
                color: index == 0 ? AppColors.yellowColor :AppColors.primaryColor.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
