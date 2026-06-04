import 'player.dart';

/// Represents a team with a name and a list of players.
class Team {
  final String id;
  String name;
  List<Player> players;

  Team({required this.id, required this.name, this.players = const []});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'],
        name: json['name'],
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList(),
      );
}