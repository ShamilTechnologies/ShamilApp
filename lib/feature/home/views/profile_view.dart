import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/core/functions/navigation.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/core/widgets/actionScreens.dart'; // For LoadingScreen
import 'dart:typed_data'; // Import for Uint8List for placeholder

// Import Social Bloc, State, Event, Model and Add View
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/social/views/add_family_member_view.dart';
// *** FIX: Added missing import for FriendsView ***
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart';


// Placeholder for transparent image data
const kTransparentImage = <int>[ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, ];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUpdatingPicture = false; // Local flag for picture update loading state
  late final SocialBloc _socialBloc; // Bloc for family/friends data

  @override
  void initState() {
    super.initState();
    // Initialize SocialBloc locally for this screen
    // Consider providing globally if needed elsewhere
    _socialBloc = SocialBloc();
    // Load initial social data (family members)
    _socialBloc.add(const LoadFamilyMembers());
    // Optionally load friends data here too if needed immediately
    // _socialBloc.add(const LoadFriendsAndRequests());
  }

  @override
  void dispose() {
    _socialBloc.close(); // Dispose the local Bloc instance
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<ImageSource?> _showImageSourceSelector() async {
     // Shows a bottom sheet to choose Camera or Gallery
     return showModalBottomSheet<ImageSource>(
      context: context, backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container( margin: const EdgeInsets.all(16.0), padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration( color:AppColors.white, borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [ BoxShadow( color: Colors.black26, blurRadius: 10, offset: Offset(0, 5), ), ],
          ),
          child: Column( mainAxisSize: MainAxisSize.min, children: [
              Text( 'Choose Image Source', style: getbodyStyle( color: AppColors.primaryColor, fontSize: 18, fontWeight: FontWeight.bold, ), ),
              const SizedBox(height: 10),
              ListTile( leading: const Icon(Icons.camera_alt, color: AppColors.primaryColor), title: Text('Camera', style: getbodyStyle(color: AppColors.primaryColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ), const Divider(),
              ListTile( leading: const Icon(Icons.photo, color: AppColors.primaryColor), title: Text('Gallery', style: getbodyStyle(color: AppColors.primaryColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ), ],
          ),
        );
       }
    );
   }

  Future<void> _pickAndUpdateProfilePicture() async {
    // Prevents starting a new upload if one is already in progress
    if (_isUpdatingPicture) return;

    final source = await _showImageSourceSelector();
    if (source == null) return; // User cancelled selection

    try {
       // Pick image using image_picker
       final pickedImage = await _picker.pickImage( source: source, imageQuality: 80, maxWidth: 1024, );
       if (pickedImage != null && mounted) {
         // Set local loading flag to show indicator on avatar
         setState(() { _isUpdatingPicture = true; });
         // Dispatch event to AuthBloc to handle upload and Firestore update
         context.read<AuthBloc>().add(UpdateProfilePicture(imageFile: File(pickedImage.path)));
       } else if (pickedImage == null) {
         showGlobalSnackBar(context, "Image selection cancelled.");
       }
    } catch (e) {
       print("Error picking image: $e");
       showGlobalSnackBar(context, "Error picking image: $e", isError: true);
       // Reset loading flag if picker throws an error
       if (mounted) { setState(() { _isUpdatingPicture = false; }); }
    }
   }
  // --- End Image Picking Logic ---

  // --- Logout Logic ---
  Future<void> _handleLogout() async {
     // Show confirmation dialog
     final confirm = await showDialog<bool>( context: context, builder: (context) => AlertDialog( title: const Text("Confirm Logout"), content: const Text("Are you sure you want to log out?"),
           actions: [ TextButton( onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel"), ),
              TextButton( onPressed: () => Navigator.of(context).pop(true), child: const Text("Logout", style: TextStyle(color: AppColors.redColor)), ), ], ), );

     if (confirm == true) {
        try {
           // Dispatch LogoutEvent to AuthBloc
           context.read<AuthBloc>().add(const LogoutEvent());
           // Navigation logic after logout (to AuthInitial state) should be handled
           // by a BlocListener higher up in the widget tree (e.g., wrapping MaterialApp or MainNavigationView)
        } catch (e) {
           print("Error dispatching logout event: $e");
           if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Logout failed: $e")), ); }
        }
     }
   }
  // --- End Logout Logic ---


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Provide the local SocialBloc instance to the widget tree below
    return BlocProvider.value(
      value: _socialBloc,
      child: Scaffold(
        appBar: AppBar( title: const Text('My Profile'), backgroundColor: theme.scaffoldBackgroundColor, elevation: 0, foregroundColor: theme.colorScheme.primary, ),
        // Use MultiBlocListener to handle side effects from both Blocs
        body: MultiBlocListener(
          listeners: [
             // Listener for AuthBloc side effects (picture update status, password reset status)
             BlocListener<AuthBloc, AuthState>(
               listener: (context, state) {
                 // Reset local picture updating flag AFTER Bloc finishes processing the update event
                 if (state is! AuthLoadingState && _isUpdatingPicture) {
                    setState(() { _isUpdatingPicture = false; });
                 }
                 // Show feedback only if WE initiated the update
                 if (state is LoginSuccessState && _isUpdatingPicture) {
                    showGlobalSnackBar(context, "Profile picture updated!");
                 }
                 // Show error snackbar only if WE triggered the update and it failed
                 else if (state is AuthErrorState && _isUpdatingPicture) {
                    showGlobalSnackBar(context, "Update failed: ${state.message}", isError: true);
                 }
                 // Show feedback for other relevant AuthBloc actions
                 else if (state is PasswordResetEmailSentState) {
                    showGlobalSnackBar(context, "Password reset email sent.");
                 }
                 // Note: Logout navigation (on AuthInitial) should be handled globally
               },
             ),
             // Listener for SocialBloc side effects (add/remove family success/error)
             BlocListener<SocialBloc, SocialState>(
                listener: (context, state) {
                   if (state is SocialSuccess) { showGlobalSnackBar(context, state.message); }
                   else if (state is SocialError) { showGlobalSnackBar(context, state.message, isError: true); }
                },
             ),
          ],
          // Use BlocBuilder for AuthBloc to determine the main UI structure
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              // Show LoadingScreen during initial load or general AuthBloc loading
              if (authState is AuthInitial || authState is AuthLoadingState) {
                 return const LoadingScreen();
              }
              // Show error if AuthBloc failed to load profile
              if (authState is AuthErrorState) {
                 return _buildErrorDisplay(context, theme, "Could not load profile: ${authState.message}");
              }
              // Show message if email verification is pending
              if (authState is AwaitingVerificationState) {
                 return _buildErrorDisplay(context, theme, "Please verify your email (${authState.email})", showRetry: false);
              }
              // Build the main profile content if AuthBloc has user data
              if (authState is LoginSuccessState) {
                 final userModel = authState.user;
                 return _buildProfileContent(context, theme, userModel);
              }
              // Fallback for any unexpected AuthBloc state
              return const Center(child: Text("An unexpected error occurred."));
            },
          ),
        ),
      ),
    );
  }

  /// Builds the main content area of the profile screen when user data is loaded.
  Widget _buildProfileContent(BuildContext context, ThemeData theme, AuthModel userModel) {
     const double avatarSize = 100.0;
     final borderRadius = BorderRadius.circular(12.0);
     // Determine profile picture URL from the AuthModel provided by AuthBloc state
     final String profilePicUrl = userModel.profilePicUrl ?? userModel.image;

     // Widget for displaying the profile picture or placeholder
     Widget profileImageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: (profilePicUrl == null || profilePicUrl.isEmpty)
           ? _buildPlaceholder(avatarSize, theme, borderRadius) // Placeholder
           : FadeInImage.memoryNetwork( // Network image with fade-in
              placeholder: _transparentImageData, // Use transparent placeholder bytes
              image: profilePicUrl,
              width: avatarSize, height: avatarSize, fit: BoxFit.cover,
              // Show placeholder on error loading image
              imageErrorBuilder: (context, error, stackTrace) => _buildPlaceholder(avatarSize, theme, borderRadius),
           ),
     );

     return RefreshIndicator(
        // Refresh action fetches latest auth status and social data
        onRefresh: () async {
           try { context.read<AuthBloc>().add(const CheckEmailVerificationStatus()); } catch(e) { print("Error dispatching auth refresh event: $e"); }
           try { context.read<SocialBloc>().add(const LoadFamilyMembers()); } catch(e) { print("Error dispatching social refresh event: $e"); }
           try { context.read<SocialBloc>().add(const LoadFriendsAndRequests()); } catch(e) { print("Error dispatching social refresh event: $e"); }
        },
        color: AppColors.primaryColor,
        child: ListView( // Main scrollable list for all profile sections
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            // --- User Info Section ---
            Center(
              child: Stack( // Stack for avatar + edit button + loading overlay
                 alignment: Alignment.center,
                 children: [
                   // Container for the avatar itself
                   SizedBox(
                      width: avatarSize, height: avatarSize,
                      child: profileImageWidget,
                   ),
                   // Edit Button positioned bottom right
                   Positioned(
                     bottom: 0, right: 0,
                     child: Material(
                       color: theme.colorScheme.primary.withOpacity(0.8),
                       shape: const CircleBorder(), clipBehavior: Clip.antiAlias,
                       child: InkWell(
                          splashColor: theme.colorScheme.primary.withOpacity(0.5),
                          onTap: _isUpdatingPicture ? null : _pickAndUpdateProfilePicture, // Disable tap while updating
                          child: Padding(
                             padding: const EdgeInsets.all(6.0),
                             // Show spinner in button if updating picture
                             child: _isUpdatingPicture
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                       ),
                     ),
                   ),
                 ],
              ),
            ),
            const SizedBox(height: 24),
            // Display User Name
            Center( child: Text( userModel.name, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center, ), ),
            const SizedBox(height: 8),
            // Display User Email
            Center( child: Text( userModel.email, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center, ), ),
            const SizedBox(height: 30),
            const Divider(), const SizedBox(height: 20),

            // --- Family Members Section ---
            // Use spread operator to insert the list of widgets returned by the helper
            ..._buildFamilySectionWidgets(context, theme),
            const SizedBox(height: 20), const Divider(), const SizedBox(height: 20),

            // --- Profile Options Section ---
             _buildProfileOption(context, Icons.person_outline, 'Edit Profile', () { print("Navigate to Edit Profile"); /* TODO */ }),
             _buildProfileOption(context, Icons.people_outline, 'Friends', () {
                // Navigate to Friends screen, passing the SocialBloc instance
                Navigator.push(context, MaterialPageRoute(builder: (_) =>
                   BlocProvider.value( value: context.read<SocialBloc>(), child: const FriendsView(), ) // *** USES FriendsView HERE ***
                ));
             }),
             _buildProfileOption(context, Icons.calendar_today_outlined, 'My Passes', () { print("Navigate to My Passes"); /* TODO */ }),
             _buildProfileOption(context, Icons.settings_outlined, 'Settings', () { print("Navigate to Settings"); /* TODO */ }),
             _buildProfileOption(context, Icons.help_outline, 'Help & Support', () { print("Navigate to Help"); /* TODO */ }),
            const SizedBox(height: 30),

            // --- Logout Button ---
            Center( child: ElevatedButton.icon(
                 icon: const Icon(Icons.logout, size: 18), label: const Text('Logout'), onPressed: _handleLogout,
                 style: ElevatedButton.styleFrom( backgroundColor: AppColors.redColor.withOpacity(0.1), foregroundColor: AppColors.redColor, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) ),
              ), ),
             const SizedBox(height: 20), // Bottom padding
          ],
        ),
      );
  }

  /// Builds the section displaying family members. Returns a List<Widget>.
  List<Widget> _buildFamilySectionWidgets(BuildContext context, ThemeData theme) {
     // Returns a list containing the header row and the BlocBuilder result
     return [
        Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Family Members", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              IconButton( icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28), tooltip: "Add Family Member",
                 onPressed: () {
                    // Navigate providing the SocialBloc instance from this context
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                       BlocProvider.value( value: context.read<SocialBloc>(), child: const AddFamilyMemberView(), )
                    )); }, ), ], ),
        const SizedBox(height: 10),
        // Use BlocBuilder for SocialBloc to display family list or status
        BlocBuilder<SocialBloc, SocialState>(
           builder: (context, state) {
              // Show loading indicator specifically for the family list part
              if (state is SocialLoading && state.isLoadingList && state is! FamilyDataLoaded) { // Changed state check slightly
                 return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
              }
              // Display list when FamilyDataLoaded state is emitted
              if (state is FamilyDataLoaded) {
                 if (state.familyMembers.isEmpty && state.incomingRequests.isEmpty) { // Check both lists
                    return const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 20.0), child: Text("No family members or requests."), ));
                 }
                 // Build Column containing requests and then accepted/external members
                 return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // Incoming Requests Section (if any)
                       if (state.incomingRequests.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                            child: Text("Incoming Requests", style: theme.textTheme.titleMedium),
                          ),
                          ...state.incomingRequests.map((request) => _buildFamilyRequestTile(context, theme, request)),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                       ],
                       // Accepted / External Members Section Title (Only if there are members)
                        if (state.familyMembers.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 5.0),
                             child: Text("Members", style: theme.textTheme.titleMedium),
                           ),
                       // Accepted / External Members List
                       ...state.familyMembers.map((member) => _buildFamilyMemberTile(context, theme, member)),
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
     ]; // End of returned list
  }

  /// Builds a ListTile for an accepted/external family member.
  Widget _buildFamilyMemberTile(BuildContext context, ThemeData theme, FamilyMember member) {
     return Card(
       elevation: 1, margin: const EdgeInsets.symmetric(vertical: 5.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       child: ListTile(
          leading: CircleAvatar( radius: 20, backgroundColor: theme.colorScheme.primaryContainer, backgroundImage: (member.profilePicUrl != null && member.profilePicUrl!.isNotEmpty) ? NetworkImage(member.profilePicUrl!) : null,
             child: (member.profilePicUrl == null || member.profilePicUrl!.isEmpty) ? Text( member.name.isNotEmpty ? member.name[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold) ) : null, ),
          title: Text(member.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text("${member.relationship}${member.status == 'pending_sent' ? ' (Request Sent)' : ''}"), // Indicate pending sent status
          trailing: (member.status != 'pending_sent') // Don't allow deleting pending sent from here
             ? IconButton( icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22,), tooltip: "Remove Member",
                onPressed: () { /* ... Confirmation Dialog and RemoveFamilyMember dispatch ... */
                   showDialog(context: context, builder: (ctx) => AlertDialog( title: const Text("Confirm Removal"), content: Text("Remove ${member.name} from your family list?"),
                      actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                         TextButton(onPressed: () { context.read<SocialBloc>().add(RemoveFamilyMember(memberDocId: member.id)); Navigator.of(ctx).pop(); }, child: const Text("Remove", style: TextStyle(color: AppColors.redColor))), ], )); }, )
             : null, // No delete for pending sent
       ),
     );
  }

  /// Builds a ListTile for an incoming family request.
  Widget _buildFamilyRequestTile(BuildContext context, ThemeData theme, FamilyRequest request) {
     return Card(
       elevation: 1, color: AppColors.accentColor.withOpacity(0.5), // Highlight requests slightly
       margin: const EdgeInsets.symmetric(vertical: 5.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       child: ListTile(
          leading: CircleAvatar( radius: 20, backgroundColor: theme.colorScheme.primaryContainer, backgroundImage: (request.profilePicUrl != null && request.profilePicUrl!.isNotEmpty) ? NetworkImage(request.profilePicUrl!) : null,
             child: (request.profilePicUrl == null || request.profilePicUrl!.isEmpty) ? Text( request.name.isNotEmpty ? request.name[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold) ) : null, ),
          title: Text(request.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text("Wants to add you as: ${request.relationship}"),
          trailing: Row( // Accept / Decline Buttons
            mainAxisSize: MainAxisSize.min,
            children: [
               IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green.shade600),
                  tooltip: 'Accept',
                  onPressed: () {
                     // TODO: Dispatch AcceptFamilyRequest event
                     print("Accept family request from ${request.userId}");
                     // context.read<SocialBloc>().add(AcceptFamilyRequest(requesterUserId: request.userId, requesterName: request.name, requesterProfilePicUrl: request.profilePicUrl, requesterRelationship: request.relationship));
                  },
               ),
               IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red.shade400),
                  tooltip: 'Decline',
                  onPressed: () {
                     // TODO: Dispatch DeclineFamilyRequest event
                     print("Decline family request from ${request.userId}");
                     // context.read<SocialBloc>().add(DeclineFamilyRequest(requesterUserId: request.userId));
                  },
               ),
            ],
          )
       ),
     );
  }


  // Widget to display error message
  Widget _buildErrorDisplay(BuildContext context, ThemeData theme, String message, {bool showRetry = true}) {
     return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
             Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50), const SizedBox(height: 16),
             Text(message, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
             if(showRetry) ...[ const SizedBox(height: 20), ElevatedButton(
                   onPressed: () { try { context.read<AuthBloc>().add(const CheckEmailVerificationStatus()); } catch(e) { print("Error dispatching retry event: $e"); } },
                   child: const Text("Retry") ), ] ], ), ), ); }

   // Helper to build the placeholder
  Widget _buildPlaceholder(double size, ThemeData theme, BorderRadius borderRadius) {
    return Container( width: size, height: size, decoration: BoxDecoration( color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: borderRadius, border: Border.all( color: theme.colorScheme.primary.withOpacity(0.1), width: 1.0, ), ),
      child: Center( child: Icon( Icons.person_rounded, size: size * 0.6, color: theme.colorScheme.primary.withOpacity(0.4), ), ), ); }

  // Helper to build profile option list tiles
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
     final theme = Theme.of(context);
     return ListTile( leading: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.8)), title: Text(title, style: theme.textTheme.bodyLarge), trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onTap: onTap, contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), hoverColor: theme.colorScheme.primary.withOpacity(0.04), ); }
}

