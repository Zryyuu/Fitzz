import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:fitzz/utils/daily_challenge.dart';
import 'package:fitzz/widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _todayKey;
  List<String> _challenges = const [];
  List<bool> _done = List<bool>.filled(3, false);
  int _strike = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayKey = DateFormat('yyyy-MM-dd').format(now);
    _init();
  }

  Future<void> _init() async {
    final storage = LocalStorageService.instance;

    // Load or create deterministic challenges for today
    var challenges = await storage.getChallenges(_todayKey);
    challenges ??= DailyChallengeGenerator.generateForDate(_todayKey);
    await storage.setChallenges(_todayKey, challenges);

    final done = await storage.getChallengesDone(_todayKey);
    final strike = await storage.getStrike();

    setState(() {
      _challenges = challenges!;
      _done = done;
      _strike = strike;
      _loading = false;
    });
  }

  Future<void> _toggle(int index, bool value) async {
    setState(() => _done[index] = value);
    await LocalStorageService.instance.setChallengesDone(_todayKey, _done);
  }

  Future<void> _finishToday() async {
    final storage = LocalStorageService.instance;
    final last = await storage.getLastCompletedDate();

    int strike = await storage.getStrike();

    if (last == _todayKey) {
      // already completed today; do nothing visual message could be added
    } else {
      // Calculate if yesterday
      final today = DateTime.parse(_todayKey);
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));
      if (last == yesterdayKey) {
        strike += 1;
      } else {
        strike = 1; // restart streak
      }
      await storage.setStrike(strike);
      await storage.setLastCompletedDate(_todayKey);
    }

    if (!mounted) return;
    setState(() => _strike = strike);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔥 Strike $_strike hari!'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _done.where((e) => e).length;
    final total = _challenges.length;
    final progress = total == 0 ? 0.0 : completed / total;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        color: const Color(0xFFF0F0F0),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerStrike(theme, progress, completed, total),
            const SizedBox(height: 8),
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (o) { o.disallowIndicator(); return true; },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _challenges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _challengeItem(i),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: completed > 0 ? _finishToday : null,
                    child: const Text('Selesai Hari Ini'),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _headerStrike(ThemeData theme, double progress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Challenge Harian', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_todayKey, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🔥 ', style: TextStyle(fontSize: 20)),
              Text('Strike $_strike hari!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE6E6E6),
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text('Selesai $completed dari $total challenge', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _challengeItem(int i) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: _done[i],
        onChanged: (v) => _toggle(i, v ?? false),
        title: Text(_challenges[i]),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
