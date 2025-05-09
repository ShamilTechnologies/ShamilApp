// lib/feature/details/widgets/reservation_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart'; // Keep for dialogs
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/details/widgets/attendee_section.dart';
import 'package:shamil_mobile_app/feature/details/widgets/dynamic_reservation_form.dart';

// Import Updated Model
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Import Reservation Bloc & State
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_bloc.dart';

// Import Reservation Models (AttendeeModel, ReservationType etc)
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';

// Import SocialBloc and models for dialogs
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
// Import Friend model (ensure correct path or definition)
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Orchestrates the display of the reservation form, including type selection,
/// dynamic form fields, attendee management, and confirmation.
/// Reads data from the provided [ReservationState].
class ReservationPanel extends StatelessWidget {
  final ThemeData theme;
  // final ServiceProviderModel provider; // <<< THIS PARAMETER IS REMOVED
  final ReservationState state; // Accepts the full Bloc state
  final bool
      isLoading; // General loading flag from parent (e.g., sheet opening)
  final bool isHybrid; // To conditionally show title

  const ReservationPanel({
    super.key,
    required this.theme,
    // required this.provider, // <<< THIS LINE IS REMOVED
    required this.state, // Accept state object
    required this.isLoading,
    required this.isHybrid,
  });

  /// Shows a dialog to select family members.
  void _showFamilySelector(
      BuildContext context, List<AttendeeModel> currentAttendees, ServiceProviderModel currentProvider) { // Requires provider context now
    final socialBloc = context.read<SocialBloc>();
    final reservationBloc = context.read<ReservationBloc>();
    final maxGroupSize = currentProvider.maxGroupSize; // Get from provider

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
                                  value: false, // Checkbox starts unchecked
                                  enabled: canAddMore,
                                  activeColor: theme.colorScheme.primary, // Use theme color
                                  onChanged: canAddMore
                                      ? (bool? selected) {
                                          if (selected == true) {
                                            // Dispatch AddAttendee event
                                            reservationBloc.add(AddAttendee(
                                                attendee: AttendeeModel(
                                              userId: familyMember.userId!,
                                              name: familyMember.name,
                                              type: 'family',
                                              status: 'going', // Family members are 'going' by default
                                            )));
                                            Navigator.of(dialogContext).pop(); // Close dialog after selection
                                          }
                                        }
                                      : null, // Disable checkbox if cannot add more
                                );
                              },
                            ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  // Show max group size warning if applicable
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
      BuildContext context, List<AttendeeModel> currentAttendees, ServiceProviderModel currentProvider) { // Requires provider context now
     final socialBloc = context.read<SocialBloc>();
     final reservationBloc = context.read<ReservationBloc>();
     final maxGroupSize = currentProvider.maxGroupSize; // Get from provider

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
                                   value: false, // Checkbox starts unchecked
                                   enabled: canAddMore,
                                   activeColor: theme.colorScheme.primary,
                                   onChanged: canAddMore
                                       ? (bool? selected) {
                                           if (selected == true) {
                                             // Dispatch AddAttendee with 'invited' status
                                             reservationBloc.add(AddAttendee(
                                                 attendee: AttendeeModel(
                                               userId: friend.userId,
                                               name: friend.name,
                                               type: 'friend',
                                               status: 'invited', // Friend status starts as 'invited'
                                             )));
                                             Navigator.of(dialogContext).pop(); // Close dialog
                                           }
                                         }
                                       : null, // Disable if max size reached
                                 );
                               },
                             ),
                 ),
                 actionsAlignment: MainAxisAlignment.spaceBetween,
                 actions: [
                   // Show max group size warning if applicable
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
    // *** Get provider from the STATE ***
    final currentProvider = state.provider;
    // Handle the case where provider might be null (e.g., during initial error)
    if (currentProvider == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("Error: Provider details are unavailable.", textAlign: TextAlign.center),
      ));
    }

    // Get data derived from the state and the provider within it
    final supportedTypes = currentProvider.supportedReservationTypes
        .map((s) => reservationTypeFromString(s))
        .where((t) => t != ReservationType.unknown)
        .toList();
    final currentSelectedType = state.selectedReservationType;
    final attendees = state.selectedAttendees;
    final maxGroupSize = currentProvider.maxGroupSize ?? 999; // Use provider from state
    final bool isProcessing = isLoading || state is ReservationCreating;

    // Determine slotsLoading safely by CHECKING the state type
    final bool slotsAreCurrentlyLoading = state is ReservationDateSelected && (state as ReservationDateSelected).isLoadingSlots;

    // Determine errorMessage safely by CHECKING the state type
    final String? errorMessage = state is ReservationError ? (state as ReservationError).message : null;

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
        // Render the form only if a type is selected or implicitly known (if only one type supported)
        if (currentSelectedType != null)
          DynamicReservationForm(
            theme: theme,
            state: state, // Pass the full current state
            isLoading: isProcessing,
            slotsCurrentlyLoading: slotsAreCurrentlyLoading, // Pass the safe boolean
            type: currentSelectedType,
            onTimeRangeSelected: (start, end) {
              if (!isProcessing) {
                context
                    .read<ReservationBloc>()
                    .add(UpdateSwipeSelection(startTime: start, endTime: end));
              }
            },
          )
        else if (supportedTypes.length > 1) // Show prompt only if multiple types exist and none selected
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text("Please select a reservation type above.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary)),
            ),
          )
        else if (supportedTypes.isEmpty && !isHybrid) // Handle case where reservation enabled but no types configured
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text("No reservation types configured by provider.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary)),
            ),
          ),


        // --- 4. Attendees Section ---
        // Render only if a type is selected
        if (currentSelectedType != null) ...[
          const Gap(24),
          AttendeeSection(
            theme: theme,
            attendees: attendees,
            maxGroupSize: maxGroupSize,
            isLoading: isProcessing,
            // Pass the provider from state to the dialog launchers
            onAddFamily: () => _showFamilySelector(context, attendees, currentProvider),
            onInviteFriend: () => _showFriendSelector(context, attendees, currentProvider),
          ),
           const Gap(32),
        ],


        // --- Error Display & Confirmation Button ---
        // Render only if a type is selected
        if (currentSelectedType != null) ... [
           // Display error message if present and not currently creating
           if (errorMessage != null && state is! ReservationCreating)
             Padding(
               padding: const EdgeInsets.only(bottom: 16.0),
               child: Center(
                   child: Text(
                 errorMessage,
                 style: TextStyle(color: theme.colorScheme.error),
                 textAlign: TextAlign.center,
               )),
             ),
           // Confirmation Button
           Center(
             child: CustomButton(
               text: state is ReservationCreating ? 'Booking...' : 'Confirm Reservation',
               // Check readiness using the Bloc helper method
               onPressed: context.read<ReservationBloc>().isReservationReadyToConfirm(state, currentSelectedType) && !isProcessing
                   ? () => context.read<ReservationBloc>().add(const CreateReservation())
                   : null, // Button is disabled if not ready or processing
             ),
           ),
        ],

        const Gap(20), // Bottom padding
      ],
    );
  }
}