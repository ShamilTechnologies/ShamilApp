import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shamil_mobile_app/core/constants/app_constants.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart'
    as profile_models;
import 'package:shamil_mobile_app/feature/social/data/suggestion_models.dart';

/// Sophisticated suggestion engine implementing high-end app techniques
class SuggestionEngine {
  static final SuggestionEngine _instance = SuggestionEngine._internal();
  factory SuggestionEngine() => _instance;
  SuggestionEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Caching
  final Map<String, SuggestionBatch> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Algorithm weights (configurable)
  static const double proximityWeight = 0.25;
  static const double governorateWeight = 0.20;
  static const double mutualFriendsWeight = 0.30;
  static const double interestsWeight = 0.15;
  static const double activityWeight = 0.10;

  /// Main entry point for generating suggestions
  Future<SuggestionBatch> generateSuggestions(SuggestionConfig config) async {
    print('🎯 SuggestionEngine: Generating suggestions for ${config.context}');

    final cacheKey = _buildCacheKey(config);

    // Check cache first
    if (_isCacheValid(cacheKey, config.cacheDuration)) {
      print('📋 Returning cached suggestions');
      return _cache[cacheKey]!;
    }

    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Generate suggestions using multiple algorithms
      final suggestions = await _generateMixedSuggestions(currentUser, config);

      // Score and rank suggestions
      final scoredSuggestions =
          await _scoreAndRankSuggestions(suggestions, currentUser, config);

      // Create batch
      final batch = SuggestionBatch(
        batchId: _generateBatchId(),
        type: SuggestionType.mixed,
        context: config.context,
        suggestions: scoredSuggestions,
        generatedAt: DateTime.now(),
        hasMorePages: scoredSuggestions.length >= config.maxSuggestions,
        metadata: {
          'algorithm_version': '2.1',
          'total_candidates': suggestions.length,
          'filtered_count': scoredSuggestions.length,
        },
      );

      // Cache the result
      _cache[cacheKey] = batch;
      _cacheTimestamps[cacheKey] = DateTime.now();

      print('✅ Generated ${batch.suggestions.length} suggestions');
      return batch;
    } catch (e) {
      print('❌ Error generating suggestions: $e');
      rethrow;
    }
  }

  /// Generate location-based suggestions (nearby users)
  Future<List<UserSuggestion>> generateNearbyUsers(AuthModel currentUser,
      {double radiusKm = 25.0, int limit = 10}) async {
    print('📍 Generating nearby user suggestions');

    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        print('⚠️ Location not available, falling back to governorate');
        return generateGovernorateUsers(currentUser, limit: limit);
      }

      // Query users within radius using Firestore geoqueries
      // Note: This requires a geohash field in user documents
      final nearbyUsers = await _queryNearbyUsers(
        position.latitude,
        position.longitude,
        radiusKm,
        limit: limit * 3, // Get more for filtering
      );

      final suggestions = <UserSuggestion>[];

      for (final user in nearbyUsers) {
        if (user.uid == currentUser.uid) continue;
        if (await _isAlreadyConnected(currentUser.uid, user.uid)) continue;

        // Note: AuthModel doesn't have lat/lng, using governorate fallback
        final distance = 10.0; // Default distance for same-governorate users

        final suggestion = UserSuggestion(
          suggestionId: _generateSuggestionId(),
          suggestedUser: user,
          type: SuggestionType.nearby,
          context: SuggestionContext.socialHub,
          confidenceScore: _calculateProximityScore(distance),
          reasons: [
            SuggestionReason(
              type: 'proximity',
              displayText: '${distance.toStringAsFixed(1)} km away',
              weight: 1.0,
              data: {'distance_km': distance},
            ),
          ],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
        );

        suggestions.add(suggestion);
      }

      print('📍 Found ${suggestions.length} nearby users');
      return suggestions;
    } catch (e) {
      print('❌ Error generating nearby suggestions: $e');
      return [];
    }
  }

  /// Generate governorate-based suggestions
  Future<List<UserSuggestion>> generateGovernorateUsers(AuthModel currentUser,
      {int limit = 15}) async {
    print('🏛️ Generating governorate-based suggestions');

    try {
      // Extract governorate from user profile or location
      final userGovernorate = await _getUserGovernorate(currentUser);
      if (userGovernorate == null) {
        print('⚠️ No governorate available for user');
        return [];
      }

      // Query users from same governorate
      final query = _firestore
          .collection('endUsers')
          .where('governorate', isEqualTo: userGovernorate)
          .where('isBlocked', isEqualTo: false)
          .limit(limit * 2);

      final snapshot = await query.get();
      final suggestions = <UserSuggestion>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;
        if (await _isAlreadyConnected(currentUser.uid, doc.id)) continue;

        final user = AuthModel.fromFirestore(doc);

        final suggestion = UserSuggestion(
          suggestionId: _generateSuggestionId(),
          suggestedUser: user,
          type: SuggestionType.governorate,
          context: SuggestionContext.socialHub,
          confidenceScore: _calculateGovernorateScore(currentUser, user),
          reasons: [
            SuggestionReason(
              type: 'location',
              displayText: 'From $userGovernorate',
              weight: 0.8,
              data: {'governorate': userGovernorate},
            ),
          ],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );

        suggestions.add(suggestion);
      }

      print('🏛️ Found ${suggestions.length} users from $userGovernorate');
      return suggestions;
    } catch (e) {
      print('❌ Error generating governorate suggestions: $e');
      return [];
    }
  }

  /// Generate mutual friends suggestions (friends of friends)
  Future<List<UserSuggestion>> generateMutualFriendsSuggestions(
      AuthModel currentUser,
      {int limit = 10}) async {
    print('👥 Generating mutual friends suggestions');

    try {
      // Get current user's friends
      final userFriends = await _getUserFriends(currentUser.uid);
      if (userFriends.isEmpty) {
        print('⚠️ User has no friends yet');
        return [];
      }

      final mutualConnections = <String, MutualConnectionData>{};

      // For each friend, get their friends
      for (final friendId in userFriends) {
        final friendsFriends = await _getUserFriends(friendId);

        for (final friendOfFriendId in friendsFriends) {
          if (friendOfFriendId == currentUser.uid) continue;
          if (userFriends.contains(friendOfFriendId)) continue;

          if (mutualConnections.containsKey(friendOfFriendId)) {
            mutualConnections[friendOfFriendId]!.count++;
            mutualConnections[friendOfFriendId]!.mutualFriends.add(friendId);
          } else {
            mutualConnections[friendOfFriendId] = MutualConnectionData(
              count: 1,
              mutualFriends: {friendId},
            );
          }
        }
      }

      // Convert to suggestions
      final suggestions = <UserSuggestion>[];

      for (final entry in mutualConnections.entries) {
        final userId = entry.key;
        final connectionData = entry.value;

        try {
          final userDoc =
              await _firestore.collection('endUsers').doc(userId).get();
          if (!userDoc.exists) continue;

          final user = AuthModel.fromFirestore(userDoc);

          final suggestion = UserSuggestion(
            suggestionId: _generateSuggestionId(),
            suggestedUser: user,
            type: SuggestionType.mutualFriends,
            context: SuggestionContext.socialHub,
            confidenceScore: _calculateMutualFriendsScore(
                connectionData.count, userFriends.length),
            reasons: [
              SuggestionReason(
                type: 'mutual_friends',
                displayText:
                    '${connectionData.count} mutual friend${connectionData.count > 1 ? 's' : ''}',
                weight: 1.0,
                data: {
                  'mutual_count': connectionData.count,
                  'mutual_friends': connectionData.mutualFriends.toList(),
                },
              ),
            ],
            generatedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 8)),
            priority:
                connectionData.count, // Higher mutual friends = higher priority
          );

          suggestions.add(suggestion);
        } catch (e) {
          print('⚠️ Error fetching user $userId: $e');
          continue;
        }
      }

      // Sort by mutual friends count
      suggestions.sort((a, b) => b.priority.compareTo(a.priority));

      print('👥 Found ${suggestions.length} mutual friends suggestions');
      return suggestions.take(limit).toList();
    } catch (e) {
      print('❌ Error generating mutual friends suggestions: $e');
      return [];
    }
  }

  /// Generate trending/popular users suggestions
  Future<List<UserSuggestion>> generateTrendingUsers(AuthModel currentUser,
      {int limit = 8}) async {
    print('📈 Generating trending user suggestions');

    try {
      // Query users with high activity/engagement scores
      // This could be based on recent activity, friend requests, profile views, etc.
      final query = _firestore
          .collection('endUsers')
          .where('isBlocked', isEqualTo: false)
          .orderBy('lastSeen', descending: true)
          .limit(limit * 3);

      final snapshot = await query.get();
      final suggestions = <UserSuggestion>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;
        if (await _isAlreadyConnected(currentUser.uid, doc.id)) continue;

        final user = AuthModel.fromFirestore(doc);

        // Calculate trending score based on recent activity
        final trendingScore = _calculateTrendingScore(user);
        if (trendingScore < 0.3) continue; // Threshold for trending

        final suggestion = UserSuggestion(
          suggestionId: _generateSuggestionId(),
          suggestedUser: user,
          type: SuggestionType.trending,
          context: SuggestionContext.socialHub,
          confidenceScore: trendingScore,
          reasons: [
            SuggestionReason(
              type: 'trending',
              displayText: 'Active user',
              weight: 0.7,
              data: {'trending_score': trendingScore},
            ),
          ],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
          isPromoted: trendingScore > 0.8, // Promote highly trending users
        );

        suggestions.add(suggestion);
      }

      print('📈 Found ${suggestions.length} trending users');
      return suggestions.take(limit).toList();
    } catch (e) {
      print('❌ Error generating trending suggestions: $e');
      return [];
    }
  }

  /// Generate new users suggestions
  Future<List<UserSuggestion>> generateNewUsers(AuthModel currentUser,
      {int limit = 5}) async {
    print('✨ Generating new user suggestions');

    try {
      // Get users who joined recently (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final query = _firestore
          .collection('endUsers')
          .where('isBlocked', isEqualTo: false)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('createdAt', descending: true)
          .limit(limit * 2);

      final snapshot = await query.get();
      final suggestions = <UserSuggestion>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;
        if (await _isAlreadyConnected(currentUser.uid, doc.id)) continue;

        final user = AuthModel.fromFirestore(doc);

        final suggestion = UserSuggestion(
          suggestionId: _generateSuggestionId(),
          suggestedUser: user,
          type: SuggestionType.newToApp,
          context: SuggestionContext.socialHub,
          confidenceScore: 0.6, // Moderate confidence for new users
          reasons: [
            SuggestionReason(
              type: 'new_user',
              displayText: 'New to Shamil',
              weight: 0.6,
              data: {
                'joined_days_ago':
                    DateTime.now().difference(user.createdAt.toDate()).inDays
              },
            ),
          ],
          generatedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        suggestions.add(suggestion);
      }

      print('✨ Found ${suggestions.length} new users');
      return suggestions.take(limit).toList();
    } catch (e) {
      print('❌ Error generating new user suggestions: $e');
      return [];
    }
  }

  // MARK: - Private Helper Methods

  /// Generate mixed suggestions using multiple algorithms
  Future<List<UserSuggestion>> _generateMixedSuggestions(
    AuthModel currentUser,
    SuggestionConfig config,
  ) async {
    final allSuggestions = <UserSuggestion>[];

    // Generate from each enabled type
    for (final type in config.enabledTypes) {
      List<UserSuggestion> typeSuggestions = [];

      switch (type) {
        case SuggestionType.nearby:
          typeSuggestions = await generateNearbyUsers(currentUser);
          break;
        case SuggestionType.governorate:
          typeSuggestions = await generateGovernorateUsers(currentUser);
          break;
        case SuggestionType.mutualFriends:
          typeSuggestions = await generateMutualFriendsSuggestions(currentUser);
          break;
        case SuggestionType.trending:
          typeSuggestions = await generateTrendingUsers(currentUser);
          break;
        case SuggestionType.newToApp:
          typeSuggestions = await generateNewUsers(currentUser);
          break;
        default:
          // Additional types can be implemented as needed
          break;
      }

      allSuggestions.addAll(typeSuggestions);
    }

    return allSuggestions;
  }

  /// Score and rank suggestions using ML-style algorithms
  Future<List<UserSuggestion>> _scoreAndRankSuggestions(
    List<UserSuggestion> suggestions,
    AuthModel currentUser,
    SuggestionConfig config,
  ) async {
    print('🔢 Scoring and ranking ${suggestions.length} suggestions');

    final scoredSuggestions = <UserSuggestion>[];

    for (final suggestion in suggestions) {
      // Calculate composite score
      final compositeScore = await _calculateCompositeScore(
        suggestion,
        currentUser,
        config,
      );

      // Only include if meets minimum confidence
      if (compositeScore >= config.minConfidenceScore) {
        // Create new suggestion with updated score
        final updatedSuggestion = UserSuggestion(
          suggestionId: suggestion.suggestionId,
          suggestedUser: suggestion.suggestedUser,
          type: suggestion.type,
          context: suggestion.context,
          confidenceScore: compositeScore,
          metadata: {
            ...suggestion.metadata,
            'composite_score': compositeScore,
            'original_score': suggestion.confidenceScore,
          },
          reasons: suggestion.reasons,
          generatedAt: suggestion.generatedAt,
          expiresAt: suggestion.expiresAt,
          isPromoted: suggestion.isPromoted,
          priority: suggestion.priority,
        );

        scoredSuggestions.add(updatedSuggestion);
      }
    }

    // Sort by composite score and priority
    scoredSuggestions.sort((a, b) {
      // Promoted suggestions first
      if (a.isPromoted && !b.isPromoted) return -1;
      if (!a.isPromoted && b.isPromoted) return 1;

      // Then by composite score
      final scoreComparison = b.confidenceScore.compareTo(a.confidenceScore);
      if (scoreComparison != 0) return scoreComparison;

      // Finally by priority
      return b.priority.compareTo(a.priority);
    });

    // Apply diversity filtering to avoid showing too many of the same type
    final diversifiedSuggestions = _applyDiversityFiltering(
      scoredSuggestions,
      config.maxSuggestions,
    );

    print('🔢 Final score: ${diversifiedSuggestions.length} suggestions');
    return diversifiedSuggestions;
  }

  /// Calculate composite score using multiple factors
  Future<double> _calculateCompositeScore(
    UserSuggestion suggestion,
    AuthModel currentUser,
    SuggestionConfig config,
  ) async {
    double score = suggestion.confidenceScore;

    // Apply type-specific weights
    final typeWeight = config.typeWeights[suggestion.type] ?? 1.0;
    score *= typeWeight;

    // Consider user interaction history (if available)
    final interactionBoost = await _calculateInteractionBoost(
      suggestion.suggestedUser.uid,
      currentUser.uid,
    );
    score += interactionBoost;

    // Consider profile completeness
    final completenessBoost =
        _calculateProfileCompletenessBoost(suggestion.suggestedUser);
    score += completenessBoost;

    // Consider recency of activity
    final activityBoost = _calculateActivityBoost(suggestion.suggestedUser);
    score += activityBoost;

    // Normalize to 0-1 range
    return math.min(1.0, math.max(0.0, score));
  }

  /// Apply diversity filtering to ensure variety in suggestions
  List<UserSuggestion> _applyDiversityFiltering(
    List<UserSuggestion> suggestions,
    int maxSuggestions,
  ) {
    final diversified = <UserSuggestion>[];
    final typeCount = <SuggestionType, int>{};

    for (final suggestion in suggestions) {
      if (diversified.length >= maxSuggestions) break;

      final currentTypeCount = typeCount[suggestion.type] ?? 0;
      final maxPerType = (maxSuggestions / SuggestionType.values.length).ceil();

      // Allow promoted suggestions regardless of type limit
      if (suggestion.isPromoted || currentTypeCount < maxPerType) {
        diversified.add(suggestion);
        typeCount[suggestion.type] = currentTypeCount + 1;
      }
    }

    return diversified;
  }

  // MARK: - Scoring Algorithms

  double _calculateProximityScore(double distanceKm) {
    // Closer = higher score
    if (distanceKm <= 1) return 1.0;
    if (distanceKm <= 5) return 0.9;
    if (distanceKm <= 15) return 0.7;
    if (distanceKm <= 25) return 0.5;
    return 0.3;
  }

  double _calculateGovernorateScore(
      AuthModel currentUser, AuthModel suggestedUser) {
    double score = 0.6; // Base score for same governorate

    // Boost if same city (commented out - AuthModel doesn't have city property)
    // if (currentUser.city != null && currentUser.city == suggestedUser.city) {
    //   score += 0.2;
    // }

    // Boost if similar age
    if (currentUser.dob != null && suggestedUser.dob != null) {
      final ageDiff =
          _calculateAgeDifference(currentUser.dob!, suggestedUser.dob!);
      if (ageDiff <= 5) score += 0.1;
    }

    return math.min(1.0, score);
  }

  double _calculateMutualFriendsScore(int mutualCount, int totalFriends) {
    if (totalFriends == 0) return 0.5;

    final ratio = mutualCount / totalFriends;

    // More mutual friends = higher score
    if (mutualCount >= 5) return 1.0;
    if (mutualCount >= 3) return 0.9;
    if (mutualCount >= 2) return 0.8;
    if (mutualCount >= 1) return 0.7;

    return 0.5;
  }

  double _calculateTrendingScore(AuthModel user) {
    double score = 0.0;

    // Recent activity boost
    if (user.lastSeen != null) {
      final hoursSinceActive =
          DateTime.now().difference(user.lastSeen!.toDate()).inHours;
      if (hoursSinceActive <= 1)
        score += 0.4;
      else if (hoursSinceActive <= 6)
        score += 0.3;
      else if (hoursSinceActive <= 24)
        score += 0.2;
      else if (hoursSinceActive <= 72) score += 0.1;
    }

    // Profile completeness boost
    score += _calculateProfileCompletenessBoost(user);

    // Recent join boost (if within last month)
    if (user.createdAt != null) {
      final daysSinceJoin =
          DateTime.now().difference(user.createdAt.toDate()).inDays;
      if (daysSinceJoin <= 7)
        score += 0.2;
      else if (daysSinceJoin <= 30) score += 0.1;
    }

    return math.min(1.0, score);
  }

  double _calculateProfileCompletenessBoost(AuthModel user) {
    double completeness = 0.0;

    if (user.name.isNotEmpty) completeness += 0.1;
    if (user.profilePicUrl?.isNotEmpty == true) completeness += 0.1;
    if (user.phone?.isNotEmpty == true) completeness += 0.05;
    if (user.gender?.isNotEmpty == true) completeness += 0.05;
    if (user.dob?.isNotEmpty == true) completeness += 0.05;

    return completeness;
  }

  double _calculateActivityBoost(AuthModel user) {
    if (user.lastSeen == null) return 0.0;

    final hoursSinceActive =
        DateTime.now().difference(user.lastSeen!.toDate()).inHours;

    if (hoursSinceActive <= 1) return 0.2;
    if (hoursSinceActive <= 6) return 0.15;
    if (hoursSinceActive <= 24) return 0.1;
    if (hoursSinceActive <= 72) return 0.05;

    return 0.0;
  }

  Future<double> _calculateInteractionBoost(
      String suggestedUserId, String currentUserId) async {
    // This would check past interactions, profile views, etc.
    // For now, return 0 - implement based on your interaction tracking
    return 0.0;
  }

  // MARK: - Utility Methods

  Future<AuthModel?> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('endUsers').doc(user.uid).get();
      if (!doc.exists) return null;

      return AuthModel.fromFirestore(doc);
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<List<AuthModel>> _queryNearbyUsers(
      double lat, double lon, double radiusKm,
      {int limit = 20}) async {
    // This requires implementing geohash or geospatial queries
    // For now, return users from same governorate as fallback
    // In production, you'd use libraries like geoflutterfire

    return [];
  }

  Future<String?> _getUserGovernorate(AuthModel user) async {
    // Try multiple sources for governorate info
    // Note: AuthModel doesn't have city property, using default fallback
    // if (user.city != null && kGovernorates.contains(user.city)) {
    //   return user.city;
    // }

    // Could also derive from location, profile, etc.
    return 'Cairo'; // Default fallback
  }

  Future<List<String>> _getUserFriends(String userId) async {
    try {
      final friendsSnapshot = await _firestore
          .collection('endUsers')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      return friendsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching user friends: $e');
      return [];
    }
  }

  Future<bool> _isAlreadyConnected(String userId1, String userId2) async {
    try {
      // Check if already friends
      final friendDoc = await _firestore
          .collection('endUsers')
          .doc(userId1)
          .collection('friends')
          .doc(userId2)
          .get();

      if (friendDoc.exists) return true;

      // Check if friend request exists
      final requestDoc = await _firestore
          .collection('endUsers')
          .doc(userId1)
          .collection('friendRequests')
          .doc(userId2)
          .get();

      return requestDoc.exists;
    } catch (e) {
      print('Error checking connection status: $e');
      return false;
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  int _calculateAgeDifference(String dob1, String dob2) {
    try {
      final date1 = DateTime.parse(dob1);
      final date2 = DateTime.parse(dob2);
      return (date1.difference(date2).inDays / 365).abs().round();
    } catch (e) {
      return 100; // Return large difference if parsing fails
    }
  }

  String _buildCacheKey(SuggestionConfig config) {
    return '${config.context.toString()}_${config.enabledTypes.length}_${config.maxSuggestions}';
  }

  bool _isCacheValid(String cacheKey, Duration maxAge) {
    if (!_cache.containsKey(cacheKey)) return false;

    final cacheTime = _cacheTimestamps[cacheKey];
    if (cacheTime == null) return false;

    return DateTime.now().difference(cacheTime) < maxAge;
  }

  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  String _generateSuggestionId() {
    return 'suggestion_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }
}

/// Helper class for tracking mutual connections
class MutualConnectionData {
  int count;
  Set<String> mutualFriends;

  MutualConnectionData({required this.count, required this.mutualFriends});
}
