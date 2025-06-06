import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';

/// Attendee Manager Component
class AttendeeManager extends StatefulWidget {
  final OptionsConfigurationState state;
  final Function(AttendeeModel) onAttendeeAdded;
  final Function(String) onAttendeeRemoved;
  final Function(AttendeeModel) onAttendeeUpdated;

  const AttendeeManager({
    super.key,
    required this.state,
    required this.onAttendeeAdded,
    required this.onAttendeeRemoved,
    required this.onAttendeeUpdated,
  });

  @override
  State<AttendeeManager> createState() => _AttendeeManagerState();
}

class _AttendeeManagerState extends State<AttendeeManager>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendeeSection(),
          const Gap(24),
          _buildQuickAddSection(),
          if (_showAddForm) ...[
            const Gap(16),
            _buildAddAttendeeForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendeeSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cyanColor, AppColors.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.person_2_fill,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendees',
                      style: app_text_style.getTitleStyle(
                        color: AppColors.lightText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${widget.state.selectedAttendees.length + 1} person(s) attending',
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          _buildCurrentUserCard(),
          if (widget.state.selectedAttendees.isNotEmpty) ...[
            const Gap(16),
            ...widget.state.selectedAttendees.map(_buildAttendeeCard),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.2),
            AppColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar('You', AppColors.primaryColor, isCurrentUser: true),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'You (Organizer)',
                      style: app_text_style.getbodyStyle(
                        color: AppColors.lightText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'HOST',
                        style: app_text_style.getSmallStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  'Booking organizer',
                  style: app_text_style.getSmallStyle(
                    color: AppColors.lightText.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.greenColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.check_mark,
              color: AppColors.greenColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeCard(AttendeeModel attendee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(attendee.name, _getAttendeeColor(attendee.type)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.name,
                  style: app_text_style.getbodyStyle(
                    color: AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getAttendeeColor(attendee.type)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getAttendeeTypeLabel(attendee.type),
                        style: app_text_style.getSmallStyle(
                          color: _getAttendeeColor(attendee.type),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      _getPaymentStatusText(attendee.paymentStatus),
                      style: app_text_style.getSmallStyle(
                        color: _getPaymentStatusColor(attendee.paymentStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onAttendeeRemoved(attendee.userId);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.trash,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, Color color, {bool isCurrentUser = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: app_text_style.getbodyStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: app_text_style.getTitleStyle(
            color: AppColors.lightText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildQuickAddButton(
              'Add Friend',
              CupertinoIcons.person_add,
              AppColors.cyanColor,
              () => _showFriendsModal(),
            ),
            _buildQuickAddButton(
              'Family Member',
              CupertinoIcons.person_2,
              AppColors.greenColor,
              () => _showFamilyModal(),
            ),
            _buildQuickAddButton(
              'External Guest',
              CupertinoIcons.person_crop_circle_badge_plus,
              AppColors.tealColor,
              () => _toggleAddForm(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAddButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const Gap(8),
              Text(
                label,
                style: app_text_style.getSmallStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAttendeeForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add External Guest',
                style: app_text_style.getTitleStyle(
                  color: AppColors.lightText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleAddForm,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.lightText.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          _buildFormField(
            'Full Name',
            _nameController,
            CupertinoIcons.person,
            'Enter full name',
          ),
          const Gap(12),
          _buildFormField(
            'Email (Optional)',
            _emailController,
            CupertinoIcons.mail,
            'Enter email address',
          ),
          const Gap(20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addExternalGuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.add, size: 18),
                  const Gap(8),
                  Text(
                    'Add Guest',
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
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: app_text_style.getSmallStyle(
            color: AppColors.lightText.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: app_text_style.getbodyStyle(
                color: AppColors.lightText.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.lightText.withValues(alpha: 0.6),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleAddForm() {
    setState(() => _showAddForm = !_showAddForm);
    HapticFeedback.lightImpact();
  }

  void _addExternalGuest() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final guest = AttendeeModel(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: 'guest',
      status: 'invited',
      paymentStatus: PaymentStatus.pending,
      amountToPay: 0.0,
      isHost: false,
    );

    widget.onAttendeeAdded(guest);
    _nameController.clear();
    _emailController.clear();
    _toggleAddForm();
    HapticFeedback.lightImpact();
  }

  void _showFriendsModal() {
    // Placeholder for friends selection modal
    HapticFeedback.lightImpact();
    // TODO: Implement friends selection modal
  }

  void _showFamilyModal() {
    // Placeholder for family selection modal
    HapticFeedback.lightImpact();
    // TODO: Implement family selection modal
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  Color _getAttendeeColor(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return AppColors.cyanColor;
      case 'family':
        return AppColors.greenColor;
      case 'guest':
        return AppColors.tealColor;
      default:
        return AppColors.primaryColor;
    }
  }

  String _getAttendeeTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return 'FRIEND';
      case 'family':
        return 'FAMILY';
      case 'guest':
        return 'GUEST';
      default:
        return 'ATTENDEE';
    }
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.complete:
        return AppColors.greenColor;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partial:
        return Colors.yellow;
      case PaymentStatus.hosted:
        return AppColors.primaryColor;
      case PaymentStatus.waived:
        return AppColors.lightText.withValues(alpha: 0.6);
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.complete:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.hosted:
        return 'Hosted';
      case PaymentStatus.waived:
        return 'Waived';
    }
  }
}
