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
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;
  // *** ADDED: Optional maxLength parameter ***
  final int? maxLength;
  // *** ADDED: Optional inputFormatters parameter ***
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
    this.suffixIcon,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    // *** ADDED: maxLength to constructor ***
    this.maxLength,
    // *** ADDED: inputFormatters to constructor ***
    this.inputFormatters,
  });


  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme themeDecoration = Theme.of(context).inputDecorationTheme;
    final InputDecoration effectiveDecoration = InputDecoration(
      labelText: labelText, hintText: hintText, prefixIcon: prefixIcon, suffixIcon: suffixIcon,
      hintStyle: themeDecoration.hintStyle, labelStyle: themeDecoration.labelStyle,
      floatingLabelStyle: themeDecoration.floatingLabelStyle,
      floatingLabelBehavior: themeDecoration.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      floatingLabelAlignment: themeDecoration.floatingLabelAlignment,
      filled: themeDecoration.filled, fillColor: themeDecoration.fillColor,
      contentPadding: themeDecoration.contentPadding, border: themeDecoration.border,
      enabledBorder: themeDecoration.enabledBorder, focusedBorder: themeDecoration.focusedBorder,
      disabledBorder: themeDecoration.disabledBorder, errorBorder: themeDecoration.errorBorder,
      focusedErrorBorder: themeDecoration.focusedErrorBorder, errorStyle: themeDecoration.errorStyle,
      prefixIconColor: themeDecoration.prefixIconColor, suffixIconColor: themeDecoration.suffixIconColor,
      // counterText removes the default character counter display if maxLength is set
      counterText: "",
    );

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
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      style: getbodyStyle(),
      decoration: effectiveDecoration,
      // *** ADDED: Pass maxLength to TextFormField ***
      maxLength: maxLength,
      // *** ADDED: Pass inputFormatters to TextFormField ***
      inputFormatters: inputFormatters,
    );
  }
}


/// Template for an email input field
class EmailTextFormField extends StatelessWidget { /* ... code as before ... */
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

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) { return 'Please enter your email'; }
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value.trim())) { return 'Please enter a valid email address'; }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).inputDecorationTheme.prefixIconColor ?? AppColors.secondaryColor;
    return GlobalTextFormField(
      labelText: 'Email', hintText: 'you@example.com',
      keyboardType: TextInputType.emailAddress, controller: controller, focusNode: focusNode,
      textInputAction: TextInputAction.next, validator: _emailValidator, // Uses validator
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted, enabled: enabled,
      prefixIcon: Icon(Icons.email_outlined, size: 20, color: iconColor),
    );
  }
}

/// Template for a standard password input field
class PasswordTextFormField extends StatefulWidget { /* ... code as before ... */
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final String labelText;

  const PasswordTextFormField({
    super.key, this.controller, this.focusNode, this.onChanged,
    this.onFieldSubmitted, this.enabled = true, this.labelText = 'Password',
  });

  @override State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscureText = true;
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) { return 'Please enter your password'; }
    if (value.length < 8) { return 'Password must be at least 8 characters'; }
    return null;
  }
  void _toggleVisibility() { setState(() { _obscureText = !_obscureText; }); }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).inputDecorationTheme.prefixIconColor ?? AppColors.secondaryColor;
    final suffixIconColor = Theme.of(context).inputDecorationTheme.suffixIconColor ?? AppColors.secondaryColor;
    return GlobalTextFormField(
      labelText: widget.labelText, hintText: 'Enter your password', obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword, controller: widget.controller, focusNode: widget.focusNode,
      textInputAction: TextInputAction.done, validator: _passwordValidator, // Uses internal validator
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted, enabled: widget.enabled,
      prefixIcon: Icon(Icons.lock_outline, size: 20, color: iconColor),
      suffixIcon: IconButton(
        icon: Icon( _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: suffixIconColor, ),
        onPressed: _toggleVisibility, splashRadius: 20,
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
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  // *** ADDED: Optional maxLength parameter ***
  final int? maxLength;
  // *** ADDED: Optional inputFormatters parameter ***
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
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    // *** ADDED: maxLength to constructor ***
    this.maxLength,
    // *** ADDED: inputFormatters to constructor ***
    this.inputFormatters,
  });

  String? _defaultValidator(String? value) {
    if (!readOnly && (value == null || value.trim().isEmpty)) {
       return '$labelText is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      labelText: labelText,
      hintText: hintText ?? 'Enter $labelText',
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator ?? _defaultValidator,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      prefixIcon: prefixIcon,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      // *** FIX: Pass maxLength down ***
      maxLength: maxLength,
      // *** FIX: Pass inputFormatters down ***
      inputFormatters: inputFormatters,
    );
  }
}

/// A global custom dropdown form field that uses the application's theme styling.
class GlobalDropdownFormField<T> extends StatelessWidget { /* ... code as before ... */
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

   String? _defaultValidator(T? value) {
    if (value == null) { return '$labelText is required'; }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme themeDecoration = Theme.of(context).inputDecorationTheme;
    final InputDecoration effectiveDecoration = InputDecoration( /* ... decoration properties ... */
      labelText: labelText, hintText: hintText, prefixIcon: prefixIcon,
      hintStyle: themeDecoration.hintStyle, labelStyle: themeDecoration.labelStyle,
      floatingLabelStyle: themeDecoration.floatingLabelStyle,
      floatingLabelBehavior: themeDecoration.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      floatingLabelAlignment: themeDecoration.floatingLabelAlignment,
      filled: themeDecoration.filled, fillColor: themeDecoration.fillColor,
      contentPadding: themeDecoration.contentPadding, border: themeDecoration.border,
      enabledBorder: themeDecoration.enabledBorder, focusedBorder: themeDecoration.focusedBorder,
      disabledBorder: themeDecoration.disabledBorder, errorBorder: themeDecoration.errorBorder,
      focusedErrorBorder: themeDecoration.focusedErrorBorder, errorStyle: themeDecoration.errorStyle,
      prefixIconColor: themeDecoration.prefixIconColor,
    );

    return DropdownButtonFormField<T>(
      decoration: effectiveDecoration, items: items, value: value,
      onChanged: enabled ? onChanged : null,
      validator: validator ?? _defaultValidator, // Pass validator
      style: getbodyStyle(),
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).inputDecorationTheme.suffixIconColor ?? AppColors.secondaryColor),
      isExpanded: true,
    );
  }
}
