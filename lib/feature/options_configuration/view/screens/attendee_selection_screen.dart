import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/options_configuration/models/options_configuration_models.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart'
    show PaymentStatus;
import 'package:shamil_mobile_app/core/utils/colors.dart';

/// Independent Attendee Selection Screen
///
/// Features:
/// - Search functionality
/// - Combined friends and family list
/// - External guest addition
/// - Modern design with squared profile pictures
/// - Real-time selection feedback
/// - Clean state management
class AttendeeSelectionScreen extends StatefulWidget {
  final List<AttendeeConfig> initialSelectedAttendees;
  final String? eventTitle;

  const AttendeeSelectionScreen({
    super.key,
    this.initialSelectedAttendees = const [],
    this.eventTitle,
  });

  @override
  State<AttendeeSelectionScreen> createState() =>
      _AttendeeSelectionScreenState();
}

class _AttendeeSelectionScreenState extends State<AttendeeSelectionScreen> {
  // Data
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();
  List<CombinedContact> _allContacts = [];
  List<CombinedContact> _filteredContacts = [];
  Set<String> _selectedAttendeeIds = {};

  // UI State
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _errorMessage;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeSelectedAttendees();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeSelectedAttendees() {
    _selectedAttendeeIds = widget.initialSelectedAttendees
        .map((attendee) => attendee.userId ?? attendee.id)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch friends and family concurrently
      final futures = await Future.wait([
        _dataOrchestrator.fetchCurrentUserFriends(),
        _dataOrchestrator.fetchCurrentUserFamilyMembers(),
      ]);

      final friends = futures[0] as List<dynamic>;
      final familyMembers = futures[1] as List<FamilyMember>;

      // Combine contacts
      _allContacts = _combineContacts(friends, familyMembers);
      _filteredContacts = List.from(_allContacts);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  List<CombinedContact> _combineContacts(
    List<dynamic> friends,
    List<FamilyMember> familyMembers,
  ) {
    final List<CombinedContact> combinedContacts = [];
    final Set<String> addedUserIds = {};

    // Process family members first (priority for relationship display)
    for (var familyMember in familyMembers) {
      final userId = familyMember.userId ?? familyMember.id ?? '';
      if (userId.isNotEmpty && !addedUserIds.contains(userId)) {
        combinedContacts.add(CombinedContact(
          userId: userId,
          name: familyMember.name ?? 'Unknown',
          profileImageUrl: familyMember.profilePicUrl,
          relationship: familyMember.relationship,
          isFamilyMember: true,
          isFriend: false,
          familyMember: familyMember,
        ));
        addedUserIds.add(userId);
      }
    }

    // Process friends and detect overlaps
    for (var friend in friends) {
      final userId = friend is Map<String, dynamic>
          ? (friend['userId'] as String? ?? friend['id'] as String? ?? '')
          : '';
      final name = friend is Map<String, dynamic>
          ? (friend['name'] as String? ?? 'Unknown')
          : friend.toString();
      final profileImageUrl = friend is Map<String, dynamic>
          ? (friend['profilePicUrl'] as String?)
          : null;

      if (userId.isNotEmpty) {
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        _filteredContacts = _allContacts.where((contact) {
          return contact.name.toLowerCase().contains(query) ||
              (contact.relationship?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _toggleContactSelection(CombinedContact contact) {
    setState(() {
      if (_selectedAttendeeIds.contains(contact.userId)) {
        _selectedAttendeeIds.remove(contact.userId);
      } else {
        _selectedAttendeeIds.add(contact.userId);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _showAddExternalGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExternalGuestDialog(
        onAddGuest: (name, relationship) {
          // Generate a unique ID for external guest
          final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
          final guestContact = CombinedContact(
            userId: guestId,
            name: name,
            profileImageUrl: null,
            relationship: relationship,
            isFamilyMember: false,
            isFriend: false,
            isExternal: true,
          );

          setState(() {
            _allContacts.add(guestContact);
            _filteredContacts = List.from(_allContacts);
            _selectedAttendeeIds.add(guestId);
          });
        },
      ),
    );
  }

  List<AttendeeConfig> _getSelectedAttendees() {
    final selectedAttendees = <AttendeeConfig>[];

    for (final contact in _allContacts) {
      if (_selectedAttendeeIds.contains(contact.userId)) {
        AttendeeConfig attendee;

        if (contact.isExternal == true) {
          // External guest
          attendee = AttendeeConfig(
            id: contact.userId,
            name: contact.name,
            type: AttendeeType.external,
            paymentStatus: PaymentStatus.pending,
            amountOwed: 0.0,
            userId: contact.userId,
            relationship: contact.relationship,
          );
        } else if (contact.isFamilyMember && contact.familyMember != null) {
          // Family member
          attendee = AttendeeConfig.fromFamilyMember(contact.familyMember!);
        } else if (contact.isFriend && contact.friendData != null) {
          // Friend
          attendee = AttendeeConfig.fromFriend(contact.friendData!);
        } else {
          continue; // Skip invalid contacts
        }

        selectedAttendees.add(attendee);
      }
    }

    return selectedAttendees;
  }

  void _onDone() {
    final selectedAttendees = _getSelectedAttendees();
    Navigator.pop(context, selectedAttendees);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Attendees',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (widget.eventTitle != null)
            Text(
              'for ${widget.eventTitle}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      actions: [
        if (_isSearching)
          IconButton(
            onPressed: _clearSearch,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
          ),
        IconButton(
          onPressed: _showAddExternalGuestDialog,
          icon: const Icon(Icons.person_add),
          tooltip: 'Add external guest',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(child: _buildContactsList()),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _searchFocusNode.hasFocus
                    ? AppColors.primaryColor.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Stats Row
          if (_allContacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Total Contacts',
                    _allContacts.length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Selected',
                    _selectedAttendeeIds.length.toString(),
                    AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Filtered',
                    _filteredContacts.length.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredContacts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedAttendeeIds.contains(contact.userId);
        return _buildContactCard(contact, isSelected);
      },
    );
  }

  Widget _buildContactCard(CombinedContact contact, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? AppColors.primaryColor.withOpacity(0.08)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleContactSelection(contact),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture with Selection Indicator
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primaryColor, width: 3)
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
                    if (isSelected)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isSelected ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
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

                // Contact Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        contact.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey.shade800,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Relationship Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildContactTypeChip(contact, isSelected),
                          if (contact.relationship != null)
                            _buildRelationshipChip(
                                contact.relationship!, isSelected),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Selection Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                            key: ValueKey('check_${contact.userId}'),
                          )
                        : Icon(
                            Icons.add_rounded,
                            color: Colors.grey[600],
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

  Widget _buildContactTypeChip(CombinedContact contact, bool isSelected) {
    String label;
    Color color;
    IconData icon;

    if (contact.isExternal == true) {
      label = 'Guest';
      color = Colors.orange;
      icon = Icons.person_outline;
    } else if (contact.isFamilyMember && contact.isFriend) {
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
          Icon(icon, color: color, size: 12),
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
          Icon(Icons.badge, color: Colors.grey[600], size: 12),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _isSearching ? 'No matches found' : 'No contacts available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _isSearching
                  ? 'Try adjusting your search terms'
                  : 'Add friends and family members in your profile to invite them to bookings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: _showAddExternalGuestDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add External Guest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_selectedAttendeeIds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedAttendeeIds.length} ${_selectedAttendeeIds.length == 1 ? 'person' : 'people'} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Ready to add to your booking',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _onDone,
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContactTypeColor(CombinedContact contact) {
    if (contact.isExternal == true) {
      return Colors.orange;
    } else if (contact.isFamilyMember && contact.isFriend) {
      return Colors.blue;
    } else if (contact.isFamilyMember) {
      return Colors.purple;
    } else {
      return Colors.green;
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
}

/// Combined Contact Model
class CombinedContact {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final String? relationship;
  final bool isFamilyMember;
  final bool isFriend;
  final bool? isExternal;
  final FamilyMember? familyMember;
  final dynamic friendData;

  const CombinedContact({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    this.relationship,
    required this.isFamilyMember,
    required this.isFriend,
    this.isExternal,
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
    bool? isExternal,
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
      isExternal: isExternal ?? this.isExternal,
      familyMember: familyMember ?? this.familyMember,
      friendData: friendData ?? this.friendData,
    );
  }
}

/// Add External Guest Dialog
class _AddExternalGuestDialog extends StatefulWidget {
  final Function(String name, String relationship) onAddGuest;

  const _AddExternalGuestDialog({required this.onAddGuest});

  @override
  State<_AddExternalGuestDialog> createState() =>
      _AddExternalGuestDialogState();
}

class _AddExternalGuestDialogState extends State<_AddExternalGuestDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _addGuest() {
    if (_formKey.currentState!.validate()) {
      widget.onAddGuest(
        _nameController.text.trim(),
        _relationshipController.text.trim().isNotEmpty
            ? _relationshipController.text.trim()
            : 'Guest',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add External Guest'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter guest name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (Optional)',
                hintText: 'e.g., Colleague, Neighbor',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addGuest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
