import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/bloc/list/reservation_list_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

class ReservationListScreen extends StatelessWidget {
  const ReservationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationListBloc(
        userRepository: context.read<UserRepository>(),
      )..add(const LoadReservationList()),
      child: const ReservationListView(),
    );
  }
}

class ReservationListView extends StatefulWidget {
  const ReservationListView({super.key});

  @override
  State<ReservationListView> createState() => _ReservationListViewState();
}

class _ReservationListViewState extends State<ReservationListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'My Reservations',
          style: AppTextStyle.getTitleStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: () {
              context
                  .read<ReservationListBloc>()
                  .add(const ReservationRefresh());
            },
          ),
        ],
      ),
      body: BlocConsumer<ReservationListBloc, ReservationListState>(
        listener: (context, state) {
          if (state is ReservationListLoaded && state.message != null) {
            showGlobalSnackBar(context, state.message!);
          }
          if (state is ReservationListLoaded && state.error != null) {
            showGlobalSnackBar(context, state.error!, isError: true);
          }
          if (state is ReservationListError) {
            showGlobalSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is ReservationListInitial ||
              state is ReservationListLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ReservationListLoaded) {
            if (state.reservations.isEmpty) {
              return _buildEmptyState();
            }

            return _buildReservationList(state.reservations);
          }

          if (state is ReservationListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: AppTextStyle.getbodyStyle(color: AppColors.redColor),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ReservationListBloc>()
                          .add(const LoadReservationList());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(
              CupertinoIcons.calendar,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(16),
          Text(
            'No Reservations',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'You don\'t have any reservations yet',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          CustomButton(
            onPressed: () {
              Navigator.of(context).pop(); // Go back to explore page
            },
            text: 'Browse Services',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(List<ReservationModel> reservations) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReservationListBloc>().add(const ReservationRefresh());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    final isPending = reservation.status == ReservationStatus.pending;
    final isConfirmed = reservation.status == ReservationStatus.confirmed;
    final isCancelled =
        reservation.status == ReservationStatus.cancelledByUser ||
            reservation.status == ReservationStatus.cancelledByProvider;
    final isCompleted = reservation.status == ReservationStatus.completed;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = CupertinoIcons.clock;
    } else if (isConfirmed) {
      statusColor = AppColors.greenColor;
      statusText = 'Confirmed';
      statusIcon = CupertinoIcons.checkmark_circle;
    } else if (isCancelled) {
      statusColor = AppColors.redColor;
      statusText = 'Cancelled';
      statusIcon = CupertinoIcons.xmark_circle;
    } else if (isCompleted) {
      statusColor = AppColors.primaryColor;
      statusText = 'Completed';
      statusIcon = CupertinoIcons.checkmark_shield;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = CupertinoIcons.question_circle;
    }

    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d').format(dateTime)
        : 'Date not specified';
    final formattedTime = dateTime != null
        ? DateFormat('h:mm a').format(dateTime)
        : 'Time not specified';

    // Calculate payment status
    final totalPrice = reservation.totalPrice ?? 0.0;
    final amountPaid =
        (reservation.paymentDetails?['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = amountPaid >= totalPrice
        ? 'Paid'
        : amountPaid > 0
            ? 'Partial'
            : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
                const Gap(8),
                Text(
                  statusText,
                  style: AppTextStyle.getSmallStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (reservation.isCommunityVisible) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.person_2,
                          color: AppColors.primaryColor,
                          size: 12,
                        ),
                        const Gap(4),
                        Text(
                          'Community',
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name
                Text(
                  reservation.serviceName ?? 'Reservation',
                  style: AppTextStyle.getTitleStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Gap(8),

                // Provider info
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.building_2_fill,
                      color: AppColors.secondaryColor,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      reservation.providerId,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Gap(4),

                // Date and time
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      formattedDate,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Gap(16),
                    const Icon(
                      CupertinoIcons.clock,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      formattedTime,
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),

                const Gap(12),

                // Payment info
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                    const Gap(4),
                    Text(
                      'Total: ${totalPrice.toStringAsFixed(2)}',
                      style: AppTextStyle.getSmallStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Gap(16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentStatus == 'Paid'
                            ? AppColors.greenColor.withOpacity(0.1)
                            : paymentStatus == 'Partial'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paymentStatus,
                        style: AppTextStyle.getSmallStyle(
                          color: paymentStatus == 'Paid'
                              ? AppColors.greenColor
                              : paymentStatus == 'Partial'
                                  ? Colors.orange
                                  : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPending || isConfirmed) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<ReservationListBloc>().add(
                                CancelReservation(
                                    reservationId: reservation.id),
                              );
                        },
                        icon: const Icon(CupertinoIcons.xmark),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.redColor,
                          side: const BorderSide(color: AppColors.redColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        // View reservation details
                      },
                      icon: const Icon(CupertinoIcons.chevron_right),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    );
  }

  void _showCancellationDialog(String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
          'Are you sure you want to cancel this reservation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ReservationListBloc>().add(
                    CancelReservation(reservationId: reservationId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
