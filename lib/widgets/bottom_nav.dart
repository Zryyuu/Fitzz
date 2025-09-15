import 'package:flutter/material.dart';
import 'package:fitzz/pages/home_page.dart';
import 'package:fitzz/pages/progress_page.dart';
import 'package:fitzz/pages/achievements_page.dart';
import 'package:fitzz/pages/library_page.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex; // 0: Home, 1: Progress, 2: Achievements, 3: Library

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const ProgressPage();
        break;
      case 2:
        page = const AchievementsPage();
        break;
      case 3:
      default:
        page = const LibraryPage();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _go(context, i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), label: 'Progress'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Achievements'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
      ],
    );
  }
}
