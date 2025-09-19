import 'package:flutter/material.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
import 'package:fitzz/widgets/profile_avatar_button.dart';
import 'package:fitzz/services/firebase_user_service.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key, this.withBottomNav = true});

  final bool withBottomNav;

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _ready = false; // keep UX consistent with other tabs
  int _strike = 0;
  int _bestStrike = 0;
  int _totalXp = 0;
  int _totalWorkouts = 0;
  List<int> _badges = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Allow parent (TabShell) to trigger manual refresh when this tab becomes visible
  Future<void> refresh() async {
    await _init();
  }

  Future<void> _init() async {
    final storage = FirebaseUserService.instance;
    final strike = await storage.getStrike();
    final bestStrike = await storage.getBestStrike();
    final totalXp = await storage.getTotalXp();
    final totalWorkouts = await storage.getTotalWorkouts();
    final badges = await storage.getBadges();
    if (!mounted) return;
    setState(() {
      _strike = strike;
      _bestStrike = bestStrike;
      _totalXp = totalXp;
      _totalWorkouts = totalWorkouts;
      _badges = badges;
      _ready = true;
    });
  }

  // Helpers copied to compute level/XP thresholds (same logic as HomePage)
  int _xpNeededForLevel(int level) {
    final tier = ((level - 1) ~/ 5);
    return 200 + 50 * tier;
  }

  int _levelFromXp(int xp) {
    int level = 1;
    int acc = 0;
    while (true) {
      final need = _xpNeededForLevel(level);
      if (xp < acc + need) return level;
      acc += need;
      level += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _levelFromXp(_totalXp);
    final achievements = <Map<String, dynamic>>[
      // Strike beruntun (current strike)
      {
        'title': 'Strike 3 Hari',
        'desc': 'Selesaikan challenge 3 hari berturut-turut',
        'unlocked': _strike >= 3,
        'progress': '${_strike.clamp(0, 3)}/3'
      },
      {
        'title': 'Strike 5 Hari',
        'desc': 'Selesaikan challenge 5 hari berturut-turut',
        'unlocked': _strike >= 5,
        'progress': '${_strike.clamp(0, 5)}/5'
      },
      {
        'title': 'Strike 7 Hari',
        'desc': 'Selesaikan challenge 7 hari berturut-turut',
        'unlocked': _strike >= 7,
        'progress': '${_strike.clamp(0, 7)}/7'
      },
      {
        'title': 'Strike 14 Hari',
        'desc': 'Selesaikan challenge 14 hari berturut-turut',
        'unlocked': _strike >= 14,
        'progress': '${_strike.clamp(0, 14)}/14'
      },
      {
        'title': 'Strike 30 Hari',
        'desc': 'Selesaikan challenge 30 hari berturut-turut',
        'unlocked': _strike >= 30,
        'progress': '${_strike.clamp(0, 30)}/30'
      },

      // Rekor terbaik (best strike ever)
      {
        'title': 'Rekor 10 Hari',
        'desc': 'Capai rekor strike 10 hari',
        'unlocked': _bestStrike >= 10,
        'progress': '${_bestStrike.clamp(0, 10)}/10'
      },
      {
        'title': 'Rekor 20 Hari',
        'desc': 'Capai rekor strike 20 hari',
        'unlocked': _bestStrike >= 20,
        'progress': '${_bestStrike.clamp(0, 20)}/20'
      },
      {
        'title': 'Rekor 50 Hari',
        'desc': 'Capai rekor strike 50 hari',
        'unlocked': _bestStrike >= 50,
        'progress': '${_bestStrike.clamp(0, 50)}/50'
      },

      // Total workout selesai
      {
        'title': 'Langkah Pertama',
        'desc': 'Selesaikan 1 workout',
        'unlocked': _totalWorkouts >= 1,
        'progress': '${_totalWorkouts.clamp(0, 1)}/1'
      },
      {
        'title': 'Semangat 10!',
        'desc': 'Selesaikan 10 workout',
        'unlocked': _totalWorkouts >= 10,
        'progress': '${_totalWorkouts.clamp(0, 10)}/10'
      },
      {
        'title': 'Konsisten 25',
        'desc': 'Selesaikan 25 workout',
        'unlocked': _totalWorkouts >= 25,
        'progress': '${_totalWorkouts.clamp(0, 25)}/25'
      },
      {
        'title': 'Pekerja Keras 50',
        'desc': 'Selesaikan 50 workout',
        'unlocked': _totalWorkouts >= 50,
        'progress': '${_totalWorkouts.clamp(0, 50)}/50'
      },
      {
        'title': 'Seratus!',
        'desc': 'Selesaikan 100 workout',
        'unlocked': _totalWorkouts >= 100,
        'progress': '${_totalWorkouts.clamp(0, 100)}/100'
      },

      // Level milestones (badge style)
      ...[10, 25, 45, 65, 75, 100].map((t) => {
            'title': 'Capai Level $t',
            'desc': 'Naik ke Level $t untuk lencana baru',
            'unlocked': level >= t,
            'progress': 'Lv $level/$t'
          }),

      // Kolektor lencana
      {
        'title': 'Kolektor Lencana',
        'desc': 'Kumpulkan 3 lencana level',
        'unlocked': _badges.length >= 3,
        'progress': '${_badges.length}/3'
      },
      {
        'title': 'Koleksi Lengkap',
        'desc': 'Kumpulkan semua lencana level',
        'unlocked': _badges.toSet().containsAll({10, 25, 45, 65, 75, 100}),
        'progress': '${_badges.length}/6'
      },
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
              final unlocked = a['unlocked'] == true;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
                      color: unlocked ? Colors.amber : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: unlocked ? Colors.black : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a['desc'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                          ),
                          if (a['progress'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(unlocked ? Icons.check_circle : Icons.lock_outline, size: 16, color: unlocked ? Colors.green : Colors.grey),
                                const SizedBox(width: 6),
                                Text(a['progress'] as String, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ]
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

