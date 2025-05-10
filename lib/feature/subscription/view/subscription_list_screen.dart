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
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';

class SubscriptionListScreen extends StatelessWidget {
  const SubscriptionListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionListBloc(
        userRepository: context.read<UserRepository>(),
      )..add(const LoadSubscriptionList()),
      child: const SubscriptionListView(),
    );
  }
}

class SubscriptionListView extends StatefulWidget {
  const SubscriptionListView({Key? key}) : super(key: key);

  @override
  State<SubscriptionListView> createState() => _SubscriptionListViewState();
}

class _SubscriptionListViewState extends State<SubscriptionListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'My Subscriptions',
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
                  .read<SubscriptionListBloc>()
                  .add(const SubscriptionRefresh());
            },
          ),
        ],
      ),
      body: BlocConsumer<SubscriptionListBloc, SubscriptionListState>(
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SubscriptionListLoaded) {
            if (state.subscriptions.isEmpty) {
              return _buildEmptyState();
            }

            return _buildSubscriptionList(state.subscriptions);
          }

          if (state is SubscriptionListError) {
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
                          .read<SubscriptionListBloc>()
                          .add(const LoadSubscriptionList());
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
              Navigator.of(context).pop(); // Go back to explore page
            },
            text: 'Browse Plans',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(List<SubscriptionModel> subscriptions) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SubscriptionListBloc>().add(const SubscriptionRefresh());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          return _buildSubscriptionCard(subscription);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionModel subscription) {
    // Determine subscription status
    final isActive = subscription.status.toLowerCase() == 'active';
    final isCancelled = subscription.status.toLowerCase() == 'cancelled';
    final isExpired = subscription.status.toLowerCase() == 'expired';

    Color statusColor;
    String statusText;

    if (isActive) {
      statusColor = AppColors.greenColor;
      statusText = 'Active';
    } else if (isCancelled) {
      statusColor = AppColors.redColor;
      statusText = 'Cancelled';
    } else if (isExpired) {
      statusColor = Colors.orange;
      statusText = 'Expired';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
    }

    final startDate = subscription.startDate.toDate();
    final expiryDate = subscription.expiryDate.toDate();

    final formattedStartDate = DateFormat('MMM d, yyyy').format(startDate);
    final formattedExpiryDate = DateFormat('MMM d, yyyy').format(expiryDate);

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
                    subscription.planName,
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
                  CupertinoIcons.calendar_badge_plus,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const Gap(4),
                Text(
                  'Start: $formattedStartDate',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const Gap(6),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar_badge_minus,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const Gap(4),
                Text(
                  'Expires: $formattedExpiryDate',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const Gap(6),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.repeat,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const Gap(4),
                Text(
                  'Billing Cycle: ${subscription.billingCycle ?? "Unknown"}',
                  style: AppTextStyle.getSmallStyle(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const Gap(8),
            if (subscription.groupSize > 1) ...[
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_2,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const Gap(4),
                  Text(
                    'Group Size: ${subscription.groupSize}',
                    style: AppTextStyle.getSmallStyle(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const Gap(8),
            ],
            Text(
              'Price: ${subscription.pricePaid.toStringAsFixed(2)} EGP',
              style: AppTextStyle.getTitleStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            if (isActive) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCancellationDialog(subscription.id);
                    },
                    icon: const Icon(CupertinoIcons.xmark_circle),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancellationDialog(String subscriptionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel this subscription? You will still have access until the current billing period ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Keep It'),
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
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
