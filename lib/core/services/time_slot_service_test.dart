import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/core/services/time_slot_service.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test class to demonstrate TimeSlotService functionality
class TimeSlotServiceTest {
  static final TimeSlotService _timeSlotService = TimeSlotService();

  /// Test the time slot generation with a sample service
  static Future<void> testServiceTimeSlots() async {
    debugPrint('🧪 Testing TimeSlotService with Service...');

    // Create a sample service provider
    final provider = ServiceProviderModel(
      id: 'test_provider_123',
      businessName: 'Test Salon',
      category: 'Beauty',
      businessDescription: 'Professional beauty services',
      address: const {'street': '123 Test St', 'city': 'Cairo'},
      isActive: true,
      isApproved: true,
      pricingModel: PricingModel.reservation,
      createdAt: Timestamp.now(),
      openingHours: {
        'monday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isOpen: true,
        ),
        'tuesday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isOpen: true,
        ),
        'wednesday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isOpen: true,
        ),
        'thursday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isOpen: true,
        ),
        'friday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          isOpen: true,
        ),
        'saturday': OpeningHoursDay(
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 16, minute: 0),
          isOpen: true,
        ),
        'sunday': OpeningHoursDay(isOpen: false),
      },
    );

    // Create a sample service (60-minute haircut)
    final service = ServiceModel(
      id: 'haircut_service_456',
      providerId: 'test_provider_123',
      name: 'Professional Haircut',
      description: 'Expert haircut and styling',
      price: 150.0,
      priceType: 'fixed',
      category: 'Haircut',
      estimatedDurationMinutes: 60, // 1 hour service
      optionsDefinition: {
        'maxCapacity': 6, // 6 people can be served simultaneously
        'allowDateSelection': true,
        'allowTimeSelection': true,
      },
    );

    // Test for today
    final today = DateTime.now();
    debugPrint('📅 Testing for date: ${today.toString().split(' ')[0]}');

    try {
      final timeSlots = await _timeSlotService.generateTimeSlots(
        date: today,
        provider: provider,
        service: service,
      );

      debugPrint('✅ Generated ${timeSlots.length} time slots:');
      for (final slot in timeSlots) {
        debugPrint(
          '   ${slot.time} - ${slot.capacityStatus} (${slot.bookedCapacity}/${slot.totalCapacity})',
        );
        if (slot.bookedByUsers.isNotEmpty) {
          debugPrint('     Booked by: ${slot.bookedByUsers.join(', ')}');
        }
      }

      // Test availability check
      if (timeSlots.isNotEmpty) {
        final firstSlot = timeSlots.first;
        final isAvailable = await _timeSlotService.isTimeSlotAvailable(
          providerId: provider.id,
          date: today,
          timeSlot: firstSlot.time,
          requestedCapacity: 2,
          service: service,
        );
        debugPrint(
          '🔍 Availability check for ${firstSlot.time} (2 people): ${isAvailable ? 'Available' : 'Not Available'}',
        );
      }

      // Get statistics
      final stats = await _timeSlotService.getSlotStatistics(
        providerId: provider.id,
        date: today,
        service: service,
      );
      debugPrint('📊 Statistics: $stats');
    } catch (e) {
      debugPrint('❌ Error testing service time slots: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    debugPrint('🚀 Starting TimeSlotService Tests...\n');

    await testServiceTimeSlots();

    debugPrint('\n✅ All TimeSlotService tests completed!');
  }
}
