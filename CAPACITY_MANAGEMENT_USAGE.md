# 🏟️ Capacity Management System - Usage Guide

## 📋 Overview

The new capacity management system provides real-time tracking of service provider capacity, attendee counts per time slot, and remaining availability. This enables multiple users to book the same time slot as long as capacity isn't exceeded.

## 🎯 Key Features

✅ **Real-time Capacity Tracking** - Track how many people are booked for each time slot
✅ **Multi-user Same Time Slot** - Allow multiple reservations for the same time as long as capacity permits  
✅ **Capacity Validation** - Automatic validation before creating reservations
✅ **Visual Capacity Indicators** - Color-coded status for UI display
✅ **Detailed Capacity Information** - See who's booked and how much space remains
✅ **Enhanced Configuration UI** - Intuitive interface with capacity visualization

## 🎨 Enhanced Configuration UI Features

### 🎯 Capacity-Aware Time Slot Selection

The updated options configuration screen now provides a rich, capacity-aware time slot selection experience:

#### Visual Features:
- **🎨 Color-coded time slots** - Green (available), Orange (limited), Red (full)
- **📊 Progress bars** - Visual capacity utilization indicators  
- **🔢 Capacity counters** - "5/20" format showing available/total spots
- **⚠️ Validation warnings** - "Not enough spots" alerts
- **📱 Responsive design** - Works perfectly on mobile devices

#### Smart Validation:
- **Real-time capacity checking** - Validates before selection
- **Attendee count awareness** - Considers user + selected attendees
- **Graceful error handling** - Helpful dialogs when capacity exceeded
- **Automatic refresh** - Updates when attendees change

### 🎨 Implementation Examples

#### Time Slot with Capacity Display
```dart
// Enhanced time slot widget with capacity information
Widget _buildCapacityTimeSlot(TimeSlotCapacity slot) {
  return Container(
    child: Column(
      children: [
        Text(slot.timeSlot), // "14:30"
        _buildCapacityProgressBar(slot), // Visual progress bar
        Text('${slot.availableCapacity}/${slot.totalCapacity}'), // "5/20"
        if (slot.availableCapacity < attendeeCount)
          Text('Not enough spots'), // Warning
      ],
    ),
  );
}
```

#### Capacity Validation Dialog
```dart
// Smart validation with detailed capacity breakdown
void _showCapacityErrorDialog(CapacityValidationResult validation) {
  showDialog(
    builder: (_) => AlertDialog(
      title: Text('Time Slot Full'),
      content: Column(
        children: [
          Text(validation.errorMessage),
          CapacityInfoWidget(
            totalCapacity: validation.totalCapacity,
            availableCapacity: validation.availableCapacity,
            neededSpots: attendeeCount,
          ),
        ],
      ),
    ),
  );
}
```

#### Progress Bar Visualization
```dart
// Mini progress bar showing capacity utilization
Widget _buildCapacityProgressBar(TimeSlotCapacity slot, bool isSelected) {
  return Container(
    width: 40,
    height: 3,
    child: LinearProgressIndicator(
      value: slot.utilizationRate, // 0.0 to 1.0
      backgroundColor: Colors.grey.withOpacity(0.3),
      valueColor: AlwaysStoppedAnimation(slot.status.color),
    ),
  );
}
```

### 📊 Capacity Legend & Indicators

The UI includes a helpful legend system:

```dart
Widget _buildCapacityLegend() {
  return Row(
    children: [
      _buildLegendItem(Colors.green, 'Available'),
      _buildLegendItem(Colors.orange, 'Limited'), 
      _buildLegendItem(Colors.red, 'Full'),
    ],
  );
}
```

### 🔄 Real-time Updates

Time slots automatically refresh when:
- Date selection changes
- Attendees are added/removed
- Provider capacity updates
- Other users make bookings

```dart
// Automatic capacity fetching
Widget _buildTimeSlotsWithCapacity() {
  return FutureBuilder<List<TimeSlotCapacity>>(
    future: _fetchTimeSlotsWithCapacity(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingSlots(); // Skeleton UI
      }
      
      return _buildCapacityAwareTimeSlots(snapshot.data ?? []);
    },
  );
}
```

### 💡 User Experience Enhancements

#### Smart Slot Filtering
- Only shows slots with sufficient capacity for selected group size
- Grays out unavailable slots instead of hiding them
- Shows capacity remaining in real-time

#### Helpful Information
- "X slots available for Y people" header
- Explanation: "Multiple people can book the same time slot"
- Capacity breakdown in error dialogs

#### Loading States
- Skeleton time slots while loading
- Progress indicators for capacity fetching
- Graceful error handling with retry options

## 🏗️ Architecture

### Core Models

```dart
// Time slot with full capacity information
class TimeSlotCapacity {
  final String timeSlot;        // "14:30"
  final DateTime date;          // Full date
  final int totalCapacity;      // 20 (provider capacity)
  final int bookedCapacity;     // 15 (currently booked)  
  final int availableCapacity;  // 5 (remaining spots)
  final List<ReservationSummary> existingReservations;
  
  bool get isAvailable;         // true if availableCapacity > 0
  double get utilizationRate;   // 0.75 (75% full)
  CapacityStatus get status;    // available/halfFull/almostFull/full
}

// Summary of existing reservations in a time slot
class ReservationSummary {
  final String id;
  final String userId;
  final String userName;
  final int attendeeCount;      // How many people this reservation includes
  final ReservationStatus status;
}

// Capacity validation result
class CapacityValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int totalCapacity;
  final int availableCapacity;
  final TimeSlotCapacity? timeSlotCapacity;
}
```

## 🚀 Usage Examples

### 1. Fetch Available Slots with Capacity Information

```dart
// New capacity-aware method
final slotsWithCapacity = await FirebaseDataOrchestrator()
    .fetchAvailableSlotsWithCapacity(
  providerId: 'provider123',
  date: DateTime(2024, 1, 15),
  durationMinutes: 60,
);

// Display in UI
for (final slot in slotsWithCapacity) {
  print('${slot.timeSlot}: ${slot.availableCapacity}/${slot.totalCapacity} available');
  print('Status: ${slot.status.displayText}');
  print('Current bookings: ${slot.existingReservations.length}');
  
  // Show color indicator
  Container(
    color: slot.status.color,
    child: Text('${slot.timeSlot} (${slot.availableCapacity} left)'),
  );
}
```

### 2. Backward Compatible Slot Fetching

```dart
// Existing method still works - now powered by capacity system
final availableSlots = await FirebaseDataOrchestrator()
    .fetchAvailableSlots(
  providerId: 'provider123', 
  date: DateTime(2024, 1, 15),
  durationMinutes: 60,
);

// Returns: ['09:00', '10:30', '14:00'] - only slots with available capacity
```

### 3. Validate Capacity Before Booking

```dart
final validation = await FirebaseDataOrchestrator()
    .validateReservationCapacity(
  providerId: 'provider123',
  reservationTime: DateTime(2024, 1, 15, 14, 30),
  durationMinutes: 60,
  attendeeCount: 3,
);

if (validation.isValid) {
  // Proceed with booking
  print('✅ Can book ${attendeeCount} people');
  print('${validation.availableCapacity} spots remaining');
} else {
  // Show error to user
  print('❌ ${validation.errorMessage}');
}
```

### 4. Create Reservation with Automatic Capacity Validation

```dart
// Capacity validation happens automatically
try {
  final reservationId = await FirebaseDataOrchestrator()
      .createReservation(reservation);
  
  print('🎉 Reservation created: $reservationId');
} catch (e) {
  if (e.toString().contains('Capacity validation failed')) {
    // Handle capacity error specifically
    showCapacityErrorDialog();
  }
}
```

### 5. Get Specific Time Slot Capacity

```dart
final slotCapacity = await FirebaseDataOrchestrator()
    .getTimeSlotCapacity(
  providerId: 'provider123',
  timeSlot: DateTime(2024, 1, 15, 14, 30),
  durationMinutes: 60,
);

if (slotCapacity != null) {
  print('Total: ${slotCapacity.totalCapacity}');
  print('Booked: ${slotCapacity.bookedCapacity}'); 
  print('Available: ${slotCapacity.availableCapacity}');
}
```

## 🎨 UI Implementation Examples

### Capacity Status Colors

```dart
extension CapacityStatusExtension on CapacityStatus {
  Color get color {
    switch (this) {
      case CapacityStatus.available:   return Colors.green;      // 0-50% full
      case CapacityStatus.halfFull:    return Colors.orange;     // 50-80% full  
      case CapacityStatus.almostFull:  return Colors.red.shade300; // 80-99% full
      case CapacityStatus.full:        return Colors.red;        // 100% full
    }
  }
}
```

### Time Slot UI Widget

```dart
Widget buildTimeSlotCard(TimeSlotCapacity slot) {
  return Card(
    color: slot.status.color.withOpacity(0.1),
    child: ListTile(
      title: Text(slot.timeSlot),
      subtitle: Text('${slot.availableCapacity}/${slot.totalCapacity} available'),
      trailing: Icon(
        slot.isAvailable ? Icons.check_circle : Icons.cancel,
        color: slot.status.color,
      ),
      onTap: slot.isAvailable ? () => bookSlot(slot) : null,
    ),
  );
}
```

### Capacity Progress Indicator

```dart
Widget buildCapacityIndicator(TimeSlotCapacity slot) {
  return Column(
    children: [
      LinearProgressIndicator(
        value: slot.utilizationRate,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation(slot.status.color),
      ),
      Text('${(slot.utilizationRate * 100).toInt()}% full'),
    ],
  );
}
```

## 📊 Database Structure

The capacity system works with the existing database structure:

```
/serviceProviders/{providerId}
  - totalCapacity: 20           // Provider's maximum capacity
  - maxCapacity: 20             // Alternative field name
  
  /pendingReservations/{reservationId}
    - reservationId: "res123"
    - userId: "user456" 
    
  /confirmedReservations/{reservationId}
    - reservationId: "res123"
    - userId: "user456"

/endUsers/{userId}/reservations/{reservationId}
  - attendees: [...]            // Array of attendees (counted for capacity)
  - reservationStartTime: timestamp
  - durationMinutes: 60
  - status: "confirmed"
```

## ⚡ Performance Optimizations

### Batch Operations
```dart
// Efficient fetching of multiple reservations
final reservations = await fetchProviderReservations(providerId);
// Uses batch reads from pending/confirmed collections
```

### Caching Strategy
```dart
// Cache capacity data for frequently accessed providers
final capacityCache = <String, TimeSlotCapacity>{};
```

### Real-time Updates
```dart
// Listen to reservation changes for live capacity updates
StreamBuilder<List<TimeSlotCapacity>>(
  stream: getCapacityUpdatesStream(providerId),
  builder: (context, snapshot) {
    // UI updates automatically when capacity changes
  },
);
```

## 🛡️ Error Handling

### Capacity Validation Errors
```dart
try {
  await createReservation(reservation);
} catch (e) {
  if (e.toString().contains('Capacity validation failed')) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Booking Full'),
        content: Text('This time slot is now full. Please choose another time.'),
      ),
    );
  }
}
```

### Graceful Degradation
```dart
// Fallback to basic availability if capacity data unavailable
final slots = await fetchAvailableSlots(...) ?? await fetchBasicSlots(...);
```

## 🔄 Migration Guide

### From Old System
```dart
// Old way
final slots = await fetchAvailableSlots(...);

// New way (same result, better underlying system)  
final slots = await fetchAvailableSlots(...);
// OR get full capacity information
final slotsWithCapacity = await fetchAvailableSlotsWithCapacity(...);
```

### Updating UI
```dart
// Before: Simple list
ListView(children: slots.map((slot) => ListTile(title: Text(slot))).toList())

// After: Rich capacity information
ListView(children: slotsWithCapacity.map(buildTimeSlotCard).toList())
```

## 🎯 Best Practices

1. **Always validate capacity** before showing booking confirmation
2. **Show visual indicators** of capacity status to users
3. **Handle capacity errors gracefully** with clear messaging
4. **Cache capacity data** for better performance
5. **Use real-time updates** for live capacity changes
6. **Provide alternatives** when slots are full

## 🚀 Future Enhancements

- **Waitlist system** for full time slots
- **Dynamic pricing** based on capacity utilization
- **Capacity alerts** for providers
- **Advanced analytics** on capacity trends
- **Automated capacity adjustments** based on demand

---

**🎉 The capacity management system with enhanced UI is now ready for production use!** 