import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/screens/home_map.dart';
import 'src/screens/reports_list.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/profile_screen.dart';
import 'src/screens/auth_screen.dart';
import 'src/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RoadRadarApp());
}

class RoadRadarApp extends StatelessWidget {
  const RoadRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Montserrat',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        bodyMedium: TextStyle(fontSize: 16),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A73E8).withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
        iconTheme: MaterialStateProperty.all(const IconThemeData(color: Color(0xFF1A73E8))),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true,
        fillColor: Color(0xFFF5F7FB),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1A73E8),
        contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
    return MaterialApp(
      title: 'RoadRadar',
      theme: baseTheme,
      home: StreamBuilder(
        stream: authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) {
            return const AuthScreen();
          }
          return const _HomeShell();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  final _pages = [
    HomeMapScreen(),
    ReportsListScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
