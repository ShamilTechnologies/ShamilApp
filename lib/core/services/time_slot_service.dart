import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

/// Time slot capacity information with real reservation data
class TimeSlotCapacity {
  final String time;
  final int totalCapacity;
  final int bookedCapacity;
  final List<String> bookedByUsers;

  TimeSlotCapacity({
    required this.time,
    required this.totalCapacity,
    required this.bookedCapacity,
    required this.bookedByUsers,
  });

  // Smart getters
  int get availableSpots => totalCapacity - bookedCapacity;
  double get capacityPercentage => (bookedCapacity / totalCapacity) * 100;
  bool get isFull => bookedCapacity >= totalCapacity;
  bool get isAlmostFull => capacityPercentage >= 80;
  bool get isHalfFull => capacityPercentage >= 50;
  bool get isAvailable => !isFull;

  String get capacityStatus {
    if (isFull) return 'Fully Booked';
    if (isAlmostFull) return 'Almost Full';
    if (isHalfFull) return 'Half Full';
    return 'Available';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotCapacity &&
          runtimeType == other.runtimeType &&
          time == other.time;

  @override
  int get hashCode => time.hashCode;
}

/// Service for generating and managing time slots with real data
class TimeSlotService {
  static final TimeSlotService _instance = TimeSlotService._internal();
  factory TimeSlotService() => _instance;
  TimeSlotService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate time slots based on service/plan timing and working hours
  Future<List<TimeSlotCapacity>> generateTimeSlots({
    required DateTime date,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
    int? customCapacity,
  }) async {
    try {
      // Get service duration (default 60 minutes)
      final durationMinutes = service?.estimatedDurationMinutes ??
          _getPlanDurationMinutes(plan) ??
          60;

      // Get working hours from provider or use defaults
      final workingHours = _getWorkingHours(provider, date);

      // Get base capacity from service/plan configuration
      final baseCapacity =
          await _getBaseCapacity(service, plan, provider, customCapacity);

      // Generate time slots based on duration
      final slots = _generateSlotTimes(
        workingHours['start']!,
        workingHours['end']!,
        durationMinutes,
      );

      // Fetch existing reservations for this date and provider
      final existingReservations = await _fetchExistingReservations(
        provider.id,
        date,
      );

      // Build capacity information for each slot
      final List<TimeSlotCapacity> timeSlots = [];

      debugPrint(
          '🏗️ Building ${slots.length} time slots with base capacity: $baseCapacity');

      for (final slotTime in slots) {
        final capacity = await _calculateSlotCapacity(
          slotTime: slotTime,
          date: date,
          providerId: provider.id,
          serviceId: service?.id,
          planId: plan?.id,
          baseCapacity: baseCapacity,
          durationMinutes: durationMinutes,
          existingReservations: existingReservations,
        );

        timeSlots.add(capacity);
      }

      // Log summary of generated slots
      final availableSlots = timeSlots.where((slot) => slot.isAvailable).length;
      final fullSlots = timeSlots.where((slot) => slot.isFull).length;
      final totalBookedSpots =
          timeSlots.fold(0, (total, slot) => total + slot.bookedCapacity);
      final totalAvailableSpots =
          timeSlots.fold(0, (total, slot) => total + slot.availableSpots);

      debugPrint(
          '📊 Summary: ${timeSlots.length} slots generated (real data only)');
      debugPrint('   🟢 Available: $availableSlots slots');
      debugPrint('   🔴 Full: $fullSlots slots');
      debugPrint(
          '   📈 Total capacity: $totalBookedSpots booked, $totalAvailableSpots available');

      return timeSlots;
    } catch (e) {
      debugPrint('❌ Error generating time slots: $e');
      return [];
    }
  }

  /// Get working hours for a specific date
  Map<String, DateTime> _getWorkingHours(
      ServiceProviderModel provider, DateTime date) {
    // Check if provider has specific working hours
    final workingHours = provider.openingHours;

    // Get day of week (1 = Monday, 7 = Sunday)
    final dayIndex = date.weekday;
    final dayName = _getDayName(dayIndex);

    DateTime startTime;
    DateTime endTime;

    if (workingHours.containsKey(dayName)) {
      final dayHours = workingHours[dayName];
      if (dayHours != null && dayHours.isOpen) {
        // Use the OpeningHoursDay object directly
        if (dayHours.startTime != null && dayHours.endTime != null) {
          startTime = DateTime(date.year, date.month, date.day,
              dayHours.startTime!.hour, dayHours.startTime!.minute);
          endTime = DateTime(date.year, date.month, date.day,
              dayHours.endTime!.hour, dayHours.endTime!.minute);
        } else {
          // Default times if startTime/endTime are null
          startTime = DateTime(date.year, date.month, date.day, 9);
          endTime = DateTime(date.year, date.month, date.day, 18);
        }
      } else {
        // Closed day or no hours defined
        startTime = DateTime(date.year, date.month, date.day, 9);
        endTime = DateTime(
            date.year, date.month, date.day, 9); // Same time = no slots
      }
    } else {
      // Default working hours: 9 AM to 6 PM
      startTime = DateTime(date.year, date.month, date.day, 9);
      endTime = DateTime(date.year, date.month, date.day, 18);
    }

    return {
      'start': startTime,
      'end': endTime,
    };
  }

  /// Get day name from day index
  String _getDayName(int dayIndex) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[dayIndex - 1];
  }

  /// Generate slot times based on duration
  List<String> _generateSlotTimes(
      DateTime start, DateTime end, int durationMinutes) {
    final slots = <String>[];
    final format = DateFormat('HH:mm');

    DateTime current = start;

    while (current.add(Duration(minutes: durationMinutes)).isBefore(end) ||
        current.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(end)) {
      slots.add(format.format(current));
      current = current.add(Duration(minutes: durationMinutes));
    }

    return slots;
  }

  /// Get base capacity from multiple real data sources including historical analysis
  Future<int> _getBaseCapacity(ServiceModel? service, PlanModel? plan,
      ServiceProviderModel provider, int? customCapacity) async {
    debugPrint('🔍 Getting base capacity...');

    if (customCapacity != null) {
      debugPrint('✅ Using custom capacity: $customCapacity');
      return customCapacity;
    }

    // 1. Check service options definition first
    if (service?.optionsDefinition != null) {
      final serviceCapacity =
          service!.optionsDefinition!['maxCapacity'] as int?;
      if (serviceCapacity != null && serviceCapacity > 0) {
        debugPrint('✅ Using service maxCapacity: $serviceCapacity');
        return serviceCapacity;
      }

      // Also check for other capacity-related fields
      final capacity = service.optionsDefinition!['capacity'] as int?;
      if (capacity != null && capacity > 0) {
        debugPrint('✅ Using service capacity: $capacity');
        return capacity;
      }

      final simultaneousCustomers =
          service.optionsDefinition!['simultaneousCustomers'] as int?;
      if (simultaneousCustomers != null && simultaneousCustomers > 0) {
        debugPrint(
            '✅ Using service simultaneousCustomers: $simultaneousCustomers');
        return simultaneousCustomers;
      }
    }

    // 2. Check plan options definition
    if (plan?.optionsDefinition != null) {
      final planCapacity = plan!.optionsDefinition!['maxCapacity'] as int?;
      if (planCapacity != null && planCapacity > 0) {
        debugPrint('✅ Using plan maxCapacity: $planCapacity');
        return planCapacity;
      }

      final capacity = plan.optionsDefinition!['capacity'] as int?;
      if (capacity != null && capacity > 0) {
        debugPrint('✅ Using plan capacity: $capacity');
        return capacity;
      }

      final classSize = plan.optionsDefinition!['classSize'] as int?;
      if (classSize != null && classSize > 0) {
        debugPrint('✅ Using plan classSize: $classSize');
        return classSize;
      }
    }

    // 3. Check provider-level capacity settings
    if (provider.totalCapacity != null && provider.totalCapacity! > 0) {
      debugPrint('✅ Using provider totalCapacity: ${provider.totalCapacity}');
      return provider.totalCapacity!;
    }

    if (provider.maxCapacity > 0) {
      debugPrint('✅ Using provider maxCapacity: ${provider.maxCapacity}');
      return provider.maxCapacity;
    }

    // 4. NEW: Analyze historical reservation data to determine real capacity
    debugPrint(
        '🔍 Analyzing historical reservations to determine real capacity...');
    final historicalCapacity = await _analyzeHistoricalCapacity(
      provider.id,
      service?.id,
      plan?.id,
    );

    if (historicalCapacity > 0) {
      debugPrint('✅ Using analyzed historical capacity: $historicalCapacity');
      return historicalCapacity;
    }

    // 5. Category-based intelligent defaults based on business type
    final category = provider.category.toLowerCase();
    int defaultCapacity;

    if (category.contains('salon') ||
        category.contains('beauty') ||
        category.contains('barber')) {
      defaultCapacity = 4; // Beauty services typically 2-6 stations
    } else if (category.contains('fitness') ||
        category.contains('gym') ||
        category.contains('yoga')) {
      defaultCapacity = 20; // Fitness classes typically 15-25 people
    } else if (category.contains('restaurant') ||
        category.contains('cafe') ||
        category.contains('dining')) {
      defaultCapacity = 30; // Restaurant tables/seats
    } else if (category.contains('medical') ||
        category.contains('clinic') ||
        category.contains('dental')) {
      defaultCapacity =
          3; // Medical practices typically 1-5 simultaneous patients
    } else if (category.contains('spa') || category.contains('massage')) {
      defaultCapacity = 6; // Spa rooms typically 4-8
    } else if (category.contains('education') ||
        category.contains('tutoring') ||
        category.contains('training')) {
      defaultCapacity = 12; // Training sessions typically 8-15 people
    } else if (service != null) {
      defaultCapacity = 6; // Services: conservative default
    } else if (plan != null) {
      defaultCapacity = 15; // Plans/classes: higher default
    } else {
      defaultCapacity = 10; // General fallback
    }

    debugPrint(
        '⚠️ Using intelligent default capacity: $defaultCapacity (category: $category)');
    return defaultCapacity;
  }

  /// Analyze historical reservation data to determine real capacity
  Future<int> _analyzeHistoricalCapacity(
    String providerId,
    String? serviceId,
    String? planId,
  ) async {
    try {
      debugPrint('📊 Starting historical capacity analysis...');

      // Query reservations from the last 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      // Build query based on available filters
      var query = _firestore
          .collection('reservations')
          .where('providerId', isEqualTo: providerId)
          .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
          .where('status', whereIn: ['confirmed', 'completed']);

      // Add service/plan filter if available
      if (serviceId != null) {
        query = query.where('serviceId', isEqualTo: serviceId);
      } else if (planId != null) {
        query = query.where('planId', isEqualTo: planId);
      }

      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();

      debugPrint('📈 Found ${reservations.length} historical reservations');

      if (reservations.isEmpty) {
        debugPrint('⚠️ No historical data available');
        return 0; // No historical data
      }

      // Group reservations by date and time slots to find peak concurrent usage
      final Map<String, Map<String, int>> dailyHourlyCapacity = {};

      for (final reservation in reservations) {
        if (reservation.reservationStartTime == null) continue;

        final startTime = reservation.reservationStartTime!.toDate();
        final endTime = reservation.endTime?.toDate() ??
            startTime.add(Duration(minutes: reservation.durationMinutes ?? 60));

        final dateKey = '${startTime.year}-${startTime.month}-${startTime.day}';
        dailyHourlyCapacity.putIfAbsent(dateKey, () => {});

        // Calculate occupied hours for this reservation
        var currentHour = DateTime(
            startTime.year, startTime.month, startTime.day, startTime.hour);
        final endHour =
            DateTime(endTime.year, endTime.month, endTime.day, endTime.hour);

        while (currentHour.isBefore(endHour) ||
            currentHour.isAtSameMomentAs(endHour)) {
          final hourKey = '${currentHour.hour}:00';
          final capacity =
              reservation.reservedCapacity ?? reservation.groupSize;

          dailyHourlyCapacity[dateKey]![hourKey] =
              (dailyHourlyCapacity[dateKey]![hourKey] ?? 0) + capacity;

          currentHour = currentHour.add(const Duration(hours: 1));
        }
      }

      // Find the maximum concurrent capacity ever recorded
      int maxConcurrentCapacity = 0;
      String? peakDate;
      String? peakHour;

      for (final dateEntry in dailyHourlyCapacity.entries) {
        for (final hourEntry in dateEntry.value.entries) {
          if (hourEntry.value > maxConcurrentCapacity) {
            maxConcurrentCapacity = hourEntry.value;
            peakDate = dateEntry.key;
            peakHour = hourEntry.key;
          }
        }
      }

      // Calculate average peak capacity over different days
      final List<int> dailyPeaks = [];
      for (final dayData in dailyHourlyCapacity.values) {
        if (dayData.isNotEmpty) {
          final dayPeak = dayData.values.reduce((a, b) => a > b ? a : b);
          dailyPeaks.add(dayPeak);
        }
      }

      if (dailyPeaks.isEmpty) {
        debugPrint('⚠️ No peak data available');
        return 0;
      }

      // Calculate statistics
      final averagePeak =
          dailyPeaks.reduce((a, b) => a + b) / dailyPeaks.length;
      dailyPeaks.sort();
      final medianPeak = dailyPeaks.length % 2 == 0
          ? (dailyPeaks[dailyPeaks.length ~/ 2 - 1] +
                  dailyPeaks[dailyPeaks.length ~/ 2]) /
              2
          : dailyPeaks[dailyPeaks.length ~/ 2].toDouble();

      // Use the higher of average or median, plus a buffer for growth
      final recommendedCapacity =
          ((averagePeak > medianPeak ? averagePeak : medianPeak) * 1.2).round();

      debugPrint('📊 Historical Analysis Results:');
      debugPrint(
          '   📈 Maximum concurrent: $maxConcurrentCapacity (on $peakDate at $peakHour)');
      debugPrint('   📊 Average peak: ${averagePeak.toStringAsFixed(1)}');
      debugPrint('   📊 Median peak: ${medianPeak.toStringAsFixed(1)}');
      debugPrint('   🎯 Recommended capacity: $recommendedCapacity');
      debugPrint('   📅 Analysis period: ${dailyHourlyCapacity.length} days');

      // Return the recommended capacity (with minimum of 2)
      return recommendedCapacity.clamp(2, 50); // Reasonable bounds
    } catch (e) {
      debugPrint('❌ Error analyzing historical capacity: $e');
      return 0; // Fall back to other methods
    }
  }

  /// Analyze user reservation patterns for additional insights
  Future<Map<String, dynamic>> analyzeUserReservationPatterns(
    String providerId, {
    String? serviceId,
    String? planId,
    int? days = 30,
  }) async {
    try {
      debugPrint('👥 Analyzing user patterns for capacity insights...');

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days!));

      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      // Build query
      var query = _firestore
          .collection('reservations')
          .where('providerId', isEqualTo: providerId)
          .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
          .where('status', whereIn: ['confirmed', 'completed']);

      if (serviceId != null) {
        query = query.where('serviceId', isEqualTo: serviceId);
      } else if (planId != null) {
        query = query.where('planId', isEqualTo: planId);
      }

      final querySnapshot = await query.get();
      final reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();

      if (reservations.isEmpty) {
        return {
          'totalReservations': 0,
          'uniqueUsers': 0,
          'averageGroupSize': 0,
          'peakHours': <String>[],
          'peakDays': <String>[],
          'recommendedCapacity': 0,
        };
      }

      // Analyze patterns
      final Set<String> uniqueUsers = {};
      final List<int> groupSizes = [];
      final Map<int, int> hourlyBookings = {}; // hour -> count
      final Map<int, int> dailyBookings = {}; // weekday -> count
      final Map<String, int> concurrentCapacity =
          {}; // time slot -> total capacity

      for (final reservation in reservations) {
        // Track unique users
        if (reservation.attendees.isNotEmpty) {
          uniqueUsers.addAll(reservation.attendees.map((a) => a.userId));
        }

        // Track group sizes
        final groupSize = reservation.groupSize > 0 ? reservation.groupSize : 1;
        groupSizes.add(groupSize);

        // Track hourly patterns
        if (reservation.reservationStartTime != null) {
          final startTime = reservation.reservationStartTime!.toDate();
          final hour = startTime.hour;
          final weekday = startTime.weekday;

          hourlyBookings[hour] = (hourlyBookings[hour] ?? 0) + 1;
          dailyBookings[weekday] = (dailyBookings[weekday] ?? 0) + 1;

          // Track concurrent capacity needs
          final timeSlot = '${startTime.hour}:${startTime.minute}';
          final capacity = reservation.reservedCapacity ?? groupSize;
          concurrentCapacity[timeSlot] =
              (concurrentCapacity[timeSlot] ?? 0) + capacity;
        }
      }

      // Calculate statistics
      final averageGroupSize = groupSizes.isNotEmpty
          ? groupSizes.reduce((a, b) => a + b) / groupSizes.length
          : 0.0;

      // Find peak hours (top 3)
      final sortedHours = hourlyBookings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final peakHours = sortedHours
          .take(3)
          .map((e) => '${e.key}:00 (${e.value} bookings)')
          .toList();

      // Find peak days (top 3)
      final sortedDays = dailyBookings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final peakDays = sortedDays
          .take(3)
          .map((e) => '${dayNames[e.key - 1]} (${e.value} bookings)')
          .toList();

      // Calculate recommended capacity based on max concurrent bookings
      final maxConcurrent = concurrentCapacity.values.isNotEmpty
          ? concurrentCapacity.values.reduce((a, b) => a > b ? a : b)
          : 0;

      final recommendedCapacity = (maxConcurrent * 1.25).round().clamp(2, 50);

      final results = {
        'totalReservations': reservations.length,
        'uniqueUsers': uniqueUsers.length,
        'averageGroupSize': averageGroupSize,
        'peakHours': peakHours,
        'peakDays': peakDays,
        'maxConcurrentCapacity': maxConcurrent,
        'recommendedCapacity': recommendedCapacity,
        'analysisPeroid': '$days days',
      };

      debugPrint('👥 User Pattern Analysis Results:');
      debugPrint('   📊 Total reservations: ${results['totalReservations']}');
      debugPrint('   👤 Unique users: ${results['uniqueUsers']}');
      debugPrint(
          '   👥 Average group size: ${averageGroupSize.toStringAsFixed(1)}');
      debugPrint('   ⏰ Peak hours: ${peakHours.join(', ')}');
      debugPrint('   📅 Peak days: ${peakDays.join(', ')}');
      debugPrint('   🎯 Max concurrent: $maxConcurrent');
      debugPrint('   💡 Recommended capacity: $recommendedCapacity');

      return results;
    } catch (e) {
      debugPrint('❌ Error analyzing user patterns: $e');
      return {
        'error': e.toString(),
        'recommendedCapacity': 0,
      };
    }
  }

  /// Get plan duration in minutes
  int? _getPlanDurationMinutes(PlanModel? plan) {
    if (plan?.optionsDefinition != null) {
      final duration =
          plan!.optionsDefinition!['sessionDurationMinutes'] as int?;
      if (duration != null) return duration;
    }
    return null; // Use default
  }

  /// Fetch existing reservations for a specific date and provider
  Future<List<ReservationModel>> _fetchExistingReservations(
    String providerId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final startTimestamp = Timestamp.fromDate(startOfDay);
      final endTimestamp = Timestamp.fromDate(endOfDay);

      debugPrint(
          '🔍 Fetching reservations for provider: $providerId on ${date.toString().split(' ')[0]}');

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('providerId', isEqualTo: providerId)
          .where('reservationStartTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('reservationStartTime', isLessThanOrEqualTo: endTimestamp)
          .where('status',
              whereIn: ['confirmed', 'pending']) // Only active reservations
          .get();

      final reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ Found ${reservations.length} real reservations');

      // Log reservation details for debugging
      for (final reservation in reservations) {
        final startTime = reservation.reservationStartTime?.toDate();
        final capacity = reservation.reservedCapacity ?? reservation.groupSize;
        debugPrint(
            '   📅 ${startTime?.toString().split(' ')[1].substring(0, 5)} - ${reservation.userName} ($capacity people)');
      }

      return reservations;
    } catch (e) {
      debugPrint('❌ Error fetching reservations: $e');
      debugPrint('! Returning empty list - no fake data used');
      return [];
    }
  }

  /// Calculate capacity for a specific time slot with real-time data
  Future<TimeSlotCapacity> _calculateSlotCapacity({
    required String slotTime,
    required DateTime date,
    required String providerId,
    String? serviceId,
    String? planId,
    required int baseCapacity,
    required int durationMinutes,
    required List<ReservationModel> existingReservations,
  }) async {
    try {
      // Parse slot time
      final slotDateTime = _parseTimeString(date, slotTime);
      final slotEndTime = slotDateTime.add(Duration(minutes: durationMinutes));

      debugPrint(
          '🕐 Calculating capacity for $slotTime (${slotDateTime.toString().split(' ')[1].substring(0, 5)} - ${slotEndTime.toString().split(' ')[1].substring(0, 5)})');

      // Find overlapping reservations with detailed overlap checking
      final overlappingReservations = <ReservationModel>[];

      for (final reservation in existingReservations) {
        if (reservation.reservationStartTime == null) continue;

        final resStartTime = reservation.reservationStartTime!.toDate();
        final resEndTime = reservation.endTime?.toDate() ??
            resStartTime
                .add(Duration(minutes: reservation.durationMinutes ?? 60));

        // Detailed overlap checking
        final hasOverlap = (resStartTime.isBefore(slotEndTime) &&
            resEndTime.isAfter(slotDateTime));

        if (hasOverlap) {
          overlappingReservations.add(reservation);
          debugPrint(
              '   📅 Overlap found: ${reservation.userName} (${resStartTime.toString().split(' ')[1].substring(0, 5)} - ${resEndTime.toString().split(' ')[1].substring(0, 5)})');
        }
      }

      // Calculate booked capacity with detailed tracking
      int bookedCapacity = 0;
      List<String> bookedByUsers = [];

      debugPrint(
          '   👥 Processing ${overlappingReservations.length} overlapping reservations...');

      for (final reservation in overlappingReservations) {
        // Count the group size or reserved capacity
        final reservationCapacity =
            reservation.reservedCapacity ?? reservation.groupSize;
        bookedCapacity += reservationCapacity;

        debugPrint(
            '     📋 ${reservation.userName}: +$reservationCapacity people (total: $bookedCapacity/$baseCapacity)');

        // Add user names (avoid duplicates)
        if (!bookedByUsers.contains(reservation.userName)) {
          bookedByUsers.add(reservation.userName);
        }

        // Add attendee names
        for (final attendee in reservation.attendees) {
          if (!bookedByUsers.contains(attendee.name)) {
            bookedByUsers.add(attendee.name);
            debugPrint('     👤 Added attendee: ${attendee.name}');
          }
        }
      }

      // Ensure we don't exceed capacity
      bookedCapacity = bookedCapacity.clamp(0, baseCapacity);

      final result = TimeSlotCapacity(
        time: slotTime,
        totalCapacity: baseCapacity,
        bookedCapacity: bookedCapacity,
        bookedByUsers: bookedByUsers,
      );

      final availableSpots = result.availableSpots;
      final statusIcon =
          result.isFull ? '🔴' : (result.isAlmostFull ? '🟡' : '🟢');

      debugPrint(
          '   $statusIcon Result: $bookedCapacity/$baseCapacity booked, $availableSpots spots available');

      return result;
    } catch (e) {
      debugPrint('❌ Error calculating slot capacity for $slotTime: $e');
      return TimeSlotCapacity(
        time: slotTime,
        totalCapacity: baseCapacity,
        bookedCapacity: 0,
        bookedByUsers: [],
      );
    }
  }

  /// Parse time string to DateTime for a specific date
  DateTime _parseTimeString(DateTime date, String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      debugPrint('Error parsing time: $timeString');
      return DateTime(date.year, date.month, date.day, 9);
    }
  }

  /// Check if a specific time slot is available for booking
  Future<bool> isTimeSlotAvailable({
    required String providerId,
    required DateTime date,
    required String timeSlot,
    required int requestedCapacity,
    ServiceModel? service,
    PlanModel? plan,
  }) async {
    try {
      final slots = await generateTimeSlots(
        date: date,
        provider: ServiceProviderModel(
          id: providerId,
          businessName: '',
          category: '',
          businessDescription: '',
          address: const {},
          isActive: true,
          isApproved: true,
          pricingModel: PricingModel.other,
          createdAt: Timestamp.now(),
        ),
        service: service,
        plan: plan,
      );

      final slot = slots.firstWhere(
        (s) => s.time == timeSlot,
        orElse: () => TimeSlotCapacity(
          time: timeSlot,
          totalCapacity: 0,
          bookedCapacity: 0,
          bookedByUsers: [],
        ),
      );

      return slot.availableSpots >= requestedCapacity;
    } catch (e) {
      debugPrint('❌ Error checking slot availability: $e');
      return false;
    }
  }

  /// Get slot statistics for a provider on a specific date
  Future<Map<String, dynamic>> getSlotStatistics({
    required String providerId,
    required DateTime date,
    ServiceModel? service,
    PlanModel? plan,
  }) async {
    try {
      final slots = await generateTimeSlots(
        date: date,
        provider: ServiceProviderModel(
          id: providerId,
          businessName: '',
          category: '',
          businessDescription: '',
          address: const {},
          isActive: true,
          isApproved: true,
          pricingModel: PricingModel.other,
          createdAt: Timestamp.now(),
        ),
        service: service,
        plan: plan,
      );

      final totalSlots = slots.length;
      final availableSlots = slots.where((s) => s.isAvailable).length;
      final fullSlots = slots.where((s) => s.isFull).length;
      final almostFullSlots =
          slots.where((s) => s.isAlmostFull && !s.isFull).length;

      final totalCapacity =
          slots.fold<int>(0, (total, slot) => total + slot.totalCapacity);
      final totalBooked =
          slots.fold<int>(0, (total, slot) => total + slot.bookedCapacity);

      return {
        'totalSlots': totalSlots,
        'availableSlots': availableSlots,
        'fullSlots': fullSlots,
        'almostFullSlots': almostFullSlots,
        'totalCapacity': totalCapacity,
        'totalBooked': totalBooked,
        'overallCapacityPercentage':
            totalCapacity > 0 ? (totalBooked / totalCapacity) * 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting slot statistics: $e');
      return {
        'totalSlots': 0,
        'availableSlots': 0,
        'fullSlots': 0,
        'almostFullSlots': 0,
        'totalCapacity': 0,
        'totalBooked': 0,
        'overallCapacityPercentage': 0,
      };
    }
  }
}
