import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'tournament_dashboard_screen.dart';

/// First screen of the app: displays all tournaments.
class TournamentListScreen extends StatefulWidget {
  final ThemeService themeService;
  const TournamentListScreen({super.key, required this.themeService});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  List<Tournament> tournaments = [];
  final StorageService storage = StorageService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    List<Tournament> loaded = await storage.loadTournaments();
    // Auto-delete filter: remove tournaments older than 30 days if flagged
    final now = DateTime.now();
    loaded = loaded.where((t) {
      if (t.autoDeleteAfterMonth) {
        final diff = now.difference(t.creationDate).inDays;
        return diff < 30;
      }
      return true;
    }).toList();
    setState(() {
      tournaments = loaded;
      isLoading = false;
    });
  }

  Future<void> _addTournament(String name, int totalMatches, TournamentType type, int count) async {
    final newTournament = Tournament(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      totalMatches: totalMatches,
      type: type,
      creationDate: DateTime.now(),
      totalTeamsOrPlayers: count,
    );
    await storage.addTournament(newTournament);
    await _loadData();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final matchController = TextEditingController();
    TournamentType selectedType = TournamentType.squad;
    final countController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create New Tournament'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tournament Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.emoji_events),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: matchController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Total Matches',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.sports_score),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TournamentType>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tournament Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.people),
                    ),
                    items: const [
                      DropdownMenuItem(value: TournamentType.solo, child: Text('Solo (1 player per team)')),
                      DropdownMenuItem(value: TournamentType.duo, child: Text('Duo (2 players per team)')),
                      DropdownMenuItem(value: TournamentType.squad, child: Text('Squad (4 players per team)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedType = value;
                          countController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: selectedType == TournamentType.solo ? 'Total Players' : 'Total Teams',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(selectedType == TournamentType.solo ? Icons.person : Icons.group),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final totalMatches = int.tryParse(matchController.text.trim()) ?? 0;
                  final count = int.tryParse(countController.text.trim()) ?? 0;
                  if (name.isNotEmpty && totalMatches > 0 && count > 0) {
                    _addTournament(name, totalMatches, selectedType, count);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields correctly')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editTournament(Tournament tournament) async {
    final nameController = TextEditingController(text: tournament.name);
    final matchController = TextEditingController(text: tournament.totalMatches.toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tournament'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tournament Name')),
            const SizedBox(height: 16),
            TextField(controller: matchController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Matches')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final newName = nameController.text.trim();
      final newMatches = int.tryParse(matchController.text.trim()) ?? tournament.totalMatches;
      if (newName.isNotEmpty) {
        final updated = tournament.copyWith(name: newName, totalMatches: newMatches);
        await storage.updateTournament(updated);
        await _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament updated!')));
      }
    }
  }

  Future<void> _deleteTournament(String id) async {
    await storage.deleteTournament(id);
    await _loadData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament deleted!')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeService.isDarkMode.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gaming Tournaments'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.cyan, Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.themeService.toggleTheme(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tournaments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No Tournaments Yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('Tap + button to create one', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final tournament = tournaments[index];
                    return Dismissible(
                      key: Key(tournament.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteTournament(tournament.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onLongPress: () => _editTournament(tournament),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [Colors.cyan.shade900.withOpacity(0.6), Colors.purple.shade900.withOpacity(0.6)]
                                  : [Colors.deepPurple.shade50, Colors.purple.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(color: isDark ? Colors.cyan.withOpacity(0.3) : Colors.grey.shade300, blurRadius: 8, offset: const Offset(0, 4))],
                            border: Border.all(color: isDark ? Colors.cyan.withOpacity(0.5) : Colors.transparent, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.cyan, Colors.purpleAccent]), shape: BoxShape.circle),
                              child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))),
                            ),
                            title: Text(tournament.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.sports_esports, size: 16, color: isDark ? Colors.cyan : Colors.deepPurple),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_getTypeString(tournament.type)} | ${tournament.type == TournamentType.solo ? "Players" : "Teams"}: ${tournament.totalTeamsOrPlayers} | Matches: ${tournament.currentMatches}/${tournament.totalMatches}',
                                      style: TextStyle(color: isDark ? Colors.cyan : Colors.deepPurple),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: tournament.totalMatches > 0 ? tournament.currentMatches / tournament.totalMatches : 0,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.cyan,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDashboardScreen(
                                    tournament: tournament,
                                    storage: storage,
                                    themeService: widget.themeService,
                                  ),
                                ),
                              );
                              _loadData(); // Refresh after returning
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  String _getTypeString(TournamentType type) {
    switch (type) {
      case TournamentType.solo:
        return 'Solo';
      case TournamentType.duo:
        return 'Duo';
      case TournamentType.squad:
        return 'Squad';
    }
  }
}