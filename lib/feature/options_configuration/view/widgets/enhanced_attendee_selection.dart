import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_bloc.dart';
import 'package:shamil_mobile_app/feature/options_configuration/bloc/options_configuration_event.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Helper class to combine friends and family members
class CombinedContact {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String? relationship;
  final bool isFamilyMember;
  final bool isFriend;
  final FamilyMember? familyMember;
  final dynamic friendData;

  const CombinedContact({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.relationship,
    required this.isFamilyMember,
    required this.isFriend,
    this.familyMember,
    this.friendData,
  });

  CombinedContact copyWith({
    String? userId,
    String? name,
    String? profileImageUrl,
    String? relationship,
    bool? isFamilyMember,
    bool? isFriend,
    FamilyMember? familyMember,
    dynamic friendData,
  }) {
    return CombinedContact(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      relationship: relationship ?? this.relationship,
      isFamilyMember: isFamilyMember ?? this.isFamilyMember,
      isFriend: isFriend ?? this.isFriend,
      familyMember: familyMember ?? this.familyMember,
      friendData: friendData ?? this.friendData,
    );
  }
}

/// Enhanced Attendee Selection Widget
///
/// Features:
/// - Combines friends and family members into one unified list
/// - Handles people who are both friends and family members
/// - Shows relationship information and connection type
/// - Modern, clean UI with proper feedback
/// - Prevents duplicate additions
/// - Supports external guest additions
class EnhancedAttendeeSelection extends StatefulWidget {
  final dynamic state; // OptionsConfigurationState

  const EnhancedAttendeeSelection({
    super.key,
    required this.state,
  });

  @override
  State<EnhancedAttendeeSelection> createState() =>
      _EnhancedAttendeeSelectionState();
}

class _EnhancedAttendeeSelectionState extends State<EnhancedAttendeeSelection> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            _buildCombinedContactsList(),
            const SizedBox(height: 20),
            _buildAddExternalGuestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.people,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Friends & Family',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Add people you want to join this booking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedContactsList() {
    final combinedContacts = _buildCombinedContactsData();

    if (combinedContacts.isEmpty) {
      return _buildEmptyContactsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Contacts (${combinedContacts.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        if (_isLoading())
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...combinedContacts.map((contact) => _buildContactCard(contact)),
      ],
    );
  }

  List<CombinedContact> _buildCombinedContactsData() {
    final List<CombinedContact> combinedContacts = [];
    final Set<String> addedUserIds = {};

    // Get family members from state
    final familyMembers = _getFamilyMembers();
    final friends = _getFriends();

    // Process family members first (they have priority for relationship display)
    for (var familyMember in familyMembers) {
      final userId = familyMember.userId ?? familyMember.id ?? '';
      if (userId.isNotEmpty && !addedUserIds.contains(userId)) {
        combinedContacts.add(CombinedContact(
          userId: userId,
          name: familyMember.name ?? 'Unknown',
          profileImageUrl: familyMember.profilePicUrl,
          relationship: familyMember.relationship,
          isFamilyMember: true,
          isFriend: false, // Will be updated if also a friend
          familyMember: familyMember,
        ));
        addedUserIds.add(userId);
      }
    }

    // Process friends and mark those who are also family members
    for (var friend in friends) {
      final userId = friend is Map<String, dynamic>
          ? (friend['userId'] as String? ?? '')
          : '';
      final name = friend is Map<String, dynamic>
          ? (friend['name'] as String? ?? 'Unknown')
          : friend.toString();
      final profileImageUrl = friend is Map<String, dynamic>
          ? (friend['profilePicUrl'] as String?)
          : null;

      if (userId.isNotEmpty) {
        // Check if this friend is already in the list as a family member
        final existingContactIndex = combinedContacts.indexWhere(
          (contact) => contact.userId == userId,
        );

        if (existingContactIndex >= 0) {
          // Mark existing family member as also being a friend
          combinedContacts[existingContactIndex] =
              combinedContacts[existingContactIndex].copyWith(
            isFriend: true,
            friendData: friend,
          );
        } else {
          // Add as new friend-only contact
          combinedContacts.add(CombinedContact(
            userId: userId,
            name: name,
            profileImageUrl: profileImageUrl,
            relationship: null,
            isFamilyMember: false,
            isFriend: true,
            friendData: friend,
          ));
          addedUserIds.add(userId);
        }
      }
    }

    // Sort by name for better UX
    combinedContacts.sort((a, b) => a.name.compareTo(b.name));

    return combinedContacts;
  }

  Widget _buildContactCard(CombinedContact contact) {
    final isAlreadyAdded = _isContactAlreadyAdded(contact.userId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyAdded
              ? Colors.green.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
          width: isAlreadyAdded ? 2 : 1,
        ),
        color: isAlreadyAdded ? Colors.green.withOpacity(0.08) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isAlreadyAdded
                ? Colors.green.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: isAlreadyAdded ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAlreadyAdded ? null : () => _addContactAsAttendee(contact),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Enhanced Profile Picture with selection indicator
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isAlreadyAdded
                            ? Border.all(color: Colors.green, width: 3)
                            : Border.all(
                                color: Colors.grey.withOpacity(0.2), width: 1),
                        color: _getContactTypeColor(contact).withOpacity(0.15),
                        image: contact.profileImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(contact.profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: contact.profileImageUrl == null
                          ? Center(
                              child: Text(
                                _getInitials(contact.name),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _getContactTypeColor(contact),
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (isAlreadyAdded)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isAlreadyAdded ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Enhanced Contact Info with better text handling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with overflow handling
                      Text(
                        contact.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isAlreadyAdded
                              ? Colors.green.shade700
                              : Colors.grey.shade800,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Enhanced relationship chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildEnhancedContactTypeChip(
                              contact, isAlreadyAdded),
                          if (contact.relationship != null)
                            _buildRelationshipChip(
                                contact.relationship!, isAlreadyAdded),
                        ],
                      ),

                      // Additional info if needed
                      if (contact.relationship != null &&
                          contact.relationship!.length > 15)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            contact.relationship!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Enhanced Action Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAlreadyAdded
                        ? Colors.green.withOpacity(0.15)
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAlreadyAdded
                          ? Colors.green.withOpacity(0.3)
                          : AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isAlreadyAdded
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                            size: 20,
                            key: ValueKey('check_${contact.userId}'),
                          )
                        : Icon(
                            Icons.add_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                            key: ValueKey('add_${contact.userId}'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedContactTypeChip(
      CombinedContact contact, bool isSelected) {
    String label;
    Color color;
    IconData icon;

    if (contact.isFamilyMember && contact.isFriend) {
      label = 'Friend & Family';
      color = Colors.blue;
      icon = Icons.people;
    } else if (contact.isFamilyMember) {
      label = 'Family';
      color = Colors.purple;
      icon = Icons.family_restroom;
    } else {
      label = 'Friend';
      color = Colors.green;
      icon = Icons.person;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.5) : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipChip(String relationship, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.grey.withOpacity(0.15)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.grey.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge,
            color: Colors.grey[600],
            size: 12,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              relationship,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContactsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No contacts found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends and family members in your profile to invite them to bookings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/profile/family-members');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contacts'),
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
    );
  }

  Widget _buildAddExternalGuestButton() {
    return InkWell(
      onTap: () => _showAddExternalGuestDialog(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
          color: AppColors.primaryColor.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add External Guest',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add someone who is not in your contacts',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to access state data
  List<FamilyMember> _getFamilyMembers() {
    try {
      return widget.state.availableFamilyMembers ?? <FamilyMember>[];
    } catch (e) {
      return <FamilyMember>[];
    }
  }

  List<dynamic> _getFriends() {
    try {
      return widget.state.availableFriends ?? <dynamic>[];
    } catch (e) {
      return <dynamic>[];
    }
  }

  bool _isLoading() {
    try {
      return widget.state.loadingFriends == true ||
          widget.state.loadingFamilyMembers == true;
    } catch (e) {
      return false;
    }
  }

  bool _isContactAlreadyAdded(String userId) {
    try {
      return widget.state.selectedAttendees
              ?.any((attendee) => attendee.userId == userId) ??
          false;
    } catch (e) {
      return false;
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  void _addContactAsAttendee(CombinedContact contact) {
    // Prevent duplicate additions
    if (_isContactAlreadyAdded(contact.userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.name} is already added to this booking'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Add based on whether they're family or friend (prioritize family if both)
    if (contact.isFamilyMember && contact.familyMember != null) {
      context.read<OptionsConfigurationBloc>().add(
            AddFamilyMemberAsAttendee(familyMember: contact.familyMember!),
          );
    } else if (contact.isFriend && contact.friendData != null) {
      context.read<OptionsConfigurationBloc>().add(
            AddFriendAsAttendee(friend: contact.friendData!),
          );
    }

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.name} added to booking'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            context.read<OptionsConfigurationBloc>().add(
                  RemoveOptionAttendee(attendeeUserId: contact.userId),
                );
          },
        ),
      ),
    );
  }

  void _showAddExternalGuestDialog() {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add External Guest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter guest name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (Optional)',
                  hintText: 'e.g., Colleague, Neighbor',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<OptionsConfigurationBloc>().add(
                        AddExternalAttendee(
                          name: nameController.text.trim(),
                          relationship:
                              relationshipController.text.trim().isNotEmpty
                                  ? relationshipController.text.trim()
                                  : 'Guest',
                        ),
                      );
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${nameController.text.trim()} added to booking'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Color _getContactTypeColor(CombinedContact contact) {
    if (contact.isFamilyMember && contact.isFriend) {
      return Colors.blue;
    } else if (contact.isFamilyMember) {
      return Colors.purple;
    } else {
      return Colors.green;
    }
  }
}
