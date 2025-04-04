import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/views/add_family_member_view.dart';
// Import the list tile builders
import 'family_list_tiles.dart';

class FamilySection extends StatelessWidget {
  const FamilySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // This widget assumes SocialBloc is provided by an ancestor (ProfileScreen)
    // It reads the bloc instance using context.read when needed for actions.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Family Members", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary, size: 28),
              tooltip: "Add Family Member",
              onPressed: () {
                // Navigate providing the SocialBloc instance from this context
                Navigator.push(context, MaterialPageRoute(builder: (_) =>
                   BlocProvider.value(
                      value: context.read<SocialBloc>(), // Pass existing bloc
                      child: const AddFamilyMemberView(),
                   )
                ));
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // BlocBuilder for SocialBloc to display family list or status
        BlocBuilder<SocialBloc, SocialState>(
          builder: (context, state) {
            // Loading state specifically for the family list part
            if (state is SocialLoading && state.isLoadingList && state is! FamilyDataLoaded) {
               return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
            }
            // Display list when FamilyDataLoaded state is emitted
            if (state is FamilyDataLoaded) {
               // Handle empty state for both members and requests
               if (state.familyMembers.isEmpty && state.incomingRequests.isEmpty) {
                  return Center(child: Padding( padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No family members or requests yet.", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)), ));
               }
               // Build Column containing requests and then accepted/external members
               return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Incoming Requests Section (if any)
                     if (state.incomingRequests.isNotEmpty) ...[
                        Padding( padding: const EdgeInsets.only(top: 10.0, bottom: 5.0), child: Text("Incoming Requests", style: theme.textTheme.titleMedium), ),
                        // Use spread operator for list generation using the helper
                        ...state.incomingRequests.map((request) => buildFamilyRequestTile(context, theme, request)),
                        const SizedBox(height: 15), const Divider(), const SizedBox(height: 10),
                     ],
                     // Accepted / External Members Section Title (if any members)
                      if (state.familyMembers.isNotEmpty)
                         Padding( padding: const EdgeInsets.only(bottom: 5.0), child: Text("Members", style: theme.textTheme.titleMedium), ),
                     // Use spread operator for list generation using the helper
                     ...state.familyMembers.map((member) => buildFamilyMemberTile(context, theme, member)),
                  ]
               );
            }
            // Display error if loading family failed
            if (state is SocialError) {
               return Center(child: Padding( padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("Error loading family: ${state.message}"), ));
            }
            // Default empty state or placeholder while waiting for initial load
            return const SizedBox(height: 50);
          },
        ),
      ],
    );
  }
}
