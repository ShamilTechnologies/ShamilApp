import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  const CommunityEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        if (state is CommunityInitial ||
            (state is CommunityLoaded &&
                state.isRefreshing &&
                state.events.isEmpty)) {
          return _buildPremiumLoadingShimmer();
        }

        if (state is CommunityLoaded) {
          if (state.events.isEmpty) {
            return _buildPremiumEmptyState(context);
          }

          return RefreshIndicator(
            backgroundColor: Colors.transparent,
            color: AppColors.primaryColor,
            onRefresh: () async {
              context.read<CommunityBloc>().add(const LoadCommunityEvents());
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only handle vertical scroll notifications, let horizontal gestures pass through
                if (notification is ScrollStartNotification) {
                  final axis = notification.metrics.axis;
                  if (axis == Axis.horizontal) {
                    return false; // Let horizontal gestures pass through to PageView
                  }
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics:
                    const ClampingScrollPhysics(), // Better for nested scrolling
                children: [
                  // Featured events section
                  if (state.events.where((e) => e.isFeatured).isNotEmpty)
                    _buildPremiumFeaturedEvents(context,
                        state.events.where((e) => e.isFeatured).toList()),

                  if (state.events.where((e) => e.isFeatured).isNotEmpty)
                    const Gap(30),

                  // Upcoming events section
                  if (state.events.where((e) => !e.isFeatured).isNotEmpty)
                    _buildPremiumUpcomingEvents(context,
                        state.events.where((e) => !e.isFeatured).toList()),
                ],
              ),
            ),
          );
        }

        if (state is CommunityError) {
          return _buildPremiumErrorState(context, state.message);
        }

        return _buildPremiumLoadingShimmer();
      },
    );
  }

  Widget _buildPremiumLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured event shimmer
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const Gap(30),

            // Section title shimmer
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Gap(20),

            // Event cards shimmer
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.3),
                        AppColors.accentColor.withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const Gap(24),
                Text(
                  'No Events Found',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(16),
                Text(
                  'There are no upcoming events in your area. Check back later or create your own event.',
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),
                Material(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigate to create event screen
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.calendar_badge_plus,
                              color: Colors.white),
                          const Gap(8),
                          Text(
                            'Find Events',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPremiumErrorState(BuildContext context, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.15),
              Colors.red.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white,
                  size: 48,
                ),
                const Gap(20),
                Text(
                  'Error Loading Events',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Gap(12),
                Text(
                  message,
                  style: AppTextStyle.getbodyStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                Material(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context
                          .read<CommunityBloc>()
                          .add(const LoadCommunityEvents());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.8),
                            Colors.red.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.arrow_clockwise,
                              color: Colors.white),
                          const Gap(8),
                          Text(
                            'Try Again',
                            style: AppTextStyle.getbodyStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPremiumFeaturedEvents(
      BuildContext context, List<CommunityEventModel> featuredEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Events',
          style: AppTextStyle.getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Gap(16),
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: featuredEvents.length,
            itemBuilder: (context, index) {
              final event = featuredEvents[index];
              return _buildPremiumFeaturedEventCard(context, event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFeaturedEventCard(
      BuildContext context, CommunityEventModel event) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(event.date);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),

            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.9),
                              AppColors.accentColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: AppTextStyle.getSmallStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Gap(12),
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
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.calendar,
                            color: Colors.white,
                            size: 16,
                          ),
                          const Gap(6),
                          Text(
                            formattedDate,
                            style: AppTextStyle.getSmallStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(16),
                          const Icon(
                            CupertinoIcons.location,
                            color: Colors.white,
                            size: 16,
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              event.location,
                              style: AppTextStyle.getSmallStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          _buildPremiumParticipantsIndicator(event),
                          const Spacer(),
                          Material(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                // Join the event
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Join',
                                  style: AppTextStyle.getbodyStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpcomingEvents(
      BuildContext context, List<CommunityEventModel> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: AppTextStyle.getTitleStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Gap(16),
        ...events.map((event) => _buildPremiumEventCard(context, event)),
      ],
    );
  }

  Widget _buildPremiumEventCard(
      BuildContext context, CommunityEventModel event) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<CommunityBloc>().add(SelectEventEvent(event));
                // Navigate to event details
              },
              child: Row(
                children: [
                  // Event image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Container(
                      width: 120,
                      height: 140,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Event details
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
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                              const Gap(6),
                              Text(
                                formattedDate,
                                style: AppTextStyle.getSmallStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: AppTextStyle.getSmallStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPremiumParticipantsIndicator(event),
                              Material(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // Join the event
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor
                                              .withOpacity(0.8),
                                          AppColors.tealColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Join',
                                      style: AppTextStyle.getSmallStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildPremiumParticipantsIndicator(CommunityEventModel event) {
    final remaining = event.maxParticipants - event.participantsCount;
    final isFull = remaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFull
              ? [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)]
              : [
                  AppColors.accentColor.withOpacity(0.8),
                  AppColors.tealColor.withOpacity(0.8)
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (isFull ? Colors.red : AppColors.accentColor).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFull
                ? CupertinoIcons.person_crop_circle_badge_xmark
                : CupertinoIcons.person_2_fill,
            size: 14,
            color: Colors.white,
          ),
          const Gap(4),
          Text(
            isFull ? 'Full' : '$remaining left',
            style: AppTextStyle.getSmallStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
