import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:fitzz/utils/daily_challenge.dart';
import 'package:fitzz/utils/motivations.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late String _todayKey;
  List<String> _challenges = const [];
  List<bool> _done = List<bool>.filled(3, false);
  int _strike = 0;
  int _bestStrike = 0;
  bool _loading = true;
  bool _revealed = false;
  int _totalXp = 0;
  int _totalWorkouts = 0;
  int? _selectedBadge;
  String? _avatarBase64;
  String? _lastCompletedDate;
  int _extraAdded = 0; // how many extra challenges added today
  bool _todayConfirmed = false; // whether user confirmed completion today
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayKey = DateFormat('yyyy-MM-dd').format(now);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  // Avatar with badge ring helper
  Widget _buildAvatarWithRing({double radius = 20}) {
    final imageProvider = (_avatarBase64 == null) ? null : MemoryImage(base64Decode(_avatarBase64!));
    // If no badge is selected, show plain avatar without ring.
    if (_selectedBadge == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
        child: imageProvider == null ? const Icon(Icons.person, color: Colors.black) : null,
      );
    }

    // Otherwise, show ring and subtle glow according to badge color.
    final ringColor = _ringColorForBadge(_selectedBadge);
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        final t = _glowCtrl.value; // 0..1
        final blur = 4 + 6 * t;
        final spread = 0.5 + 1.0 * t;
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
            boxShadow: [
              BoxShadow(color: ringColor.withValues(alpha: 0.5), blurRadius: blur, spreadRadius: spread),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
            child: imageProvider == null ? const Icon(Icons.person, color: Colors.black) : null,
          ),
        );
      },
    );
  }

  Color _ringColorForBadge(int? level) {
    if (level == null) return Colors.white;
    // Map specific badge levels to ring colors
    switch (level) {
      case 10:
        return const Color(0xFFB0BEC5); // steel grey
      case 25:
        return const Color(0xFF26C6DA); // cyan
      case 45:
        return const Color(0xFF66BB6A); // green
      case 65:
        return const Color(0xFFFFCA28); // amber
      case 75:
        return const Color(0xFFFF7043); // deep orange
      case 100:
        return const Color(0xFFAB47BC); // purple
      default:
        return Colors.black;
    }
  }

  Future<void> _init() async {
    final storage = LocalStorageService.instance;

    // Load existing flags & stats first
    var challenges = await storage.getChallenges(_todayKey);
    final done = await storage.getChallengesDone(_todayKey);
    final revealed = await storage.getChallengesRevealed(_todayKey);
    final totalXp = await storage.getTotalXp();
    final totalWorkouts = await storage.getTotalWorkouts();
    final bestStrike = await storage.getBestStrike();
    final extraAdded = await storage.getExtraCount(_todayKey);
    final selectedBadge = await storage.getSelectedBadgeLevel();
    final avatar = await storage.getAvatarBase64();

    // Apply missed-day penalty once per day: if last completed is neither today nor yesterday
    final last = await storage.getLastCompletedDate();
    final checkedDate = await storage.getPenaltyCheckedDate();
    final today = DateTime.parse(_todayKey);
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));
    if (checkedDate != _todayKey) {
      if (last != null && last != _todayKey && last != yesterdayKey) {
        // Missed yesterday => reset strike and drop 1 level
        int newStrike = 0;
        int newTotalXp = _baseXpForLevel((_levelFromXp(totalXp) - 1).clamp(1, 999)) - 0;
        // Prevent negative XP
        if (newTotalXp < 0) newTotalXp = 0;
        await storage.setStrike(newStrike);
        await storage.setTotalXp(newTotalXp);
      }
      await storage.setPenaltyCheckedDate(_todayKey);
    }
    // reload values that could have changed by penalty
    final strikeAfter = await storage.getStrike();
    final totalXpAfter = await storage.getTotalXp();

    // Generate today's challenges scaled by level if not yet revealed
    final levelNow = _levelFromXp(totalXpAfter);
    if (!revealed) {
      challenges = DailyChallengeGenerator.generateForDateLevel(_todayKey, levelNow);
      await storage.setChallenges(_todayKey, challenges);
    }

    setState(() {
      _challenges = challenges!;
      _done = done;
      _strike = strikeAfter;
      _revealed = revealed;
      _totalXp = totalXpAfter;
      _totalWorkouts = totalWorkouts;
      _bestStrike = bestStrike;
      _selectedBadge = selectedBadge;
      _avatarBase64 = avatar;
      _lastCompletedDate = last;
      _extraAdded = extraAdded;
      _todayConfirmed = last == _todayKey; // if already confirmed today
      _loading = false;
    });
  }

  Future<void> _toggle(int index, bool value) async {
    // Only allow marking as done via confirmation; ignore uncheck
    if (value && !_done[index]) {
      await _confirmChallenge(index);
    }
  }

  Future<void> _confirmChallenge(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Tandai selesai "${_challenges[index]}"? XP akan langsung bertambah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Konfirmasi')),
        ],
      ),
    );
    if (confirmed != true) return;

    final storage = LocalStorageService.instance;

    // 1) Mark done and persist
    setState(() => _done[index] = true);
    await storage.setChallengesDone(_todayKey, _done);

    // 2) Add XP instantly for this challenge
    int totalXp = await storage.getTotalXp();
    final prevLevel = _levelFromXp(totalXp);
    final gained = _xpForChallenge(_challenges[index]);
    totalXp += gained;
    await storage.setTotalXp(totalXp);

    // 3) Level up popup if any
    final newLevel = _levelFromXp(totalXp);
    if (newLevel > prevLevel && mounted) {
      final prevBadges = await storage.getBadges();
      List<int> badges = List<int>.from(prevBadges);
      for (final t in const [10, 25, 45, 65, 75, 100]) {
        if (newLevel >= t && !badges.contains(t)) badges.add(t);
      }
      badges.sort();
      await storage.setBadges(badges);
      final gainedBadges = [10, 25, 45, 65, 75, 100]
          .where((b) => newLevel >= b && !prevBadges.contains(b))
          .toList();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Level Up!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dari Level $prevLevel ke Level $newLevel'),
              const SizedBox(height: 8),
              Text('XP per level berikutnya ${_xpNeededForLevel(newLevel) == _xpNeededForLevel(prevLevel) ? 'tetap' : 'bertambah menjadi'} ${_xpNeededForLevel(newLevel)} XP'),
              if (gainedBadges.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Badge baru:'),
                Wrap(
                  spacing: 6,
                  children: gainedBadges.map((e) => Chip(label: Text('Lv$e'))).toList(),
                )
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    }

    // 4) If daily 3 just completed now, award daily completion (strike/workout)
    final dailyCount = 3;
    final dailyCompletedNow = List<bool>.from(_done.take(dailyCount)).every((e) => e);
    if (dailyCompletedNow && !_todayConfirmed) {
      final last = await storage.getLastCompletedDate();
      int strike = await storage.getStrike();
      final today = DateTime.parse(_todayKey);
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));
      if (last == yesterdayKey) {
        strike += 1;
      } else {
        strike = 1;
      }
      await storage.setStrike(strike);
      await storage.setLastCompletedDate(_todayKey);
      final totalWorkouts = (await storage.getTotalWorkouts()) + 1;
      await storage.setTotalWorkouts(totalWorkouts);
      // update best strike live
      int bestStrike = await storage.getBestStrike();
      if (strike > bestStrike) {
        bestStrike = strike;
        await storage.setBestStrike(bestStrike);
      }

      if (!mounted) return;
      setState(() {
        _strike = strike;
        _bestStrike = bestStrike;
        _todayConfirmed = true;
        _totalXp = totalXp; // reflect XP gain
        _totalWorkouts = totalWorkouts;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Strike $_strike hari!'), behavior: SnackBarBehavior.floating),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _totalXp = totalXp; // reflect XP gain
      });
    }
  }

  Future<void> _addExtraChallenge() async {
    if (!_revealed) return;
    if (_extraAdded >= 3) return;
    final storage = LocalStorageService.instance;
    final levelNow = _levelFromXp(_totalXp);
    // generate until non-duplicate
    final pool = <String>{..._challenges};
    int tries = 0;
    String? candidate;
    while (tries < 10) {
      final gen = DailyChallengeGenerator.generateForDateLevel('$_todayKey+$_extraAdded+$tries', levelNow);
      // pick first that is not in pool
      candidate = gen.firstWhere((e) => !pool.contains(e), orElse: () => gen.first);
      if (!pool.contains(candidate)) break;
      tries++;
    }
    if (candidate == null || pool.contains(candidate)) return;
    setState(() {
      _challenges = [..._challenges, candidate!];
      _done = [..._done, false];
      _extraAdded += 1;
    });
    await storage.setChallenges(_todayKey, _challenges);
    await storage.setChallengesDone(_todayKey, _done);
    await storage.setExtraCount(_todayKey, _extraAdded);
  }

  Future<void> _revealToday() async {
    await LocalStorageService.instance.setChallengesRevealed(_todayKey, true);
    if (!mounted) return;
    setState(() => _revealed = true);
  }

  int _xpForChallenge(String text) {
    // Map keywords to difficulty
    final t = text.toLowerCase();
    // berat
    if (t.contains('burpee') || t.contains('jump') && t.contains('squat')) {
      return 70;
    }
    // sedang
    if (t.contains('dip') || t.contains('lunge') || t.contains('plank') && (t.contains('90') || t.contains('120'))){
      return 50;
    }
    // ringan
    if (t.contains('push') || t.contains('squat') || t.contains('lari') || t.contains('run') || t.contains('jalan') || t.contains('jumping jack') || t.contains('mountain climber') || t.contains('wall sit')) {
      return 30;
    }
    return 30; // default ringan
  }

  // XP per level increases every 5 levels: 1-5:200, 6-10:250, ...
  int _xpNeededForLevel(int level) {
    final tier = ((level - 1) ~/ 5); // 0-based tier
    return 200 + 50 * tier;
  }

  int _baseXpForLevel(int level) {
    int xp = 0;
    for (int l = 1; l < level; l++) {
      xp += _xpNeededForLevel(l);
    }
    return xp;
  }

  int _nextLevelTotalXp(int level) => _baseXpForLevel(level + 1);

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
    final completedDaily = _done.take(3).where((e) => e).length;
    final progress = 3 == 0 ? 0.0 : completedDaily / 3;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final level = _levelFromXp(_totalXp);
    final baseXp = _baseXpForLevel(level);
    final nextXp = _nextLevelTotalXp(level);
    final xpWithinLevel = (_totalXp - baseXp).clamp(0, _xpNeededForLevel(level));
    final xpProgress = (xpWithinLevel / (nextXp - baseXp)).clamp(0.0, 1.0);
    final motivation = Motivations.forContext(
      _todayKey,
      level: level,
      strike: _strike,
      bestStrike: _bestStrike,
      lastCompletedDate: _lastCompletedDate,
      levelJustUp: false,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
              borderRadius: BorderRadius.circular(24),
              child: _buildAvatarWithRing(radius: 18),
            ),
          ),
        ],
      ),
      // Drawer removed: bottom navigation is used instead
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: Container(
        color: const Color(0xFFF0F0F0),
        width: double.infinity,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerSection(theme, xpProgress, level, xpWithinLevel, nextXp - baseXp),
            const SizedBox(height: 8),
            _quickStats(theme),
            const SizedBox(height: 8),
            _motivationCard(theme, motivation),
            const SizedBox(height: 8),
            _sectionTitle(theme, 'Challenge WorkOut Harian'),
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (o) { o.disallowIndicator(); return true; },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _revealed
                      ? ListView.separated(
                          itemCount: _challenges.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _challengeItem(i),
                        )
                      : ListView(
                          children: [
                            _revealPlaceholder(theme, progress, completedDaily, 3),
                          ],
                        ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (_revealed && completedDaily == 3 && _extraAdded < 3) ? _addExtraChallenge : null,
                          child: Text(_extraAdded < 3 ? 'Tambah Challenge (${3 - _extraAdded} sisa)' : 'Challenge tambahan habis'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerSection(ThemeData theme, double xpProgress, int level, int xpWithinLevel, int levelSpan) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF7F7F7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level $level', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('XP: $xpWithinLevel/$levelSpan', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: xpProgress,
              backgroundColor: const Color(0xFFE6E6E6),
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 20)),
              Text('Strike $_strike hari!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // Badges are now represented as the profile avatar border (ring) on the top-right.
        ],
      ),
    );
  }

  Widget _quickStats(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem(const Icon(Icons.local_fire_department_outlined, color: Colors.black), 'Strike tertinggi', '$_bestStrike Hari'),
          _statItem(const Icon(Icons.check_circle_outline, color: Colors.black), 'Workout selesai', '$_totalWorkouts Kali'),
          _statItem(const Icon(Symbols.stars, fill: 0, weight: 400, grade: 0, opticalSize: 24, color: Colors.black), 'Total XP', '$_totalXp XP'),
        ],
      ),
    );
  }

  Widget _statItem(Widget icon, String title, String value) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _motivationCard(ThemeData theme, String motivation) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Text(
        '“$motivation”',
        style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _revealPlaceholder(ThemeData theme, double progress, int completed, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_off_outlined),
                  const SizedBox(width: 8),
                  Text('Challenge hari ini tersembunyi', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(_todayKey, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _revealToday,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: const Text('Mulai Challenge Hari Ini'),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _challengeItem(int i) {
    final completed = _done[i];
    return Opacity(
      opacity: completed ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          value: completed,
          onChanged: (v) => _toggle(i, v ?? false),
          title: Text(
            _challenges[i],
            style: TextStyle(
              decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
          subtitle: Text(i < 3 ? 'Challenge Harian' : 'Challenge Tambahan', style: const TextStyle(fontSize: 12)),
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
