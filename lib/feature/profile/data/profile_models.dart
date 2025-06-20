import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';

/// Comprehensive profile data model for rich user profiles
class UserProfile extends Equatable {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String? profilePicUrl;
  final String? bio;
  final String? location;
  final String? website;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isVerified;
  final bool isBlocked;
  final bool isPrivate;
  final bool isOnline;

  // Social stats
  final ProfileStats stats;
  final List<Achievement> achievements;
  final List<String> interests;
  final List<String> languages;

  // Professional info
  final String? jobTitle;
  final String? company;
  final String? education;

  // Social connections
  final FriendshipStatus? friendshipStatus; // Only when viewing other profiles
  final List<MutualFriend> mutualFriends;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    this.profilePicUrl,
    this.bio,
    this.location,
    this.website,
    this.phone,
    this.gender,
    this.dateOfBirth,
    required this.createdAt,
    this.lastSeen,
    this.isVerified = false,
    this.isBlocked = false,
    this.isPrivate = false,
    this.isOnline = false,
    required this.stats,
    this.achievements = const [],
    this.interests = const [],
    this.languages = const [],
    this.jobTitle,
    this.company,
    this.education,
    this.friendshipStatus,
    this.mutualFriends = const [],
  });

  factory UserProfile.fromAuthModel(
    AuthModel authModel, {
    ProfileStats? stats,
    List<Achievement>? achievements,
    FriendshipStatus? friendshipStatus,
    List<MutualFriend>? mutualFriends,
  }) {
    return UserProfile(
      uid: authModel.uid,
      name: authModel.name,
      username: authModel.username,
      email: authModel.email,
      profilePicUrl: authModel.profilePicUrl ?? authModel.image,
      phone: authModel.phone,
      gender: authModel.gender,
      dateOfBirth:
          authModel.dob != null ? DateTime.tryParse(authModel.dob!) : null,
      createdAt: authModel.createdAt.toDate(),
      lastSeen: authModel.lastSeen?.toDate(),
      isVerified: authModel.isVerified,
      isBlocked: authModel.isBlocked,
      stats: stats ?? ProfileStats.empty(),
      achievements: achievements ?? [],
      friendshipStatus: friendshipStatus,
      mutualFriends: mutualFriends ?? [],
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      profilePicUrl: data['profilePicUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      website: data['website'] as String?,
      phone: data['phone'] as String?,
      gender: data['gender'] as String?,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] as bool? ?? false,
      isBlocked: data['isBlocked'] as bool? ?? false,
      isPrivate: data['isPrivate'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      stats: ProfileStats.fromMap(data['stats'] as Map<String, dynamic>? ?? {}),
      achievements: (data['achievements'] as List<dynamic>? ?? [])
          .map((a) => Achievement.fromMap(a as Map<String, dynamic>))
          .toList(),
      interests: List<String>.from(data['interests'] as List<dynamic>? ?? []),
      languages: List<String>.from(data['languages'] as List<dynamic>? ?? []),
      jobTitle: data['jobTitle'] as String?,
      company: data['company'] as String?,
      education: data['education'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? profilePicUrl,
    String? bio,
    String? location,
    String? website,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isVerified,
    bool? isBlocked,
    bool? isPrivate,
    bool? isOnline,
    ProfileStats? stats,
    List<Achievement>? achievements,
    List<String>? interests,
    List<String>? languages,
    String? jobTitle,
    String? company,
    String? education,
    FriendshipStatus? friendshipStatus,
    List<MutualFriend>? mutualFriends,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isPrivate: isPrivate ?? this.isPrivate,
      isOnline: isOnline ?? this.isOnline,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      education: education ?? this.education,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      mutualFriends: mutualFriends ?? this.mutualFriends,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        username,
        email,
        profilePicUrl,
        bio,
        location,
        website,
        phone,
        gender,
        dateOfBirth,
        createdAt,
        lastSeen,
        isVerified,
        isBlocked,
        isPrivate,
        isOnline,
        stats,
        achievements,
        interests,
        languages,
        jobTitle,
        company,
        education,
        friendshipStatus,
        mutualFriends,
      ];
}

/// Profile statistics and engagement metrics
class ProfileStats extends Equatable {
  final int friendsCount;
  final int mutualFriendsCount;
  final int postsCount;
  final int reservationsCount;
  final int reviewsCount;
  final int achievementsCount;
  final double averageRating;
  final DateTime? lastActiveDate;
  final int profileViews;
  final String accountType; // 'basic', 'premium', 'business'

  const ProfileStats({
    this.friendsCount = 0,
    this.mutualFriendsCount = 0,
    this.postsCount = 0,
    this.reservationsCount = 0,
    this.reviewsCount = 0,
    this.achievementsCount = 0,
    this.averageRating = 0.0,
    this.lastActiveDate,
    this.profileViews = 0,
    this.accountType = 'basic',
  });

  factory ProfileStats.empty() => const ProfileStats();

  factory ProfileStats.fromMap(Map<String, dynamic> map) {
    return ProfileStats(
      friendsCount: map['friendsCount'] as int? ?? 0,
      mutualFriendsCount: map['mutualFriendsCount'] as int? ?? 0,
      postsCount: map['postsCount'] as int? ?? 0,
      reservationsCount: map['reservationsCount'] as int? ?? 0,
      reviewsCount: map['reviewsCount'] as int? ?? 0,
      achievementsCount: map['achievementsCount'] as int? ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      lastActiveDate: map['lastActiveDate'] != null
          ? (map['lastActiveDate'] as Timestamp).toDate()
          : null,
      profileViews: map['profileViews'] as int? ?? 0,
      accountType: map['accountType'] as String? ?? 'basic',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendsCount': friendsCount,
      'mutualFriendsCount': mutualFriendsCount,
      'postsCount': postsCount,
      'reservationsCount': reservationsCount,
      'reviewsCount': reviewsCount,
      'achievementsCount': achievementsCount,
      'averageRating': averageRating,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'profileViews': profileViews,
      'accountType': accountType,
    };
  }

  @override
  List<Object?> get props => [
        friendsCount,
        mutualFriendsCount,
        postsCount,
        reservationsCount,
        reviewsCount,
        achievementsCount,
        averageRating,
        lastActiveDate,
        profileViews,
        accountType,
      ];
}

/// User achievements and badges
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final String category; // 'social', 'reservations', 'reviews', 'special'
  final DateTime unlockedAt;
  final bool isRare;
  final String? progress; // For progress-based achievements

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.unlockedAt,
    this.isRare = false,
    this.progress,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconUrl: map['iconUrl'] as String,
      category: map['category'] as String,
      unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
      isRare: map['isRare'] as bool? ?? false,
      progress: map['progress'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'category': category,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'isRare': isRare,
      if (progress != null) 'progress': progress,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconUrl,
        category,
        unlockedAt,
        isRare,
        progress,
      ];
}

/// Mutual friends information
class MutualFriend extends Equatable {
  final String uid;
  final String name;
  final String? profilePicUrl;
  final String username;

  const MutualFriend({
    required this.uid,
    required this.name,
    this.profilePicUrl,
    required this.username,
  });

  factory MutualFriend.fromMap(Map<String, dynamic> map) {
    return MutualFriend(
      uid: map['uid'] as String,
      name: map['name'] as String,
      profilePicUrl: map['profilePicUrl'] as String?,
      username: map['username'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'profilePicUrl': profilePicUrl,
      'username': username,
    };
  }

  @override
  List<Object?> get props => [uid, name, profilePicUrl, username];
}

/// Friendship status between users
enum FriendshipStatus {
  none,
  requestSent,
  requestReceived,
  friends,
  blocked,
}

/// Profile view context for different use cases
enum ProfileViewContext {
  ownProfile,
  friendProfile,
  searchResult,
  suggestion,
  mutualFriend,
}
