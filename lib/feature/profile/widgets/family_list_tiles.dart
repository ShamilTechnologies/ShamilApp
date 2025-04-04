import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
// Import placeholder builder and image data if needed directly
import 'package:shamil_mobile_app/feature/profile/views/profile_view.dart' show buildProfilePlaceholder, transparentImageData;


/// Builds a ListTile for an accepted/external family member.
Widget buildFamilyMemberTile(BuildContext context, ThemeData theme, FamilyMember member) {
   const double listAvatarSize = 44.0;
   final listBorderRadius = BorderRadius.circular(8.0);

   Widget leadingWidget = SizedBox(
      width: listAvatarSize, height: listAvatarSize,
      child: ClipRRect(
        borderRadius: listBorderRadius,
        child: (member.profilePicUrl == null || member.profilePicUrl!.isEmpty)
            ? buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius)
            : FadeInImage.memoryNetwork(
                placeholder: transparentImageData, image: member.profilePicUrl!,
                width: listAvatarSize, height: listAvatarSize, fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) => buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius),
              ),
      ),
   );

   return Card(
     elevation: 1.5, margin: const EdgeInsets.symmetric(vertical: 5.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
     child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        leading: leadingWidget,
        title: Text(member.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text("${member.relationship}${member.status == 'pending_sent' ? ' (Request Sent)' : ''}"),
        trailing: (member.status != 'pending_sent')
           ? IconButton( icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22,), tooltip: "Remove Member",
              onPressed: () {
                 showDialog(context: context, builder: (ctx) => AlertDialog( title: const Text("Confirm Removal"), content: Text("Remove ${member.name} from your family list?"),
                    actions: [ TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                       TextButton(onPressed: () { context.read<SocialBloc>().add(RemoveFamilyMember(memberDocId: member.id)); Navigator.of(ctx).pop(); }, child: const Text("Remove", style: TextStyle(color: AppColors.redColor))), ], )); }, )
           : null,
     ),
   );
}

/// Builds a ListTile for an incoming family request.
Widget buildFamilyRequestTile(BuildContext context, ThemeData theme, FamilyRequest request) {
    const double listAvatarSize = 44.0;
    final listBorderRadius = BorderRadius.circular(8.0);

    Widget leadingWidget = SizedBox(
      width: listAvatarSize, height: listAvatarSize,
      child: ClipRRect(
        borderRadius: listBorderRadius,
        child: (request.profilePicUrl == null || request.profilePicUrl!.isEmpty)
            ? buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius)
            : FadeInImage.memoryNetwork(
                placeholder: transparentImageData, image: request.profilePicUrl!,
                width: listAvatarSize, height: listAvatarSize, fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) => buildProfilePlaceholder(listAvatarSize, theme, listBorderRadius),
              ),
      ),
    );

    return Card(
      elevation: 1.5, color: AppColors.accentColor.withOpacity(0.6),
      margin: const EdgeInsets.symmetric(vertical: 5.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
         contentPadding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
         leading: leadingWidget,
         title: Text(request.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
         subtitle: Text("Wants to add you as: ${request.relationship}"),
         trailing: Row( // Accept / Decline Buttons
           mainAxisSize: MainAxisSize.min,
           children: [
              _buildRequestActionButton( context: context, theme: theme, icon: Icons.check_rounded, color: Colors.green, tooltip: 'Accept',
                 onTap: () {
                    print("Accept family request from ${request.userId}");
                    // Dispatch event with all necessary info for the other user's update
                    context.read<SocialBloc>().add(AcceptFamilyRequest(requesterUserId: request.userId, requesterName: request.name, requesterProfilePicUrl: request.profilePicUrl, requesterRelationship: request.relationship));
                 },
              ),
              const SizedBox(width: 8),
              _buildRequestActionButton( context: context, theme: theme, icon: Icons.close_rounded, color: Colors.red, tooltip: 'Decline',
                 onTap: () {
                    print("Decline family request from ${request.userId}");
                    context.read<SocialBloc>().add(DeclineFamilyRequest(requesterUserId: request.userId));
                 },
              ),
           ],
         )
      ),
    );
}

/// Helper to build action buttons for requests
Widget _buildRequestActionButton({ required BuildContext context, required ThemeData theme, required IconData icon, required Color color, required String tooltip, required VoidCallback onTap }) {
    return Tooltip( message: tooltip, child: Material( color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8.0),
       child: InkWell( onTap: onTap, borderRadius: BorderRadius.circular(8.0), splashColor: color.withOpacity(0.3), highlightColor: color.withOpacity(0.2),
          child: Padding( padding: const EdgeInsets.all(8.0), child: Icon(icon, color: color, size: 20), ),
       ), ), );
 }

