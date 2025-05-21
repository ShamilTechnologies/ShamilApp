import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TournamentModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String organizerId;
  final String organizerName;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String governorateId;
  final String governorateName;
  final String gameType;
  final String tournamentType; // 'individual', 'team'
  final int participantsCount;
  final int maxParticipants;
  final List<String> participantIds;
  final double entryFee;
  final String currency;
  final String
      status; // 'registration', 'upcoming', 'ongoing', 'completed', 'cancelled'
  final List<TournamentPrize> prizes;
  final List<TournamentMatch> matches;
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.governorateId,
    required this.governorateName,
    required this.gameType,
    required this.tournamentType,
    required this.participantsCount,
    required this.maxParticipants,
    required this.participantIds,
    required this.entryFee,
    this.currency = 'EGP',
    required this.status,
    required this.prizes,
    required this.matches,
    required this.createdAt,
  });

  factory TournamentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      governorateId: data['governorateId'] ?? '',
      governorateName: data['governorateName'] ?? '',
      gameType: data['gameType'] ?? '',
      tournamentType: data['tournamentType'] ?? 'individual',
      participantsCount: data['participantsCount'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 0,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      entryFee: (data['entryFee'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'EGP',
      status: data['status'] ?? 'registration',
      prizes: (data['prizes'] as List<dynamic>?)
              ?.map((e) => TournamentPrize.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      matches: (data['matches'] as List<dynamic>?)
              ?.map((e) => TournamentMatch.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'governorateId': governorateId,
      'governorateName': governorateName,
      'gameType': gameType,
      'tournamentType': tournamentType,
      'participantsCount': participantsCount,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'entryFee': entryFee,
      'currency': currency,
      'status': status,
      'prizes': prizes.map((e) => e.toMap()).toList(),
      'matches': matches.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TournamentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? organizerId,
    String? organizerName,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? governorateId,
    String? governorateName,
    String? gameType,
    String? tournamentType,
    int? participantsCount,
    int? maxParticipants,
    List<String>? participantIds,
    double? entryFee,
    String? currency,
    String? status,
    List<TournamentPrize>? prizes,
    List<TournamentMatch>? matches,
    DateTime? createdAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      gameType: gameType ?? this.gameType,
      tournamentType: tournamentType ?? this.tournamentType,
      participantsCount: participantsCount ?? this.participantsCount,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantIds: participantIds ?? this.participantIds,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      prizes: prizes ?? this.prizes,
      matches: matches ?? this.matches,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        organizerId,
        organizerName,
        startDate,
        endDate,
        location,
        governorateId,
        governorateName,
        gameType,
        tournamentType,
        participantsCount,
        maxParticipants,
        participantIds,
        entryFee,
        currency,
        status,
        prizes,
        matches,
        createdAt,
      ];
}

class TournamentPrize extends Equatable {
  final int rank;
  final String title;
  final double amount;
  final String currency;
  final String description;

  const TournamentPrize({
    required this.rank,
    required this.title,
    required this.amount,
    this.currency = 'EGP',
    required this.description,
  });

  factory TournamentPrize.fromMap(Map<String, dynamic> map) {
    return TournamentPrize(
      rank: map['rank'] ?? 0,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? 'EGP',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'title': title,
      'amount': amount,
      'currency': currency,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [rank, title, amount, currency, description];
}

class TournamentMatch extends Equatable {
  final String id;
  final int round;
  final int matchNumber;
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;
  final DateTime? scheduledTime;
  final String status; // 'scheduled', 'ongoing', 'completed', 'cancelled'
  final String? winnerId;
  final String? score;
  final Map<String, dynamic>? matchDetails;

  const TournamentMatch({
    required this.id,
    required this.round,
    required this.matchNumber,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
    this.scheduledTime,
    required this.status,
    this.winnerId,
    this.score,
    this.matchDetails,
  });

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    return TournamentMatch(
      id: map['id'] ?? '',
      round: map['round'] ?? 0,
      matchNumber: map['matchNumber'] ?? 0,
      player1Id: map['player1Id'] ?? '',
      player1Name: map['player1Name'] ?? '',
      player2Id: map['player2Id'] ?? '',
      player2Name: map['player2Name'] ?? '',
      scheduledTime: map['scheduledTime'] != null
          ? (map['scheduledTime'] as Timestamp).toDate()
          : null,
      status: map['status'] ?? 'scheduled',
      winnerId: map['winnerId'],
      score: map['score'],
      matchDetails: map['matchDetails'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'round': round,
      'matchNumber': matchNumber,
      'player1Id': player1Id,
      'player1Name': player1Name,
      'player2Id': player2Id,
      'player2Name': player2Name,
      'scheduledTime':
          scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'status': status,
      'winnerId': winnerId,
      'score': score,
      'matchDetails': matchDetails,
    };
  }

  @override
  List<Object?> get props => [
        id,
        round,
        matchNumber,
        player1Id,
        player1Name,
        player2Id,
        player2Name,
        scheduledTime,
        status,
        winnerId,
        score,
        matchDetails,
      ];
}
