// lib/feature/social/views/find_friends_view.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

class FindFriendsView extends StatefulWidget {
  const FindFriendsView({super.key});

  @override
  State<FindFriendsView> createState() => _FindFriendsViewState();
}

class _FindFriendsViewState extends State<FindFriendsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeSearchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _activeSearchQuery = query.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SocialBloc>().add(SearchUsers(query: _activeSearchQuery));
    });
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme, UserSearchResultWithStatus userWithStatus) {
    final socialBloc = context.read<SocialBloc>();
    final String targetUserId = userWithStatus.user.uid;
    final String targetUserName = userWithStatus.user.name;
    final String? targetUserPicUrl = userWithStatus.user.profilePicUrl ?? userWithStatus.user.image;

    final bool isProcessingThisUser = (socialBloc.state is SocialLoading &&
                                     (socialBloc.state as SocialLoading).processingUserId == targetUserId);

    if (isProcessingThisUser) {
      return const SizedBox(
        width: 100, height: 38,
        child: Center(child: CupertinoActivityIndicator(radius: 9, color: AppColors.primaryColor)),
      );
    }

    Widget button;
    switch (userWithStatus.status) {
      case FriendshipStatus.none:
        button = ElevatedButton.icon(
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text("Add"),
          onPressed: () => socialBloc.add(SendFriendRequest(
              targetUserId: targetUserId,
              targetUserName: targetUserName,
              targetUserPicUrl: targetUserPicUrl)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle: app_text_style.getSmallStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        break;
      case FriendshipStatus.requestSent:
        button = OutlinedButton.icon(
          icon: Icon(Icons.outgoing_mail, size: 18, color: Colors.orange.shade700),
          label: Text("Sent", style: app_text_style.getSmallStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500, fontSize: 13)),
          onPressed: () => socialBloc.add(UnsendFriendRequest(targetUserId: targetUserId)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.orange.shade400),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        break;
      case FriendshipStatus.requestReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: ()  => socialBloc.add(DeclineFriendRequest(requesterUserId: targetUserId)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal:12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Decline", style: app_text_style.getSmallStyle(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.w500))
            ),
            const Gap(6),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text("Accept"),
              onPressed: () => socialBloc.add(AcceptFriendRequest(
                  requesterUserId: targetUserId,
                  requesterUserName: targetUserName,
                  requesterUserPicUrl: targetUserPicUrl)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: app_text_style.getSmallStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      case FriendshipStatus.friends:
        button = Chip(
          avatar: Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.primary),
          label: Text("Friends", style: app_text_style.getSmallStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
        break;
    }
    return SizedBox(width: 110, child: button); // Ensure buttons have a consistent min width
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Friends', style: app_text_style.getTitleStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: app_text_style.getbodyStyle(color: AppColors.secondaryText.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.secondaryText.withOpacity(0.7)),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: AppColors.secondaryText.withOpacity(0.7)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              style: app_text_style.getbodyStyle(color: AppColors.primaryText),
            ),
          ),
        ),
      ),
      body: BlocConsumer<SocialBloc, SocialState>(
        listener: (context, state) {
          if (state is SocialSuccess && ModalRoute.of(context)?.isCurrent == true) {
            showGlobalSnackBar(context, state.message, isError: false);
          } else if (state is SocialError && ModalRoute.of(context)?.isCurrent == true) {
            showGlobalSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is SocialLoading && state.isLoadingList && _activeSearchQuery.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }
          if (state is SocialLoading && _activeSearchQuery.isNotEmpty && state.processingUserId == null) {
            return _buildShimmerList(theme);
          }

          if (state is FriendSearchResultsLoaded) {
            if (state.results.isEmpty && state.query.isNotEmpty) {
              return _buildEmptyState(
                theme,
                icon: Icons.person_search_outlined,
                title: "No users found for \"${state.query}\"",
                message: "Try a different name or username, or check for typos. Make sure the user has an account.",
              );
            } else if (state.results.isEmpty && state.query.isEmpty) {
               return _buildEmptyState(
                theme,
                icon: Icons.connect_without_contact_rounded,
                title: "Find Your Friends",
                message: "Enter a name or username in the search bar above to connect with people you know on the platform.",
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              itemCount: state.results.length,
              separatorBuilder: (context, index) => const Divider(height: 0.5, thickness: 0.3, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final userWithStatus = state.results[index];
                final user = userWithStatus.user;
                return ListTile(
                  leading: buildProfilePlaceholder( // Corrected call with named parameters
                    imageUrl: user.profilePicUrl ?? user.image,
                    name: user.name,
                    size: 48.0,
                    borderRadius: BorderRadius.circular(8.0), // Squared with 8px radius
                  ),
                  title: Text(user.name, style: app_text_style.getTitleStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  subtitle: Text("@${user.username}", style: app_text_style.getSmallStyle(color: theme.colorScheme.secondary)),
                  trailing: _buildActionButton(context, theme, userWithStatus),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  onTap: () {
                     showGlobalSnackBar(context, "Tapped on ${user.name}", isError: false);
                  },
                );
              },
            );
          }
          return _buildEmptyState(
            theme,
            icon: Icons.group_add_outlined,
            title: "Connect with Others",
            message: "Use the search bar to find friends and family on the platform.",
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: theme.colorScheme.secondary.withOpacity(0.5)),
            const Gap(20),
            Text(title, style: app_text_style.getTitleStyle(fontSize: 19, color: theme.colorScheme.onSurface.withOpacity(0.8)), textAlign: TextAlign.center),
            const Gap(10),
            Text(message, style: app_text_style.getbodyStyle(color: theme.colorScheme.secondary, height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return ListView.builder(
      itemCount: 7,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: theme.disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0)
                  )
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 18, width: MediaQuery.of(context).size.width * 0.45, color: theme.disabledColor.withOpacity(0.1)),
                    const Gap(8),
                    Container(height: 14, width: MediaQuery.of(context).size.width * 0.3, color: theme.disabledColor.withOpacity(0.1)),
                  ],
                ),
              ),
              const Gap(12),
              Container(height: 36, width: 90, decoration: BoxDecoration(color: theme.disabledColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8))),
            ],
          ),
        );
      },
    );
  }
}
