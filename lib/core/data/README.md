# Firebase Data Orchestrator

## Overview

The `FirebaseDataOrchestrator` is a centralized data management system that consolidates all Firebase operations for the Shamil Mobile App. It provides a single source of truth for data operations with clean architecture, consistent error handling, and optimized performance.

## Architecture Benefits

### 🎯 **Centralized Data Management**
- Single file for all Firebase operations
- Consistent error handling across the app
- Unified logging and debugging
- Easy maintenance and updates

### 🚀 **Performance Optimizations**
- Batch operations for related writes
- Real-time streams for live data
- Optimized queries with proper indexing
- Automatic retry mechanisms

### 🔒 **Security & Reliability**
- Consistent authentication checks
- Proper data validation
- Transaction-based operations
- Offline support ready

### 🧹 **Clean Code Principles**
- Single Responsibility Principle
- Dependency Injection ready
- Testable architecture
- Type-safe operations

## Usage Guide

### 1. Basic Setup

```dart
// Get the singleton instance
final dataOrchestrator = FirebaseDataOrchestrator();

// Check authentication status
if (dataOrchestrator.isAuthenticated) {
  // User is logged in
  final userId = dataOrchestrator.currentUserId;
}
```

### 2. Reservation Operations

#### Creating a Reservation
```dart
try {
  final reservation = ReservationModel(
    providerId: 'provider_123',
    serviceName: 'Hair Cut',
    // ... other fields
  );
  
  final reservationId = await dataOrchestrator.createReservation(reservation);
  print('Reservation created: $reservationId');
} catch (e) {
  print('Error creating reservation: $e');
}
```

#### Listening to User Reservations
```dart
StreamBuilder<List<ReservationModel>>(
  stream: dataOrchestrator.getUserReservationsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final reservations = snapshot.data!;
      return ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return ReservationCard(reservation: reservations[index]);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

#### Cancelling a Reservation
```dart
try {
  await dataOrchestrator.cancelReservation('reservation_123');
  print('Reservation cancelled successfully');
} catch (e) {
  print('Error cancelling reservation: $e');
}
```

### 3. Subscription Operations

#### Creating a Subscription
```dart
try {
  final subscription = SubscriptionModel(
    providerId: 'provider_123',
    planId: 'plan_456',
    // ... other fields
  );
  
  final subscriptionId = await dataOrchestrator.createSubscription(subscription);
  print('Subscription created: $subscriptionId');
} catch (e) {
  print('Error creating subscription: $e');
}
```

#### Monitoring Subscriptions
```dart
StreamBuilder<List<SubscriptionModel>>(
  stream: dataOrchestrator.getUserSubscriptionsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final subscriptions = snapshot.data!;
      return SubscriptionsList(subscriptions: subscriptions);
    }
    return LoadingWidget();
  },
)
```

### 4. Service Provider Operations

#### Fetching Providers with Filters
```dart
try {
  final providers = await dataOrchestrator.getServiceProviders(
    city: 'Amman',
    category: 'Beauty',
    searchQuery: 'hair salon',
    limit: 20,
  );
  
  print('Found ${providers.length} providers');
} catch (e) {
  print('Error fetching providers: $e');
}
```

#### Getting Provider Details
```dart
try {
  final provider = await dataOrchestrator.getServiceProviderDetails('provider_123');
  print('Provider: ${provider.businessName}');
} catch (e) {
  print('Error fetching provider details: $e');
}
```

### 5. Favorites Management

#### Adding to Favorites
```dart
try {
  await dataOrchestrator.addToFavorites('provider_123');
  print('Added to favorites');
} catch (e) {
  print('Error adding to favorites: $e');
}
```

#### Real-time Favorites Stream
```dart
StreamBuilder<List<ServiceProviderDisplayModel>>(
  stream: dataOrchestrator.getFavoritesStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final favorites = snapshot.data!;
      return FavoritesList(favorites: favorites);
    }
    return LoadingWidget();
  },
)
```

### 6. User Profile Operations

#### Getting Current User Profile
```dart
try {
  final user = await dataOrchestrator.getCurrentUserProfile();
  if (user != null) {
    print('User: ${user.name}');
  }
} catch (e) {
  print('Error fetching user profile: $e');
}
```

#### Updating Profile
```dart
try {
  await dataOrchestrator.updateUserProfile({
    'name': 'New Name',
    'phone': '+962123456789',
  });
  print('Profile updated');
} catch (e) {
  print('Error updating profile: $e');
}
```

### 7. Social Features

#### Sending Friend Request
```dart
try {
  final result = await dataOrchestrator.sendFriendRequest(
    targetUserId: 'user_456',
    targetUserName: 'John Doe',
    targetUserProfilePicUrl: 'https://example.com/pic.jpg',
  );
  
  if (result['success']) {
    print('Friend request sent');
  } else {
    print('Error: ${result['error']}');
  }
} catch (e) {
  print('Error sending friend request: $e');
}
```

#### Monitoring Friends
```dart
StreamBuilder<List<AuthModel>>(
  stream: dataOrchestrator.getFriendsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final friends = snapshot.data!;
      return FriendsList(friends: friends);
    }
    return LoadingWidget();
  },
)
```

### 8. Notifications

#### Adding Notifications
```dart
final notification = NotificationModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  title: 'New Message',
  body: 'You have a new message from John',
  type: 'message',
  timestamp: DateTime.now(),
);

await dataOrchestrator.addNotification(notification);
```

#### Listening to Notifications
```dart
StreamBuilder<List<NotificationModel>>(
  stream: dataOrchestrator.getNotificationsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final notifications = snapshot.data!;
      return NotificationsList(notifications: notifications);
    }
    return LoadingWidget();
  },
)
```

### 9. Analytics & Statistics

#### Getting User Statistics
```dart
try {
  final stats = await dataOrchestrator.getUserStatistics();
  print('Total Reservations: ${stats['totalReservations']}');
  print('Total Subscriptions: ${stats['totalSubscriptions']}');
  print('Total Favorites: ${stats['totalFavorites']}');
} catch (e) {
  print('Error fetching statistics: $e');
}
```

## Migration Guide

### From Existing Repositories

#### 1. Replace Repository Injections

**Before:**
```dart
class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationRepository _repository;
  
  ReservationBloc({required ReservationRepository repository})
      : _repository = repository,
        super(ReservationInitial());
}
```

**After:**
```dart
class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  
  ReservationBloc({FirebaseDataOrchestrator? dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator ?? FirebaseDataOrchestrator(),
        super(ReservationInitial());
}
```

#### 2. Update Method Calls

**Before:**
```dart
final reservations = await _repository.fetchUserReservations();
```

**After:**
```dart
final reservations = await _dataOrchestrator.getUserReservationsStream().first;
// Or for real-time updates:
_dataOrchestrator.getUserReservationsStream().listen((reservations) {
  // Handle reservations update
});
```

#### 3. Error Handling

**Before:**
```dart
try {
  await _repository.createReservation(reservation);
} on FirebaseException catch (e) {
  // Handle Firebase-specific errors
} catch (e) {
  // Handle general errors
}
```

**After:**
```dart
try {
  await _dataOrchestrator.createReservation(reservation);
} catch (e) {
  // All errors are already handled and wrapped consistently
  print('Error: $e');
}
```

## Best Practices

### 1. Stream Management
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  final _dataOrchestrator = FirebaseDataOrchestrator();

  @override
  void initState() {
    super.initState();
    _subscription = _dataOrchestrator.getUserReservationsStream().listen(
      (reservations) {
        // Handle reservations
      },
      onError: (error) {
        // Handle errors
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### 2. Error Handling
```dart
Future<void> handleReservation() async {
  try {
    final reservationId = await _dataOrchestrator.createReservation(reservation);
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reservation created: $reservationId')),
    );
  } catch (e) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### 3. Loading States
```dart
class ReservationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReservationModel>>(
      stream: FirebaseDataOrchestrator().getUserReservationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error.toString());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget();
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return ReservationCard(reservation: snapshot.data![index]);
          },
        );
      },
    );
  }
}
```

## Testing

### Unit Testing
```dart
void main() {
  group('FirebaseDataOrchestrator', () {
    late FirebaseDataOrchestrator orchestrator;
    
    setUp(() {
      orchestrator = FirebaseDataOrchestrator();
    });
    
    test('should create reservation successfully', () async {
      // Mock authentication
      when(mockAuth.currentUser).thenReturn(mockUser);
      
      final reservation = ReservationModel(/* test data */);
      final result = await orchestrator.createReservation(reservation);
      
      expect(result, isNotEmpty);
    });
  });
}
```

### Integration Testing
```dart
void main() {
  group('Integration Tests', () {
    testWidgets('should display reservations list', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to reservations screen
      await tester.tap(find.byKey(Key('reservations_tab')));
      await tester.pumpAndSettle();
      
      // Verify reservations are displayed
      expect(find.byType(ReservationCard), findsWidgets);
    });
  });
}
```

## Performance Considerations

### 1. Pagination
```dart
class ProvidersListWidget extends StatefulWidget {
  @override
  _ProvidersListWidgetState createState() => _ProvidersListWidgetState();
}

class _ProvidersListWidgetState extends State<ProvidersListWidget> {
  final List<ServiceProviderDisplayModel> _providers = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;

  Future<void> _loadMoreProviders() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newProviders = await FirebaseDataOrchestrator().getServiceProviders(
        limit: 20,
        lastDocument: _lastDocument,
      );
      
      setState(() {
        _providers.addAll(newProviders);
        _lastDocument = newProviders.isNotEmpty ? newProviders.last.document : null;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

### 2. Caching
```dart
class CachedDataService {
  static final Map<String, ServiceProviderModel> _providerCache = {};
  static final FirebaseDataOrchestrator _orchestrator = FirebaseDataOrchestrator();
  
  static Future<ServiceProviderModel> getProvider(String providerId) async {
    if (_providerCache.containsKey(providerId)) {
      return _providerCache[providerId]!;
    }
    
    final provider = await _orchestrator.getServiceProviderDetails(providerId);
    _providerCache[providerId] = provider;
    return provider;
  }
}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Ensure user is logged in before calling methods
   - Check Firebase Auth configuration

2. **Permission Errors**
   - Verify Firestore security rules
   - Check user permissions

3. **Network Errors**
   - Implement retry logic
   - Handle offline scenarios

4. **Performance Issues**
   - Use pagination for large datasets
   - Implement proper indexing
   - Cache frequently accessed data

### Debug Mode
```dart
// Enable debug logging
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

## Future Enhancements

1. **Offline Support**
   - Implement local caching
   - Queue operations for when online

2. **Real-time Collaboration**
   - Multi-user reservation conflicts
   - Live updates for shared data

3. **Advanced Analytics**
   - User behavior tracking
   - Performance metrics

4. **AI Integration**
   - Smart recommendations
   - Predictive analytics

## Contributing

When adding new operations to the orchestrator:

1. Follow the existing pattern
2. Add proper error handling
3. Include documentation
4. Write tests
5. Update this README

## Support

For questions or issues:
- Check the troubleshooting section
- Review existing code patterns
- Contact the development team 