import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  // Global (not namespaced)
  static const loggedIn = 'logged_in';
  static const activeEmail = 'active_user_email';

  // Base keys (will be namespaced per email): user_{email}__<key>
  static const strikeCount = 'strike_count';
  static const lastCompletedDate = 'last_completed_date'; // yyyy-MM-dd
  static const totalXp = 'total_xp';
  static const totalWorkouts = 'total_workouts';
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

  // Helpers: namespacing per email
  String _nsKey(String email, String base) => 'user_${email.toLowerCase()}__$base';
  Future<String?> _getActiveEmail() async {
    final p = await _prefs;
    return p.getString(StorageKeys.activeEmail);
  }
  Future<void> _setActiveEmail(String? email) async {
    final p = await _prefs;
    if (email == null || email.isEmpty) {
      await p.remove(StorageKeys.activeEmail);
    } else {
      await p.setString(StorageKeys.activeEmail, email.toLowerCase());
    }
  }

  // Public: active user management
  Future<String?> getActiveEmail() => _getActiveEmail();
  Future<void> setActiveEmail(String? email) => _setActiveEmail(email);

  Future<bool> isLoggedIn() async {
    final p = await _prefs;
    return p.getBool(StorageKeys.loggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final p = await _prefs;
    await p.setBool(StorageKeys.loggedIn, value);
  }

  // ---------- AUTH (per-email) ----------
  Future<bool> isUserRegistered(String email) async {
    final p = await _prefs;
    return p.containsKey(_nsKey(email, StorageKeys.password));
  }

  Future<void> registerUser({required String email, required String password, String? displayName}) async {
    final p = await _prefs;
    final e = email.toLowerCase();
    await p.setString(_nsKey(e, StorageKeys.password), password);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await p.setString(_nsKey(e, StorageKeys.displayName), displayName.trim());
    }
  }

  Future<bool> validateCredentials({required String email, required String password}) async {
    final p = await _prefs;
    final saved = p.getString(_nsKey(email, StorageKeys.password));
    return saved != null && saved == password;
  }

  // Profile: Display Name (active user)
  Future<String?> getDisplayName() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getString(_nsKey(email, StorageKeys.displayName));
  }

  Future<void> setDisplayName(String? name) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    if (name == null || name.trim().isEmpty) {
      await p.remove(_nsKey(email, StorageKeys.displayName));
    } else {
      await p.setString(_nsKey(email, StorageKeys.displayName), name.trim());
    }
  }

  // Profile: Avatar image (base64 encoded PNG/JPEG) for active user
  Future<String?> getAvatarBase64() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getString(_nsKey(email, StorageKeys.avatarBase64));
  }

  Future<void> setAvatarBase64(String? base64) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    if (base64 == null || base64.isEmpty) {
      await p.remove(_nsKey(email, StorageKeys.avatarBase64));
    } else {
      await p.setString(_nsKey(email, StorageKeys.avatarBase64), base64);
    }
  }

  // Profile: Password (local-only demo; not secure)
  Future<String?> getPassword() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getString(_nsKey(email, StorageKeys.password));
  }

  Future<void> setPassword(String? password) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    if (password == null || password.isEmpty) {
      await p.remove(_nsKey(email, StorageKeys.password));
    } else {
      await p.setString(_nsKey(email, StorageKeys.password), password);
    }
  }

  // Direct (by email) variants used during login/register
  Future<String?> getPasswordForEmail(String email) async {
    final p = await _prefs;
    return p.getString(_nsKey(email, StorageKeys.password));
  }
  Future<String?> getDisplayNameForEmail(String email) async {
    final p = await _prefs;
    return p.getString(_nsKey(email, StorageKeys.displayName));
  }

  Future<int> getStrike() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return 0;
    return p.getInt(_nsKey(email, StorageKeys.strikeCount)) ?? 0;
  }

  Future<void> setStrike(int value) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setInt(_nsKey(email, StorageKeys.strikeCount), value);
  }

  Future<String?> getLastCompletedDate() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getString(_nsKey(email, StorageKeys.lastCompletedDate));
  }

  Future<void> setLastCompletedDate(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setString(_nsKey(email, StorageKeys.lastCompletedDate), yyyymmdd);
  }

  // XP & Workouts summary
  Future<int> getTotalXp() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return 0;
    return p.getInt(_nsKey(email, StorageKeys.totalXp)) ?? 0;
  }

  Future<void> setTotalXp(int value) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setInt(_nsKey(email, StorageKeys.totalXp), value);
  }

  Future<int> getTotalWorkouts() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return 0;
    return p.getInt(_nsKey(email, StorageKeys.totalWorkouts)) ?? 0;
  }

  Future<void> setTotalWorkouts(int value) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setInt(_nsKey(email, StorageKeys.totalWorkouts), value);
  }

  // Best strike
  Future<int> getBestStrike() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return 0;
    return p.getInt(_nsKey(email, StorageKeys.bestStrike)) ?? 0;
  }

  Future<void> setBestStrike(int value) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setInt(_nsKey(email, StorageKeys.bestStrike), value);
  }

  // Badges earned (levels achieved)
  Future<List<int>> getBadges() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return <int>[];
    final raw = p.getString(_nsKey(email, StorageKeys.badgesEarned));
    if (raw == null) return <int>[];
    final list = (jsonDecode(raw) as List).map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    list.sort();
    return list;
  }

  Future<void> setBadges(List<int> badges) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    badges = badges.toSet().toList()..sort();
    await p.setString(_nsKey(email, StorageKeys.badgesEarned), jsonEncode(badges));
  }

  // Penalty checked date
  Future<String?> getPenaltyCheckedDate() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getString(_nsKey(email, StorageKeys.penaltyCheckedDate));
  }

  Future<void> setPenaltyCheckedDate(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setString(_nsKey(email, StorageKeys.penaltyCheckedDate), yyyymmdd);
  }

  // Extra challenges added count per date
  Future<int> getExtraCount(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return 0;
    return p.getInt(_nsKey(email, StorageKeys.extraCountForDate(yyyymmdd))) ?? 0;
    }

  Future<void> setExtraCount(String yyyymmdd, int count) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setInt(_nsKey(email, StorageKeys.extraCountForDate(yyyymmdd)), count);
  }

  // Selected badge (used e.g., as avatar border)
  Future<int?> getSelectedBadgeLevel() async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    return p.getInt(_nsKey(email, StorageKeys.selectedBadgeLevel));
  }

  Future<void> setSelectedBadgeLevel(int? level) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    if (level == null) {
      await p.remove(_nsKey(email, StorageKeys.selectedBadgeLevel));
    } else {
      await p.setInt(_nsKey(email, StorageKeys.selectedBadgeLevel), level);
    }
  }

  Future<List<String>?> getChallenges(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return null;
    final raw = p.getString(_nsKey(email, StorageKeys.challengesForDate(yyyymmdd)));
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
  }

  Future<void> setChallenges(String yyyymmdd, List<String> challenges) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setString(_nsKey(email, StorageKeys.challengesForDate(yyyymmdd)), jsonEncode(challenges));
  }

  Future<List<bool>> getChallengesDone(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return List<bool>.filled(3, false);
    final raw = p.getString(_nsKey(email, StorageKeys.challengesDoneForDate(yyyymmdd)));
    if (raw == null) return List<bool>.filled(3, false);
    return (jsonDecode(raw) as List).map((e) => e == true).toList();
  }

  Future<void> setChallengesDone(String yyyymmdd, List<bool> done) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setString(_nsKey(email, StorageKeys.challengesDoneForDate(yyyymmdd)), jsonEncode(done));
  }

  // Daily reveal state
  Future<bool> getChallengesRevealed(String yyyymmdd) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return false;
    return p.getBool(_nsKey(email, StorageKeys.challengesRevealedForDate(yyyymmdd))) ?? false;
  }

  Future<void> setChallengesRevealed(String yyyymmdd, bool revealed) async {
    final p = await _prefs;
    final email = await _getActiveEmail();
    if (email == null) return;
    await p.setBool(_nsKey(email, StorageKeys.challengesRevealedForDate(yyyymmdd)), revealed);
  }
}
