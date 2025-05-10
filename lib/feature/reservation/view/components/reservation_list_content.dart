import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/reservation/bloc/reservation_list_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';

class ReservationListContent extends StatelessWidget {
  const ReservationListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReservationListBloc, ReservationListState>(
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
          return _buildLoadingShimmer();
        }

        if (state is ReservationListLoaded) {
          if (state.reservations.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildReservationList(context, state.reservations);
        }

        if (state is ReservationListError) {
          return _buildErrorState(context, state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Gap(12),
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.white),
                      const Gap(4),
                      Container(width: 100, height: 16, color: Colors.white),
                      const Gap(16),
                      Container(width: 20, height: 20, color: Colors.white),
                      const Gap(4),
                      Container(width: 80, height: 16, color: Colors.white),
                    ],
                  ),
                  const Gap(16),
                  Container(width: 150, height: 24, color: Colors.white),
                  const Gap(16),
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
              // Navigate to explore page to browse services
              Navigator.of(context).pop();
            },
            text: 'Browse Services',
            width: 200,
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
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.redColor,
            size: 48,
          ),
          const Gap(16),
          Text(
            'Error Loading Reservations',
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
              context
                  .read<ReservationListBloc>()
                  .add(const LoadReservationList());
            },
            text: 'Try Again',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
      BuildContext context, List<ReservationModel> reservations) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReservationListBloc>().add(const ReservationRefresh());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All', true),
                _buildFilterChip(context, 'Upcoming', false),
                _buildFilterChip(context, 'Completed', false),
                _buildFilterChip(context, 'Cancelled', false),
              ],
            ),
          ),
          const Gap(16),

          // Upcoming heading if any
          if (reservations.any((r) =>
              r.status == ReservationStatus.confirmed ||
              r.status == ReservationStatus.pending)) ...[
            Text(
              'Upcoming Reservations',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            // List upcoming reservations
            ...reservations
                .where((r) =>
                    r.status == ReservationStatus.confirmed ||
                    r.status == ReservationStatus.pending)
                .map((reservation) =>
                    _buildReservationCard(context, reservation))
                .toList(),
            const Gap(24),
          ],

          // Past heading if any
          if (reservations.any((r) =>
              r.status == ReservationStatus.completed ||
              r.status == ReservationStatus.cancelledByUser ||
              r.status == ReservationStatus.cancelledByProvider)) ...[
            Text(
              'Past Reservations',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            // List past reservations
            ...reservations
                .where((r) =>
                    r.status == ReservationStatus.completed ||
                    r.status == ReservationStatus.cancelledByUser ||
                    r.status == ReservationStatus.cancelledByProvider)
                .map((reservation) =>
                    _buildReservationCard(context, reservation))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
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
            // Implement filter functionality
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

  Widget _buildReservationCard(
      BuildContext context, ReservationModel reservation) {
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
      statusColor = const Color(0xFFFAAD14);
      statusText = 'Pending';
      statusIcon = CupertinoIcons.clock;
    } else if (isConfirmed) {
      statusColor = const Color(0xFF52C41A);
      statusText = 'Confirmed';
      statusIcon = CupertinoIcons.checkmark_circle;
    } else if (isCancelled) {
      statusColor = const Color(0xFFFF4D4F);
      statusText = 'Cancelled';
      statusIcon = CupertinoIcons.xmark_circle;
    } else if (isCompleted) {
      statusColor = const Color(0xFF1890FF);
      statusText = 'Completed';
      statusIcon = CupertinoIcons.checkmark_seal;
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
      statusIcon = CupertinoIcons.question_circle;
    }

    final dateTime = reservation.reservationStartTime?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('EEE, MMM d, yyyy').format(dateTime)
        : 'No date';
    final formattedTime =
        dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'No time';

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
        child: Column(
          children: [
            Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              child: Icon(
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
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.calendar,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const Gap(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: AppTextStyle.getSmallStyle(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  formattedDate,
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.clock,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const Gap(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: AppTextStyle.getSmallStyle(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  formattedTime,
                                  style: AppTextStyle.getTitleStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (reservation.groupSize > 1) ...[
                          const Gap(12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  CupertinoIcons.person_2,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const Gap(12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Group Size',
                                    style: AppTextStyle.getSmallStyle(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    '${reservation.groupSize} people',
                                    style: AppTextStyle.getTitleStyle(
                                      fontSize: 14,
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (reservation.totalPrice != null) ...[
                    const Gap(20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.1),
                            AppColors.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTextStyle.getSmallStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${reservation.totalPrice!.toStringAsFixed(2)} EGP',
                            style: AppTextStyle.getTitleStyle(
                              fontSize: 16,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isPending || isConfirmed) ...[
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isConfirmed) ...[
                          SizedBox(
                            width: 120,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Handle view details - could navigate to a detail page
                              },
                              icon:
                                  const Icon(CupertinoIcons.doc_text, size: 18),
                              label: const Text('Details'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                side: BorderSide(color: AppColors.primaryColor),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          ),
                          const Gap(12),
                        ],
                        if (isPending || isConfirmed) ...[
                          SizedBox(
                            width: 120,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showCancellationDialog(
                                    context, reservation.id);
                              },
                              icon: const Icon(CupertinoIcons.xmark_circle,
                                  size: 18),
                              label: const Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancellationDialog(BuildContext context, String reservationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.red,
                size: 24,
              ),
            ),
            const Gap(16),
            const Text('Cancel Reservation'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this reservation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'No, Keep It',
              style: TextStyle(color: Colors.grey),
            ),
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
