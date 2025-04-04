import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart'; // For AppColors if needed
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart'; // For refresh event
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // For refresh event
import 'package:shamil_mobile_app/feature/profile/widgets/user_info_section.dart';
import 'package:shamil_mobile_app/feature/profile/widgets/family_section.dart';
import 'package:shamil_mobile_app/feature/profile/widgets/profile_options_section.dart';

class ProfileContent extends StatelessWidget {
  final AuthModel userModel;
  final bool isUpdatingPicture;
  final VoidCallback onUpdatePicture;
  final VoidCallback onLogout;

  const ProfileContent({
    super.key,
    required this.userModel,
    required this.isUpdatingPicture,
    required this.onUpdatePicture,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Dispatch refresh events to both Blocs
        try { context.read<AuthBloc>().add(const CheckEmailVerificationStatus()); } catch(e) { print("Error dispatching auth refresh event: $e"); }
        try { context.read<SocialBloc>().add(const LoadFamilyMembers()); } catch(e) { print("Error dispatching social refresh event: $e"); }
        try { context.read<SocialBloc>().add(const LoadFriendsAndRequests()); } catch(e) { print("Error dispatching social refresh event: $e"); }
        await Future.delayed(const Duration(milliseconds: 500)); // Visual delay
      },
      color: AppColors.primaryColor,
      child: ListView( // Main scrollable list for all profile sections
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          // --- User Info Section ---
          UserInfoSection(
             userModel: userModel,
             isUpdatingPicture: isUpdatingPicture,
             onEditPicture: onUpdatePicture,
          ),
          const SizedBox(height: 30),
          const Divider(), const SizedBox(height: 20),

          // --- Family Members Section ---
          const FamilySection(), // This widget now contains the SocialBlocBuilder
          const SizedBox(height: 20), const Divider(), const SizedBox(height: 20),

          // --- Profile Options Section ---
          const ProfileOptionsSection(), // Contains the ListTiles
          const SizedBox(height: 30),

          // --- Logout Button ---
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              onPressed: onLogout, // Use callback passed from ProfileScreen
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redColor.withOpacity(0.1),
                foregroundColor: AppColors.redColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }
}
