import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({super.key});
  
  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      hintText: 'Find things to do',
      keyboardType: TextInputType.text,
      prefixIcon: Icon(
        Icons.search,
        // ignore: deprecated_member_use
        color: AppColors.primaryColor.withOpacity(0.5),
      ),
      textInputAction: TextInputAction.search,
      enabled: true,
      onChanged: (value) {
        // Handle search input changes here.
      },
      onFieldSubmitted: (value) {
        // Handle search submission here.
      },
    );
  }
}
