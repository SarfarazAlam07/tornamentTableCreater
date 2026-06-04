import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'screens/tournament_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = ThemeService();
  runApp(PointTableApp(themeService: themeService));
}

class PointTableApp extends StatelessWidget {
  final ThemeService themeService;
  const PointTableApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeService.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Gaming Point Table',
          theme: themeService.getTheme(isDark),
          home: TournamentListScreen(themeService: themeService),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}