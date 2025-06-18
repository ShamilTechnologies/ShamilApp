# 📖 Quick Reference Guide - Shamil App Firebase Structure

## 🗄️ Database Collections

### Primary Collections
```
endUsers/{userId}/
├── reservations/{reservationId}     # Full reservation data
├── subscriptions/{subscriptionId}   # Full subscription data
├── favorites/{favoriteId}           # User's favorite providers
├── friends/{friendId}               # Social connections
├── familyMembers/{memberId}         # Family member data
└── notifications/{notificationId}   # User notifications

serviceProviders/{providerId}/
├── pendingReservations/{reservationId}    # References only
├── confirmedReservations/{reservationId}  # References only
├── cancelledReservations/{reservationId}  # References only
├── activeSubscriptions/{subscriptionId}   # References only
└── cancelledSubscriptions/{subscriptionId} # References only
```

## 🎫 Reservation Data Structure

### Complete Reservation (endUsers collection)
```json
{
  "id": "res_123",
  "userId": "user_456",
  "userName": "John Doe",
  "providerId": "provider_789",
  "serviceId": "service_001",
  "serviceName": "Premium Spa Package",
  "type": "service-based",
  "durationMinutes": 90,
  "reservationStartTime": "2024-01-15T14:00:00Z",
  "endTime": "2024-01-15T15:30:00Z",
  "groupSize": 2,
  "attendees": [...],
  "status": "confirmed",
  "paymentStatus": "completed",
  "totalPrice": 500.0,
  "notes": "Special occasion",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:30:00Z"
}
```

### Reference (serviceProviders collection)
```json
{
  "reservationId": "res_123",
  "userId": "user_456",
  "userName": "John Doe",
  "serviceName": "Premium Spa Package",
  "reservationStartTime": "2024-01-15T14:00:00Z",
  "status": "confirmed",
  "totalPrice": 500.0,
  "groupSize": 2,
  "createdAt": "2024-01-01T10:00:00Z"
}
```

## 🔄 Subscription Data Structure

### Complete Subscription (endUsers collection)
```json
{
  "id": "sub_123",
  "userId": "user_456",
  "userName": "John Doe",
  "providerId": "provider_789",
  "planId": "plan_premium",
  "planName": "Premium Monthly Membership",
  "billingCycle": "monthly",
  "status": "active",
  "startDate": "2024-01-01T00:00:00Z",
  "expiryDate": "2024-02-01T00:00:00Z",
  "pricePaid": 299.99,
  "groupSize": 2,
  "subscribers": [...],
  "paymentDetails": {...},
  "createdAt": "2024-01-01T00:00:00Z"
}
```

## 🚀 Common Operations

### Get Provider Reservations
```dart
final reservations = await FirebaseDataOrchestrator()
    .fetchProviderReservations('provider_123');
```

### Create Reservation
```dart
final reservationId = await FirebaseDataOrchestrator()
    .createReservation(reservationModel);
```

### Update Status
```dart
await FirebaseDataOrchestrator().updateReservationStatus(
  reservationId: 'res_123',
  status: ReservationStatus.confirmed,
);
```

### Get User Statistics
```dart
final stats = await FirebaseDataOrchestrator().getUserStatistics();
// Returns: {'totalReservations': 15, 'totalSubscriptions': 3, 'totalFavorites': 8}
```

## 📊 Status Enums

### Reservation Status
- `pending` - Awaiting confirmation/payment
- `confirmed` - Payment confirmed, reservation active
- `completed` - Service delivered
- `cancelled` - Reservation cancelled

### Payment Status
- `pending` - Payment not yet processed
- `completed` - Payment successful
- `failed` - Payment failed
- `refunded` - Payment refunded

### Subscription Status
- `active` - Subscription is active
- `cancelled` - User cancelled subscription
- `expired` - Subscription expired
- `payment_failed` - Payment processing failed

## 🔍 Query Patterns

### Filter by Status
```dart
final confirmedReservations = reservations
    .where((r) => r.status == ReservationStatus.confirmed)
    .toList();
```

### Get This Month's Data
```dart
final thisMonth = DateTime(DateTime.now().year, DateTime.now().month);
final thisMonthReservations = reservations
    .where((r) => r.createdAt.toDate().isAfter(thisMonth))
    .toList();
```

### Calculate Revenue
```dart
final totalRevenue = reservations
    .where((r) => r.status == ReservationStatus.confirmed)
    .fold(0.0, (sum, r) => sum + (r.totalPrice ?? 0.0));
```

## ⚡ Performance Tips

### Use Caching
```dart
final Map<String, dynamic> _cache = {};
final Map<String, DateTime> _cacheTimestamps = {};

// Cache provider details for 5 minutes
if (timestamp != null && DateTime.now().difference(timestamp).inMinutes < 5) {
  return _cache[key];
}
```

### Limit Data Fetching
```dart
// Get recent reservations only
final recentReservations = reservations
    .where((r) => r.createdAt.toDate().isAfter(DateTime.now().subtract(Duration(days: 30))))
    .take(10)
    .toList();
```

### Batch Operations
```dart
// Update multiple reservations at once
for (final id in reservationIds) {
  batch.update(reservationRef(id), {'status': 'confirmed'});
}
await batch.commit();
```

## 🔐 Security Rules

### Provider Access
```javascript
// Service providers can only access their own data
match /serviceProviders/{providerId} {
  allow read, write: if request.auth != null && 
                     request.auth.uid == resource.data.ownerUid;
}
```

### User Data Protection
```javascript
// Users can only access their own data
match /endUsers/{userId} {
  allow read, write: if request.auth != null && 
                     request.auth.uid == userId;
}
```

## 🔧 Error Handling

### Firebase Exceptions
```dart
try {
  final result = await operation();
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      throw Exception('Access denied');
    case 'not-found':
      throw Exception('Data not found');
    default:
      throw Exception('Firebase error: ${e.message}');
  }
} catch (e) {
  throw Exception('General error: $e');
}
```

### Retry Pattern
```dart
Future<T> withRetry<T>(Future<T> Function() operation) async {
  for (int i = 0; i < 3; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == 2) rethrow;
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  throw Exception('Should never reach here');
}
```

## 📱 Real-time Updates

### Stream Builder Pattern
```dart
StreamBuilder<List<ReservationModel>>(
  stream: FirebaseDataOrchestrator().getUserReservationsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final reservations = snapshot.data!;
    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) => ReservationTile(reservations[index]),
    );
  },
)
```

## 📈 Analytics Calculations

### Key Metrics
```dart
// Customer retention rate
final uniqueCustomers = reservations.map((r) => r.userId).toSet().length;
final repeatCustomers = customerFrequency.values.where((count) => count > 1).length;
final retentionRate = uniqueCustomers > 0 ? repeatCustomers / uniqueCustomers * 100 : 0.0;

// Average order value
final totalRevenue = confirmedReservations.fold(0.0, (sum, r) => sum + r.totalPrice);
final averageOrderValue = confirmedReservations.isNotEmpty ? totalRevenue / confirmedReservations.length : 0.0;

// Growth rate
final thisMonthCount = thisMonthReservations.length;
final lastMonthCount = lastMonthReservations.length;
final growthRate = lastMonthCount > 0 ? (thisMonthCount - lastMonthCount) / lastMonthCount * 100 : 0.0;
```

---

For complete documentation, refer to the main [README](README.md) and [Firebase Data Orchestrator Guide](firebase-data-orchestrator-guide.md). 