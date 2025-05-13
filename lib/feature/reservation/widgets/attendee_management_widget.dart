// lib/feature/reservation/presentation/widgets/attendee_management_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';

class AttendeeManagementWidget extends StatelessWidget {
  final List<AttendeeModel> attendees;
  final Function(String) onRemoveAttendee;
  final Function() onAddFamilyMember;
  final Function() onAddFriend;
  final int maxCapacity;
  final bool isHostingEnabled;
  final String? venueCategory;
  
  const AttendeeManagementWidget({
    super.key,
    required this.attendees,
    required this.onRemoveAttendee,
    required this.onAddFamilyMember,
    required this.onAddFriend,
    required this.maxCapacity,
    this.isHostingEnabled = false,
    this.venueCategory,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canAddMore = attendees.length < maxCapacity;
    final bool isSportOrFitness = venueCategory == 'Sports' || 
                                venueCategory == 'Fitness' ||
                                venueCategory == 'Entertainment';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendee selection title and counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Attendees", 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
            ),
            Text(
              "${attendees.length}/${maxCapacity == 999 ? '∞' : maxCapacity}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary, 
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
        const Gap(16),
        
        // Attendee list (if any)
        if (attendees.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.onSecondaryContainer)
                  ),
                ),
                title: Text(attendee.name),
                subtitle: Row(
                  children: [
                    Text(
                      attendee.type == 'self' 
                          ? 'You' 
                          : _capitalizeFirstLetter(attendee.type),
                      style: theme.textTheme.bodySmall,
                    ),
                    const Gap(8),
                    _buildPaymentStatusChip(context, attendee),
                  ],
                ),
                trailing: attendee.type != 'self'
                  ? IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.error),
                      onPressed: () => onRemoveAttendee(attendee.userId),
                    )
                  : null,
              );
            },
          ),
        
        const Gap(16),
        
        // Add attendee buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.group),
                label: const Text("Family"),
                onPressed: canAddMore ? onAddFamilyMember : null,
              ),
            ),
            const Gap(8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Friends"),
                onPressed: canAddMore ? onAddFriend : null,
              ),
            ),
          ],
        ),
        
        // Hosting option (if eligible category)
        if (isHostingEnabled && isSportOrFitness && canAddMore) ...[
          const Gap(16),
          const Divider(),
          const Gap(8),
          OutlinedButton.icon(
            icon: const Icon(Icons.public),
            label: const Text("Host this Reservation"),
            onPressed: () {
              // Show hosting dialog
              _showHostingDialog(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const Gap(8),
          Text(
            "Make your reservation visible to the community and let others join",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary.withOpacity(0.7)
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        // Warning for max capacity
        if (!canAddMore) ...[
          const Gap(8),
          Text(
            "Maximum capacity reached",
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
  
  Widget _buildPaymentStatusChip(BuildContext context, AttendeeModel attendee) {
    final theme = Theme.of(context);
    
    Color chipColor;
    String statusText;
    
    switch (attendee.paymentStatus) {
      case PaymentStatus.pending:
        chipColor = Colors.orange;
        statusText = "Pending";
        break;
      case PaymentStatus.partial:
        chipColor = Colors.blue;
        statusText = "Partial";
        break;
      case PaymentStatus.complete:
        chipColor = Colors.green;
        statusText = "Paid";
        break;
      case PaymentStatus.hosted:
        chipColor = Colors.purple;
        statusText = "Hosted";
        break;
      case PaymentStatus.waived:
        chipColor = Colors.grey;
        statusText = "Waived";
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor.withOpacity(0.5))
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w500
        ),
      ),
    );
  }
  
  void _showHostingDialog(BuildContext context) {
    // Implementation for hosting dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Host This Reservation"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Description (visible to others)",
                hintText: "E.g., Join me for a friendly tennis match!"
              ),
              maxLines: 3,
            ),
            Gap(16),
            Text(
              "This will make your reservation visible to the community. Others can request to join and you can approve or deny requests.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement hosting logic
            },
            child: const Text("Make Public"),
          ),
        ],
      ),
    );
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}