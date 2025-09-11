import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const loggedIn = 'logged_in';
  static const strikeCount = 'strike_count';
  static const lastCompletedDate = 'last_completed_date'; // yyyy-MM-dd
  static const totalXp = 'total_xp';
  static const totalWorkouts = 'total_workouts';
  // New: track highest strike and earned badges
  static const bestStrike = 'best_strike';
  static const badgesEarned = 'badges_earned'; // json list<int>
  static const penaltyCheckedDate = 'penalty_checked_date'; // yyyy-MM-dd
  static const selectedBadgeLevel = 'selected_badge_level'; // int, one of thresholds
  // Profile
  static const displayName = 'user_display_name';
  static const password = 'user_password';
  static const avatarBase64 = 'user_avatar_base64';

  static String challengesForDate(String yyyymmdd) => 'challenges_$yyyymmdd';
  static String challengesDoneForDate(String yyyymmdd) => 'challenges_done_$yyyymmdd';
  static String challengesRevealedForDate(String yyyymmdd) => 'challenges_revealed_$yyyymmdd';
  static String extraCountForDate(String yyyymmdd) => 'challenges_extra_count_$yyyymmdd';
}

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> isLoggedIn() async {
    final p = await _prefs;
    return p.getBool(StorageKeys.loggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final p = await _prefs;
    await p.setBool(StorageKeys.loggedIn, value);
  }

  // Profile: Display Name
  Future<String?> getDisplayName() async {
    final p = await _prefs;
    return p.getString(StorageKeys.displayName);
  }

  Future<void> setDisplayName(String? name) async {
    final p = await _prefs;
    if (name == null || name.trim().isEmpty) {
      await p.remove(StorageKeys.displayName);
    } else {
      await p.setString(StorageKeys.displayName, name.trim());
    }
  }

  // Profile: Avatar image (base64 encoded PNG/JPEG)
  Future<String?> getAvatarBase64() async {
    final p = await _prefs;
    return p.getString(StorageKeys.avatarBase64);
  }

  Future<void> setAvatarBase64(String? base64) async {
    final p = await _prefs;
    if (base64 == null || base64.isEmpty) {
      await p.remove(StorageKeys.avatarBase64);
    } else {
      await p.setString(StorageKeys.avatarBase64, base64);
    }
  }

  // Profile: Password (local-only demo; not secure)
  Future<String?> getPassword() async {
    final p = await _prefs;
    return p.getString(StorageKeys.password);
  }

  Future<void> setPassword(String? password) async {
    final p = await _prefs;
    if (password == null || password.isEmpty) {
      await p.remove(StorageKeys.password);
    } else {
      await p.setString(StorageKeys.password, password);
    }
  }

  Future<int> getStrike() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.strikeCount) ?? 0;
  }

  Future<void> setStrike(int value) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.strikeCount, value);
  }

  Future<String?> getLastCompletedDate() async {
    final p = await _prefs;
    return p.getString(StorageKeys.lastCompletedDate);
  }

  Future<void> setLastCompletedDate(String yyyymmdd) async {
    final p = await _prefs;
    await p.setString(StorageKeys.lastCompletedDate, yyyymmdd);
  }

  // XP & Workouts summary
  Future<int> getTotalXp() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.totalXp) ?? 0;
  }

  Future<void> setTotalXp(int value) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.totalXp, value);
  }

  Future<int> getTotalWorkouts() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.totalWorkouts) ?? 0;
  }

  Future<void> setTotalWorkouts(int value) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.totalWorkouts, value);
  }

  // Best strike
  Future<int> getBestStrike() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.bestStrike) ?? 0;
  }

  Future<void> setBestStrike(int value) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.bestStrike, value);
  }

  // Badges earned (levels achieved)
  Future<List<int>> getBadges() async {
    final p = await _prefs;
    final raw = p.getString(StorageKeys.badgesEarned);
    if (raw == null) return <int>[];
    final list = (jsonDecode(raw) as List).map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    list.sort();
    return list;
  }

  Future<void> setBadges(List<int> badges) async {
    final p = await _prefs;
    badges = badges.toSet().toList()..sort();
    await p.setString(StorageKeys.badgesEarned, jsonEncode(badges));
  }

  // Penalty checked date
  Future<String?> getPenaltyCheckedDate() async {
    final p = await _prefs;
    return p.getString(StorageKeys.penaltyCheckedDate);
  }

  Future<void> setPenaltyCheckedDate(String yyyymmdd) async {
    final p = await _prefs;
    await p.setString(StorageKeys.penaltyCheckedDate, yyyymmdd);
  }

  // Extra challenges added count per date
  Future<int> getExtraCount(String yyyymmdd) async {
    final p = await _prefs;
    return p.getInt(StorageKeys.extraCountForDate(yyyymmdd)) ?? 0;
    }

  Future<void> setExtraCount(String yyyymmdd, int count) async {
    final p = await _prefs;
    await p.setInt(StorageKeys.extraCountForDate(yyyymmdd), count);
  }

  // Selected badge (used e.g., as avatar border)
  Future<int?> getSelectedBadgeLevel() async {
    final p = await _prefs;
    return p.getInt(StorageKeys.selectedBadgeLevel);
  }

  Future<void> setSelectedBadgeLevel(int? level) async {
    final p = await _prefs;
    if (level == null) {
      await p.remove(StorageKeys.selectedBadgeLevel);
    } else {
      await p.setInt(StorageKeys.selectedBadgeLevel, level);
    }
  }

  Future<List<String>?> getChallenges(String yyyymmdd) async {
    final p = await _prefs;
    final raw = p.getString(StorageKeys.challengesForDate(yyyymmdd));
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
  }

  Future<void> setChallenges(String yyyymmdd, List<String> challenges) async {
    final p = await _prefs;
    await p.setString(StorageKeys.challengesForDate(yyyymmdd), jsonEncode(challenges));
  }

  Future<List<bool>> getChallengesDone(String yyyymmdd) async {
    final p = await _prefs;
    final raw = p.getString(StorageKeys.challengesDoneForDate(yyyymmdd));
    if (raw == null) return List<bool>.filled(3, false);
    return (jsonDecode(raw) as List).map((e) => e == true).toList();
  }

  Future<void> setChallengesDone(String yyyymmdd, List<bool> done) async {
    final p = await _prefs;
    await p.setString(StorageKeys.challengesDoneForDate(yyyymmdd), jsonEncode(done));
  }

  // Daily reveal state
  Future<bool> getChallengesRevealed(String yyyymmdd) async {
    final p = await _prefs;
    return p.getBool(StorageKeys.challengesRevealedForDate(yyyymmdd)) ?? false;
  }

  Future<void> setChallengesRevealed(String yyyymmdd, bool revealed) async {
    final p = await _prefs;
    await p.setBool(StorageKeys.challengesRevealedForDate(yyyymmdd), revealed);
  }
}
