import 'package:shared_preferences/shared_preferences.dart';

import 'proximity_checker.dart';

/// Посещённые места, время уведомлений и настройки в shared_preferences.
class Storage implements NotificationLog {
  Storage(this._prefs);

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _visitedKey = 'visited';
  static const _notifiedPrefix = 'notified_';
  static const _lastAnyKey = 'notified_any';

  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  set onboardingDone(bool v) => _prefs.setBool('onboarding_done', v);

  bool get guideEnabled => _prefs.getBool('guide_enabled') ?? true;
  set guideEnabled(bool v) => _prefs.setBool('guide_enabled', v);

  double get radiusScale => _prefs.getDouble('radius_scale') ?? 1.0;
  set radiusScale(double v) => _prefs.setDouble('radius_scale', v);

  Set<String> get visited => (_prefs.getStringList(_visitedKey) ?? const []).toSet();

  void markVisited(String placeId) {
    final ids = visited..add(placeId);
    _prefs.setStringList(_visitedKey, ids.toList());
  }

  /// Идущая сейчас прогулка и точки, пройденные в ней.
  String? get activeWalk => _prefs.getString('active_walk');
  set activeWalk(String? id) => id == null ? _prefs.remove('active_walk') : _prefs.setString('active_walk', id);

  Set<String> walkStops(String walkId) => (_prefs.getStringList('walk_$walkId') ?? const []).toSet();

  void markWalkStop(String walkId, String placeId) =>
      _prefs.setStringList('walk_$walkId', (walkStops(walkId)..add(placeId)).toList());

  void clearWalk(String walkId) => _prefs.remove('walk_$walkId');

  static const _achievementsKey = 'achievements';

  /// Полученные достижения: id → когда получено. Хранятся строками «id|миллисекунды».
  Map<String, DateTime> get unlockedAchievements => {
        for (final s in _prefs.getStringList(_achievementsKey) ?? const <String>[])
          if (s.split('|') case [final id, final ms])
            id: DateTime.fromMillisecondsSinceEpoch(int.tryParse(ms) ?? 0),
      };

  void markAchievements(Iterable<String> ids, DateTime at) {
    final all = unlockedAchievements;
    for (final id in ids) {
      all.putIfAbsent(id, () => at);
    }
    _prefs.setStringList(
      _achievementsKey,
      [for (final e in all.entries) '${e.key}|${e.value.millisecondsSinceEpoch}'],
    );
  }

  void resetProgress() {
    _prefs.remove(_achievementsKey);
    _prefs.remove('active_walk');
    for (final key in _prefs.getKeys().where((k) => k.startsWith('walk_')).toList()) {
      _prefs.remove(key);
    }
    _prefs.remove(_visitedKey);
    _prefs.remove(_lastAnyKey);
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_notifiedPrefix)).toList()) {
      _prefs.remove(key);
    }
  }

  @override
  DateTime? lastNotified(String placeId) => _readTime('$_notifiedPrefix$placeId');

  @override
  DateTime? get lastAnyNotified => _readTime(_lastAnyKey);

  @override
  void markNotified(String placeId, DateTime at) {
    _prefs.setInt('$_notifiedPrefix$placeId', at.millisecondsSinceEpoch);
    _prefs.setInt(_lastAnyKey, at.millisecondsSinceEpoch);
    markVisited(placeId);
  }

  DateTime? _readTime(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
