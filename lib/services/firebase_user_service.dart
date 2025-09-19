import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Centralized keys used in Firestore user documents and subcollections
class StorageKeys {
  // Base keys (namespaced under users/{uid})
  static const strikeCount = 'strike_count';
  static const lastCompletedDate = 'last_completed_date'; // yyyy-MM-dd
  static const totalXp = 'total_xp';
  static const totalWorkouts = 'total_workouts';
  static const bestStrike = 'best_strike';
  static const badgesEarned = 'badges_earned'; // list<int>
  static const penaltyCheckedDate = 'penalty_checked_date'; // yyyy-MM-dd
  static const lastOpenedDate = 'last_opened_date'; // yyyy-MM-dd
  static const selectedBadgeLevel = 'selected_badge_level'; // int
  static const avatarData = 'avatar_data_base64'; // String? base64 of small image
  // Profile
  static const displayName = 'user_display_name';

  static String challengesForDate(String yyyymmdd) => 'challenges_$yyyymmdd';
  static String challengesDoneForDate(String yyyymmdd) => 'challenges_done_$yyyymmdd';
  static String challengesRevealedForDate(String yyyymmdd) => 'challenges_revealed_$yyyymmdd';
  static String extraCountForDate(String yyyymmdd) => 'challenges_extra_count_$yyyymmdd';
}

// Firebase-only service for user data. All persistence uses Cloud Firestore
// under users/{uid} and its subcollections.
class FirebaseUserService {
  FirebaseUserService._();
  static final FirebaseUserService instance = FirebaseUserService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  // Live notifiers for UI
  final ValueNotifier<String?> avatarUrlNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> avatarDataNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int?> selectedBadgeLevelNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int> dataVersionNotifier = ValueNotifier<int>(0);

  Future<void> preloadNotifiers() async {
    avatarUrlNotifier.value = await getAvatarUrl();
    avatarDataNotifier.value = await getAvatarData();
    selectedBadgeLevelNotifier.value = await getSelectedBadgeLevel();
  }

  void bumpDataVersion() {
    dataVersionNotifier.value = dataVersionNotifier.value + 1;
  }

  // Registration helper (call after sign-up if needed)
  Future<void> ensureUserProfile({String? displayName}) async {
    final doc = _userDoc();
    final user = _auth.currentUser;
    if (doc == null || user == null) return;
    await doc.set({
      'email': user.email?.toLowerCase(),
      StorageKeys.displayName: (displayName ?? '').trim(),
      StorageKeys.totalXp: 0,
      StorageKeys.totalWorkouts: 0,
      StorageKeys.bestStrike: 0,
      StorageKeys.strikeCount: 0,
      'avatarUrl': null,
      StorageKeys.avatarData: null,
      StorageKeys.badgesEarned: <int>[],
      StorageKeys.selectedBadgeLevel: null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Profile: Display Name
  Future<String?> getDisplayName() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?[StorageKeys.displayName] as String?;
  }

  Future<void> setDisplayName(String? name) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.displayName: (name ?? '').trim(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Profile: Avatar URL (stored in users/{uid}.avatarUrl)
  Future<String?> getAvatarUrl() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?['avatarUrl'] as String?;
  }

  Future<void> setAvatarUrl(String? url) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({'avatarUrl': url, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    avatarUrlNotifier.value = (url == null || url.isEmpty) ? null : url;
  }

  // Profile: Avatar Data (base64 string) alternative to Storage URL
  Future<String?> getAvatarData() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?[StorageKeys.avatarData] as String?;
  }

  Future<void> setAvatarData(String? base64) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.avatarData: base64, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    avatarDataNotifier.value = (base64 == null || base64.isEmpty) ? null : base64;
  }

  // Selected badge level (avatar border)
  Future<int?> getSelectedBadgeLevel() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return (snap.data()?[StorageKeys.selectedBadgeLevel] as int?);
  }

  Future<void> setSelectedBadgeLevel(int? level) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.selectedBadgeLevel: level, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    selectedBadgeLevelNotifier.value = level;
  }

  // Strike
  Future<int> getStrike() async {
    final doc = _userDoc();
    if (doc == null) return 0;
    final snap = await doc.get();
    return (snap.data()?[StorageKeys.strikeCount] as int?) ?? 0;
  }

  Future<void> setStrike(int value) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.strikeCount: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Dates
  Future<String?> getLastCompletedDate() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?[StorageKeys.lastCompletedDate] as String?;
  }

  Future<void> setLastCompletedDate(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.lastCompletedDate: yyyymmdd, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // XP & Workouts
  Future<int> getTotalXp() async {
    final doc = _userDoc();
    if (doc == null) return 0;
    final snap = await doc.get();
    return (snap.data()?[StorageKeys.totalXp] as int?) ?? 0;
  }

  Future<void> setTotalXp(int value) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.totalXp: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<int> getTotalWorkouts() async {
    final doc = _userDoc();
    if (doc == null) return 0;
    final snap = await doc.get();
    return (snap.data()?[StorageKeys.totalWorkouts] as int?) ?? 0;
  }

  Future<void> setTotalWorkouts(int value) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.totalWorkouts: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<int> getBestStrike() async {
    final doc = _userDoc();
    if (doc == null) return 0;
    final snap = await doc.get();
    return (snap.data()?[StorageKeys.bestStrike] as int?) ?? 0;
  }

  Future<void> setBestStrike(int value) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.bestStrike: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Badges
  Future<List<int>> getBadges() async {
    final doc = _userDoc();
    if (doc == null) return <int>[];
    final snap = await doc.get();
    final list = (snap.data()?[StorageKeys.badgesEarned] as List?)?.map((e) => (e as num).toInt()).toList() ?? <int>[];
    list.sort();
    return list;
  }

  Future<void> setBadges(List<int> badges) async {
    final doc = _userDoc();
    if (doc == null) return;
    badges = badges.toSet().toList()..sort();
    await doc.set({StorageKeys.badgesEarned: badges, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Penalty guards
  Future<String?> getPenaltyCheckedDate() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?[StorageKeys.penaltyCheckedDate] as String?;
  }

  Future<void> setPenaltyCheckedDate(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.penaltyCheckedDate: yyyymmdd, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<String?> getLastOpenedDate() async {
    final doc = _userDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    return snap.data()?[StorageKeys.lastOpenedDate] as String?;
  }

  Future<void> setLastOpenedDate(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.set({StorageKeys.lastOpenedDate: yyyymmdd, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // Daily subcollection
  Future<int> getExtraCount(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return 0;
    final dailyDoc = doc.collection('daily').doc(yyyymmdd);
    final snap = await dailyDoc.get();
    return (snap.data()?['extraAdded'] as int?) ?? 0;
  }

  Future<void> setExtraCount(String yyyymmdd, int count) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.collection('daily').doc(yyyymmdd).set({'extraAdded': count}, SetOptions(merge: true));
  }

  Future<List<String>?> getChallenges(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return null;
    final dailyDoc = doc.collection('daily').doc(yyyymmdd);
    final snap = await dailyDoc.get();
    final list = (snap.data()?['challenges'] as List?)?.map((e) => e.toString()).toList();
    return list;
  }

  Future<void> setChallenges(String yyyymmdd, List<String> challenges) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.collection('daily').doc(yyyymmdd).set({'challenges': challenges}, SetOptions(merge: true));
  }

  Future<List<bool>> getChallengesDone(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return List<bool>.filled(3, false);
    final dailyDoc = doc.collection('daily').doc(yyyymmdd);
    final snap = await dailyDoc.get();
    final list = (snap.data()?['done'] as List?)?.map((e) => e == true).toList() ?? List<bool>.filled(3, false);
    return list;
  }

  Future<void> setChallengesDone(String yyyymmdd, List<bool> done) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.collection('daily').doc(yyyymmdd).set({'done': done}, SetOptions(merge: true));
  }

  Future<bool> getChallengesRevealed(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return false;
    final dailyDoc = doc.collection('daily').doc(yyyymmdd);
    final snap = await dailyDoc.get();
    return (snap.data()?['revealed'] as bool?) ?? false;
  }

  Future<void> setChallengesRevealed(String yyyymmdd, bool revealed) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.collection('daily').doc(yyyymmdd).set({'revealed': revealed}, SetOptions(merge: true));
  }

  Future<void> removeDailyData(String yyyymmdd) async {
    final doc = _userDoc();
    if (doc == null) return;
    await doc.collection('daily').doc(yyyymmdd).delete();
  }
}
