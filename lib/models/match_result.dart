/// Stores the result of a single match.
class MatchResult {
  final String matchId;          // Unique ID
  final DateTime date;           // Match date
  final Map<String, dynamic> teamPoints; // teamId -> {positionPoints, kills, total}

  MatchResult({
    required this.matchId,
    required this.date,
    required this.teamPoints,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'date': date.toIso8601String(),
        'teamPoints': teamPoints,
      };

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
        matchId: json['matchId'],
        date: DateTime.parse(json['date']),
        teamPoints: Map<String, dynamic>.from(json['teamPoints']),
      );
}