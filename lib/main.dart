import 'package:flutter/material.dart';
import 'logic/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    NotificationService().init(),
    themeProvider.load(),
  ]);
  runApp(const L9BossTrackerApp());
}

class L9BossTrackerApp extends StatelessWidget {
  const L9BossTrackerApp({super.key});

  static const _seed = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'L9 Boss Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _seed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
