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
import 'package:shamil_mobile_app/feature/community/models/community_event_model.dart';

class CommunityEventsTab extends StatelessWidget {
  const CommunityEventsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state is CommunityInitial ||
            (state is CommunityLoaded &&
                state.isRefreshing &&
                state.events.isEmpty)) {
          return _buildLoadingShimmer();
        }

        if (state is CommunityLoaded) {
          if (state.events.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CommunityBloc>().add(const LoadCommunityEvents());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Featured events section
                _buildFeaturedEvents(
                    context, state.events.where((e) => e.isFeatured).toList()),

                const Gap(24),

                // Upcoming events section
                _buildUpcomingEvents(
                    context, state.events.where((e) => !e.isFeatured).toList()),
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
            // Featured event shimmer
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const Gap(24),

            // Section title shimmer
            Container(
              width: 150,
              height: 24,
              color: Colors.white,
            ),
            const Gap(16),

            // Event cards shimmer
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 120,
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
              CupertinoIcons.calendar,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'No Events Found',
            style: AppTextStyle.getTitleStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'There are no upcoming events in your area. Check back later or create your own event.',
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
              // Navigate to create event screen
            },
            icon: const Icon(CupertinoIcons.calendar_badge_plus),
            label: const Text('Find Events'),
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
            'Error Loading Events',
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
              context.read<CommunityBloc>().add(const LoadCommunityEvents());
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

  Widget _buildFeaturedEvents(
      BuildContext context, List<CommunityEventModel> featuredEvents) {
    if (featuredEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Events',
          style: AppTextStyle.getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: featuredEvents.length,
            itemBuilder: (context, index) {
              final event = featuredEvents[index];
              return _buildFeaturedEventCard(context, event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedEventCard(
      BuildContext context, CommunityEventModel event) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(event.date);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(event.imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<CommunityBloc>().add(SelectEventEvent(event));
              // Navigate to event details
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: AppTextStyle.getSmallStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    event.title,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        color: Colors.white,
                        size: 16,
                      ),
                      const Gap(4),
                      Text(
                        formattedDate,
                        style: AppTextStyle.getSmallStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(12),
                      const Icon(
                        CupertinoIcons.location,
                        color: Colors.white,
                        size: 16,
                      ),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTextStyle.getSmallStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      _buildParticipantsIndicator(event),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // Join the event
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(
      BuildContext context, List<CommunityEventModel> events) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: AppTextStyle.getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(16),
        ...events.map((event) => _buildEventCard(context, event)).toList(),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, CommunityEventModel event) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(event.date);

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
              context.read<CommunityBloc>().add(SelectEventEvent(event));
              // Navigate to event details
            },
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 120,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTextStyle.getTitleStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.calendar,
                              color: AppColors.secondaryText,
                              size: 14,
                            ),
                            const Gap(4),
                            Text(
                              formattedDate,
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.location,
                              color: AppColors.secondaryText,
                              size: 14,
                            ),
                            const Gap(4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: AppTextStyle.getSmallStyle(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildParticipantsIndicator(event),
                            OutlinedButton(
                              onPressed: () {
                                // Join the event
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                side: const BorderSide(
                                    color: AppColors.primaryColor),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Join'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsIndicator(CommunityEventModel event) {
    final remaining = event.maxParticipants - event.participantsCount;
    final isFull = remaining <= 0;

    return Row(
      children: [
        Icon(
          isFull
              ? CupertinoIcons.person_crop_circle_badge_xmark
              : CupertinoIcons.person_2_fill,
          size: 16,
          color: isFull ? Colors.red : AppColors.primaryColor,
        ),
        const Gap(4),
        Text(
          isFull ? 'Full' : '$remaining slots left',
          style: AppTextStyle.getSmallStyle(
            color: isFull ? Colors.red : AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
