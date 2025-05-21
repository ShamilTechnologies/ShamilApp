import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

class PassesContent extends StatelessWidget {
  final PassType passType;

  const PassesContent({
    Key? key,
    required this.passType,
  }) : super(key: key);

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
          return _buildLoadingShimmer();
        }

        if (state is MyPassesLoaded) {
          // Use a default filter if the current one is null
          final currentFilter = state.currentFilter ?? PassFilter.all;

          final items = passType == PassType.reservation
              ? state.filteredReservations
              : state.filteredSubscriptions;

          if (items.isEmpty) {
            // Check if we have any items before filtering
            final allItems = passType == PassType.reservation
                ? state.reservations
                : state.subscriptions;

            if (allItems.isEmpty) {
              return _buildEmptyState(context);
            } else {
              // If we have items but filter caused empty result, show filter empty state
              return _buildFilterEmptyState(context, currentFilter);
            }
          }

          return passType == PassType.reservation
              ? _buildReservationList(
                  context, state.filteredReservations, currentFilter)
              : _buildSubscriptionList(
                  context, state.filteredSubscriptions, currentFilter);
        }

        if (state is MyPassesError) {
          return _buildErrorState(context, state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // UI builders
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: passType == PassType.reservation ? 180 : 220,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 200,
                          height: 24,
                          color: Colors.white,
                        ),
                        Container(
                          width: 80,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const Gap(18),
                    // Content box
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Spacer(),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(width: 80, height: 36, color: Colors.white),
                        const Gap(8),
                        Container(width: 80, height: 36, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
              passType == PassType.reservation
                  ? CupertinoIcons.calendar
                  : CupertinoIcons.creditcard,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            passType == PassType.reservation
                ? 'No Reservations Yet'
                : 'No Subscriptions Yet',
            style: AppTextStyle.getTitleStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              passType == PassType.reservation
                  ? 'Book your first service to see your reservations here'
                  : 'Subscribe to a plan to see your subscriptions here',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(32),
          CustomButton(
            onPressed: () {
              // Navigate to explore page to browse services/plans
              Navigator.of(context).pop();
            },
            text: passType == PassType.reservation
                ? 'Browse Services'
                : 'Browse Plans',
            width: 220,
            height: 50,
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
            color: AppColors.redColor,
            size: 48,
          ),
          const Gap(16),
          Text(
            passType == PassType.reservation
                ? 'Error Loading Reservations'
                : 'Error Loading Subscriptions',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            message,
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          CustomButton(
            onPressed: () {
              context.read<MyPassesBloc>().add(const LoadMyPasses());
            },
            text: 'Try Again',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(BuildContext context,
      List<ReservationModel> reservations, PassFilter currentFilter) {
    // Upcoming and past sections are now handled by the bloc's filtered lists

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MyPassesBloc>().add(const RefreshMyPasses());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All',
                    currentFilter == PassFilter.all, PassFilter.all),
                _buildFilterChip(context, 'Upcoming',
                    currentFilter == PassFilter.upcoming, PassFilter.upcoming),
                _buildFilterChip(
                    context,
                    'Completed',
                    currentFilter == PassFilter.completed,
                    PassFilter.completed),
                _buildFilterChip(
                    context,
                    'Cancelled',
                    currentFilter == PassFilter.cancelled,
                    PassFilter.cancelled),
              ],
            ),
          ),
          const Gap(16),

          // Reservation cards
          ...reservations.map(
              (reservation) => _buildReservationCard(context, reservation)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(BuildContext context,
      List<SubscriptionModel> subscriptions, PassFilter currentFilter) {
    // Active and inactive sections are now handled by the bloc's filtered lists

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MyPassesBloc>().add(const RefreshMyPasses());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All',
                    currentFilter == PassFilter.all, PassFilter.all),
                _buildFilterChip(context, 'Active',
                    currentFilter == PassFilter.active, PassFilter.active),
                _buildFilterChip(context, 'Expired',
                    currentFilter == PassFilter.expired, PassFilter.expired),
                _buildFilterChip(
                    context,
                    'Cancelled',
                    currentFilter == PassFilter.cancelled,
                    PassFilter.cancelled),
              ],
            ),
          ),
          const Gap(16),

          // Subscription cards
          ...subscriptions.map(
              (subscription) => _buildSubscriptionCard(context, subscription)),
        ],
      ),
    );
  }

  Widget _buildReservationCard(
      BuildContext context, ReservationModel reservation) {
    final isPending = reservation.status == ReservationStatus.pending;
    final isConfirmed = reservation.status == ReservationStatus.confirmed;
    final isCancelled =
        reservation.status == ReservationStatus.cancelledByUser ||
            reservation.status == ReservationStatus.cancelledByProvider;
    final isCompleted = reservation.status == ReservationStatus.completed;

    // Status info
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPending) {
      statusColor = const Color(0xFFFAAD14); // Orange
      statusText = 'Pending';
      statusIcon = CupertinoIcons.clock;
    } else if (isConfirmed) {
      statusColor = const Color(0xFF52C41A); // Green
      statusText = 'Confirmed';
      statusIcon = CupertinoIcons.checkmark_circle;
    } else if (isCancelled) {
      statusColor = const Color(0xFFFF4D4F); // Red
      statusText = 'Cancelled';
      statusIcon = CupertinoIcons.xmark_circle;
    } else if (isCompleted) {
      statusColor = const Color(0xFF1890FF); // Blue
      statusText = 'Completed';
      statusIcon = CupertinoIcons.checkmark_seal;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = CupertinoIcons.question_circle;
    }

    // Date/Time formatting
    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d, yyyy').format(dateTime)
        : 'No date';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'No time';

    // Determine provider name from typeSpecificData if available
    final providerName =
        reservation.typeSpecificData?['providerName'] as String? ?? '';

    // Get price and currency from typeSpecificData or directly from totalPrice
    final price = reservation.totalPrice;
    final currency = 'EGP'; // Default currency

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Status indicator at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor,
                      statusColor.withOpacity(0.7),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with service name and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.calendar,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                reservation.serviceName ??
                                    'Service Reservation',
                                style: AppTextStyle.getTitleStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            const Gap(4),
                            Text(
                              statusText,
                              style: AppTextStyle.getSmallStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Details box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    size: 16,
                                    color: AppColors.secondaryText,
                                  ),
                                  const Gap(8),
                                  Text(
                                    formattedDate,
                                    style: AppTextStyle.getSmallStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.clock,
                                    size: 16,
                                    color: AppColors.secondaryText,
                                  ),
                                  const Gap(8),
                                  Text(
                                    formattedTime,
                                    style: AppTextStyle.getSmallStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (providerName.isNotEmpty) ...[
                                const Gap(8),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.location,
                                      size: 16,
                                      color: AppColors.secondaryText,
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        providerName,
                                        style: AppTextStyle.getSmallStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$currency ${price?.toStringAsFixed(2) ?? '0.00'}',
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 16,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Queue information for queue-based reservations
                  if (reservation.queueBased && isConfirmed)
                    _buildQueueInfo(reservation),

                  const Gap(16),

                  // Button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (reservation.queueBased &&
                          isConfirmed &&
                          reservation.queueStatus != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to queue details screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QueueReservationPage(
                                  providerId: reservation.providerId,
                                  governorateId: reservation.governorateId,
                                  serviceId: reservation.serviceId,
                                  serviceName: reservation.serviceName,
                                  queueReservationId:
                                      reservation.queueStatus?.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(CupertinoIcons.person_3_fill,
                              size: 16),
                          label: const Text('View Queue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (reservation.queueBased &&
                          isConfirmed &&
                          reservation.queueStatus != null)
                        const Gap(8),
                      if ((isPending || isConfirmed) &&
                          !isCancelled &&
                          !isCompleted)
                        OutlinedButton(
                          onPressed: () {
                            _showCancelConfirmation(context, reservation.id);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.redColor,
                            side: const BorderSide(color: AppColors.redColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      const Gap(8),
                      Container(
                        width: 100, // Fixed width to avoid infinite constraints
                        child: ElevatedButton(
                          onPressed: () {
                            _showReservationDetails(context, reservation);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Details'),
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
    );
  }

  Widget _buildSubscriptionCard(
      BuildContext context, SubscriptionModel subscription) {
    // Determine subscription status
    final status = subscription.status.toLowerCase();
    final isActive = status == 'active';
    final isPending = status == 'pending';
    final isCancelled = status == 'cancelled';
    final isExpired = status == 'expired';
    final isPaymentFailed = status == 'payment_failed';

    // Status styling
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = const Color(0xFF52C41A); // Green
      statusText = 'Active';
      statusIcon = CupertinoIcons.checkmark_circle;
    } else if (isPending) {
      statusColor = const Color(0xFFFAAD14); // Orange
      statusText = 'Pending';
      statusIcon = CupertinoIcons.clock;
    } else if (isCancelled) {
      statusColor = const Color(0xFFFF4D4F); // Red
      statusText = 'Cancelled';
      statusIcon = CupertinoIcons.xmark_circle;
    } else if (isExpired) {
      statusColor = const Color(0xFFFAAD14); // Orange
      statusText = 'Expired';
      statusIcon = CupertinoIcons.timer;
    } else if (isPaymentFailed) {
      statusColor = const Color(0xFFFF4D4F); // Red
      statusText = 'Payment Failed';
      statusIcon = CupertinoIcons.exclamationmark_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = CupertinoIcons.question_circle;
    }

    // Calculate progress for active subscriptions
    double progressValue = 0.0;
    int daysRemaining = 0;

    if (isActive) {
      final startDate = subscription.startDate.toDate();
      final expiryDate = subscription.expiryDate.toDate();
      final now = DateTime.now();

      final totalDuration = expiryDate.difference(startDate).inDays;
      final elapsedDuration = now.difference(startDate).inDays;

      if (totalDuration > 0) {
        progressValue = elapsedDuration / totalDuration;
        // Clamp progress value between 0 and 1
        progressValue = progressValue.clamp(0.0, 1.0);
        daysRemaining = expiryDate.difference(now).inDays;
      }
    }

    // Format dates
    final startDate = subscription.startDate.toDate();
    final expiryDate = subscription.expiryDate.toDate();

    final formattedStartDate = DateFormat('MMM d, yyyy').format(startDate);
    final formattedExpiryDate = DateFormat('MMM d, yyyy').format(expiryDate);

    // Get provider name from the provider repository or use a default
    final providerName =
        ''; // This would come from a provider repository lookup

    // Use pricePaid for the price and default currency
    final price = subscription.pricePaid;
    final currency = 'EGP'; // Default currency

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Status indicator at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor,
                      statusColor.withOpacity(0.7),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with plan name and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.creditcard,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                subscription.planName,
                                style: AppTextStyle.getTitleStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            const Gap(4),
                            Text(
                              statusText,
                              style: AppTextStyle.getSmallStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Details box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Period',
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              '$formattedStartDate - $formattedExpiryDate',
                              style: AppTextStyle.getSmallStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),

                        // Provider
                        if (providerName.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Provider',
                                style: AppTextStyle.getSmallStyle(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                providerName,
                                style: AppTextStyle.getSmallStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                        ],

                        // Billing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Billing',
                              style: AppTextStyle.getSmallStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              '$currency ${price.toStringAsFixed(2)} / ${subscription.billingCycle ?? 'month'}',
                              style: AppTextStyle.getSmallStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),

                        // Progress indicator for active subscriptions
                        if (isActive) ...[
                          const Gap(16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              color: statusColor,
                              minHeight: 10,
                            ),
                          ),
                          const Gap(8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Usage',
                                style: AppTextStyle.getSmallStyle(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                '$daysRemaining days remaining',
                                style: AppTextStyle.getSmallStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons
                  if (isActive || isPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Show details
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                side: const BorderSide(
                                    color: AppColors.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              child: const Text('View'),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Show cancel confirmation dialog
                                _showCancelConfirmationDialog(
                                    context, subscription.id, false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.redColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildFilterChip(
      BuildContext context, String label, bool isSelected, PassFilter filter) {
    final isActive = label == 'Active' || label == 'Upcoming';
    final isAll = label == 'All';
    final isPast = label == 'Completed';
    final isCancelled = label == 'Cancelled';

    Color chipColor;
    if (isActive) {
      chipColor = const Color(0xFF52C41A);
    } else if (isPast) {
      chipColor = const Color(0xFF1890FF);
    } else if (isCancelled) {
      chipColor = const Color(0xFFFF4D4F);
    } else {
      chipColor = AppColors.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          selected: isSelected,
          onSelected: (selected) {
            // Apply the filter if it's not already selected
            if (selected && !isSelected) {
              // Use BlocProvider.of instead of context.read for better error handling
              final bloc = BlocProvider.of<MyPassesBloc>(context);
              if (bloc.state is MyPassesLoaded) {
                bloc.add(ChangePassFilter(filter));
              }
            }
          },
          backgroundColor: Colors.white,
          selectedColor: chipColor.withOpacity(0.15),
          checkmarkColor: chipColor,
          labelStyle: AppTextStyle.getSmallStyle(
            color: isSelected ? chipColor : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive && isSelected)
                Icon(CupertinoIcons.calendar_badge_plus,
                    size: 14, color: chipColor)
              else if (isPast && isSelected)
                Icon(CupertinoIcons.checkmark_circle,
                    size: 14, color: chipColor)
              else if (isCancelled && isSelected)
                Icon(CupertinoIcons.xmark_circle, size: 14, color: chipColor)
              else if (isAll && isSelected)
                Icon(CupertinoIcons.layers_alt, size: 14, color: chipColor),
              if (isSelected) const Gap(4),
              Text(label),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(
              color: isSelected ? chipColor : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          elevation: isSelected ? 0 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          showCheckmark: false,
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(BuildContext context, PassFilter filter) {
    String filterText = '';
    Color filterColor;

    // Determine filter text and color based on pass type and filter
    if (passType == PassType.reservation) {
      if (filter == PassFilter.upcoming) {
        filterText = 'upcoming';
        filterColor = const Color(0xFF52C41A); // Green
      } else if (filter == PassFilter.completed) {
        filterText = 'completed';
        filterColor = const Color(0xFF1890FF); // Blue
      } else {
        filterText = 'cancelled';
        filterColor = const Color(0xFFFF4D4F); // Red
      }
    } else {
      if (filter == PassFilter.active) {
        filterText = 'active';
        filterColor = const Color(0xFF52C41A); // Green
      } else if (filter == PassFilter.expired) {
        filterText = 'expired';
        filterColor = const Color(0xFFFAAD14); // Orange
      } else {
        filterText = 'cancelled';
        filterColor = const Color(0xFFFF4D4F); // Red
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: filterColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filter == PassFilter.upcoming || filter == PassFilter.active
                  ? CupertinoIcons.calendar_badge_plus
                  : filter == PassFilter.completed ||
                          filter == PassFilter.expired
                      ? CupertinoIcons.checkmark_circle
                      : CupertinoIcons.xmark_circle,
              color: filterColor,
              size: 48,
            ),
          ),
          const Gap(20),
          Text(
            'No ${filterText} ${passType == PassType.reservation ? 'reservations' : 'subscriptions'}',
            style: AppTextStyle.getTitleStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try selecting a different filter to view your other passes',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(32),
          CustomButton(
            onPressed: () {
              // Reset filter to 'All'
              final bloc = BlocProvider.of<MyPassesBloc>(context);
              bloc.add(const ChangePassFilter(PassFilter.all));
            },
            text: 'Show All Passes',
            width: 220,
            height: 50,
            color: filterColor,
          ),
        ],
      ),
    );
  }

  // Add a method to display queue information
  Widget _buildQueueInfo(ReservationModel reservation) {
    if (!reservation.queueBased || reservation.queueStatus == null) {
      return const SizedBox.shrink();
    }

    final queueStatus = reservation.queueStatus!;
    Color statusColor;
    IconData statusIcon;

    switch (queueStatus.status) {
      case 'waiting':
        statusColor = Colors.orange;
        statusIcon = CupertinoIcons.time;
        break;
      case 'processing':
        statusColor = Colors.green;
        statusIcon = CupertinoIcons.arrow_right_circle_fill;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = CupertinoIcons.checkmark_circle_fill;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = CupertinoIcons.xmark_circle_fill;
        break;
      case 'no_show':
        statusColor = Colors.grey;
        statusIcon = CupertinoIcons.person_crop_circle_badge_xmark;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = CupertinoIcons.question_circle;
    }

    // Safely format the estimated entry time
    String formattedTime = 'Unknown';
    try {
      if (queueStatus.estimatedEntryTime != null) {
        formattedTime = queueStatus.estimatedEntryTime
            .toLocal()
            .toString()
            .substring(11, 16);
      }
    } catch (e) {
      // Use default value if formatting fails
      print('Error formatting time: $e');
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const Gap(8),
              Text(
                'Queue Status: ${queueStatus.status?.toUpperCase() ?? "UNKNOWN"}',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position: #${queueStatus.position}',
                    style: AppTextStyle.getbodyStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'People ahead: ${queueStatus.peopleAhead}',
                    style: AppTextStyle.getbodyStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Estimated time:',
                    style: AppTextStyle.getbodyStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formattedTime,
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
