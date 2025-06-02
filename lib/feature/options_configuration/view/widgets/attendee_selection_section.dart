import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';

class AttendeeSelectionSection extends StatefulWidget {
  final OptionsConfigurationState state;

  const AttendeeSelectionSection({
    super.key,
    required this.state,
  });

  @override
  State<AttendeeSelectionSection> createState() =>
      _AttendeeSelectionSectionState();
}

class _AttendeeSelectionSectionState extends State<AttendeeSelectionSection> {
  final TextEditingController _externalNameController = TextEditingController();
  final TextEditingController _externalEmailController =
      TextEditingController();
  final TextEditingController _externalPhoneController =
      TextEditingController();
  final TextEditingController _externalRelationshipController =
      TextEditingController();

  // Tab selection
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _externalNameController.dispose();
    _externalEmailController.dispose();
    _externalPhoneController.dispose();
    _externalRelationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_2_fill,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    "Who will attend?",
                    style: AppTextStyle.getTitleStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Selected attendees list
            if (widget.state.selectedAttendees.isNotEmpty) ...[
              _buildSelectedAttendeesList(),
              const Gap(16),
            ],

            // Tab selection for attendee sources
            _buildAttendeeSourceTabs(),
            const Gap(12),

            // Tab content based on selection
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAttendeesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selected attendees (${widget.state.selectedAttendees.length})",
          style: AppTextStyle.getTitleStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.state.selectedAttendees.map((attendee) {
            return Chip(
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              labelStyle: AppTextStyle.getSmallStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              avatar: _getAttendeeAvatar(attendee),
              label: Text(attendee.name),
              deleteIcon: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 18,
                color: AppColors.primaryColor,
              ),
              onDeleted: () {
                context.read<OptionsConfigurationBloc>().add(
                      RemoveOptionAttendee(attendeeUserId: attendee.userId),
                    );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _getAttendeeAvatar(AttendeeModel attendee) {
    Color avatarColor;
    IconData iconData;

    // Determine avatar appearance based on attendee type
    switch (attendee.type.toLowerCase()) {
      case 'self':
        avatarColor = AppColors.primaryColor;
        iconData = CupertinoIcons.person_fill;
        break;
      case 'friend':
        avatarColor = Colors.blue;
        iconData = CupertinoIcons.person_2_fill;
        break;
      case 'family':
        avatarColor = Colors.green;
        iconData = CupertinoIcons.house_fill;
        break;
      default: // guest
        avatarColor = Colors.orange;
        iconData = CupertinoIcons.person_badge_plus_fill;
    }

    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: 12,
      child: Icon(
        iconData,
        size: 12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAttendeeSourceTabs() {
    return CupertinoSegmentedControl<int>(
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Self'),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Friends'),
        ),
        2: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Family'),
        ),
        3: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Other'),
        ),
      },
      groupValue: _selectedTabIndex,
      onValueChanged: (value) {
        setState(() {
          _selectedTabIndex = value;
        });

        // When switching to friends or family tabs, load the data
        if (value == 1 &&
            widget.state.availableFriends.isEmpty &&
            !widget.state.loadingFriends) {
          context
              .read<OptionsConfigurationBloc>()
              .add(const LoadCurrentUserFriends());
        } else if (value == 2 &&
            widget.state.availableFamilyMembers.isEmpty &&
            !widget.state.loadingFamilyMembers) {
          context
              .read<OptionsConfigurationBloc>()
              .add(const LoadCurrentUserFamilyMembers());
        }
      },
      selectedColor: AppColors.primaryColor,
      unselectedColor: Colors.white,
      borderColor: AppColors.primaryColor,
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSelfAttendeeSection();
      case 1:
        return _buildFriendsSection();
      case 2:
        return _buildFamilySection();
      case 3:
        return _buildExternalAttendeeForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelfAttendeeSection() {
    // Get current user from auth bloc
    final authState = context.watch<AuthBloc>().state;
    if (authState is LoginSuccessState) {
      final user = authState.user;

      // Check if user is already added as an attendee
      final bool isAlreadyAdded = widget.state.selectedAttendees.any(
          (attendee) =>
              attendee.userId == user.uid &&
              attendee.type.toLowerCase() == 'self');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Leading avatar
            CircleAvatar(
              backgroundImage: user.profilePicUrl != null
                  ? NetworkImage(user.profilePicUrl!)
                  : null,
              radius: 20,
              child: user.profilePicUrl == null
                  ? const Icon(CupertinoIcons.person_fill)
                  : null,
            ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing widget
            const SizedBox(width: 12),
            isAlreadyAdded
                ? const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: Colors.green)
                : SizedBox(
                    width: 90, // Constrain width of the button
                    child: ElevatedButton(
                      onPressed: () {
                        // Add current user as an attendee
                        final attendee = AttendeeModel(
                          userId: user.uid,
                          name: user.name,
                          type: 'self',
                          status: 'confirmed',
                          isHost: true,
                        );

                        context.read<OptionsConfigurationBloc>().add(
                              AddOptionAttendee(attendee: attendee),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      child: const Text('Add Me'),
                    ),
                  ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text('Please log in to add yourself as an attendee'),
      );
    }
  }

  Widget _buildFriendsSection() {
    if (widget.state.loadingFriends) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.state.availableFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'No friends found',
                style: AppTextStyle.getTitleStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Add friends from the Social section to invite them',
                style: AppTextStyle.getSmallStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.state.availableFriends.length,
      itemBuilder: (context, index) {
        final friend = widget.state.availableFriends[index];

        // Check if friend is already added as an attendee
        final bool isAlreadyAdded = widget.state.selectedAttendees.any(
            (attendee) =>
                attendee.userId == friend.userId &&
                attendee.type.toLowerCase() == 'friend');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              // Leading avatar
              CircleAvatar(
                backgroundImage: friend.profilePicUrl != null
                    ? NetworkImage(friend.profilePicUrl!)
                    : null,
                radius: 20,
                child: friend.profilePicUrl == null
                    ? const Icon(CupertinoIcons.person_fill)
                    : null,
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  friend.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),

              // Trailing widget
              isAlreadyAdded
                  ? const Icon(CupertinoIcons.checkmark_circle_fill,
                      color: Colors.green, size: 24)
                  : IconButton(
                      icon: const Icon(
                        CupertinoIcons.plus_circle_fill,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      onPressed: () {
                        context.read<OptionsConfigurationBloc>().add(
                              AddFriendAsAttendee(friend: friend),
                            );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFamilySection() {
    if (widget.state.loadingFamilyMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.state.availableFamilyMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'No family members found',
                style: AppTextStyle.getTitleStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Add family members from the Social section to invite them',
                style: AppTextStyle.getSmallStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.state.availableFamilyMembers.length,
      itemBuilder: (context, index) {
        final familyMember = widget.state.availableFamilyMembers[index];

        // Check if family member is already added as an attendee
        final bool isAlreadyAdded = widget.state.selectedAttendees.any(
            (attendee) =>
                attendee.userId == familyMember.id &&
                attendee.type.toLowerCase() == 'family');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              // Leading avatar
              CircleAvatar(
                backgroundImage: familyMember.profilePicUrl != null
                    ? NetworkImage(familyMember.profilePicUrl!)
                    : null,
                radius: 20,
                child: familyMember.profilePicUrl == null
                    ? const Icon(CupertinoIcons.person_fill)
                    : null,
              ),
              const SizedBox(width: 12),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      familyMember.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      familyMember.relationship,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing widget
              isAlreadyAdded
                  ? const Icon(CupertinoIcons.checkmark_circle_fill,
                      color: Colors.green, size: 24)
                  : IconButton(
                      icon: const Icon(
                        CupertinoIcons.plus_circle_fill,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      onPressed: () {
                        context.read<OptionsConfigurationBloc>().add(
                              AddFamilyMemberAsAttendee(
                                  familyMember: familyMember),
                            );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExternalAttendeeForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add External Attendee',
            style: AppTextStyle.getTitleStyle(fontSize: 16),
          ),
          const Gap(12),
          TextFormField(
            controller: _externalNameController,
            decoration: InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter attendee name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const Gap(8),
          TextFormField(
            controller: _externalEmailController,
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'Enter attendee email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const Gap(8),
          TextFormField(
            controller: _externalPhoneController,
            decoration: InputDecoration(
              labelText: 'Phone (optional)',
              hintText: 'Enter attendee phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const Gap(8),
          TextFormField(
            controller: _externalRelationshipController,
            decoration: InputDecoration(
              labelText: 'Relationship (optional)',
              hintText: 'E.g., Colleague, Friend',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_externalNameController.text.isNotEmpty) {
                  context.read<OptionsConfigurationBloc>().add(
                        AddExternalAttendee(
                          name: _externalNameController.text,
                          email: _externalEmailController.text.isEmpty
                              ? null
                              : _externalEmailController.text,
                          phone: _externalPhoneController.text.isEmpty
                              ? null
                              : _externalPhoneController.text,
                          relationship:
                              _externalRelationshipController.text.isEmpty
                                  ? null
                                  : _externalRelationshipController.text,
                        ),
                      );

                  // Clear the form
                  _externalNameController.clear();
                  _externalEmailController.clear();
                  _externalPhoneController.clear();
                  _externalRelationshipController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Attendee'),
            ),
          ),
        ],
      ),
    );
  }
}
