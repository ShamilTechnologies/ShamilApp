// lib/core/widgets/placeholders.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;

/// Builds a versatile profile placeholder.
///
/// Displays a [CachedNetworkImage] if [imageUrl] is provided and valid.
/// Otherwise, displays the initials from [name] if provided.
/// If neither is available or name is too short, displays a default person icon.
Widget buildProfilePlaceholder({
  String? imageUrl,
  required String name,
  required double size, // This is a required named parameter
  BorderRadius? borderRadius,
  TextStyle? textStyle,
  Color? backgroundColor,
  Color? textColor,
  BoxFit fit = BoxFit.cover,
  IconData defaultIcon = Icons.person_outline_rounded, // Allow customizing default icon
}) {
  // Use a default theme or Theme.of(context) if context is available and needed for theme-dependent defaults.
  // For simplicity here, some defaults are hardcoded or derived.
  final ThemeData currentTheme = ThemeData(); // Placeholder, ideally use Theme.of(context)

  final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8.0); // Default to 8px for squared look
  final safeSize = size.isFinite && size > 0 ? size : 48.0;

  String initials = '';
  if (name.isNotEmpty) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isNotEmpty) {
      initials = nameParts.first.isNotEmpty ? nameParts.first[0].toUpperCase() : '';
      if (nameParts.length > 1 && nameParts.last.isNotEmpty) {
        initials += nameParts.last[0].toUpperCase();
      } else if (initials.isEmpty && name.length > 1) {
        // Fallback if only one part or first part is empty
        initials = name.substring(0,1).toUpperCase();
      }
    }
  }


  Widget placeholderContent;

  bool isValidImageUrl = imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true;

  if (isValidImageUrl) {
    placeholderContent = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: safeSize,
      height: safeSize,
      fit: fit,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          // borderRadius is applied by ClipRRect
          image: DecorationImage(
            image: imageProvider,
            fit: fit,
          ),
        ),
      ),
      placeholder: (context, url) => Container(
        width: safeSize,
        height: safeSize,
        color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.05),
        child: Center(child: CupertinoActivityIndicator(radius: safeSize * 0.2)),
      ),
      errorWidget: (context, url, error) => _buildInitialsOrIcon(
        initials: initials,
        size: safeSize,
        textStyle: textStyle,
        backgroundColor: backgroundColor ?? AppColors.accentColor.withOpacity(0.5), // Different color for error fallback
        textColor: textColor,
        defaultIcon: defaultIcon,
        theme: currentTheme,
      ),
    );
  } else {
     placeholderContent = _buildInitialsOrIcon(
      initials: initials,
      size: safeSize,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      textColor: textColor,
      defaultIcon: defaultIcon,
      theme: currentTheme,
    );
  }

  return ClipRRect(
    borderRadius: effectiveBorderRadius,
    child: Container(
      width: safeSize,
      height: safeSize,
      color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.08),
      child: placeholderContent,
    ),
  );
}

Widget _buildInitialsOrIcon({
  required String initials,
  required double size,
  TextStyle? textStyle,
  Color? backgroundColor,
  Color? textColor,
  required IconData defaultIcon,
  required ThemeData theme,
}) {
  final iconSize = (size * 0.5).clamp(18.0, size * 0.6); // Adjusted icon size clamping
  final effectiveTextStyle = textStyle ??
      app_text_style.getTitleStyle(
        fontSize: (size * (initials.length == 1 ? 0.45 : 0.35)).clamp(10.0, 30.0), // Adjust font based on initial length
        color: textColor ?? theme.colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      );

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.primaryColor.withOpacity(0.1),
    ),
    child: Center(
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: effectiveTextStyle,
              textAlign: TextAlign.center,
            )
          : Icon(
              defaultIcon,
              size: iconSize,
              color: textColor ?? AppColors.primaryColor.withOpacity(0.6),
            ),
    ),
  );
}

Widget buildImagePlaceholder(BuildContext context, {double? width, double? height, BorderRadius? borderRadius}) {
  final theme = Theme.of(context);
  return Container(
    width: width ?? double.infinity,
    height: height ?? 150,
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      borderRadius: borderRadius ?? BorderRadius.circular(8.0),
    ),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: (height ?? 150) * 0.4,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    ),
  );
}

Widget buildImageErrorWidget(BuildContext context, {double? width, double? height, BorderRadius? borderRadius}) {
   final theme = Theme.of(context);
  return Container(
    width: width ?? double.infinity,
    height: height ?? 150,
     decoration: BoxDecoration(
      color: theme.colorScheme.errorContainer.withOpacity(0.3),
      borderRadius: borderRadius ?? BorderRadius.circular(8.0),
    ),
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
         size: (height ?? 150) * 0.4,
        color: theme.colorScheme.onErrorContainer.withOpacity(0.6),
      ),
    ),
  );
}
