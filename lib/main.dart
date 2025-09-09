import 'package:flutter/material.dart';
import 'package:fitzz/pages/splash_page.dart';
import 'package:fitzz/pages/login_page.dart';
import 'package:fitzz/pages/register_page.dart';
import 'package:fitzz/pages/home_page.dart';
import 'package:fitzz/pages/progress_page.dart';
import 'package:fitzz/pages/achievements_page.dart';
import 'package:fitzz/pages/library_page.dart';
import 'package:fitzz/pages/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitzz',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        // Global typography for consistent mobile-friendly sizing
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF4F4F4F),
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B6B6B),
          ),
        ),
        // Inputs style across pages
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE5E5E5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/progress': (_) => const ProgressPage(),
        '/achievements': (_) => const AchievementsPage(),
        '/library': (_) => const LibraryPage(),
        '/profile': (_) => const ProfilePage(),
      },
    );
  }
}
