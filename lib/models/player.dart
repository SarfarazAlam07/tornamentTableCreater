/// Represents a single player in a team.
class Player {
  final String id;   // Unique identifier
  String name;       // Player's in-game name

  Player({required this.id, required this.name});

  /// Convert Player object to JSON for storage
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  /// Create Player object from JSON
  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(id: json['id'], name: json['name']);
}