import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

import '../../../core/payment/bloc/payment_bloc.dart';
import '../../../core/payment/ui/widgets/modern_payment_widget.dart';
import '../../../core/payment/models/payment_models.dart';

/// Main Payments Screen integrated into the app navigation
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    _fadeController.forward();

    // Initialize payment system
    _initializePayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializePayments() {
    context.read<PaymentBloc>().add(const InitializePayments());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentBloc(
        stripeService: null, // Use null to let it create its own instance
      )..add(const InitializePayments()),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Decorative background elements
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.07),
                  ),
                ),
              ),

              // Main content
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: innerBoxIsScrolled
                          ? AppColors.primaryColor
                          : Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryColor,
                                AppColors.secondaryColor,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.payment,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const Gap(12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Payments',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Manage your transactions',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
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
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: const [
                          Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                          Tab(icon: Icon(Icons.add_card), text: 'New Payment'),
                          Tab(icon: Icon(Icons.history), text: 'History'),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildNewPaymentTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        if (state is PaymentError) {
          return _buildErrorState(state.message);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(state),
              const Gap(20),
              _buildQuickActions(),
              const Gap(20),
              _buildRecentTransactions(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewPaymentTab() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Payment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Gap(8),
              Text(
                'Choose a payment method and amount',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Gap(20),
              _buildPaymentScenarios(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        List<PaymentResponse> history = [];
        if (state is PaymentLoaded) {
          history = state.paymentHistory;
        }

        if (history.isEmpty) {
          return _buildEmptyState('No payment history found');
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<PaymentBloc>()
                .add(const LoadPaymentHistory(isRefresh: true));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(history[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(PaymentState state) {
    double totalSpent = 0.0;
    int totalTransactions = 0;

    if (state is PaymentLoaded) {
      final stats = state.statistics;
      totalSpent = (stats['totalAmount'] as num?)?.toDouble() ?? 0.0;
      totalTransactions = (stats['totalPayments'] as int?) ?? 0;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Spent',
            value: 'EGP ${totalSpent.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
            color: AppColors.primaryColor,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            title: 'Transactions',
            value: totalTransactions.toString(),
            icon: Icons.receipt_long,
            color: AppColors.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Service Payment',
                subtitle: 'Pay for bookings',
                icon: Icons.build,
                color: AppColors.primaryColor,
                onTap: () => _showServicePaymentDialog(),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionCard(
                title: 'Subscription',
                subtitle: 'Monthly plans',
                icon: Icons.subscriptions,
                color: AppColors.secondaryColor,
                onTap: () => _showSubscriptionPaymentDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScenarios() {
    final scenarios = [
      {
        'title': 'Service Booking',
        'description': 'Pay for professional services',
        'amount': 250.0,
        'icon': Icons.build,
        'color': const Color(0xFF2a548d),
      },
      {
        'title': 'Subscription Plan',
        'description': 'Monthly premium features',
        'amount': 99.0,
        'icon': Icons.subscriptions,
        'color': const Color(0xFF6385c3),
      },
      {
        'title': 'Cash Payment',
        'description': 'Pay with cash at Fawry',
        'amount': 150.0,
        'icon': Icons.store,
        'color': Colors.orange,
      },
    ];

    return Column(
      children: scenarios.map((scenario) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showPaymentDialog(scenario),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (scenario['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      scenario['icon'] as IconData,
                      color: scenario['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          scenario['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'EGP ${(scenario['amount'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Gap(8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(PaymentState state) {
    List<PaymentResponse> recentTransactions = [];

    if (state is PaymentLoaded) {
      recentTransactions = state.paymentHistory.take(3).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const Gap(12),
        if (recentTransactions.isEmpty)
          _buildEmptyState('No recent transactions')
        else
          ...recentTransactions
              .map((transaction) => _buildTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildTransactionCard(PaymentResponse transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(transaction.status),
              color: _getStatusColor(transaction.status),
              size: 20,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment #${transaction.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Gap(4),
                Text(
                  _formatDate(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${transaction.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const Gap(16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const Gap(16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const Gap(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: () =>
                  context.read<PaymentBloc>().add(const InitializePayments()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showServicePaymentDialog() {
    _showPaymentDialog({
      'title': 'Service Booking',
      'description': 'Pay for professional services',
      'amount': 250.0,
      'icon': Icons.build,
      'color': const Color(0xFF2a548d),
    });
  }

  void _showSubscriptionPaymentDialog() {
    _showPaymentDialog({
      'title': 'Subscription Plan',
      'description': 'Monthly premium features',
      'amount': 99.0,
      'icon': Icons.subscriptions,
      'color': const Color(0xFF6385c3),
    });
  }

  void _showPaymentDialog(Map<String, dynamic> scenario) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make payments')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: BlocProvider.value(
            value: context.read<PaymentBloc>(),
            child: ModernPaymentWidget(
              amount: PaymentAmount(
                amount: scenario['amount'] as double,
                currency: Currency.egp,
              ),
              customer: PaymentCustomer(
                id: user.uid,
                name: user.displayName ?? 'User',
                email: user.email ?? '',
                phone: user.phoneNumber,
              ),
              description: scenario['description'] as String,
              onPaymentSuccess: () {
                Navigator.pop(context);
                _showSuccessDialog(scenario);
              },
              onPaymentFailure: () {
                Navigator.pop(context);
                _showErrorDialog('Payment failed. Please try again.');
              },
              onPaymentCancelled: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> scenario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const Gap(16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Gap(8),
            Text(
              'Your payment for ${scenario['title']} has been processed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh data
              context
                  .read<PaymentBloc>()
                  .add(const LoadPaymentHistory(isRefresh: true));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
            ),
            const Gap(16),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Gap(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return Colors.red;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Icons.access_time;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return Icons.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.undo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
