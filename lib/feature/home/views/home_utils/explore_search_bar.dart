// lib/feature/home/views/home_utils/explore_search_bar.dart

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
// Removed HomeBloc import as search submission is handled via callback

class ExploreSearchBar extends StatefulWidget {
  final TextEditingController?
      externalController; // Renamed to clarify it's optional and external
  final Function(String)?
      onSearch; // Callback when search is submitted or text cleared

  const ExploreSearchBar({
    super.key,
    this.externalController,
    this.onSearch,
  });

  @override
  State<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends State<ExploreSearchBar> {
  // Internal controller, initialized if no external one is provided
  late TextEditingController _internalController;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // Use external controller if provided, otherwise create an internal one
    _internalController =
        widget.externalController ?? TextEditingController();

    // Listen to the effective controller for changes to manage clear button visibility
    _internalController.addListener(_updateClearButtonVisibility);
    // Initial check for clear button visibility
    _updateClearButtonVisibility();
  }

  void _updateClearButtonVisibility() {
    if (mounted) {
      final shouldShow = _internalController.text.isNotEmpty;
      if (_showClearButton != shouldShow) {
        setState(() {
          _showClearButton = shouldShow;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ExploreSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the externalController instance changes, update the internal one
    // and re-attach listeners.
    if (widget.externalController != oldWidget.externalController) {
      _internalController.removeListener(_updateClearButtonVisibility);
      _internalController =
          widget.externalController ?? TextEditingController();
      _internalController.addListener(_updateClearButtonVisibility);
      _updateClearButtonVisibility(); // Update visibility with the new controller
    }
  }

  @override
  void dispose() {
    // Remove listener. Dispose only if it's an internal controller.
    _internalController.removeListener(_updateClearButtonVisibility);
    if (widget.externalController == null) {
      _internalController
          .dispose(); // Dispose internal controller if it was created here
    }
    super.dispose();
  }

  void _handleClear() {
    _internalController.clear();
    widget.onSearch
        ?.call(''); // Notify parent that search text has been cleared
    FocusScope.of(context)
        .unfocus(); // Optionally hide keyboard after clearing
  }

  void _handleSearchSubmitted(String value) {
    final trimmedValue = value.trim();
    print("Search submitted from ExploreSearchBar: $trimmedValue");
    widget.onSearch?.call(
        trimmedValue); // Call the onSearch callback with the trimmed value
    FocusScope.of(context).unfocus(); // Hide keyboard
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller:
          _internalController, // Always use the (potentially internal) _internalController
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: 'Find places, activities...',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: AppColors.accentColor.withOpacity(0.5),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.secondaryColor.withOpacity(0.8),
          size: 22,
        ),
        suffixIcon: _showClearButton
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppColors.secondaryColor.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: _handleClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.0),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
      onChanged: (value) {
        // The listener on _internalController already handles _showClearButton update.
        // If you need live search triggered on every change (debounced):
        // _debouncedSearch?.call(value); // Implement debouncing logic
      },
      onFieldSubmitted: _handleSearchSubmitted,
    );
  }
}