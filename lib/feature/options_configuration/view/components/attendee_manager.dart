import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

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
  late SocialBloc _socialBloc;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
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

    // Initialize social bloc with data orchestrator
    _socialBloc = SocialBloc(
      dataOrchestrator: FirebaseDataOrchestrator(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    _socialBloc.close();
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
    HapticFeedback.lightImpact();
    _socialBloc.add(const LoadFriendsAndRequests());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: _socialBloc,
        child: _buildContactSelectionModal('friend'),
      ),
    );
  }

  void _showFamilyModal() {
    HapticFeedback.lightImpact();
    _socialBloc.add(const LoadFamilyMembers());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: _socialBloc,
        child: _buildContactSelectionModal('family'),
      ),
    );
  }

  Widget _buildContactSelectionModal(String type) {
    final title = type == 'friend' ? 'Add Friends' : 'Add Family Members';
    final color = type == 'friend' ? AppColors.cyanColor : AppColors.greenColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepSpaceNavy,
            AppColors.deepSpaceNavy.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    type == 'friend'
                        ? CupertinoIcons.person_add
                        : CupertinoIcons.person_2,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Text(
                    title,
                    style: app_text_style.getTitleStyle(
                      color: AppColors.lightText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.lightText.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: AppColors.lightText.withValues(alpha: 0.6),
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: app_text_style.getbodyStyle(
                      color: AppColors.lightText,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search ${type == 'friend' ? 'friends' : 'family'}...',
                      hintStyle: app_text_style.getbodyStyle(
                        color: AppColors.lightText.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (type == 'friend') {
                        _socialBloc.add(SearchUsers(query: value));
                      }
                      // Family search could be implemented similarly
                    },
                  ),
                ),
              ],
            ),
          ),

          const Gap(20),

          // Contact list with BlocBuilder
          Expanded(
            child: BlocBuilder<SocialBloc, SocialState>(
              builder: (context, state) {
                if (state is SocialLoading && state.isLoadingList) {
                  return _buildLoadingState();
                } else if (state is SocialError) {
                  return _buildErrorState(state.message, type);
                } else if (type == 'friend') {
                  return _buildFriendsList(state, color);
                } else {
                  return _buildFamilyList(state, color);
                }
              },
            ),
          ),

          // Add manual entry button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _toggleAddForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
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
                      'Add Manually',
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const Gap(16),
          Text(
            'Loading contacts...',
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            color: Colors.orange,
            size: 48,
          ),
          const Gap(16),
          Text(
            'Error loading ${type == 'friend' ? 'friends' : 'family'}',
            style: app_text_style.getTitleStyle(
              color: AppColors.lightText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: () {
              if (type == 'friend') {
                _socialBloc.add(const LoadFriendsAndRequests());
              } else {
                _socialBloc.add(const LoadFamilyMembers());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(SocialState state, Color color) {
    if (state is FriendsAndRequestsLoaded) {
      if (state.friends.isEmpty) {
        return _buildEmptyState('No friends added yet', 'friend', color);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.friends.length,
        itemBuilder: (context, index) {
          final friend = state.friends[index];
          return _buildContactCard(
            name: friend.name,
            subtitle: 'Friend',
            avatar: _getInitials(friend.name),
            profilePicUrl: friend.profilePicUrl,
            color: color,
            onTap: () => _addFirebaseContactAsAttendee(
              friend.userId,
              friend.name,
              'friend',
            ),
          );
        },
      );
    } else if (state is FriendSearchResultsLoaded) {
      if (state.results.isEmpty && state.query.isNotEmpty) {
        return _buildEmptyState('No friends found', 'friend', color);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.results.length,
        itemBuilder: (context, index) {
          final result = state.results[index];
          return _buildContactCard(
            name: result.user.name ?? 'Unknown',
            subtitle: 'Friend',
            avatar: _getInitials(result.user.name ?? 'Unknown'),
            profilePicUrl: result.user.profilePicUrl,
            color: color,
            onTap: () => _addFirebaseContactAsAttendee(
              result.user.uid ?? '',
              result.user.name ?? 'Unknown',
              'friend',
            ),
          );
        },
      );
    }

    return _buildEmptyState('No friends found', 'friend', color);
  }

  Widget _buildFamilyList(SocialState state, Color color) {
    if (state is FamilyDataLoaded) {
      if (state.familyMembers.isEmpty) {
        return _buildEmptyState('No family members added yet', 'family', color);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.familyMembers.length,
        itemBuilder: (context, index) {
          final member = state.familyMembers[index];
          return _buildContactCard(
            name: member.name,
            subtitle: member.relationship,
            avatar: _getInitials(member.name),
            profilePicUrl: member.profilePicUrl,
            color: color,
            onTap: () => _addFirebaseContactAsAttendee(
              member.userId ?? member.id,
              member.name,
              'family',
            ),
          );
        },
      );
    }

    return _buildEmptyState('No family members found', 'family', color);
  }

  Widget _buildEmptyState(String message, String type, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'friend'
                ? CupertinoIcons.person_2
                : CupertinoIcons.person_3,
            color: color.withValues(alpha: 0.6),
            size: 64,
          ),
          const Gap(20),
          Text(
            message,
            style: app_text_style.getTitleStyle(
              color: AppColors.lightText.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'Add ${type == 'friend' ? 'friends' : 'family members'} to invite them to your bookings',
            textAlign: TextAlign.center,
            style: app_text_style.getbodyStyle(
              color: AppColors.lightText.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String name,
    required String subtitle,
    required String avatar,
    String? profilePicUrl,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: profilePicUrl != null && profilePicUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            profilePicUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  avatar,
                                  style: app_text_style.getbodyStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            avatar,
                            style: app_text_style.getbodyStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: app_text_style.getbodyStyle(
                          color: AppColors.lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        subtitle,
                        style: app_text_style.getSmallStyle(
                          color: AppColors.lightText.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.add_circled,
                  color: color,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addFirebaseContactAsAttendee(String userId, String name, String type) {
    final attendee = AttendeeModel(
      userId: userId,
      name: name,
      type: type,
      status: 'invited',
      paymentStatus: PaymentStatus.pending,
      amountToPay: 0.0,
      isHost: false,
    );

    widget.onAttendeeAdded(attendee);

    // Send OneSignal notification to the invited user
    _sendInvitationNotification(userId, name, type);

    Navigator.of(context).pop();
    HapticFeedback.lightImpact();
  }

  Future<void> _sendInvitationNotification(
      String userId, String name, String type) async {
    try {
      // Get current user info (would normally come from auth context)
      final currentUserName =
          'Ahmed Hamdy Ahmed'; // Should come from actual user session

      // Prepare notification data
      final notificationData = {
        'type': 'booking_invitation',
        'inviter_id': 'Ug0Tjah6HqN4YUBDuQzDVsEEkKk2', // Current user ID
        'inviter_name': currentUserName,
        'invited_as': type,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send notification using OneSignal's API to specific user
      await _sendNotificationToUser(userId, {
        'headings': {'en': '🎉 You\'re Invited!'},
        'contents': {
          'en':
              '$currentUserName has invited you to join their booking! Tap to view details.'
        },
        'data': notificationData,
      });

      debugPrint('✅ Invitation notification sent to $name ($userId)');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  CupertinoIcons.bell_fill,
                  color: AppColors.greenColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invitation sent to $name!',
                  style: app_text_style.getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.greenColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to send invitation notification: $e');

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '$name was added but notification failed to send',
                  style: app_text_style.getbodyStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendNotificationToUser(
      String userId, Map<String, dynamic> notificationPayload) async {
    // This would typically use OneSignal's REST API with your app's REST API key
    // For now, we'll simulate the call with a delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In production, you would:
    // 1. Call your backend Cloud Function
    // 2. Backend function would use OneSignal REST API to send notification to specific user ID
    // 3. Use external_user_id matching to target the correct user

    // Example of what the Cloud Function would do:
    /*
    import 'dart:convert';
    import 'package:http/http.dart' as http;
    
    final response = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic YOUR_REST_API_KEY',
      },
      body: jsonEncode({
        'app_id': 'YOUR_APP_ID',
        'include_external_user_ids': [userId],
        'headings': notificationPayload['headings'],
        'contents': notificationPayload['contents'],
        'data': notificationPayload['data'],
        'buttons': [
          {'id': 'view_booking', 'text': 'View Booking'},
          {'id': 'decline', 'text': 'Decline'},
        ],
        'android_sound': 'notification',
        'ios_sound': 'notification.wav',
        'android_channel_id': 'booking_invitations',
        'priority': 10,
      }),
    );
    
    if (response.statusCode == 200) {
      debugPrint('✅ OneSignal notification sent successfully');
    } else {
      debugPrint('❌ OneSignal notification failed: \${response.body}');
    }
    */

    debugPrint('🔔 [SIMULATION] OneSignal notification sent to user: $userId');
    debugPrint('📱 Notification payload: $notificationPayload');
  }

  void _addContactAsAttendee(Map<String, String> contact, String type) {
    final attendee = AttendeeModel(
      userId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: contact['name']!,
      type: type,
      status: 'invited',
      paymentStatus: PaymentStatus.pending,
      amountToPay: 0.0,
      isHost: false,
    );

    widget.onAttendeeAdded(attendee);
    Navigator.of(context).pop();
    HapticFeedback.lightImpact();
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
