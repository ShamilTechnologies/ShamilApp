import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc if needed for direct dispatch (alternative)
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart'; // Import HomeBloc events

class ExploreSearchBar extends StatelessWidget {
  // *** ADDED: Accept controller and callback from parent ***
  final TextEditingController? controller;
  final Function(String)? onSearch; // Callback when search is submitted

  const ExploreSearchBar({
    super.key,
    this.controller,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField( // Use standard TextFormField for clarity
      controller: controller, // Use the passed controller
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.primaryColor, // Text color inside the field
      ),
      decoration: InputDecoration(
        hintText: 'Find places, activities...', // Updated hint text
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryColor.withOpacity(0.7), // Hint text color
        ),
        // --- Styling ---
        filled: true,
        fillColor: AppColors.accentColor.withOpacity(0.5), // Light background fill
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.secondaryColor.withOpacity(0.8), // Icon color
          size: 22,
        ),
        // Optional: Add a clear button
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppColors.secondaryColor.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: () {
                  controller?.clear();
                  // Optionally trigger search with empty query or clear results
                  onSearch?.call(''); // Call search callback with empty string
                },
              )
            : null, // No suffix icon if controller is null or text is empty
        // Border styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0), // Consistent radius
          borderSide: BorderSide.none, // No visible border line
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          // Optional: Add a subtle border on focus
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Adjust padding
      ),
      onChanged: (value) {
        // Implement debounced search here if needed for live suggestions
        // For now, we only trigger search on submission
        // Need to call setState in parent if suffixIcon visibility depends on controller text
      },
      onFieldSubmitted: (value) {
        // *** Call the onSearch callback when submitted ***
        final trimmedValue = value.trim();
        print("Search submitted: $trimmedValue");
        onSearch?.call(trimmedValue); // Use the passed callback
        // Hide keyboard
        FocusScope.of(context).unfocus();
      },
    );
  }
}
