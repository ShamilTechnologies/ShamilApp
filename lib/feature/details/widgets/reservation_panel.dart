// lib/feature/details/widgets/reservation_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // Keep for dialogs
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/details/widgets/attendee_section.dart';
import 'package:shamil_mobile_app/feature/details/widgets/dynamic_reservation_form.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
// Import SocialBloc and models for dialogs
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Orchestrates the display of the reservation form, including type selection,
/// dynamic form fields, attendee management, and confirmation.
/// Reads data from the provided [ReservationState].
class ReservationPanel extends StatelessWidget {
  final ThemeData theme;
  final ServiceProviderModel provider;
  final ReservationState state; // Accepts the full Bloc state
  final bool
      isLoading; // General loading flag from parent (e.g., sheet opening)
  final bool isHybrid; // To conditionally show title

  const ReservationPanel({
    super.key,
    required this.theme,
    required this.provider,
    required this.state, // Accept state object
    required this.isLoading,
    required this.isHybrid,
  });

  /// Shows a dialog to select family members.
  void _showFamilySelector(
      BuildContext context, List<AttendeeModel> currentAttendees) {
    // ... (Implementation remains the same) ...
    final socialBloc = context.read<SocialBloc>();
    final reservationBloc = context.read<ReservationBloc>();
    final maxGroupSize = provider.maxGroupSize;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: socialBloc,
          child: BlocBuilder<SocialBloc, SocialState>(
            builder: (ctx, socialState) {
              List<FamilyMember> availableFamily = [];
              if (socialState is FamilyDataLoaded) {
                final currentAttendeeIds =
                    currentAttendees.map((a) => a.userId).toSet();
                availableFamily = socialState.familyMembers
                    .where((fm) =>
                        fm.status == 'accepted' &&
                        fm.userId != null &&
                        !currentAttendeeIds.contains(fm.userId!))
                    .toList();
              }
              bool canAddMore = maxGroupSize == null ||
                  currentAttendees.length < maxGroupSize;
              bool isLoadingSocial =
                  socialState is SocialLoading && socialState.isLoadingList;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                title: const Text("Add Family Members"),
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: isLoadingSocial
                      ? const Center(child: CircularProgressIndicator())
                      : (availableFamily.isEmpty)
                          ? Center(
                              child: Text(
                                  "No other accepted family members found.",
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableFamily.length,
                              itemBuilder: (listCtx, index) {
                                final familyMember = availableFamily[index];
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(familyMember.name),
                                  subtitle: Text(familyMember.relationship),
                                  value: false,
                                  enabled: canAddMore,
                                  activeColor: theme.primaryColor,
                                  onChanged: canAddMore
                                      ? (bool? selected) {
                                          if (selected == true) {
                                            reservationBloc.add(AddAttendee(
                                                attendee: AttendeeModel(
                                              userId: familyMember.userId!,
                                              name: familyMember.name,
                                              type: 'family',
                                              status: 'going',
                                            )));
                                            Navigator.of(dialogContext).pop();
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  if (!canAddMore && maxGroupSize != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text("Max group size ($maxGroupSize) reached.",
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 12)),
                    ),
                  TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text("Close",
                          style:
                              TextStyle(color: theme.colorScheme.secondary))),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Shows a dialog to select friends to invite.
  void _showFriendSelector(
      BuildContext context, List<AttendeeModel> currentAttendees) {
    // ... (Implementation remains the same) ...
    final socialBloc = context.read<SocialBloc>();
    final reservationBloc = context.read<ReservationBloc>();
    final maxGroupSize = provider.maxGroupSize;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: socialBloc,
          child: BlocBuilder<SocialBloc, SocialState>(
            builder: (ctx, socialState) {
              List<Friend> availableFriends = [];
              if (socialState is FriendsAndRequestsLoaded) {
                final currentAttendeeIds =
                    currentAttendees.map((a) => a.userId).toSet();
                availableFriends = socialState.friends
                    .where((f) => !currentAttendeeIds.contains(f.userId))
                    .toList();
              }
              bool canAddMore = maxGroupSize == null ||
                  currentAttendees.length < maxGroupSize;
              bool isLoadingSocial =
                  socialState is SocialLoading && socialState.isLoadingList;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                title: const Text("Invite Friends"),
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: isLoadingSocial
                      ? const Center(child: CircularProgressIndicator())
                      : (availableFriends.isEmpty)
                          ? Center(
                              child: Text("No other friends found.",
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableFriends.length,
                              itemBuilder: (listCtx, index) {
                                final friend = availableFriends[index];
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(friend.name),
                                  value: false,
                                  enabled: canAddMore,
                                  activeColor: theme.primaryColor,
                                  onChanged: canAddMore
                                      ? (bool? selected) {
                                          if (selected == true) {
                                            reservationBloc.add(AddAttendee(
                                                attendee: AttendeeModel(
                                              userId: friend.userId,
                                              name: friend.name,
                                              type: 'friend',
                                              status: 'invited',
                                            )));
                                            Navigator.of(dialogContext).pop();
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  if (!canAddMore && maxGroupSize != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text("Max group size ($maxGroupSize) reached.",
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 12)),
                    ),
                  TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text("Close",
                          style:
                              TextStyle(color: theme.colorScheme.secondary))),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get data directly from the state object passed in
    final supportedTypes = provider.supportedReservationTypes
        .map((s) => reservationTypeFromString(s))
        .where((t) => t != ReservationType.unknown)
        .toList();
    final currentSelectedType = state.selectedReservationType;
    final attendees = state.selectedAttendees;
    final maxGroupSize = provider.maxGroupSize ?? 999;
    final bool isProcessing = isLoading || state is ReservationCreating;

    // *** FIX: Determine slotsLoading safely based on the ACTUAL state type ***
    final bool slotsAreCurrentlyLoading = (state is ReservationDateSelected)
        ? (state as ReservationDateSelected).isLoadingSlots
        : false; // Default to false if not in DateSelected state

    // *** FIX: Determine errorMessage safely based on ACTUAL state type ***
    final String? errorMessage = (state is ReservationError)
        ? (state as ReservationError).message
        : null; // Null if not in error state

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Section Title (Only if not Hybrid) ---
        if (!isHybrid)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Book Reservation",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),

        // --- 1. Reservation Type Selection (If multiple supported) ---
        if (supportedTypes.length > 1) ...[
          Text("1. Select Reservation Type:",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: supportedTypes.map((type) {
              final bool isSelected = currentSelectedType == type;
              return ChoiceChip(
                label: Text(type.displayString),
                selected: isSelected,
                onSelected: isProcessing
                    ? null
                    : (selected) {
                        if (selected) {
                          context.read<ReservationBloc>().add(
                              SelectReservationType(reservationType: type));
                        }
                      },
                selectedColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal),
                backgroundColor: AppColors.primaryColor.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.grey.shade300)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const Gap(24),
        ],

        // --- 2. & 3. Dynamic Reservation Form ---
        if (currentSelectedType != null)
          DynamicReservationForm(
            theme: theme,
            provider: provider,
            state: state,
            isLoading: isProcessing,
            slotsCurrentlyLoading:
                slotsAreCurrentlyLoading, // Pass the safe boolean
            type: currentSelectedType,
            onTimeRangeSelected: (start, end) {
              if (!isProcessing) {
                context
                    .read<ReservationBloc>()
                    .add(UpdateSwipeSelection(startTime: start, endTime: end));
              }
            },
          )
        else if (supportedTypes.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text("Please select a reservation type above.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary)),
            ),
          ),

        // --- 4. Attendees Section ---
        const Gap(24),
        AttendeeSection(
          theme: theme,
          attendees: attendees,
          maxGroupSize: maxGroupSize,
          isLoading: isProcessing,
          onAddFamily: () => _showFamilySelector(context, attendees),
          onInviteFriend: () => _showFriendSelector(context, attendees),
        ),

        // --- Error Display & Confirmation Button ---
        const Gap(32),
        // *** FIX: Use the safely determined errorMessage ***
        if (errorMessage != null &&
            state
                is! ReservationCreating) // Avoid showing old errors during creation
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(
                child: Text(
              errorMessage,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            )),
          ),
        Center(
          child: CustomButton(
            text: state is ReservationCreating
                ? 'Booking...'
                : 'Confirm Reservation',
            onPressed: context
                        .read<ReservationBloc>()
                        .isReservationReadyToConfirm(
                            state, currentSelectedType) &&
                    !isProcessing
                ? () => context
                    .read<ReservationBloc>()
                    .add(const CreateReservation())
                : null,
          ),
        ),
        const Gap(20), // Bottom padding
      ],
    );
  }
}
