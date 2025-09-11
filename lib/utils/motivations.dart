import 'dart:math';

/// Centralized daily motivations that adapt to user's level & progress.
class Motivations {
  // Categories
  static const List<String> supportive = [
    'Setiap rep kecil itu langkah besar buat mentalmu.',
    'Capek itu tanda kamu lagi ditempa, bukan tanda kamu lemah.',
    'Hari ini cukup satu langkah ke depan, jangan berhenti.',
    'Sedikit tapi konsisten lebih kuat dari banyak tapi bolong.',
    'Kamu udah lebih jauh dari orang yang belum mulai.',
  ];

  static const List<String> tegasNyentil = [
    'Alasan nggak bikin badanmu kuat, gerakan yang bikin.',
    'Kalau nggak mulai sekarang, kapan lagi?',
    'Gampang nyerah itu kebiasaan, tahan sebentar itu kemenangan.',
    'Kalau masih bisa napas, berarti kamu masih bisa lanjut.',
    'Berhenti bukan pilihan, selesai itu tujuan.',
  ];

  static const List<String> progressOriented = [
    'Strike hari ini adalah bukti kecil kalau kamu bisa lebih jauh.',
    'Lihat mundur sebentar—kamu udah nggak di titik nol lagi.',
    'Setiap tetes keringat adalah tanda upgrade dirimu.',
    'Hari berat itu justru bikin hasil lebih manis.',
    'Progress lambat masih lebih baik daripada nol.',
  ];

  static const List<String> hardcorePush = [
    'Kalau latihan terasa enteng, berarti kamu belum berkembang.',
    'Rasa sakit sebentar lebih baik daripada penyesalan panjang.',
    'Lawanmu hari ini bukan orang lain, tapi rasa malasmu.',
    'Semakin berat, semakin dekat kamu ke level berikutnya.',
    'Tubuhmu kuat, tapi mentalmu harus lebih kuat.',
  ];

  static const List<String> strikeConsistency = [
    'Strike bukan angka, itu bukti kamu disiplin.',
    'Putus sehari bisa bikin ulang, jadi jangan biarin kosong.',
    'Konsistensi lebih kuat dari motivasi.',
    'Kalender penuh tanda strike itu medali aslimu.',
    'Satu hari lagi bisa jadi rekor barumu.',
  ];

  // Special moments
  static const List<String> specialFirstStrike = [
    'Strike pertama—ini awal perjalananmu.',
  ];
  static const List<String> specialSevenStrike = [
    'Strike ke-7, selamat naik level mental dan fisik!',
  ];
  static const List<String> specialComeback = [
    'Strike putus? Bangkit sekarang, jangan biarin dua kali.',
    'Hari ini hari comeback, buktikan kalau kamu belum habis.',
  ];
  static const List<String> specialLevelUp = [
    'Level naik bukan hadiah, itu bukti kerja kerasmu.',
  ];

  static int _seedFrom(List<Object?> parts) {
    final s = parts.map((e) => e?.toString() ?? '').join('#');
    return s.codeUnits.fold<int>(0, (p, c) => (p * 131 + c) & 0x7fffffff);
  }

  /// Choose motivation deterministically for a given day, adapted to user context.
  /// - yyyymmdd: date key
  /// - level: current level
  /// - strike: current running strike
  /// - bestStrike: best strike ever
  /// - lastCompletedDate: last day completed (yyyy-MM-dd) or null
  /// - levelJustUp: optional flag to select level-up message
  static String forContext(
    String yyyymmdd, {
    required int level,
    required int strike,
    required int bestStrike,
    String? lastCompletedDate,
    bool levelJustUp = false,
  }) {
    // 1) Special moments override
    List<String>? pool;
    final todaySeed = _seedFrom([yyyymmdd, level, strike, bestStrike, lastCompletedDate, levelJustUp]);

    // comeback: lastCompletedDate not null and not today/yesterday
    final today = yyyymmdd;
    String? yesterday;
    try {
      final d = DateTime.parse(yyyymmdd);
      yesterday = d.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    } catch (_) {}

    if (levelJustUp) {
      pool = specialLevelUp;
    } else if (strike == 1) {
      pool = specialFirstStrike;
    } else if (strike == 7) {
      pool = specialSevenStrike;
    } else if (lastCompletedDate != null && lastCompletedDate != today && lastCompletedDate != yesterday) {
      pool = specialComeback;
    }

    // 2) If no special, pick by level and streak mood
    pool ??= _categoryFor(level: level, strike: strike, bestStrike: bestStrike);

    final rand = Random(todaySeed);
    return pool[rand.nextInt(pool.length)];
  }

  static List<String> _categoryFor({required int level, required int strike, required int bestStrike}) {
    // Base by level tier
    if (level <= 10) {
      return supportive;
    } else if (level <= 25) {
      return progressOriented;
    } else if (level <= 45) {
      return tegasNyentil;
    } else {
      return hardcorePush;
    }
  }

  /// Backward-compat simple date-based pick (fallback)
  static String forDate(String yyyymmdd) {
    final all = [
      ...supportive,
      ...tegasNyentil,
      ...progressOriented,
      ...hardcorePush,
      ...strikeConsistency,
      ...specialFirstStrike,
      ...specialSevenStrike,
      ...specialComeback,
      ...specialLevelUp,
    ];
    final rand = Random(_seedFrom([yyyymmdd]));
    return all[rand.nextInt(all.length)];
  }
}
