// lib/feature/social/bloc/social_state.dart
part of 'social_bloc.dart';

enum FriendshipStatus { none, friends, requestSent, requestReceived }

abstract class SocialState extends Equatable {
  const SocialState();
  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {}

class SocialLoading extends SocialState {
  final bool isLoadingList;
  final String? processingUserId;

  const SocialLoading({this.isLoadingList = false, this.processingUserId});

  @override
  List<Object?> get props => [isLoadingList, processingUserId];
}

class FamilyRequest extends Equatable {
  final String userId;
  final String name;
  final String? profilePicUrl;
  final String relationship;
  final Timestamp requestedAt;

  const FamilyRequest(
      {required this.userId,
      required this.name,
      this.profilePicUrl,
      required this.relationship,
      required this.requestedAt});

  factory FamilyRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FamilyRequest(
      userId: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      profilePicUrl: data['profilePicUrl'] as String?,
      relationship: data['relationship'] as String? ?? 'Relative',
      requestedAt: data['addedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
  @override
  List<Object?> get props =>
      [userId, name, profilePicUrl, relationship, requestedAt];
}

class FamilyDataLoaded extends SocialState {
  final List<FamilyMember> familyMembers;
  final List<FamilyRequest> incomingRequests;

  const FamilyDataLoaded({
    required this.familyMembers,
    required this.incomingRequests,
  });

  @override
  List<Object?> get props => [familyMembers, incomingRequests];
}

class Friend extends Equatable {
  final String userId;
  final String name;
  final String? profilePicUrl;
  final Timestamp? friendedAt;

  const Friend(
      {required this.userId,
      required this.name,
      this.profilePicUrl,
      this.friendedAt});

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Friend(
      userId: doc.id,
      name: data['displayName'] as String? ??
          data['name'] as String? ??
          'Unknown Friend',
      profilePicUrl: data['profilePicUrl'] as String?,
      friendedAt: data['friendedAt'] as Timestamp?,
    );
  }
  @override
  List<Object?> get props => [userId, name, profilePicUrl, friendedAt];
}

class FriendRequest extends Equatable {
  final String userId;
  final String name;
  final String? profilePicUrl;
  final String status; // 'pending_sent' or 'pending_received'
  final Timestamp? requestedAt;

  const FriendRequest({
    required this.userId,
    required this.name,
    this.profilePicUrl,
    required this.status,
    this.requestedAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequest(
      userId: doc.id,
      name: data['displayName'] as String? ??
          data['name'] as String? ??
          'Unknown User',
      profilePicUrl: data['profilePicUrl'] as String?,
      status: data['status'] as String? ?? 'unknown',
      requestedAt:
          data['requestedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?,
    );
  }
  @override
  List<Object?> get props => [userId, name, profilePicUrl, status, requestedAt];
}

class FriendsAndRequestsLoaded extends SocialState {
  final List<Friend> friends;
  final List<FriendRequest> incomingRequests;
  final List<FriendRequest> outgoingRequests;

  const FriendsAndRequestsLoaded({
    required this.friends,
    required this.incomingRequests,
    required this.outgoingRequests,
  });

  @override
  List<Object?> get props => [friends, incomingRequests, outgoingRequests];
}

class UserSearchResultWithStatus extends Equatable {
  final AuthModel user;
  final FriendshipStatus status;

  const UserSearchResultWithStatus({required this.user, required this.status});
  @override
  List<Object?> get props => [user, status];
}

// State for friend search results
class FriendSearchResultsLoaded extends SocialState {
  final List<UserSearchResultWithStatus> results;
  final String query;

  const FriendSearchResultsLoaded({required this.results, required this.query});
  @override
  List<Object?> get props => [results, query];
}

// State for national ID search result (for family linking)
class UserNationalIdSearchResult extends SocialState {
  final AuthModel? foundUser;
  final String searchedNationalId; // Store the ID that was searched

  const UserNationalIdSearchResult(
      {this.foundUser, required this.searchedNationalId});
  @override
  List<Object?> get props => [foundUser, searchedNationalId];
}

class SocialSuccess extends SocialState {
  final String message;
  const SocialSuccess({this.message = "Operation successful."});
  @override
  List<Object?> get props => [message];
}

class SocialError extends SocialState {
  final String message;
  const SocialError({required this.message});
  @override
  List<Object?> get props => [message];
}

// --- Suggestion States ---
class SuggestionsLoaded extends SocialState {
  final SuggestionBatch batch;
  final SuggestionContext context;

  const SuggestionsLoaded({
    required this.batch,
    required this.context,
  });

  @override
  List<Object?> get props => [batch, context];
}

class SuggestionsLoading extends SocialState {
  final SuggestionContext context;

  const SuggestionsLoading({required this.context});

  @override
  List<Object?> get props => [context];
}

class SuggestionsError extends SocialState {
  final String message;
  final SuggestionContext context;

  const SuggestionsError({
    required this.message,
    required this.context,
  });

  @override
  List<Object?> get props => [message, context];
}

class SuggestionInteractionProcessed extends SocialState {
  final String suggestionId;
  final SuggestionInteractionType interactionType;
  final String message;

  const SuggestionInteractionProcessed({
    required this.suggestionId,
    required this.interactionType,
    required this.message,
  });

  @override
  List<Object?> get props => [suggestionId, interactionType, message];
}
