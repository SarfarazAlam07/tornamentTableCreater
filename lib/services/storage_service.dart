import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament.dart';
import '../utils/constants.dart';

/// Handles offline data storage using SharedPreferences.
class StorageService {
  /// Loads all tournaments from local storage.
  Future<List<Tournament>> loadTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(AppConstants.tournamentsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Tournament.fromJson(json)).toList();
  }

  /// Saves the entire tournament list to local storage.
  Future<void> saveTournaments(List<Tournament> tournaments) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(tournaments.map((t) => t.toJson()).toList());
    await prefs.setString(AppConstants.tournamentsKey, jsonString);
  }

  /// Adds a new tournament.
  Future<void> addTournament(Tournament tournament) async {
    final tournaments = await loadTournaments();
    tournaments.add(tournament);
    await saveTournaments(tournaments);
  }

  /// Updates an existing tournament.
  Future<void> updateTournament(Tournament updated) async {
    final tournaments = await loadTournaments();
    final index = tournaments.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      tournaments[index] = updated;
      await saveTournaments(tournaments);
    }
  }

  /// Deletes a tournament by its ID.
  Future<void> deleteTournament(String id) async {
    final tournaments = await loadTournaments();
    tournaments.removeWhere((t) => t.id == id);
    await saveTournaments(tournaments);
  }
}