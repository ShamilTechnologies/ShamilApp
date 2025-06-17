import 'package:flutter/cupertino.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Configuration step model for the booking flow
class ConfigurationStep {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ConfigurationStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  /// Get the default steps for the booking flow
  static List<ConfigurationStep> getDefaultSteps() {
    return [
      ConfigurationStep(
        id: 'details',
        title: 'Booking Details',
        subtitle: 'Date, time & attendees',
        icon: CupertinoIcons.calendar_today,
        color: AppColors.primaryColor,
      ),
      ConfigurationStep(
        id: 'preferences',
        title: 'Preferences & Splitting',
        subtitle: 'Customize your experience',
        icon: CupertinoIcons.slider_horizontal_3,
        color: AppColors.tealColor,
      ),
      ConfigurationStep(
        id: 'payment',
        title: 'Complete Payment',
        subtitle: 'Secure payment to confirm',
        icon: CupertinoIcons.creditcard_fill,
        color: AppColors.successColor,
      ),
    ];
  }
}
