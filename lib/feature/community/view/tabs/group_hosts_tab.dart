import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_event.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_state.dart';
import 'package:shamil_mobile_app/feature/community/models/group_host_model.dart';

class GroupHostsTab extends StatelessWidget {
  const GroupHostsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state is CommunityInitial ||
            (state is CommunityLoaded &&
                state.isRefreshing &&
                state.groupHosts.isEmpty)) {
          return _buildLoadingShimmer();
        }

        if (state is CommunityLoaded) {
          if (state.groupHosts.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CommunityBloc>().add(const LoadGroupHostsEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExplanationCard(),
                const Gap(24),

                // Groups list
                ...state.groupHosts
                    .map((group) => _buildGroupHostCard(context, group))
                    ,

                // Add some bottom padding
                const SizedBox(height: 80),
              ],
            ),
          );
        }

        if (state is CommunityError) {
          return _buildErrorState(context, state.message);
        }

        return _buildLoadingShimmer();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation card shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const Gap(24),

            // Group host cards shimmer
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              CupertinoIcons.person_3,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'No Group Hosts Found',
            style: AppTextStyle.getTitleStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Be the first to host a group reservation! Host a group and invite others to join you.',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create group host screen
            },
            icon: const Icon(CupertinoIcons.person_add),
            label: const Text('Host a Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: Colors.red,
            size: 48,
          ),
          const Gap(16),
          Text(
            'Error Loading Group Hosts',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
              context.read<CommunityBloc>().add(const LoadGroupHostsEvent());
            },
            icon: const Icon(CupertinoIcons.arrow_clockwise),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lightbulb,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const Gap(8),
              Text(
                'What are Group Hosts?',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'Group hosts are users who create reservations that others can join. Join an existing group to save costs or host your own!',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHostCard(BuildContext context, GroupHostModel group) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(group.dateTime);
    final formattedTime = DateFormat('h:mm a').format(group.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              context.read<CommunityBloc>().add(SelectGroupHostEvent(group));
              // Navigate to group details
            },
            child: Column(
              children: [
                // Header with host info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(group.hostImageUrl),
                        radius: 20,
                      ),
                      const Gap(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.hostName,
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Host',
                            style: AppTextStyle.getSmallStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(group.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(group.status),
                          style: AppTextStyle.getSmallStyle(
                            color: _getStatusColor(group.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(8),
                      Text(
                        group.description,
                        style: AppTextStyle.getbodyStyle(
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(12),

                      // Info row: service, time, location
                      Row(
                        children: [
                          _buildInfoItem(
                            icon: CupertinoIcons.tickets,
                            text: group.serviceName,
                          ),
                          _buildInfoItem(
                            icon: CupertinoIcons.calendar,
                            text: formattedDate,
                          ),
                          _buildInfoItem(
                            icon: CupertinoIcons.clock,
                            text: formattedTime,
                          ),
                        ],
                      ),
                      const Gap(12),

                      // Location and price
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              icon: CupertinoIcons.location,
                              text: group.providerName,
                              fullWidth: true,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${group.currency} ${group.pricePerPerson.toStringAsFixed(2)} / person',
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Participants and join button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildParticipantsIndicator(group),
                          if (group.status == 'open')
                            ElevatedButton.icon(
                              onPressed: () {
                                // Join the group
                              },
                              icon: const Icon(CupertinoIcons.person_add,
                                  size: 16),
                              label: const Text('Join Group'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    bool fullWidth = false,
  }) {
    return Container(
      constraints: fullWidth ? null : const BoxConstraints(maxWidth: 110),
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.secondaryText,
          ),
          const Gap(4),
          Flexible(
            child: Text(
              text,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsIndicator(GroupHostModel group) {
    final remaining = group.maxParticipants - group.currentParticipants;
    final isFull = remaining <= 0;

    return Row(
      children: [
        Icon(
          CupertinoIcons.person_3_fill,
          size: 16,
          color: isFull ? Colors.red : AppColors.primaryColor,
        ),
        const Gap(4),
        Text(
          '${group.currentParticipants}/${group.maxParticipants} joined',
          style: AppTextStyle.getSmallStyle(
            color: isFull ? Colors.red : AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'full':
        return 'Full';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
