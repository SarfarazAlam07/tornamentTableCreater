import 'package:flutter/material.dart';
import '../models/team.dart';

/// A dialog that asks for rank and kills for each team in a match.
class MatchEntryDialog extends StatefulWidget {
  final List<Team> teams;
  final Map<int, int> rankPoints; // Not used directly but kept for consistency

  const MatchEntryDialog({super.key, required this.teams, required this.rankPoints});

  @override
  State<MatchEntryDialog> createState() => _MatchEntryDialogState();
}

class _MatchEntryDialogState extends State<MatchEntryDialog> {
  late Map<String, TextEditingController> _rankControllers;
  late Map<String, TextEditingController> _killControllers;

  @override
  void initState() {
    super.initState();
    _rankControllers = {};
    _killControllers = {};
    for (var team in widget.teams) {
      _rankControllers[team.id] = TextEditingController(text: '1');
      _killControllers[team.id] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var c in _rankControllers.values) c.dispose();
    for (var c in _killControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Match Result'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.teams.length,
          itemBuilder: (context, index) {
            final team = widget.teams[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rankControllers[team.id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rank',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _killControllers[team.id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Kills',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Map<String, int> result = {};
            for (var team in widget.teams) {
              int rank = int.tryParse(_rankControllers[team.id]!.text.trim()) ?? 99;
              result[team.id] = rank;
              // kills are not used in this version – can be extended later
            }
            Navigator.pop(context, result);
          },
          child: const Text('Save Match'),
        ),
      ],
    );
  }
}