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
  // Use a GlobalKey to access ProgressPage state without exposing private types across libraries
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _achievementsKey = GlobalKey();

  late final List<Widget> _pages = <Widget>[
    const HomePage(withBottomNav: false),
    ProgressPage(key: _progressKey, withBottomNav: false),
    AchievementsPage(key: _achievementsKey, withBottomNav: false),
    const LibraryPage(withBottomNav: false),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
    // If entering directly to a tab that needs live data, refresh once UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_index == 1) {
        final st = _progressKey.currentState;
        if (st != null) {
          (st as dynamic).refresh?.call();
        }
      } else if (_index == 2) {
        final st = _achievementsKey.currentState;
        if (st != null) {
          (st as dynamic).refresh?.call();
        }
      }
    });
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    // Trigger refresh when switching to Progress/Achievements tab so numbers are up to date
    if (i == 1) {
      final st = _progressKey.currentState;
      if (st != null) {
        (st as dynamic).refresh?.call();
      }
    } else if (i == 2) {
      final st = _achievementsKey.currentState;
      if (st != null) {
        (st as dynamic).refresh?.call();
      }
    }
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
