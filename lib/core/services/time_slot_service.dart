import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/firebase_data_orchestrator.dart';
import '../../feature/home/data/service_provider_model.dart';
import '../../feature/details/data/service_model.dart';
import '../../feature/details/data/plan_model.dart';
import '../../feature/reservation/data/models/reservation_model.dart';

/// Enhanced Time Slot Service with Real Firebase Data Integration
///
/// Features:
/// - Real-time capacity tracking from Firebase
/// - Dynamic slot generation based on provider availability
/// - Conflict detection with existing reservations
/// - Capacity optimization for different service types
/// - Real-world business hours integration
/// - Holiday and special hours support
class TimeSlotService {
  static final TimeSlotService _instance = TimeSlotService._internal();
  factory TimeSlotService() => _instance;
  TimeSlotService._internal();

  final FirebaseDataOrchestrator _firebaseOrchestrator =
      FirebaseDataOrchestrator();
  final Map<String, List<TimeSlotCapacity>> _slotCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Generate time slots with real Firebase data integration
  Future<List<TimeSlotCapacity>> generateTimeSlots({
    required DateTime date,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('🔄 Generating real-time slots for ${provider.businessName}');
      debugPrint('   Date: ${DateFormat('yyyy-MM-dd').format(date)}');
      debugPrint('   Service: ${service?.name ?? 'N/A'}');
      debugPrint('   Plan: ${plan?.name ?? 'N/A'}');

      // Check cache first (unless force refresh)
      final cacheKey =
          _generateCacheKey(date, provider.id, service?.id, plan?.id);
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        debugPrint('✅ Using cached slots');
        return _slotCache[cacheKey] ?? [];
      }

      // Get real working hours from provider
      final workingHours = await _getRealWorkingHours(provider, date);
      if (!workingHours['isOpen']) {
        debugPrint('❌ Provider is closed on this date');
        return [];
      }

      // Get service configuration with real duration
      final serviceConfig =
          await _getServiceConfiguration(service, plan, provider);
      debugPrint('📋 Service config: $serviceConfig');

      // Fetch existing reservations from Firebase for this date and provider
      final existingReservations = await _fetchExistingReservations(
        providerId: provider.id,
        date: date,
        serviceId: service?.id,
        planId: plan?.id,
      );
      debugPrint(
          '📅 Found ${existingReservations.length} existing reservations');

      // Generate slots based on real data
      final slots = await _generateRealTimeSlots(
        workingHours: workingHours,
        serviceConfig: serviceConfig,
        existingReservations: existingReservations,
        date: date,
        providerId: provider.id,
      );

      // Cache the results
      _slotCache[cacheKey] = slots;
      _cacheTimestamps[cacheKey] = DateTime.now();

      debugPrint('✅ Generated ${slots.length} real-time slots');
      return slots;
    } catch (e) {
      debugPrint('❌ Error generating time slots: $e');
      return [];
    }
  }

  /// Fetch existing reservations from Firebase for the specific date
  Future<List<ReservationModel>> _fetchExistingReservations({
    required String providerId,
    required DateTime date,
    String? serviceId,
    String? planId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Use FirebaseDataOrchestrator instead of direct Firebase queries
      debugPrint('🔍 Fetching reservations from Firebase:');
      debugPrint('   Provider: $providerId');
      debugPrint(
          '   Date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');
      debugPrint('   Service: $serviceId');

      final reservations = <ReservationModel>[];

      try {
        // Use the data orchestrator to get provider reservations from Firebase
        final orchestrator = FirebaseDataOrchestrator();
        final providerReservations =
            await orchestrator.fetchProviderReservations(providerId);

        debugPrint(
            '📋 Firebase data: ${providerReservations.length} total reservations found');

        // Filter reservations for the specific date and service
        for (final reservation in providerReservations) {
          try {
            final reservationDate = reservation.reservationStartTime?.toDate();
            if (reservationDate != null) {
              final reservationDay = DateTime(reservationDate.year,
                  reservationDate.month, reservationDate.day);
              final targetDay = DateTime(date.year, date.month, date.day);

              // Check if reservation is on the target date
              if (reservationDay.isAtSameMomentAs(targetDay)) {
                // Filter by service if specified
                if (serviceId != null) {
                  final reservationServiceId =
                      reservation.serviceId?.toString();
                  if (reservationServiceId != null &&
                      reservationServiceId != serviceId) {
                    debugPrint(
                        '   ⏭️ Skipping reservation ${reservation.id}: service mismatch ($reservationServiceId != $serviceId)');
                    continue;
                  }
                }

                // Check reservation status (only include active reservations)
                if (reservation.status == ReservationStatus.confirmed ||
                    reservation.status == ReservationStatus.pending) {
                  reservations.add(reservation);
                  debugPrint(
                      '   ✅ Added reservation: ${reservation.id} at ${reservation.reservationStartTime?.toDate()}');
                  debugPrint('      Status: ${reservation.status}');
                  debugPrint(
                      '      Attendees: ${reservation.attendees.length}');
                } else {
                  debugPrint(
                      '   ⏭️ Skipping reservation ${reservation.id}: status ${reservation.status}');
                }
              } else {
                debugPrint(
                    '   ⏭️ Skipping reservation ${reservation.id}: date mismatch');
              }
            } else {
              debugPrint(
                  '   ⚠️ Could not extract date from reservation ${reservation.id}');
            }
          } catch (e) {
            debugPrint('❌ Error processing reservation ${reservation.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Error fetching reservations from data orchestrator: $e');
        // Fallback: return empty list to avoid breaking the UI
      }

      // Also check subscriptions if it's a plan
      if (planId != null) {
        final subscriptionsQuery = FirebaseFirestore.instance
            .collection('subscriptions')
            .where('providerId', isEqualTo: providerId)
            .where('planId', isEqualTo: planId)
            .where('status', whereIn: ['active', 'pending']);

        final subSnapshot = await subscriptionsQuery.get();

        for (final doc in subSnapshot.docs) {
          try {
            final data = doc.data();
            // Convert subscription to reservation-like format for slot calculation
            if (data['startDate'] != null) {
              final startDate = (data['startDate'] as Timestamp).toDate();
              if (_isSameDay(startDate, date)) {
                // Create a pseudo-reservation for subscription slot blocking
                final pseudoReservation = ReservationModel(
                  id: 'sub_${doc.id}',
                  userId: data['userId'] ?? '',
                  userName: data['userName'] ?? 'Subscriber',
                  providerId: providerId,
                  governorateId: data['governorateId'] ?? '',
                  type: ReservationType.serviceBased,
                  serviceId: planId,
                  serviceName: data['planName'] ?? 'Plan Service',
                  reservationStartTime: Timestamp.fromDate(startDate),
                  durationMinutes: 90,
                  attendees: [],
                  status: ReservationStatus.confirmed,
                  paymentStatus: 'completed',
                  totalPrice: data['pricePaid']?.toDouble() ?? 0.0,
                  createdAt: Timestamp.now(),
                );
                reservations.add(pseudoReservation);
                debugPrint('   📋 Found subscription: ${doc.id} at $startDate');
              }
            }
          } catch (e) {
            debugPrint('❌ Error parsing subscription ${doc.id}: $e');
          }
        }
      }

      debugPrint('✅ Total reservations found: ${reservations.length}');
      return reservations;
    } catch (e) {
      debugPrint('❌ Error fetching existing reservations: $e');
      return [];
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Generate time slots with real capacity calculations based on actual reservations
  Future<List<TimeSlotCapacity>> _generateRealTimeSlots({
    required Map<String, dynamic> workingHours,
    required Map<String, dynamic> serviceConfig,
    required List<ReservationModel> existingReservations,
    required DateTime date,
    required String providerId,
  }) async {
    final List<TimeSlotCapacity> slots = [];

    try {
      final startTime = workingHours['start'] as DateTime;
      final endTime = workingHours['end'] as DateTime;

      final serviceDuration = serviceConfig['duration'] as int; // in minutes
      final maxCapacity = serviceConfig['capacity'] as int;
      final bufferTime =
          serviceConfig['bufferTime'] as int? ?? 15; // minutes between slots

      debugPrint('⏰ Generating slots:');
      debugPrint(
          '   Working hours: ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}');
      debugPrint('   Service duration: ${serviceDuration}min');
      debugPrint('   Max capacity: $maxCapacity');
      debugPrint('   Buffer time: ${bufferTime}min');

      // Generate slots based on service duration (not fixed 30-minute intervals)
      // For a 60-minute service, generate slots every 60 minutes
      final slotInterval = serviceDuration; // Use service duration as interval
      var currentSlotTime = startTime;
      final now = DateTime.now();
      final isToday = _isSameDay(date, now);

      while (currentSlotTime
              .add(Duration(minutes: serviceDuration))
              .isBefore(endTime) ||
          currentSlotTime
              .add(Duration(minutes: serviceDuration))
              .isAtSameMomentAs(endTime)) {
        final slotEndTime =
            currentSlotTime.add(Duration(minutes: serviceDuration));
        final timeString = DateFormat('HH:mm').format(currentSlotTime);

        // Skip past time slots for current day
        if (isToday && currentSlotTime.isBefore(now)) {
          debugPrint('   ⏭️ Skipping past slot: ${timeString}');
          currentSlotTime =
              currentSlotTime.add(Duration(minutes: slotInterval));
          continue;
        }

        // Calculate real capacity for this time slot
        final slotCapacity = await _calculateRealSlotCapacity(
          slotTime: currentSlotTime,
          slotEndTime: slotEndTime,
          maxCapacity: maxCapacity,
          existingReservations: existingReservations,
          serviceDuration: serviceDuration,
        );

        slots.add(slotCapacity);

        debugPrint(
            '   🕐 ${timeString}: ${slotCapacity.bookedCapacity}/${slotCapacity.totalCapacity} (${slotCapacity.capacityStatus})');

        // Move to next slot based on service duration
        currentSlotTime = currentSlotTime.add(Duration(minutes: slotInterval));
      }

      return slots;
    } catch (e) {
      debugPrint('❌ Error generating real-time slots: $e');
      return [];
    }
  }

  /// Calculate real slot capacity based on actual reservations
  Future<TimeSlotCapacity> _calculateRealSlotCapacity({
    required DateTime slotTime,
    required DateTime slotEndTime,
    required int maxCapacity,
    required List<ReservationModel> existingReservations,
    required int serviceDuration,
  }) async {
    try {
      final timeString = DateFormat('HH:mm').format(slotTime);
      int bookedCapacity = 0;
      final List<String> bookedByUsers = [];
      final List<ReservationSummary> conflictingReservations = [];

      // Check each existing reservation for overlap with this slot
      for (final reservation in existingReservations) {
        if (reservation.reservationStartTime == null) continue;

        final reservationStart = reservation.reservationStartTime!.toDate();
        final reservationDuration =
            reservation.durationMinutes ?? serviceDuration;
        final reservationEnd =
            reservationStart.add(Duration(minutes: reservationDuration));

        // Check if reservation overlaps with this slot
        final hasOverlap = _hasTimeOverlap(
          slotTime,
          slotEndTime,
          reservationStart,
          reservationEnd,
        );

        if (hasOverlap) {
          // Count attendees for capacity calculation
          final attendeeCount = math.max(1, reservation.attendees.length);
          bookedCapacity += attendeeCount;

          if (!bookedByUsers.contains(reservation.userName)) {
            bookedByUsers.add(reservation.userName);
          }

          // Add to conflicting reservations
          conflictingReservations.add(ReservationSummary(
            id: reservation.id,
            userId: reservation.userId,
            userName: reservation.userName,
            startTime: reservationStart,
            duration: reservationDuration,
            attendeeCount: attendeeCount,
            status: reservation.status.toString(),
          ));
        }
      }

      final availableCapacity = math.max(0, maxCapacity - bookedCapacity);
      final capacityPercentage =
          maxCapacity > 0 ? bookedCapacity / maxCapacity : 0.0;

      return TimeSlotCapacity(
        time: timeString,
        date: slotTime,
        totalCapacity: maxCapacity,
        bookedCapacity: bookedCapacity,
        availableSpots: availableCapacity,
        bookedByUsers: bookedByUsers,
        conflictingReservations: conflictingReservations,
        capacityPercentage: capacityPercentage,
        isAvailable: availableCapacity > 0,
        isFull: availableCapacity == 0,
        isAlmostFull: capacityPercentage >= 0.8,
        capacityStatus:
            _getCapacityStatus(capacityPercentage, availableCapacity),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error calculating real slot capacity: $e');
      return TimeSlotCapacity(
        time: DateFormat('HH:mm').format(slotTime),
        date: slotTime,
        totalCapacity: maxCapacity,
        bookedCapacity: 0,
        availableSpots: maxCapacity,
        bookedByUsers: [],
        conflictingReservations: [],
      );
    }
  }

  /// Check if two time periods overlap
  bool _hasTimeOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Get real working hours from provider configuration
  Future<Map<String, dynamic>> _getRealWorkingHours(
    ServiceProviderModel provider,
    DateTime date,
  ) async {
    try {
      final dayName = _getDayName(date.weekday);
      final dayHours = provider.openingHours[dayName];

      if (dayHours == null || !dayHours.isOpen) {
        return {'isOpen': false};
      }

      // Convert TimeOfDay to DateTime for the specific date
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        dayHours.startTime?.hour ?? 9,
        dayHours.startTime?.minute ?? 0,
      );

      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        dayHours.endTime?.hour ?? 18,
        dayHours.endTime?.minute ?? 0,
      );

      return {
        'isOpen': true,
        'start': startTime,
        'end': endTime,
        'dayName': dayName,
      };
    } catch (e) {
      debugPrint('❌ Error getting working hours: $e');
      return {'isOpen': false};
    }
  }

  /// Get service configuration with REAL-TIME Firebase data ONLY
  Future<Map<String, dynamic>> _getServiceConfiguration(
    ServiceModel? service,
    PlanModel? plan,
    ServiceProviderModel provider,
  ) async {
    try {
      // Debug capacity data to understand what's available
      await _debugCapacityData(service, plan, provider);
      if (service != null) {
        // Get service-specific capacity from REAL-TIME Firebase data ONLY
        int? serviceCapacity;

        // FIRST PRIORITY: Get capacity from REAL-TIME Firebase bookableServices data
        serviceCapacity = await _getCapacityFromFirebaseBookableServices(
            provider.id, service.id);

        // SECOND: Try to get capacity from optionsDefinition
        if (serviceCapacity == null && service.optionsDefinition != null) {
          serviceCapacity = service.optionsDefinition!['maxCapacity'] as int? ??
              service.optionsDefinition!['capacity'] as int? ??
              service.optionsDefinition!['maxParticipants'] as int? ??
              service.optionsDefinition!['sessionCapacity'] as int? ??
              service.optionsDefinition!['classCapacity'] as int?;
        }

        // THIRD: Try to get from service properties
        if (serviceCapacity == null) {
          final Map<String, dynamic> serviceData = service.toFirestore();
          serviceCapacity = serviceData['capacity'] as int? ??
              serviceData['maxCapacity'] as int? ??
              serviceData['sessionCapacity'] as int?;
        }

        // Finally, fall back to provider capacity
        final capacity =
            serviceCapacity ?? _getProviderCapacityFromModel(provider);

        debugPrint('🎯 PRODUCTION Service capacity configuration:');
        debugPrint('   Service: ${service.name} (ID: ${service.id})');
        debugPrint(
            '   🔥 Firebase bookableServices capacity: ${await _getCapacityFromFirebaseBookableServices(provider.id, service.id)}');
        debugPrint(
            '   Options definition capacity fields: ${service.optionsDefinition?.keys.where((k) => k.toLowerCase().contains('capacity')).toList()}');
        debugPrint('   Extracted service capacity: $serviceCapacity');
        debugPrint(
            '   Provider fallback capacity: ${_getProviderCapacityFromModel(provider)}');
        debugPrint('   🎯 FINAL PRODUCTION capacity: $capacity');

        return {
          'duration': service.estimatedDurationMinutes ?? 60,
          'capacity': capacity,
          'type': 'service',
          'id': service.id,
          'name': service.name,
          'bufferTime':
              service.optionsDefinition?['bufferTimeMinutes'] as int? ?? 15,
          'allowOverlap':
              service.optionsDefinition?['allowOverlappingBookings'] as bool? ??
                  false,
        };
      } else if (plan != null) {
        // Get plan-specific capacity
        int? planCapacity;

        if (plan.optionsDefinition != null) {
          planCapacity = plan.optionsDefinition!['maxParticipants'] as int? ??
              plan.optionsDefinition!['capacity'] as int? ??
              plan.optionsDefinition!['maxCapacity'] as int? ??
              plan.optionsDefinition!['subscriberLimit'] as int?;
        }

        final capacity =
            planCapacity ?? _getProviderCapacityFromModel(provider);

        debugPrint('🎯 Plan capacity configuration:');
        debugPrint('   Plan: ${plan.name} (ID: ${plan.id})');
        debugPrint('   Options definition: ${plan.optionsDefinition}');
        debugPrint('   Extracted plan capacity: $planCapacity');
        debugPrint(
            '   Provider capacity: ${_getProviderCapacityFromModel(provider)}');
        debugPrint('   Final capacity used: $capacity');

        return {
          'duration': _getPlanDurationMinutes(plan) ?? 90,
          'capacity': capacity,
          'type': 'plan',
          'id': plan.id,
          'name': plan.name,
          'bufferTime': 30, // Plans typically need more buffer time
          'allowOverlap': true, // Plans can have multiple subscribers
        };
      }

      // Default configuration using provider capacity
      final defaultCapacity = _getProviderCapacityFromModel(provider);
      debugPrint('🎯 Default capacity configuration: $defaultCapacity');

      return {
        'duration': 60,
        'capacity': defaultCapacity,
        'type': 'default',
        'bufferTime': 15,
        'allowOverlap': false,
      };
    } catch (e) {
      debugPrint('❌ Error getting service configuration: $e');
      return {
        'duration': 60,
        'capacity': 10,
        'type': 'default',
        'bufferTime': 15,
        'allowOverlap': false,
      };
    }
  }

  /// Get real-time capacity from Firebase bookableServices array
  Future<int?> _getCapacityFromFirebaseBookableServices(
      String providerId, String serviceId) async {
    try {
      debugPrint('🔍 Fetching capacity from Firebase bookableServices...');
      debugPrint('   Provider ID: $providerId');
      debugPrint('   Service ID: $serviceId');

      final providerDoc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(providerId)
          .get();

      if (!providerDoc.exists || providerDoc.data() == null) {
        debugPrint('❌ Provider document not found in Firebase');
        return null;
      }

      final data = providerDoc.data()!;
      final bookableServices = data['bookableServices'] as List<dynamic>?;

      if (bookableServices == null || bookableServices.isEmpty) {
        debugPrint('❌ No bookableServices found in Firebase');
        return null;
      }

      debugPrint(
          '📋 Found ${bookableServices.length} bookable services in Firebase');

      // Find the service with matching ID
      for (final serviceData in bookableServices) {
        if (serviceData is Map<String, dynamic>) {
          final id = serviceData['id']?.toString();
          final name = serviceData['name']?.toString();
          final capacity = serviceData['capacity'] as int?;
          final duration = serviceData['durationMinutes'] as int?;

          debugPrint(
              '   📋 Service: $name (ID: $id, Capacity: $capacity, Duration: ${duration}min)');

          if (id == serviceId) {
            debugPrint('✅ FOUND MATCHING SERVICE IN FIREBASE:');
            debugPrint('   Name: $name');
            debugPrint('   ID: $id');
            debugPrint('   Capacity: $capacity');
            debugPrint('   Duration: ${duration} minutes');
            return capacity;
          }
        }
      }

      debugPrint(
          '❌ Service ID $serviceId not found in Firebase bookableServices');
      debugPrint(
          '   Available service IDs: ${bookableServices.map((s) => s is Map ? s['id'] : 'invalid').toList()}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching capacity from Firebase: $e');
      return null;
    }
  }

  /// Get provider capacity from the provider model (production fallback only)
  int _getProviderCapacityFromModel(ServiceProviderModel provider) {
    try {
      // Try to get capacity from available fields in the provider model
      final capacity = provider.totalCapacity ??
          provider.maxCapacity ??
          provider.maxGroupSize ??
          10; // Conservative production default

      debugPrint('🏢 Provider capacity from model (fallback):');
      debugPrint('   Provider: ${provider.businessName} (ID: ${provider.id})');
      debugPrint('   Total capacity: ${provider.totalCapacity}');
      debugPrint('   Max capacity: ${provider.maxCapacity}');
      debugPrint('   Max group size: ${provider.maxGroupSize}');
      debugPrint('   Final capacity used: $capacity');

      return capacity;
    } catch (e) {
      debugPrint('❌ Error getting provider capacity from model: $e');
      return 10; // Conservative production default
    }
  }

  /// Get provider default capacity from Firebase (deprecated - use model instead)
  Future<int> _getProviderDefaultCapacity(String providerId) async {
    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('serviceProviders') // Fixed collection name
          .doc(providerId)
          .get();

      if (providerDoc.exists) {
        final data = providerDoc.data()!;
        return data['defaultCapacity'] ??
            data['maxCapacity'] ??
            data['totalCapacity'] ??
            10;
      }

      return 10; // Default capacity
    } catch (e) {
      debugPrint('❌ Error getting provider capacity: $e');
      return 10;
    }
  }

  /// Get capacity status message
  String _getCapacityStatus(double percentage, int availableSpots) {
    if (availableSpots == 0) return 'Fully Booked';
    if (percentage >= 0.9) return 'Almost Full';
    if (percentage >= 0.7) return 'Filling Up';
    if (percentage >= 0.5) return 'Half Full';
    return 'Available';
  }

  /// Generate cache key for slot caching
  String _generateCacheKey(
      DateTime date, String providerId, String? serviceId, String? planId) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${providerId}_${dateStr}_${serviceId ?? ''}_${planId ?? ''}';
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  /// Get plan duration in minutes
  int? _getPlanDurationMinutes(PlanModel? plan) {
    if (plan == null) return null;

    // Extract duration from plan description or use default
    if (plan.description.toLowerCase().contains('hour')) {
      final match =
          RegExp(r'(\d+)\s*hour').firstMatch(plan.description.toLowerCase());
      if (match != null) {
        return int.tryParse(match.group(1)!) != null
            ? int.parse(match.group(1)!) * 60
            : null;
      }
    }

    return 90; // Default plan duration
  }

  /// Clear cache for specific provider/date
  void clearCache({String? providerId, DateTime? date}) {
    if (providerId != null && date != null) {
      final pattern = '${providerId}_${DateFormat('yyyy-MM-dd').format(date)}';
      _slotCache.removeWhere((key, value) => key.startsWith(pattern));
      _cacheTimestamps.removeWhere((key, value) => key.startsWith(pattern));
    } else {
      _slotCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Refresh slots for real-time updates
  Future<List<TimeSlotCapacity>> refreshSlots({
    required DateTime date,
    required ServiceProviderModel provider,
    ServiceModel? service,
    PlanModel? plan,
  }) async {
    return generateTimeSlots(
      date: date,
      provider: provider,
      service: service,
      plan: plan,
      forceRefresh: true,
    );
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
          pricingModel: PricingModel.reservation,
          createdAt: Timestamp.now(),
        ),
        service: service,
        plan: plan,
      );

      final targetSlot = slots.firstWhere(
        (slot) => slot.time == timeSlot,
        orElse: () => TimeSlotCapacity(
          time: timeSlot,
          date: date,
          totalCapacity: 0,
          bookedCapacity: 0,
          availableSpots: 0,
          bookedByUsers: [],
          conflictingReservations: [],
        ),
      );

      return targetSlot.availableSpots >= requestedCapacity;
    } catch (e) {
      debugPrint('❌ Error checking slot availability: $e');
      return false;
    }
  }

  /// Get statistics for time slots on a specific date
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
          pricingModel: PricingModel.reservation,
          createdAt: Timestamp.now(),
        ),
        service: service,
        plan: plan,
      );

      final totalSlots = slots.length;
      final availableSlots = slots.where((slot) => slot.isAvailable).length;
      final fullSlots = slots.where((slot) => slot.isFull).length;
      final almostFullSlots = slots.where((slot) => slot.isAlmostFull).length;

      final totalCapacity =
          slots.fold<int>(0, (sum, slot) => sum + slot.totalCapacity);
      final bookedCapacity =
          slots.fold<int>(0, (sum, slot) => sum + slot.bookedCapacity);
      final availableCapacity = totalCapacity - bookedCapacity;

      return {
        'total_slots': totalSlots,
        'available_slots': availableSlots,
        'full_slots': fullSlots,
        'almost_full_slots': almostFullSlots,
        'total_capacity': totalCapacity,
        'booked_capacity': bookedCapacity,
        'available_capacity': availableCapacity,
        'utilization_rate':
            totalCapacity > 0 ? bookedCapacity / totalCapacity : 0.0,
        'peak_hours': _getPeakHours(slots),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting slot statistics: $e');
      return {
        'total_slots': 0,
        'available_slots': 0,
        'full_slots': 0,
        'almost_full_slots': 0,
        'total_capacity': 0,
        'booked_capacity': 0,
        'available_capacity': 0,
        'utilization_rate': 0.0,
        'peak_hours': [],
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get peak hours based on booking patterns
  List<String> _getPeakHours(List<TimeSlotCapacity> slots) {
    final peakSlots = slots
        .where((slot) => slot.capacityPercentage >= 0.7)
        .map((slot) => slot.time)
        .toList();

    peakSlots.sort();
    return peakSlots;
  }

  /// Extract reservation date from data with common field name variations
  DateTime? _extractReservationDate(Map<String, dynamic> data) {
    try {
      // Try the most common field names
      if (data.containsKey('reservationStartTime')) {
        return (data['reservationStartTime'] as Timestamp).toDate();
      } else if (data.containsKey('startTime')) {
        return (data['startTime'] as Timestamp).toDate();
      } else if (data.containsKey('reservationTime')) {
        return (data['reservationTime'] as Timestamp).toDate();
      } else if (data.containsKey('reservation_start_time')) {
        return (data['reservation_start_time'] as Timestamp).toDate();
      } else if (data.containsKey('createdAt')) {
        return (data['createdAt'] as Timestamp).toDate();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error extracting date from reservation data: $e');
      return null;
    }
  }

  /// Debug capacity data for production troubleshooting
  Future<void> _debugCapacityData(
    ServiceModel? service,
    PlanModel? plan,
    ServiceProviderModel provider,
  ) async {
    debugPrint('🔍 PRODUCTION Capacity Debug:');
    debugPrint('   Provider: ${provider.businessName} (${provider.id})');

    if (service != null) {
      debugPrint('   Service: ${service.name} (${service.id})');

      // Check Firebase bookableServices capacity
      final firebaseCapacity = await _getCapacityFromFirebaseBookableServices(
          provider.id, service.id);
      debugPrint('   🔥 Firebase bookableServices capacity: $firebaseCapacity');

      // Check service options
      if (service.optionsDefinition != null) {
        final options = service.optionsDefinition!;
        debugPrint('   Service options: {');
        options.forEach((key, value) {
          if (key.toLowerCase().contains('capacity') ||
              key.toLowerCase().contains('participant') ||
              key.toLowerCase().contains('max')) {
            debugPrint('     $key: $value');
          }
        });
        debugPrint('   }');
      }
    }

    if (plan != null) {
      debugPrint('   Plan: ${plan.name} (${plan.id})');
      if (plan.optionsDefinition != null) {
        final options = plan.optionsDefinition!;
        debugPrint('   Plan options: {');
        options.forEach((key, value) {
          if (key.toLowerCase().contains('capacity') ||
              key.toLowerCase().contains('participant') ||
              key.toLowerCase().contains('max')) {
            debugPrint('     $key: $value');
          }
        });
        debugPrint('   }');
      }
    }

    // Provider capacity info
    debugPrint('   Provider capacity fields:');
    debugPrint('     totalCapacity: ${provider.totalCapacity}');
    debugPrint('     maxCapacity: ${provider.maxCapacity}');
    debugPrint('     maxGroupSize: ${provider.maxGroupSize}');
    debugPrint('     minGroupSize: ${provider.minGroupSize}');
  }
}

/// Enhanced time slot capacity model with real-time data
class TimeSlotCapacity {
  final String time;
  final DateTime date;
  final int totalCapacity;
  final int bookedCapacity;
  final int availableSpots;
  final List<String> bookedByUsers;
  final List<ReservationSummary> conflictingReservations;
  final double capacityPercentage;
  final bool isAvailable;
  final bool isFull;
  final bool isAlmostFull;
  final String capacityStatus;
  final DateTime lastUpdated;

  TimeSlotCapacity({
    required this.time,
    required this.date,
    required this.totalCapacity,
    required this.bookedCapacity,
    required this.availableSpots,
    required this.bookedByUsers,
    required this.conflictingReservations,
    this.capacityPercentage = 0.0,
    this.isAvailable = true,
    this.isFull = false,
    this.isAlmostFull = false,
    this.capacityStatus = 'Available',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Backward compatibility properties
  String get timeSlot => time;
  int get availableCapacity => availableSpots;
  List<ReservationSummary> get existingReservations => conflictingReservations;

  /// Capacity utilization percentage (0.0 to 1.0)
  double get utilizationRate => capacityPercentage;

  /// Capacity status for UI display
  CapacityStatus get status {
    if (isFull) return CapacityStatus.full;
    if (isAlmostFull) return CapacityStatus.almostFull;
    if (capacityPercentage >= 0.5) return CapacityStatus.halfFull;
    return CapacityStatus.available;
  }

  /// Create from Firebase document
  factory TimeSlotCapacity.fromFirestore(Map<String, dynamic> data) {
    return TimeSlotCapacity(
      time: data['time'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCapacity: data['totalCapacity'] ?? 0,
      bookedCapacity: data['bookedCapacity'] ?? 0,
      availableSpots: data['availableSpots'] ?? data['availableCapacity'] ?? 0,
      bookedByUsers: List<String>.from(data['bookedByUsers'] ?? []),
      conflictingReservations: (data['conflictingReservations'] as List?)
              ?.map((item) => ReservationSummary.fromMap(item))
              .toList() ??
          (data['existingReservations'] as List?)
              ?.map((item) => ReservationSummary.fromMap(item))
              .toList() ??
          [],
      capacityPercentage: (data['capacityPercentage'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      isFull: data['isFull'] ?? false,
      isAlmostFull: data['isAlmostFull'] ?? false,
      capacityStatus: data['capacityStatus'] ?? 'Available',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'timeSlot': time, // Backward compatibility
      'date': Timestamp.fromDate(date),
      'totalCapacity': totalCapacity,
      'bookedCapacity': bookedCapacity,
      'availableSpots': availableSpots,
      'availableCapacity': availableSpots, // Backward compatibility
      'bookedByUsers': bookedByUsers,
      'conflictingReservations':
          conflictingReservations.map((r) => r.toMap()).toList(),
      'existingReservations': conflictingReservations
          .map((r) => r.toMap())
          .toList(), // Backward compatibility
      'capacityPercentage': capacityPercentage,
      'isAvailable': isAvailable,
      'isFull': isFull,
      'isAlmostFull': isAlmostFull,
      'capacityStatus': capacityStatus,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Reservation summary for capacity calculations
class ReservationSummary {
  final String id;
  final String userId;
  final String userName;
  final DateTime startTime;
  final int duration;
  final int attendeeCount;
  final String status;

  ReservationSummary({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.duration,
    required this.attendeeCount,
    required this.status,
  });

  // Backward compatibility property
  DateTime get reservationTime => startTime;

  factory ReservationSummary.fromReservation(ReservationModel reservation) {
    return ReservationSummary(
      id: reservation.id,
      userId: reservation.userId,
      userName: reservation.userName,
      startTime: reservation.reservationStartTime?.toDate() ?? DateTime.now(),
      duration: reservation.durationMinutes ?? 60,
      attendeeCount: reservation.attendees?.length ?? 1,
      status: reservation.status.toString(),
    );
  }

  factory ReservationSummary.fromMap(Map<String, dynamic> data) {
    return ReservationSummary(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ??
          (data['reservationTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      duration: data['duration'] ?? 60,
      attendeeCount: data['attendeeCount'] ?? 1,
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'startTime': Timestamp.fromDate(startTime),
      'reservationTime':
          Timestamp.fromDate(startTime), // Backward compatibility
      'duration': duration,
      'attendeeCount': attendeeCount,
      'status': status,
    };
  }
}

/// Capacity status for UI representation
enum CapacityStatus {
  available,
  halfFull,
  almostFull,
  full,
}

extension CapacityStatusExtension on CapacityStatus {
  String get displayText {
    switch (this) {
      case CapacityStatus.available:
        return 'Available';
      case CapacityStatus.halfFull:
        return 'Half Full';
      case CapacityStatus.almostFull:
        return 'Almost Full';
      case CapacityStatus.full:
        return 'Full';
    }
  }

  Color get color {
    switch (this) {
      case CapacityStatus.available:
        return const Color(0xFF4CAF50); // Green
      case CapacityStatus.halfFull:
        return const Color(0xFFFF9800); // Orange
      case CapacityStatus.almostFull:
        return const Color(0xFFFF5722); // Red-orange
      case CapacityStatus.full:
        return const Color(0xFFF44336); // Red
    }
  }
}
