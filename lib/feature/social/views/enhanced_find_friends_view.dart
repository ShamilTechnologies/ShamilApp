import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_bloc.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_event.dart'
    hide SearchUsers;
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart'
    hide FriendshipStatus, SearchUsers;
import 'package:shamil_mobile_app/feature/profile/views/user_profile_view.dart';
import 'package:shamil_mobile_app/core/widgets/placeholders.dart';

class EnhancedFindFriendsView extends StatefulWidget {
  const EnhancedFindFriendsView({super.key});

  @override
  State<EnhancedFindFriendsView> createState() =>
      _EnhancedFindFriendsViewState();
}

class _EnhancedFindFriendsViewState extends State<EnhancedFindFriendsView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeSearchQuery = "";

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _activeSearchQuery = query.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<SocialBloc>().add(SearchUsers(query: _activeSearchQuery));
    });
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileView(
          userId: userId,
          context: ProfileViewContext.searchResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title:
            const Text('Find Friends', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                prefixIcon: const Icon(CupertinoIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search Results
          Expanded(
            child: BlocBuilder<SocialBloc, SocialState>(
              builder: (context, state) {
                if (state is SocialLoading) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                        color: AppColors.primaryColor),
                  );
                }

                if (state is FriendSearchResultsLoaded) {
                  if (state.results.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final userWithStatus = state.results[index];
                      final user = userWithStatus.user;

                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0] : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '@${user.username}',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          trailing: _buildActionButton(userWithStatus),
                          onTap: () => _navigateToProfile(user.uid),
                        ),
                      );
                    },
                  );
                }

                return const Center(
                  child: Text(
                    'Start searching to find friends',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(UserSearchResultWithStatus userWithStatus) {
    final socialBloc = context.read<SocialBloc>();
    final user = userWithStatus.user;

    switch (userWithStatus.status) {
      case FriendshipStatus.none:
        return ElevatedButton(
          onPressed: () => socialBloc.add(SendFriendRequest(
            targetUserId: user.uid,
            targetUserName: user.name,
            targetUserPicUrl: user.profilePicUrl,
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: const Text('Add'),
        );

      case FriendshipStatus.requestSent:
        return ElevatedButton(
          onPressed: () => socialBloc.add(UnsendFriendRequest(
            targetUserId: user.uid,
          )),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Sent'),
        );

      case FriendshipStatus.friends:
        return const Chip(
          label: Text('Friends'),
          backgroundColor: Colors.green,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
