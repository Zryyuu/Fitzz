import 'dart:math';

class ChallengeType {
  final String name; // e.g., 'Push-up'
  final int base; // base reps/seconds at level 1
  final int perLevel; // increment per level
  final bool isDuration; // true => seconds, false => reps
  const ChallengeType(this.name, this.base, this.perLevel, {this.isDuration = false});

  String format(int level) {
    int value = base + perLevel * (level - 1);
    if (isDuration) {
      return '$name $value detik';
    }
    return '$name ${value}x';
  }
}

class DailyChallengeGenerator {
  // Derived from your table (approx):
  static const List<ChallengeType> types = [
    ChallengeType('Push-up', 10, 3),
    ChallengeType('Sit-up', 15, 3),
    ChallengeType('Squat', 15, 3),
    ChallengeType('Lunge / kaki', 10, 2),
    ChallengeType('Burpee', 5, 2),
    ChallengeType('Dip (kursi)', 8, 2),
    ChallengeType('Jumping Jack', 30, 10, isDuration: true),
    ChallengeType('High Knees', 20, 10, isDuration: true),
    ChallengeType('Plank', 20, 5, isDuration: true),
    ChallengeType('Wall Sit', 20, 5, isDuration: true),
    ChallengeType('Mountain Climber', 15, 5, isDuration: true),
    ChallengeType('Jump Squat', 8, 2),
  ];

  static int _seedFrom(String a, int b) {
    final s = '$a#$b';
    return s.codeUnits.fold<int>(0, (p, c) => (p * 131 + c) & 0x7fffffff);
  }

  /// Deterministic pick of 3 challenges based on date and current level.
  /// If level goes up/down, the output becomes harder/easier automatically.
  static List<String> generateForDateLevel(String yyyymmdd, int level) {
    final rand = Random(_seedFrom(yyyymmdd, level));
    final idx = <int>{};
    while (idx.length < 3 && idx.length < types.length) {
      idx.add(rand.nextInt(types.length));
    }
    return idx.map((i) => types[i].format(level)).toList();
  }
}
