/// App-wide constants used across the application.
class AppConstants {
  // SharedPreferences keys
  static const String tournamentsKey = 'tournaments';
  static const String themeKey = 'isDarkMode';
  static const String backgroundImageKey = 'backgroundImage';

  /// Default rank points (Free Fire standard)
  static const Map<int, int> defaultRankPoints = {
    1: 12, 2: 9, 3: 8, 4: 7, 5: 6,
    6: 5, 7: 4, 8: 3, 9: 2, 10: 1,
    11: 0, 12: 0,
  };

  /// Points awarded per kill (default = 1)
  static const int defaultKillPoint = 1;
}