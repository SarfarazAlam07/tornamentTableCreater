import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/match_result.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../widgets/match_entry_dialog.dart';
import 'teams_tab.dart';
import 'matches_tab.dart';
import 'point_table_tab.dart';

/// Dashboard screen with three tabs: Teams, Matches, Point Table.
class TournamentDashboardScreen extends StatefulWidget {
  final Tournament tournament;
  final StorageService storage;
  final ThemeService themeService;

  const TournamentDashboardScreen({
    super.key,
    required this.tournament,
    required this.storage,
    required this.themeService,
  });

  @override
  State<TournamentDashboardScreen> createState() =>
      _TournamentDashboardScreenState();
}

class _TournamentDashboardScreenState extends State<TournamentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Tournament _tournament;
  int _currentTabIndex = 0;
  String? _backgroundImagePath;

  // Keys for capturing screenshots of each tab
  final GlobalKey _teamsTabKey = GlobalKey();
  final GlobalKey _matchesTabKey = GlobalKey();
  final GlobalKey _pointTableTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('background_${_tournament.id}');
    setState(() {
      _backgroundImagePath = path;
    });
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_${_tournament.id}', picked.path);
      setState(() {
        _backgroundImagePath = picked.path;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Background image set!')));
    }
  }

  /// Captures a widget as PNG using RepaintBoundary.
  Future<XFile?> _captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return XFile(file.path);
    } catch (e) {
      print('Error capturing: $e');
      return null;
    }
  }

  Future<void> _shareCurrentTab() async {
    GlobalKey? targetKey;
    switch (_currentTabIndex) {
      case 0:
        targetKey = _teamsTabKey;
        break;
      case 1:
        targetKey = _matchesTabKey;
        break;
      case 2:
        targetKey = _pointTableTabKey;
        break;
    }
    if (targetKey == null) return;
    final xfile = await _captureWidget(targetKey);
    if (xfile != null) {
      await Share.shareXFiles([
        xfile,
      ], text: '${_tournament.name} - ${_getTabName(_currentTabIndex)}');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to capture image')));
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Teams';
      case 1:
        return 'Matches';
      case 2:
        return 'Point Table';
      default:
        return 'Screen';
    }
  }

  Future<void> _shareFinalPointTable() async {
    final xfile = await _captureWidget(_pointTableTabKey);
    if (xfile != null) {
      await Share.shareXFiles([
        xfile,
      ], text: 'Final Point Table - ${_tournament.name}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture point table')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final all = await widget.storage.loadTournaments();
    final updated = all.firstWhere((t) => t.id == _tournament.id);
    setState(() {
      _tournament = updated;
    });
  }

  Future<void> _saveTournament(Tournament updated) async {
    await widget.storage.updateTournament(updated);
    await _refreshData();
  }

  void _showAddTeamDialog() {
    final teamNameController = TextEditingController();
    final playersController = TextEditingController(); // multiline

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Team'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter player names (one per line):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: playersController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText: 'Player 1\nPlayer 2\nPlayer 3',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final teamName = teamNameController.text.trim();
                  if (teamName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter team name')),
                    );
                    return;
                  }
                  final rawPlayers = playersController.text.trim();
                  if (rawPlayers.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter at least one player'),
                      ),
                    );
                    return;
                  }
                  final playerNames =
                      rawPlayers
                          .split('\n')
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();
                  if (playerNames.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid player names')),
                    );
                    return;
                  }
                  final players =
                      playerNames
                          .map(
                            (n) => Player(
                              id:
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString() +
                                  n,
                              name: n,
                            ),
                          )
                          .toList();
                  final newTeam = Team(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: teamName,
                    players: players,
                  );
                  final updated = _tournament.copyWith(
                    teams: [..._tournament.teams, newTeam],
                  );
                  await _saveTournament(updated);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTeam(String id) async {
    final updated = _tournament.copyWith(
      teams: _tournament.teams.where((t) => t.id != id).toList(),
    );
    await _saveTournament(updated);
  }

  void _editPointSettings() {
    final Map<int, TextEditingController> rankControllers = {};
    for (int i = 1; i <= 12; i++) {
      rankControllers[i] = TextEditingController(
        text: _tournament.rankPoints[i].toString(),
      );
    }
    final TextEditingController killController = TextEditingController(
      text: _tournament.killPoint.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Point Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 1; i <= 12; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 60, child: Text('Rank $i:')),
                          Expanded(
                            child: TextField(
                              controller: rankControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Point per Kill:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: killController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final Map<int, int> newPoints = {};
                  for (int i = 1; i <= 12; i++) {
                    newPoints[i] = int.tryParse(rankControllers[i]!.text) ?? 0;
                  }
                  final newKill = int.tryParse(killController.text) ?? 1;
                  final updated = _tournament.copyWith(
                    rankPoints: newPoints,
                    killPoint: newKill,
                  );
                  _saveTournament(updated);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _addMatch() async {
    if (_tournament.teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 teams first!')),
      );
      return;
    }
    if (_tournament.currentMatches >= _tournament.totalMatches) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament full! Cannot add more matches.'),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder:
          (context) => MatchEntryDialog(
            teams: _tournament.teams,
            rankPoints: _tournament.rankPoints,
          ),
    );
    if (result != null) {
      Map<String, dynamic> teamPoints = {};
      for (var entry in result.entries) {
        final teamId = entry.key;
        final rank = entry.value;
        final kills = 0; // we are not using kills in this iteration
        final posPoints = _tournament.rankPoints[rank] ?? 0;
        final total = posPoints + (kills * _tournament.killPoint);
        teamPoints[teamId] = {
          'positionPoints': posPoints,
          'kills': kills,
          'total': total,
        };
      }

      Map<String, Map<String, int>> newStandings = Map.from(
        _tournament.standings,
      );
      for (var teamId in teamPoints.keys) {
        final old =
            newStandings[teamId] ??
            {'positionPoints': 0, 'kills': 0, 'total': 0};
        final add = teamPoints[teamId];
        newStandings[teamId] = {
          'positionPoints':
              old['positionPoints']! + (add['positionPoints'] as int),
          'kills': old['kills']! + (add['kills'] as int),
          'total': old['total']! + (add['total'] as int),
        };
      }
      final newMatch = MatchResult(
        matchId: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        teamPoints: teamPoints,
      );
      final updated = _tournament.copyWith(
        matches: [..._tournament.matches, newMatch],
        standings: newStandings,
        currentMatches: _tournament.currentMatches + 1,
      );
      await _saveTournament(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Match added!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeService.isDarkMode.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _showAddTeamDialog,
              tooltip: 'Add Team',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _editPointSettings,
            tooltip: 'Point Settings',
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickBackgroundImage,
            tooltip: 'Set Background',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCurrentTab,
            tooltip: 'Share this screen',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'auto_delete') {
                final updated = _tournament.copyWith(
                  autoDeleteAfterMonth: !_tournament.autoDeleteAfterMonth,
                );
                await _saveTournament(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _tournament.autoDeleteAfterMonth
                          ? 'Auto-delete OFF'
                          : 'Auto-delete ON',
                    ),
                  ),
                );
              } else if (value == 'share_final') {
                await _shareFinalPointTable();
              }
            },
            itemBuilder:
                (context) => [
                  CheckedPopupMenuItem(
                    checked: _tournament.autoDeleteAfterMonth,
                    child: const Text('Auto-delete after 1 month'),
                    value: 'auto_delete',
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    child: Text('Share Final Point Table'),
                    value: 'share_final',
                  ),
                ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Teams', icon: Icon(Icons.group)),
            Tab(text: 'Matches', icon: Icon(Icons.sports_score)),
            Tab(text: 'Point Table', icon: Icon(Icons.leaderboard)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Container(
        decoration:
            _backgroundImagePath != null
                ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(_backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
                : null,
        child: TabBarView(
          controller: _tabController,
          children: [
            RepaintBoundary(
              key: _teamsTabKey,
              child: TeamsTab(
                teams: _tournament.teams,
                onAddTeam: (teamName, playerNames) async {
                  final players =
                      playerNames
                          .map(
                            (n) => Player(
                              id:
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString() +
                                  n,
                              name: n,
                            ),
                          )
                          .toList();
                  final newTeam = Team(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: teamName,
                    players: players,
                  );
                  final updated = _tournament.copyWith(
                    teams: [..._tournament.teams, newTeam],
                  );
                  await _saveTournament(updated);
                },
                onDeleteTeam: _deleteTeam,
                isDark: isDark,
              ),
            ),
            RepaintBoundary(
              key: _matchesTabKey,
              child: MatchesTab(
                matches: _tournament.matches,
                teams: _tournament.teams,
                isDark: isDark,
              ),
            ),
            RepaintBoundary(
              key: _pointTableTabKey,
              child: PointTableTab(
                standings: _tournament.standings,
                teams: _tournament.teams,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMatch,
        icon: const Icon(Icons.add),
        label: const Text('Add Match'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
