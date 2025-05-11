import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';

/// A global custom text form field that leverages the application's theme
/// for consistent styling, with support for modern design, error states,
/// and custom icons.
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
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;
  final String? errorText;
  final bool isRequired;

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
    this.maxLength,
    this.inputFormatters,
    this.hasError = false,
    this.errorText,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final InputDecorationTheme themeDecoration = theme.inputDecorationTheme;
    
    // Create effective decoration with modern styling
    final InputDecoration effectiveDecoration = InputDecoration(
      labelText: isRequired ? '$labelText*' : labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade200 
            : AppColors.secondaryText.withOpacity(0.6),
      ),
      labelStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade600 
            : AppColors.secondaryText,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade600 
            : AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: hasError 
            ? BorderSide(color: Colors.red.shade400, width: 1.5) 
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError 
              ? Colors.red.shade400 
              : AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade600,
          width: 2.0,
        ),
      ),
      errorStyle: getSmallStyle(
        color: Colors.red.shade600,
        fontSize: 12,
      ),
      errorText: hasError ? errorText : null,
      // counterText removes the default character counter display if maxLength is set
      counterText: maxLength != null ? "" : null,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasError 
            ? Border.all(color: Colors.red.shade400, width: 1.0) 
            : null,
      ),
      child: TextFormField(
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
        style: getbodyStyle(
          color: hasError ? Colors.red.shade800 : null,
        ),
        decoration: effectiveDecoration,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

/// A modern styled email input field with error handling
class EmailTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool hasError;
  final String? errorText;

  const EmailTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.hasError = false,
    this.errorText,
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
    return GlobalTextFormField(
      labelText: 'Email',
      hintText: 'you@example.com',
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      validator: _emailValidator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      hasError: hasError,
      errorText: errorText,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasError 
                ? Colors.red.shade50 
                : AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            CupertinoIcons.mail,
            color: hasError 
                ? Colors.red.shade600 
                : AppColors.primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// A modern styled password field with visibility toggle and error handling
class PasswordTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final String labelText;
  final bool hasError;
  final String? errorText;

  const PasswordTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.labelText = 'Password',
    this.hasError = false,
    this.errorText,
  });

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscureText = true;

  // Password validation logic
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      labelText: widget.labelText,
      hintText: 'Enter your password',
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.done,
      validator: _passwordValidator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      hasError: widget.hasError,
      errorText: widget.errorText,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.hasError 
                ? Colors.red.shade50 
                : AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            CupertinoIcons.lock,
            color: widget.hasError 
                ? Colors.red.shade600 
                : AppColors.primaryColor,
            size: 20,
          ),
        ),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText 
              ? CupertinoIcons.eye 
              : CupertinoIcons.eye_slash,
          size: 20,
          color: widget.hasError 
              ? Colors.red.shade600 
              : AppColors.secondaryColor,
        ),
        onPressed: _toggleVisibility,
        splashRadius: 20,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// A general-purpose styled text field with modern design and error handling
class GeneralTextFormField extends StatelessWidget {
  final String? hintText;
  final String labelText;
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
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;
  final String? errorText;
  final bool isRequired;
  final IconData? iconData;

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
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.hasError = false,
    this.errorText,
    this.isRequired = true,
    this.iconData,
  });

  // Default validator if none is provided
  String? _defaultValidator(String? value) {
    if (!readOnly && isRequired && (value == null || value.trim().isEmpty)) {
      return '$labelText is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Create a modern styled prefix icon if iconData is provided
    Widget? effectivePrefixIcon = prefixIcon;
    if (prefixIcon == null && iconData != null) {
      effectivePrefixIcon = Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasError 
                ? Colors.red.shade50 
                : AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            iconData,
            color: hasError 
                ? Colors.red.shade600 
                : AppColors.primaryColor,
            size: 20,
          ),
        ),
      );
    }
    
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
      prefixIcon: effectivePrefixIcon,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      hasError: hasError,
      errorText: errorText,
      isRequired: isRequired,
    );
  }
}

/// A modern styled dropdown field with error handling
class GlobalDropdownFormField<T> extends StatelessWidget {
  final String? hintText;
  final String labelText;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final IconData? iconData;
  final bool hasError;
  final String? errorText;
  final bool isRequired;

  const GlobalDropdownFormField({
    super.key,
    this.hintText,
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.iconData,
    this.hasError = false,
    this.errorText,
    this.isRequired = true,
  });

  // Default validator for dropdown
  String? _defaultValidator(T? value) {
    if (isRequired && value == null) {
      return '$labelText is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create prefix icon container
    Widget prefixIconWidget = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasError 
              ? Colors.red.shade50 
              : AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          iconData ?? CupertinoIcons.list_bullet,
          color: hasError 
              ? Colors.red.shade600 
              : AppColors.primaryColor,
          size: 20,
        ),
      ),
    );

    // Define dropdown decoration
    final InputDecoration decoration = InputDecoration(
      labelText: isRequired ? '$labelText*' : labelText,
      hintText: hintText,
      prefixIcon: prefixIconWidget,
      hintStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade200 
            : AppColors.secondaryText.withOpacity(0.6),
      ),
      labelStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade600 
            : AppColors.secondaryText,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: getbodyStyle(
        color: hasError 
            ? Colors.red.shade600 
            : AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: hasError 
            ? BorderSide(color: Colors.red.shade400, width: 1.5) 
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError 
              ? Colors.red.shade400 
              : AppColors.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade600,
          width: 2.0,
        ),
      ),
      errorStyle: getSmallStyle(
        color: Colors.red.shade600,
        fontSize: 12,
      ),
      errorText: hasError ? errorText : null,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasError 
            ? Border.all(color: Colors.red.shade400, width: 1.0) 
            : null,
      ),
      child: DropdownButtonFormField<T>(
        decoration: decoration,
        items: items,
        value: value,
        onChanged: enabled ? onChanged : null,
        validator: validator ?? _defaultValidator,
        style: getbodyStyle(
          color: hasError ? Colors.red.shade800 : null,
        ),
        icon: Icon(
          CupertinoIcons.chevron_down,
          color: hasError 
              ? Colors.red.shade600 
              : AppColors.secondaryColor,
          size: 18,
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
        focusColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// A date picker field with modern styling
class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorText;
  final bool isRequired;

  const DatePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    required this.onTap,
    this.hasError = false,
    this.errorText,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return GeneralTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? 'YYYY-MM-DD',
      validator: validator,
      enabled: enabled,
      readOnly: true,
      onTap: enabled ? onTap : null,
      keyboardType: TextInputType.none,
      hasError: hasError,
      errorText: errorText,
      isRequired: isRequired,
      iconData: CupertinoIcons.calendar,
      suffixIcon: Icon(
        CupertinoIcons.chevron_down,
        color: hasError 
            ? Colors.red.shade600 
            : AppColors.secondaryColor,
        size: 18,
      ),
    );
  }
}

/// A phone number field with country code picker
class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final Widget countryCodePicker;
  final bool hasError;
  final String? errorText;
  
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
    required this.countryCodePicker,
    this.hasError = false,
    this.errorText,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country code picker
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: hasError 
                ? Border.all(color: Colors.red.shade400, width: 1.0) 
                : null,
          ),
          child: countryCodePicker,
        ),
        const SizedBox(width: 8),
        // Phone number field
        Expanded(
          child: GeneralTextFormField(
            controller: controller,
            labelText: labelText,
            hintText: hintText ?? 'Your phone number',
            validator: validator,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            iconData: CupertinoIcons.phone,
            hasError: hasError,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

/// A search bar with modern styling
class SearchBarField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  
  const SearchBarField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    bool showClearButton = controller.text.isNotEmpty;
    
    return GeneralTextFormField(
      controller: controller,
      labelText: '',
      hintText: hintText,
      onChanged: (value) {
        if (onChanged != null) onChanged!(value);
      },
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      iconData: CupertinoIcons.search,
      isRequired: false,
      suffixIcon: showClearButton 
          ? IconButton(
              icon: const Icon(
                CupertinoIcons.clear_circled_solid,
                color: AppColors.secondaryColor,
                size: 18,
              ),
              onPressed: () {
                controller.clear();
                if (onClear != null) onClear!();
              },
            )
          : null,
    );
  }
}