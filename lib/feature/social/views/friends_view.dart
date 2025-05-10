import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/views/find_friends_view.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:typed_data';

// Placeholder for transparent image data
const kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
final Uint8List _transparentImageData = Uint8List.fromList(kTransparentImage);

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load initial data
    try {
      context.read<SocialBloc>().add(const LoadFriendsAndRequests());
    } catch (e) {
      print("Error dispatching LoadFriendsAndRequests: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showGlobalSnackBar(context, "Could not load friends data.",
              isError: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ensure changes are reflected when returning to previous screen
        Navigator.pop(context, true); // Return true to indicate refresh needed
        return false; // Let our custom navigation handle the pop
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: BlocConsumer<SocialBloc, SocialState>(
          listener: (context, state) {
            if (state is SocialSuccess) {
              showGlobalSnackBar(context, state.message);
            } else if (state is SocialError) {
              showGlobalSnackBar(context, state.message, isError: true);
            }
          },
          builder: (context, state) {
            // Show loading state
            if (state is SocialLoading &&
                state.isLoadingList &&
                state is! FriendsAndRequestsLoaded) {
              return _buildLoadingView();
            }

            // Extract data from state
            List<Friend> friends = [];
            List<FriendRequest> requests = [];
            bool isActionLoading =
                state is SocialLoading && !state.isLoadingList;

            if (state is FriendsAndRequestsLoaded) {
              friends = state.friends;
              requests = state.incomingRequests;
            }

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primaryColor,
                          unselectedLabelColor: AppColors.secondaryText,
                          indicatorColor: AppColors.primaryColor,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: AppTextStyle.getTitleStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: AppTextStyle.getTitleStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: 'Friends'),
                            Tab(text: 'Requests'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFriendsList(friends, isActionLoading),
                            _buildRequestsList(requests, isActionLoading),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<SocialBloc>(),
                  child: const FindFriendsView(),
                ),
              ),
            );

            // Refresh the list when returning from find friends screen
            if (mounted) {
              context.read<SocialBloc>().add(const LoadFriendsAndRequests());
            }
          },
          backgroundColor: AppColors.primaryColor,
          child:
              const Icon(CupertinoIcons.person_badge_plus, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(CupertinoIcons.back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Icon and title
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_3_fill,
                      color: AppColors.primaryColor,
                      size: 26,
                    ),
                  ),

                  const Gap(14),

                  Expanded(
                    child: Text(
                      'Friends',
                      style: AppTextStyle.getHeadlineTextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Refresh button
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.refresh,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      context
                          .read<SocialBloc>()
                          .add(const LoadFriendsAndRequests());
                    },
                  ),
                ],
              ),
              const Gap(12),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Connect with friends and see requests',
                    style: AppTextStyle.getbodyStyle(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(List<Friend> friends, bool isLoading) {
    if (friends.isEmpty) {
      return _buildEmptyState(
        'No Friends Yet',
        'Connect with others by adding friends through the search feature.',
        CupertinoIcons.person_3,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SocialBloc>().add(const LoadFriendsAndRequests());
      },
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildFriendCard(friends[index], isLoading),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<FriendRequest> requests, bool isLoading) {
    if (requests.isEmpty) {
      return _buildEmptyState(
        'No Pending Requests',
        'When someone sends you a friend request, it will appear here.',
        CupertinoIcons.person_badge_plus,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SocialBloc>().add(const LoadFriendsAndRequests());
      },
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildRequestCard(requests[index], isLoading),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              // Handle friend tap
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile picture
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: friend.profilePicUrl != null &&
                            friend.profilePicUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              friend.profilePicUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Text(
                                  friend.name.isNotEmpty
                                      ? friend.name[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              friend.name.isNotEmpty
                                  ? friend.name[0].toUpperCase()
                                  : '?',
                              style: AppTextStyle.getTitleStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                  ),
                  const Gap(16),
                  // Friend details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.name,
                          style: AppTextStyle.getTitleStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Text(
                          friend.friendedAt != null
                              ? "Friend since: ${MaterialLocalizations.of(context).formatShortDate(friend.friendedAt!.toDate())}"
                              : "Recently added",
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remove friend button
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.person_badge_minus,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      _showRemoveFriendDialog(context, friend);
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

  Widget _buildRequestCard(FriendRequest request, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                // Profile picture
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
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Text(
                                request.name.isNotEmpty
                                    ? request.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyle.getTitleStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            request.name.isNotEmpty
                                ? request.name[0].toUpperCase()
                                : '?',
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentColor,
                            ),
                          ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        "Wants to be your friend",
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
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<SocialBloc>().add(DeclineFriendRequest(
                                requesterUserId: request.userId));
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
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<SocialBloc>().add(AcceptFriendRequest(
                                requesterUserId: request.userId,
                                requesterUserName: request.name,
                                requesterUserPicUrl: request.profilePicUrl));
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

  void _showRemoveFriendDialog(BuildContext context, Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove Friend'),
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
                text: friend.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' from your friends?',
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
              context
                  .read<SocialBloc>()
                  .add(RemoveFriend(friendUserId: friend.userId));
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

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            const Gap(16),
            Text(
              title,
              style: AppTextStyle.getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                message,
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<SocialBloc>(),
                      child: const FindFriendsView(),
                    ),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.search),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer for tabs
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Gap(24),

                  // Shimmer for list items
                  Expanded(
                    child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 90,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
