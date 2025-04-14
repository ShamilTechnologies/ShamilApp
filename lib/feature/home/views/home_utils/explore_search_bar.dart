import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Keep for fallback colors if needed

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme data
    final theme = Theme.of(context);

    // Use GlobalTextFormField, assuming it correctly applies InputDecorationTheme
    return GlobalTextFormField(
      hintText: 'Find things to do...', // Slightly more engaging hint text
      keyboardType: TextInputType.text,
      prefixIcon: Icon(
        Icons.search_rounded, // Use rounded icon
        // *** Use color from the theme's InputDecorationTheme ***
        // Provide a fallback color if the theme doesn't define one.
        color: theme.inputDecorationTheme.prefixIconColor ??
            AppColors.secondaryColor.withOpacity(0.7),
        size: 22, // Optional: Adjust size
      ),
      textInputAction: TextInputAction.search,
      enabled: true, // Assuming search is always enabled
      onChanged: (value) {
        // TODO: Implement debounced search logic if needed
        print("Search query changed: $value");
      },
      onFieldSubmitted: (value) {
        // TODO: Handle direct search submission
        print("Search submitted: $value");
      },
      // The GlobalTextFormField should internally use the theme's
      // input decoration for border, fill color, hint style, etc.
      // No need to override them here unless specific changes are desired.
    );
  }
}
