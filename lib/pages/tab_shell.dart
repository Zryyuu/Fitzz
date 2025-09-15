import 'package:flutter/material.dart';
import 'package:fitzz/pages/home_page.dart';
import 'package:fitzz/pages/progress_page.dart';
import 'package:fitzz/pages/achievements_page.dart';
import 'package:fitzz/pages/library_page.dart';
// AppBars are managed by each page; TabShell only controls bottom navigation and keeps pages alive

class TabShell extends StatefulWidget {
  const TabShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  late int _index;

  final _pages = <Widget>[
    const HomePage(withBottomNav: false),
    const ProgressPage(withBottomNav: false),
    const AchievementsPage(withBottomNav: false),
    const LibraryPage(withBottomNav: false),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Achievements'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
        ],
      ),
    );
  }
}
