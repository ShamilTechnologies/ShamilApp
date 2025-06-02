import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/passes/bloc/my_passes_bloc.dart';
import 'package:shamil_mobile_app/feature/passes/data/models/pass_type.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/pages/queue_reservation_page.dart';

class PassesContent extends StatefulWidget {
  final PassType passType;

  const PassesContent({
    super.key,
    required this.passType,
  });

  @override
  State<PassesContent> createState() => _PassesContentState();
}

class _PassesContentState extends State<PassesContent>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyPassesBloc, MyPassesState>(
      listener: (context, state) {
        if (state is MyPassesLoaded) {
          if (state.successMessage != null) {
            showGlobalSnackBar(context, state.successMessage!);
          }
          if (state.errorMessage != null) {
            showGlobalSnackBar(context, state.errorMessage!, isError: true);
          }
        }
        if (state is MyPassesError) {
          showGlobalSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        if (state is MyPassesInitial || state is MyPassesLoading) {
          return _buildPremiumLoadingShimmer();
        }

        if (state is MyPassesLoaded) {
          final currentFilter = state.currentFilter ?? PassFilter.all;
          final items = widget.passType == PassType.reservation
              ? state.filteredReservations
              : state.filteredSubscriptions;

          if (items.isEmpty) {
            final allItems = widget.passType == PassType.reservation
                ? state.reservations
                : state.subscriptions;

            if (allItems.isEmpty) {
              return _buildPremiumEmptyState(context);
            } else {
              return _buildPremiumFilterEmptyState(context, currentFilter);
            }
          }

          return widget.passType == PassType.reservation
              ? _buildPremiumReservationList(
                  context, state.filteredReservations, currentFilter)
              : _buildPremiumSubscriptionList(
                  context, state.filteredSubscriptions, currentFilter);
        }

        if (state is MyPassesError) {
          return _buildPremiumErrorState(context, state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPremiumLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Premium filter chips shimmer
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.3),
                    child: Container(
                      width: 90,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Gap(20),

          // Premium cards shimmer
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.3),
                    child: Container(
                      height: 180,
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
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmptyState(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium icon container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.3),
                            AppColors.primaryColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          widget.passType == PassType.reservation
                              ? Icons.event_note_rounded
                              : Icons.card_membership_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const Gap(24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFB8BCC8)],
                      ).createShader(bounds),
                      child: Text(
                        widget.passType == PassType.reservation
                            ? 'No Reservations Yet'
                            : 'No Subscriptions Yet',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      widget.passType == PassType.reservation
                          ? 'Book your first service to see your reservations here'
                          : 'Subscribe to a plan to see your subscriptions here',
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.tealColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            child: Text(
                              widget.passType == PassType.reservation
                                  ? 'Browse Services'
                                  : 'Browse Plans',
                              style: AppTextStyle.getbodyStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildPremiumFilterEmptyState(
      BuildContext context, PassFilter currentFilter) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_off_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 48,
                      ),
                    ),
                    const Gap(24),
                    Text(
                      'No Results Found',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'No ${widget.passType == PassType.reservation ? 'reservations' : 'subscriptions'} match the current filter.',
                      style: AppTextStyle.getbodyStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<MyPassesBloc>()
                                .add(const ChangePassFilter(PassFilter.all));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Text(
                              'Show All',
                              style: AppTextStyle.getbodyStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildPremiumErrorState(BuildContext context, String message) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withOpacity(0.3),
                            Colors.red.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.withOpacity(0.8),
                        size: 48,
                      ),
                    ),
                    const Gap(24),
                    Text(
                      widget.passType == PassType.reservation
                          ? 'Error Loading Reservations'
                          : 'Error Loading Subscriptions',
                      style: AppTextStyle.getTitleStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
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
                    const Gap(32),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Color(0xFFD32F2F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context
                                .read<MyPassesBloc>()
                                .add(const LoadMyPasses());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            child: Text(
                              'Try Again',
                              style: AppTextStyle.getbodyStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildPremiumReservationList(BuildContext context,
      List<ReservationModel> reservations, PassFilter currentFilter) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Premium filter chips
                _buildPremiumFilterChips(context, currentFilter, true),
                const Gap(20),

                // Premium reservation cards
                Expanded(
                  child: RefreshIndicator(
                    backgroundColor: const Color(0xFF1A1A2E),
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      context.read<MyPassesBloc>().add(const RefreshMyPasses());
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final animationValue =
                                (_animationController.value - delay)
                                    .clamp(0.0, 1.0);

                            return Transform.translate(
                              offset: Offset(0, (1 - animationValue) * 30),
                              child: Opacity(
                                opacity: animationValue,
                                child: _buildPremiumReservationCard(
                                    context, reservations[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumSubscriptionList(BuildContext context,
      List<SubscriptionModel> subscriptions, PassFilter currentFilter) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Premium filter chips
                _buildPremiumFilterChips(context, currentFilter, false),
                const Gap(20),

                // Premium subscription cards
                Expanded(
                  child: RefreshIndicator(
                    backgroundColor: const Color(0xFF1A1A2E),
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      HapticFeedback.lightImpact();
                      context.read<MyPassesBloc>().add(const RefreshMyPasses());
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final animationValue =
                                (_animationController.value - delay)
                                    .clamp(0.0, 1.0);

                            return Transform.translate(
                              offset: Offset(0, (1 - animationValue) * 30),
                              child: Opacity(
                                opacity: animationValue,
                                child: _buildPremiumSubscriptionCard(
                                    context, subscriptions[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumFilterChips(
      BuildContext context, PassFilter currentFilter, bool isReservation) {
    final filters = isReservation
        ? [
            _FilterData(PassFilter.all, 'All', Icons.apps_rounded),
            _FilterData(
                PassFilter.upcoming, 'Upcoming', Icons.schedule_rounded),
            _FilterData(
                PassFilter.completed, 'Completed', Icons.check_circle_rounded),
            _FilterData(
                PassFilter.cancelled, 'Cancelled', Icons.cancel_rounded),
          ]
        : [
            _FilterData(PassFilter.all, 'All', Icons.apps_rounded),
            _FilterData(
                PassFilter.active, 'Active', Icons.check_circle_rounded),
            _FilterData(
                PassFilter.expired, 'Expired', Icons.access_time_rounded),
            _FilterData(
                PassFilter.cancelled, 'Cancelled', Icons.cancel_rounded),
          ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = currentFilter == filter.value;

          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<MyPassesBloc>().add(ChangePassFilter(filter.value));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.tealColor,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const Gap(6),
                      Text(
                        filter.label,
                        style: AppTextStyle.getbodyStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumReservationCard(
      BuildContext context, ReservationModel reservation) {
    final isPending = reservation.status == ReservationStatus.pending;
    final isConfirmed = reservation.status == ReservationStatus.confirmed;
    final isCancelled =
        reservation.status == ReservationStatus.cancelledByUser ||
            reservation.status == ReservationStatus.cancelledByProvider;
    final isCompleted = reservation.status == ReservationStatus.completed;

    // Status info with premium colors
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPending) {
      statusColor = const Color(0xFFFFB74D);
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    } else if (isConfirmed) {
      statusColor = const Color(0xFF66BB6A);
      statusText = 'Confirmed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF5350);
      statusText = 'Cancelled';
      statusIcon = Icons.cancel_rounded;
    } else if (isCompleted) {
      statusColor = const Color(0xFF42A5F5);
      statusText = 'Completed';
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = Icons.help_outline_rounded;
    }

    // Date/Time formatting
    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d, yyyy').format(dateTime)
        : 'No date';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'No time';

    // Get price and currency
    final price = reservation.totalPrice;
    final currency = 'EGP';

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with service name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reservation.serviceName ?? 'Service Reservation',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.8),
                            statusColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: Colors.white,
                          ),
                          const Gap(4),
                          Text(
                            statusText,
                            style: AppTextStyle.getbodyStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Date and time info with premium styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.tealColor.withOpacity(0.3),
                                    AppColors.tealColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: AppTextStyle.getbodyStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentColor.withOpacity(0.3),
                                    AppColors.accentColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                formattedTime,
                                style: AppTextStyle.getbodyStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Queue information if available
                if (reservation.queueBased &&
                    isConfirmed &&
                    reservation.queueStatus != null)
                  _buildPremiumQueueInfo(reservation),

                const Gap(16),

                // Price and actions with premium styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$currency ${price?.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((isPending || isConfirmed) &&
                              !isCancelled &&
                              !isCompleted)
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.8),
                                      Colors.red.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      _showCancelConfirmation(
                                          context, reservation.id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Text(
                                        'Cancel',
                                        style: AppTextStyle.getbodyStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showReservationDetails(
                                        context, reservation);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      'Details',
                                      style: AppTextStyle.getbodyStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSubscriptionCard(
      BuildContext context, SubscriptionModel subscription) {
    final status = subscription.status.toLowerCase();
    final isActive = status == 'active';
    final isPending = status == 'pending';
    final isCancelled = status == 'cancelled';
    final isExpired = status == 'expired';

    // Status styling with premium colors
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = const Color(0xFF66BB6A);
      statusText = 'Active';
      statusIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      statusColor = const Color(0xFFFFB74D);
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF5350);
      statusText = 'Cancelled';
      statusIcon = Icons.cancel_rounded;
    } else if (isExpired) {
      statusColor = const Color(0xFFFF8A65);
      statusText = 'Expired';
      statusIcon = Icons.access_time_rounded;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = Icons.help_outline_rounded;
    }

    // Format dates
    final startDate = subscription.startDate.toDate();
    final expiryDate = subscription.expiryDate.toDate();
    final formattedStartDate = DateFormat('MMM d, yyyy').format(startDate);
    final formattedExpiryDate = DateFormat('MMM d, yyyy').format(expiryDate);

    // Calculate progress for active subscriptions
    double progressValue = 0.0;
    int daysRemaining = 0;

    if (isActive) {
      final now = DateTime.now();
      final totalDuration = expiryDate.difference(startDate).inDays;
      final elapsedDuration = now.difference(startDate).inDays;

      if (totalDuration > 0) {
        progressValue = elapsedDuration / totalDuration;
        progressValue = progressValue.clamp(0.0, 1.0);
        daysRemaining = expiryDate.difference(now).inDays;
      }
    }

    final price = subscription.pricePaid;
    final currency = 'EGP';

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with plan name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subscription.planName,
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.8),
                            statusColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: Colors.white,
                          ),
                          const Gap(4),
                          Text(
                            statusText,
                            style: AppTextStyle.getbodyStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Period with premium styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.tealColor.withOpacity(0.3),
                              AppColors.tealColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.date_range_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          '$formattedStartDate - $formattedExpiryDate',
                          style: AppTextStyle.getbodyStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicator for active subscriptions
                if (isActive) ...[
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: AppTextStyle.getbodyStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$daysRemaining days remaining',
                              style: AppTextStyle.getbodyStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Gap(16),

                // Price and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.tealColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$currency ${price.toStringAsFixed(2)}',
                        style: AppTextStyle.getTitleStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isActive || isPending)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.8),
                                      Colors.red.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      _showCancelConfirmationDialog(
                                          context, subscription.id, false);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Text(
                                        'Cancel',
                                        style: AppTextStyle.getbodyStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      // Show details
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Text(
                                        'View',
                                        style: AppTextStyle.getbodyStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium queue info widget
  Widget _buildPremiumQueueInfo(ReservationModel reservation) {
    if (!reservation.queueBased || reservation.queueStatus == null) {
      return const SizedBox.shrink();
    }

    final queueStatus = reservation.queueStatus!;
    Color statusColor = AppColors.primaryColor;

    switch (queueStatus.status) {
      case 'waiting':
        statusColor = const Color(0xFFFFB74D);
        break;
      case 'processing':
        statusColor = const Color(0xFF66BB6A);
        break;
      case 'completed':
        statusColor = const Color(0xFF42A5F5);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF5350);
        break;
    }

    String formattedTime = 'Unknown';
    try {
      formattedTime =
          DateFormat('h:mm a').format(queueStatus.estimatedEntryTime);
    } catch (e) {
      // Use default value if formatting fails
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Queue Position',
                style: AppTextStyle.getbodyStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.8),
                      statusColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#${queueStatus.position}',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Estimated Time',
                style: AppTextStyle.getbodyStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  formattedTime,
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(
      BuildContext context, String itemId, bool isReservation) {
    // Capture the bloc from the original context before building a new context in the dialog
    final myPassesBloc = BlocProvider.of<MyPassesBloc>(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Cancellation',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: AppColors.redColor,
                  size: 32,
                ),
              ),
              const Gap(16),
              Text(
                'Are you sure you want to cancel ${isReservation ? 'this reservation' : 'this subscription'}?',
                style: AppTextStyle.getbodyStyle(),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'This action cannot be undone.',
                style: AppTextStyle.getSmallStyle(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'No, Keep It',
                style: AppTextStyle.getbodyStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                if (isReservation) {
                  myPassesBloc.add(
                    CancelReservationPass(reservationId: itemId),
                  );
                } else {
                  myPassesBloc.add(
                    CancelSubscriptionPass(subscriptionId: itemId),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Method to show reservation details
  void _showReservationDetails(
      BuildContext context, ReservationModel reservation) {
    // Capture the bloc before showing dialog
    final myPassesBloc = BlocProvider.of<MyPassesBloc>(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reservation Details',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: Colors.grey,
                  ),
                ],
              ),
              const Gap(24),

              // Service info
              Text(
                reservation.serviceName ?? 'Service Reservation',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),

              // Details
              _buildDetailRow('Status', _getStatusText(reservation.status)),
              _buildDetailRow(
                  'Date',
                  DateFormat('EEEE, MMMM d, y').format(
                      reservation.reservationStartTime?.toDate() ??
                          DateTime.now())),
              _buildDetailRow(
                  'Time',
                  DateFormat('h:mm a').format(
                      reservation.reservationStartTime?.toDate() ??
                          DateTime.now())),
              if (reservation.queueBased &&
                  reservation.queueStatus != null) ...[
                const Divider(height: 32),
                Text(
                  'Queue Information',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(12),
                _buildDetailRow(
                    'Position', '#${reservation.queueStatus!.position}'),
                _buildDetailRow(
                    'Status', reservation.queueStatus!.status.toUpperCase()),
                _buildDetailRow(
                    'People Ahead', '${reservation.queueStatus!.peopleAhead}'),
                _buildDetailRow(
                    'Estimated Entry',
                    DateFormat('h:mm a')
                        .format(reservation.queueStatus!.estimatedEntryTime)),
              ],

              const Divider(height: 32),

              // Attendees
              Text(
                'Attendees',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(12),
              ...reservation.attendees
                  .map((attendee) => _buildAttendeeRow(attendee)),

              const Gap(24),

              // Buttons
              Row(
                children: [
                  if ((reservation.status == ReservationStatus.pending ||
                          reservation.status == ReservationStatus.confirmed) &&
                      reservation.queueBased &&
                      reservation.queueStatus != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QueueReservationPage(
                                providerId: reservation.providerId,
                                governorateId: reservation.governorateId,
                                serviceId: reservation.serviceId,
                                serviceName: reservation.serviceName,
                                queueReservationId: reservation.queueStatus?.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Queue'),
                      ),
                    ),
                  if (reservation.status == ReservationStatus.pending ||
                      reservation.status == ReservationStatus.confirmed) ...[
                    const Gap(12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showCancelConfirmation(context, reservation.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.redColor,
                          side: const BorderSide(color: AppColors.redColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel Reservation'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to show cancel confirmation dialog
  void _showCancelConfirmation(BuildContext context, String reservationId) {
    // Capture the bloc from the original context before building a new context in the dialog
    final myPassesBloc = BlocProvider.of<MyPassesBloc>(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
            'Are you sure you want to cancel this reservation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              myPassesBloc
                  .add(CancelReservationPass(reservationId: reservationId));
              Navigator.pop(dialogContext);
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.redColor)),
          ),
        ],
      ),
    );
  }

  // Helper method to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.getbodyStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build attendee row
  Widget _buildAttendeeRow(AttendeeModel attendee) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                style: AppTextStyle.getTitleStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.name,
                  style: AppTextStyle.getbodyStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${attendee.type.toUpperCase()} ${attendee.isHost ? '• HOST' : ''}',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAttendeeStatusColor(attendee.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              attendee.status.toUpperCase(),
              style: AppTextStyle.getSmallStyle(
                color: _getAttendeeStatusColor(attendee.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status text
  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.cancelledByUser:
        return 'Cancelled by User';
      case ReservationStatus.cancelledByProvider:
        return 'Cancelled by Provider';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.noShow:
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get attendee status color
  Color _getAttendeeStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'going':
        return Colors.green;
      case 'invited':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Helper class for filter data
class _FilterData {
  final PassFilter value;
  final String label;
  final IconData icon;

  _FilterData(this.value, this.label, this.icon);
}
