import '../utils/constants.dart';
import 'team.dart';
import 'match_result.dart';

/// Type of tournament: Solo, Duo, or Squad
enum TournamentType { solo, duo, squad }

/// Main tournament model holding all data.
class Tournament {
  final String id;
  String name;
  int totalMatches;
  int currentMatches;
  TournamentType type;
  DateTime creationDate;
  int totalTeamsOrPlayers;   // For solo: total players; for duo/squad: total teams
  List<Team> teams;
  List<MatchResult> matches;
  Map<String, Map<String, int>> standings; // teamId -> {posPts, kills, total}
  Map<int, int> rankPoints;   // rank -> points (customizable)
  int killPoint;               // points per kill (customizable)
  bool autoDeleteAfterMonth;   // If true, delete after 30 days

  Tournament({
    required this.id,
    required this.name,
    required this.totalMatches,
    this.currentMatches = 0,
    required this.type,
    required this.creationDate,
    required this.totalTeamsOrPlayers,
    this.teams = const [],
    this.matches = const [],
    this.standings = const {},
    this.rankPoints = AppConstants.defaultRankPoints,
    this.killPoint = AppConstants.defaultKillPoint,
    this.autoDeleteAfterMonth = false,
  });

  // ---------- JSON Serialization ----------
  factory Tournament.fromJson(Map<String, dynamic> json) {
    // Parse rankPoints (keys are strings in JSON)
    Map<int, int> rankPoints = {};
    if (json['rankPoints'] != null) {
      (json['rankPoints'] as Map).forEach((k, v) {
        rankPoints[int.parse(k.toString())] = v as int;
      });
    } else {
      rankPoints = AppConstants.defaultRankPoints;
    }

    return Tournament(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown',
      totalMatches: json['totalMatches'] ?? 0,
      currentMatches: json['currentMatches'] ?? 0,
      type: json['type'] != null
          ? TournamentType.values.firstWhere(
              (e) => e.toString() == json['type'],
              orElse: () => TournamentType.squad,
            )
          : TournamentType.squad,
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'])
          : DateTime.now(),
      totalTeamsOrPlayers: json['totalTeamsOrPlayers'] ?? 0,
      teams: (json['teams'] as List?)?.map((t) => Team.fromJson(t)).toList() ?? [],
      matches: (json['matches'] as List?)?.map((m) => MatchResult.fromJson(m)).toList() ?? [],
      standings: (json['standings'] as Map?)?.map(
            (k, v) => MapEntry(k, Map<String, int>.from(v)),
          ) ??
          {},
      rankPoints: rankPoints,
      killPoint: json['killPoint'] ?? AppConstants.defaultKillPoint,
      autoDeleteAfterMonth: json['autoDeleteAfterMonth'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, int> rankPointsJson = {};
    rankPoints.forEach((k, v) {
      rankPointsJson[k.toString()] = v;
    });
    return {
      'id': id,
      'name': name,
      'totalMatches': totalMatches,
      'currentMatches': currentMatches,
      'type': type.toString(),
      'creationDate': creationDate.toIso8601String(),
      'totalTeamsOrPlayers': totalTeamsOrPlayers,
      'teams': teams.map((t) => t.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'standings': standings,
      'rankPoints': rankPointsJson,
      'killPoint': killPoint,
      'autoDeleteAfterMonth': autoDeleteAfterMonth,
    };
  }

  // ---------- Helper Methods ----------
  Tournament copyWith({
    String? name,
    int? totalMatches,
    int? currentMatches,
    TournamentType? type,
    DateTime? creationDate,
    int? totalTeamsOrPlayers,
    List<Team>? teams,
    List<MatchResult>? matches,
    Map<String, Map<String, int>>? standings,
    Map<int, int>? rankPoints,
    int? killPoint,
    bool? autoDeleteAfterMonth,
  }) {
    return Tournament(
      id: id,
      name: name ?? this.name,
      totalMatches: totalMatches ?? this.totalMatches,
      currentMatches: currentMatches ?? this.currentMatches,
      type: type ?? this.type,
      creationDate: creationDate ?? this.creationDate,
      totalTeamsOrPlayers: totalTeamsOrPlayers ?? this.totalTeamsOrPlayers,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
      standings: standings ?? this.standings,
      rankPoints: rankPoints ?? this.rankPoints,
      killPoint: killPoint ?? this.killPoint,
      autoDeleteAfterMonth: autoDeleteAfterMonth ?? this.autoDeleteAfterMonth,
    );
  }
}