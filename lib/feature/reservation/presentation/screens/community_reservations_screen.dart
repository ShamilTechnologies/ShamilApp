// lib/feature/reservation/screens/community_reservations_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as AppTextStyle;
import 'package:shamil_mobile_app/core/functions/snackbar_helper.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/reservation/data/repositories/reservation_repository.dart';
import 'package:shamil_mobile_app/feature/reservation/widgets/community_reservation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen that displays community-visible reservations that users can join
class CommunityReservationsScreen extends StatefulWidget {
  const CommunityReservationsScreen({super.key});

  @override
  State<CommunityReservationsScreen> createState() =>
      _CommunityReservationsScreenState();
}

class _CommunityReservationsScreenState
    extends State<CommunityReservationsScreen> {
  // Selected category filter
  String? _selectedCategory;

  // Available categories with icons
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Sports', 'icon': Icons.sports_soccer},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Wellness', 'icon': Icons.spa},
    {'name': 'Social', 'icon': Icons.people}
  ];

  // Loading state
  bool _isLoading = false;

  // Error state
  String? _errorMessage;

  // List of community reservations
  List<ReservationModel> _communityReservations = [];

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Sort options
  String _sortBy = 'date'; // 'date', 'price', 'capacity'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchCommunityReservations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Community Events',
          style: AppTextStyle.getTitleStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _fetchCommunityReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  // Filter reservations based on search
                  _filterReservations();
                });
              },
            ),
          ),

          // Category filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Category',
                  style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == null &&
                              category['name'] == 'All' ||
                          _selectedCategory == category['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.primaryText,
                              ),
                              const SizedBox(width: 4),
                              Text(category['name'] as String),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected
                                  ? (category['name'] == 'All'
                                      ? null
                                      : category['name'] as String)
                                  : null;
                            });
                            _filterReservations();
                          },
                          backgroundColor: Colors.white,
                          selectedColor:
                              AppColors.primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.primaryText,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Sort by:',
                  style: AppTextStyle.getbodyStyle(fontWeight: FontWeight.w600),
                ),
                const Gap(8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                    DropdownMenuItem(
                        value: 'capacity', child: Text('Capacity')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                        _sortReservations();
                      });
                    }
                  },
                ),
                const Gap(8),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortReservations();
                    });
                  },
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  void _filterReservations() {
    // Implement search and category filtering
    final searchTerm = _searchController.text.toLowerCase();
    final filtered = _communityReservations.where((res) {
      final matchesSearch = (res.serviceName?.toLowerCase() ?? '')
              .contains(searchTerm) ||
          (res.hostingDescription?.toLowerCase() ?? '').contains(searchTerm);
      final matchesCategory =
          _selectedCategory == null || res.hostingCategory == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {
      _communityReservations = filtered;
      _sortReservations();
    });
  }

  void _sortReservations() {
    switch (_sortBy) {
      case 'date':
        _communityReservations.sort((a, b) {
          final aTime = a.reservationStartTime ?? Timestamp.now();
          final bTime = b.reservationStartTime ?? Timestamp.now();
          return _sortAscending
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
        break;
      case 'price':
        _communityReservations.sort((a, b) {
          final aPrice = a.totalPrice ?? 0.0;
          final bPrice = b.totalPrice ?? 0.0;
          return _sortAscending
              ? aPrice.compareTo(bPrice)
              : bPrice.compareTo(aPrice);
        });
        break;
      case 'capacity':
        _communityReservations.sort((a, b) {
          final aCapacity = a.reservedCapacity ?? 0;
          final bCapacity = b.reservedCapacity ?? 0;
          return _sortAscending
              ? aCapacity.compareTo(bCapacity)
              : bCapacity.compareTo(aCapacity);
        });
        break;
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: AppTextStyle.getbodyStyle(color: AppColors.redColor),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: _fetchCommunityReservations,
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

    if (_communityReservations.isEmpty) {
      return _buildEmptyState();
    }

    // Filter reservations based on selected category
    final filteredReservations = _selectedCategory == null
        ? _communityReservations
        : _communityReservations
            .where((res) => res.hostingCategory == _selectedCategory)
            .toList();

    if (filteredReservations.isEmpty) {
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
                _getCategoryIcon(_selectedCategory!),
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            const Gap(16),
            Text(
              'No $_selectedCategory Events',
              style: AppTextStyle.getTitleStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              'There are no $_selectedCategory events available right now',
              style: AppTextStyle.getbodyStyle(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Show All Events'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCommunityReservations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredReservations.length,
        itemBuilder: (context, index) {
          final reservation = filteredReservations[index];
          return CommunityReservationCard(
            reservation: reservation,
            onViewDetails: () => _viewReservationDetails(reservation),
            onRequestJoin: () => _requestToJoin(reservation),
          );
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
            child: const Icon(
              CupertinoIcons.group,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const Gap(16),
          Text(
            'No Community Events',
            style: AppTextStyle.getTitleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'There are no community events available yet',
            style: AppTextStyle.getbodyStyle(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: _fetchCommunityReservations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCommunityReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get repository from the context
      final repository = context.read<ReservationRepository>();

      // Calculate date range (now to 30 days in the future)
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      // Fetch community reservations
      final reservations = await repository.getCommunityHostedReservations(
        category: _selectedCategory ?? '',
        startDate: now,
        endDate: endDate,
      );

      setState(() {
        _communityReservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _viewReservationDetails(ReservationModel reservation) {
    // Navigate to detailed view
    // This would open a detailed view of the reservation
    showGlobalSnackBar(context, 'Event details functionality coming soon');
  }

  void _requestToJoin(ReservationModel reservation) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join This Event?'),
        content: Text(
          'Would you like to request to join "${reservation.serviceName}" hosted by ${reservation.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitJoinRequest(reservation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request to Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitJoinRequest(ReservationModel reservation) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get repository from the context
      final repository = context.read<ReservationRepository>();

      // Submit join request
      final result = await repository.requestToJoinReservation(
        reservationId: reservation.id,
        userId: 'current_user_id', // In a real app, get this from auth
        userName: 'Current User', // In a real app, get this from auth
      );

      // Close loading dialog
      Navigator.pop(context);

      // Handle result
      if (result['success'] == true) {
        showGlobalSnackBar(
          context,
          'Join request sent to ${reservation.userName}',
        );

        // Refresh the list
        _fetchCommunityReservations();
      } else {
        showGlobalSnackBar(
          context,
          'Failed to send join request: ${result['error']}',
          isError: true,
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      showGlobalSnackBar(
        context,
        'Error sending join request: $e',
        isError: true,
      );
    }
  }

  /// Get icon based on category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return CupertinoIcons.flame_fill;
      case 'sports':
        return CupertinoIcons.sportscourt_fill;
      case 'entertainment':
        return CupertinoIcons.film_fill;
      case 'education':
        return CupertinoIcons.book_fill;
      case 'wellness':
        return CupertinoIcons.heart_fill;
      case 'social':
        return CupertinoIcons.person_3_fill;
      default:
        return CupertinoIcons.star_fill;
    }
  }
}
