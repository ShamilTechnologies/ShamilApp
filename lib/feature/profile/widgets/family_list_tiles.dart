import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:gap/gap.dart';
// Import placeholder builder and image data if needed directly

/// Builds a ListTile for an accepted/external family member.
Widget buildFamilyMemberTile(
    BuildContext context, ThemeData theme, FamilyMember member) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Could navigate to member details in the future
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile picture or placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: member.profilePicUrl != null &&
                          member.profilePicUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            member.profilePicUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              CupertinoIcons.person_fill,
                              color: AppColors.primaryColor,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.person_fill,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                ),
                const Gap(16),
                // Member details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member.relationship,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      if (member.phone != null && member.phone!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.phone,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const Gap(4),
                            Text(
                              member.phone!,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      if (member.email != null && member.email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.mail,
                                size: 14,
                                color: AppColors.secondaryText,
                              ),
                              const Gap(4),
                              Expanded(
                                child: Text(
                                  member.email!,
                                  style: AppTextStyle.getSmallStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.person_badge_minus,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    _showRemoveMemberDialog(context, member);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds a ListTile for an incoming family request.
Widget buildFamilyRequestTile(
    BuildContext context, ThemeData theme, FamilyRequest request) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: AppColors.accentColor.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile picture or placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: request.profilePicUrl != null &&
                        request.profilePicUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          request.profilePicUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            CupertinoIcons.person_fill,
                            color: AppColors.accentColor,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.person_fill,
                        color: AppColors.accentColor,
                        size: 24,
                      ),
              ),
              const Gap(16),
              // Request details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      "Wants to connect as your ${request.relationship}",
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    context.read<SocialBloc>().add(
                        DeclineFamilyRequest(requesterUserId: request.userId));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
                const Gap(12),
                ElevatedButton(
                  onPressed: () {
                    context.read<SocialBloc>().add(
                          AcceptFamilyRequest(
                            requesterUserId: request.userId,
                            requesterName: request.name,
                            requesterProfilePicUrl: request.profilePicUrl,
                            requesterRelationship: request.relationship,
                          ),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showRemoveMemberDialog(BuildContext context, FamilyMember member) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Remove Family Member'),
      content: RichText(
        text: TextSpan(
          style: AppTextStyle.getbodyStyle(
            color: Colors.black87,
          ),
          children: [
            const TextSpan(
              text: 'Are you sure you want to remove ',
            ),
            TextSpan(
              text: member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: ' from your family members?',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<SocialBloc>().add(
                  RemoveFamilyMember(memberDocId: member.id),
                );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}
