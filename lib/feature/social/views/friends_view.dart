import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // Use AppColors
// Use text style helpers
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/views/find_friends_view.dart';
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
    // Load initial data - Ensure SocialBloc is provided above this widget
    // If provided locally in ProfileScreen, it should already be available via context.read
    try {
       context.read<SocialBloc>().add(const LoadFriendsAndRequests());
    } catch (e) {
       print("Error dispatching LoadFriendsAndRequests: $e. Ensure SocialBloc is provided.");
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
        // Use theme settings for AppBar
        // backgroundColor: theme.appBarTheme.backgroundColor,
        // foregroundColor: theme.appBarTheme.foregroundColor,
        // elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Find Friends',
            onPressed: () {
               // Navigate to Find Friends screen
               // Ensure SocialBloc is available to the FindFriendsView
               Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  BlocProvider.value(
                     value: context.read<SocialBloc>(), // Pass the existing Bloc instance
                     child: const FindFriendsView(),
                  )
               ));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary, // Use theme color
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: theme.colorScheme.primary, // Use theme color
          indicatorWeight: 2.5, // Slightly thicker indicator
          labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), // Style for labels
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      // Use BlocListener for side effects (snackbars after accept/decline/remove)
      body: BlocListener<SocialBloc, SocialState>(
         listener: (context, state) {
            if (state is SocialSuccess) {
               showGlobalSnackBar(context, state.message);
            } else if (state is SocialError) {
                showGlobalSnackBar(context, state.message, isError: true);
            }
         },
         // BlocBuilder rebuilds the TabBarView based on state
         child: BlocBuilder<SocialBloc, SocialState>(
           builder: (context, state) {
             // Show loading indicator centered if initial load for friends/requests
             if (state is SocialLoading && state.isLoadingList && state is! FriendsAndRequestsLoaded) {
                return const Center(child: CircularProgressIndicator());
             }
             // Display tabs if data is loaded or if an action is loading (shows previous data)
             if (state is FriendsAndRequestsLoaded || (state is SocialLoading && !state.isLoadingList)) {
                List<Friend> friends = [];
                List<FriendRequest> requests = [];
                bool isActionLoading = state is SocialLoading && !state.isLoadingList;

                // Extract data from current or previous loaded state
                final currentState = state is FriendsAndRequestsLoaded ? state : context.read<SocialBloc>().state;
                if (currentState is FriendsAndRequestsLoaded) {
                   friends = currentState.friends;
                   requests = currentState.incomingRequests;
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Pass loading state to disable buttons during actions
                    _buildFriendsList(context, theme, friends, isActionLoading),
                    _buildRequestsList(context, theme, requests, isActionLoading),
                  ],
                );
             }
              // Show error message if loading list failed
             if (state is SocialError) {
                 return Center(child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Text("Error loading data: ${state.message}", textAlign: TextAlign.center),
                 ));
             }
             // Default/Initial state
             return const Center(child: CircularProgressIndicator()); // Show loader initially
           },
         ),
      ),
    );
  }

  // Widget to build the list of accepted friends
  Widget _buildFriendsList(BuildContext context, ThemeData theme, List<Friend> friends, bool isLoading) {
     if (friends.isEmpty) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("You haven't added any friends yet.\nTap the '+' icon to find friends.", textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        ));
     }
     return RefreshIndicator(
        onRefresh: () async => context.read<SocialBloc>().add(const LoadFriendsAndRequests()),
        color: theme.colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Add padding around list
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card( // Wrap ListTile in a Card
              margin: const EdgeInsets.symmetric(vertical: 6.0), // Space between cards
              elevation: 1.5, // Subtle elevation
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Padding inside ListTile
                leading: CircleAvatar(
                   radius: 25, // Slightly larger avatar
                   backgroundColor: theme.colorScheme.primaryContainer,
                   backgroundImage: (friend.profilePicUrl != null && friend.profilePicUrl!.isNotEmpty)
                      ? NetworkImage(friend.profilePicUrl!) : null,
                   child: (friend.profilePicUrl == null || friend.profilePicUrl!.isEmpty)
                      ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                ),
                title: Text(friend.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                   "Friend since: ${friend.friendedAt?.toDate().toString().split(' ')[0] ?? 'N/A'}", // Format date
                   style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                trailing: IconButton(
                   icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade400),
                   tooltip: 'Remove Friend',
                   // Disable button if an action is loading elsewhere
                   onPressed: isLoading ? null : () {
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

  // Widget to build the list of incoming friend requests
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
            return Card( // Wrap in Card
               margin: const EdgeInsets.symmetric(vertical: 6.0),
               elevation: 1.5,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
               child: ListTile(
                 contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                 leading: CircleAvatar(
                   radius: 25,
                   backgroundColor: theme.colorScheme.primaryContainer,
                   backgroundImage: (request.profilePicUrl != null && request.profilePicUrl!.isNotEmpty)
                      ? NetworkImage(request.profilePicUrl!) : null,
                   child: (request.profilePicUrl == null || request.profilePicUrl!.isEmpty)
                      ? Text(request.name.isNotEmpty ? request.name[0].toUpperCase() : '?') : null,
                ),
                title: Text(request.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text("Wants to be your friend", style: theme.textTheme.bodySmall),
                trailing: isLoading // Show spinner if action is loading
                   ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                   : Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        // Accept Button (Circular Style)
                        InkWell(
                           onTap: () {
                              context.read<SocialBloc>().add(AcceptFriendRequest(
                                 requesterUserId: request.userId,
                                 requesterUserName: request.name,
                                 requesterUserPicUrl: request.profilePicUrl,
                              ));
                           },
                           borderRadius: BorderRadius.circular(20),
                           child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                 color: Colors.green.withOpacity(0.15),
                                 shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded, color: Colors.green.shade700, size: 20),
                           ),
                        ),
                        const SizedBox(width: 8),
                        // Decline Button (Circular Style)
                        InkWell(
                           onTap: () {
                              context.read<SocialBloc>().add(DeclineFriendRequest(requesterUserId: request.userId));
                           },
                           borderRadius: BorderRadius.circular(20),
                           child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                 color: Colors.red.withOpacity(0.1),
                                 shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, color: Colors.red.shade600, size: 20),
                           ),
                        ),
                     ],
                  ),
               ),
            );
          },
        ),
     );
  }

}

// Helper for placeholder image data (if needed and not imported globally)
// final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);
