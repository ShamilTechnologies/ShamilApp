import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

class ExploreTopSection extends StatelessWidget {
  final String currentCity;
  final VoidCallback onCityTap;
  
  const ExploreTopSection({
    super.key,
    required this.currentCity,
    required this.onCityTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: "Explore" and large city name.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore',
              style: getbodyStyle(
                color: AppColors.yellowColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentCity,
              style: getbodyStyle(
                color: AppColors.primaryColor,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        // Right side: button to open city selection.
        GestureDetector(
          onTap: onCityTap,
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              Text(
                '$currentCity,',
                style: getbodyStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
            ],
          ),
        ),
      ],
    );
  }
}
