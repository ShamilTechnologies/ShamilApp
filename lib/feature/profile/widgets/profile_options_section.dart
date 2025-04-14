import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // To read SocialBloc for navigation
import 'package:shamil_mobile_app/feature/profile/views/edit_profile_view.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart';
// Import other target screens when created
// import 'package:shamil_mobile_app/feature/profile/views/edit_profile_view.dart';
// import 'package:shamil_mobile_app/feature/passes/views/my_passes_view.dart';
// import 'package:shamil_mobile_app/feature/settings/views/settings_view.dart';
// import 'package:shamil_mobile_app/feature/help/views/help_view.dart';

class ProfileOptionsSection extends StatelessWidget {
  const ProfileOptionsSection({super.key});

  // Helper to build profile option list tiles
  Widget _buildProfileOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.8)),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: theme.colorScheme.primary.withOpacity(0.04),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProfileOption(
            context, Icons.person_outline_rounded, 'Edit Profile', () {
          print("Navigate to Edit Profile");
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EditProfileView()));
        }),
        _buildProfileOption(context, Icons.people_alt_outlined, 'Friends', () {
          // Navigate to Friends screen, passing the SocialBloc instance
          // Assumes SocialBloc was provided above ProfileScreen or passed down
          try {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                          value: context
                              .read<SocialBloc>(), // Read Bloc from context
                          child: const FriendsView(),
                        )));
          } catch (e) {
            print(
                "Error navigating to FriendsView (SocialBloc not found?): $e");
          }
        }),
        _buildProfileOption(context, Icons.calendar_today_outlined, 'My Passes',
            () {
          print("Navigate to My Passes");
          // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => MyPassesView()));
        }),
        _buildProfileOption(context, Icons.settings_outlined, 'Settings', () {
          print("Navigate to Settings");
          // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsView()));
        }),
        _buildProfileOption(
            context, Icons.help_outline_rounded, 'Help & Support', () {
          print("Navigate to Help");
          // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => HelpView()));
        }),
      ],
    );
  }
}
