import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';

/// The Teams tab inside Tournament Dashboard.
/// Displays all teams with expandable player list.
class TeamsTab extends StatelessWidget {
  final List<Team> teams;
  final Function(String, List<String>) onAddTeam; // (teamName, playerNames)
  final Function(String) onDeleteTeam;
  final bool isDark;

  const TeamsTab({
    super.key,
    required this.teams,
    required this.onAddTeam,
    required this.onDeleteTeam,
    required this.isDark,
  });

  void _showAddTeamDialog(BuildContext context) {
    final teamNameController = TextEditingController();
    final playersController = TextEditingController(); // multiline input

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teamNameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Enter player names (one per line):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: playersController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Player 1\nPlayer 2\nPlayer 3',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final teamName = teamNameController.text.trim();
              if (teamName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter team name')));
                return;
              }
              final rawPlayers = playersController.text.trim();
              if (rawPlayers.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one player')));
                return;
              }
              final playerNames = rawPlayers.split('\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
              if (playerNames.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid player names')));
                return;
              }
              onAddTeam(teamName, playerNames);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return teams.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No Teams Yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Tap + icon in top bar to add teams', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Dismissible(
                key: Key(team.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onDeleteTeam(team.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.cyan,
                      child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(team.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text('Players: ${team.players.length}'),
                    children: team.players.map((player) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(player.name),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
  }
}