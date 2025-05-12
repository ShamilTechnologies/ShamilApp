// lib/feature/details/widgets/attendee_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

// Helper extension from options_bottom_sheet (consider moving to a common place)
extension StringExtension on String {
    String capitalize() { if (isEmpty) return this; return split(' ').map((word) { if (word.isEmpty) return ''; return word[0].toUpperCase() + word.substring(1).toLowerCase(); }).join(' '); }
}

/// Displays the list of attendees for a reservation and provides buttons
/// to add family members or invite friends.
class AttendeeSection extends StatelessWidget {
  final ThemeData theme;
  final List<AttendeeModel> attendees;
  final int maxGroupSize; // Use 999 or similar for infinity
  final bool isLoading;
  final VoidCallback onAddFamily; // Callback to show family selector
  final VoidCallback onInviteFriend; // Callback to show friend selector
  // No need for onRemoveAttendee callback if handled directly via Bloc below

  const AttendeeSection({
    super.key,
    required this.theme,
    required this.attendees,
    required this.maxGroupSize,
    required this.isLoading,
    required this.onAddFamily,
    required this.onInviteFriend,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAddMoreAttendees = attendees.length < maxGroupSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Gap(16),
        // Section Header
        Text(
            "4. Attendees (${attendees.length}/${maxGroupSize == 999 ? '∞' : maxGroupSize})",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Gap(10),

        // Attendee List or Placeholder
        if (attendees.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Just you (add family/friends below)",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  // TODO: Replace with actual image loading logic if available
                  child: Text(
                      attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                ),
                title: Text(attendee.name, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  attendee.type == 'self'
                      ? 'You (${attendee.status})'
                      : '${attendee.type.capitalize()} (${attendee.status})',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                // Remove Button (only for non-self)
                trailing: attendee.type != 'self'
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400, size: 20),
                        tooltip: "Remove ${attendee.name}",
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        // Dispatch RemoveAttendee event directly
                        onPressed: isLoading
                            ? null
                            : () => context.read<ReservationBloc>().add(RemoveAttendee(userIdToRemove: attendee.userId)),
                      )
                    : null,
              );
            },
          ),
        const Gap(12),

        // Add/Invite Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: const Text("Add Family"),
              style: OutlinedButton.styleFrom( foregroundColor: AppColors.primaryColor, side: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              // Disable if loading or max size reached, call callback otherwise
              onPressed: isLoading || !canAddMoreAttendees ? null : onAddFamily,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text("Invite Friend"),
              style: OutlinedButton.styleFrom( foregroundColor: AppColors.primaryColor, side: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              // Disable if loading or max size reached, call callback otherwise
              onPressed: isLoading || !canAddMoreAttendees ? null : onInviteFriend,
            ),
          ],
        ),

        // Max group size warning
        if (!canAddMoreAttendees && maxGroupSize != 999)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Text("Maximum group size ($maxGroupSize) reached.",
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
          ),
      ],
    );
  }
}
