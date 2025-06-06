import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:shamil_mobile_app/core/constants/icon_constants.dart'
    as AppIcons;
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

class ContentSections extends StatelessWidget {
  final ServiceProviderDisplayModel displayData;
  final ServiceProviderModel? detailedProvider;
  final Function(BuildContext, String?, String) onLaunchUrl;
  final VoidCallback? onNavigateToServices;

  const ContentSections({
    super.key,
    required this.displayData,
    required this.detailedProvider,
    required this.onLaunchUrl,
    this.onNavigateToServices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayData.city.isNotEmpty) _buildLocationSection(),
          const Gap(24),
          if (detailedProvider != null) _buildQuickActions(context),
          const Gap(32),
          if (detailedProvider?.businessDescription.isNotEmpty == true)
            _buildAboutSection(),
          const Gap(32),
          if (detailedProvider?.bookableServices.isNotEmpty == true ||
              detailedProvider?.subscriptionPlans.isNotEmpty == true)
            _buildServicesSection(),
          const Gap(32),
          if (detailedProvider?.amenities.isNotEmpty == true)
            _buildAmenitiesSection(),
          const Gap(32),
          if (detailedProvider?.openingHours.isNotEmpty == true &&
              detailedProvider!.openingHours.values.any((day) => day.isOpen))
            _buildOpeningHoursSection(context),
          const Gap(32),
          if (detailedProvider != null) _buildContactSection(context),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppColors.glassmorphismDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orangeColor.withOpacity(0.2),
                    AppColors.orangeColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orangeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.orangeColor, AppColors.yellowColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.location_solid,
                      size: 16,
                      color: AppColors.lightText,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      displayData.city,
                      style: AppTextStyle.getbodyStyle(
                        color: AppColors.lightText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: _buildQuickActionsList(context)
          .map((action) => Expanded(child: action))
          .toList(),
    );
  }

  List<Widget> _buildQuickActionsList(BuildContext context) {
    List<Widget> actionCards = [];

    if (detailedProvider!.primaryPhoneNumber != null) {
      actionCards.add(_buildActionCard(
        icon: CupertinoIcons.phone_fill,
        label: "Call",
        color: AppColors.greenColor,
        onTap: () =>
            onLaunchUrl(context, detailedProvider!.primaryPhoneNumber, "Call"),
      ));
    }

    if (detailedProvider!.location != null) {
      actionCards.add(_buildActionCard(
        icon: CupertinoIcons.map_fill,
        label: "Directions",
        color: AppColors.orangeColor,
        onTap: () {
          final lat = detailedProvider!.location!.latitude;
          final lon = detailedProvider!.location!.longitude;
          final url =
              'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
          onLaunchUrl(context, url, "Map");
        },
      ));
    }

    if (detailedProvider!.website != null) {
      actionCards.add(_buildActionCard(
        icon: CupertinoIcons.globe,
        label: "Website",
        color: AppColors.cyanColor,
        onTap: () => onLaunchUrl(context, detailedProvider!.website, "Website"),
      ));
    }

    if (detailedProvider!.primaryEmail != null) {
      actionCards.add(_buildActionCard(
        icon: CupertinoIcons.envelope_fill,
        label: "Email",
        color: AppColors.purpleColor,
        onTap: () =>
            onLaunchUrl(context, detailedProvider!.primaryEmail, "Email"),
      ));
    }

    return actionCards;
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.1),
              child: Center(
                child: Icon(
                  icon,
                  color: AppColors.lightText,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildContentSection(
      title: "About This Business",
      icon: CupertinoIcons.info_circle_fill,
      iconColor: AppColors.primaryColor,
      child: Text(
        detailedProvider!.businessDescription,
        style: AppTextStyle.getbodyStyle(
          color: AppColors.lightText,
          height: 1.7,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return _buildContentSection(
      title: "Services & Plans",
      icon: CupertinoIcons.square_grid_2x2_fill,
      iconColor: AppColors.primaryColor,
      child: Column(
        children: [
          if (detailedProvider!.bookableServices.isNotEmpty) ...[
            _buildServiceCard(
              title: "Bookable Services",
              subtitle:
                  "${detailedProvider!.bookableServices.length} services available",
              icon: CupertinoIcons.calendar_badge_plus,
              color: AppColors.primaryColor,
            ),
            const Gap(12),
          ],
          if (detailedProvider!.subscriptionPlans.isNotEmpty) ...[
            _buildServiceCard(
              title: "Subscription Plans",
              subtitle:
                  "${detailedProvider!.subscriptionPlans.length} plans available",
              icon: CupertinoIcons.creditcard_fill,
              color: AppColors.electricBlue,
            ),
            const Gap(16),
          ],
          _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.getbodyStyle(
                    color: AppColors.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.primaryTextSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNavigateToServices,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.arrow_right_circle_fill,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                const Gap(8),
                Text(
                  "View All Services & Plans",
                  style: AppTextStyle.getbodyStyle(
                    color: AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return _buildContentSection(
      title: "Facilities & Amenities",
      icon: CupertinoIcons.star_circle_fill,
      iconColor: AppColors.tealColor,
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: detailedProvider!.amenities.map((amenity) {
          final icon = AppIcons.getIconForAmenity(amenity);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tealColor.withOpacity(0.12),
                  AppColors.tealColor.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.tealColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.tealColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  amenity,
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.lightText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    return _buildContentSection(
      title: "Opening Hours",
      icon: CupertinoIcons.clock_fill,
      iconColor: AppColors.accentColor,
      child: _buildOpeningHours(context, detailedProvider!.openingHours),
    );
  }

  Widget _buildOpeningHours(
      BuildContext context, Map<String, OpeningHoursDay> hoursMap) {
    final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    final daysOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Column(
      children: daysOrder.take(4).map((day) {
        final hours = hoursMap[day.toLowerCase()];
        final bool isToday = day == today;
        final String displayDay = day[0].toUpperCase() + day.substring(1);
        String displayHours;

        if (hours == null ||
            !hours.isOpen ||
            hours.startTime == null ||
            hours.endTime == null) {
          displayHours = "Closed";
        } else {
          final localizations = MaterialLocalizations.of(context);
          final startFormatted = localizations.formatTimeOfDay(
            hours.startTime!,
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );
          final endFormatted = localizations.formatTimeOfDay(
            hours.endTime!,
            alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          );
          displayHours = "$startFormatted - $endFormatted";
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isToday
                  ? [
                      AppColors.accentColor.withOpacity(0.15),
                      AppColors.accentColor.withOpacity(0.05),
                    ]
                  : [
                      AppColors.primaryTextHint.withOpacity(0.1),
                      AppColors.primaryTextHint.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? AppColors.accentColor.withOpacity(0.3)
                  : AppColors.glassmorphismBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    displayDay,
                    style: AppTextStyle.getbodyStyle(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isToday ? AppColors.accentColor : AppColors.lightText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (hours == null || !hours.isOpen)
                      ? AppColors.redColor.withOpacity(0.2)
                      : AppColors.greenColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayHours,
                  style: AppTextStyle.getbodyStyle(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: (hours == null || !hours.isOpen)
                        ? AppColors.redColor
                        : (isToday
                            ? AppColors.accentColor
                            : AppColors.lightText),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    List<Widget> contactItems = [];

    if (detailedProvider!.primaryPhoneNumber != null) {
      contactItems.add(_buildContactItem(
        context: context,
        icon: CupertinoIcons.phone_fill,
        label: detailedProvider!.primaryPhoneNumber!,
        subtitle: "Tap to call",
        color: AppColors.greenColor,
        action: () =>
            onLaunchUrl(context, detailedProvider!.primaryPhoneNumber, "Call"),
      ));
    }

    if (detailedProvider!.primaryEmail != null) {
      contactItems.add(_buildContactItem(
        context: context,
        icon: CupertinoIcons.envelope_fill,
        label: detailedProvider!.primaryEmail!,
        subtitle: "Tap to email",
        color: AppColors.purpleColor,
        action: () =>
            onLaunchUrl(context, detailedProvider!.primaryEmail, "Email"),
      ));
    }

    if (contactItems.isEmpty) return const SizedBox.shrink();

    return _buildContentSection(
      title: "Contact Information",
      icon: CupertinoIcons.phone_fill,
      iconColor: AppColors.greenColor,
      child: Column(children: contactItems),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                action();
              },
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: AppColors.lightText, size: 22),
                      ),
                    ),
                    const Gap(20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppTextStyle.getbodyStyle(
                              color: AppColors.lightText,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Gap(4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              subtitle,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.lightText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: AppColors.lightText,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppColors.glassmorphismDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.15),
                      iconColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [iconColor, iconColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: AppColors.lightText,
                          size: 20,
                        ),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      title,
                      style: AppTextStyle.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
