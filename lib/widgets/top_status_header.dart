import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitzz/services/firebase_user_service.dart';

class TopStatusHeader extends StatefulWidget {
  const TopStatusHeader({super.key, this.totalXp, this.strike});

  final int? totalXp;
  final int? strike;

  @override
  State<TopStatusHeader> createState() => _TopStatusHeaderState();
}

class _TopStatusHeaderState extends State<TopStatusHeader> {
  String? _avatarUrl;
  String? _avatarData;
  int _totalXp = 0;
  int _strike = 0;

  @override
  void initState() {
    super.initState();
    final s = FirebaseUserService.instance;
    s.preloadNotifiers().then((_) async {
      if (!mounted) return;
      setState(() {
        _avatarUrl = s.avatarUrlNotifier.value;
        _avatarData = s.avatarDataNotifier.value;
      });
      // Load totals if not provided by parent
      if (widget.totalXp == null || widget.strike == null) {
        final txp = await s.getTotalXp();
        final st = await s.getStrike();
        if (mounted) {
          setState(() {
            _totalXp = txp;
            _strike = st;
          });
        }
      } else {
        _totalXp = widget.totalXp!;
        _strike = widget.strike!;
      }
    });
    s.avatarUrlNotifier.addListener(_onChange);
    s.avatarDataNotifier.addListener(_onChange);
    s.dataVersionNotifier.addListener(_onDataVersion);
  }

  @override
  void dispose() {
    final s = FirebaseUserService.instance;
    s.avatarUrlNotifier.removeListener(_onChange);
    s.avatarDataNotifier.removeListener(_onChange);
    s.dataVersionNotifier.removeListener(_onDataVersion);
    super.dispose();
  }

  void _onChange() {
    final s = FirebaseUserService.instance;
    if (!mounted) return;
    setState(() {
      _avatarUrl = s.avatarUrlNotifier.value;
      _avatarData = s.avatarDataNotifier.value;
    });
  }

  Future<void> _onDataVersion() async {
    if (!mounted) return;
    final s = FirebaseUserService.instance;
    final txp = await s.getTotalXp();
    final st = await s.getStrike();
    if (!mounted) return;
    setState(() {
      _totalXp = txp;
      _strike = st;
    });
  }

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
    final totalXp = widget.totalXp ?? _totalXp;
    final strike = widget.strike ?? _strike;
    final level = _levelFromXp(totalXp);
    int acc = 0;
    for (int l = 1; l < level; l++) { acc += _xpNeededForLevel(l); }
    final intoLevel = (totalXp - acc).clamp(0, _xpNeededForLevel(level));
    final need = _xpNeededForLevel(level);

    ImageProvider? imageProvider;
    if (_avatarData != null && _avatarData!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(_avatarData!));
      } catch (_) {
        imageProvider = null;
      }
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_avatarUrl!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
            child: imageProvider == null ? const Icon(Icons.person, color: Colors.black) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level $level', style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    value: need == 0 ? 0 : (intoLevel / need).clamp(0, 1).toDouble(),
                  ),
                ),
                const SizedBox(height: 2),
                Text('XP: $intoLevel/$need', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 4),
              Text('$strike', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
