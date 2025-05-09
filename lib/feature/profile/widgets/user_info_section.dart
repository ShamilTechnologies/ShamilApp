// lib/feature/profile/widgets/user_info_section.dart

import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
// Import placeholder builder and image data
import 'package:shamil_mobile_app/core/constants/image_constants.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart'; // Use shared placeholder builder

class UserInfoSection extends StatelessWidget {
  final AuthModel userModel;
  final bool isUpdatingPicture;
  final VoidCallback onEditPicture;

  const UserInfoSection({
    super.key,
    required this.userModel,
    required this.isUpdatingPicture,
    required this.onEditPicture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double avatarSize = 100.0;
    final borderRadius = BorderRadius.circular(12.0);
    // Ensure profilePicUrl check handles empty strings
    String? profilePicUrl = userModel.profilePicUrl ?? userModel.image;
    if (profilePicUrl != null && profilePicUrl.isEmpty) {
       profilePicUrl = null;
    }

    // Widget for displaying the profile picture or placeholder
    Widget profileImageWidget = ClipRRect(
      borderRadius: borderRadius,
      child: (profilePicUrl == null)
         ? buildProfilePlaceholder(avatarSize, theme, borderRadius) // Use helper
         : FadeInImage.memoryNetwork(
            placeholder: transparentImageData, // Use imported data
            image: profilePicUrl,
            width: avatarSize, height: avatarSize, fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) => buildProfilePlaceholder(avatarSize, theme, borderRadius),
         ),
    );

    return Column( // Use Column for vertical layout of info
      children: [
         Center(
           child: Stack( // Stack for avatar + edit button + loading overlay
              alignment: Alignment.center,
              children: [
                // *** Use Hero widget with UNIQUE tag ***
                Hero(
                  tag: 'userProfilePic_hero_profile', // UNIQUE tag for profile screen
                  child: SizedBox( width: avatarSize, height: avatarSize, child: profileImageWidget, ),
                ),
                // Edit Button positioned bottom right
                Positioned( bottom: 0, right: 0,
                  child: Material(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    shape: const CircleBorder(), clipBehavior: Clip.antiAlias,
                    elevation: 2.0,
                    child: InkWell(
                       splashColor: theme.colorScheme.primary.withOpacity(0.5),
                       onTap: isUpdatingPicture ? null : onEditPicture,
                       child: Padding( padding: const EdgeInsets.all(6.0),
                          child: isUpdatingPicture
                             ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                             : const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                       ), ), ), ),
              ],
           ),
         ),
         const SizedBox(height: 24),
         // Display User Name
         Center( child: Text( userModel.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ), ),
         const SizedBox(height: 8),
         // Display User Email
         Center( child: Text( userModel.email, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center, ), ),
      ],
    );
  }
}