import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageKeys {
  static const loggedIn = 'logged_in';
  static const strikeCount = 'strike_count';
  static const lastCompletedDate = 'last_completed_date'; // yyyy-MM-dd

  static String challengesForDate(String yyyymmdd) => 'challenges_$yyyymmdd';
  static String challengesDoneForDate(String yyyymmdd) => 'challenges_done_$yyyymmdd';
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
}
