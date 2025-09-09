import 'dart:math';

class DailyChallengeGenerator {
  static final List<String> _pool = [
    'Push Up 10x',
    'Push Up 20x',
    'Push Up 30x',
    'Squat 20x',
    'Squat 30x',
    'Plank 60 detik',
    'Plank 90 detik',
    'Lari 5 menit',
    'Lari 10 menit',
    'Jalan cepat 15 menit',
    'Lompat tali 100x',
    'Wall Sit 60 detik',
    'Burpees 15x',
    'Mountain Climber 40x',
  ];

  /// Deterministic pick of 3 challenges based on yyyy-MM-dd
  static List<String> generateForDate(String yyyymmdd) {
    // Simple hash of date to seed Random
    int seed = yyyymmdd.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
    final rand = Random(seed);
    final indices = <int>{};
    while (indices.length < 3 && indices.length < _pool.length) {
      indices.add(rand.nextInt(_pool.length));
    }
    return indices.map((i) => _pool[i]).toList();
  }
}
