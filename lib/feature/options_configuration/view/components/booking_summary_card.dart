import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:intl/intl.dart';

/// Enhanced Booking Summary Card with Comprehensive Details
class BookingSummaryCard extends StatefulWidget {
  final OptionsConfigurationState state;
  final ServiceProviderModel provider;
  final ServiceModel? service;
  final PlanModel? plan;
  final VoidCallback? onEditBooking;

  const BookingSummaryCard({
    super.key,
    required this.state,
    required this.provider,
    this.service,
    this.plan,
    this.onEditBooking,
  });

  @override
  State<BookingSummaryCard> createState() => _BookingSummaryCardState();
}

class _BookingSummaryCardState extends State<BookingSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildServiceDetails(),
            _buildBookingDetails(),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? _buildExpandedDetails()
                  : const SizedBox.shrink(),
            ),
            _buildCostBreakdown(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.cyanColor],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              CupertinoIcons.doc_text_fill,
              color: Colors.white,
              size: 26,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Summary',
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  'Review your booking details',
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    color: AppColors.lightText.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    final serviceName = widget.service?.name ?? widget.plan?.name ?? 'Service';
    final providerName = widget.provider.businessName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.briefcase_fill,
                color: AppColors.tealColor,
                size: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: app_text_style.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'by $providerName',
                    style: app_text_style.getbodyStyle(
                      color: AppColors.lightText.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confirmed',
                style: app_text_style.getSmallStyle(
                  color: AppColors.greenColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailRow(
            icon: CupertinoIcons.calendar,
            iconColor: AppColors.primaryColor,
            title: 'Date & Time',
            value: _getDateTimeText(),
          ),
          const Gap(16),
          _buildDetailRow(
            icon: CupertinoIcons.person_2_fill,
            iconColor: AppColors.cyanColor,
            title: 'Attendees',
            value:
                '${widget.state.selectedAttendees.length + (widget.state.includeUserInBooking ? 1 : 0)} person${widget.state.selectedAttendees.length + (widget.state.includeUserInBooking ? 1 : 0) != 1 ? 's' : ''}',
          ),
          const Gap(16),
          _buildDetailRow(
            icon: CupertinoIcons.location_fill,
            iconColor: AppColors.tealColor,
            title: 'Venue',
            value: _getVenueText(),
          ),
          const Gap(16),
          _buildDetailRow(
            icon: CupertinoIcons.creditcard_fill,
            iconColor: AppColors.greenColor,
            title: 'Payment',
            value: _getPaymentMethodText(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(2),
              Text(
                value,
                style: app_text_style.getbodyStyle(
                  color: AppColors.lightText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(
            color: Colors.white24,
            thickness: 1,
          ),
          const Gap(16),
          Text(
            'Additional Details',
            style: app_text_style.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),
          if (widget.state.enableReminders) ...[
            _buildDetailRow(
              icon: CupertinoIcons.bell_fill,
              iconColor: AppColors.orangeColor,
              title: 'Reminders',
              value: _getReminderText(),
            ),
            const Gap(16),
          ],
          if (widget.state.notes?.isNotEmpty == true) ...[
            _buildDetailRow(
              icon: CupertinoIcons.text_quote,
              iconColor: AppColors.primaryColor,
              title: 'Notes',
              value: widget.state.notes!,
            ),
            const Gap(16),
          ],
          if (widget.state.venueBookingConfig != null) ...[
            _buildDetailRow(
              icon: CupertinoIcons.house_fill,
              iconColor: AppColors.tealColor,
              title: 'Venue Details',
              value: _getVenueDetailsText(),
            ),
            const Gap(16),
          ],
          _buildDetailRow(
            icon: CupertinoIcons.share_solid,
            iconColor: AppColors.cyanColor,
            title: 'Sharing',
            value: widget.state.enableSharing
                ? 'Social sharing enabled'
                : 'Private booking',
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final basePrice = widget.service?.price ?? widget.plan?.price ?? 0.0;
    final attendeeMultiplier =
        widget.state.selectedAttendees.length.toDouble() +
            (widget.state.includeUserInBooking ? 1.0 : 0.0);
    final subtotal = basePrice * attendeeMultiplier;

    // Calculate additional costs based on selections
    double venueCost = 0.0;
    if (widget.state.venueBookingConfig?.type == VenueBookingType.fullVenue) {
      venueCost = subtotal * 0.15; // 15% venue setup fee for full venue
    }

    double premiumFeatures = 0.0;
    if (widget.state.selectedAddOns.isNotEmpty) {
      // Calculate add-ons cost
      premiumFeatures = widget.state.addOnsPrice;
    }

    final tax = (subtotal + venueCost + premiumFeatures) * 0.1; // 10% tax
    final total = subtotal + venueCost + premiumFeatures + tax;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.1),
              AppColors.cyanColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: AppColors.greenColor,
                  size: 24,
                ),
                const Gap(12),
                Text(
                  'Cost Breakdown',
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Gap(20),
            _buildCostRow('Service fee', 'EGP ${basePrice.toStringAsFixed(2)}'),
            if (attendeeMultiplier > 1)
              _buildCostRow('× ${attendeeMultiplier.toInt()} attendees',
                  'EGP ${subtotal.toStringAsFixed(2)}'),
            if (venueCost > 0)
              _buildCostRow(
                  'Venue setup fee', 'EGP ${venueCost.toStringAsFixed(2)}'),
            if (premiumFeatures > 0)
              _buildCostRow('Add-ons & extras',
                  'EGP ${premiumFeatures.toStringAsFixed(2)}'),
            _buildCostRow('Tax (10%)', 'EGP ${tax.toStringAsFixed(2)}'),
            const Gap(12),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const Gap(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: app_text_style.getTitleStyle(
                    color: AppColors.lightText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.greenColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'EGP ${total.toStringAsFixed(2)}',
                    style: app_text_style.getTitleStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            amount,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: widget.onEditBooking,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.lightText.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.pencil,
                      color: AppColors.lightText.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const Gap(8),
                    Text(
                      'Edit Details',
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _shareBooking(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cyanColor, AppColors.tealColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.share,
                          color: Colors.white,
                          size: 16,
                        ),
                        const Gap(8),
                        Text(
                          'Share',
                          style: app_text_style.getbodyStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateTimeText() {
    if (widget.state.selectedDate != null &&
        widget.state.selectedTime != null) {
      final date = DateFormat('MMM d, yyyy').format(widget.state.selectedDate!);
      return '$date at ${widget.state.selectedTime}';
    }
    return 'Not selected';
  }

  String _getVenueText() {
    if (widget.state.venueBookingConfig != null) {
      final config = widget.state.venueBookingConfig!;
      switch (config.type) {
        case VenueBookingType.fullVenue:
          return 'Full venue booking';
        case VenueBookingType.partialCapacity:
          return 'Partial capacity (${config.selectedCapacity} seats)';
      }
    }
    return 'Provider\'s location';
  }

  String _getVenueDetailsText() {
    if (widget.state.venueBookingConfig != null) {
      final config = widget.state.venueBookingConfig!;
      final details = <String>[];

      if (config.type == VenueBookingType.fullVenue) {
        details.add('Full venue reserved');
      } else {
        details.add('${config.selectedCapacity} seats reserved');
      }

      if (config.isPrivateEvent) {
        details.add('Private event');
      }

      return details.join(' • ');
    }
    return 'Standard booking';
  }

  String _getPaymentMethodText() {
    switch (widget.state.paymentMethod) {
      case 'creditCard':
        return 'Credit Card';
      case 'debitCard':
        return 'Debit Card';
      case 'applePay':
        return 'Apple Pay';
      case 'googlePay':
        return 'Google Pay';
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Pay on Arrival';
      default:
        return 'Not selected';
    }
  }

  String _getReminderText() {
    final times = widget.state.reminderTimes;
    if (times.isEmpty) return 'No reminders set';
    if (times.length == 1) {
      final minutes = times.first;
      if (minutes < 60) {
        return '$minutes minutes before';
      } else if (minutes < 1440) {
        return '${(minutes / 60).round()} hours before';
      } else {
        return '${(minutes / 1440).round()} days before';
      }
    }
    return '${times.length} reminders set';
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _shareBooking() {
    // Implement sharing functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: Text(
          'Share Booking',
          style: app_text_style.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Share your booking details with friends and family.',
          style: app_text_style.getbodyStyle(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: app_text_style.getbodyStyle(
                color: AppColors.lightText.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement actual sharing logic here
            },
            child: Text(
              'Share',
              style: app_text_style.getbodyStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
