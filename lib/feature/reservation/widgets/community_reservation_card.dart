// lib/feature/reservation/widgets/community_reservation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

/// A card widget that displays a community-visible reservation
/// with options to view details and request to join
class CommunityReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onViewDetails;
  final VoidCallback onRequestJoin;

  const CommunityReservationCard({
    super.key,
    required this.reservation,
    required this.onViewDetails,
    required this.onRequestJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hostName = reservation.userName;
    final serviceName = reservation.serviceName ?? 'Community Event';
    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d').format(dateTime)
        : 'Date not specified';
    final formattedTime = dateTime != null
        ? DateFormat('h:mm a').format(dateTime)
        : 'Time not specified';
    final category = reservation.hostingCategory ?? 'Social';
    final description =
        reservation.hostingDescription ?? 'Join this community event!';

    // Calculate spaces remaining (if any)
    final totalCapacity = reservation.reservedCapacity ?? 0;
    final currentAttendees = reservation.attendees.length;
    final spacesRemaining = totalCapacity - currentAttendees;

    // Calculate price per person if cost splitting is enabled
    final totalPrice = reservation.totalPrice ?? 0.0;
    final pricePerPerson = reservation.costSplitDetails != null
        ? totalPrice / totalCapacity
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 16,
                ),
                const Gap(8),
                Text(
                  category,
                  style: AppTextStyle.getSmallStyle(
                    color: _getCategoryColor(category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (spacesRemaining > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$spacesRemaining spaces left',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  serviceName,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Gap(8),

                // Host info
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_fill,
                      color: AppColors.secondaryColor,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      'Hosted by $hostName',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Gap(4),

                // Date and time
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      formattedDate,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Gap(16),
                    const Icon(
                      CupertinoIcons.clock,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      formattedTime,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Gap(12),

                // Description
                Text(
                  description,
                  style: AppTextStyle.getbodyStyle(
                    color: AppColors.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Gap(16),

                // Price and capacity info
                Row(
                  children: [
                    if (pricePerPerson != null) ...[
                      const Icon(
                        CupertinoIcons.money_dollar_circle,
                        color: AppColors.secondaryText,
                        size: 16,
                      ),
                      const Gap(4),
                      Text(
                        '${pricePerPerson.toStringAsFixed(2)} per person',
                        style: AppTextStyle.getSmallStyle(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Gap(16),
                    ],
                    const Icon(
                      CupertinoIcons.group,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      '$currentAttendees/$totalCapacity attendees',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(CupertinoIcons.info_circle),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton.icon(
                      onPressed: spacesRemaining > 0 ? onRequestJoin : null,
                      icon: const Icon(CupertinoIcons.person_add),
                      label: const Text('Join'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on event category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return AppColors.greenColor;
      case 'sports':
        return AppColors.orangeColor;
      case 'entertainment':
        return AppColors.purpleColor;
      case 'education':
        return AppColors.cyanColor;
      case 'wellness':
        return Colors.teal;
      case 'social':
        return AppColors.secondaryColor;
      default:
        return AppColors.primaryColor;
    }
  }

  /// Get icon based on event category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return CupertinoIcons.flame_fill;
      case 'sports':
        return CupertinoIcons.sportscourt_fill;
      case 'entertainment':
        return CupertinoIcons.film_fill;
      case 'education':
        return CupertinoIcons.book_fill;
      case 'wellness':
        return CupertinoIcons.heart_fill;
      case 'social':
        return CupertinoIcons.person_3_fill;
      default:
        return CupertinoIcons.star_fill;
    }
  }
}
