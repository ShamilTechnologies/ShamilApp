import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/widgets/custom_button.dart';
import 'package:shamil_mobile_app/feature/subscription/bloc/subscription_list_bloc.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionListContent extends StatelessWidget {
  const SubscriptionListContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionListBloc, SubscriptionListState>(
      listener: (context, state) {
        if (state is SubscriptionListLoaded && state.message != null) {
          showGlobalSnackBar(context, state.message!);
        }
        if (state is SubscriptionListLoaded && state.error != null) {
          showGlobalSnackBar(context, state.error!, isError: true);
        }
        if (state is SubscriptionListError) {
          showGlobalSnackBar(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        if (state is SubscriptionListInitial ||
            state is SubscriptionListLoading) {
          return _buildLoadingShimmer();
        }

        if (state is SubscriptionListLoaded) {
          if (state.subscriptions.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildSubscriptionList(context, state.subscriptions);
        }

        if (state is SubscriptionListError) {
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
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 200,
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
                  const Gap(16),
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.white),
                      const Gap(4),
                      Container(width: 150, height: 16, color: Colors.white),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.white),
                      const Gap(4),
                      Container(width: 150, height: 16, color: Colors.white),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.white),
                      const Gap(4),
                      Container(width: 150, height: 16, color: Colors.white),
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
            child: const Icon(
              CupertinoIcons.creditcard,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(16),
          Text(
            'No Subscriptions',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'You don\'t have any active subscriptions',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          CustomButton(
            onPressed: () {
              // Navigate to explore page to browse plans
              Navigator.of(context).pop();
            },
            text: 'Browse Plans',
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
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.redColor,
            size: 48,
          ),
          const Gap(16),
          Text(
            'Error Loading Subscriptions',
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
                  .read<SubscriptionListBloc>()
                  .add(const LoadSubscriptionList());
            },
            text: 'Try Again',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(
      BuildContext context, List<SubscriptionModel> subscriptions) {
    // Sort subscriptions by status (active first)
    final activeSubscriptions = subscriptions
        .where((s) =>
            s.status.toLowerCase() == 'active' ||
            s.status.toLowerCase() == 'pending')
        .toList();

    final inactiveSubscriptions = subscriptions
        .where((s) =>
            s.status.toLowerCase() == 'cancelled' ||
            s.status.toLowerCase() == 'expired' ||
            s.status.toLowerCase() == 'payment_failed')
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SubscriptionListBloc>().add(const SubscriptionRefresh());
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
                _buildFilterChip(context, 'Active', false),
                _buildFilterChip(context, 'Expired', false),
                _buildFilterChip(context, 'Cancelled', false),
              ],
            ),
          ),
          const Gap(16),

          // Active subscriptions heading if any
          if (activeSubscriptions.isNotEmpty) ...[
            Text(
              'Active Subscriptions',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            ...activeSubscriptions
                .map((subscription) =>
                    _buildSubscriptionCard(context, subscription))
                ,
            const Gap(24),
          ],

          // Inactive subscriptions heading if any
          if (inactiveSubscriptions.isNotEmpty) ...[
            Text(
              'Past Subscriptions',
              style: AppTextStyle.getTitleStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            ...inactiveSubscriptions
                .map((subscription) =>
                    _buildSubscriptionCard(context, subscription))
                ,
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    final isActive = label == 'Active';
    final isAll = label == 'All';
    final isExpired = label == 'Expired';
    final isCancelled = label == 'Cancelled';

    Color chipColor;
    if (isActive) {
      chipColor = const Color(0xFF52C41A);
    } else if (isExpired) {
      chipColor = const Color(0xFFFAAD14);
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
                Icon(CupertinoIcons.creditcard_fill, size: 14, color: chipColor)
              else if (isExpired && isSelected)
                Icon(CupertinoIcons.timer, size: 14, color: chipColor)
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

  Widget _buildSubscriptionCard(
      BuildContext context, SubscriptionModel subscription) {
    // Determine subscription status
    final isActive = subscription.status.toLowerCase() == 'active';
    final isPending = subscription.status.toLowerCase() == 'pending';
    final isCancelled = subscription.status.toLowerCase() == 'cancelled';
    final isExpired = subscription.status.toLowerCase() == 'expired';
    final isPaymentFailed =
        subscription.status.toLowerCase() == 'payment_failed';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = const Color(0xFF52C41A);
      statusText = 'Active';
      statusIcon = CupertinoIcons.checkmark_circle;
    } else if (isPending) {
      statusColor = const Color(0xFFFAAD14);
      statusText = 'Pending';
      statusIcon = CupertinoIcons.clock;
    } else if (isCancelled) {
      statusColor = const Color(0xFFFF4D4F);
      statusText = 'Cancelled';
      statusIcon = CupertinoIcons.xmark_circle;
    } else if (isExpired) {
      statusColor = const Color(0xFFFAAD14);
      statusText = 'Expired';
      statusIcon = CupertinoIcons.timer;
    } else if (isPaymentFailed) {
      statusColor = const Color(0xFFFF4D4F);
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

    final startDate = subscription.startDate.toDate();
    final expiryDate = subscription.expiryDate.toDate();

    final formattedStartDate = DateFormat('MMM d, yyyy').format(startDate);
    final formattedExpiryDate = DateFormat('MMM d, yyyy').format(expiryDate);

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

                  // Progress bar for active subscriptions
                  if (isActive) ...[
                    const Gap(20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.hourglass,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                  ),
                                  const Gap(10),
                                  Text(
                                    'Subscription Progress',
                                    style: AppTextStyle.getSmallStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  '$daysRemaining days left',
                                  style: AppTextStyle.getSmallStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.white,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                        _buildInfoRow(
                          CupertinoIcons.calendar_badge_plus,
                          'Start Date',
                          formattedStartDate,
                        ),
                        const Gap(12),
                        _buildInfoRow(
                          CupertinoIcons.calendar_badge_minus,
                          'Expiry Date',
                          formattedExpiryDate,
                        ),
                        const Gap(12),
                        _buildInfoRow(
                          CupertinoIcons.repeat,
                          'Billing Cycle',
                          subscription.billingCycle ?? 'Unknown',
                        ),
                        if (subscription.groupSize > 1) ...[
                          const Gap(12),
                          _buildInfoRow(
                            CupertinoIcons.person_2,
                            'Group Size',
                            '${subscription.groupSize} people',
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Price section
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
                          'Payment Amount',
                          style: AppTextStyle.getSmallStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${subscription.pricePaid.toStringAsFixed(2)} EGP',
                          style: AppTextStyle.getTitleStyle(
                            fontSize: 16,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isActive) ...[
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Handle view details - could navigate to a detail page
                          },
                          icon: const Icon(CupertinoIcons.doc_text, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: const BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        const Gap(12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showCancellationDialog(context, subscription.id);
                          },
                          icon:
                              const Icon(CupertinoIcons.xmark_circle, size: 18),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryColor,
          ),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyle.getSmallStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(2),
            Text(
              value,
              style: AppTextStyle.getTitleStyle(
                fontSize: 14,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancellationDialog(BuildContext context, String subscriptionId) {
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
            const Text('Cancel Subscription'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this subscription? You will still have access until the current billing period ends.',
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
              context.read<SubscriptionListBloc>().add(
                    CancelSubscription(subscriptionId: subscriptionId),
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
