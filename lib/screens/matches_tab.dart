import 'package:flutter/material.dart';
import '../models/match_result.dart';
import '../models/team.dart';

/// The Matches tab inside Tournament Dashboard.
/// Displays a list of all matches with per-team scores.
class MatchesTab extends StatelessWidget {
  final List<MatchResult> matches;
  final List<Team> teams;
  final bool isDark;

  const MatchesTab({super.key, required this.matches, required this.teams, required this.isDark});

  String _getTeamName(String id) => teams.firstWhere(
        (t) => t.id == id,
        orElse: () => Team(id: '', name: 'Unknown', players: []),
      ).name;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_score, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Matches Yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Tap + button to add a match', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.cyan : Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Match ${index + 1} - ${match.date.day}/${match.date.month}/${match.date.year}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                ...match.teamPoints.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(_getTeamName(entry.key))),
                        Text(
                          'Pos: ${entry.value['positionPoints']}  K: ${entry.value['kills']}  Total: ${entry.value['total']}',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}