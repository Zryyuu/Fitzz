import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex; // 0: Home, 1: Progress, 2: Achievements, 3: Library

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/progress');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/achievements');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/library');
        break;
    }
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
