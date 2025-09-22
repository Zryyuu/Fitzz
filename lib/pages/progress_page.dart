import 'package:flutter/material.dart';
import 'package:fitzz/services/firebase_user_service.dart';
import 'package:intl/intl.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
// import 'package:fitzz/widgets/profile_avatar_button.dart';
import 'package:fitzz/widgets/top_status_header.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, this.withBottomNav = true});

  final bool withBottomNav;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with WidgetsBindingObserver {
  int _strike = 0;
  String _lastDate = '';
  bool _ready = false; // prevent flicker until async init completes
  int _totalXp = 0;
  // Monthly grid state
  late DateTime _visibleMonth; // first day of month
  Set<int> _completedDays = <int>{}; // set of day numbers in visible month
  bool _loadingMonth = false;
  int _monthLoadSeq = 0; // sequence guard for month loading

  // Allow parent (e.g., TabShell) to trigger a manual refresh when this tab becomes visible
  Future<void> refresh() async {
    await _init();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _init();
    // Auto-refresh when global data version bumps (e.g., after rewind)
    final storage = FirebaseUserService.instance;
    storage.dataVersionNotifier.addListener(_onDataVersionChanged);
  }

  void _onDataVersionChanged() {
    // silently refresh; ignore if widget not mounted
    if (!mounted) return;
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FirebaseUserService.instance.dataVersionNotifier.removeListener(_onDataVersionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh stats and the current month when returning to the app
      refresh();
    }
  }

  Future<void> _init() async {
    final storage = FirebaseUserService.instance;
    final strike = await storage.getStrike();
    final last = await storage.getLastCompletedDate() ?? '-';
    final totalXp = await storage.getTotalXp();
    if (!mounted) return;
    setState(() {
      _strike = strike;
      _lastDate = last;
      _totalXp = totalXp;
      _ready = true;
    });
    // Load the initial month after basic stats are ready
    await _loadMonthData(_visibleMonth);
  }

  // Load all days in a month and mark those completed (first 3 challenges done)
  Future<void> _loadMonthData(DateTime month) async {
    if (!mounted) return;
    final int seq = ++_monthLoadSeq; // mark this request as the latest
    setState(() {
      _loadingMonth = true;
      // Kosongkan tampilan selesai agar tidak terbawa saat loading bulan baru
      _completedDays = <int>{};
    });
    final storage = FirebaseUserService.instance;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final completed = <int>{};
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final done = await storage.getChallengesDone(key);
      final dailyCompleted = done.take(3).every((e) => e == true);
      if (dailyCompleted) completed.add(d);
    }
    if (!mounted) return;
    // Drop results if a newer month load has started or month view has changed
    if (seq != _monthLoadSeq || month.year != _visibleMonth.year || month.month != _visibleMonth.month) {
      return;
    }
    setState(() {
      _completedDays = completed;
      _loadingMonth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Skeleton while waiting to avoid initial default flash
    if (!_ready) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TopStatusHeader(totalXp: _totalXp, strike: _strike),
              ),
            ),
          ),
        ),
        bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 1) : null,
        body: const SizedBox.expand(),
      );
    }
    final theme = Theme.of(context);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TopStatusHeader(totalXp: _totalXp, strike: _strike),
            ),
          ),
        ),
      ),
      // Drawer removed. Use bottom navigation instead.
      bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 1) : null,
      body: Container(
        color: const Color(0xFFF0F0F0),
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Full-width black bar behind the rounded top of the first white section
            Positioned(top: 0, left: 0, right: 0, child: Container(height: 48, color: Colors.black)),
            // Sticky top summary card (keeps rounded corners visible under header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text('Strike: $_strike hari', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Terakhir selesai: $_lastDate'),
                    Text('Hari ini: $today'),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 600;
                const double stickySummaryHeight = 132; // approximate visible height of sticky card
                return ListView(
                  padding: const EdgeInsets.only(bottom: 16)
                      .copyWith(top: stickySummaryHeight + 16),
                  children: [
                    // Content below sticky card
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
                      child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Grafik Bulanan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                tooltip: 'Bulan sebelumnya',
                                onPressed: () async {
                                  setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
                                  await _loadMonthData(_visibleMonth);
                                },
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F3F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(DateFormat('MMMM yyyy').format(_visibleMonth), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              IconButton(
                                tooltip: 'Bulan berikutnya',
                                onPressed: (DateTime(_visibleMonth.year, _visibleMonth.month + 1).isAfter(DateTime.now()))
                                    ? null
                                    : () async {
                                        setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));
                                        await _loadMonthData(_visibleMonth);
                                      },
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Weekday headers
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Sen', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Sel', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Rab', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Kam', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Jum', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Sab', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('Min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_loadingMonth)
                            const LinearProgressIndicator(
                              minHeight: 3,
                              color: Color(0xFFBDBDBD),
                              backgroundColor: Color(0xFFEDEDED),
                            ),
                          if (_loadingMonth) const SizedBox(height: 6),
                          _monthlyGrid(theme),
                        ],
                      ),
                    ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
}

  Widget _monthlyGrid(ThemeData theme) {
    // Build a compact 7-column grid. Monday is the first day.
    final month = _visibleMonth;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (first.weekday + 6) % 7; // 0..6, Monday-first
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNum = index - startOffset + 1;
        final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
        if (!inMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(month.year, month.month, dayNum);
        final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
        // Saat loading, abaikan status selesai agar kotak tampil netral
        final completed = !_loadingMonth && _completedDays.contains(dayNum);
        final isFuture = date.isAfter(DateTime.now());
        final baseColor = completed
            ? const Color(0xFF2E7D32) // green
            : isFuture
                ? const Color(0xFFEDEDED)
                : const Color(0xFFD9D9D9);
        return Tooltip(
          message: DateFormat('EEE, dd MMM').format(date) + (completed ? ' • Selesai' : ''),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(5),
              border: isToday ? Border.all(color: Colors.black, width: 1) : null,
            ),
          ),
        );
      },
    );
  }
}
