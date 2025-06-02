// lib/core/data/example_integration.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart';

// ============================================================================
// EXAMPLE 1: UPDATED RESERVATION BLOC
// ============================================================================

/// Updated ReservationBloc using FirebaseDataOrchestrator
class ModernReservationBloc extends Cubit<ReservationState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  StreamSubscription? _reservationsSubscription;

  ModernReservationBloc({FirebaseDataOrchestrator? dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator ?? FirebaseDataOrchestrator(),
        super(ReservationInitial());

  /// Load user reservations with real-time updates
  void loadReservations() {
    emit(ReservationLoading());

    _reservationsSubscription?.cancel();
    _reservationsSubscription =
        _dataOrchestrator.getUserReservationsStream().listen(
              (reservations) => emit(ReservationLoaded(reservations)),
              onError: (error) => emit(ReservationError(error.toString())),
            );
  }

  /// Create a new reservation
  Future<void> createReservation(ReservationModel reservation) async {
    try {
      emit(ReservationCreating());
      final reservationId =
          await _dataOrchestrator.createReservation(reservation);
      emit(ReservationCreated(reservationId));
      // Reservations will be automatically updated via stream
    } catch (e) {
      emit(ReservationError('Failed to create reservation: $e'));
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(String reservationId) async {
    try {
      emit(ReservationCancelling());
      await _dataOrchestrator.cancelReservation(reservationId);
      emit(ReservationCancelled());
      // Reservations will be automatically updated via stream
    } catch (e) {
      emit(ReservationError('Failed to cancel reservation: $e'));
    }
  }

  @override
  Future<void> close() {
    _reservationsSubscription?.cancel();
    return super.close();
  }
}

// States for the modern bloc
abstract class ReservationState {}

class ReservationInitial extends ReservationState {}

class ReservationLoading extends ReservationState {}

class ReservationLoaded extends ReservationState {
  final List<ReservationModel> reservations;
  ReservationLoaded(this.reservations);
}

class ReservationCreating extends ReservationState {}

class ReservationCreated extends ReservationState {
  final String reservationId;
  ReservationCreated(this.reservationId);
}

class ReservationCancelling extends ReservationState {}

class ReservationCancelled extends ReservationState {}

class ReservationError extends ReservationState {
  final String message;
  ReservationError(this.message);
}

// ============================================================================
// EXAMPLE 2: MODERN SUBSCRIPTION MANAGEMENT
// ============================================================================

class SubscriptionManager {
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();

  /// Get user subscriptions stream
  Stream<List<SubscriptionModel>> get subscriptionsStream =>
      _dataOrchestrator.getUserSubscriptionsStream();

  /// Create subscription with validation
  Future<String> createSubscription({
    required String providerId,
    required String planId,
    required String planName,
    required double price,
    required DateTime startDate,
    required DateTime expiryDate,
  }) async {
    // Validate input
    if (!_dataOrchestrator.isAuthenticated) {
      throw Exception('User must be logged in to create subscription');
    }

    final subscription = SubscriptionModel(
      id: '', // Will be generated
      userId: _dataOrchestrator.currentUserId!,
      userName: _dataOrchestrator.currentUser?.displayName ?? 'User',
      providerId: providerId,
      planId: planId,
      planName: planName,
      status: SubscriptionStatus.active.statusString,
      startDate: Timestamp.fromDate(startDate),
      expiryDate: Timestamp.fromDate(expiryDate),
      pricePaid: price,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    return await _dataOrchestrator.createSubscription(subscription);
  }

  /// Cancel subscription with confirmation
  Future<void> cancelSubscription(String subscriptionId) async {
    await _dataOrchestrator.cancelSubscription(subscriptionId);
  }

  /// Get subscription statistics
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    final stats = await _dataOrchestrator.getUserStatistics();
    return {
      'totalSubscriptions': stats['totalSubscriptions'] ?? 0,
      'activeSubscriptions': await _getActiveSubscriptionsCount(),
    };
  }

  Future<int> _getActiveSubscriptionsCount() async {
    final subscriptions = await subscriptionsStream.first;
    return subscriptions
        .where((sub) => sub.status == SubscriptionStatus.active.statusString)
        .length;
  }
}

// ============================================================================
// EXAMPLE 3: MODERN UI WIDGETS
// ============================================================================

/// Modern Reservations List Widget
class ModernReservationsListWidget extends StatelessWidget {
  const ModernReservationsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReservationModel>>(
      stream: FirebaseDataOrchestrator().getUserReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateWidget();
        }

        return _buildReservationsList(snapshot.data!);
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Retry logic could be implemented here
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No reservations found'),
          SizedBox(height: 8),
          Text('Your reservations will appear here'),
        ],
      ),
    );
  }

  Widget _buildReservationsList(List<ReservationModel> reservations) {
    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        return ModernReservationCard(reservation: reservations[index]);
      },
    );
  }
}

/// Modern Reservation Card Widget
class ModernReservationCard extends StatelessWidget {
  final ReservationModel reservation;

  const ModernReservationCard({
    super.key,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reservation.serviceName ?? 'Service',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildStatusChip(reservation.status.toString() ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Provider: ${reservation.providerId}'),
            if (reservation.reservationStartTime != null)
              Text('Date: ${_formatDate(reservation.reservationStartTime!)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (reservation.status == 'pending') ...[
                  TextButton(
                    onPressed: () => _cancelReservation(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: () => _viewDetails(context),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status ?? 'Unknown'),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _cancelReservation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content:
            const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseDataOrchestrator().cancelReservation(reservation.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation cancelled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling reservation: $e')),
          );
        }
      }
    }
  }

  void _viewDetails(BuildContext context) {
    // Navigate to reservation details screen
    Navigator.of(context)
        .pushNamed('/reservation-details', arguments: reservation);
  }
}

// ============================================================================
// EXAMPLE 4: FAVORITES MANAGEMENT
// ============================================================================

class FavoritesManager extends ChangeNotifier {
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();
  StreamSubscription? _favoritesSubscription;
  List<ServiceProviderDisplayModel> _favorites = [];
  bool _isLoading = false;

  List<ServiceProviderDisplayModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  void initialize() {
    _isLoading = true;
    notifyListeners();

    _favoritesSubscription?.cancel();
    _favoritesSubscription = _dataOrchestrator.getFavoritesStream().listen(
      (favorites) {
        _favorites = favorites;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> toggleFavorite(String providerId) async {
    try {
      final isFavorite =
          _favorites.any((provider) => provider.id == providerId);

      if (isFavorite) {
        await _dataOrchestrator.removeFromFavorites(providerId);
      } else {
        await _dataOrchestrator.addToFavorites(providerId);
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  bool isFavorite(String providerId) {
    return _favorites.any((provider) => provider.id == providerId);
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 5: PROVIDER SEARCH WITH PAGINATION
// ============================================================================

class ProviderSearchManager {
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();
  final List<ServiceProviderDisplayModel> _providers = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  List<ServiceProviderDisplayModel> get providers => _providers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> searchProviders({
    String? city,
    String? category,
    String? searchQuery,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _providers.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    _isLoading = true;

    try {
      final newProviders = await _dataOrchestrator.getServiceProviders(
        city: city,
        category: category,
        searchQuery: searchQuery,
        limit: 20,
        lastDocument: _lastDocument,
      );

      _providers.addAll(newProviders);

      if (newProviders.length < 20) {
        _hasMore = false;
      } else {
        // Note: You might need to modify this based on your actual implementation
        // For now, we'll set _lastDocument to null to indicate no more pagination
        _lastDocument = null;
      }
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  void clear() {
    _providers.clear();
    _lastDocument = null;
    _hasMore = true;
  }
}

// ============================================================================
// EXAMPLE 6: COMPLETE INTEGRATION EXAMPLE
// ============================================================================

/// Example of a complete screen using the orchestrator
class ModernReservationsScreen extends StatefulWidget {
  const ModernReservationsScreen({super.key});

  @override
  State<ModernReservationsScreen> createState() =>
      _ModernReservationsScreenState();
}

class _ModernReservationsScreenState extends State<ModernReservationsScreen> {
  final FirebaseDataOrchestrator _dataOrchestrator = FirebaseDataOrchestrator();
  late StreamSubscription _reservationsSubscription;
  late StreamSubscription _statisticsSubscription;

  List<ReservationModel> _reservations = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Listen to reservations
    _reservationsSubscription =
        _dataOrchestrator.getUserReservationsStream().listen(
      (reservations) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (error) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );

    // Load statistics
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _dataOrchestrator.getUserStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      // Handle statistics error silently
      debugPrint('Error loading statistics: $e');
    }
  }

  @override
  void dispose() {
    _reservationsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics section
          if (_statistics.isNotEmpty) _buildStatisticsSection(),

          // Reservations list
          Expanded(
            child: _buildReservationsSection(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create reservation screen
          Navigator.of(context).pushNamed('/create-reservation');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total',
            _statistics['totalReservations']?.toString() ?? '0',
            Icons.event,
          ),
          _buildStatCard(
            'Subscriptions',
            _statistics['totalSubscriptions']?.toString() ?? '0',
            Icons.subscriptions,
          ),
          _buildStatCard(
            'Favorites',
            _statistics['totalFavorites']?.toString() ?? '0',
            Icons.favorite,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No reservations found'),
            SizedBox(height: 8),
            Text('Your reservations will appear here'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        return ModernReservationCard(reservation: _reservations[index]);
      },
    );
  }
}
