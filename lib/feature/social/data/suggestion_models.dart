import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';

/// Enum for different types of suggestions
enum SuggestionType {
  nearby, // Based on proximity/location
  governorate, // Same governorate/region
  mutualFriends, // Friends of friends
  similarInterests, // Common activities/preferences
  newToApp, // Recently joined users
  trending, // Popular/active users
  familyNetwork, // Extended family connections
  workBased, // Same profession/workplace
  ageBased, // Similar age group
  mixed, // Combination of multiple factors
}

/// Enum for suggestion context - where the suggestion appears
enum SuggestionContext {
  homeQuickAccess, // Home screen quick access cards
  socialHub, // Main social suggestions screen
  friendsList, // Within friends management
  familyNetwork, // Family connections screen
  profileView, // When viewing someone's profile
  onboarding, // New user suggestions
  notification, // Push notification suggestions
}

/// Core suggestion model with advanced scoring
class UserSuggestion extends Equatable {
  final String suggestionId;
  final AuthModel suggestedUser;
  final SuggestionType type;
  final SuggestionContext context;
  final double confidenceScore; // 0.0 to 1.0
  final Map<String, dynamic> metadata; // Additional context data
  final List<SuggestionReason> reasons;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final bool isPromoted; // For sponsored/featured suggestions
  final int priority; // Higher number = higher priority

  const UserSuggestion({
    required this.suggestionId,
    required this.suggestedUser,
    required this.type,
    required this.context,
    required this.confidenceScore,
    this.metadata = const {},
    required this.reasons,
    required this.generatedAt,
    this.expiresAt,
    this.isPromoted = false,
    this.priority = 0,
  });

  /// Creates a suggestion from Firestore document
  factory UserSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserSuggestion(
      suggestionId: doc.id,
      suggestedUser: AuthModel.fromFirestore(doc), // This would need adjustment
      type: SuggestionType.values.firstWhere(
        (type) => type.toString().split('.').last == data['type'],
        orElse: () => SuggestionType.mixed,
      ),
      context: SuggestionContext.values.firstWhere(
        (context) => context.toString().split('.').last == data['context'],
        orElse: () => SuggestionContext.socialHub,
      ),
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      reasons: (data['reasons'] as List<dynamic>?)
              ?.map((r) => SuggestionReason.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt:
          (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isPromoted: data['isPromoted'] as bool? ?? false,
      priority: data['priority'] as int? ?? 0,
    );
  }

  /// Converts to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'suggestedUserId': suggestedUser.uid,
      'type': type.toString().split('.').last,
      'context': context.toString().split('.').last,
      'confidenceScore': confidenceScore,
      'metadata': metadata,
      'reasons': reasons.map((r) => r.toMap()).toList(),
      'generatedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isPromoted': isPromoted,
      'priority': priority,
    };
  }

  /// Gets user-friendly title for the suggestion
  String get title {
    switch (type) {
      case SuggestionType.nearby:
        return 'People Near You';
      case SuggestionType.governorate:
        return 'From Your Area';
      case SuggestionType.mutualFriends:
        return 'Friends of Friends';
      case SuggestionType.similarInterests:
        return 'Similar Interests';
      case SuggestionType.newToApp:
        return 'New to Shamil';
      case SuggestionType.trending:
        return 'Trending Users';
      case SuggestionType.familyNetwork:
        return 'Extended Network';
      case SuggestionType.workBased:
        return 'Professional Network';
      case SuggestionType.ageBased:
        return 'Similar Age Group';
      case SuggestionType.mixed:
        return 'Recommended for You';
    }
  }

  /// Gets the primary reason text
  String get primaryReasonText {
    if (reasons.isEmpty) return 'Suggested for you';
    return reasons.first.displayText;
  }

  /// Checks if suggestion is still valid
  bool get isValid {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    return confidenceScore > 0.1; // Minimum confidence threshold
  }

  @override
  List<Object?> get props => [
        suggestionId,
        suggestedUser,
        type,
        context,
        confidenceScore,
        metadata,
        reasons,
        generatedAt,
        expiresAt,
        isPromoted,
        priority,
      ];
}

/// Represents a reason why a user is being suggested
class SuggestionReason extends Equatable {
  final String type; // 'location', 'mutual_friends', 'interests', etc.
  final String displayText; // User-friendly explanation
  final double weight; // Importance of this reason (0.0 to 1.0)
  final Map<String, dynamic> data; // Additional context

  const SuggestionReason({
    required this.type,
    required this.displayText,
    required this.weight,
    this.data = const {},
  });

  factory SuggestionReason.fromMap(Map<String, dynamic> map) {
    return SuggestionReason(
      type: map['type'] as String,
      displayText: map['displayText'] as String,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'displayText': displayText,
      'weight': weight,
      'data': data,
    };
  }

  @override
  List<Object?> get props => [type, displayText, weight, data];
}

/// Suggestion batch for efficient loading
class SuggestionBatch extends Equatable {
  final String batchId;
  final SuggestionType type;
  final SuggestionContext context;
  final List<UserSuggestion> suggestions;
  final DateTime generatedAt;
  final bool hasMorePages;
  final String? nextPageToken;
  final Map<String, dynamic> metadata;

  const SuggestionBatch({
    required this.batchId,
    required this.type,
    required this.context,
    required this.suggestions,
    required this.generatedAt,
    this.hasMorePages = false,
    this.nextPageToken,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        batchId,
        type,
        context,
        suggestions,
        generatedAt,
        hasMorePages,
        nextPageToken,
        metadata,
      ];
}

/// Suggestion configuration for different contexts
class SuggestionConfig extends Equatable {
  final SuggestionContext context;
  final List<SuggestionType> enabledTypes;
  final int maxSuggestions;
  final double minConfidenceScore;
  final Duration cacheDuration;
  final bool allowPromoted;
  final Map<SuggestionType, double> typeWeights;

  const SuggestionConfig({
    required this.context,
    required this.enabledTypes,
    this.maxSuggestions = 10,
    this.minConfidenceScore = 0.1,
    this.cacheDuration = const Duration(hours: 4),
    this.allowPromoted = true,
    this.typeWeights = const {},
  });

  /// Default config for home screen quick access
  static const homeQuickAccess = SuggestionConfig(
    context: SuggestionContext.homeQuickAccess,
    enabledTypes: [
      SuggestionType.nearby,
      SuggestionType.mutualFriends,
      SuggestionType.trending,
    ],
    maxSuggestions: 5,
    minConfidenceScore: 0.3,
    cacheDuration: Duration(hours: 2),
  );

  /// Default config for main social hub
  static const socialHub = SuggestionConfig(
    context: SuggestionContext.socialHub,
    enabledTypes: SuggestionType.values,
    maxSuggestions: 20,
    minConfidenceScore: 0.1,
    cacheDuration: Duration(hours: 6),
  );

  @override
  List<Object?> get props => [
        context,
        enabledTypes,
        maxSuggestions,
        minConfidenceScore,
        cacheDuration,
        allowPromoted,
        typeWeights,
      ];
}

/// User interaction with suggestions for machine learning
class SuggestionInteraction extends Equatable {
  final String interactionId;
  final String suggestionId;
  final String userId;
  final String suggestedUserId;
  final SuggestionInteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SuggestionInteraction({
    required this.interactionId,
    required this.suggestionId,
    required this.userId,
    required this.suggestedUserId,
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });

  factory SuggestionInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SuggestionInteraction(
      interactionId: doc.id,
      suggestionId: data['suggestionId'] as String,
      userId: data['userId'] as String,
      suggestedUserId: data['suggestedUserId'] as String,
      type: SuggestionInteractionType.values.firstWhere(
        (type) => type.toString().split('.').last == data['type'],
        orElse: () => SuggestionInteractionType.viewed,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suggestionId': suggestionId,
      'userId': userId,
      'suggestedUserId': suggestedUserId,
      'type': type.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        interactionId,
        suggestionId,
        userId,
        suggestedUserId,
        type,
        timestamp,
        metadata,
      ];
}

/// Types of interactions users can have with suggestions
enum SuggestionInteractionType {
  viewed, // User saw the suggestion
  tapped, // User tapped/clicked on suggestion
  dismissed, // User dismissed/ignored suggestion
  connected, // User sent friend request or connected
  blocked, // User blocked the suggested person
  shared, // User shared the suggestion
  saved, // User saved for later
  reported, // User reported inappropriate suggestion
}
