import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/text_field_templates.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // Import AuthModel
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // Import SocialBloc
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
// Import AppColors
import 'dart:async'; // Import for Timer (debounce)

class FindFriendsView extends StatefulWidget {
  const FindFriendsView({super.key});

  @override
  State<FindFriendsView> createState() => _FindFriendsViewState();
}

class _FindFriendsViewState extends State<FindFriendsView> {
  final _searchController = TextEditingController();
  List<AuthModel> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';
  // Timer for debounce
  Timer? _debounce;

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
     // Start new timer
     _debounce = Timer(const Duration(milliseconds: 500), () { // Wait 500ms after user stops typing
        _searchUsers(query); // Perform search
     });
  }


  void _searchUsers(String query) {
     final trimmedQuery = query.trim();
     // Update state to show loading and clear results immediately if query is not empty
     setState(() {
        _currentQuery = trimmedQuery;
        _isLoading = trimmedQuery.isNotEmpty; // Show loading only if query is not empty
        _searchResults = [];
     });

     // Dispatch event only if query is not empty
     if (trimmedQuery.isNotEmpty) {
        try {
           context.read<SocialBloc>().add(SearchUsers(query: trimmedQuery));
        } catch (e) {
           print("Error accessing SocialBloc: $e");
           // Handle error if Bloc is not available (though unlikely if provided correctly)
           setState(() { _isLoading = false; });
           showGlobalSnackBar(context, "Could not perform search.", isError: true);
        }
     }
  }

  void _sendRequest(AuthModel targetUser) {
     try {
       // Dispatch event to send friend request
       context.read<SocialBloc>().add(SendFriendRequest(
          targetUserId: targetUser.uid,
          targetUserName: targetUser.name,
          targetUserPicUrl: targetUser.profilePicUrl ?? targetUser.image,
       ));
       // Provide immediate feedback
       showGlobalSnackBar(context, "Friend request sent to ${targetUser.name}");
       // Optionally update the button state locally for this user immediately
       // Or wait for BlocListener to potentially update the whole list
       // Example: Mark this user locally as 'requestSent' if managing state here
     } catch (e) {
        print("Error accessing SocialBloc: $e");
        showGlobalSnackBar(context, "Could not send request.", isError: true);
     }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends')),
      // Use BlocListener to handle state changes from Bloc (results, errors)
      body: BlocListener<SocialBloc, SocialState>(
        listener: (context, state) {
           // Listen for search results or errors specifically from search
           // Check if the result corresponds to the current query to avoid race conditions
           if (state is FriendSearchResults && state.query == _currentQuery) {
              setState(() {
                 _searchResults = state.users;
                 _isLoading = false; // Stop loading when results arrive
              });
           } else if (state is SocialError && _isLoading && state.message.contains("search")) {
              // Handle search error only if we were loading search results
              setState(() {
                 _isLoading = false;
                 _searchResults = [];
              });
              showGlobalSnackBar(context, "Error searching users: ${state.message}", isError: true);
           }
           // Optionally listen for SocialSuccess after sending request to update UI/button state
           // else if (state is SocialSuccess && state.message.contains("request sent")) { ... }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GeneralTextFormField(
                controller: _searchController,
                labelText: 'Search Users', // Updated label
                hintText: 'Enter name or username...', // Updated hint
                textInputAction: TextInputAction.search,
                prefixIcon: const Icon(Icons.search),
                // Use onChanged with debounce instead of onFieldSubmitted
                onChanged: _onSearchChanged,
                // onFieldSubmitted: _searchUsers, // Remove if using onChanged debounce
              ),
            ),
            // Display Loading, No Results, or List
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_searchResults.isEmpty && _currentQuery.isNotEmpty)
               Expanded(child: Center(child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text('No users found matching "$_currentQuery".', textAlign: TextAlign.center),
               )))
            else if (_searchResults.isEmpty && _currentQuery.isEmpty)
               Expanded(child: Center(child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text('Enter a name or username above to find friends.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
               )))
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 16), // Add divider
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    // TODO: Check actual friend status (already friends, request sent/received)
                    // This requires loading the current user's friend data (from friends subcollection)
                    // and comparing against the search result user IDs.
                    // For now, using placeholder values.
                    bool alreadyFriends = false; // Placeholder - Replace with actual check
                    bool requestSent = false; // Placeholder - Replace with actual check
                    bool requestReceived = false; // Placeholder - Replace with actual check

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 25, // Consistent avatar size
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty)
                            ? NetworkImage(user.profilePicUrl!)
                            : (user.image.isNotEmpty ? NetworkImage(user.image) : null) as ImageProvider?,
                        child: (user.profilePicUrl == null || user.profilePicUrl!.isEmpty) && user.image.isEmpty
                            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Text(user.name, style: theme.textTheme.titleMedium),
                      subtitle: Text("@${user.username}"), // Show username
                      trailing: _buildFriendButton(context, user, alreadyFriends, requestSent, requestReceived),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the appropriate button based on friend status
  Widget _buildFriendButton(BuildContext context, AuthModel targetUser, bool areFriends, bool sentRequest, bool receivedRequest) {
     // TODO: Replace placeholder bools with actual status check logic
     // This requires fetching and checking the status in the current user's
     // 'friends' subcollection for the targetUser.uid document.

     final theme = Theme.of(context);
     final socialBloc = context.read<SocialBloc>(); // Get bloc instance

     if (areFriends) {
        return OutlinedButton.icon(
           icon: const Icon(Icons.check, size: 16),
           label: const Text("Friends"),
           style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjust padding
           ),
           onPressed: null, // Disabled
        );
     } else if (sentRequest) {
         return OutlinedButton.icon(
           icon: const Icon(Icons.hourglass_top_rounded, size: 16),
           label: const Text("Sent"),
           style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              side: BorderSide(color: Colors.orange.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           ),
           onPressed: null, // Disabled
        );
     } else if (receivedRequest) {
         return ElevatedButton(
            onPressed: () {
               // Dispatch AcceptFriendRequest event
               socialBloc.add(AcceptFriendRequest(
                  requesterUserId: targetUser.uid,
                  requesterUserName: targetUser.name,
                  requesterUserPicUrl: targetUser.profilePicUrl ?? targetUser.image,
               ));
            },
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.green.shade600,
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text("Accept"),
         );
     } else {
         // Default: Add Friend button
         return ElevatedButton.icon(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text("Add"),
            style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               // Use default ElevatedButton theme styling
            ),
            onPressed: () => _sendRequest(targetUser),
         );
     }
  }

}
