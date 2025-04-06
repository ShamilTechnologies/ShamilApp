import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for InputFormatters
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart'; // Import text styles

/// A global custom text form field that leverages the application's theme
/// for consistent styling, allowing specific overrides.
class GlobalTextFormField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon; // Correct parameter name
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;


  const GlobalTextFormField({
    super.key,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon, // Correct parameter name
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
  });


  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme themeDecoration = Theme.of(context).inputDecorationTheme;
    // Create effective decoration by applying theme defaults and then specific overrides
    final InputDecoration effectiveDecoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon, // Correct parameter name
      hintStyle: themeDecoration.hintStyle,
      labelStyle: themeDecoration.labelStyle,
      floatingLabelStyle: themeDecoration.floatingLabelStyle,
      floatingLabelBehavior: themeDecoration.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      floatingLabelAlignment: themeDecoration.floatingLabelAlignment,
      filled: themeDecoration.filled,
      fillColor: themeDecoration.fillColor,
      contentPadding: themeDecoration.contentPadding,
      border: themeDecoration.border, // Base border
      enabledBorder: themeDecoration.enabledBorder, // Border when enabled
      focusedBorder: themeDecoration.focusedBorder, // Border when focused
      disabledBorder: themeDecoration.disabledBorder, // Border when disabled
      errorBorder: themeDecoration.errorBorder, // Border on error
      focusedErrorBorder: themeDecoration.focusedErrorBorder, // Border on error and focused
      errorStyle: themeDecoration.errorStyle,
      prefixIconColor: themeDecoration.prefixIconColor,
      suffixIconColor: themeDecoration.suffixIconColor,
      // counterText removes the default character counter display if maxLength is set
      counterText: maxLength != null ? "" : null, // Only hide counter if maxLength is used
    ).applyDefaults(themeDecoration); // Ensure theme defaults are applied

    return TextFormField(
      enabled: enabled,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines, // Password fields are always single line
      minLines: obscureText ? 1 : minLines,
      // Use theme's text style for input, fallback to getbodyStyle
      style: Theme.of(context).textTheme.bodyLarge ?? getbodyStyle(),
      decoration: effectiveDecoration,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
    );
  }
}


/// Template for an email input field
class EmailTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  const EmailTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  // Email validation logic
  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    // More robust email regex
    final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Get icon color from theme, provide fallback
    final iconColor = Theme.of(context).inputDecorationTheme.prefixIconColor ?? AppColors.secondaryColor;
    return GlobalTextFormField(
      labelText: 'Email',
      hintText: 'you@example.com',
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      validator: _emailValidator, // Use specific email validator
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      prefixIcon: Icon(Icons.email_outlined, size: 20, color: iconColor),
    );
  }
}

/// Template for a standard password input field
class PasswordTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final String labelText; // Allow customizing label (e.g., "Password", "Confirm Password")

  const PasswordTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.labelText = 'Password', // Default label
  });

  @override State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscureText = true; // State to toggle password visibility

  // Password validation logic
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Add more complex validation if needed (e.g., uppercase, number, symbol)
    return null;
  }

  // Toggle password visibility
  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get icon colors from theme, provide fallbacks
    final iconColor = Theme.of(context).inputDecorationTheme.prefixIconColor ?? AppColors.secondaryColor;
    final suffixIconColor = Theme.of(context).inputDecorationTheme.suffixIconColor ?? AppColors.secondaryColor;

    return GlobalTextFormField(
      labelText: widget.labelText,
      hintText: 'Enter your password',
      obscureText: _obscureText, // Use state variable
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.done, // Usually 'done' for last password field
      validator: _passwordValidator, // Use internal validator
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: iconColor), // Rounded icon
      suffixIcon: IconButton( // Visibility toggle button
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: suffixIconColor,
        ),
        onPressed: _toggleVisibility,
        splashRadius: 20, // Define splash radius for better feedback
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// Template for a general text input field.
class GeneralTextFormField extends StatelessWidget {
  final String? hintText;
  final String labelText; // Required
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  // *** ADDED: suffixIcon parameter ***
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;


  const GeneralTextFormField({
    super.key,
    this.hintText,
    required this.labelText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    // *** ADDED: suffixIcon to constructor ***
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
  });

  // Default validator if none is provided
  String? _defaultValidator(String? value) {
    // Only validate if not readOnly and value is empty/whitespace
    if (!readOnly && (value == null || value.trim().isEmpty)) {
       return '$labelText is required';
    }
    return null; // Return null if valid or readOnly
  }

  @override
  Widget build(BuildContext context) {
    // Use GlobalTextFormField as the base
    return GlobalTextFormField(
      labelText: labelText,
      hintText: hintText ?? 'Enter $labelText', // Default hint if none provided
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      // Use provided validator, or the default one if none is given
      validator: validator ?? _defaultValidator,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      prefixIcon: prefixIcon,
      // *** FIX: Pass suffixIcon correctly ***
      suffixIcon: suffixIcon, // Pass the suffixIcon parameter down
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
    );
  }
}

/// A global custom dropdown form field that uses the application's theme styling.
class GlobalDropdownFormField<T> extends StatelessWidget {
  final String? hintText;
  final String labelText; // Required
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final Widget? prefixIcon;

  const GlobalDropdownFormField({
    super.key,
    this.hintText,
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  // Default validator for dropdown
  String? _defaultValidator(T? value) {
    if (value == null) {
      return '$labelText is required';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme themeDecoration = Theme.of(context).inputDecorationTheme;
    // Create effective decoration by applying theme defaults
    final InputDecoration effectiveDecoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      hintStyle: themeDecoration.hintStyle,
      labelStyle: themeDecoration.labelStyle,
      floatingLabelStyle: themeDecoration.floatingLabelStyle,
      floatingLabelBehavior: themeDecoration.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      floatingLabelAlignment: themeDecoration.floatingLabelAlignment,
      filled: themeDecoration.filled,
      fillColor: themeDecoration.fillColor,
      contentPadding: themeDecoration.contentPadding, // Use theme padding
      border: themeDecoration.border,
      enabledBorder: themeDecoration.enabledBorder,
      focusedBorder: themeDecoration.focusedBorder,
      disabledBorder: themeDecoration.disabledBorder,
      errorBorder: themeDecoration.errorBorder,
      focusedErrorBorder: themeDecoration.focusedErrorBorder,
      errorStyle: themeDecoration.errorStyle,
      prefixIconColor: themeDecoration.prefixIconColor,
      // Suffix icon color is handled by DropdownButtonFormField's icon property
    ).applyDefaults(themeDecoration);

    return DropdownButtonFormField<T>(
      decoration: effectiveDecoration, // Apply themed decoration
      items: items,
      value: value,
      // Disable onChanged callback if not enabled
      onChanged: enabled ? onChanged : null,
      validator: validator ?? _defaultValidator, // Pass validator
      // Use theme's text style for dropdown items, fallback to getbodyStyle
      style: Theme.of(context).textTheme.bodyLarge ?? getbodyStyle(),
      // Use themed icon color for dropdown arrow, provide fallback
      icon: Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).inputDecorationTheme.suffixIconColor ?? AppColors.secondaryColor),
      isExpanded: true, // Ensure dropdown takes full width available
      // Customize dropdown menu appearance if needed
      // dropdownColor: Theme.of(context).cardColor,
    );
  }
}
