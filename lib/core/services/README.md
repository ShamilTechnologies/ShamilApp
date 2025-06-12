# Time Slot Service

The TimeSlotService provides real-time slot generation and capacity management based on actual reservation data.

## Key Features

- **Dynamic Time Slots**: Generated based on service duration and working hours
- **Real Capacity Data**: Fetches actual reservations from Firestore
- **Smart Overlap Detection**: Accurately calculates available capacity
- **Service/Plan Support**: Works with both individual services and plans
- **Provider Integration**: Respects working hours and business rules

## Usage

```dart
final timeSlotService = TimeSlotService();

final slots = await timeSlotService.generateTimeSlots(
  date: DateTime.now(),
  provider: serviceProvider,
  service: selectedService,
);
```

## Configuration

Services and plans can specify capacity in their `optionsDefinition`:

```dart
optionsDefinition: {
  'maxCapacity': 8,
  'sessionDurationMinutes': 60,
}
```

## Integration

The DateTimeSelector automatically uses this service for real-time availability. 