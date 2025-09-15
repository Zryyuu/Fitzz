import 'package:flutter/material.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
import 'package:fitzz/widgets/profile_avatar_button.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key, this.withBottomNav = true});

  final bool withBottomNav;

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _ready = false; // keep UX consistent with other tabs

  @override
  void initState() {
    super.initState();
    // No async data yet, but delay one microtask to match ready pattern and avoid flicker
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievements = const [
      {'title': 'Strike 5 Hari', 'desc': 'Selesaikan challenge 5 hari berturut-turut'},
      {'title': 'Strike 30 Hari', 'desc': 'Selesaikan challenge 30 hari berturut-turut'},
      {'title': 'Early Bird', 'desc': 'Selesaikan challenge sebelum jam 7 pagi'},
    ];

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Achievements'),
          actions: const [
            ProfileAvatarButton(radius: 18),
          ],
        ),
        bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 2) : null,
        body: const SizedBox.expand(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Achievements'),
        actions: const [
          ProfileAvatarButton(radius: 18),
        ],
      ),
      // Drawer removed: using bottom navigation
      bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 2) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = achievements[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title']!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(a['desc']!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

