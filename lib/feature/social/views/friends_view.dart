import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
// Import text style helpers
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/views/find_friends_view.dart'; // Import Find Friends screen
// For navigation
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'dart:typed_data'; // For placeholder image data if needed locally

// Placeholder for transparent image data (if not imported globally)
const kTransparentImage = <int>[ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, ];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tabs: Friends, Requests
    // Load initial data - Assumes SocialBloc provided above this widget
    try {
       // Request data load when the screen initializes
       context.read<SocialBloc>().add(const LoadFriendsAndRequests());
    } catch (e) {
       print("Error dispatching LoadFriendsAndRequests from FriendsView initState: $e. Ensure SocialBloc is provided.");
       // Optionally show a snackbar if Bloc is missing
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
             showGlobalSnackBar(context, "Could not load friends data.", isError: true);
          }
       });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          // Button to navigate to Find Friends screen
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Find Friends',
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  BlocProvider.value( // Pass the existing SocialBloc instance
                     value: context.read<SocialBloc>(),
                     child: const FindFriendsView(),
                  )
               ));
            },
          ),
        ],
        // TabBar for switching between Friends and Requests lists
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2.5,
          labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'My Friends'),
            // Tab for Requests, potentially showing a badge with the count
            Tab(
               child: BlocBuilder<SocialBloc, SocialState>( // Badge Example
                  builder: (context, state) {
                     int requestCount = 0;
                     // Get count from the loaded state
                     if (state is FriendsAndRequestsLoaded) {
                        requestCount = state.incomingRequests.length;
                     }
                     // Build the tab label with an optional badge
                     return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Text('Requests'),
                           // Show badge only if count > 0
                           if (requestCount > 0) ...[
                              const SizedBox(width: 6),
                              CircleAvatar(
                                 radius: 9, // Slightly larger badge
                                 backgroundColor: AppColors.redColor, // Use app's red color
                                 child: Text(
                                    requestCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold) // Make text bold
                                 ),
                              )
                           ]
                        ],
                     );
                  }
               )
            ),
          ],
        ),
      ),
      // Use MultiBlocListener for handling side effects from SocialBloc
      body: MultiBlocListener(
         listeners: [
            BlocListener<SocialBloc, SocialState>(
               listener: (context, state) {
                  // Show snackbar feedback for success/error messages
                  if (state is SocialSuccess) { showGlobalSnackBar(context, state.message); }
                  else if (state is SocialError) { showGlobalSnackBar(context, state.message, isError: true); }
               },
            ),
         ],
         // Use BlocBuilder to display content based on SocialBloc state
         child: BlocBuilder<SocialBloc, SocialState>(
           builder: (context, state) {
             // Show loading indicator during initial list load
             if (state is SocialLoading && state.isLoadingList && state is! FriendsAndRequestsLoaded) {
                return const Center(child: CircularProgressIndicator());
             }
             // Display TabBarView when data is loaded or an action is in progress
             if (state is FriendsAndRequestsLoaded || (state is SocialLoading && !state.isLoadingList)) {
                List<Friend> friends = [];
                List<FriendRequest> requests = [];
                bool isActionLoading = state is SocialLoading && !state.isLoadingList;

                // Extract data safely from current or previous loaded state
                // Use context.watch or context.select for more targeted rebuilds if needed
                final currentState = context.read<SocialBloc>().state;
                if (currentState is FriendsAndRequestsLoaded) {
                   friends = currentState.friends;
                   requests = currentState.incomingRequests;
                }

                // Build the TabBarView with the two list widgets
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsList(context, theme, friends, isActionLoading),
                    _buildRequestsList(context, theme, requests, isActionLoading),
                  ],
                );
             }
              // Show error message if loading the list failed
             if (state is SocialError) {
                 return Center(child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Text("Error loading data: ${state.message}", textAlign: TextAlign.center),
                 ));
             }
             // Default state (usually initial)
             return const Center(child: CircularProgressIndicator());
           },
         ),
      ),
    );
  }

  /// Builds the list widget for accepted friends.
  Widget _buildFriendsList(BuildContext context, ThemeData theme, List<Friend> friends, bool isLoading) {
     if (friends.isEmpty) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
             "You haven't added any friends yet.\nTap the '+' icon above to find friends.",
             textAlign: TextAlign.center,
             style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)
          ),
        ));
     }
     // Use RefreshIndicator for pull-to-refresh
     return RefreshIndicator(
        onRefresh: () async => context.read<SocialBloc>().add(const LoadFriendsAndRequests()),
        color: theme.colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            // Build a Card for each friend
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: CircleAvatar(
                   radius: 25,
                   backgroundColor: theme.colorScheme.primaryContainer,
                   // Use FadeInImage for friend's avatar
                   backgroundImage: (friend.profilePicUrl != null && friend.profilePicUrl!.isNotEmpty)
                      ? NetworkImage(friend.profilePicUrl!) : null,
                   // Show initial if no image
                   child: (friend.profilePicUrl == null || friend.profilePicUrl!.isEmpty)
                      ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                ),
                title: Text(friend.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                   // Format the timestamp nicely
                   "Friend since: ${friend.friendedAt != null ? MaterialLocalizations.of(context).formatShortDate(friend.friendedAt!.toDate()) : 'N/A'}",
                   style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                // Remove Friend Button
                trailing: IconButton(
                   icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade400),
                   tooltip: 'Remove Friend',
                   // Disable button if an action is loading elsewhere on the screen
                   onPressed: isLoading ? null : () {
                      // Confirmation Dialog
                      showDialog(context: context, builder: (ctx) => AlertDialog(
                         title: const Text("Confirm Removal"), content: Text("Remove ${friend.name} from your friends?"),
                         actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                            TextButton(onPressed: () {
                               context.read<SocialBloc>().add(RemoveFriend(friendUserId: friend.userId));
                               Navigator.of(ctx).pop();
                            }, child: const Text("Remove", style: TextStyle(color: AppColors.redColor))),
                         ],
                      ));
                   },
                ),
              ),
            );
          },
        ),
     );
  }

  /// Builds the list widget for incoming friend requests.
  Widget _buildRequestsList(BuildContext context, ThemeData theme, List<FriendRequest> requests, bool isLoading) {
     if (requests.isEmpty) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("No incoming friend requests.", textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        ));
     }
     return RefreshIndicator(
        onRefresh: () async => context.read<SocialBloc>().add(const LoadFriendsAndRequests()),
        color: theme.colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
               margin: const EdgeInsets.symmetric(vertical: 6.0),
               elevation: 1.5,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Padding inside card
                 child: Row( // Use Row for more control over layout
                   children: [
                     // Avatar
                     CircleAvatar(
                       radius: 25,
                       backgroundColor: theme.colorScheme.primaryContainer,
                       backgroundImage: (request.profilePicUrl != null && request.profilePicUrl!.isNotEmpty)
                          ? NetworkImage(request.profilePicUrl!) : null,
                       child: (request.profilePicUrl == null || request.profilePicUrl!.isEmpty)
                          ? Text(request.name.isNotEmpty ? request.name[0].toUpperCase() : '?') : null,
                     ),
                     const SizedBox(width: 16),
                     // Name and Subtitle
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(request.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                           const SizedBox(height: 2),
                           Text("Wants to be your friend", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                         ],
                       ),
                     ),
                     const SizedBox(width: 8),
                     // Action Buttons (Rounded Squares)
                     if (isLoading) // Show spinner if action is loading elsewhere
                       const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                     else ...[ // Use spread operator for buttons
                       _buildRequestActionButton( // Accept Button
                          context: context, theme: theme, icon: Icons.check_rounded,
                          color: Colors.green, tooltip: 'Accept',
                          onTap: () {
                             context.read<SocialBloc>().add(AcceptFriendRequest(
                                requesterUserId: request.userId,
                                requesterUserName: request.name, // Pass denormalized data
                                requesterUserPicUrl: request.profilePicUrl,
                             ));
                          }
                       ),
                       const SizedBox(width: 8), // Space between buttons
                       _buildRequestActionButton( // Decline Button
                          context: context, theme: theme, icon: Icons.close_rounded,
                          color: Colors.red, tooltip: 'Decline',
                          onTap: () {
                             context.read<SocialBloc>().add(DeclineFriendRequest(requesterUserId: request.userId));
                          }
                       ),
                     ]
                   ],
                 ),
               ),
            );
          },
        ),
     );
  }

  /// Helper to build rounded square action buttons for requests.
  Widget _buildRequestActionButton({
     required BuildContext context, required ThemeData theme, required IconData icon,
     required Color color, required String tooltip, required VoidCallback onTap
  }) {
     return Tooltip( // Add tooltip for accessibility
       message: tooltip,
       child: Material( // Use Material for shape, color, InkWell
          color: color.withOpacity(0.15), // Background color
          borderRadius: BorderRadius.circular(8.0), // Rounded square
          child: InkWell(
             onTap: onTap,
             borderRadius: BorderRadius.circular(8.0),
             splashColor: color.withOpacity(0.3),
             highlightColor: color.withOpacity(0.2),
             child: Padding(
               padding: const EdgeInsets.all(8.0), // Padding inside button
               child: Icon(icon, color: color, size: 20), // Icon color
             ),
          ),
       ),
     );
  }

}

// Helper for placeholder image data (if needed and not imported globally)
// final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);
