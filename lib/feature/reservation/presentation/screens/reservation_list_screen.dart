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
  const ReservationListScreen({Key? key}) : super(key: key);

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
  const ReservationListView({Key? key}) : super(key: key);

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
            child: Icon(
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

    if (isPending) {
      statusColor = Colors.orange;
      statusText = 'Pending';
    } else if (isConfirmed) {
      statusColor = AppColors.greenColor;
      statusText = 'Confirmed';
    } else if (isCancelled) {
      statusColor = AppColors.redColor;
      statusText = 'Cancelled';
    } else if (isCompleted) {
      statusColor = Colors.blue;
      statusText = 'Completed';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
    }

    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d, yyyy').format(dateTime)
        : 'No date';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'No time';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.serviceName ?? 'Service Reservation',
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyle.getSmallStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: AppColors.secondaryText,
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
                  size: 16,
                  color: AppColors.secondaryText,
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
            const Gap(8),
            if (reservation.groupSize > 1) ...[
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_2,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const Gap(4),
                  Text(
                    'Group Size: ${reservation.groupSize}',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const Gap(8),
            ],
            if (reservation.totalPrice != null) ...[
              Text(
                'Total: ${reservation.totalPrice!.toStringAsFixed(2)} EGP',
                style: AppTextStyle.getTitleStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(12),
            ],
            if (isPending || isConfirmed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isConfirmed) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        // Handle view details - could navigate to a detail page
                      },
                      icon: const Icon(CupertinoIcons.doc_text),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                    const Gap(8),
                  ],
                  if (isPending || isConfirmed) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _showCancellationDialog(reservation.id);
                      },
                      icon: const Icon(CupertinoIcons.xmark_circle),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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
