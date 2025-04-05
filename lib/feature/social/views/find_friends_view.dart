import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // Import AuthModel
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // Import SocialBloc
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import AppColors if needed
import 'dart:async'; // Import for Timer (debounce)
// For placeholder image data
// Import placeholder builder helper
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart' show buildProfilePlaceholder, transparentImageData;


class FindFriendsView extends StatefulWidget {
  const FindFriendsView({super.key});

  @override
  State<FindFriendsView> createState() => _FindFriendsViewState();
}

class _FindFriendsViewState extends State<FindFriendsView> {
  final _searchController = TextEditingController();
  // *** Store results with status ***
  List<UserSearchResultWithStatus> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';
  Timer? _debounce; // Timer for debouncing search input

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
    super.dispose();
  }


  // Debounced search function
  void _onSearchChanged(String query) {
     // Cancel previous timer if active
     if (_debounce?.isActive ?? false) _debounce!.cancel();
     // Start new timer - wait 500ms after user stops typing
     _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchUsers(query); // Perform search after delay
     });
  }


  void _searchUsers(String query) {
     final trimmedQuery = query.trim();
     // Update state to show loading and clear results immediately if query is not empty
     setState(() {
        _currentQuery = trimmedQuery;
        _isLoading = trimmedQuery.isNotEmpty; // Show loading only if query is not empty
        _searchResults = []; // Clear previous results
     });

     // Dispatch event only if query is not empty
     if (trimmedQuery.isNotEmpty) {
        try {
           // Access SocialBloc provided by parent (e.g., ProfileScreen or FriendsView)
           context.read<SocialBloc>().add(SearchUsers(query: trimmedQuery));
        } catch (e) {
           print("Error accessing SocialBloc: $e");
           // Handle error if Bloc is not available
           if (mounted) {
              setState(() { _isLoading = false; });
              showGlobalSnackBar(context, "Could not perform search.", isError: true);
           }
        }
     }
  }

  /// Dispatches the SendFriendRequest event to the SocialBloc.
  void _sendRequest(AuthModel targetUser) {
     try {
       // Access SocialBloc provided by parent
       context.read<SocialBloc>().add(SendFriendRequest(
          targetUserId: targetUser.uid,
          targetUserName: targetUser.name, // Pass denormalized data
          targetUserPicUrl: targetUser.profilePicUrl ?? targetUser.image, // Pass denormalized data
       ));
       // Provide immediate feedback to the user
       showGlobalSnackBar(context, "Friend request sent to ${targetUser.name}");
       // Update local state to show "Sent" immediately
       setState(() {
          final index = _searchResults.indexWhere((res) => res.user.uid == targetUser.uid);
          if (index != -1) {
             _searchResults[index] = UserSearchResultWithStatus(user: targetUser, status: FriendshipStatus.requestSent);
          }
       });
     } catch (e) {
        print("Error accessing SocialBloc: $e");
        showGlobalSnackBar(context, "Could not send request.", isError: true);
     }
  }

  /// Dispatches the UnsendFriendRequest event to the SocialBloc.
  void _unsendRequest(AuthModel targetUser) {
     try {
       context.read<SocialBloc>().add(UnsendFriendRequest(targetUserId: targetUser.uid));
       showGlobalSnackBar(context, "Friend request cancelled for ${targetUser.name}");
       // Update local state to show "Add" immediately
       setState(() {
          final index = _searchResults.indexWhere((res) => res.user.uid == targetUser.uid);
          if (index != -1) {
             _searchResults[index] = UserSearchResultWithStatus(user: targetUser, status: FriendshipStatus.none);
          }
       });
     } catch (e) { print("Error accessing SocialBloc: $e"); showGlobalSnackBar(context, "Could not cancel request.", isError: true); }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends')),
      // Use BlocListener to update local state based on Bloc state changes
      body: BlocListener<SocialBloc, SocialState>(
        listener: (context, state) {
           // *** Listen for FriendSearchResultsWithStatus ***
           if (state is FriendSearchResultsWithStatus && state.query == _currentQuery) {
              if (mounted) {
                 setState(() {
                    _searchResults = state.results; // Update with results containing status
                    _isLoading = false; // Stop loading when results arrive
                 });
              }
           } else if (state is SocialError && _isLoading && state.message.contains("search")) {
              // Handle search error only if we were loading search results
              if (mounted) { setState(() { _isLoading = false; _searchResults = []; }); }
              showGlobalSnackBar(context, "Error searching users: ${state.message}", isError: true);
           }
           // Listen for general success/error for feedback on actions *initiated here*
           else if (state is SocialSuccess && (state.message.contains("request sent") || state.message.contains("cancelled"))) {
              // Snackbar shown in _sendRequest/_unsendRequest, just log maybe
              print("Bloc Success: ${state.message}");
              // Optionally trigger a re-search to get updated statuses from the Bloc if needed
              // _searchUsers(_currentQuery);
           } else if (state is SocialError && (state.message.contains("send request") || state.message.contains("cancel request"))) {
               showGlobalSnackBar(context, state.message, isError: true); // Show error from Bloc if sending/cancelling failed
           }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GeneralTextFormField(
                controller: _searchController,
                labelText: 'Search Users',
                hintText: 'Enter name or username...',
                textInputAction: TextInputAction.search,
                prefixIcon: const Icon(Icons.search),
                onChanged: _onSearchChanged, // Use debounced search
              ),
            ),
            // Display Loading indicator, No Results message, or the List
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty && _currentQuery.isNotEmpty)
               Expanded(child: Center(child: Padding( padding: const EdgeInsets.all(20.0), child: Text('No users found matching "$_currentQuery".', textAlign: TextAlign.center), )))
            else if (_searchResults.isEmpty && _currentQuery.isEmpty)
               Expanded(child: Center(child: Padding( padding: const EdgeInsets.all(20.0), child: Text('Enter a name or username above to find friends.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)), )))
            else
              // Display search results in a ListView
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 16),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index]; // Now UserSearchResultWithStatus
                    final user = result.user;
                    final status = result.status; // Get status from the result object

                    // Use Squared Photo Logic
                    const double listAvatarSize = 48.0;
                    final listBorderRadius = BorderRadius.circular(10.0);
                    final String profilePicUrl = user.profilePicUrl ?? user.image;
                    Widget leadingWidget = SizedBox(
                       width: listAvatarSize, height: listAvatarSize,
                       child: ClipRRect(
                         borderRadius: listBorderRadius,
                         child: (profilePicUrl.isEmpty)
                             ? buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius) // Use helper
                             : FadeInImage.memoryNetwork(
                                 placeholder: transparentImageData, image: profilePicUrl,
                                 width: listAvatarSize, height: listAvatarSize, fit: BoxFit.cover,
                                 imageErrorBuilder: (context, error, stackTrace) => buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius),
                               ),
                       ),
                    );

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                      leading: leadingWidget, // Use squared photo widget
                      title: Text(user.name, style: theme.textTheme.titleMedium),
                      subtitle: Text("@${user.username}", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)), // Show username
                      // Pass status to button builder
                      trailing: _buildFriendButton(context, theme, user, status),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build the appropriate button based on friend status
  /// Accepts FriendshipStatus enum
  Widget _buildFriendButton(BuildContext context, ThemeData theme, AuthModel targetUser, FriendshipStatus status) {
     final socialBloc = context.read<SocialBloc>(); // Get bloc instance

     // Define common button styles
     final buttonStyle = ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold), minimumSize: const Size(80, 38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), );
     final outlinedButtonStyle = OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold), minimumSize: const Size(80, 38), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), );

     // Determine button based on status
     switch (status) {
        case FriendshipStatus.friends:
           return OutlinedButton( style: outlinedButtonStyle.copyWith(foregroundColor: WidgetStateProperty.all(Colors.grey)), onPressed: null, child: const Text("Friends"), );
        case FriendshipStatus.requestSent:
           // Show Unsend Button
           return OutlinedButton(
              style: outlinedButtonStyle.copyWith(foregroundColor: WidgetStateProperty.all(Colors.orange.shade800), side: WidgetStateProperty.all(BorderSide(color: Colors.orange.shade300))),
              onPressed: () => _unsendRequest(targetUser), // Call unsend handler
              child: const Text("Sent"), // Or "Cancel"? Let's keep "Sent" for now
           );
        case FriendshipStatus.requestReceived:
           return ElevatedButton(
              onPressed: () { socialBloc.add(AcceptFriendRequest( requesterUserId: targetUser.uid, requesterUserName: targetUser.name, requesterUserPicUrl: targetUser.profilePicUrl ?? targetUser.image, )); },
              style: buttonStyle.copyWith(backgroundColor: WidgetStateProperty.all(Colors.green.shade600)),
              child: const Text("Accept"),
           );
        case FriendshipStatus.none:
        default: // Default: Add Friend button
           return ElevatedButton(
              style: buttonStyle,
              onPressed: () => _sendRequest(targetUser),
              child: const Text("Add"),
           );
     }
  }
}

/// Helper to build placeholder (copied from profile_view.dart)
Widget buildProfilePlaceholder(double size, ThemeData theme, BorderRadius borderRadius) {
  return Container( width: size, height: size, decoration: BoxDecoration( color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: borderRadius, border: Border.all( color: theme.colorScheme.primary.withOpacity(0.1), width: 1.0, ), ),
    child: Center( child: Icon( Icons.person_rounded, size: size * 0.6, color: theme.colorScheme.primary.withOpacity(0.4), ), ), );
}

