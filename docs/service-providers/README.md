# 🏢 Service Provider Developer Documentation

## Overview

This documentation provides comprehensive guidance for service providers on how to access and manage reservation and subscription data in the Shamil App Firebase system.

## 📋 Table of Contents

- [Firebase Data Structure](#firebase-data-structure)
- [User Data Access](#user-data-access)
- [Reservation System](#reservation-system)
- [Subscription System](#subscription-system)
- [Firebase Data Orchestrator Usage](#firebase-data-orchestrator-usage)
- [Code Examples](#code-examples)
- [Best Practices](#best-practices)

---

## 🗄️ Firebase Data Structure

### Collection Overview

The Shamil App uses a dual-collection approach for efficient data management:

```
Firestore Database
├── endUsers/                           # User-centric data storage
│   └── {userId}/
│       ├── reservations/               # ✅ FULL reservation data
│       ├── subscriptions/              # ✅ FULL subscription data
│       ├── favorites/                  # User's favorite providers
│       ├── friends/                    # Social connections
│       ├── familyMembers/              # Family member data
│       └── notifications/              # User notifications
│
├── serviceProviders/                   # Provider-centric reference storage
│   └── {providerId}/
│       ├── pendingReservations/        # 📋 References to pending bookings
│       ├── confirmedReservations/      # ✅ References to confirmed bookings
│       ├── cancelledReservations/      # ❌ References to cancelled bookings
│       ├── activeSubscriptions/        # 🔄 References to active subscriptions
│       ├── cancelledSubscriptions/     # ❌ References to cancelled subscriptions
│       └── [provider business data]    # Business info, services, plans
│
└── [other collections...]             # System collections
```

### Key Design Principles

1. **📊 Single Source of Truth**: Full data stored in user collections
2. **🔗 Reference-Based Provider Views**: Provider collections contain references only
3. **⚡ Real-time Sync**: Changes propagated across both collections
4. **🔒 Security**: User data protected, provider access controlled
5. **📈 Analytics-Ready**: Structure optimized for reporting and insights

---

## 👤 User Data Access

### User Profile Structure

```javascript
// Path: /endUsers/{userId}
{
  "uid": "user123",
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "profilePictureUrl": "https://...",
  "governorateId": "cairo",
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "preferences": {
    "notifications": true,
    "language": "en",
    "currency": "EGP"
  },
  // Statistics (maintained automatically)
  "totalReservations": 15,
  "totalSubscriptions": 3,
  "totalFavorites": 8
}
```

### Getting User Statistics

```dart
// Using Firebase Data Orchestrator
final dataOrchestrator = FirebaseDataOrchestrator();

// Get comprehensive user statistics
Map<String, dynamic> userStats = await dataOrchestrator.getUserStatistics();
print('Total Reservations: ${userStats['totalReservations']}');
print('Total Subscriptions: ${userStats['totalSubscriptions']}');
print('Total Favorites: ${userStats['totalFavorites']}');
```

---

## 🎫 Reservation System

### Reservation Data Structure

#### Full Reservation Data (User Collection)

```javascript
// Path: /endUsers/{userId}/reservations/{reservationId}
{
  "id": "res_123",
  "userId": "user_456",
  "userName": "John Doe",
  "providerId": "provider_789",
  "governorateId": "cairo",
  
  // Service Details
  "serviceId": "service_001",
  "serviceName": "Premium Spa Package",
  "type": "service-based",           // ReservationType enum
  "durationMinutes": 90,
  
  // Scheduling
  "reservationStartTime": "2024-01-15T14:00:00Z",
  "endTime": "2024-01-15T15:30:00Z",
  
  // Group & Attendees
  "groupSize": 2,
  "attendees": [
    {
      "userId": "user_456",
      "name": "John Doe",
      "type": "primary",
      "status": "confirmed",
      "paymentStatus": "completed",
      "amountPaid": 250.0,
      "isHost": true
    }
  ],
  
  // Status & Payment
  "status": "confirmed",             // pending, confirmed, completed, cancelled
  "paymentStatus": "completed",
  "paymentDetails": {
    "method": "creditCard",
    "gateway": "stripe",
    "transactionId": "pi_1234567890",
    "amount": 500.0,
    "currency": "EGP"
  },
  
  // Additional Info
  "notes": "Special occasion - anniversary",
  "totalPrice": 500.0,
  "selectedAddOnsList": ["massage", "refreshments"],
  
  // Venue Booking (if applicable)
  "isFullVenueReservation": false,
  "reservedCapacity": 2,
  
  // Community Features
  "isCommunityVisible": false,
  "hostingCategory": null,
  "hostingDescription": null,
  
  // Cost Splitting
  "costSplitDetails": {
    "type": "equal",
    "hostPaying": false,
    "customSplits": {}
  },
  
  // Queue Management (if applicable)
  "queueBased": false,
  "queuePosition": null,
  "estimatedEntryTime": null,
  
  // Metadata
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:30:00Z",
  "confirmedAt": "2024-01-01T10:15:00Z",
  "reservationCode": "SH-RES-001"
}
```

#### Reference Data (Provider Collection)

```javascript
// Path: /serviceProviders/{providerId}/confirmedReservations/{reservationId}
{
  "reservationId": "res_123",
  "userId": "user_456",
  "userName": "John Doe",
  "serviceName": "Premium Spa Package",
  "reservationStartTime": "2024-01-15T14:00:00Z",
  "status": "confirmed",
  "totalPrice": 500.0,
  "groupSize": 2,
  "confirmedAt": "2024-01-01T10:15:00Z",
  "createdAt": "2024-01-01T10:00:00Z"
}
```

### Accessing Reservation Data

#### Get All Reservations for a Provider

```dart
// Get provider reservations with full data
Future<List<ReservationModel>> getProviderReservations(String providerId) async {
  final dataOrchestrator = FirebaseDataOrchestrator();
  
  try {
    // This method handles both pending and confirmed reservations
    final reservations = await dataOrchestrator.fetchProviderReservations(providerId);
    
    print('📊 Found ${reservations.length} reservations for provider $providerId');
    
    // Filter by status if needed
    final confirmedReservations = reservations
        .where((r) => r.status == ReservationStatus.confirmed)
        .toList();
    
    final pendingReservations = reservations
        .where((r) => r.status == ReservationStatus.pending)
        .toList();
    
    print('✅ Confirmed: ${confirmedReservations.length}');
    print('⏳ Pending: ${pendingReservations.length}');
    
    return reservations;
  } catch (e) {
    print('❌ Error fetching reservations: $e');
    throw Exception('Failed to fetch provider reservations: $e');
  }
}
```

#### Get Real-time Reservation Updates

```dart
// Listen to reservation changes in real-time
Stream<List<ReservationModel>> getProviderReservationStream(String providerId) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('serviceProviders')
      .doc(providerId)
      .collection('confirmedReservations')
      .orderBy('reservationStartTime', descending: false)
      .snapshots()
      .asyncMap((snapshot) async {
    
    final List<ReservationModel> reservations = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;
      final reservationId = data['reservationId'] as String;
      
      try {
        // Get full reservation data from user collection
        final reservationDoc = await firestore
            .collection('endUsers')
            .doc(userId)
            .collection('reservations')
            .doc(reservationId)
            .get();
        
        if (reservationDoc.exists) {
          final reservation = ReservationModel.fromFirestore(reservationDoc);
          reservations.add(reservation);
        }
      } catch (e) {
        print('Error fetching reservation $reservationId: $e');
      }
    }
    
    return reservations;
  });
}
```

---

## 🔄 Subscription System

### Subscription Data Structure

#### Full Subscription Data (User Collection)

```javascript
// Path: /endUsers/{userId}/subscriptions/{subscriptionId}
{
  "id": "sub_123",
  "userId": "user_456", 
  "userName": "John Doe",
  "providerId": "provider_789",
  
  // Plan Details
  "planId": "plan_premium",
  "planName": "Premium Monthly Membership",
  "billingCycle": "monthly",           // monthly, yearly, weekly
  
  // Status & Lifecycle
  "status": "active",                  // active, cancelled, expired, payment_failed
  "startDate": "2024-01-01T00:00:00Z",
  "expiryDate": "2024-02-01T00:00:00Z",
  "nextBillingDate": "2024-02-01T00:00:00Z",
  
  // Group & Subscribers
  "groupSize": 2,
  "subscribers": [
    {
      "userId": "user_456",
      "name": "John Doe",
      "role": "primary",
      "status": "active"
    },
    {
      "userId": "user_789", 
      "name": "Jane Smith",
      "role": "member",
      "status": "active"
    }
  ],
  
  // Payment Information
  "pricePaid": 299.99,
  "paymentDetails": {
    "method": "creditCard",
    "gateway": "stripe",
    "subscriptionId": "sub_stripe_123",
    "customerId": "cus_stripe_456"
  },
  
  // Cancellation (if applicable)
  "cancellationReason": null,
  "cancelledAt": null,
  
  // Additional Features
  "selectedAddOns": ["priority-booking", "extra-sessions"],
  "notes": "Corporate subscription for team",
  
  // Metadata
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Accessing Subscription Data

#### Get Provider Subscriptions

```dart
// Get all subscriptions for a provider
Future<List<SubscriptionModel>> getProviderSubscriptions(String providerId) async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Get active subscriptions
    final activeSnapshot = await firestore
        .collection('serviceProviders')
        .doc(providerId)
        .collection('activeSubscriptions')
        .get();
    
    final List<SubscriptionModel> allSubscriptions = [];
    
    // Process active subscriptions
    for (final doc in activeSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;
      final subscriptionId = data['subscriptionId'] as String;
      
      try {
        final subscriptionDoc = await firestore
            .collection('endUsers')
            .doc(userId)
            .collection('subscriptions')
            .doc(subscriptionId)
            .get();
        
        if (subscriptionDoc.exists) {
          final subscription = SubscriptionModel.fromFirestore(subscriptionDoc);
          allSubscriptions.add(subscription);
        }
      } catch (e) {
        print('Error fetching subscription $subscriptionId: $e');
      }
    }
    
    print('📊 Found ${allSubscriptions.length} total subscriptions for provider $providerId');
    
    return allSubscriptions;
  } catch (e) {
    print('❌ Error fetching provider subscriptions: $e');
    throw Exception('Failed to fetch provider subscriptions: $e');
  }
}
```

---

## 🛠️ Firebase Data Orchestrator Usage

The `FirebaseDataOrchestrator` is the central data access layer for the Shamil App.

### Key Methods for Service Providers

#### Reservation Operations

```dart
// Get singleton instance
final dataOrchestrator = FirebaseDataOrchestrator();

// Create reservation
String reservationId = await dataOrchestrator.createReservation(reservationModel);

// Confirm payment and activate reservation
await dataOrchestrator.confirmReservationPayment(
  reservationId: 'res_123',
  paymentId: 'pi_stripe_123',
  gateway: PaymentGateway.stripe,
);

// Update reservation status
await dataOrchestrator.updateReservationStatus(
  reservationId: 'res_123',
  status: ReservationStatus.completed,
  paymentStatus: 'completed',
);

// Get provider reservations
List<ReservationModel> reservations = await dataOrchestrator.fetchProviderReservations('provider_123');

// Cancel reservation
await dataOrchestrator.cancelReservation('res_123');
```

#### Subscription Operations

```dart
// Create subscription
String subscriptionId = await dataOrchestrator.createSubscription(subscriptionModel);

// Cancel subscription
await dataOrchestrator.cancelSubscription('sub_123');

// Get user subscriptions stream
Stream<List<SubscriptionModel>> subscriptionsStream = dataOrchestrator.getUserSubscriptionsStream();
```

#### Analytics & Statistics

```dart
// Get user statistics
Map<String, dynamic> userStats = await dataOrchestrator.getUserStatistics();

// Get provider details
Map<String, dynamic>? providerDetails = await dataOrchestrator.getProviderDetails('provider_123');

// Get user email for notifications
String? userEmail = await dataOrchestrator.getUserEmail('user_123');
```

---

## 💻 Code Examples

### Complete Provider Dashboard

```dart
class ProviderDashboard extends StatefulWidget {
  final String providerId;
  
  const ProviderDashboard({required this.providerId});
  
  @override
  _ProviderDashboardState createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  final dataOrchestrator = FirebaseDataOrchestrator();
  
  List<ReservationModel> reservations = [];
  List<SubscriptionModel> subscriptions = [];
  Map<String, dynamic> statistics = {};
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    try {
      // Load reservations
      final providerReservations = await dataOrchestrator.fetchProviderReservations(widget.providerId);
      
      // Load subscriptions  
      final providerSubscriptions = await getProviderSubscriptions(widget.providerId);
      
      // Calculate statistics
      final stats = _calculateStatistics(providerReservations, providerSubscriptions);
      
      setState(() {
        reservations = providerReservations;
        subscriptions = providerSubscriptions;
        statistics = stats;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
  }
  
  Map<String, dynamic> _calculateStatistics(
    List<ReservationModel> reservations,
    List<SubscriptionModel> subscriptions,
  ) {
    // Reservation statistics
    final totalReservations = reservations.length;
    final confirmedReservations = reservations
        .where((r) => r.status == ReservationStatus.confirmed)
        .length;
    
    // Subscription statistics
    final totalSubscriptions = subscriptions.length;
    final activeSubscriptions = subscriptions
        .where((s) => s.status == 'active')
        .length;
    
    // Revenue calculations
    final totalRevenue = reservations
        .where((r) => r.status == ReservationStatus.confirmed)
        .fold(0.0, (sum, r) => sum + (r.totalPrice ?? 0.0));
    
    final subscriptionRevenue = subscriptions
        .where((s) => s.status == 'active')
        .fold(0.0, (sum, s) => sum + s.pricePaid);
    
    return {
      'totalReservations': totalReservations,
      'confirmedReservations': confirmedReservations,
      'totalSubscriptions': totalSubscriptions,
      'activeSubscriptions': activeSubscriptions,
      'totalRevenue': totalRevenue,
      'subscriptionRevenue': subscriptionRevenue,
      'totalRevenueCombined': totalRevenue + subscriptionRevenue,
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Dashboard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatisticsCards(),
            SizedBox(height: 24),
            _buildReservationsSection(),
            SizedBox(height: 24),
            _buildSubscriptionsSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Reservations', '${statistics['totalReservations'] ?? 0}'),
        _buildStatCard('Confirmed Reservations', '${statistics['confirmedReservations'] ?? 0}'),
        _buildStatCard('Active Subscriptions', '${statistics['activeSubscriptions'] ?? 0}'),
        _buildStatCard('Total Revenue', 'EGP ${statistics['totalRevenueCombined']?.toStringAsFixed(2) ?? '0.00'}'),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Reservations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: math.min(reservations.length, 5),
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            return ListTile(
              title: Text(reservation.serviceName ?? 'Service'),
              subtitle: Text('${reservation.userName} - ${reservation.status.statusString}'),
              trailing: Text('EGP ${reservation.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: math.min(subscriptions.length, 5),
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return ListTile(
              title: Text(subscription.planName),
              subtitle: Text('${subscription.userName} - ${subscription.status}'),
              trailing: Text('EGP ${subscription.pricePaid.toStringAsFixed(2)}'),
            );
          },
        ),
      ],
    );
  }
}
```

---

## 🔍 Best Practices

### 1. Data Access Patterns

- **✅ Always use the Firebase Data Orchestrator** for data operations
- **✅ Handle null values gracefully** in all data models
- **✅ Implement proper error handling** for network operations
- **✅ Use streams for real-time updates** where appropriate
- **✅ Cache frequently accessed data** to improve performance

### 2. Security Considerations

- **🔒 Validate user authentication** before accessing data
- **🔒 Respect data privacy** - only access necessary user information
- **🔒 Implement proper permission checks** for provider data access
- **🔒 Log all data access operations** for audit trails
- **🔒 Use secure connections** (HTTPS) for all API calls

### 3. Performance Optimization

- **⚡ Use pagination** for large data sets
- **⚡ Implement efficient queries** with proper indexes
- **⚡ Batch operations** when possible to reduce API calls
- **⚡ Cache provider statistics** to avoid repeated calculations
- **⚡ Use real-time listeners judiciously** to avoid excessive bandwidth usage

### 4. Error Handling

```dart
// Example of robust error handling
Future<List<ReservationModel>> getReservationsWithErrorHandling(String providerId) async {
  try {
    final reservations = await dataOrchestrator.fetchProviderReservations(providerId);
    return reservations;
  } on FirebaseException catch (e) {
    // Handle Firebase-specific errors
    print('Firebase error: ${e.code} - ${e.message}');
    throw Exception('Database error: ${e.message}');
  } on Exception catch (e) {
    // Handle general exceptions
    print('General error: $e');
    throw Exception('Failed to fetch reservations: $e');
  } catch (e) {
    // Handle any other errors
    print('Unexpected error: $e');
    throw Exception('An unexpected error occurred');
  }
}
```

---

## 📞 Support & Resources

### Documentation Links
- [Firebase Data Orchestrator Source](../../lib/core/data/firebase_data_orchestrator.dart)
- [Reservation Models](../../lib/feature/reservation/data/models/reservation_model.dart)
- [Subscription Models](../../lib/feature/subscription/data/subscription_model.dart)
- [Service Provider Models](../../lib/feature/home/data/service_provider_model.dart)

### Getting Help
For technical support or questions about the data structure:
1. Check the source code documentation
2. Review the example implementations
3. Contact the development team
4. Submit issues through the proper channels

---

*This documentation is maintained by the Shamil App development team. For updates or corrections, please contact the technical team.* 