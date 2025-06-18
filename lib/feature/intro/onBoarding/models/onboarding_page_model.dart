import 'package:flutter/material.dart';

/// Model class representing a single onboarding page
class OnboardingPageModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData iconData;
  final Color primaryColor;
  final Color secondaryColor;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconData,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Create a copy of this model with updated values
  OnboardingPageModel copyWith({
    String? title,
    String? subtitle,
    String? description,
    IconData? iconData,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return OnboardingPageModel(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingPageModel &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.description == description &&
        other.iconData == iconData &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        subtitle.hashCode ^
        description.hashCode ^
        iconData.hashCode ^
        primaryColor.hashCode ^
        secondaryColor.hashCode;
  }

  @override
  String toString() {
    return 'OnboardingPageModel(title: $title, subtitle: $subtitle, description: $description, iconData: $iconData, primaryColor: $primaryColor, secondaryColor: $secondaryColor)';
  }
}
