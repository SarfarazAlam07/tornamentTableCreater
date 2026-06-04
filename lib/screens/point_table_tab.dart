import 'package:flutter/material.dart';
import '../models/team.dart';

/// The Point Table tab inside Tournament Dashboard.
/// Shows sorted rankings based on total points.
class PointTableTab extends StatelessWidget {
  final Map<String, Map<String, int>> standings;
  final List<Team> teams;
  final bool isDark;

  const PointTableTab({super.key, required this.standings, required this.teams, required this.isDark});

  List<_StandingRow> get _sortedStandings {
    List<_StandingRow> rows = [];
    for (var team in teams) {
      final stats = standings[team.id] ?? {'positionPoints': 0, 'kills': 0, 'total': 0};
      rows.add(_StandingRow(
        teamName: team.name,
        positionPoints: stats['positionPoints']!,
        kills: stats['kills']!,
        total: stats['total']!,
      ));
    }
    rows.sort((a, b) => b.total.compareTo(a.total));
    for (int i = 0; i < rows.length; i++) {
      rows[i].rank = i + 1;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sortedStandings;
    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Teams Yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Add teams and matches to see point table', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.cyan, Colors.purpleAccent]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Expanded(child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(flex: 2, child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(child: Text('POS.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(child: Text('KILLS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              Expanded(child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        // List of standings
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: row.rank == 1
                            ? Colors.amber
                            : row.rank == 2
                                ? Colors.grey.shade400
                                : row.rank == 3
                                    ? Colors.brown
                                    : Colors.cyan.withOpacity(0.3),
                        child: Text('${row.rank}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(row.teamName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(child: Text('${row.positionPoints}')),
                    Expanded(child: Text('${row.kills}')),
                    Expanded(child: Text('${row.total}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Helper class for storing a single row in the point table.
class _StandingRow {
  int rank = 0;
  final String teamName;
  final int positionPoints;
  final int kills;
  final int total;
  _StandingRow({
    required this.teamName,
    required this.positionPoints,
    required this.kills,
    required this.total,
  });
}